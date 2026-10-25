# Healthcare Operations Analytics

A data analytics project focused on exploring healthcare operations data with **MySQL** and **Python**. The project is designed to demonstrate a complete analytical workflow: loading structured CSV data into a relational database, validating data quality, cleaning and exploring the data, and developing operational insights with SQL and Python.

> **Project status:** In progress  
> **Primary tools:** MySQL, MySQL Workbench, SQL, Python, Pandas

## Project Objectives

- Build a relational database for healthcare operations data.
- Import CSV datasets into MySQL tables and validate that the data loaded correctly.
- Use SQL to query, join, aggregate, and analyze operational data.
- Identify data-quality issues such as missing values, duplicate records, and inconsistent values.
- Perform exploratory data analysis (EDA) and deeper analysis with Python.
- Present clear, reproducible findings that could support operational decision-making.

## Technology Stack

| Tool | Purpose |
|---|---|
| MySQL | Relational database and SQL analysis |
| MySQL Workbench | Database management and query execution |
| Python | Data cleaning, quality checks, EDA, and advanced analysis |
| Pandas / NumPy | Data manipulation and numerical analysis |
| Matplotlib / Seaborn / Plotly | Data visualization |
| Jupyter | Interactive analysis and documentation |

## Repository Structure

The project may be organized as follows. Adjust folder and file names to match the final repository layout.

```text
healthcare-operations-analytics/
├── data/
│   ├── raw/                     # Original CSV files
│   └── processed/               # Cleaned/exported data, if applicable
├── sql/
│   ├── 01_create_tables.sql     # Database and table definitions
│   ├── 02_import_validation.sql # Row counts and import checks
│   ├── 03_data_quality.sql      # SQL-based data-quality checks
│   ├── 04_eda.sql               # Exploratory SQL queries
│   └── 05_advanced_analysis.sql # Deeper operational analysis
├── notebooks/                   # Optional notebooks for exploration
├── src/
│   ├── data_cleaning.py
│   ├── eda.py
│   ├── data_quality.py
│   └── advanced_analysis.py
├── reports/                     # Charts, summaries, and exported reports
├── README.md
└── requirements.txt
```

## Database and Data

The project uses CSV files loaded into a MySQL database named `healthcare_operations` (or the database name configured locally).

Known dataset/table names from the current workflow include `patients`, `departments`, and `bed_capacity_daily`. Add the remaining tables and their purpose here once the final schema is confirmed.

| Table / dataset | Intended use |
|---|---|
| `patients` | Patient-related records and attributes |
| `departments` | Hospital department information |
| `bed_capacity_daily` | Daily bed-capacity information |
| Other project tables | Document each table after confirming the final schema |

**Data note:** Do not publish private, identifiable, or otherwise sensitive patient information. Use synthetic, anonymized, or appropriately licensed data and document the source.

## Getting Started

### 1. Clone or download the repository

```bash
git clone <your-repository-url>
cd healthcare-operations-analytics
```

If you have not published the repository yet, download the project folder and open a terminal in that folder.

### 2. Create and activate a virtual environment (recommended)

Windows:

```bash
python -m venv .venv
.venv\Scripts\activate
```

macOS / Linux:

```bash
python3 -m venv .venv
source .venv/bin/activate
```

### 3. Install Python dependencies

```bash
python -m pip install --upgrade pip
pip install -r requirements.txt
```

### 4. Set up MySQL

1. Install and open MySQL Server and MySQL Workbench.
2. Create or select the `healthcare_operations` database.
3. Run the table-creation SQL script from the `sql/` folder, if included.
4. Import the CSV files into their matching tables.
5. Validate the import with row-count queries and checks for duplicate keys, missing values, and incorrect data types.

Example validation query:

```sql
USE healthcare_operations;

SELECT COUNT(*) AS patient_row_count
FROM patients;
```

Run this only after confirming that the `patients` table exists and that the database contains the expected data.

### 5. Configure the database connection

If Python scripts connect to MySQL, configure the connection using environment variables or a local configuration file that is **not committed to GitHub**. Never commit passwords, API keys, or other credentials.

Example environment-variable names:

```text
DB_HOST=localhost
DB_PORT=3306
DB_NAME=healthcare_operations
DB_USER=your_mysql_username
DB_PASSWORD=your_mysql_password
```

These are example variable names; your scripts must be written to read them before they will take effect. Do not put real credentials in this README.

## Analysis Workflow

1. **Database setup:** Create tables and load source CSV files.
2. **Import validation:** Compare row counts and verify keys, columns, and data types.
3. **Data cleaning:** Inspect missing values, duplicates, inconsistent categories, and invalid values; document any corrections.
4. **Data quality assessment:** Summarize completeness, uniqueness, validity, and consistency checks.
5. **Exploratory data analysis:** Use descriptive statistics, grouped summaries, and visualizations to understand the data.
6. **Advanced analysis:** Develop SQL joins, aggregations, comparisons, and operational metrics based on the available columns.
7. **Reporting:** Summarize findings, limitations, and actionable recommendations supported by the data.

## Example SQL Analysis

The following is a generic example of aggregating records by department. Adapt the column names to match the actual schema.

```sql
SELECT
    department_id,
    COUNT(*) AS record_count
FROM your_table_name
GROUP BY department_id
ORDER BY record_count DESC;
```

## Quality and Reproducibility

- Keep raw source files unchanged; write cleaned outputs to a separate location.
- Record cleaning decisions rather than silently dropping records.
- Check primary keys and duplicate records before running joins.
- Validate row counts after imports and transformations.
- Use clear SQL aliases and descriptive file names.
- Document assumptions, metric definitions, and known limitations.
- Keep credentials and sensitive data out of version control.

## Current Deliverables

Update this checklist as each item is completed.

- [ ] Database schema and table-creation scripts
- [ ] CSV import and validation checks
- [ ] SQL data-quality checks
- [ ] SQL exploratory analysis
- [ ] Advanced SQL analysis
- [ ] Python data-cleaning workflow
- [ ] Python EDA and visualizations
- [ ] Final findings and recommendations
- [ ] Screenshots or exported report for the repository

## Author

**Sameer Hussain**  
Aspiring Data Analyst | SQL | Python | Excel | Power BI

- GitHub: https://github.com/sameer-hussain-AI
- LinkedIn: https://www.linkedin.com/in/sameer-hussain-920722356/

## Disclaimer

This is an analytics portfolio project for learning and demonstration. Any operational conclusions depend on the quality, coverage, and definitions of the source data and should not be treated as clinical guidance.
