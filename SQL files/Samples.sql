/*-- =================================================================
-- 1. Patients (10 records)
-- =================================================================
INSERT INTO Patients (NationalID, FirstName, LastName, Gender, DOB, Phone, Address) VALUES
('1234567890', 'John', 'Doe', 'Male', '1980-01-15', '123-456-7890', '123 Main St, New York, NY 10001'),
('0987654321', 'Jane', 'Roe', 'Female', '1992-05-20', '234-567-8901', '456 Oak Ave, Los Angeles, CA 90001'),
('1122334455', 'Bob', 'Smith', 'Male', '1975-11-02', '345-678-9012', '789 Pine Rd, Chicago, IL 60601'),
('2233445566', 'Alice', 'Johnson', 'Female', '1988-07-18', '456-789-0123', '321 Elm St, Houston, TX 77001'),
('3344556677', 'Charlie', 'Brown', 'Male', '2000-12-25', '567-890-1234', '654 Maple Dr, Phoenix, AZ 85001'),
('4455667788', 'Diana', 'Prince', 'Female', '1995-03-01', '678-901-2345', '987 Cedar Ln, Philadelphia, PA 19101'),
('5566778899', 'Evan', 'Wright', 'Male', '1983-09-10', '789-012-3456', '147 Birch Blvd, San Antonio, TX 78201'),
('6677889900', 'Fiona', 'Davis', 'Female', '1979-06-22', '890-123-4567', '258 Walnut St, San Diego, CA 92101'),
('7788990011', 'George', 'Harris', 'Male', '1998-08-14', '901-234-5678', '369 Spruce Ave, Dallas, TX 75201'),
('8899001122', 'Helen', 'Clark', 'Female', '1990-04-30', '012-345-6789', '741 Ash Rd, San Jose, CA 95101');
GO*/

/*INSERT INTO Staff (FirstName, LastName, Role, Specialty, Phone) VALUES
('Adam', 'Hart', 'Doctor', 'Cardiology', '111-111-1111'),
('Bruce', 'Wayne', 'Doctor', 'Neurology', '222-222-2222'),
('Clark', 'Kent', 'Doctor', 'Orthopedics', '333-333-3333'),
('Diana', 'Troy', 'Doctor', 'Pediatrics', '444-444-4444'),
('Edward', 'Elric', 'Doctor', 'Emergency', '555-555-5555'),
('Nancy', 'Drew', 'Nurse', NULL, '666-666-6666'),
('Oliver', 'Twist', 'Nurse', NULL, '777-777-7777'),
('Peter', 'Parker', 'Nurse', NULL, '888-888-8888'),
('Tony', 'Stark', 'Admin', NULL, '999-999-9999'),
('Steve', 'Rogers', 'Admin', NULL, '101-101-1010');
GO*/

/*INSERT INTO Appointments (PatientID, StaffID, ApptDate, ApptType, Status) VALUES
(1, 1, '2026-07-15 09:00:00', 'InPerson', 'Scheduled'),
(2, 2, '2026-07-16 10:30:00', 'Online', 'Scheduled'),
(3, 3, '2026-07-17 11:00:00', 'InPerson', 'Cancelled'),
(4, 4, '2026-07-18 14:00:00', 'InPerson', 'Scheduled'),
(5, 5, '2026-07-19 15:30:00', 'Online', 'Rescheduled'),
(6, 1, '2026-07-20 09:30:00', 'InPerson', 'Scheduled'),
(7, 2, '2026-07-21 12:00:00', 'Online', 'Scheduled'),
(8, 3, '2026-07-22 16:00:00', 'InPerson', 'Cancelled'),
(9, 4, '2026-07-23 08:30:00', 'InPerson', 'Scheduled'),
(10, 5, '2026-07-24 13:00:00', 'Online', 'Scheduled');
GO*/

/*INSERT INTO Departments (DeptName) VALUES
('Cardiology'),
('Neurology'),
('Orthopedics'),
('Pediatrics'),
('Emergency'),
('Radiology'),
('Dermatology'),
('ENT'),
('Ophthalmology'),
('General Surgery');
GO*/

