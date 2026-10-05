-- Q6. Repeat customer rate
-- Business question: What share of customers buy more than once?
-- Metric definitions:
--   total_customers  = real customers (customer_unique_id) with >= 1 delivered order
--   repeat_customers = real customers with >= 2 delivered orders
--   repeat_rate_pct  = repeat_customers / total_customers * 100
-- Note: customer_id is generated per order → counting by customer_id gives 0% by design.

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(o.order_id) AS order_count     -- orders:customers is 1:1, no fan-out
    FROM orders o
    JOIN customers c
      ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(*)                                                         AS total_customers,
    COUNT(*) FILTER (WHERE order_count >= 2)                         AS repeat_customers,
    ROUND(COUNT(*) FILTER (WHERE order_count >= 2) * 100.0 / COUNT(*), 2) AS repeat_rate_pct
FROM customer_orders;

-- Result: 93,358 customers | 2,801 repeat customers | 3.00%

-- Validation: SUM(order_count) in customer_orders = 96,478 = all delivered orders ✅
--   → every delivered order is assigned to exactly one customer; nothing lost or double-counted.

-- Insight:
--   97% of customers bought only once. Combined with Q1 (growth came from more orders,
--   not bigger baskets), growth is driven almost entirely by NEW customer acquisition.
--   Caution: customers who joined in mid/late 2018 had little time to return
--   (observation window) → the true repeat rate is likely somewhat higher.
--   Low repeat rate ≠ dissatisfaction: durable products have low purchase frequency, and
--   Olist sells through large marketplaces, so customers may not see it as one store.
--   Opportunity: retention. Hypothesis (not tested): late deliveries (Q4) may also
--   reduce the chance of a repeat purchase.