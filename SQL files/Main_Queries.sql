-- =====================================================
-- Query0: Teds
-- =====================================================
USE HospitalDB;
SELECT * FROM Beds;

-- =====================================================
-- Query1: Full Patient List
-- =====================================================
USE HospitalDB;
GO
SELECT * FROM Patients;

-- =====================================================
-- Query2: Search Patient by National ID
-- =====================================================
USE HospitalDB;
GO
SELECT * FROM Patients WHERE NationalID = '1234567890';

-- =====================================================
-- Query3:  Patient Medical History
-- =====================================================
USE HospitalDB;
GO
SELECT 
    p.PatientID,
    p.FirstName,
    p.LastName,
    mh.ICD_Code,
    mh.Diagnosis,
    mh.MedicationHistory,
    mh.SmokingHistory,
    mh.Height_cm,
    mh.Weight_kg,
    mh.BloodPressure,
    mh.RecordDate
FROM Patients p
JOIN Medical_Records mr ON p.PatientID = mr.PatientID
JOIN Medical_History mh ON mr.RecordID = mh.RecordID
WHERE p.PatientID = 1; 

-- =====================================================
-- Query4: Patients with Specific Diagnosis (by ICD_Code)
-- =====================================================
USE HospitalDB;
GO
SELECT 
    p.PatientID,
    p.FirstName,
    p.LastName,
    mh.ICD_Code,
    mh.Diagnosis
FROM Patients p
JOIN Medical_Records mr ON p.PatientID = mr.PatientID
JOIN Medical_History mh ON mr.RecordID = mh.RecordID
WHERE mh.ICD_Code = 'I10'; 

-- =====================================================
-- Query5: Patient Anthropometric Information (Latest Record)
-- =====================================================
USE HospitalDB;
GO
SELECT 
    p.PatientID,
    p.FirstName,
    p.LastName,
    mh.Height_cm,
    mh.Weight_kg,
    mh.BloodPressure,
    mh.RecordDate AS LastMeasurementDate
FROM Patients p
JOIN Medical_Records mr ON p.PatientID = mr.PatientID
JOIN Medical_History mh ON mr.RecordID = mh.RecordID
WHERE mh.RecordDate = (
    SELECT MAX(RecordDate) 
    FROM Medical_History mh2 
    JOIN Medical_Records mr2 ON mh2.RecordID = mr2.RecordID 
    WHERE mr2.PatientID = p.PatientID
);

-- =====================================================
-- Query6: Today's Appointments
-- =====================================================
USE HospitalDB;
GO
SELECT 
    a.AppointmentID,
    p.FirstName AS PatientFirstName,
    p.LastName AS PatientLastName,
    s.FirstName AS DoctorFirstName,
    s.LastName AS DoctorLastName,
    a.ApptDate,
    a.ApptType,
    a.Status
FROM Appointments a
JOIN Patients p ON a.PatientID = p.PatientID
LEFT JOIN Staff s ON a.StaffID = s.StaffID
WHERE CAST(a.ApptDate AS DATE) = CAST(GETDATE() AS DATE);

-- =====================================================
-- Query7: Appointments for a Specific Doctor
-- =====================================================
USE HospitalDB;
GO
SELECT 
    a.AppointmentID,
    p.FirstName AS PatientFirstName,
    p.LastName AS PatientLastName,
    a.ApptDate,
    a.ApptType,
    a.Status
FROM Appointments a
JOIN Patients p ON a.PatientID = p.PatientID
WHERE a.StaffID = 1;  

-- =====================================================
-- Query8: Cancelled Appointments in the Last Week
-- =====================================================
USE HospitalDB;
GO
SELECT 
    a.AppointmentID,
    p.FirstName AS PatientFirstName,
    p.LastName AS PatientLastName,
    s.FirstName AS DoctorFirstName,
    s.LastName AS DoctorLastName,
    a.ApptDate,
    a.Status
