-- Q3. Delivery performance (monthly)
-- Business question: How long does delivery take, and how often is the
--   estimated delivery date (the promise to the customer) met?
-- Metric definitions:
--   delivered_orders   = delivered orders with a delivery date (Phase 2 decision)
--   avg_delivery_days  = purchase date → delivered to customer (days)
--   avg_estimated_days = purchase date → estimated delivery date (the promise, days)
--   on_time_rate_pct   = % of orders delivered on or before the estimated date
-- Note: both dates are cast to DATE. Estimated dates are stored at 00:00,
--   so comparing timestamps would mark same-day deliveries as late.

SELECT
    TO_CHAR(DATE_TRUNC('month', order_purchase_timestamp), 'YYYY-MM') AS month,
    COUNT(order_id)                                                 AS delivered_orders,
    ROUND(AVG(order_delivered_customer_date::date
              - order_purchase_timestamp::date), 2)                 AS avg_delivery_days,
    ROUND(AVG(order_estimated_delivery_date::date
              - order_purchase_timestamp::date), 2)                 AS avg_estimated_days,
    ROUND(AVG(CASE
                  WHEN order_delivered_customer_date::date
                       <= order_estimated_delivery_date::date THEN 1.0
                  ELSE 0.0
              END) * 100, 2)                                        AS on_time_rate_pct
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL   -- Phase 2 decision
GROUP BY DATE_TRUNC('month', order_purchase_timestamp)
ORDER BY DATE_TRUNC('month', order_purchase_timestamp);

-- Validation: SUM of delivered_orders = 96,470 (expected 96,470 = 96,478 - 8 without date)

-- Result (selected months):
--   month   | orders | delivery_days | estimated_days | on_time_%
--   2017-10 |  4,478 |     11.73     |     23.66      |   95.82
--   2017-11 |  7,288 |     15.07     |     23.20      |   87.60
--   2018-01 |  7,069 |     14.01     |     26.94      |   94.30
--   2018-02 |  6,555 |     16.87     |     25.16      |   85.87
--   2018-03 |  7,003 |     16.24     |     22.67      |   81.04  ← lowest
--   2018-04 |  6,798 |     11.42     |     24.31      |   95.50

-- Insight:
--   1. Olist delivers in ~11-17 days but promises ~23-28 days. This ~10-12 day
--      buffer keeps the on-time rate high (usually 93-97%).
--      Trade-off: long promises protect the on-time KPI but may reduce conversion
--      (not measurable with this data).
--   2. On-time rate dropped in 2017-11 (peak volume) and in 2018-02/03.
--   3. Correlation ≠ causation: 2018-01 had similar volume (7,069) but 94.3% on-time,
--      so high volume alone does not explain the drops.
--   4. 2018-03 (lowest, 81%): slower delivery (16.2 days) combined with the
--      shortest promise (22.7 days) → less buffer → more late orders.