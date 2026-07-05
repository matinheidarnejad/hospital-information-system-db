-- =====================================================
-- Hospital Information System (HIS) - Complete Database Schema
-- =====================================================
/*
-- 1. Drop existing database if it exists (clean start)
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'HospitalDB')
DROP DATABASE HospitalDB;
GO

CREATE DATABASE HospitalDB;
GO

USE HospitalDB;
GO*/

-- =====================================================
-- Section 1: Core & People
-- =====================================================

CREATE TABLE Patients (
    PatientID INT PRIMARY KEY IDENTITY(1,1),
    NationalID VARCHAR(10) UNIQUE NOT NULL,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Gender VARCHAR(10) CHECK (Gender IN ('Male', 'Female')) NOT NULL,
    DOB DATE NOT NULL,
    Phone VARCHAR(15),
    Address NVARCHAR(200)
);
GO

CREATE TABLE Staff (
    StaffID INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Role VARCHAR(20) CHECK (Role IN ('Doctor', 'Nurse', 'Admin')) NOT NULL,
    Specialty NVARCHAR(100) NULL, -- Only for doctors
    Phone VARCHAR(15)
);
GO

CREATE TABLE Departments (
    DepartmentID INT PRIMARY KEY IDENTITY(1,1),
    DeptName NVARCHAR(100) NOT NULL
);
GO

-- =====================================================
-- Section 2: Admissions, Appointments & Beds
-- =====================================================

CREATE TABLE Appointments (
    AppointmentID INT PRIMARY KEY IDENTITY(1,1),
    PatientID INT NOT NULL FOREIGN KEY REFERENCES Patients(PatientID),
    StaffID INT NULL FOREIGN KEY REFERENCES Staff(StaffID),
    DepartmentID INT NULL FOREIGN KEY REFERENCES Departments(DepartmentID),
    ApptDate DATETIME NOT NULL,
    ApptType VARCHAR(20) CHECK (ApptType IN ('InPerson', 'Online')) NOT NULL,
    Status VARCHAR(20) CHECK (Status IN ('Scheduled', 'Cancelled', 'Rescheduled')) NOT NULL, 
    CONSTRAINT CK_Appt_Target CHECK (StaffID IS NOT NULL OR DepartmentID IS NOT NULL)
);
GO

CREATE TABLE Beds (
    BedID INT PRIMARY KEY IDENTITY(1,1),
    DepartmentID INT NOT NULL FOREIGN KEY REFERENCES Departments(DepartmentID),
    Status VARCHAR(20) CHECK (Status IN ('Available', 'Reserved', 'Occupied')) NOT NULL
);
GO

CREATE TABLE Inpatient_Transfers (
    TransferID INT PRIMARY KEY IDENTITY(1,1),
    PatientID INT NOT NULL FOREIGN KEY REFERENCES Patients(PatientID),
    BedID INT NOT NULL FOREIGN KEY REFERENCES Beds(BedID),
    StartDate DATETIME NOT NULL,
    EndDate DATETIME NULL
);
GO

-- =====================================================
-- Section 3: Clinical Records & Lab
-- =====================================================

*CREATE TABLE Medical_Records (
    RecordID INT PRIMARY KEY IDENTITY(1,1),
    PatientID INT NOT NULL UNIQUE FOREIGN KEY REFERENCES Patients(PatientID)
);
GO

CREATE TABLE Medical_History (
    HistoryID INT PRIMARY KEY IDENTITY(1,1),
    RecordID INT NOT NULL FOREIGN KEY REFERENCES Medical_Records(RecordID),
    ICD_Code VARCHAR(20) NOT NULL, 
    Diagnosis NVARCHAR(MAX) NOT NULL, 
    MedicationHistory NVARCHAR(MAX) NULL, 
    SmokingHistory VARCHAR(20) CHECK (SmokingHistory IN ('Yes', 'No', 'Former')) NULL,
    Height_cm DECIMAL(5, 2) NULL,
    Weight_kg DECIMAL(5, 2) NULL,
    BloodPressure VARCHAR(20) NULL,
    RecordDate DATE NOT NULL
);
GO

CREATE TABLE Lab_Results (
    ResultID INT PRIMARY KEY IDENTITY(1,1),
    PatientID INT NOT NULL FOREIGN KEY REFERENCES Patients(PatientID),
    StaffID INT NOT NULL FOREIGN KEY REFERENCES Staff(StaffID), 
    DepartmentID INT NOT NULL FOREIGN KEY REFERENCES Departments(DepartmentID),
    TestType NVARCHAR(100) NOT NULL,
    ResultDetails NVARCHAR(MAX) NULL,
    IsCritical BIT NOT NULL DEFAULT 0,
    Status VARCHAR(20) CHECK (Status IN ('Requested', 'Completed')) NOT NULL DEFAULT 'Requested',
    TestDate DATE NOT NULL
);
GO

-- =====================================================
-- Section 4: Inventory, Pharmacy & Prescriptions
-- =====================================================

