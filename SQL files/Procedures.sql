USE HospitalDB;
GO

-- =====================================================
-- Procedure1: sp_RegisterPatient 
-- =====================================================
DROP PROCEDURE IF EXISTS sp_RegisterPatient;
GO
CREATE PROCEDURE sp_RegisterPatient
    @NationalID VARCHAR(10),
    @FirstName NVARCHAR(50),
    @LastName NVARCHAR(50),
    @Gender VARCHAR(10),
    @DOB DATE,
    @Phone VARCHAR(15) = NULL,
    @Address NVARCHAR(200) = NULL,
    @PatientID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (SELECT 1 FROM Patients WHERE NationalID = @NationalID)
    BEGIN
        RAISERROR('This national ID number has already been registered in the system.', 16, 1);
        RETURN;
    END;
    

    INSERT INTO Patients (NationalID, FirstName, LastName, Gender, DOB, Phone, Address)
    VALUES (@NationalID, @FirstName, @LastName, @Gender, @DOB, @Phone, @Address);
    
    SET @PatientID = SCOPE_IDENTITY();
    
    INSERT INTO Medical_Records (PatientID)
    VALUES (@PatientID);
    
    SELECT @PatientID AS PatientID, 'The patient was successfully registered.' AS Message;
END;
GO


-- =====================================================
-- Procedure2: sp_BookAppointment (نسخه نهایی با چک تداخل)
-- =====================================================
DROP PROCEDURE IF EXISTS sp_BookAppointment;
GO

CREATE PROCEDURE sp_BookAppointment
    @PatientID INT,
    @StaffID INT = NULL,
    @DepartmentID INT = NULL,
    @ApptDate DATETIME,
    @ApptType VARCHAR(20),
    @AppointmentID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ErrorMessage NVARCHAR(200) = '';
    DECLARE @InsertedID TABLE (ID INT);
    
    -- چک کردن وجود بیمار
    IF NOT EXISTS (SELECT 1 FROM Patients WHERE PatientID = @PatientID)
    BEGIN
        SET @ErrorMessage = 'Patient not found.';
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END;
    
    -- چک کردن اینکه حداقل یکی از StaffID یا DepartmentID پر شده باشد
    IF @StaffID IS NULL AND @DepartmentID IS NULL
    BEGIN
        SET @ErrorMessage = 'At least one of physician or department must be specified.';
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END;
    
    -- چک کردن تداخل نوبت برای بیمار (بازه 30 دقیقه)
    IF EXISTS (
        SELECT 1 FROM Appointments 
        WHERE PatientID = @PatientID 
          AND Status IN ('Scheduled', 'Rescheduled')
          AND ABS(DATEDIFF(MINUTE, ApptDate, @ApptDate)) < 30
    )
    BEGIN
        SET @ErrorMessage = 'Patient already has an active appointment within 30 minutes of this time.';
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END;
    
    -- چک کردن تداخل نوبت برای پزشک
    IF @StaffID IS NOT NULL
    BEGIN
        IF EXISTS (
            SELECT 1 FROM Appointments 
            WHERE StaffID = @StaffID 
              AND Status IN ('Scheduled', 'Rescheduled')
              AND ABS(DATEDIFF(MINUTE, ApptDate, @ApptDate)) < 30
        )
        BEGIN
            SET @ErrorMessage = 'Doctor already has an appointment within 30 minutes of this time.';
            RAISERROR(@ErrorMessage, 16, 1);
            RETURN;
        END;
    END;
    
    -- ثبت نوبت با OUTPUT INTO
    INSERT INTO Appointments (PatientID, StaffID, DepartmentID, ApptDate, ApptType, Status)
    OUTPUT INSERTED.AppointmentID INTO @InsertedID
    VALUES (@PatientID, @StaffID, @DepartmentID, @ApptDate, @ApptType, 'Scheduled');
    
    -- گرفتن ID نوبت ثبت شده از جدول موقت
    SELECT TOP 1 @AppointmentID = ID FROM @InsertedID;
    
    -- برگردوندن نتیجه
    SELECT @AppointmentID AS AppointmentID, 'Appointment successfully booked.' AS Message;
END;
GO

