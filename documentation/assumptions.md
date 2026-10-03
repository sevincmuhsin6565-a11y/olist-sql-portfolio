# Assumptions & Data Decisions

Raw data is never modified. All data quality issues are handled with filters in queries.

| Topic | Decision | Reason |
|---|---|---|
| Delivery metrics | `order_status = 'delivered'` AND `order_delivered_customer_date IS NOT NULL` (96,470 orders) | 8 delivered orders have no delivery date |
| Sales / revenue | Delivered orders only ("realized revenue") | Canceled / undelivered orders are not revenue. Trade-off: 1,107 `shipped` orders excluded |
| Customer count | `customer_unique_id` | `customer_id` is generated per order |
| Reviews | Aggregate to order level before joining | Some orders have multiple reviews |
| Categories | LEFT JOIN to translation table, fallback label for missing | 610 products have NULL category, 13 have no translation |
| Geolocation | Excluded | Not needed for the business questions |