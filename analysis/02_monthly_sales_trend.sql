-- Q1. Monthly sales trend
-- Business question: How do order count, revenue and average order value change by month?
-- Metric definitions:
--   order_count     = number of delivered orders (by purchase month)
--   revenue         = SUM(order_items.price), freight excluded
--   avg_order_value = revenue / order_count

SELECT
    TO_CHAR(DATE_TRUNC('month', o.order_purchase_timestamp), 'YYYY-MM') AS month,
    COUNT(DISTINCT o.order_id)                                        AS order_count,
    ROUND(SUM(oi.price)::numeric, 2)                                  AS revenue,
    ROUND((SUM(oi.price) / COUNT(DISTINCT o.order_id))::numeric, 2)   AS avg_order_value
FROM orders o
JOIN order_items oi
  ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
ORDER BY DATE_TRUNC('month', o.order_purchase_timestamp);

-- Validation: total delivered orders in this query = 96,478 (matches orders table) ✅
--   → every delivered order has at least one item; INNER JOIN drops nothing.

-- Data notes:
--   2016 months are incomplete (1 order in 2016-09 and 2016-12, 2016-11 missing).
--   Sep-Oct 2018 orders are mostly not delivered yet → cut off by the delivered filter.
--   Trend is interpreted for 2017-01 to 2018-08 only.

-- Insight:
--   2017: strong growth in order volume; peak month is 2017-11.
--     Hypothesis: Black Friday promotions (timing matches, but not provable with this data).
--   2018: growth stopped. Orders moved sideways with a slight decline
--     (7,069 in Jan → 6,351 in Aug). Not conclusive: the last months may be
--     slightly affected by the delivery cut-off.
--   2018 revenue peaked in Apr-May (~975K) because AOV was higher (143-145),
--     not because there were more orders.
--   AOV stays in a narrow range (~125-150): overall growth came from more orders,
--     not bigger baskets.