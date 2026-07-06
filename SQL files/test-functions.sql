SELECT dbo.fn_GetPatientFullName(1) AS FullName;

SELECT dbo.fn_CalculatePatientAge(1) AS Age;

SELECT dbo.fn_GetBedAvailability(1) AS AvailableBeds;

SELECT dbo.fn_GetTotalPatientPayments(1) AS TotalPayments;

SELECT dbo.fn_GetPatientBalance(1) AS Balance;


SELECT dbo.fn_GetDoctorAppointmentCount(1, '2026-07-01', '2026-07-31') AS AppointmentCount;

SELECT dbo.fn_GetDepartmentBedOccupancyRate(1) AS OccupancyRate;

SELECT dbo.fn_GetCriticalLabResults(4) AS CriticalResults;

SELECT dbo.fn_GetInventoryItemStock(1) AS CurrentStock;

SELECT dbo.fn_GetTotalAppointmentsPerDay('2026-07-15') AS TotalAppointments;

SELECT dbo.fn_GetActiveIoTDevicesCount() AS ActiveDevices;

SELECT dbo.fn_GetUncheckedAlertsCount() AS UncheckedAlerts;

SELECT dbo.fn_GetPatientAdmissionHistory(3) AS AdmissionHistory;

SELECT dbo.fn_GetPrescriptionDetails(1) AS PrescriptionDetails;

SELECT dbo.fn_GetDepartmentFullInfo(1) AS DepartmentInfo;

SELECT dbo.fn_GetPendingInvoicesCount() AS PendingInvoices;

SELECT dbo.fn_GetLabRequestStatus(1) AS RequestStatus;

SELECT dbo.fn_GetDrugInteractionCount(1) AS InteractionCount;

SELECT dbo.fn_GetPatientAppointmentHistory(1) AS AppointmentHistory;

SELECT dbo.fn_GetStaffWorkload(1) AS Workload;

SELECT dbo.fn_GetInventoryTurnover(1) AS Turnover;

SELECT dbo.fn_GetPatientInsuranceCoverage(1) AS InsuranceCoverage;

SELECT dbo.fn_GetAvailableBedsForDepartment(1) AS AvailableBedsList;