/*INSERT INTO Beds (DepartmentID, Status) VALUES
(1, 'Available'),
(2, 'Occupied'),
(3, 'Reserved'),
(4, 'Available'),
(5, 'Occupied'),
(6, 'Available'),
(7, 'Reserved'),
(8, 'Occupied'),
(9, 'Available'),
(10, 'Available');
GO*/

/*INSERT INTO Inpatient_Transfers (PatientID, BedID, StartDate, EndDate) VALUES
(1, 2, '2026-06-01 08:00:00', '2026-06-05 10:00:00'),
(2, 5, '2026-06-10 09:00:00', '2026-06-15 11:00:00'),
(3, 3, '2026-06-12 10:00:00', NULL),
(4, 8, '2026-06-15 11:00:00', '2026-06-20 12:00:00'),
(5, 1, '2026-06-18 12:00:00', NULL),
(6, 4, '2026-06-20 13:00:00', '2026-06-25 09:00:00'),
(7, 7, '2026-06-22 14:00:00', NULL),
(8, 2, '2026-06-25 15:00:00', '2026-06-30 16:00:00'),
(9, 5, '2026-06-28 08:00:00', NULL),
(10, 10, '2026-07-01 09:00:00', '2026-07-03 17:00:00');
GO*/

/*INSERT INTO Medical_Records (PatientID) VALUES
(1), (2), (3), (4), (5), (6), (7), (8), (9), (10);
GO*/

/*INSERT INTO Medical_History (RecordID, ICD_Code, Diagnosis, RecordDate) VALUES
(1, 'I10', 'Essential (primary) hypertension', '2026-01-10'),
(2, 'E11.9', 'Type 2 diabetes without complications', '2026-02-12'),
(3, 'J45.909', 'Unspecified asthma', '2026-03-15'),
(4, 'M17.9', 'Osteoarthritis of knee', '2026-04-01'),
(5, 'F32.9', 'Major depressive disorder', '2026-05-20'),
(6, 'I25.10', 'Atherosclerotic heart disease', '2026-06-11'),
(7, 'N18.9', 'Chronic kidney disease', '2026-06-22'),
(8, 'J06.9', 'Acute upper respiratory infection', '2026-07-01'),
(9, 'S06.9X9A', 'Intracranial injury', '2026-07-05'),
(10, 'L30.9', 'Unspecified dermatitis', '2026-07-07');
GO*/

/*INSERT INTO Lab_Results (PatientID, StaffID, TestType, ResultDetails, IsCritical, TestDate) VALUES
(1, 1, 'Blood Test', 'Cholesterol: 240, Triglycerides: 190', 0, '2026-07-01'),
(2, 2, 'MRI', 'No abnormalities detected in brain', 0, '2026-07-02'),
(3, 3, 'X-Ray', 'Fracture detected in right tibia', 1, '2026-07-03'),
(4, 4, 'Blood Test', 'Hemoglobin: 10.5 (Low), Platelets: 150', 1, '2026-07-04'),
(5, 5, 'ECG', 'Normal sinus rhythm', 0, '2026-07-05'),
(6, 1, 'Urine Test', 'Protein: 3+, Glucose: Negative', 0, '2026-07-06'),
(7, 2, 'CT Scan', 'Kidney stone found in left ureter', 1, '2026-07-07'),
(8, 3, 'Blood Test', 'WBC: 12000 (Elevated), CRP: 45', 0, '2026-07-08'),
(9, 4, 'Ultrasound', 'Gallbladder sludge', 0, '2026-07-09'),
(10, 5, 'Blood Test', 'Potassium: 5.8 (High), Sodium: 132', 1, '2026-07-10');
GO*/

/*INSERT INTO Inventory_Items (ItemName, ItemType, CurrentStock) VALUES
('Paracetamol 500mg', 'Medicine', 500),
('Ibuprofen 400mg', 'Medicine', 300),
('Amoxicillin 250mg', 'Medicine', 200),
('Blood Pressure Monitor', 'Equipment', 15),
('Disposable Syringe 5ml', 'Equipment', 1000),
('Bandage Roll', 'Equipment', 250),
('MRI Contrast Agent', 'Medicine', 50),
('Insulin Glargine', 'Medicine', 80),
('Ventilator Machine', 'Equipment', 10),
('Oxygen Cylinder', 'Equipment', 25);
GO*/

