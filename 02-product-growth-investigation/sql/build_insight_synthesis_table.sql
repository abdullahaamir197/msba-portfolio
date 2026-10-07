-- ====================================================================
-- Script: build_insight_synthesis_table.sql
-- Builds the executive insight summary used by the decision review.
-- Dialect: DuckDB / PostgreSQL
-- ====================================================================

WITH theme_summary AS (
    SELECT
        second_order_strategic_theme AS strategic_theme,
        COUNT(ticket_id) AS ticket_frequency,
        COUNT(DISTINCT company_id) AS affected_companies,
        ROUND(COALESCE(SUM(company_annual_revenue), 0), 2) AS total_economic_revenue_weight
    FROM 'research/thematic_coding_matrix.csv'
    GROUP BY second_order_strategic_theme
)

SELECT
    strategic_theme,
    ticket_frequency,
    affected_companies,
    total_economic_revenue_weight,
    -- Classify each theme by customer signal and commercial impact.
    CASE 
        WHEN strategic_theme = '1. CRITICAL_DATA_INTEGRATION' THEN 'Quadrant 3: Under-reported risk (High revenue impact, low vocal complaint)'
        WHEN strategic_theme = '2. PLATFORM_PERFORMANCE_RELIABILITY' THEN 'Quadrant 1: Core Strength / Core Fix (High revenue & high volume)'
        WHEN strategic_theme = '3. COMMERCIAL_BILLING_CHECKOUT' THEN 'Quadrant 2: The Vocal Trap (High volume, low revenue contribution)'
        ELSE 'Quadrant 4: Lower-priority operational friction'
    END AS triangulation_quadrant,
    -- Translate the classification into a practical next step.
    CASE 
        WHEN strategic_theme = '1. CRITICAL_DATA_INTEGRATION' THEN 'PRIORITY 1 SPRINT (Must-Have Table Stakes)'
        WHEN strategic_theme = '2. PLATFORM_PERFORMANCE_RELIABILITY' THEN 'PRIORITY 2 SPRINT (Performance Optimization)'
        WHEN strategic_theme = '3. COMMERCIAL_BILLING_CHECKOUT' THEN 'REPACKAGING / AUTOMATION (Self-Serve Flow)'
        ELSE 'DEFER / REVIEW'
    END AS strategic_action
FROM theme_summary
ORDER BY total_economic_revenue_weight DESC;