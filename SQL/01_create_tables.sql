-- Healthcare Operations Analytics Project

CREATE DATABASE IF NOT EXISTS healthcare_operations;
USE healthcare_operations;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS treatments;
DROP TABLE IF EXISTS admissions;
DROP TABLE IF EXISTS bed_capacity_daily;
DROP TABLE IF EXISTS beds;
DROP TABLE IF EXISTS doctors;
DROP TABLE IF EXISTS patients;
DROP TABLE IF EXISTS departments;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE departments (
    department_id INT PRIMARY KEY,
    department_name VARCHAR(80) NOT NULL UNIQUE,
    floor_number TINYINT NOT NULL,
    annual_budget DECIMAL(12,2) NOT NULL
);

CREATE TABLE doctors (
    doctor_id INT PRIMARY KEY,
    doctor_name VARCHAR(100) NOT NULL,
    specialty VARCHAR(80) NOT NULL,
    department_id INT NOT NULL,
    hire_date DATE NOT NULL,
    monthly_salary DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_doctors_department
        FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

CREATE TABLE patients (
    patient_id INT PRIMARY KEY,
    patient_name VARCHAR(100) NOT NULL,
    gender ENUM('Female','Male','Other') NOT NULL,
    date_of_birth DATE NOT NULL,
    city VARCHAR(80) NOT NULL,
    registration_date DATE NOT NULL
);

CREATE TABLE beds (
    bed_id INT PRIMARY KEY,
    ward_name VARCHAR(80) NOT NULL,
    bed_type ENUM('General','Private','ICU','Maternity','Pediatric') NOT NULL,
    department_id INT NOT NULL,
    daily_rate DECIMAL(8,2) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_beds_department
        FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

CREATE TABLE admissions (
    admission_id INT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    department_id INT NOT NULL,
    bed_id INT NOT NULL,
    admission_date DATE NOT NULL,
    discharge_date DATE NULL,
    admission_type ENUM('Emergency','Scheduled','Referral') NOT NULL,
    status ENUM('Discharged','Admitted','Transferred') NOT NULL,
    total_bill DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_admissions_patient
        FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    CONSTRAINT fk_admissions_doctor
        FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id),
    CONSTRAINT fk_admissions_department
        FOREIGN KEY (department_id) REFERENCES departments(department_id),
    CONSTRAINT fk_admissions_bed
        FOREIGN KEY (bed_id) REFERENCES beds(bed_id),
    CONSTRAINT chk_admission_dates
        CHECK (discharge_date IS NULL OR discharge_date >= admission_date)
);

CREATE TABLE treatments (
    treatment_id INT PRIMARY KEY,
    admission_id INT NOT NULL,
    treatment_name VARCHAR(100) NOT NULL,
    treatment_date DATE NOT NULL,
    treatment_cost DECIMAL(10,2) NOT NULL,
    outcome ENUM('Improved','Stable','Follow-up Required') NOT NULL,
    CONSTRAINT fk_treatments_admission
        FOREIGN KEY (admission_id) REFERENCES admissions(admission_id)
);

CREATE TABLE bed_capacity_daily (
    capacity_id INT PRIMARY KEY,
    capacity_date DATE NOT NULL,
    department_id INT NOT NULL,
    total_beds INT NOT NULL,
    occupied_beds INT NOT NULL,
    CONSTRAINT fk_capacity_department
        FOREIGN KEY (department_id) REFERENCES departments(department_id),
    CONSTRAINT uq_capacity_date_department UNIQUE (capacity_date, department_id),
    CONSTRAINT chk_bed_capacity CHECK (
        total_beds >= 0 AND occupied_beds >= 0 AND occupied_beds <= total_beds
    )
);

CREATE INDEX idx_admissions_dates ON admissions(admission_date, discharge_date);
CREATE INDEX idx_admissions_department ON admissions(department_id);
CREATE INDEX idx_treatments_date ON treatments(treatment_date);
CREATE INDEX idx_capacity_date ON bed_capacity_daily(capacity_date);
