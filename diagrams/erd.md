# Entity Relationship Diagram

Olist dataset — 8 tables (geolocation excluded). Only key columns shown.

```mermaid
erDiagram
    customers ||--|| orders : "customer_id"
    orders ||--o{ order_items : "order_id"
    orders ||--o{ order_payments : "order_id"
    orders ||--o{ order_reviews : "order_id"
    products ||--o{ order_items : "product_id"
    sellers ||--o{ order_items : "seller_id"
    product_category_translation ||--o{ products : "product_category_name"

    customers {
        text customer_id PK
        text customer_unique_id
    }
    orders {
        text order_id PK
        text customer_id FK
    }
    order_items {
        text order_id PK
        int order_item_id PK
        text product_id FK
        text seller_id FK
    }
    order_payments {
        text order_id PK
        int payment_sequential PK
    }
    order_reviews {
        text review_id PK
        text order_id PK
    }
    products {
        text product_id PK
        text product_category_name FK
    }
    sellers {
        text seller_id PK
    }
```

## Grain notes
- `customer_id` is generated per order → real customers are counted with `customer_unique_id`.
- `order_reviews` grain is `(review_id, order_id)`; some orders have multiple reviews, some have none.
- An order can contain items from multiple sellers (`seller_id` is at item level).
- Never join two N-side tables (e.g. `order_items` and `order_payments`) directly → fan-out.