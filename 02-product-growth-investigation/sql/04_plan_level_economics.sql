-- ====================================================================
-- Script: 04_plan_level_economics.sql
-- Segment economics and compare commercial motions.
-- Dialect: DuckDB / PostgreSQL
-- ====================================================================

WITH company_commercial_tiers AS (
    -- Segment companies by employee count.
    SELECT
        company_id,
        company_name,
        industry,
        TRY_CAST(num_employees AS INTEGER) AS num_employees,
        TRY_CAST(annual_revenue AS NUMERIC) AS company_annual_revenue,
        CASE 
            WHEN TRY_CAST(num_employees AS INTEGER) < 50 THEN '1. Small Business (SMB)'
            WHEN TRY_CAST(num_employees AS INTEGER) BETWEEN 50 AND 250 THEN '2. Mid-Market'
            WHEN TRY_CAST(num_employees AS INTEGER) > 250 THEN '3. Enterprise Scale'
            ELSE '4. Unclassified'
        END AS commercial_tier
    FROM 'data/companies.csv'
),

tier_pipeline_performance AS (
    -- Summarize deal activity and won revenue by tier.
    SELECT
        ct.commercial_tier,
        COUNT(DISTINCT ct.company_id) AS total_companies,
        COUNT(DISTINCT d.deal_id) AS total_pipeline_deals,
        -- Closed Won and Closed Lost deal counts.
        COUNT(DISTINCT CASE WHEN d.stage = 'Closed Won' THEN d.deal_id END) AS closed_won_deals,
        COUNT(DISTINCT CASE WHEN d.stage = 'Closed Lost' THEN d.deal_id END) AS closed_lost_deals,
        -- Revenue from Closed Won deals.
        COALESCE(SUM(CASE WHEN d.stage = 'Closed Won' THEN TRY_CAST(d.amount AS NUMERIC) ELSE 0 END), 0) AS total_won_revenue
    FROM company_commercial_tiers ct
    LEFT JOIN 'data/deals.csv' d
        ON ct.company_id = d.company_id
    GROUP BY ct.commercial_tier
),

tier_unit_economics_assumptions AS (
    -- Apply tier-specific acquisition costs and the assumed gross margin.
    SELECT
        commercial_tier,
        total_companies,
        total_pipeline_deals,
        closed_won_deals,
        closed_lost_deals,
        total_won_revenue,
        -- Average value of a won contract.
        ROUND(
            total_won_revenue / NULLIF(closed_won_deals, 0), 
            2
        ) AS avg_won_deal_size,
        -- Win rate: Won / (Won + Lost).
        ROUND(
            closed_won_deals * 100.0 / NULLIF(closed_won_deals + closed_lost_deals, 0), 
            2
        ) AS deal_win_rate_pct,
        -- Estimated customer acquisition cost by sales motion.
        CASE 
            WHEN commercial_tier = '1. Small Business (SMB)' THEN 1500.00 -- Automated self-serve & digital ads
            WHEN commercial_tier = '2. Mid-Market' THEN 5000.00          -- Inbound SDR + Account Executive
            WHEN commercial_tier = '3. Enterprise Scale' THEN 25000.00    -- Dedicated Field Sales + Solutions Engineer
            ELSE 1000.00
        END AS estimated_tier_cac,
        0.80 AS gross_margin_pct
    FROM tier_pipeline_performance
)

-- Final unit-economics scorecard.
SELECT
    commercial_tier,
    total_companies,
    total_pipeline_deals,
    closed_won_deals,
    closed_lost_deals,
    total_won_revenue,
    avg_won_deal_size,
    deal_win_rate_pct,
    estimated_tier_cac,
    -- Monthly gross profit per won account.
    ROUND(((avg_won_deal_size / 12.0) * gross_margin_pct)::NUMERIC, 2) AS monthly_gross_profit,
    -- CAC payback period in months.
    ROUND(
        (estimated_tier_cac / NULLIF((avg_won_deal_size / 12.0) * gross_margin_pct, 0))::NUMERIC, 
        1
    ) AS cac_payback_months,
    -- Estimated lifetime value using a 15% annual churn assumption.
    ROUND(
        ((avg_won_deal_size * gross_margin_pct) / 0.15)::NUMERIC, 
        2
    ) AS customer_ltv,
    -- LTV-to-CAC ratio.
    ROUND(
        (((avg_won_deal_size * gross_margin_pct) / 0.15) / estimated_tier_cac)::NUMERIC, 
        2
    ) AS ltv_to_cac_ratio
FROM tier_unit_economics_assumptions
ORDER BY commercial_tier;