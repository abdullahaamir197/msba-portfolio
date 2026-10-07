-- ====================================================================
-- Script: build_triangulation_matrix.sql
-- Builds the four-quadrant matrix linking customer issues to commercial impact.
-- Dialect: DuckDB / PostgreSQL
-- ====================================================================

WITH issue_commercial_impact AS (
    SELECT
        t.subject AS customer_issue,
        COUNT(DISTINCT t.ticket_id) AS ticket_volume,
        COUNT(DISTINCT t.associated_company_id) AS affected_companies,
        -- Count lost deals associated with companies reporting this issue.
        COUNT(DISTINCT CASE WHEN d.stage = 'Closed Lost' THEN d.deal_id END) AS associated_closed_lost_deals,
        -- Estimate the revenue associated with those lost deals.
        COALESCE(SUM(CASE WHEN d.stage = 'Closed Lost' THEN TRY_CAST(d.amount AS NUMERIC) ELSE 0 END), 0) AS associated_lost_deal_revenue,
        -- Average ticket resolution time.
        ROUND(AVG((EXTRACT(EPOCH FROM (TRY_CAST(t.closed_date AS TIMESTAMP) - TRY_CAST(t.createdate AS TIMESTAMP))) / 3600.0))::NUMERIC, 1) AS avg_resolution_hours
    FROM 'data/tickets.csv' t
    LEFT JOIN 'data/deals.csv' d
        ON t.associated_company_id = d.company_id
    GROUP BY t.subject
)

SELECT
    customer_issue,
    ticket_volume,
    affected_companies,
    associated_closed_lost_deals,
    associated_lost_deal_revenue,
    avg_resolution_hours,
    -- Classify each issue using ticket volume and a USD 250,000 revenue threshold.
    CASE 
        WHEN ticket_volume >= 20 AND associated_lost_deal_revenue >= 250000 
            THEN 'Quadrant 1: Core System Fix (High Vocal + High Financial Impact)'
        WHEN ticket_volume >= 20 AND associated_lost_deal_revenue < 250000 
            THEN 'Quadrant 2: The Vocal Trap (High Vocal + Low Financial Impact)'
        WHEN ticket_volume < 20 AND associated_lost_deal_revenue >= 250000 
            THEN 'Quadrant 3: Under-reported risk (Low Vocal + High Financial Impact)'
        ELSE 'Quadrant 4: Minor Operational Defect (Low Vocal + Low Impact)'
    END AS triangulation_quadrant,
    -- Suggest a proportionate response.
    CASE 
        WHEN ticket_volume < 20 AND associated_lost_deal_revenue >= 250000 
            THEN 'PRIORITY 1 SPRINT (Protect Enterprise Retention)'
        WHEN ticket_volume >= 20 AND associated_lost_deal_revenue >= 250000 
            THEN 'PRIORITY 2 SPRINT (Core Reliability)'
        WHEN ticket_volume >= 20 AND associated_lost_deal_revenue < 250000 
            THEN 'DEFER (Validate Demand Before Roadmap Investment)'
        ELSE 'STANDARD BACKLOG'
    END AS architectural_action
FROM issue_commercial_impact
ORDER BY associated_lost_deal_revenue DESC, ticket_volume DESC;