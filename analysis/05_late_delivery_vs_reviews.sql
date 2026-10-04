-- Q4. Late delivery vs review score
-- Business question: Do late deliveries receive lower review scores than on-time ones?
-- Metric definitions:
--   delivery_status    = 'On time' if delivered on/before estimated date (DATE compare, same as Q3)
--   order_count        = delivered orders with a delivery date AND at least one review
--   avg_review_score   = average review score (1-5)
--   low_score_rate_pct = % of orders with score <= 2
-- Review handling: reviews are aggregated to order level first (Phase 1 finding).
--   If an order has multiple reviews, the LOWEST score is used (worst experience).
--   Affects 551 orders only.

WITH review_cte AS (
    SELECT
        order_id,
        MIN(review_score) AS final_score
    FROM order_reviews
    GROUP BY order_id
)
SELECT
    CASE
        WHEN o.order_delivered_customer_date::date
             <= o.order_estimated_delivery_date::date THEN 'On time'
        ELSE 'Late'
    END                                                              AS delivery_status,
    COUNT(DISTINCT o.order_id)                                       AS order_count,
    ROUND(AVG(r.final_score), 2)                                     AS avg_review_score,
    ROUND(AVG(CASE WHEN r.final_score <= 2 THEN 1.0 ELSE 0.0 END) * 100, 2) AS low_score_rate_pct
FROM orders o
JOIN review_cte r                                 -- INNER JOIN: orders without reviews are excluded
  ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL  -- Phase 2 decision
GROUP BY delivery_status;

-- Result:
--   delivery_status | order_count | avg_review_score | low_score_rate_pct
--   On time         |      89,443 |             4.29 |               9.31
--   Late            |       6,381 |             2.27 |              62.47

-- Validation:
--   review_cte rows = 98,673 = distinct order_ids in order_reviews → one row per order ✅
--   On time + Late = 95,824 = 96,470 delivered orders - 646 delivered orders without a review ✅

-- Insight:
--   Late orders are only ~6.7% of reviewed orders, but 62.5% of them get a low score
--   (vs 9.3% for on-time orders, ~6.7x higher). Average score drops from 4.29 to 2.27.
--   Late delivery is STRONGLY ASSOCIATED with low reviews. Not proven as the only cause:
--   confounders like seller or customer region may affect both delay and satisfaction.
--   Business takeaway: a small operational problem creates a disproportionately
--   large customer satisfaction problem.