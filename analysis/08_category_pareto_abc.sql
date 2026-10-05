-- Q7 (Advanced SQL). Category Pareto / ABC analysis with window functions
-- Business question: How many categories generate 80% of revenue?
--   How do categories split into A / B / C importance classes?
-- Metric definitions:
--   category / revenue    = same as Q2 (English name → Portuguese name → 'Unknown')
--   revenue_rank          = rank by revenue (1 = highest)
--   revenue_share_pct     = category revenue / total revenue * 100
--   cumulative_share_pct  = running total of revenue share, highest first
--   abc_class             = A: cumulative <= 80% | B: <= 95% | C: rest
-- Window function notes:
--   SUM(...) OVER ()            → grand total next to every row (rows are NOT collapsed)
--   SUM(...) OVER (ORDER BY ... ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
--                               → running total; ROWS + category tie-breaker gives
--                                 deterministic results even if two revenues are equal
--   abc_class is assigned in the outer query: a window result cannot be used
--   inside the same SELECT where it is calculated.


-- A) Category list with ABC class
WITH category_revenue AS (
    SELECT
        COALESCE(pt.product_category_name_english, p.product_category_name, 'Unknown') AS category,
        SUM(oi.price) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p     ON oi.product_id = p.product_id
    LEFT JOIN product_category_translation pt
           ON p.product_category_name = pt.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY category
),
category_pareto AS (
    SELECT
        category,
        revenue,
        RANK() OVER (ORDER BY revenue DESC)                          AS revenue_rank,
        revenue * 100.0 / SUM(revenue) OVER ()                       AS revenue_share_pct,
        SUM(revenue) OVER (ORDER BY revenue DESC, category
                           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
            * 100.0 / SUM(revenue) OVER ()                           AS cumulative_share_pct
    FROM category_revenue
)
SELECT
    revenue_rank,
    category,
    ROUND(revenue::numeric, 2)              AS revenue,
    ROUND(revenue_share_pct::numeric, 2)    AS revenue_share_pct,
    ROUND(cumulative_share_pct::numeric, 2) AS cumulative_share_pct,
    CASE
        WHEN cumulative_share_pct <= 80 THEN 'A'
        WHEN cumulative_share_pct <= 95 THEN 'B'
        ELSE 'C'
    END                                     AS abc_class
FROM category_pareto
ORDER BY revenue_rank;

-- Result: 74 categories. Rank 10 cumulative = 62.43% (matches Q2) ✅
--   Last row cumulative = 100% ✅


-- B) Summary by ABC class
WITH category_revenue AS (
    SELECT
        COALESCE(pt.product_category_name_english, p.product_category_name, 'Unknown') AS category,
        SUM(oi.price) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p     ON oi.product_id = p.product_id
    LEFT JOIN product_category_translation pt
           ON p.product_category_name = pt.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY category
),
category_pareto AS (
    SELECT
        category,
        revenue,
        revenue * 100.0 / SUM(revenue) OVER ()                       AS revenue_share_pct,
        SUM(revenue) OVER (ORDER BY revenue DESC, category
                           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
            * 100.0 / SUM(revenue) OVER ()                           AS cumulative_share_pct
    FROM category_revenue
),
abc_classified AS (
    SELECT
        category,
        revenue_share_pct,
        CASE
            WHEN cumulative_share_pct <= 80 THEN 'A'
            WHEN cumulative_share_pct <= 95 THEN 'B'
            ELSE 'C'
        END AS abc_class
    FROM category_pareto
)
SELECT
    abc_class,
    COUNT(*)                                  AS category_count,
    ROUND(SUM(revenue_share_pct)::numeric, 2) AS revenue_share_pct
FROM abc_classified
GROUP BY abc_class
ORDER BY abc_class;

-- Result:
--   abc_class | category_count | revenue_share_pct
--   A         |             17 |             79.69
--   B         |             16 |             15.14
--   C         |             41 |              5.17
-- Validation: 17 + 16 + 41 = 74 categories; 79.69 + 15.14 + 5.17 = 100% ✅

-- Insight:
--   17 of 74 categories (23%) generate ~80% of revenue → close to the 80/20 rule.
--   41 categories (55%) generate only ~5% → a long tail.
--   ABC tells where to focus management attention (A first), NOT which categories
--   to drop: C categories may add assortment breadth or bring traffic
--   (not measurable with this data).
--   'Unknown' (NULL category) ranks 21st with ~171K revenue → the Phase 2 data quality
--   issue affects real money, not just a few rows.