/*INSERT INTO Inventory_Transactions (ItemID, TransactionType, Quantity, TransactionDate) VALUES
(1, 'Inbound', 100, '2026-07-01 08:00:00'),
(2, 'Outbound', 50, '2026-07-02 09:00:00'),
(3, 'Inbound', 200, '2026-07-03 10:00:00'),
(4, 'Outbound', 2, '2026-07-04 11:00:00'),
(5, 'Inbound', 500, '2026-07-05 12:00:00'),
(6, 'Outbound', 30, '2026-07-06 13:00:00'),
(7, 'Inbound', 20, '2026-07-07 14:00:00'),
(8, 'Outbound', 10, '2026-07-08 15:00:00'),
(9, 'Inbound', 5, '2026-07-09 16:00:00'),
(10, 'Outbound', 3, '2026-07-10 17:00:00');
GO*/

/*INSERT INTO Prescriptions (PatientID, StaffID, IssueDate) VALUES
(1, 1, '2026-07-01'),
(2, 2, '2026-07-02'),
(3, 3, '2026-07-03'),
(4, 4, '2026-07-04'),
(5, 5, '2026-07-05'),
(6, 1, '2026-07-06'),
(7, 2, '2026-07-07'),
(8, 3, '2026-07-08'),
(9, 4, '2026-07-09'),
(10, 5, '2026-07-10');
GO*/

/*INSERT INTO Prescription_Items (PrescriptionID, ItemID, Quantity) VALUES
(1, 1, 30),
(2, 2, 20),
(3, 3, 15),
(4, 1, 40),
(5, 2, 25),
(6, 8, 10),
(7, 1, 60),
(8, 3, 14),
(9, 2, 30),
(10, 8, 5);
GO*/

/*INSERT INTO Drug_Interactions (DrugA_ID, DrugB_ID, Severity, Description) VALUES
(1, 2, 'Moderate', 'Increased risk of gastrointestinal bleeding'),
(1, 3, 'Critical', 'Potential allergic cross-reactivity'),
(2, 3, 'Moderate', 'Reduced efficacy of Amoxicillin'),
(3, 8, 'Critical', 'Severe hypoglycemia risk'),
(1, 8, 'Moderate', 'Masking of hypoglycemic symptoms'),
(2, 8, 'Moderate', 'Increased fluid retention'),
(3, 7, 'Critical', 'Nephrotoxicity risk'),
(1, 7, 'Moderate', 'Reduced renal clearance'),
(2, 7, 'Moderate', 'Hypertensive crisis'),
(8, 7, 'Critical', 'Severe hyperkalemia');
GO*/

/*INSERT INTO Invoices (PatientID, TotalAmount, InsuranceShare, PatientShare, Status) VALUES
(1, 2500.00, 1500.00, 1000.00, 'Pending'),
(2, 3200.00, 2000.00, 1200.00, 'Paid'),
(3, 4500.00, 3000.00, 1500.00, 'Pending'),
(4, 1800.00, 1000.00, 800.00, 'Paid'),
(5, 6700.00, 5000.00, 1700.00, 'Pending'),
(6, 2300.00, 1300.00, 1000.00, 'Paid'),
(7, 8900.00, 6000.00, 2900.00, 'Pending'),
(8, 1500.00, 800.00, 700.00, 'Paid'),
(9, 4200.00, 2800.00, 1400.00, 'Pending'),
(10, 3100.00, 2000.00, 1100.00, 'Paid');
GO*/

/*INSERT INTO Payments (InvoiceID, Amount, PaymentType, PaymentDate) VALUES
(1, 500.00, 'Deposit', '2026-07-01 09:00:00'),
(2, 1200.00, 'FullSettlement', '2026-07-02 10:00:00'),
(3, 700.00, 'Deposit', '2026-07-03 11:00:00'),
(4, 800.00, 'FullSettlement', '2026-07-04 12:00:00'),
(5, 1000.00, 'Deposit', '2026-07-05 13:00:00'),
(6, 1000.00, 'FullSettlement', '2026-07-06 14:00:00'),
(7, 1500.00, 'Deposit', '2026-07-07 15:00:00'),
(8, 700.00, 'FullSettlement', '2026-07-08 16:00:00'),
(9, 800.00, 'Deposit', '2026-07-09 17:00:00'),
(10, 1100.00, 'FullSettlement', '2026-07-10 18:00:00');
GO*/