-- =====================================================
-- Procedure3: sp_AdmitPatient 
-- =====================================================
DROP PROCEDURE IF EXISTS sp_AdmitPatient;
GO
CREATE PROCEDURE sp_AdmitPatient
    @PatientID INT,
    @BedID INT,
    @StartDate DATETIME,
    @TransferID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT EXISTS (SELECT 1 FROM Patients WHERE PatientID = @PatientID)
    BEGIN
        RAISERROR('The patient in question was not found.', 16, 1);
        RETURN;
    END;
    
    IF EXISTS (SELECT 1 FROM Inpatient_Transfers WHERE PatientID = @PatientID AND EndDate IS NULL)
    BEGIN
        RAISERROR('The patient is already hospitalized on another bed.', 16, 1);
        RETURN;
    END;
    
    IF NOT EXISTS (SELECT 1 FROM Beds WHERE BedID = @BedID)
    BEGIN
        RAISERROR('The requested bed was not found.', 16, 1);
        RETURN;
    END;
    
    IF EXISTS (SELECT 1 FROM Beds WHERE BedID = @BedID AND Status != 'Available')
    BEGIN
        RAISERROR('The bed in question is currently occupied.', 16, 1);
        RETURN;
    END;
    
    UPDATE Beds SET Status = 'Occupied' WHERE BedID = @BedID;
    
    INSERT INTO Inpatient_Transfers (PatientID, BedID, StartDate, EndDate)
    VALUES (@PatientID, @BedID, @StartDate, NULL);
    
    SET @TransferID = SCOPE_IDENTITY();
    
    SELECT @TransferID AS TransferID, 'The patient was successfully admitted.' AS Message;
END;
GO

-- =====================================================
-- Procedure4: sp_TransferPatient 
-- =====================================================
DROP PROCEDURE IF EXISTS sp_TransferPatient;
GO
CREATE PROCEDURE sp_TransferPatient
    @PatientID INT,
    @NewBedID INT,
    @TransferDate DATETIME,
    @TransferID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentBedID INT;
    
    SELECT TOP 1 @CurrentBedID = BedID
    FROM Inpatient_Transfers
    WHERE PatientID = @PatientID AND EndDate IS NULL
    ORDER BY StartDate DESC;
    
    IF @CurrentBedID IS NULL
    BEGIN
        RAISERROR('The patient is currently not hospitalized.', 16, 1);
        RETURN;
    END;
    
    IF @CurrentBedID = @NewBedID
    BEGIN
        RAISERROR('The patient is already on this bed. Self-transfer is not allowed.', 16, 1);
        RETURN;
    END;
    
    IF NOT EXISTS (SELECT 1 FROM Beds WHERE BedID = @NewBedID AND Status = 'Available')
    BEGIN
        RAISERROR('The new bed is not available.', 16, 1);
        RETURN;
    END;
    
    BEGIN TRANSACTION;
    
    UPDATE Inpatient_Transfers
    SET EndDate = @TransferDate
    WHERE PatientID = @PatientID AND EndDate IS NULL;
    
    UPDATE Beds SET Status = 'Available' WHERE BedID = @CurrentBedID;
    
    UPDATE Beds SET Status = 'Occupied' WHERE BedID = @NewBedID;
    
    INSERT INTO Inpatient_Transfers (PatientID, BedID, StartDate, EndDate)
    VALUES (@PatientID, @NewBedID, @TransferDate, NULL);
    
    SET @TransferID = SCOPE_IDENTITY();
    
    COMMIT TRANSACTION;
    
    SELECT @TransferID AS TransferID, 'The patient was successfully transferred.' AS Message;
END;
GO

-- =====================================================
-- Procedure5: sp_DispensePrescription 
-- =====================================================
DROP PROCEDURE IF EXISTS sp_DispensePrescription;
GO
CREATE PROCEDURE sp_DispensePrescription
    @PrescriptionID INT,
    @Success BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Success = 0;
    
    DECLARE @ItemID INT;
    DECLARE @Quantity INT;
    DECLARE @CurrentStock INT;
    
    IF NOT EXISTS (SELECT 1 FROM Prescriptions WHERE PrescriptionID = @PrescriptionID)
    BEGIN
        RAISERROR('The requested prescription was not found.', 16, 1);
        RETURN;
    END;
    
    BEGIN TRANSACTION;
    
    DECLARE PrescriptionCursor CURSOR FOR
    SELECT ItemID, Quantity
    FROM Prescription_Items
    WHERE PrescriptionID = @PrescriptionID;
    
    OPEN PrescriptionCursor;
    FETCH NEXT FROM PrescriptionCursor INTO @ItemID, @Quantity;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @CurrentStock = CurrentStock
        FROM Inventory_Items
        WHERE ItemID = @ItemID;
        
        IF @CurrentStock < @Quantity
        BEGIN
            RAISERROR('The medication stock is insufficient.', 16, 1);
            ROLLBACK TRANSACTION;
            CLOSE PrescriptionCursor;
            DEALLOCATE PrescriptionCursor;
            RETURN;
        END;
        
        UPDATE Inventory_Items
        SET CurrentStock = CurrentStock - @Quantity
        WHERE ItemID = @ItemID;
        
        
        FETCH NEXT FROM PrescriptionCursor INTO @ItemID, @Quantity;
    END;
    
    CLOSE PrescriptionCursor;
    DEALLOCATE PrescriptionCursor;
    
    COMMIT TRANSACTION;
    
    SET @Success = 1;
    SELECT @PrescriptionID AS PrescriptionID, 'The prescription was successfully delivered.' AS Message;
