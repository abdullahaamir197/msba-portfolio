-- ====================================================================
-- Script: shift_share_check.sql
-- Compare retention changes with the underlying industry mix.
-- Dialect: DuckDB / PostgreSQL
-- ====================================================================

WITH company_cohorts AS (
    SELECT
        c.company_id,
        c.industry,
        DATE_TRUNC('quarter', CAST(MIN(d.close_date) AS DATE)) AS cohort_quarter
    FROM 'data/companies.csv' c
    INNER JOIN 'data/deals.csv' d
        ON c.company_id = d.company_id
    GROUP BY c.company_id, c.industry
),

repeat_deal_activity AS (
    SELECT DISTINCT
        company_id,
        DATE_TRUNC('quarter', CAST(close_date AS DATE)) AS activity_quarter
    FROM 'data/deals.csv'
)

SELECT
    cc.cohort_quarter,
    cc.industry,
    COUNT(DISTINCT cc.company_id) AS total_cohort_companies,
    -- Count companies that closed repeat deals in subsequent quarters:
    COUNT(DISTINCT CASE 
        WHEN ra.activity_quarter > cc.cohort_quarter THEN cc.company_id 
    END) AS retained_companies,
    -- Compute Retention Rate %:
    ROUND(
        COUNT(DISTINCT CASE WHEN ra.activity_quarter > cc.cohort_quarter THEN cc.company_id END) * 100.0 / 
        COUNT(DISTINCT cc.company_id), 
        2
    ) AS retention_rate_pct
FROM company_cohorts cc
LEFT JOIN repeat_deal_activity ra
    ON cc.company_id = ra.company_id
GROUP BY cc.cohort_quarter, cc.industry
ORDER BY cc.cohort_quarter, total_cohort_companies DESC;