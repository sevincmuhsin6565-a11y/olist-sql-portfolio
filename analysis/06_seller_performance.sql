-- Q5. Seller performance (scorecard)
-- Business question: Are the top-revenue sellers also good at on-time delivery
--   and customer satisfaction?
-- Metric definitions:
--   order_count      = delivered orders the seller is part of
--   revenue          = SUM(order_items.price) of the seller's items
--   late_rate_pct    = % of the seller's orders delivered after the estimated date
--   avg_review_score = average review score of the seller's orders (reviewed orders only)
-- Grain: data is first reduced to ONE ROW PER (seller, order) to avoid counting
--   the same delay/review multiple times when a seller has several items in an order.
-- Assumptions:
--   Delivery date and review are order-level. In multi-seller orders, a delay or
--   review is attributed to every seller in the order (cannot be separated).
--   Delivered orders with a delivery date only (Phase 2) → 8 orders excluded.

WITH review_cte AS (
    SELECT
        order_id,
        MIN(review_score) AS final_score
    FROM order_reviews
    GROUP BY order_id
),
seller_orders AS (
    SELECT
        oi.seller_id,
        o.order_id,
        SUM(oi.price) AS order_revenue,
        MAX(CASE
                WHEN o.order_delivered_customer_date::date
                     > o.order_estimated_delivery_date::date THEN 1.0
                ELSE 0.0
            END)      AS is_late
    FROM order_items oi
    JOIN orders o
      ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL   -- Phase 2 decision
    GROUP BY oi.seller_id, o.order_id
)
SELECT
    so.seller_id,
    COUNT(so.order_id)                        AS order_count,
    ROUND(SUM(so.order_revenue)::numeric, 2)  AS revenue,
    ROUND(AVG(so.is_late) * 100, 2)           AS late_rate_pct,
    ROUND(AVG(r.final_score), 2)              AS avg_review_score
FROM seller_orders so
LEFT JOIN review_cte r                         -- LEFT JOIN: keep revenue of orders without reviews
  ON so.order_id = r.order_id
GROUP BY so.seller_id
ORDER BY revenue DESC
LIMIT 10;

-- Benchmark: platform-wide late rate = 6.77%
--   (same filter, SUM-free version of Q3 without GROUP BY)

-- Validation: seller_orders rows = 97,811 = distinct (seller_id, order_id) pairs ✅

-- Result (seller_id shortened):
--   seller   | orders | revenue    | late_% | review
--   4869f7a5 |  1,124 | 226,987.93 |  10.50 | 4.15
--   53243585 |    348 | 217,940.44 |   3.45 | 4.19
--   4a3ca931 |  1,772 | 196,882.12 |   9.71 | 3.85
--   fa1c13f2 |    578 | 190,917.14 |   9.17 | 4.37
--   7c67e144 |    973 | 186,570.05 |   9.15 | 3.49
--   ...      (top 10 shown when the query is run)

-- Insight:
--   1. 5 of the top 10 sellers are late more often than the platform average (6.77%).
--      The #1 seller (10.5%) is ~1.5x the average: high volume amplifies the delay problem.
--   2. Delay does not explain every low score. Seller 7c67e144 has a 9.15% late rate,
--      which would suggest a score of ~4.10 (using Q4 scores: 2.27 late / 4.29 on time),
--      but the actual score is 3.49. Hypothesis: other problems (product quality,
--      wrong items, packaging). Not provable with this data.
--   3. Different revenue models again: 53243585 earns ~626 per order with only 348 orders
--      (price-driven); 4a3ca931 has 1,772 orders (volume-driven).