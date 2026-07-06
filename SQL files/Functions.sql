-- =====================================================
-- Function1:  GetPatientFullName 
-- =====================================================
USE HospitalDB;
GO

CREATE FUNCTION fn_GetPatientFullName(@PatientID INT)
RETURNS NVARCHAR(101)
AS
BEGIN
    DECLARE @FullName NVARCHAR(101);
    
    SELECT @FullName = FirstName + ' ' + LastName
    FROM Patients
    WHERE PatientID = @PatientID;
    
    RETURN @FullName;
END;
GO

-- =====================================================
-- Function2: CalculatePatientAge 
-- =====================================================
USE HospitalDB;
GO

CREATE FUNCTION fn_CalculatePatientAge(@PatientID INT)
RETURNS INT
AS
BEGIN
    DECLARE @Age INT;
    DECLARE @DOB DATE;
    
    SELECT @DOB = DOB
    FROM Patients
    WHERE PatientID = @PatientID;
    
    SET @Age = DATEDIFF(YEAR, @DOB, GETDATE());
    
    IF (MONTH(@DOB) > MONTH(GETDATE())) OR 
       (MONTH(@DOB) = MONTH(GETDATE()) AND DAY(@DOB) > DAY(GETDATE()))
    BEGIN
        SET @Age = @Age - 1;
    END;
    
    RETURN @Age;
END;
GO

-- =====================================================
-- Function3: GetBedAvailability 
-- =====================================================
USE HospitalDB;
GO

CREATE FUNCTION fn_GetBedAvailability(@DepartmentID INT)
RETURNS INT
AS
BEGIN
    DECLARE @AvailableBeds INT;
    
    SELECT @AvailableBeds = COUNT(*)
    FROM Beds
    WHERE DepartmentID = @DepartmentID
      AND Status = 'Available';
    
    RETURN @AvailableBeds;
END;
GO

-- =====================================================
-- Function4: GetTotalPatientPayments 
-- =====================================================
USE HospitalDB;
GO

CREATE FUNCTION fn_GetTotalPatientPayments(@PatientID INT)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @TotalPayments DECIMAL(18,2);
    
    SELECT @TotalPayments = SUM(p.Amount)
    FROM Payments p
    JOIN Invoices i ON p.InvoiceID = i.InvoiceID
    WHERE i.PatientID = @PatientID;
    
    RETURN ISNULL(@TotalPayments, 0);
END;
GO

-- =====================================================
-- Function5: GetPatientBalance 
-- =====================================================
USE HospitalDB;
GO

CREATE FUNCTION fn_GetPatientBalance(@PatientID INT)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @Balance DECIMAL(18,2);
    
    SELECT @Balance = 
        (SELECT ISNULL(SUM(i.PatientShare), 0) FROM Invoices i WHERE i.PatientID = @PatientID AND i.Status = 'Pending')
        - 
        (SELECT ISNULL(SUM(p.Amount), 0) FROM Payments p JOIN Invoices i ON p.InvoiceID = i.InvoiceID WHERE i.PatientID = @PatientID);
    
    RETURN ISNULL(@Balance, 0);
END;
GO

-- =====================================================
-- Function6: GetDoctorAppointmentCount 
-- =====================================================
USE HospitalDB;
GO

CREATE FUNCTION fn_GetDoctorAppointmentCount(
    @StaffID INT,
    @StartDate DATE,
    @EndDate DATE
)
RETURNS INT
AS
BEGIN
    DECLARE @Count INT;
    
    SELECT @Count = COUNT(*)
    FROM Appointments
    WHERE StaffID = @StaffID
      AND CAST(ApptDate AS DATE) BETWEEN @StartDate AND @EndDate
      AND Status != 'Cancelled';   
    
    RETURN @Count;
END;
GO

-- =====================================================
-- Function7: GetDepartmentBedOccupancyRate 
-- =====================================================
USE HospitalDB;
GO

