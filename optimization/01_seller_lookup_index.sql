-- Query optimization: seller lookup with EXPLAIN ANALYZE + index
-- Scenario: a seller dashboard runs this query for ONE seller every time it opens.
-- Goal: measure the plan, add an index, and prove the effect (before vs after).

-- Query (top seller from Q5)
EXPLAIN ANALYZE
SELECT
    COUNT(DISTINCT oi.order_id) AS order_count,   -- DISTINCT: count orders, not items
    SUM(oi.price)               AS revenue
FROM order_items oi
JOIN orders o
  ON oi.order_id = o.order_id
WHERE oi.seller_id = '4869f7a5dfa277a7dca6462dcf3b52b2'
  AND o.order_status = 'delivered';
-- Result (without EXPLAIN ANALYZE): 1,124 orders | 226,987.93 revenue (matches Q5) ✅
-- Note: an earlier version used COUNT(oi.order_id) and returned 1,148 = items, not orders.


-- BEFORE (no index on seller_id)
--   order_items: Parallel Seq Scan → whole table read
--     Rows Removed by Filter: 55,747 per worker x 2 ≈ 111,000 rows read and discarded
--   Execution Time: 70.5 ms

-- Optimization
CREATE INDEX idx_order_items_seller_id ON order_items (seller_id);
ANALYZE order_items;   -- refresh table statistics so the planner can use the index
-- An index does not change the data; raw data stays untouched.

-- AFTER (index on seller_id)
--   order_items: Bitmap Index Scan on idx_order_items_seller_id
--     → found 1,156 rows directly (0.16 ms, 4 pages), no rows discarded
--   Execution Time: 41.3 ms  → ~41% faster

-- Findings:
--   1. The index removed the full scan of order_items (~111K wasted rows → 0).
--   2. New bottleneck: orders is still fully scanned and hashed (96,478 rows)
--      just to match ~1,150 rows. Fixing one bottleneck reveals the next one.
--      Possible next step: let the join use the orders primary key (not done here).
--   3. This index does NOT help Q5 (all sellers): a query that needs every row is
--      cheaper as a sequential scan. Indexes help SELECTIVE queries (~1% of rows here).
--   4. Trade-off: each index uses disk space and slows down INSERT/UPDATE.
--      Add indexes for frequent, selective queries only.
--   5. Scale: Seq Scan time grows linearly with table size; index lookup stays almost
--      constant. On 100M rows, the same difference would be seconds, not milliseconds.

-- To reset: DROP INDEX idx_order_items_seller_id;