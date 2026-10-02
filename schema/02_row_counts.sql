-- Row count check after import (compared with Kaggle source)
-- Purpose: verify that no rows were lost during CSV import.
-- geolocation table excluded (out of scope).

SELECT 'customers'            AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'orders'               AS table_name, COUNT(*) AS row_count FROM orders
UNION ALL
SELECT 'order_items'          AS table_name, COUNT(*) AS row_count FROM order_items
UNION ALL
SELECT 'order_payments'       AS table_name, COUNT(*) AS row_count FROM order_payments
UNION ALL
SELECT 'order_reviews'        AS table_name, COUNT(*) AS row_count FROM order_reviews
UNION ALL
SELECT 'products'             AS table_name, COUNT(*) AS row_count FROM products
UNION ALL
SELECT 'sellers'              AS table_name, COUNT(*) AS row_count FROM sellers
UNION ALL
SELECT 'category_translation' AS table_name, COUNT(*) AS row_count FROM product_category_translation
ORDER BY table_name;

-- Result:
-- category_translation      71
-- customers              99441
-- order_items           112650
-- order_payments        103886
-- order_reviews          99224
-- orders                 99441
-- products               32951
-- sellers                 3095
--
-- All counts match the Kaggle source → no data loss during import.