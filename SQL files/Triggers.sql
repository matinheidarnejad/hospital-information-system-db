USE HospitalDB;
GO

-- =====================================================
-- Trigger 1: trg_UpdateStockOnPrescription
-- =====================================================
DROP TRIGGER IF EXISTS trg_UpdateStockOnPrescription;
GO
CREATE TRIGGER trg_UpdateStockOnPrescription
ON Prescription_Items
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ItemID INT;
    DECLARE @Quantity INT;
    DECLARE @CurrentStock INT;
    
    DECLARE PrescriptionCursor CURSOR FOR
    SELECT ItemID, Quantity
    FROM inserted;
    
    OPEN PrescriptionCursor;
    FETCH NEXT FROM PrescriptionCursor INTO @ItemID, @Quantity;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @CurrentStock = CurrentStock
        FROM Inventory_Items
        WHERE ItemID = @ItemID;
        
        IF @CurrentStock < @Quantity
        BEGIN
            RAISERROR('Insufficient stock for ItemID: %d. Available: %d, Required: %d', 16, 1, @ItemID, @CurrentStock, @Quantity);
            ROLLBACK TRANSACTION;
            RETURN;
        END;
        
        UPDATE Inventory_Items
        SET CurrentStock = CurrentStock - @Quantity
        WHERE ItemID = @ItemID;
        
        FETCH NEXT FROM PrescriptionCursor INTO @ItemID, @Quantity;
    END;
    
    CLOSE PrescriptionCursor;
    DEALLOCATE PrescriptionCursor;
END;
GO

-- =====================================================
-- Trigger 2: trg_LogInventoryTransaction
-- =====================================================
DROP TRIGGER IF EXISTS trg_LogInventoryTransaction;
GO
CREATE TRIGGER trg_LogInventoryTransaction
ON Inventory_Items
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF UPDATE(CurrentStock)
    BEGIN
        INSERT INTO Inventory_Transactions (ItemID, TransactionType, Quantity, TransactionDate)
        SELECT 
            i.ItemID,
            CASE 
                WHEN i.CurrentStock > d.CurrentStock THEN 'Inbound'
                WHEN i.CurrentStock < d.CurrentStock THEN 'Outbound'
                ELSE NULL
            END AS TransactionType,
            ABS(i.CurrentStock - d.CurrentStock) AS Quantity,
            GETDATE() AS TransactionDate
        FROM inserted i
        INNER JOIN deleted d ON i.ItemID = d.ItemID
        WHERE i.CurrentStock != d.CurrentStock;
    END;
END;
GO

-- =====================================================
-- Trigger 3: trg_PreventOverbooking
-- =====================================================
DROP TRIGGER IF EXISTS trg_PreventOverbooking;
GO
CREATE TRIGGER trg_PreventOverbooking
ON Appointments
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @PatientID INT;
    DECLARE @ApptDate DATETIME;
    DECLARE @StaffID INT;
    DECLARE @DepartmentID INT;
    DECLARE @ApptType VARCHAR(20);
    DECLARE @Status VARCHAR(20);
    
    DECLARE AppointmentCursor CURSOR FOR
    SELECT PatientID, ApptDate, StaffID, DepartmentID, ApptType, Status
    FROM inserted;
    
    OPEN AppointmentCursor;
    FETCH NEXT FROM AppointmentCursor INTO @PatientID, @ApptDate, @StaffID, @DepartmentID, @ApptType, @Status;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM Patients WHERE PatientID = @PatientID)
        BEGIN
            RAISERROR('Patient not found.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;
        
        IF @StaffID IS NULL AND @DepartmentID IS NULL
        BEGIN
            RAISERROR('At least one of StaffID or DepartmentID must be specified.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;
        
        IF EXISTS (
            SELECT 1 FROM Appointments 
            WHERE PatientID = @PatientID 
              AND CAST(ApptDate AS DATE) = CAST(@ApptDate AS DATE)
              AND Status IN ('Scheduled', 'Rescheduled')
        )
        BEGIN
            RAISERROR('Patient already has an active appointment on this date.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;
        
        INSERT INTO Appointments (PatientID, StaffID, DepartmentID, ApptDate, ApptType, Status)
        VALUES (@PatientID, @StaffID, @DepartmentID, @ApptDate, @ApptType, @Status);
        
        FETCH NEXT FROM AppointmentCursor INTO @PatientID, @ApptDate, @StaffID, @DepartmentID, @ApptType, @Status;
    END;
    
    CLOSE AppointmentCursor;
    DEALLOCATE AppointmentCursor;
END;
GO

-- =====================================================
-- Trigger 4: trg_CheckCriticalLabResult
-- =====================================================
DROP TRIGGER IF EXISTS trg_CheckCriticalLabResult;
GO
CREATE TRIGGER trg_CheckCriticalLabResult
ON Lab_Results
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF UPDATE(IsCritical) OR UPDATE(ResultDetails)
    BEGIN
        INSERT INTO Alerts (ResultID, Severity, Status, GeneratedAt)
        SELECT 
            i.ResultID,
            CASE 
                WHEN i.IsCritical = 1 THEN 'Critical'
                ELSE 'Moderate'
            END AS Severity,
            'Unchecked' AS Status,
            GETDATE() AS GeneratedAt
        FROM inserted i
        WHERE i.IsCritical = 1;
    END;
END;
GO

-- ==========================================================================================
-- tests
-- ==========================================================================================

-- =============================================
-- Test 1: trg_UpdateStockOnPrescription
-- =============================================
SELECT ItemID, ItemName, CurrentStock FROM Inventory_Items WHERE ItemID = 1;

INSERT INTO Prescription_Items (PrescriptionID, ItemID, Quantity)
VALUES (1, 1, 5);

SELECT ItemID, ItemName, CurrentStock FROM Inventory_Items WHERE ItemID = 1;
GO

-- =============================================
-- Test 2: trg_LogInventoryTransaction
-- =============================================

UPDATE Inventory_Items
SET CurrentStock = CurrentStock + 10
WHERE ItemID = 1;

SELECT * FROM Inventory_Transactions WHERE ItemID = 1 ORDER BY TransactionDate DESC;
GO

-- =============================================
-- Test 3: trg_PreventOverbooking
-- =============================================
INSERT INTO Appointments (PatientID, StaffID, DepartmentID, ApptDate, ApptType, Status)
VALUES (1, 1, NULL, '2026-07-15 09:00:00', 'InPerson', 'Scheduled');
GO

-- =============================================
-- Test 4: trg_CheckCriticalLabResult
-- =============================================
SELECT COUNT(*) AS AlertsBefore FROM Alerts;

UPDATE Lab_Results
SET IsCritical = 1, ResultDetails = 'Critical: Blood pressure 180/120'
WHERE ResultID = 5;

SELECT COUNT(*) AS AlertsAfter FROM Alerts;

SELECT * FROM Alerts ORDER BY GeneratedAt DESC;
GO