END;
GO

-- =====================================================
-- Procedure6: sp_RecordLabResult 
-- =====================================================
DROP PROCEDURE IF EXISTS sp_RecordLabResult;
GO
CREATE PROCEDURE sp_RecordLabResult
    @ResultID INT,
    @ResultDetails NVARCHAR(MAX),
    @IsCritical BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT EXISTS (SELECT 1 FROM Lab_Results WHERE ResultID = @ResultID)
    BEGIN
        RAISERROR('The requested test was not found.', 16, 1);
        RETURN;
    END;
    
    BEGIN TRANSACTION;
    
    UPDATE Lab_Results
    SET ResultDetails = @ResultDetails,
        IsCritical = @IsCritical,
        Status = 'Completed',
        TestDate = GETDATE()
    WHERE ResultID = @ResultID;
    
    
    COMMIT TRANSACTION;
    
    SELECT @ResultID AS ResultID, 'The test result was successfully recorded.' AS Message;
END;
GO
-- =====================================================
-- Procedure7: sp_RecordPayment 
-- =====================================================
DROP PROCEDURE IF EXISTS sp_RecordPayment;
GO
CREATE PROCEDURE sp_RecordPayment
    @InvoiceID INT,
    @Amount DECIMAL(18,2),
    @PaymentType VARCHAR(20),
    @PaymentID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @PatientShare DECIMAL(18,2);
    DECLARE @TotalPayments DECIMAL(18,2);
    DECLARE @RemainingShare DECIMAL(18,2);
    
    IF NOT EXISTS (SELECT 1 FROM Invoices WHERE InvoiceID = @InvoiceID)
    BEGIN
        RAISERROR('The requested invoice was not found.', 16, 1);
        RETURN;
    END;
    
    IF EXISTS (SELECT 1 FROM Invoices WHERE InvoiceID = @InvoiceID AND Status = 'Paid')
    BEGIN
        RAISERROR('This invoice has already been settled.', 16, 1);
        RETURN;
    END;

    SELECT @PatientShare = PatientShare FROM Invoices WHERE InvoiceID = @InvoiceID;
    SELECT @TotalPayments = ISNULL(SUM(Amount), 0) FROM Payments WHERE InvoiceID = @InvoiceID;
    
    SET @RemainingShare = @PatientShare - @TotalPayments;

    IF @Amount > @RemainingShare
    BEGIN
        RAISERROR('The payment amount exceeds the remaining balance of the invoice.', 16, 1);
        RETURN;
    END;
    
    BEGIN TRANSACTION;
    
    INSERT INTO Payments (InvoiceID, Amount, PaymentType, PaymentDate)
    VALUES (@InvoiceID, @Amount, @PaymentType, GETDATE());
    
    SET @PaymentID = SCOPE_IDENTITY();
    
    SELECT @TotalPayments = ISNULL(SUM(Amount), 0) FROM Payments WHERE InvoiceID = @InvoiceID;
    
    IF @TotalPayments >= @PatientShare
    BEGIN
        UPDATE Invoices
        SET Status = 'Paid'
        WHERE InvoiceID = @InvoiceID;
    END;
    
    COMMIT TRANSACTION;
    
    SELECT @PaymentID AS PaymentID, 'The payment was successfully recorded.' AS Message;
END;
GO
-- =====================================================
-- Procedure 8: sp_DischargePatient 
-- =====================================================
DROP PROCEDURE IF EXISTS sp_DischargePatient;
GO
CREATE PROCEDURE sp_DischargePatient
    @PatientID INT,
    @DischargeDate DATETIME,
    @Success BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Success = 0;
    
    DECLARE @CurrentBedID INT;
    
    SELECT TOP 1 @CurrentBedID = BedID
    FROM Inpatient_Transfers
    WHERE PatientID = @PatientID AND EndDate IS NULL
    ORDER BY StartDate DESC;
    
    IF @CurrentBedID IS NULL
    BEGIN
        RAISERROR('The patient is not currently hospitalized.', 16, 1);
        RETURN;
    END;
    
    BEGIN TRANSACTION;
    
    UPDATE Inpatient_Transfers
    SET EndDate = @DischargeDate
    WHERE PatientID = @PatientID AND EndDate IS NULL;
    
    UPDATE Beds
    SET Status = 'Available'
    WHERE BedID = @CurrentBedID;
    
    COMMIT TRANSACTION;
    
    SET @Success = 1;
    SELECT @PatientID AS PatientID, 'The patient was successfully discharged and the bed is now available.' AS Message;
