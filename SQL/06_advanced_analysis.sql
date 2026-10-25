-- ==============================================================================
-- Project: Healthcare Operations Analytics (MySQL 8.0+)
-- Script 06: Advanced Analytics & Window Functions (06_advanced_analysis.sql)
-- Purpose: Perform deep operational intelligence using Common Table Expressions (CTEs),
--          Window Functions (RANK, DENSE_RANK, LAG), YoY/MoM financial analysis,
--          workload modeling, and readmission identification.
-- Special Note: Avoids fan-out / double-counting by aggregating one-to-many 
--               child tables (e.g., treatments) prior to joining.
-- ==============================================================================

USE healthcare_operations;

-- ------------------------------------------------------------------------------
-- 1. MONTH-OVER-MONTH (MoM) REVENUE GROWTH & TREND ANALYSIS
-- Uses LAG() window function to calculate MoM growth percentage.
-- ------------------------------------------------------------------------------

WITH monthly_revenue_cte AS (
    SELECT 
        DATE_FORMAT(admission_date, '%Y-%m') AS rev_month,
        SUM(total_bill) AS current_month_revenue,
        COUNT(admission_id) AS total_admissions
    FROM admissions
    GROUP BY DATE_FORMAT(admission_date, '%Y-%m')
)
SELECT 
    rev_month,
    current_month_revenue,
    total_admissions,
    LAG(current_month_revenue, 1) OVER (ORDER BY rev_month) AS prior_month_revenue,
    ROUND(
        (current_month_revenue - LAG(current_month_revenue, 1) OVER (ORDER BY rev_month)) 
        * 100.0 / LAG(current_month_revenue, 1) OVER (ORDER BY rev_month), 2
    ) AS mom_growth_pct
FROM monthly_revenue_cte
ORDER BY rev_month;

-- ------------------------------------------------------------------------------
-- 2. DEPARTMENT PERFORMANCE & REVENUE RANKING
-- Uses RANK() and DENSE_RANK() to rank departments by revenue and length of stay.
-- ------------------------------------------------------------------------------

WITH dept_metrics AS (
    SELECT 
        d.department_name,
        COUNT(a.admission_id) AS admission_count,
        SUM(a.total_bill) AS total_dept_revenue,
        AVG(DATEDIFF(COALESCE(a.discharge_date, CURRENT_DATE()), a.admission_date)) AS avg_los
    FROM departments d
    JOIN admissions a ON d.department_id = a.department_id
    GROUP BY d.department_id, d.department_name
)
SELECT 
    department_name,
    admission_count,
    total_dept_revenue,
    ROUND(avg_los, 1) AS avg_los_days,
    RANK() OVER (ORDER BY total_dept_revenue DESC) AS revenue_rank,
    DENSE_RANK() OVER (ORDER BY avg_los DESC) AS los_rank
FROM dept_metrics;

-- ------------------------------------------------------------------------------
-- 3. DOCTOR WORKLOAD & REVENUE CONTRIBUTION ANALYSIS
-- Evaluates admissions per doctor, total revenue, and salary-to-revenue efficiency.
-- ------------------------------------------------------------------------------

WITH doctor_summary AS (
    SELECT 
        doc.doctor_id,
        doc.doctor_name,
        dept.department_name,
        doc.monthly_salary,
        COUNT(a.admission_id) AS total_patients_treated,
        SUM(a.total_bill) AS total_revenue_generated
    FROM doctors doc
    JOIN departments dept ON doc.department_id = dept.department_id
    LEFT JOIN admissions a ON doc.doctor_id = a.doctor_id
    GROUP BY doc.doctor_id, doc.doctor_name, dept.department_name, doc.monthly_salary
)
SELECT 
    doctor_name,
    department_name,
    monthly_salary,
    total_patients_treated,
    total_revenue_generated,
    DENSE_RANK() OVER (PARTITION BY department_name ORDER BY total_revenue_generated DESC) AS dept_doctor_rank,
    ROUND(total_revenue_generated / NULLIF(monthly_salary * 12, 0), 2) AS annual_salary_multiplier