FROM Appointments a
JOIN Patients p ON a.PatientID = p.PatientID
LEFT JOIN Staff s ON a.StaffID = s.StaffID
WHERE a.Status = 'Cancelled'
  AND a.ApptDate >= DATEADD(WEEK, -1, GETDATE());

-- =====================================================
-- Query9:  Appointment Count by Department
-- =====================================================
USE HospitalDB;
GO
SELECT 
    d.DeptName,
    COUNT(a.AppointmentID) AS AppointmentCount
FROM Departments d
LEFT JOIN Appointments a ON d.DepartmentID = a.DepartmentID
GROUP BY d.DeptName
ORDER BY AppointmentCount DESC;

-- =====================================================
-- Query10: Bed Status by Department
-- =====================================================
USE HospitalDB;
GO
SELECT 
    d.DeptName,
    b.BedID,
    b.Status
FROM Beds b
JOIN Departments d ON b.DepartmentID = d.DepartmentID
ORDER BY d.DeptName, b.BedID;

-- =====================================================
-- Query11: Currently Admitted Patients (EndDate IS NULL)
-- =====================================================
USE HospitalDB;
GO
SELECT 
    p.PatientID,
    p.FirstName,
    p.LastName,
    b.BedID,
    d.DeptName,
    it.StartDate
FROM Patients p
JOIN Inpatient_Transfers it ON p.PatientID = it.PatientID
JOIN Beds b ON it.BedID = b.BedID
JOIN Departments d ON b.DepartmentID = d.DepartmentID
WHERE it.EndDate IS NULL;

-- =====================================================
-- Query12: Patient Transfer History
-- =====================================================
USE HospitalDB;
GO
SELECT 
    it.TransferID,
    b.BedID,
    d.DeptName,
    it.StartDate,
    it.EndDate,
    DATEDIFF(DAY, it.StartDate, ISNULL(it.EndDate, GETDATE())) AS DaysAdmitted
FROM Inpatient_Transfers it
JOIN Beds b ON it.BedID = b.BedID
JOIN Departments d ON b.DepartmentID = d.DepartmentID
WHERE it.PatientID = 1  
ORDER BY it.StartDate DESC;

-- =====================================================
-- Query13: Admitted Patient Count by Department
-- =====================================================
USE HospitalDB;
GO
SELECT 
    d.DeptName,
    COUNT(DISTINCT it.PatientID) AS AdmittedPatients
FROM Departments d
JOIN Beds b ON d.DepartmentID = b.DepartmentID
JOIN Inpatient_Transfers it ON b.BedID = it.BedID
WHERE it.EndDate IS NULL
GROUP BY d.DeptName
ORDER BY AdmittedPatients DESC;

-- =====================================================
-- Query14: Today's Lab Requests (Status = 'Requested')
-- =====================================================
USE HospitalDB;
GO
SELECT 
    lr.ResultID,
    p.FirstName AS PatientFirstName,
    p.LastName AS PatientLastName,
    s.FirstName AS DoctorFirstName,
    s.LastName AS DoctorLastName,
    lr.TestType,
    lr.TestDate,
    lr.Status
FROM Lab_Results lr
JOIN Patients p ON lr.PatientID = p.PatientID
JOIN Staff s ON lr.StaffID = s.StaffID
WHERE lr.Status = 'Requested'
  AND CAST(lr.TestDate AS DATE) = CAST(GETDATE() AS DATE);

-- =====================================================
-- Query15: Critical Lab Results (IsCritical = 1)
-- =====================================================
USE HospitalDB;
GO
SELECT 
    lr.ResultID,
    p.FirstName AS PatientFirstName,
    p.LastName AS PatientLastName,
    lr.TestType,
    lr.ResultDetails,
    lr.TestDate
FROM Lab_Results lr
JOIN Patients p ON lr.PatientID = p.PatientID
WHERE lr.IsCritical = 1;

