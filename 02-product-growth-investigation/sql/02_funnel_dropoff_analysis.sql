WITH deal_stage_flags AS (
    SELECT
        deal_id,
        company_id,
        -- Every opportunity enters the funnel at Prospecting.
        1 AS reached_prospecting,
        
        -- Opportunities that reached Demo Scheduled or beyond.
        CASE 
            WHEN stage IN ('Demo Scheduled', 'Negotiation', 'Closed Won') THEN 1 
            ELSE 0 
        END AS reached_demo,

        -- Opportunities that reached Negotiation or beyond.
        CASE 
            WHEN stage IN ('Negotiation', 'Closed Won') THEN 1 
            ELSE 0 
        END AS reached_negotiation,

        -- Opportunities that reached Closed Won.
        CASE 
            WHEN stage = 'Closed Won' THEN 1 
            ELSE 0 
        END AS reached_closed_won
    FROM 'data/deals.csv'
),

funnel_stages AS (
    SELECT 1 AS step_number, '1. Prospecting' AS step_name, SUM(reached_prospecting) AS deals_count FROM deal_stage_flags
    UNION ALL
    SELECT 2, '2. Demo Scheduled', SUM(reached_demo) FROM deal_stage_flags
    UNION ALL
    SELECT 3, '3. Negotiation', SUM(reached_negotiation) FROM deal_stage_flags
    UNION ALL
    SELECT 4, '4. Closed Won', SUM(reached_closed_won) FROM deal_stage_flags
)

SELECT
    step_number,
    step_name,
    deals_count,
    -- Conversion relative to the top of the funnel.
    ROUND(deals_count * 100.0 / FIRST_VALUE(deals_count) OVER (ORDER BY step_number), 2) AS absolute_conversion_pct,
    -- Conversion from the previous stage.
    ROUND(
        deals_count * 100.0 / COALESCE(LAG(deals_count) OVER (ORDER BY step_number), deals_count), 
        2
    ) AS step_conversion_pct,
    -- Loss between the previous stage and this stage.
    ROUND(
        100.0 - (deals_count * 100.0 / COALESCE(LAG(deals_count) OVER (ORDER BY step_number), deals_count)), 
        2
    ) AS step_dropoff_pct
FROM funnel_stages
ORDER BY step_number;