CREATE TABLE Inventory_Items (
    ItemID INT PRIMARY KEY IDENTITY(1,1),
    ItemName NVARCHAR(150) NOT NULL,
    ItemType VARCHAR(20) CHECK (ItemType IN ('Medicine', 'Equipment')) NOT NULL,
    CurrentStock INT NOT NULL DEFAULT 0
);
GO

CREATE TABLE Inventory_Transactions (
    TransactionID INT PRIMARY KEY IDENTITY(1,1),
    ItemID INT NOT NULL FOREIGN KEY REFERENCES Inventory_Items(ItemID),
    TransactionType VARCHAR(10) CHECK (TransactionType IN ('Inbound', 'Outbound')) NOT NULL,
    Quantity INT NOT NULL,
    TransactionDate DATETIME NOT NULL
);
GO

CREATE TABLE Prescriptions (
    PrescriptionID INT PRIMARY KEY IDENTITY(1,1),
    PatientID INT NOT NULL FOREIGN KEY REFERENCES Patients(PatientID),
    StaffID INT NOT NULL FOREIGN KEY REFERENCES Staff(StaffID),
    IssueDate DATE NOT NULL
);
GO

CREATE TABLE Prescription_Items (
    PrescriptionItemID INT PRIMARY KEY IDENTITY(1,1),
    PrescriptionID INT NOT NULL FOREIGN KEY REFERENCES Prescriptions(PrescriptionID),
    ItemID INT NOT NULL FOREIGN KEY REFERENCES Inventory_Items(ItemID),
    Quantity INT NOT NULL
);
GO

CREATE TABLE Drug_Interactions (
    InteractionID INT PRIMARY KEY IDENTITY(1,1),
    DrugA_ID INT NOT NULL FOREIGN KEY REFERENCES Inventory_Items(ItemID),
    DrugB_ID INT NOT NULL FOREIGN KEY REFERENCES Inventory_Items(ItemID),
    Severity VARCHAR(20) CHECK (Severity IN ('Critical', 'Moderate')) NOT NULL,
    Description NVARCHAR(MAX)
);
GO

-- =====================================================
-- Section 5: Financials & Accounting
-- =====================================================

CREATE TABLE Invoices (
    InvoiceID INT PRIMARY KEY IDENTITY(1,1),
    PatientID INT NOT NULL FOREIGN KEY REFERENCES Patients(PatientID),
    TotalAmount DECIMAL(18, 2) NOT NULL,
    InsuranceShare DECIMAL(18, 2) NOT NULL DEFAULT 0,
    PatientShare DECIMAL(18, 2) NOT NULL DEFAULT 0,
    Status VARCHAR(20) CHECK (Status IN ('Paid', 'Pending')) NOT NULL
);
GO

CREATE TABLE Payments (
    PaymentID INT PRIMARY KEY IDENTITY(1,1),
    InvoiceID INT NOT NULL FOREIGN KEY REFERENCES Invoices(InvoiceID),
    Amount DECIMAL(18, 2) NOT NULL,
    PaymentType VARCHAR(20) CHECK (PaymentType IN ('Deposit', 'FullSettlement')) NOT NULL,
    PaymentDate DATETIME NOT NULL
);
GO

-- =====================================================
-- Section 6: IoT & Alert System
-- =====================================================

CREATE TABLE IoT_Devices (
    MAC_Address VARCHAR(17) PRIMARY KEY, -- Format XX:XX:XX:XX:XX:XX
    DeviceType NVARCHAR(100) NOT NULL,
    Status VARCHAR(20) CHECK (Status IN ('Active', 'Inactive', 'UnderMaintenance')) NOT NULL,
    PatientID INT NULL FOREIGN KEY REFERENCES Patients(PatientID),
    BedID INT NULL FOREIGN KEY REFERENCES Beds(BedID)
);
GO

CREATE TABLE IoT_Logs (
    LogID INT PRIMARY KEY IDENTITY(1,1),
    MAC_Address VARCHAR(17) NOT NULL FOREIGN KEY REFERENCES IoT_Devices(MAC_Address),
    MetricType NVARCHAR(50) NOT NULL, -- e.g., Temperature, HR, SpO2
    MetricValue FLOAT NOT NULL,
    Timestamp DATETIME NOT NULL
);
GO

CREATE TABLE Alerts (
    AlertID INT PRIMARY KEY IDENTITY(1,1),
    LogID INT NULL FOREIGN KEY REFERENCES IoT_Logs(LogID), 
    ResultID INT NULL FOREIGN KEY REFERENCES Lab_Results(ResultID), 
    Severity VARCHAR(20) CHECK (Severity IN ('Moderate', 'Critical')) NOT NULL, 
    Status VARCHAR(20) CHECK (Status IN ('Unchecked', 'Acknowledged', 'Resolved')) NOT NULL,
    GeneratedAt DATETIME NOT NULL, 
    ResolvedAt DATETIME NULL, 
    ResponderID INT NULL FOREIGN KEY REFERENCES Staff(StaffID),
    CONSTRAINT CK_Alert_Source CHECK (LogID IS NOT NULL OR ResultID IS NOT NULL)
);
GO