-- =====================================================
-- Query16: Lab Request Count by Department
-- =====================================================
USE HospitalDB;
GO
SELECT 
    d.DeptName,
    COUNT(lr.ResultID) AS LabRequestCount
FROM Departments d
LEFT JOIN Lab_Results lr ON d.DepartmentID = lr.DepartmentID
GROUP BY d.DeptName
ORDER BY LabRequestCount DESC;

-- =====================================================
-- Query17: Lab Results for a Specific Patient
-- =====================================================
USE HospitalDB;
GO
SELECT 
    lr.ResultID,
    s.FirstName AS DoctorFirstName,
    s.LastName AS DoctorLastName,
    lr.TestType,
    lr.ResultDetails,
    lr.IsCritical,
    lr.Status,
    lr.TestDate
FROM Lab_Results lr
JOIN Staff s ON lr.StaffID = s.StaffID
WHERE lr.PatientID = 1  
ORDER BY lr.TestDate DESC;

-- =====================================================
-- Query18: Prescriptions for a Specific Patient
-- =====================================================
USE HospitalDB;
GO
SELECT 
    pr.PrescriptionID,
    s.FirstName AS DoctorFirstName,
    s.LastName AS DoctorLastName,
    pr.IssueDate,
    pi.ItemID,
    ii.ItemName,
    pi.Quantity
FROM Prescriptions pr
JOIN Staff s ON pr.StaffID = s.StaffID
JOIN Prescription_Items pi ON pr.PrescriptionID = pi.PrescriptionID
JOIN Inventory_Items ii ON pi.ItemID = ii.ItemID
WHERE pr.PatientID = 1  
ORDER BY pr.IssueDate DESC;

-- =====================================================
-- Query19: Drug Interactions for a Specific Drug
-- =====================================================
USE HospitalDB;
GO
SELECT 
    di.InteractionID,
    ii1.ItemName AS DrugA,
    ii2.ItemName AS DrugB,
    di.Severity,
    di.Description
FROM Drug_Interactions di
JOIN Inventory_Items ii1 ON di.DrugA_ID = ii1.ItemID
JOIN Inventory_Items ii2 ON di.DrugB_ID = ii2.ItemID
WHERE di.DrugA_ID = 1 OR di.DrugB_ID = 1;  

-- =====================================================
-- Query20: Low Stock Medicines (CurrentStock < 50)
-- =====================================================
USE HospitalDB;
GO
SELECT 
    ItemID,
    ItemName,
    ItemType,
    CurrentStock
FROM Inventory_Items
WHERE ItemType = 'Medicine'
  AND CurrentStock < 50
ORDER BY CurrentStock ASC;

-- =====================================================
-- Query21: Full Inventory List
-- =====================================================
USE HospitalDB;
GO
SELECT 
    ItemID,
    ItemName,
    ItemType,
    CurrentStock
FROM Inventory_Items
ORDER BY ItemType, ItemName;

-- =====================================================
-- Query22: Transaction History for a Specific Item
-- =====================================================
USE HospitalDB;
GO
SELECT 
    TransactionID,
    TransactionType,
    Quantity,
    TransactionDate
FROM Inventory_Transactions
WHERE ItemID = 1  
ORDER BY TransactionDate DESC;

-- =====================================================
-- Query23: Inventory Transactions Report (Date Range)
-- =====================================================
USE HospitalDB;
GO
SELECT 
    ii.ItemName,
    it.TransactionType,
    it.Quantity,
    it.TransactionDate
FROM Inventory_Transactions it
JOIN Inventory_Items ii ON it.ItemID = ii.ItemID
WHERE it.TransactionDate BETWEEN '2026-07-01' AND '2026-07-10'  
ORDER BY it.TransactionDate;

