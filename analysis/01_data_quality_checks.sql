-- Data quality checks
-- Goal: find missing, inconsistent or unmatched records before business analysis.
-- Raw data is NOT modified; issues are handled with filters (see documentation/assumptions.md).


-- 1. Order status distribution
SELECT
    order_status,
    COUNT(*) AS order_count
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;
-- Result: delivered 96,478 | shipped 1,107 | canceled 625 | unavailable 609
--         invoiced 314 | processing 301 | created 5 | approved 2  (total 99,441)
-- Impact: Only delivered orders represent realized sales and completed deliveries.
--         Analyses will filter with order_status = 'delivered' (whitelist).


-- 2. Delivered orders with missing delivery date
SELECT
    COUNT(*) AS delivered_without_date
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;
-- Result: 8
-- Impact: AVG() silently skips NULLs, but CASE-based on-time flags would count
--         these orders as "late". Delivery metrics exclude them explicitly.


-- 3. Delivery date earlier than purchase date (impossible timeline)
SELECT
    COUNT(*) AS invalid_timeline_orders
FROM orders
WHERE order_delivered_customer_date < order_purchase_timestamp;
-- Result: 0 ✅
-- Impact: No negative delivery times; delivery duration calculations are safe.


-- 4.1 Products with NULL category
SELECT
    COUNT(*) AS null_category_products
FROM products
WHERE product_category_name IS NULL;
-- Result: 610


-- 4.2 Products whose category has no English translation
SELECT
    COUNT(p.product_id) AS untranslated_products
FROM products p
LEFT JOIN product_category_translation pt
       ON p.product_category_name = pt.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND pt.product_category_name IS NULL;
-- Result: 13
-- Impact (4.1 + 4.2): An INNER JOIN to the translation table would silently drop
--         623 products and their sales. Category analyses use LEFT JOIN
--         with a fallback label.