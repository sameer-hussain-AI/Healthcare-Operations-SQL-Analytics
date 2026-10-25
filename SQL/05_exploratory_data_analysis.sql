-- ==============================================================================
-- Project: Healthcare Operations Analytics (MySQL 8.0+)
-- Script 05: Exploratory Data Analysis (EDA) (05_exploratory_data_analysis.sql)

USE healthcare_operations;

-- ------------------------------------------------------------------------------
-- 1. OVERALL HOSPITAL DATASET SUMMARY
-- Purpose: Quick executive snapshot of total volume and total financial throughput.
-- ------------------------------------------------------------------------------

SELECT 
    COUNT(DISTINCT a.admission_id) AS total_admissions,
    COUNT(DISTINCT a.patient_id) AS total_patients_served,
    COUNT(DISTINCT a.doctor_id) AS active_doctors,
    SUM(a.total_bill) AS gross_billed_revenue,
    ROUND(AVG(a.total_bill), 2) AS avg_revenue_per_admission,
    ROUND(AVG(DATEDIFF(COALESCE(a.discharge_date, CURRENT_DATE()), a.admission_date)), 1) AS avg_length_of_stay_days
FROM admissions a;

-- ------------------------------------------------------------------------------
-- 2. ADMISSIONS BY DEPARTMENT AND STATUS
-- Purpose: Identify high-volume departments and current patient disposition.
-- ------------------------------------------------------------------------------

SELECT 
    d.department_name,
    COUNT(a.admission_id) AS total_admissions,
    SUM(CASE WHEN a.status = 'Discharged' THEN 1 ELSE 0 END) AS discharged_count,
    SUM(CASE WHEN a.status = 'Admitted' THEN 1 ELSE 0 END) AS currently_admitted,
    SUM(CASE WHEN a.status = 'Transferred' THEN 1 ELSE 0 END) AS transferred_count,
    ROUND(COUNT(a.admission_id) * 100.0 / (SELECT COUNT(*) FROM admissions), 2) AS pct_of_total_admissions
FROM departments d
LEFT JOIN admissions a ON d.department_id = a.department_id
GROUP BY d.department_id, d.department_name
ORDER BY total_admissions DESC;

-- ------------------------------------------------------------------------------
-- 3. TOTAL AND AVERAGE BILLED REVENUE BY DEPARTMENT
-- Purpose: Analyze department financial contribution vs budget allocation.
-- ------------------------------------------------------------------------------

SELECT 
    d.department_name,
    d.annual_budget,
    COUNT(a.admission_id) AS total_admissions,
    SUM(a.total_bill) AS total_revenue_generated,
    ROUND(AVG(a.total_bill), 2) AS avg_bill_per_patient,
    ROUND(SUM(a.total_bill) * 100.0 / d.annual_budget, 2) AS revenue_budget_ratio_pct
FROM departments d
LEFT JOIN admissions a ON d.department_id = a.department_id
GROUP BY d.department_id, d.department_name, d.annual_budget
ORDER BY total_revenue_generated DESC;

-- ------------------------------------------------------------------------------
-- 4. MONTHLY ADMISSIONS AND REVENUE TRENDS
-- Purpose: Evaluate temporal volume trends and revenue seasonality.
-- ------------------------------------------------------------------------------

SELECT 
    DATE_FORMAT(admission_date, '%Y-%m') AS year_month,
    COUNT(admission_id) AS monthly_admissions,
    SUM(total_bill) AS monthly_revenue,
    ROUND(AVG(total_bill), 2) AS avg_monthly_bill
FROM admissions
GROUP BY DATE_FORMAT(admission_date, '%Y-%m')
ORDER BY year_month ASC;

-- ------------------------------------------------------------------------------
-- 5. PATIENT DEMOGRAPHICS & GEOGRAPHIC DISTRIBUTION
-- Purpose: Understand patient population distribution across age groups and cities.
-- ------------------------------------------------------------------------------

-- Demographics by Age Group and Gender
SELECT 
    p.age_group,
    p.gender,
    COUNT(*) AS patient_count
FROM vw_patients_clean p
GROUP BY p.age_group, p.gender
ORDER BY p.age_group, p.gender;

-- Geographic Distribution (Top Patient Cities)
SELECT 
    city,
    COUNT(*) AS total_patients,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM patients), 2) AS city_share_pct
FROM patients
GROUP BY city
ORDER BY total_patients DESC;

-- ------------------------------------------------------------------------------
-- 6. TREATMENT TYPES, COSTS, AND OUTCOMES
-- Purpose: Analyze medical intervention volume, average cost, and outcome mix.
-- ------------------------------------------------------------------------------

SELECT 
    treatment_name,
    COUNT(*) AS times_performed,
    SUM(treatment_cost) AS total_treatment_revenue,
    ROUND(AVG(treatment_cost), 2) AS avg_treatment_cost,
    SUM(CASE WHEN outcome = 'Improved' THEN 1 ELSE 0 END) AS count_improved,
    SUM(CASE WHEN outcome = 'Stable' THEN 1 ELSE 0 END) AS count_stable,
    SUM(CASE WHEN outcome = 'Follow-up Required' THEN 1 ELSE 0 END) AS count_followup_req
FROM treatments
GROUP BY treatment_name
ORDER BY times_performed DESC;

-- ------------------------------------------------------------------------------
-- 7. DAILY BED CAPACITY & OCCUPANCY TRENDS
-- Purpose: Monitor average occupied beds and capacity utilization rate per department.
-- ------------------------------------------------------------------------------

SELECT 
    d.department_name,
    ROUND(AVG(b.total_beds), 0) AS configured_total_beds,
    ROUND(AVG(b.occupied_beds), 2) AS avg_daily_occupied_beds,
    ROUND(AVG(b.occupied_beds * 100.0 / b.total_beds), 2) AS avg_occupancy_rate_pct
FROM bed_capacity_daily b
JOIN departments d ON b.department_id = d.department_id
GROUP BY d.department_id, d.department_name
ORDER BY avg_occupancy_rate_pct DESC;