-- =====================================================
-- Query24: Patient Invoices and Payments
-- =====================================================
USE HospitalDB;
GO
SELECT 
    i.InvoiceID,
    i.TotalAmount,
    i.InsuranceShare,
    i.PatientShare,
    i.Status,
    p.Amount AS PaidAmount,
    p.PaymentType,
    p.PaymentDate
FROM Invoices i
LEFT JOIN Payments p ON i.InvoiceID = p.InvoiceID
WHERE i.PatientID = 1  
ORDER BY i.InvoiceID;

-- =====================================================
-- Query25: Unpaid Invoices (Status = 'Pending')
-- =====================================================
USE HospitalDB;
GO
SELECT 
    i.InvoiceID,
    p.FirstName AS PatientFirstName,
    p.LastName AS PatientLastName,
    i.TotalAmount,
    i.InsuranceShare,
    i.PatientShare,
    i.Status
FROM Invoices i
JOIN Patients p ON i.PatientID = p.PatientID
WHERE i.Status = 'Pending';

-- =====================================================
-- Query26: Total Hospital Revenueن
-- =====================================================
USE HospitalDB;
GO
SELECT 
    SUM(TotalAmount) AS TotalRevenue,
    SUM(InsuranceShare) AS TotalInsurance,
    SUM(PatientShare) AS TotalPatientPayments
FROM Invoices;

-- =====================================================
-- Query27: Insurance vs Patient Share Breakdown
-- =====================================================
USE HospitalDB;
GO
SELECT 
    i.InvoiceID,
    p.FirstName AS PatientFirstName,
    p.LastName AS PatientLastName,
    i.TotalAmount,
    i.InsuranceShare AS InsuranceCoverage,
    i.PatientShare AS PatientPayment,
    CAST((i.InsuranceShare / i.TotalAmount) * 100 AS DECIMAL(5,2)) AS InsurancePercentage,
    CAST((i.PatientShare / i.TotalAmount) * 100 AS DECIMAL(5,2)) AS PatientPercentage
FROM Invoices i
JOIN Patients p ON i.PatientID = p.PatientID;

-- =====================================================
-- Query28: Active IoT Devices (Status = 'Active')
-- =====================================================
USE HospitalDB;
GO
SELECT 
    MAC_Address,
    DeviceType,
    Status,
    PatientID,
    BedID
FROM IoT_Devices
WHERE Status = 'Active';

-- =====================================================
-- Query29: Logs for a Specific IoT Device
-- =====================================================
USE HospitalDB;
GO
SELECT 
    LogID,
    MAC_Address,
    MetricType,
    MetricValue,
    Timestamp
FROM IoT_Logs
WHERE MAC_Address = 'AA:BB:CC:DD:EE:01'  
ORDER BY Timestamp DESC;

-- =====================================================
-- Query30: Unchecked Alerts (Status = 'Unchecked')
-- =====================================================
USE HospitalDB;
GO
SELECT 
    AlertID,
    Severity,
    Status,
    GeneratedAt,
    CASE 
        WHEN LogID IS NOT NULL THEN 'IoT Alert'
        WHEN ResultID IS NOT NULL THEN 'Lab Alert'
    END AS AlertSource
FROM Alerts
WHERE Status = 'Unchecked'
ORDER BY GeneratedAt DESC;

-- =====================================================
-- Query31: Critical Alerts (Severity = 'Critical')
-- =====================================================
USE HospitalDB;
GO
SELECT 
    AlertID,
    Severity,
    Status,
    GeneratedAt,
    ResolvedAt,
    s.FirstName AS ResponderFirstName,
    s.LastName AS ResponderLastName,
    CASE 
        WHEN LogID IS NOT NULL THEN 'IoT Alert'
        WHEN ResultID IS NOT NULL THEN 'Lab Alert'
    END AS AlertSource
FROM Alerts a
LEFT JOIN Staff s ON a.ResponderID = s.StaffID
WHERE a.Severity = 'Critical'
ORDER BY a.GeneratedAt DESC;