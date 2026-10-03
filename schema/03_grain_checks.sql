-- Grain checks: COUNT(*) vs COUNT(DISTINCT key)
-- If both counts are equal, the key is unique and defines the table's grain.

-- 1. orders: is order_id unique?
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS distinct_order_ids
FROM orders;
-- Result: 99441 | 99441 → unique ✅


-- 2. customers: is customer_id unique? How many real customers?
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id)        AS distinct_customer_ids,
    COUNT(DISTINCT customer_unique_id) AS distinct_unique_customers
FROM customers;
-- Result: 99441 | 99441 | 96096
-- customer_id is unique, but it is generated per order.
-- Real customers = customer_unique_id (96,096).


-- 3. order_items: is (order_id, order_item_id) unique?
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT (order_id, order_item_id)) AS distinct_keys
FROM order_items;
-- Result: 112650 | 112650 → unique ✅


-- 4. order_payments: is (order_id, payment_sequential) unique?
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT (order_id, payment_sequential)) AS distinct_keys
FROM order_payments;
-- Result: 103886 | 103886 → unique ✅


-- 5. order_reviews: is review_id unique? Is order_id unique?
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT review_id) AS distinct_review_ids,
    COUNT(DISTINCT order_id)  AS distinct_order_ids
FROM order_reviews;
-- Result: 99224 | 98410 | 98673 → neither column is unique on its own ❌


-- 6. order_reviews: is (review_id, order_id) unique?
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT (review_id, order_id)) AS distinct_keys
FROM order_reviews;
-- Result: ___ | ___


-- Findings:
-- customers: customer_id is per order; use customer_unique_id to count real customers (96,096).
-- order_reviews: review_id and order_id are NOT unique on their own.
--   551 orders have multiple reviews, 768 orders have no review.
--   → Aggregate reviews to order level before joining with orders.