END;
GO
-- =====================================================
-- Procedure 9: sp_GenerateInvoice 
-- =====================================================
DROP PROCEDURE IF EXISTS sp_GenerateInvoice;
GO
CREATE PROCEDURE sp_GenerateInvoice
    @PatientID INT,
    @InvoiceID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @BedCost DECIMAL(18,2) = 0;
    DECLARE @MedCost DECIMAL(18,2) = 0;
    DECLARE @LabCost DECIMAL(18,2) = 0;
    DECLARE @TotalAmount DECIMAL(18,2) = 0;
    DECLARE @InsuranceShare DECIMAL(18,2) = 0;
    DECLARE @PatientShare DECIMAL(18,2) = 0;
    
    SELECT @BedCost = ISNULL(SUM(DATEDIFF(DAY, StartDate, ISNULL(EndDate, GETDATE())) * 50000.00), 0)
    FROM Inpatient_Transfers
    WHERE PatientID = @PatientID;
    
    SELECT @MedCost = ISNULL(SUM(pi.Quantity * 10000.00), 0)
    FROM Prescription_Items pi
    JOIN Prescriptions p ON pi.PrescriptionID = p.PrescriptionID
    WHERE p.PatientID = @PatientID;
    
    SELECT @LabCost = ISNULL(COUNT(*) * 30000.00, 0)
    FROM Lab_Results
    WHERE PatientID = @PatientID AND Status = 'Completed';
    
    SET @TotalAmount = @BedCost + @MedCost + @LabCost;
    
    IF @TotalAmount = 0
    BEGIN
        RAISERROR('No services or hospitalization found to bill for this patient.', 16, 1);
        RETURN;
    END;
    
    SET @InsuranceShare = @TotalAmount * 0.70;
    SET @PatientShare = @TotalAmount - @InsuranceShare;
    
    INSERT INTO Invoices (PatientID, TotalAmount, InsuranceShare, PatientShare, Status)
    VALUES (@PatientID, @TotalAmount, @InsuranceShare, @PatientShare, 'Pending');
    
    SET @InvoiceID = SCOPE_IDENTITY();
    
    SELECT @InvoiceID AS InvoiceID, 'Invoice generated successfully.' AS Message, 
           @TotalAmount AS Total, @PatientShare AS PatientAmount, @BedCost AS BedShare;
END;
GO


-- ==========================================================================================
-- tests
-- ==========================================================================================
USE HospitalDB;
GO

-- =============================================
-- Test 1: Register New Patient (with completely new National ID)
-- =============================================
DECLARE @NewPatientID INT;
DECLARE @NewNationalID VARCHAR(10) = '9998887776';

IF NOT EXISTS (SELECT 1 FROM Patients WHERE NationalID = @NewNationalID)
BEGIN
    EXEC sp_RegisterPatient 
        @NationalID = @NewNationalID,
        @FirstName = 'Sara',
        @LastName = 'Ahmadi',
        @Gender = 'Female',
        @DOB = '1995-08-20',
        @Phone = '09351234567',
        @Address = 'Isfahan, Iran',
        @PatientID = @NewPatientID OUTPUT;
    
    SELECT @NewPatientID AS NewPatientID, 'New patient successfully registered.' AS Message;
END
ELSE
BEGIN
    PRINT 'This National ID is already registered. Please choose another one.';
END
GO

-- =============================================
-- Test 2: Book Appointment (with new patient and new date)
-- =============================================
DECLARE @NewAppointmentID INT;
DECLARE @TestPatientID INT = 5;
DECLARE @TestDate DATETIME = '2026-07-28 14:30:00';

IF NOT EXISTS (
    SELECT 1 FROM Appointments 
    WHERE PatientID = @TestPatientID 
      AND CAST(ApptDate AS DATE) = CAST(@TestDate AS DATE)
      AND Status IN ('Scheduled', 'Rescheduled')
)
BEGIN
    EXEC sp_BookAppointment 
        @PatientID = @TestPatientID,
        @StaffID = 2,
        @DepartmentID = NULL,
        @ApptDate = @TestDate,
        @ApptType = 'Online',
        @AppointmentID = @NewAppointmentID OUTPUT;
    
    SELECT @NewAppointmentID AS NewAppointmentID, 'New appointment successfully booked.' AS Message;
