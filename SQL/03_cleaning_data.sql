-- ==============================================================================
-- Project: Healthcare Operations Analytics (MySQL 8.0+)
-- Script 03: Data Cleaning & View Construction (03_data_cleaning.sql)
-- Purpose: Inspect missing/blank values, validate numeric and date ranges,
--          and build non-destructive analytical views with derived metrics.

USE healthcare_operations;

-- ------------------------------------------------------------------------------
-- 1. INSPECTION OF MISSING AND BLANK VALUES
-- ------------------------------------------------------------------------------

-- Check missing values across primary patient attributes
SELECT 
    COUNT(*) AS total_patients,
    SUM(CASE WHEN patient_name IS NULL OR TRIM(patient_name) = '' THEN 1 ELSE 0 END) AS missing_names,
    SUM(CASE WHEN gender IS NULL THEN 1 ELSE 0 END) AS missing_gender,
    SUM(CASE WHEN date_of_birth IS NULL THEN 1 ELSE 0 END) AS missing_dob,
    SUM(CASE WHEN city IS NULL OR TRIM(city) = '' THEN 1 ELSE 0 END) AS missing_city
FROM patients;

-- Check open/ongoing admissions vs missing discharge dates
SELECT 
    status,
    COUNT(*) AS total_records,
    SUM(CASE WHEN discharge_date IS NULL THEN 1 ELSE 0 END) AS null_discharge_dates
FROM admissions
GROUP BY status;

-- ------------------------------------------------------------------------------
-- 2. VALIDATION OF DATES, AGES, AND NUMERIC VALUES
-- ------------------------------------------------------------------------------

-- Detect invalid age bounds (DOB in future or unrealistically old)
SELECT patient_id, patient_name, date_of_birth,
       TIMESTAMPDIFF(YEAR, date_of_birth, CURRENT_DATE()) AS calculated_age
FROM patients
WHERE date_of_birth > CURRENT_DATE() 
   OR TIMESTAMPDIFF(YEAR, date_of_birth, CURRENT_DATE()) > 120;

-- Detect logical anomalies in admission vs discharge dates
SELECT admission_id, patient_id, admission_date, discharge_date
FROM admissions
WHERE discharge_date IS NOT NULL AND discharge_date < admission_date;

-- Check for zero or negative financials
SELECT 'admissions' AS table_name, admission_id AS record_id, total_bill AS amount FROM admissions WHERE total_bill <= 0
UNION ALL
SELECT 'treatments', treatment_id, treatment_cost FROM treatments WHERE treatment_cost <= 0
UNION ALL
SELECT 'beds', bed_id, daily_rate FROM beds WHERE daily_rate <= 0;

-- ------------------------------------------------------------------------------
-- 3. NON-DESTRUCTIVE CLEANED VIEWS WITH DERIVED METRICS
-- ------------------------------------------------------------------------------

-- View 1: Cleaned Patients with Calculated Age & Age Brackets
CREATE OR REPLACE VIEW vw_patients_clean AS
SELECT 
    patient_id,
    TRIM(patient_name) AS patient_name,
    gender,
    date_of_birth,
    TRIM(city) AS city,
    registration_date,
    TIMESTAMPDIFF(YEAR, date_of_birth, CURRENT_DATE()) AS age,
    CASE 
        WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURRENT_DATE()) < 18 THEN 'Pediatric (<18)'
        WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURRENT_DATE()) BETWEEN 18 AND 35 THEN 'Young Adult (18-35)'
        WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURRENT_DATE()) BETWEEN 36 AND 60 THEN 'Middle-aged (36-60)'
        ELSE 'Senior (60+)'
    END AS age_group
FROM patients;

-- View 2: Cleaned Admissions with Length of Stay (LOS) & Billing Metrics
CREATE OR REPLACE VIEW vw_admissions_clean AS
SELECT 
    a.admission_id,
    a.patient_id,
    a.doctor_id,
    a.department_id,
    a.bed_id,
    a.admission_date,
    a.discharge_date,
    a.admission_type,
    a.status,
    a.total_bill,
    -- If discharged, calculate actual stay days. If active, calculate days up to today.
    CASE 
        WHEN a.discharge_date IS NOT NULL THEN DATEDIFF(a.discharge_date, a.admission_date)
        ELSE DATEDIFF(CURRENT_DATE(), a.admission_date)
    END AS length_of_stay_days,
    -- Derived Daily Cost per Admission
    ROUND(
        a.total_bill / GREATEST(1, CASE 
            WHEN a.discharge_date IS NOT NULL THEN DATEDIFF(a.discharge_date, a.admission_date)
            ELSE DATEDIFF(CURRENT_DATE(), a.admission_date)
        END), 2
    ) AS daily_billed_rate
FROM admissions a;

-- View 3: Comprehensive Enriched Admissions View
CREATE OR REPLACE VIEW vw_admissions_enriched AS
SELECT 
    ac.admission_id,
    p.patient_name,
    p.gender,
    p.age,
    p.age_group,
    p.city AS patient_city,
    doc.doctor_name,
    doc.specialty AS doctor_specialty,
    dept.department_name,
    dept.floor_number,
    b.ward_name,
    b.bed_type,
    ac.admission_date,
    ac.discharge_date,
    ac.admission_type,
    ac.status,
    ac.length_of_stay_days,
    ac.total_bill
FROM vw_admissions_clean ac
JOIN vw_patients_clean p ON ac.patient_id = p.patient_id
JOIN doctors doc ON ac.doctor_id = doc.doctor_id
JOIN departments dept ON ac.department_id = dept.department_id
JOIN beds b ON ac.bed_id = b.bed_id;