CREATE FUNCTION fn_GetDepartmentBedOccupancyRate(@DepartmentID INT)
RETURNS DECIMAL(5,2)
AS
BEGIN
    DECLARE @TotalBeds INT;
    DECLARE @OccupiedBeds INT;
    DECLARE @OccupancyRate DECIMAL(5,2);
    
    SELECT @TotalBeds = COUNT(*) FROM Beds WHERE DepartmentID = @DepartmentID;
    SELECT @OccupiedBeds = COUNT(*) FROM Beds WHERE DepartmentID = @DepartmentID AND Status = 'Occupied';
    
    IF @TotalBeds = 0
        SET @OccupancyRate = 0;
    ELSE
        SET @OccupancyRate = (@OccupiedBeds * 100.0) / @TotalBeds;
    
    RETURN @OccupancyRate;
END;
GO

-- =====================================================
-- Function8: GetCriticalLabResults 
-- =====================================================
USE HospitalDB;
GO

CREATE FUNCTION fn_GetCriticalLabResults(@PatientID INT)
RETURNS INT
AS
BEGIN
    DECLARE @CriticalCount INT;
    
    SELECT @CriticalCount = COUNT(*)
    FROM Lab_Results
    WHERE PatientID = @PatientID
      AND IsCritical = 1;
    
    RETURN @CriticalCount;
END;
GO

-- =====================================================
-- Function9: GetInventoryItemStock 
-- =====================================================
USE HospitalDB;
GO

CREATE FUNCTION fn_GetInventoryItemStock(@ItemID INT)
RETURNS INT
AS
BEGIN
    DECLARE @Stock INT;
    
    SELECT @Stock = CurrentStock
    FROM Inventory_Items
    WHERE ItemID = @ItemID;
    
    RETURN @Stock;
END;
GO

-- =====================================================
-- Function10: GetTotalAppointmentsPerDay 
-- =====================================================
USE HospitalDB;
GO

CREATE FUNCTION fn_GetTotalAppointmentsPerDay(@Date DATE)
RETURNS INT
AS
BEGIN
    DECLARE @Total INT;
    
    SELECT @Total = COUNT(*)
    FROM Appointments
    WHERE CAST(ApptDate AS DATE) = @Date
      AND Status != 'Cancelled';  
    
    RETURN @Total;
END;
GO

-- =====================================================
-- Function11: GetActiveIoTDevicesCount 
-- =====================================================
USE HospitalDB;
GO

CREATE FUNCTION fn_GetActiveIoTDevicesCount()
RETURNS INT
AS
BEGIN
    DECLARE @ActiveCount INT;
    
    SELECT @ActiveCount = COUNT(*)
    FROM IoT_Devices
    WHERE Status = 'Active';
    
    RETURN @ActiveCount;
END;
GO

-- =====================================================
-- Function12: GetUncheckedAlertsCount 
-- =====================================================
USE HospitalDB;
GO

CREATE FUNCTION fn_GetUncheckedAlertsCount()
RETURNS INT
AS
BEGIN
    DECLARE @UncheckedCount INT;
    
    SELECT @UncheckedCount = COUNT(*)
    FROM Alerts
    WHERE Status = 'Unchecked';
    
    RETURN @UncheckedCount;
END;
GO

-- =====================================================
-- Function13: GetPatientAdmissionHistory 
-- =====================================================
USE HospitalDB;
GO