END
ELSE
BEGIN
    PRINT 'Patient already has an active appointment on this date. Please choose another date.';
END
GO

-- =============================================
-- Test 3: Admit Patient (with an available bed) 
-- =============================================
DECLARE @NewTransferID INT;
DECLARE @AvailableBedID INT;
DECLARE @CurrentDate DATETIME = GETDATE(); 

SELECT TOP 1 @AvailableBedID = BedID 
FROM Beds 
WHERE Status = 'Available' 
ORDER BY BedID;

IF @AvailableBedID IS NOT NULL
BEGIN
    EXEC sp_AdmitPatient 
        @PatientID = 5,
        @BedID = @AvailableBedID,
        @StartDate = @CurrentDate, 
        @TransferID = @NewTransferID OUTPUT;
    
    SELECT @NewTransferID AS NewTransferID, 'Patient successfully admitted.' AS Message, @AvailableBedID AS BedID;
END
ELSE
BEGIN
    PRINT 'No available beds found.';
END
GO
-- =============================================
-- Test 4: Record Lab Result (with a ResultID that has Status='Requested')
-- =============================================
DECLARE @TestResultID INT;
SELECT TOP 1 @TestResultID = ResultID 
FROM Lab_Results 
WHERE Status = 'Requested' 
ORDER BY ResultID;

IF @TestResultID IS NOT NULL
BEGIN
    EXEC sp_RecordLabResult 
        @ResultID = @TestResultID,
        @ResultDetails = 'Test Result: All values are normal. Patient is in good condition.',
        @IsCritical = 0;
    
    SELECT @TestResultID AS ResultID, 'Lab result successfully recorded.' AS Message;
END
ELSE
BEGIN
    PRINT 'No lab requests found with Status = Requested.';
END
GO

-- =============================================
-- Test 5: Record Payment (with an unpaid invoice)
-- =============================================
DECLARE @NewPaymentID INT;
DECLARE @TestInvoiceID INT;

SELECT TOP 1 @TestInvoiceID = InvoiceID 
FROM Invoices 
WHERE Status = 'Pending' 
ORDER BY InvoiceID;

IF @TestInvoiceID IS NOT NULL
BEGIN
    EXEC sp_RecordPayment 
        @InvoiceID = @TestInvoiceID,
        @Amount = 500.00,
        @PaymentType = 'Deposit',
        @PaymentID = @NewPaymentID OUTPUT;
    
    SELECT @NewPaymentID AS NewPaymentID, 'Payment successfully recorded.' AS Message, @TestInvoiceID AS InvoiceID;
END
ELSE
BEGIN
    PRINT 'All invoices have already been settled.';
END
GO
-- =============================================
-- Test 8: Discharge Hospitalized Patient
-- =============================================
DECLARE @SuccessDischarge BIT;
DECLARE @HospitalizedPatientID INT;

SELECT TOP 1 @HospitalizedPatientID = PatientID 
FROM Inpatient_Transfers 
WHERE EndDate IS NULL;

IF @HospitalizedPatientID IS NOT NULL
BEGIN
    EXEC sp_DischargePatient 
        @PatientID = @HospitalizedPatientID,
        @DischargeDate = '2026-07-15 14:00:00',
        @Success = @SuccessDischarge OUTPUT;
        
    SELECT @SuccessDischarge AS IsSuccess, 'Patient successfully discharged.' AS Message, @HospitalizedPatientID AS PatientID;
END
ELSE
BEGIN
    PRINT 'No currently hospitalized patients found to discharge.';
END;
GO

-- =============================================
-- Test 9: Generate Invoice for Patient 1
-- =============================================
DECLARE @NewGeneratedInvoiceID INT;

EXEC sp_GenerateInvoice 
    @PatientID = 1,
    @InvoiceID = @NewGeneratedInvoiceID OUTPUT;

SELECT @NewGeneratedInvoiceID AS GeneratedInvoiceID, 'Invoice successfully generated.' AS Message;
GO

