-- ====================================================================
-- Script: 01_cohort_retention_channel_mix.sql
-- Phase II: Product & Growth Investigation
-- Target: Multi-Period Cohort Retention Matrix by Industry Segment
-- Dialect: DuckDB / PostgreSQL
-- ====================================================================

WITH company_cohorts AS (
    -- Step 1: Identify each company's first deal month and industry.
    SELECT
        c.company_id,
        c.industry,
        DATE_TRUNC('month', CAST(MIN(d.close_date) AS DATE)) AS cohort_month
    FROM 'data/companies.csv' c
    INNER JOIN 'data/deals.csv' d
        ON c.company_id = d.company_id
    GROUP BY c.company_id, c.industry
),

cohort_starting_sizes AS (
    -- Step 2: Establish the starting company count for each cohort and industry.
    SELECT
        cohort_month,
        industry,
        COUNT(DISTINCT company_id) AS starting_companies
    FROM company_cohorts
    GROUP BY cohort_month, industry
),

company_monthly_activity AS (
    -- Step 3: Keep one activity record per company per calendar month.
    SELECT DISTINCT
        company_id,
        DATE_TRUNC('month', CAST(close_date AS DATE)) AS activity_month
    FROM 'data/deals.csv'
),

cohort_lifecycle_events AS (
    -- Step 4: Compare each activity month with the company's cohort month.
    SELECT
        cc.company_id,
        cc.industry,
        cc.cohort_month,
        cma.activity_month,
        -- Calculate the number of months since cohort entry.
        (
            (EXTRACT(year FROM cma.activity_month) - EXTRACT(year FROM cc.cohort_month)) * 12 +
            (EXTRACT(month FROM cma.activity_month) - EXTRACT(month FROM cc.cohort_month))
        ) AS month_offset
    FROM company_cohorts cc
    INNER JOIN company_monthly_activity cma
        ON cc.company_id = cma.company_id
),

active_counts_by_offset AS (
    -- Step 5: Count active companies at each lifecycle month.
    SELECT
        cohort_month,
        industry,
        month_offset,
        COUNT(DISTINCT company_id) AS active_companies
    FROM cohort_lifecycle_events
    GROUP BY cohort_month, industry, month_offset
)

-- Step 6: Compare active companies with the original cohort size.
SELECT
    a.cohort_month,
    a.industry,
    a.month_offset,
    a.active_companies,
    s.starting_companies,
    ROUND((a.active_companies * 100.0) / s.starting_companies, 2) AS retention_rate_pct
FROM active_counts_by_offset a
INNER JOIN cohort_starting_sizes s
    ON a.cohort_month = s.cohort_month
   AND a.industry = s.industry
ORDER BY a.cohort_month, a.industry, a.month_offset;