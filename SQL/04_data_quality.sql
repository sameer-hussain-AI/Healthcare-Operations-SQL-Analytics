-- ==============================================================================
-- Project: Healthcare Operations Analytics (MySQL 8.0+)
-- Script 04: Data Quality Assurance & Audit Checks (04_data_quality.sql)
-- Purpose: Execute row-count verification, integrity checks, duplicate audits,
--          foreign key validations, and bed-capacity logic sanity checks.
-- ==============================================================================

USE healthcare_operations;

-- ------------------------------------------------------------------------------
-- 1. ROW COUNT VERIFICATION
-- Target: 10 Depts, 30 Doctors, 100 Patients, 60 Beds, 250 Admissions,
--         500 Treatments, 900 Capacity logs = Total 1,850 records.
-- ------------------------------------------------------------------------------

SELECT 'departments' AS table_name, COUNT(*) AS record_count, 10 AS expected_count, (COUNT(*) = 10) AS is_valid FROM departments
UNION ALL
SELECT 'doctors', COUNT(*), 30, (COUNT(*) = 30) FROM doctors
UNION ALL
SELECT 'patients', COUNT(*), 100, (COUNT(*) = 100) FROM patients
UNION ALL
SELECT 'beds', COUNT(*), 60, (COUNT(*) = 60) FROM beds
UNION ALL
SELECT 'admissions', COUNT(*), 250, (COUNT(*) = 250) FROM admissions
UNION ALL
SELECT 'treatments', COUNT(*), 500, (COUNT(*) = 500) FROM treatments
UNION ALL
SELECT 'bed_capacity_daily', COUNT(*), 900, (COUNT(*) = 900) FROM bed_capacity_daily;

-- Total Record Aggregation
SELECT SUM(cnt) AS grand_total_records, 1850 AS expected_grand_total
FROM (
    SELECT COUNT(*) AS cnt FROM departments
    UNION ALL SELECT COUNT(*) FROM doctors
    UNION ALL SELECT COUNT(*) FROM patients
    UNION ALL SELECT COUNT(*) FROM beds
    UNION ALL SELECT COUNT(*) FROM admissions
    UNION ALL SELECT COUNT(*) FROM treatments
    UNION ALL SELECT COUNT(*) FROM bed_capacity_daily
) sub;

-- ------------------------------------------------------------------------------
-- 2. DUPLICATE & UNIQUE CONSTRAINT CHECKS
-- ------------------------------------------------------------------------------

-- Check for duplicate department names
SELECT department_name, COUNT(*) FROM departments GROUP BY department_name HAVING COUNT(*) > 1;

-- Check for duplicate capacity entries for same date & department
SELECT capacity_date, department_id, COUNT(*) 
FROM bed_capacity_daily 
GROUP BY capacity_date, department_id 
HAVING COUNT(*) > 1;

-- ------------------------------------------------------------------------------
-- 3. FOREIGN KEY & REFERENTIAL INTEGRITY AUDIT
-- ------------------------------------------------------------------------------

-- Orphan Admissions (Missing Patient, Doctor, Department, or Bed)
SELECT a.admission_id 
FROM admissions a
LEFT JOIN patients p ON a.patient_id = p.patient_id
LEFT JOIN doctors d ON a.doctor_id = d.doctor_id
LEFT JOIN departments dept ON a.department_id = dept.department_id
LEFT JOIN beds b ON a.bed_id = b.bed_id
WHERE p.patient_id IS NULL OR d.doctor_id IS NULL OR dept.department_id IS NULL OR b.bed_id IS NULL;

-- Orphan Treatments (Treatment referencing non-existent admission)
SELECT t.treatment_id 
FROM treatments t
LEFT JOIN admissions a ON t.admission_id = a.admission_id
WHERE a.admission_id IS NULL;

-- ------------------------------------------------------------------------------
-- 4. BUSINESS LOGIC & CROSS-TABLE CONSISTENCY CHECKS
-- ------------------------------------------------------------------------------

-- Bed Capacity Constraints (occupied_beds > total_beds or negative values)
SELECT capacity_id, capacity_date, department_id, total_beds, occupied_beds
FROM bed_capacity_daily
WHERE occupied_beds > total_beds OR occupied_beds < 0 OR total_beds < 0;

-- Doctor-Department Mismatch in Admissions
-- Checks if an admission's department matches the treating doctor's department
SELECT a.admission_id, a.doctor_id, a.department_id AS admission_dept, d.department_id AS doctor_dept
FROM admissions a
JOIN doctors d ON a.doctor_id = d.doctor_id
WHERE a.department_id <> d.department_id;

-- Treatment Date vs Admission Date Validation
-- Treatment cannot occur before admission date or after discharge date
SELECT t.treatment_id, t.admission_id, t.treatment_date, a.admission_date, a.discharge_date
FROM treatments t
JOIN admissions a ON t.admission_id = a.admission_id
WHERE t.treatment_date < a.admission_date 
   OR (a.discharge_date IS NOT NULL AND t.treatment_date > a.discharge_date);

-- Admission Status Consistency
-- Discharged patients must have a discharge_date; Currently Admitted should have NULL discharge_date
SELECT admission_id, status, discharge_date
FROM admissions
WHERE (status = 'Discharged' AND discharge_date IS NULL)
   OR (status = 'Admitted' AND discharge_date IS NOT NULL);