-- =====================================================
-- Procedure 10: sp_UpdatePatient (ویرایش اطلاعات بیمار)
-- =====================================================
DROP PROCEDURE IF EXISTS sp_UpdatePatient;
GO
CREATE PROCEDURE sp_UpdatePatient
    @PatientID INT,
    @NationalID VARCHAR(10),
    @FirstName NVARCHAR(50),
    @LastName NVARCHAR(50),
    @Gender VARCHAR(10),
    @DOB DATE,
    @Phone VARCHAR(15) = NULL,
    @Address NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- چک کردن وجود بیمار
    IF NOT EXISTS (SELECT 1 FROM Patients WHERE PatientID = @PatientID)
    BEGIN
        RAISERROR('Patient not found.', 16, 1);
        RETURN;
    END;

    -- چک کردن تکراری نبودن شماره ملی (به جز خود بیمار)
    IF EXISTS (SELECT 1 FROM Patients WHERE NationalID = @NationalID AND PatientID != @PatientID)
    BEGIN
        RAISERROR('This National ID is already registered to another patient.', 16, 1);
        RETURN;
    END;

    -- بروزرسانی اطلاعات بیمار
    UPDATE Patients
    SET 
        NationalID = @NationalID,
        FirstName = @FirstName,
        LastName = @LastName,
        Gender = @Gender,
        DOB = @DOB,
        Phone = @Phone,
        Address = @Address
    WHERE PatientID = @PatientID;

    SELECT @PatientID AS PatientID, 'Patient information successfully updated.' AS Message;
END;
GO

-- =====================================================
-- Procedure 11: sp_AddMedicalHistory (ثبت سابقه پزشکی)
-- =====================================================
DROP PROCEDURE IF EXISTS sp_AddMedicalHistory;
GO

CREATE PROCEDURE sp_AddMedicalHistory
    @PatientID INT,
    @ICD_Code VARCHAR(20),
    @Diagnosis NVARCHAR(MAX),
    @MedicationHistory NVARCHAR(MAX) = NULL,
    @SmokingHistory VARCHAR(20) = NULL,
    @Height_cm DECIMAL(5,2) = NULL,
    @Weight_kg DECIMAL(5,2) = NULL,
    @BloodPressure VARCHAR(20) = NULL,
    @RecordDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- چک کردن وجود بیمار
    IF NOT EXISTS (SELECT 1 FROM Patients WHERE PatientID = @PatientID)
    BEGIN
        RAISERROR('Patient not found.', 16, 1);
        RETURN;
    END;
    
    -- گرفتن RecordID از Medical_Records
    DECLARE @RecordID INT;
    SELECT @RecordID = RecordID FROM Medical_Records WHERE PatientID = @PatientID;
    
    -- اگه RecordID نبود، بساز
    IF @RecordID IS NULL
    BEGIN
        INSERT INTO Medical_Records (PatientID) VALUES (@PatientID);
        SET @RecordID = SCOPE_IDENTITY();
    END;
    
    -- ثبت سابقه پزشکی
    INSERT INTO Medical_History (
        RecordID, ICD_Code, Diagnosis, MedicationHistory, 
        SmokingHistory, Height_cm, Weight_kg, BloodPressure, RecordDate
    )
    VALUES (
        @RecordID, @ICD_Code, @Diagnosis, @MedicationHistory,
        @SmokingHistory, @Height_cm, @Weight_kg, @BloodPressure,
        ISNULL(@RecordDate, GETDATE())
    );
    
    SELECT SCOPE_IDENTITY() AS HistoryID, 'Medical history successfully added.' AS Message;
END;
GO

-- =====================================================
-- Procedure 12: sp_PrescribeMedicine (تجویز دارو)
-- =====================================================
DROP PROCEDURE IF EXISTS sp_PrescribeMedicine;
GO

CREATE PROCEDURE sp_PrescribeMedicine
    @PatientID INT,
    @StaffID INT,
    @ItemID INT,
    @Quantity INT,
    @PrescriptionID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- چک کردن وجود بیمار
    IF NOT EXISTS (SELECT 1 FROM Patients WHERE PatientID = @PatientID)
    BEGIN
        RAISERROR('Patient not found.', 16, 1);
        RETURN;
    END;
    
    -- چک کردن وجود پزشک
    IF NOT EXISTS (SELECT 1 FROM Staff WHERE StaffID = @StaffID AND Role = 'Doctor')
    BEGIN
        RAISERROR('Doctor not found.', 16, 1);
        RETURN;
    END;
    
    -- چک کردن وجود دارو
    IF NOT EXISTS (SELECT 1 FROM Inventory_Items WHERE ItemID = @ItemID AND ItemType = 'Medicine')
    BEGIN
        RAISERROR('Medicine not found.', 16, 1);
        RETURN;
    END;
    
    -- چک کردن موجودی دارو
    DECLARE @CurrentStock INT;
    SELECT @CurrentStock = CurrentStock FROM Inventory_Items WHERE ItemID = @ItemID;
    
    IF @CurrentStock < @Quantity
    BEGIN
        RAISERROR('Insufficient stock. Available: %d, Required: %d', 16, 1, @CurrentStock, @Quantity);
        RETURN;
    END;
    
    BEGIN TRANSACTION;
    
    -- ثبت نسخه
    INSERT INTO Prescriptions (PatientID, StaffID, IssueDate)
    VALUES (@PatientID, @StaffID, GETDATE());
    
    SET @PrescriptionID = SCOPE_IDENTITY();
    
    -- ثبت آیتم‌های نسخه
    INSERT INTO Prescription_Items (PrescriptionID, ItemID, Quantity)
    VALUES (@PrescriptionID, @ItemID, @Quantity);
    
    -- کم کردن موجودی
    UPDATE Inventory_Items
    SET CurrentStock = CurrentStock - @Quantity
    WHERE ItemID = @ItemID;
    
    COMMIT TRANSACTION;
    
    SELECT @PrescriptionID AS PrescriptionID, 'Prescription successfully added.' AS Message;
