-- ====================================================================
-- Script: build_thematic_coding_matrix.sql
-- Build the thematic coding matrix from support-ticket subjects.
-- Dialect: DuckDB / PostgreSQL
-- ====================================================================

SELECT
    t.ticket_id,
    c.company_id,
    c.company_name,
    c.industry,
    TRY_CAST(c.annual_revenue AS NUMERIC) AS company_annual_revenue,
    t.priority,
    t.status,
    t.subject AS verbatim_customer_quote,
    -- 1st-Order Code (Specific Descriptive Tag):
    CASE 
        WHEN t.subject LIKE '%Salesforce%' THEN 'INTEGRATION_SALESFORCE_FAILURE'
        WHEN t.subject LIKE '%API%500%' THEN 'BACKEND_API_500_ERROR'
        WHEN t.subject LIKE '%Data sync%' THEN 'DATA_SYNC_LATENCY'
        WHEN t.subject LIKE '%UI not loading%' THEN 'DASHBOARD_RENDER_FAILURE'
        WHEN t.subject LIKE '%Slow page%' THEN 'APP_PERFORMANCE_LATENCY'
        WHEN t.subject LIKE '%misalignment%' THEN 'COSMETIC_UI_DEFECT'
        WHEN t.subject LIKE '%Trial upgrade%' THEN 'BILLING_UPGRADE_FRICTION'
        ELSE 'OTHER_INQUIRY'
    END AS first_order_code,
    -- 2nd-Order Theme (High-Level Strategic Bucket):
    CASE 
        WHEN t.subject LIKE '%Salesforce%' OR t.subject LIKE '%API%500%' OR t.subject LIKE '%Data sync%' 
            THEN '1. CRITICAL_DATA_INTEGRATION'
        WHEN t.subject LIKE '%UI not loading%' OR t.subject LIKE '%Slow page%' 
            THEN '2. PLATFORM_PERFORMANCE_RELIABILITY'
        WHEN t.subject LIKE '%Trial upgrade%' 
            THEN '3. COMMERCIAL_BILLING_CHECKOUT'
        ELSE '4. COSMETIC_MINOR_DEFECTS'
    END AS second_order_strategic_theme
FROM 'data/tickets.csv' t
LEFT JOIN 'data/companies.csv' c
    ON t.associated_company_id = c.company_id
ORDER BY company_annual_revenue DESC, t.ticket_id;