/*INSERT INTO IoT_Devices (MAC_Address, DeviceType, Status, PatientID, BedID) VALUES
('AA:BB:CC:DD:EE:01', 'Vital Signs Band', 'Active', 1, 2),
('AA:BB:CC:DD:EE:02', 'Temperature Sensor', 'Active', 2, 5),
('AA:BB:CC:DD:EE:03', 'Vital Signs Band', 'Inactive', 3, 3),
('AA:BB:CC:DD:EE:04', 'Blood Pressure Monitor', 'Active', 4, 8),
('AA:BB:CC:DD:EE:05', 'Vital Signs Band', 'UnderMaintenance', 5, 1),
('AA:BB:CC:DD:EE:06', 'Temperature Sensor', 'Active', 6, 4),
('AA:BB:CC:DD:EE:07', 'Blood Pressure Monitor', 'Inactive', 7, 7),
('AA:BB:CC:DD:EE:08', 'Vital Signs Band', 'Active', 8, 2),
('AA:BB:CC:DD:EE:09', 'Temperature Sensor', 'Active', 9, 5),
('AA:BB:CC:DD:EE:10', 'Vital Signs Band', 'Active', 10, 10);
GO*/

//*INSERT INTO IoT_Logs (MAC_Address, MetricType, MetricValue, Timestamp) VALUES
('AA:BB:CC:DD:EE:01', 'HR', 72.5, '2026-07-10 08:00:00'),
('AA:BB:CC:DD:EE:02', 'Temperature', 36.6, '2026-07-10 08:05:00'),
('AA:BB:CC:DD:EE:03', 'HR', 110.0, '2026-07-10 08:10:00'),
('AA:BB:CC:DD:EE:04', 'BP_Systolic', 145.0, '2026-07-10 08:15:00'),
('AA:BB:CC:DD:EE:05', 'SpO2', 89.0, '2026-07-10 08:20:00'),
('AA:BB:CC:DD:EE:06', 'Temperature', 38.2, '2026-07-10 08:25:00'),
('AA:BB:CC:DD:EE:07', 'BP_Diastolic', 95.0, '2026-07-10 08:30:00'),
('AA:BB:CC:DD:EE:08', 'HR', 85.3, '2026-07-10 08:35:00'),
('AA:BB:CC:DD:EE:09', 'Temperature', 36.8, '2026-07-10 08:40:00'),
('AA:BB:CC:DD:EE:10', 'SpO2', 96.0, '2026-07-10 08:45:00');
GO*/

/*INSERT INTO Alerts (LogID, Severity, Status, GeneratedAt, ResolvedAt, ResponderID) VALUES
(1, 'Moderate', 'Acknowledged', '2026-07-10 08:02:00', '2026-07-10 08:10:00', 6),
(2, 'Moderate', 'Resolved', '2026-07-10 08:07:00', '2026-07-10 08:20:00', 7),
(3, 'Critical', 'Unchecked', '2026-07-10 08:12:00', NULL, NULL),
(4, 'Critical', 'Acknowledged', '2026-07-10 08:17:00', '2026-07-10 08:30:00', 8),
(5, 'Critical', 'Unchecked', '2026-07-10 08:22:00', NULL, NULL),
(6, 'Moderate', 'Resolved', '2026-07-10 08:27:00', '2026-07-10 08:35:00', 6),
(7, 'Critical', 'Acknowledged', '2026-07-10 08:32:00', '2026-07-10 08:45:00', 9),
(8, 'Moderate', 'Unchecked', '2026-07-10 08:37:00', NULL, NULL),
(9, 'Moderate', 'Resolved', '2026-07-10 08:42:00', '2026-07-10 08:50:00', 10),
(10, 'Moderate', 'Acknowledged', '2026-07-10 08:47:00', '2026-07-10 08:55:00', 7);
GO*/