END;
GO

-- =====================================================
-- Procedure 13: sp_RequestLabTest (درخواست آزمایش - نسخه نهایی)
-- =====================================================
DROP PROCEDURE IF EXISTS sp_RequestLabTest;
GO

CREATE PROCEDURE sp_RequestLabTest
    @PatientID INT,
    @StaffID INT,
    @TestType NVARCHAR(100),
    @DepartmentID INT = NULL,
    @ResultID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- چک کردن وجود بیمار
    IF NOT EXISTS (SELECT 1 FROM Patients WHERE PatientID = @PatientID)
    BEGIN
        RAISERROR('Patient not found.', 16, 1);
        RETURN;
    END;
    
    -- چک کردن وجود پزشک
    IF NOT EXISTS (SELECT 1 FROM Staff WHERE StaffID = @StaffID AND Role = 'Doctor')
    BEGIN
        RAISERROR('Doctor not found.', 16, 1);
        RETURN;
    END;
    
    -- اگر DepartmentID داده نشده، از دپارتمان آزمایشگاه استفاده کن
    IF @DepartmentID IS NULL
    BEGIN
        SELECT TOP 1 @DepartmentID = DepartmentID 
        FROM Departments 
        WHERE DeptName LIKE '%Lab%' OR DeptName LIKE '%آزمایش%';
        
        -- اگر باز هم DepartmentID پیدا نشد، از دپارتمان پیش‌فرض (1) استفاده کن
        IF @DepartmentID IS NULL
        BEGIN
            SET @DepartmentID = 1;
        END;
    END;
    
    -- ثبت درخواست آزمایش
    INSERT INTO Lab_Results (PatientID, StaffID, DepartmentID, TestType, Status, TestDate)
    VALUES (@PatientID, @StaffID, @DepartmentID, @TestType, 'Requested', GETDATE());
    
    SET @ResultID = SCOPE_IDENTITY();
    
    SELECT @ResultID AS ResultID, 'Lab test request successfully added.' AS Message;
END;
GO

-- =====================================================
-- Procedure 14: sp_GetPendingLabRequests (دریافت درخواست‌های معلق)
-- =====================================================
DROP PROCEDURE IF EXISTS sp_GetPendingLabRequests;
GO

CREATE PROCEDURE sp_GetPendingLabRequests
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        lr.ResultID,
        p.FirstName + ' ' + p.LastName AS PatientName,
        p.NationalID,
        s.FirstName + ' ' + s.LastName AS DoctorName,
        lr.TestType,
        lr.TestDate AS RequestDate,
        lr.Status
    FROM Lab_Results lr
    JOIN Patients p ON lr.PatientID = p.PatientID
    JOIN Staff s ON lr.StaffID = s.StaffID
    WHERE lr.Status = 'Requested'
    ORDER BY lr.TestDate ASC;
END;
GO
--------------------------------------------
USE HospitalDB;
GO

DROP PROCEDURE IF EXISTS sp_GenerateConsolidatedInvoice;
GO