FROM doctor_summary
ORDER BY department_name, dept_doctor_rank;

-- ------------------------------------------------------------------------------
-- 4. REPEAT PATIENT & READMISSION ANALYSIS
-- Uses window functions (LAG and ROW_NUMBER) to calculate days between admissions.
-- ------------------------------------------------------------------------------

WITH patient_admissions_lag AS (
    SELECT 
        a.admission_id,
        a.patient_id,
        p.patient_name,
        a.admission_date,
        a.discharge_date,
        LAG(a.discharge_date, 1) OVER (
            PARTITION BY a.patient_id 
            ORDER BY a.admission_date
        ) AS previous_discharge_date,
        ROW_NUMBER() OVER (
            PARTITION BY a.patient_id 
            ORDER BY a.admission_date
        ) AS visit_number
    FROM admissions a
    JOIN patients p ON a.patient_id = p.patient_id
)
SELECT 
    admission_id,
    patient_id,
    patient_name,
    visit_number,
    admission_date,
    previous_discharge_date,
    DATEDIFF(admission_date, previous_discharge_date) AS days_since_last_discharge,
    CASE 
        WHEN DATEDIFF(admission_date, previous_discharge_date) <= 30 THEN '30-Day Readmission'
        WHEN DATEDIFF(admission_date, previous_discharge_date) <= 90 THEN '90-Day Readmission'
        WHEN previous_discharge_date IS NOT NULL THEN 'Subsequent Visit (>90 Days)'
        ELSE 'First Admission'
    END AS readmission_category
FROM patient_admissions_lag
WHERE visit_number > 1
ORDER BY patient_id, visit_number;

-- ------------------------------------------------------------------------------
-- 5. REVENUE CONCENTRATION & HIGH-BILL OUTLIERS
-- Identifies top 10% highest-billed admissions using PERCENT_RANK().
-- ------------------------------------------------------------------------------

WITH ranked_bills AS (
    SELECT 
        a.admission_id,
        p.patient_name,
        dept.department_name,
        a.total_bill,
        PERCENT_RANK() OVER (ORDER BY a.total_bill ASC) AS bill_percentile
    FROM admissions a
    JOIN patients p ON a.patient_id = p.patient_id
    JOIN departments dept ON a.department_id = dept.department_id
)
SELECT 
    admission_id,
    patient_name,
    department_name,
    total_bill,
    ROUND(bill_percentile * 100, 2) AS percentile,
    'Top 10% High-Cost Outlier' AS billing_status
FROM ranked_bills
WHERE bill_percentile >= 0.90
ORDER BY total_bill DESC;

-- ------------------------------------------------------------------------------
-- 6. SAFE JOIN: COMBINING ADMISSIONS AND TREATMENT COSTS WITHOUT FAN-OUT
-- Pre-aggregates treatment costs per admission prior to joining to prevent 
-- multiplying admission bills during table joins.
-- ------------------------------------------------------------------------------

WITH treatment_aggregates AS (
    SELECT 
        admission_id,
        COUNT(treatment_id) AS treatment_count,
        SUM(treatment_cost) AS total_treatment_cost,
        AVG(treatment_cost) AS avg_treatment_cost
    FROM treatments
    GROUP BY admission_id
)
SELECT 
    a.admission_id,
    p.patient_name,
    dept.department_name,
    a.total_bill AS admission_total_bill,
    COALESCE(t.treatment_count, 0) AS total_treatments_given,
    COALESCE(t.total_treatment_cost, 0) AS total_treatment_cost_sum,
    -- Calculate net balance or overhead ratio safely
    ROUND(a.total_bill - COALESCE(t.total_treatment_cost, 0), 2) AS margin_over_treatments
FROM admissions a
JOIN patients p ON a.patient_id = p.patient_id
JOIN departments dept ON a.department_id = dept.department_id
LEFT JOIN treatment_aggregates t ON a.admission_id = t.admission_id
ORDER BY a.admission_id ASC;
