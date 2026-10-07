-- ====================================================================
-- Script: 03_ttv_and_cancellation_sequencing.sql
-- Support sequencing and churn-risk analysis.
-- Dialect: DuckDB / PostgreSQL
-- ====================================================================

WITH ticket_resolution_metrics AS (
    -- Clean timestamps and calculate ticket resolution time in hours.
    SELECT
        ticket_id,
        associated_company_id AS company_id,
        priority,
        status,
        TRY_CAST(createdate AS TIMESTAMP) AS ticket_created_at,
        TRY_CAST(closed_date AS TIMESTAMP) AS ticket_closed_at,
        -- Resolution time in hours.
        ROUND(
            (EXTRACT(EPOCH FROM (TRY_CAST(closed_date AS TIMESTAMP) - TRY_CAST(createdate AS TIMESTAMP))) / 3600.0)::NUMERIC, 
            2
        ) AS resolution_hours
    FROM 'data/tickets.csv'
),

deals_with_support_history AS (
    -- Link each deal to tickets created during the preceding 60 days.
    SELECT
        d.deal_id,
        d.deal_name,
        d.stage,
        d.amount,
        TRY_CAST(d.close_date AS DATE) AS deal_close_date,
        t.ticket_id,
        t.priority,
        t.resolution_hours,
        -- Days between ticket creation and deal close.
        ROUND(
            (EXTRACT(EPOCH FROM (TRY_CAST(d.close_date AS TIMESTAMP) - t.ticket_created_at)) / 86400.0)::NUMERIC, 
            1
        ) AS warning_lead_time_days
    FROM 'data/deals.csv' d
    LEFT JOIN ticket_resolution_metrics t
        ON d.company_id = t.company_id
       -- Keep tickets created before close and within the 60-day window.
       AND t.ticket_created_at <= TRY_CAST(d.close_date AS TIMESTAMP)
       AND t.ticket_created_at >= TRY_CAST(d.close_date AS TIMESTAMP) - INTERVAL '60 days'
)

-- Compare support friction across Closed Won, Closed Lost, and Negotiation stages.
SELECT
    stage,
    COUNT(DISTINCT deal_id) AS total_deals,
    -- Deals with at least one support ticket before the decision.
    COUNT(DISTINCT CASE WHEN ticket_id IS NOT NULL THEN deal_id END) AS deals_with_support_friction,
    -- Share of deals linked to support activity.
    ROUND(
        COUNT(DISTINCT CASE WHEN ticket_id IS NOT NULL THEN deal_id END) * 100.0 / 
        COUNT(DISTINCT deal_id), 
        2
    ) AS support_attachment_pct,
    -- Average ticket resolution time.
    ROUND(AVG(resolution_hours)::NUMERIC, 2) AS avg_resolution_time_hours,
    -- Share of linked tickets marked High or Urgent.
    ROUND(
        COUNT(CASE WHEN priority IN ('High', 'Urgent') THEN 1 END) * 100.0 / 
        NULLIF(COUNT(ticket_id), 0), 
        2
    ) AS high_priority_ticket_pct,
    -- Average time between ticket creation and deal close.
    ROUND(AVG(warning_lead_time_days)::NUMERIC, 1) AS avg_warning_lead_time_days
FROM deals_with_support_history
WHERE stage IN ('Closed Won', 'Closed Lost', 'Negotiation')
GROUP BY stage
ORDER BY total_deals DESC;