CREATE PROCEDURE sp_GenerateConsolidatedInvoice
    @PatientID INT,
    @InvoiceID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @BedCost DECIMAL(18,2) = 0;
    DECLARE @MedCost DECIMAL(18,2) = 0;
    DECLARE @LabCost DECIMAL(18,2) = 0;
    DECLARE @TotalAmount DECIMAL(18,2) = 0;
    DECLARE @InsuranceShare DECIMAL(18,2) = 0;
    DECLARE @PatientShare DECIMAL(18,2) = 0;
    
    -- محاسبه هزینه بستری
    SELECT @BedCost = ISNULL(SUM(DATEDIFF(DAY, StartDate, ISNULL(EndDate, GETDATE())) * 50000.00), 0)
    FROM Inpatient_Transfers
    WHERE PatientID = @PatientID;
    
    -- محاسبه هزینه داروها
    SELECT @MedCost = ISNULL(SUM(pi.Quantity * 10000.00), 0)
    FROM Prescription_Items pi
    JOIN Prescriptions p ON pi.PrescriptionID = p.PrescriptionID
    WHERE p.PatientID = @PatientID;
    
    -- محاسبه هزینه آزمایش‌ها
    SELECT @LabCost = ISNULL(COUNT(*) * 30000.00, 0)
    FROM Lab_Results
    WHERE PatientID = @PatientID AND Status = 'Completed';
    
    SET @TotalAmount = @BedCost + @MedCost + @LabCost;
    
    IF @TotalAmount = 0
    BEGIN
        RAISERROR('No services or hospitalization found to bill for this patient.', 16, 1);
        RETURN;
    END;
    
    SET @InsuranceShare = @TotalAmount * 0.70;
    SET @PatientShare = @TotalAmount - @InsuranceShare;
    
    -- ثبت فاکتور جدید
    INSERT INTO Invoices (PatientID, TotalAmount, InsuranceShare, PatientShare, Status)
    VALUES (@PatientID, @TotalAmount, @InsuranceShare, @PatientShare, 'Pending');
    
    SET @InvoiceID = SCOPE_IDENTITY();
    
    SELECT 
        @InvoiceID AS InvoiceID, 
        'Consolidated invoice generated successfully.' AS Message,
        @TotalAmount AS TotalAmount,
        @InsuranceShare AS InsuranceShare,
        @PatientShare AS PatientShare,
        @BedCost AS BedCost,
        @MedCost AS MedCost,
        @LabCost AS LabCost;
END;
GO




USE HospitalDB;
GO

-- =====================================================
-- Procedure 16: sp_GenerateConsolidatedInvoice
-- =====================================================
DROP PROCEDURE IF EXISTS sp_GenerateConsolidatedInvoice;
GO

CREATE PROCEDURE sp_GenerateConsolidatedInvoice
    @PatientID INT,
    @InvoiceID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @BedCost DECIMAL(18,2) = 0;
    DECLARE @MedCost DECIMAL(18,2) = 0;
    DECLARE @LabCost DECIMAL(18,2) = 0;
    DECLARE @TotalAmount DECIMAL(18,2) = 0;
    DECLARE @InsuranceShare DECIMAL(18,2) = 0;
    DECLARE @PatientShare DECIMAL(18,2) = 0;
    
    -- محاسبه هزینه بستری
    SELECT @BedCost = ISNULL(SUM(DATEDIFF(DAY, StartDate, ISNULL(EndDate, GETDATE())) * 50000.00), 0)
    FROM Inpatient_Transfers
    WHERE PatientID = @PatientID;
    
    -- محاسبه هزینه داروها
    SELECT @MedCost = ISNULL(SUM(pi.Quantity * 10000.00), 0)
    FROM Prescription_Items pi
    JOIN Prescriptions p ON pi.PrescriptionID = p.PrescriptionID
    WHERE p.PatientID = @PatientID;
    
    -- محاسبه هزینه آزمایش‌ها
    SELECT @LabCost = ISNULL(COUNT(*) * 30000.00, 0)
    FROM Lab_Results
    WHERE PatientID = @PatientID AND Status = 'Completed';
    
    SET @TotalAmount = @BedCost + @MedCost + @LabCost;
    
    IF @TotalAmount = 0
    BEGIN
        RAISERROR('No services or hospitalization found to bill for this patient.', 16, 1);
        RETURN;
    END;
    
    SET @InsuranceShare = @TotalAmount * 0.70;
    SET @PatientShare = @TotalAmount - @InsuranceShare;
    
    -- ثبت فاکتور جدید
    INSERT INTO Invoices (PatientID, TotalAmount, InsuranceShare, PatientShare, Status)
    VALUES (@PatientID, @TotalAmount, @InsuranceShare, @PatientShare, 'Pending');
    
    SET @InvoiceID = SCOPE_IDENTITY();
    
    SELECT 
        @InvoiceID AS InvoiceID, 
        'Consolidated invoice generated successfully.' AS Message,
        @TotalAmount AS TotalAmount,
        @InsuranceShare AS InsuranceShare,
        @PatientShare AS PatientShare,
        @BedCost AS BedCost,
        @MedCost AS MedCost,
        @LabCost AS LabCost;
END;
GO

