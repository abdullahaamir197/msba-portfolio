-- Create permanent shortcuts so we never type the file path again!
CREATE OR REPLACE TABLE order_items AS 
    SELECT * FROM '01-operational-transformation/Olist_dataset/olist_order_items_dataset.csv';

CREATE OR REPLACE TABLE orders AS 
    SELECT * FROM '01-operational-transformation/Olist_dataset/olist_orders_dataset.csv';

CREATE OR REPLACE TABLE customers AS 
    SELECT * FROM '01-operational-transformation/Olist_dataset/olist_customers_dataset.csv';

CREATE OR REPLACE TABLE sellers AS 
    SELECT * FROM '01-operational-transformation/Olist_dataset/olist_sellers_dataset.csv';

CREATE OR REPLACE TABLE products AS 
    SELECT * FROM '01-operational-transformation/Olist_dataset/olist_products_dataset.csv';

CREATE OR REPLACE TABLE order_reviews AS 
    SELECT * FROM '01-operational-transformation/Olist_dataset/olist_order_reviews_dataset.csv';




SELECT 
    CASE 
        WHEN s.seller_state = c.customer_state THEN 'Same State (Local)'
        ELSE 'Interstate (Cross-Country)'
    END AS route_type,
    COUNT(oi.order_id) AS total_items,
    SUM(oi.freight_value) AS total_freight_brl,
    ROUND(AVG(oi.freight_value), 2) AS avg_freight_brl

FROM order_items oi
JOIN orders o     ON oi.order_id = o.order_id
JOIN customers c  ON o.customer_id = c.customer_id
JOIN sellers s    ON oi.seller_id = s.seller_id

WHERE o.order_status = 'delivered'

GROUP BY 
    CASE 
        WHEN s.seller_state = c.customer_state THEN 'Same State (Local)'
        ELSE 'Interstate (Cross-Country)'
    END;


SELECT 
    -- 1. CLASSIFY SLA PERFORMANCE
    CASE 
        WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'On-Time / Early'
        ELSE 'Late (SLA Breached)'
    END AS delivery_performance,
    
    -- 2. VOLUME OF ORDERS
    COUNT(order_id) AS total_orders,
    
    -- 3. LEG 1: SELLER DISPATCH TIME (DAYS)
    ROUND(AVG(DATE_DIFF('day', order_purchase_timestamp, order_delivered_carrier_date)), 1) AS avg_seller_dispatch_days,
    
    -- 4. LEG 2: CARRIER TRANSIT TIME (DAYS)
    ROUND(AVG(DATE_DIFF('day', order_delivered_carrier_date, order_delivered_customer_date)), 1) AS avg_carrier_transit_days,
    
    -- 5. TOTAL DOORSTEP CYCLE TIME (DAYS)
    ROUND(AVG(DATE_DIFF('day', order_purchase_timestamp, order_delivered_customer_date)), 1) AS avg_total_cycle_days

FROM orders

WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_delivered_carrier_date IS NOT NULL

GROUP BY 
    CASE 
        WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'On-Time / Early'
        ELSE 'Late (SLA Breached)'
    END;


-- ============================================================================
-- QUERY 3: Multi-Seller Split Shipments & Freight Penalty
-- Business Objective: Measure how much extra freight we burn when an order 
--                     is split across multiple independent sellers.
-- Tables Used: order_items
-- ============================================================================

-- ----------------------------------------------------------------------------
-- PHASE 1: THE FIRST CALCULATOR (CTE)
-- Collapse order_items down to the ORDER grain (1 row per order)
-- ----------------------------------------------------------------------------
WITH order_seller_summary AS (
    SELECT 
        order_id,
        
        -- Count how many DIFFERENT sellers are fulfilling this single order
        COUNT(DISTINCT seller_id) AS total_sellers,
        
        -- Sum up all freight fees charged across all items in this order
        SUM(freight_value) AS total_order_freight
        
    FROM order_items
    GROUP BY order_id
)


SELECT 
    -- 1. THE LABEL: Classify whether the order was split or consolidated
    CASE 
        WHEN total_sellers > 1 THEN 'Multi-Seller (Split Shipment)'
        ELSE 'Single-Seller (Consolidated)'
    END AS fulfillment_type,
    
    -- 2. VOLUME: Total orders in each bucket
    COUNT(order_id) AS total_orders,
    
    -- 3. VOLUME SHARE: % of our entire order volume
    ROUND(
        100.0 * COUNT(order_id) / SUM(COUNT(order_id)) OVER (), 
        2
    ) AS pct_of_total_orders,
    
    -- 4. TOTAL FREIGHT CASH: Total money paid to carriers for this bucket
    ROUND(SUM(total_order_freight), 2) AS total_freight_paid_brl,
    
    -- 5. UNIT ECONOMICS: Average freight cost paid PER ORDER
    ROUND(AVG(total_order_freight), 2) AS avg_freight_per_order_brl

-- Read from our Phase 1 calculator
FROM order_seller_summary

-- Group by the exact label we created in the SELECT
GROUP BY 
    CASE 
        WHEN total_sellers > 1 THEN 'Multi-Seller (Split Shipment)'
        ELSE 'Single-Seller (Consolidated)'
    END;



SELECT 
    CASE 
        WHEN p.product_weight_g < 1000 THEN '1. Lightweight (< 1kg)'
        WHEN p.product_weight_g <= 5000 THEN '2. Mediumweight (1kg - 5kg)'
        ELSE '3. Heavyweight (> 5kg)'
    END AS product_weight_class,
    
    COUNT(oi.order_id) AS total_items,
    ROUND(AVG(oi.freight_value), 2) AS avg_freight_brl,
    ROUND(AVG(DATE_DIFF('day', o.order_delivered_carrier_date, o.order_delivered_customer_date)), 1) AS avg_transit_days

FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o   ON oi.order_id = o.order_id

WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND p.product_weight_g IS NOT NULL

GROUP BY 
    CASE 
        WHEN p.product_weight_g < 1000 THEN '1. Lightweight (< 1kg)'
        WHEN p.product_weight_g <= 5000 THEN '2. Mediumweight (1kg - 5kg)'
        ELSE '3. Heavyweight (> 5kg)'
    END

ORDER BY product_weight_class ASC;


SELECT 
    -- 1. THE LABEL: Did delivery beat or breach the promised deadline?
    CASE 
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'Late (SLA Breached)'
        ELSE 'On-Time / Early'
    END AS delivery_performance,
    
    -- 2. TOTAL VOLUME IN EACH BUCKET
    COUNT(o.order_id) AS total_reviews,
    
    -- 3. AVERAGE CUSTOMER SATISFACTION (CSAT: 1.0 to 5.0)
    ROUND(AVG(r.review_score), 2) AS avg_csat_score,
    
    -- 4. TOTAL 1-STAR REVIEWS (ANGRY CUSTOMERS)
    COUNT(CASE WHEN r.review_score = 1 THEN 1 END) AS total_1_star_reviews,
    
    -- 5. PERCENTAGE OF 1-STAR REVIEWS
    ROUND(
        100.0 * COUNT(CASE WHEN r.review_score = 1 THEN 1 END) / COUNT(o.order_id), 
        2
    ) AS pct_1_star_reviews

FROM orders o
JOIN order_reviews r ON o.order_id = r.order_id

-- WHERE comes BEFORE GROUP BY
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL

-- Group by the exact label
GROUP BY 
    CASE 
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'Late (SLA Breached)'
        ELSE 'On-Time / Early'
    END;