CREATE FUNCTION fn_GetPatientAdmissionHistory(@PatientID INT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @History NVARCHAR(MAX);
    
    SELECT @History = STRING_AGG(
        'Section: ' + d.DeptName + ' | Bed: ' + CAST(b.BedID AS VARCHAR) + 
        ' | from: ' + CAST(it.StartDate AS VARCHAR) + ' | until: ' + ISNULL(CAST(it.EndDate AS VARCHAR), 'Currently hospitalized'),
        CHAR(13) + CHAR(10)
    )
    FROM Inpatient_Transfers it
    JOIN Beds b ON it.BedID = b.BedID
    JOIN Departments d ON b.DepartmentID = d.DepartmentID
    WHERE it.PatientID = @PatientID;
    
    RETURN ISNULL(@History, 'No hospitalization history found.');
END;
GO

-- =====================================================
-- Function14: GetPrescriptionDetails 
-- =====================================================
USE HospitalDB;
GO

CREATE FUNCTION fn_GetPrescriptionDetails(@PrescriptionID INT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @Details NVARCHAR(MAX);
    
    SELECT @Details = STRING_AGG(
        ii.ItemName + ' (Quantity: ' + CAST(pi.Quantity AS VARCHAR) + ')',
        ', '
    )
    FROM Prescription_Items pi
    JOIN Inventory_Items ii ON pi.ItemID = ii.ItemID
    WHERE pi.PrescriptionID = @PrescriptionID;
    
    RETURN ISNULL(@Details, 'No copies found.');
END;
GO

-- =====================================================
-- Function15: GetDepartmentFullInfo 
-- =====================================================
USE HospitalDB;
GO

CREATE FUNCTION fn_GetDepartmentFullInfo(@DepartmentID INT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @Info NVARCHAR(MAX);
    DECLARE @DeptName NVARCHAR(100);
    DECLARE @TotalBeds INT;
    DECLARE @AvailableBeds INT;
    DECLARE @OccupiedBeds INT;
    
    SELECT @DeptName = DeptName FROM Departments WHERE DepartmentID = @DepartmentID;
    SELECT @TotalBeds = COUNT(*) FROM Beds WHERE DepartmentID = @DepartmentID;
    SELECT @AvailableBeds = COUNT(*) FROM Beds WHERE DepartmentID = @DepartmentID AND Status = 'Available';
    SELECT @OccupiedBeds = COUNT(*) FROM Beds WHERE DepartmentID = @DepartmentID AND Status = 'Occupied';
    
    SET @Info = 'Section: ' + @DeptName + CHAR(13) + CHAR(10) +
                'Total beds: ' + CAST(@TotalBeds AS VARCHAR) + CHAR(13) + CHAR(10) +
                'Empty beds: ' + CAST(@AvailableBeds AS VARCHAR) + CHAR(13) + CHAR(10) +
                'Occupied beds: ' + CAST(@OccupiedBeds AS VARCHAR);
    
    RETURN @Info;
END;
GO

-- =====================================================
-- Function16: GetPendingInvoicesCount
-- =====================================================
USE HospitalDB;
GO

CREATE FUNCTION fn_GetPendingInvoicesCount()
RETURNS INT
AS
BEGIN
    DECLARE @PendingCount INT;
    
    SELECT @PendingCount = COUNT(*)
    FROM Invoices
    WHERE Status = 'Pending';
    
    RETURN @PendingCount;
END;
GO

-- =====================================================
-- Function17: GetLabRequestStatus 
-- =====================================================
USE HospitalDB;
GO

CREATE FUNCTION fn_GetLabRequestStatus(@ResultID INT)
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @Status NVARCHAR(50);
    
    SELECT @Status = Status
    FROM Lab_Results
    WHERE ResultID = @ResultID;
    
    RETURN ISNULL(@Status, 'Request not found.');
END;
GO

-- =====================================================
-- Function18: GetDrugInteractionCount 
-- =====================================================
USE HospitalDB;
GO

CREATE FUNCTION fn_GetDrugInteractionCount(@ItemID INT)
RETURNS INT
AS
BEGIN
    DECLARE @InteractionCount INT;
    
    SELECT @InteractionCount = COUNT(*)
    FROM Drug_Interactions
    WHERE DrugA_ID = @ItemID OR DrugB_ID = @ItemID;
    
    RETURN @InteractionCount;
END;
GO

-- =====================================================
-- Function19: GetPatientAppointmentHistory 
-- =====================================================
USE HospitalDB;
GO

CREATE FUNCTION fn_GetPatientAppointmentHistory(@PatientID INT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @History NVARCHAR(MAX);
    
    SELECT @History = STRING_AGG(
        'Date: ' + CAST(a.ApptDate AS VARCHAR) + 
        ' | Type: ' + a.ApptType + 
        ' | Status: ' + a.Status + 
        ISNULL(' | Doctor: ' + s.FirstName + ' ' + s.LastName, ''),
        CHAR(13) + CHAR(10)
    )
    FROM Appointments a
    LEFT JOIN Staff s ON a.StaffID = s.StaffID
    WHERE a.PatientID = @PatientID;
    
    RETURN ISNULL(@History, 'No appointment history found.');
END;
GO

-- =====================================================
-- Function20: GetStaffWorkload 
-- =====================================================
USE HospitalDB;
GO

CREATE FUNCTION fn_GetStaffWorkload(@StaffID INT)
RETURNS INT
AS
BEGIN
    DECLARE @Workload INT;
    
    SELECT @Workload = COUNT(*)
    FROM Appointments
    WHERE StaffID = @StaffID
      AND CAST(ApptDate AS DATE) = CAST(GETDATE() AS DATE)
      AND Status != 'Cancelled';
    
    RETURN @Workload;
END;
GO

-- =====================================================
-- Function21: GetInventoryTurnover 
-- =====================================================
USE HospitalDB;
GO

CREATE FUNCTION fn_GetInventoryTurnover(@ItemID INT)
RETURNS INT
AS
BEGIN
    DECLARE @TotalOutbound INT;
    
    SELECT @TotalOutbound = SUM(Quantity)
    FROM Inventory_Transactions
    WHERE ItemID = @ItemID
      AND TransactionType = 'Outbound';
    
    RETURN ISNULL(@TotalOutbound, 0);
END;
GO

-- =====================================================
-- Function22: GetPatientInsuranceCoverage
-- =====================================================
USE HospitalDB;
GO

CREATE FUNCTION fn_GetPatientInsuranceCoverage(@PatientID INT)
RETURNS DECIMAL(5,2)
AS
BEGIN
    DECLARE @Coverage DECIMAL(5,2);
    
    SELECT @Coverage = AVG((InsuranceShare * 100.0) / TotalAmount)
    FROM Invoices
    WHERE PatientID = @PatientID
      AND TotalAmount > 0;
    
    RETURN ISNULL(@Coverage, 0);
END;
GO

-- =====================================================
-- Function23: GetAvailableBedsForDepartment 
-- =====================================================
USE HospitalDB;
GO

CREATE FUNCTION fn_GetAvailableBedsForDepartment(@DepartmentID INT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @BedList NVARCHAR(MAX);
    
    SELECT @BedList = STRING_AGG('Bed number ' + CAST(BedID AS VARCHAR), ', ')
    FROM Beds
    WHERE DepartmentID = @DepartmentID
      AND Status = 'Available';
    
    RETURN ISNULL(@BedList, 'There are no empty beds available.');
END;
GO


/*
-- =====================================================
-- delete functions
-- =====================================================
USE HospitalDB;
GO

DROP FUNCTION IF EXISTS fn_GetPatientFullName;
DROP FUNCTION IF EXISTS fn_CalculatePatientAge;
DROP FUNCTION IF EXISTS fn_GetBedAvailability;
DROP FUNCTION IF EXISTS fn_GetTotalPatientPayments;
DROP FUNCTION IF EXISTS fn_GetPatientBalance;
DROP FUNCTION IF EXISTS fn_GetDoctorAppointmentCount;
DROP FUNCTION IF EXISTS fn_GetDepartmentBedOccupancyRate;
DROP FUNCTION IF EXISTS fn_GetCriticalLabResults;
DROP FUNCTION IF EXISTS fn_GetInventoryItemStock;
DROP FUNCTION IF EXISTS fn_GetTotalAppointmentsPerDay;
DROP FUNCTION IF EXISTS fn_GetActiveIoTDevicesCount;
DROP FUNCTION IF EXISTS fn_GetUncheckedAlertsCount;
DROP FUNCTION IF EXISTS fn_GetPatientAdmissionHistory;
DROP FUNCTION IF EXISTS fn_GetPrescriptionDetails;
DROP FUNCTION IF EXISTS fn_GetDepartmentFullInfo;
DROP FUNCTION IF EXISTS fn_GetPendingInvoicesCount;
DROP FUNCTION IF EXISTS fn_GetLabRequestStatus;
DROP FUNCTION IF EXISTS fn_GetDrugInteractionCount;
DROP FUNCTION IF EXISTS fn_GetPatientAppointmentHistory;
DROP FUNCTION IF EXISTS fn_GetStaffWorkload;
DROP FUNCTION IF EXISTS fn_GetInventoryTurnover;
DROP FUNCTION IF EXISTS fn_GetPatientInsuranceCoverage;
DROP FUNCTION IF EXISTS fn_GetAvailableBedsForDepartment;
GO*/