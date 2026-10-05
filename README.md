# Olist E-Commerce SQL Analysis

🇹🇷 [Türkçe versiyon](README.tr.md)

SQL analysis of ~100K orders (2016–2018) from Olist, a Brazilian e-commerce marketplace, built in
PostgreSQL. The project covers sales trends, product categories, delivery operations, customer
reviews, seller performance and repeat purchases. Each question starts with a metric definition
and ends with a validation step and a cautious interpretation.

**Tools:** PostgreSQL · DataGrip · Git/GitHub
**Dataset:** [Brazilian E-Commerce Public Dataset by Olist (Kaggle)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

---

## About this project

This is my first SQL portfolio project, completed after a sector-focused SQL course by Nafiz Altay
(Udemy). The aim was to apply SQL to a real dataset and to make sure each result is correct, not
only that each query runs. As an Industrial Engineering student, I also read the delivery and
seller results from an operations perspective (lead time, service level, prioritization).

---

## Approach

**Business question → Metric definition → Required tables → SQL → Validation → Interpretation**

### How results were checked

| Practice | Example in this project |
|---|---|
| **Grain checks** | `COUNT(*)` vs `COUNT(DISTINCT key)` for every table ([`schema/03`](schema/03_grain_checks.sql)). Found that `order_reviews` is not unique per order (551 orders have multiple reviews). |
| **Metric definitions** | Written at the top of every analysis file. Orders are counted with `COUNT(DISTINCT order_id)` after joining items; customers with `customer_unique_id` (using `customer_id` would give a 0% repeat rate). |
| **Fan-out prevention** | Reviews are aggregated to order level before joining (Q4). Seller metrics are computed at the (seller, order) level so a delay or review is counted once per order (Q5). |
| **Validation / reconciliation** | Q1: delivered orders in the monthly query = 96,478 (matches `orders`). Q2: category revenues sum to the total delivered revenue (13,221,498.11). Q4: 95,824 reviewed orders = 96,470 delivered orders − 646 without a review. Q5: 97,811 seller-order rows = distinct (seller, order) pairs. Q7: ABC classes add up to 74 categories and 100% of revenue. |
| **NULL handling** | 8 delivered orders without a delivery date are excluded explicitly (a `CASE`-based on-time flag would count them as late). `LEFT JOIN` + `COALESCE` keeps 623 products without a category or translation. Dates are cast to `DATE` because estimated delivery dates are stored at 00:00. |
| **Correlation ≠ causation** | The on-time rate dropped in Nov 2017 (peak volume), but Jan 2018 had similar volume and a 94.3% on-time rate → volume alone does not explain the drops. |
| **Performance** | `EXPLAIN ANALYZE` before and after adding an index; documented which queries the index helps and which it does not. |

---

## Key findings

| Area | Result |
|---|---|
| **Sales** | Delivered orders grew through 2017 (peak: 7,288 in Nov 2017) and were flat to slightly lower in 2018 (7,069 in Jan → 6,351 in Aug). AOV stayed within ~125–150, so the revenue increase is mainly explained by order volume rather than basket size. |
| **Product categories** | 17 of 74 categories (23%) account for 79.7% of revenue; the top 10 account for 62%. `bed_bath_table` sells the most items at a low average price (~93); `watches_gifts` sells about half as many at ~199. |
| **Delivery** | Monthly average delivery time: ~11–17 days; promised: ~23–28 days. The on-time rate was 93–97% in most months, with a low of 81% in Mar 2018, when slower deliveries coincided with the shortest promised lead time of the period. |
| **Reviews** | Late orders: average score 2.27, 62.5% low scores (1–2). On-time orders: 4.29 and 9.3%. A strong association; other factors (seller, region) may affect both. |
| **Sellers** | 5 of the top 10 sellers by revenue have a late rate above the platform average of 6.77% (highest: 10.5%). |
| **Repeat customers** | 2,801 of 93,358 customers (3.0%) have 2+ delivered orders; the order base is dominated by one-time buyers. |
| **Query performance** | An index on `order_items.seller_id` reduced a single-seller query from 70.5 ms to 41.3 ms (~41%) by replacing a full scan with an index scan. |

---

## Operations perspective

- **Delivery as a process:** delivery was measured with two KPIs — lead time (speed) and on-time
  rate (service level) — because one can improve while the other gets worse. The ~10–12 day gap
  between promised and actual delivery is consistent with the high on-time rate; whether shorter
  promises would increase sales cannot be measured with this data.
- **ABC classification:** a standard inventory-prioritization method applied to categories. It
  shows where management attention matters most; it does not show which categories to drop.
- **Seller scorecard:** sellers are compared on volume, late rate and review score together,
  against a platform benchmark, rather than on revenue alone.
- **Measure → change → re-measure:** the indexing work followed this cycle. Removing the scan of
  `order_items` made the next cost (scanning `orders`) the largest remaining step in the plan.

---

## Project structure

```
├── schema/
│   ├── 01_create_tables.sql          # table definitions
│   ├── 02_row_counts.sql             # import check vs Kaggle source
│   └── 03_grain_checks.sql           # what does one row represent?
├── diagrams/
│   └── erd.md                        # entity relationship diagram (Mermaid)
├── analysis/
│   ├── 01_data_quality_checks.sql
│   ├── 02_monthly_sales_trend.sql
│   ├── 03_top_categories_by_revenue.sql
│   ├── 04_delivery_performance.sql
│   ├── 05_late_delivery_vs_reviews.sql
│   ├── 06_seller_performance.sql
│   ├── 07_repeat_customers.sql
│   └── 08_category_pareto_abc.sql    # window functions
├── optimization/
│   └── 01_seller_lookup_index.sql    # EXPLAIN ANALYZE before/after
└── documentation/
    └── assumptions.md                # data decisions & metric rules
```

---

## Data quality & key decisions

Raw data is never modified; issues are handled with filters in queries.
Full list: [`documentation/assumptions.md`](documentation/assumptions.md)

- `customer_id` is generated per order → real customers are counted with `customer_unique_id`.
- `order_reviews` is not unique per order → reviews are aggregated to order level before joining;
  if an order has multiple reviews, the lowest score is used.
- 8 delivered orders have no delivery date → excluded from delivery metrics.
- 610 products have no category and 13 have no English translation → `LEFT JOIN` + fallback
  label, so no revenue is dropped.
- Revenue = `SUM(order_items.price)` of delivered orders (freight excluded).

---

## SQL techniques used

- `INNER JOIN` and `LEFT JOIN` across up to four tables
- CTEs, including multi-step CTE chains
- Window functions: `RANK()`, `SUM() OVER ()`, running totals with
  `SUM() OVER (ORDER BY ... ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)`
- Aggregation: `COUNT(DISTINCT ...)` (including composite keys), `SUM`, `AVG`, `MIN` / `MAX`,
  `COUNT(*) FILTER (WHERE ...)`
- `CASE WHEN` for flags, rates and classification
- Dates: `DATE_TRUNC`, `TO_CHAR`, `::date` casting and date subtraction
- `COALESCE` for fallback labels
- `UNION ALL` (import row-count check)
- `EXPLAIN ANALYZE`, `CREATE INDEX`, `ANALYZE`

---

## Limitations

- **Observational data:** all relationships (e.g. late delivery and low reviews) are associations,
  not proven causes.
- **Incomplete 2016 data:** 2016-09 and 2016-12 have one order each and 2016-11 has none.
- **Late-2018 cut-off:** most Sep–Oct 2018 orders were not yet delivered when the data was
  collected, so they fall out of the delivered filter. Trends are read for 2017-01 to 2018-08.
- **Multi-seller orders:** delivery dates and reviews are order-level, so in orders with several
  sellers a delay or review is attributed to every seller in the order.
- **Repeat-rate bias:** customers whose first order was in late 2018 had little time to return,
  so the 3.0% repeat rate likely understates the true rate.

---

## How to reproduce

1. Download the dataset from Kaggle (CSV files are not included in this repo).
2. Create the tables with `schema/01_create_tables.sql` and import the CSVs.
3. Run `schema/02_row_counts.sql` to verify the import.
4. Run the files in `analysis/` in order.

---

## AI usage

AI tools were used as a tutor and reviewer during this project. Claude guided the workflow with
questions and hints, reviewed my queries for logic errors (grain, joins, NULL handling, metric
definitions), and helped format the files and draft the documentation. For some questions,
including the window-function analysis, I studied AI-suggested solutions (Claude, Gemini) and
worked through the logic step by step before using them.

All queries were run in DataGrip, and results were checked against independent totals as
described above. I can explain the logic of every query in this repository.

---

**Author:** Muhsin Sevinç — Industrial Engineering student