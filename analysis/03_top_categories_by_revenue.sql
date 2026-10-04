-- Q2. Top categories by revenue
-- Business question: Which product categories generate the most revenue?
--   Is it driven by sales volume or by price?
-- Metric definitions:
--   category       = English name → Portuguese name (no translation) → 'Unknown' (NULL category)
--   order_count    = delivered orders containing at least one item from the category
--   items_sold     = number of order items sold
--   revenue        = SUM(order_items.price), freight excluded (same as Q1)
--   avg_item_price = revenue / items_sold

SELECT
    COALESCE(pt.product_category_name_english, p.product_category_name, 'Unknown') AS category,
    COUNT(DISTINCT o.order_id)                                       AS order_count,
    COUNT(oi.order_item_id)                                          AS items_sold,
    ROUND(SUM(oi.price)::numeric, 2)                                 AS revenue,
    ROUND((SUM(oi.price) / COUNT(oi.order_item_id))::numeric, 2)     AS avg_item_price
FROM orders o
JOIN order_items oi
  ON o.order_id = oi.order_id
JOIN products p
  ON oi.product_id = p.product_id
LEFT JOIN product_category_translation pt
  ON p.product_category_name = pt.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY category
ORDER BY revenue DESC
LIMIT 10;

-- Result (top 3):
--   health_beauty   | 8,647 orders |  9,465 items | 1,233,131.72 | avg 130.28
--   watches_gifts   | 5,495 orders |  5,859 items | 1,166,176.98 | avg 199.04
--   bed_bath_table  | 9,272 orders | 10,953 items | 1,023,434.76 | avg  93.44

-- Validation: SUM of revenue across ALL categories (no LIMIT) = 13,221,498.11
--   = total delivered revenue → INNER JOIN to products loses no sales ✅

-- Notes:
--   order_count cannot be summed across categories: an order with items from
--   2 categories is counted in both.

-- Insight:
--   Two different revenue models:
--     bed_bath_table = volume-driven (most items sold, low avg price ~93).
--     watches_gifts  = price-driven (about half the items, avg price ~199).
--   Top 10 categories generate ~62% of total revenue (8.25M / 13.22M)
--     → revenue is concentrated in a few categories (analyzed further in Phase 4).