# Online Store Database

A small PostgreSQL database for a fictional online store, built for the "Introduction to Databases" course project. It models customers, product categories, products, orders, order lines, and payments.

## Files

| File | Purpose |
|---|---|
| `ERD_OnlineStore.mermaid` | Entity-Relationship Diagram, Mermaid source |
| `relationships.png` | Rendered version of the ERD |
| `01_schema.sql` | Table definitions, constraints, indexes |
| `02_sample_data.sql` | Sample rows for every table |
| `03_queries.sql` | Seven demonstration queries |

Run the SQL files in that order (`01` → `02` → `03`) against a PostgreSQL 18 instance.

## Schema overview

Six tables, four relationships:

- **customers → orders** — one customer places many orders.
- **categories → products** — one category groups many products.
- **orders ↔ products**, resolved by **order_items** — an order holds many products, a product can appear in many orders.
- **orders → payments** — one order can be settled by one or more payments.

### customers

Basic contact info plus `created_at`. `email` is unique — it's the natural key I use in a couple of the demo queries to pull up a specific customer.

### categories

Just a name and a description. Kept deliberately simple since the assignment only needed enough structure to demonstrate a one-to-many relationship.

### products

Each product belongs to exactly one category (`category_id`, `NOT NULL`). The foreign key uses `ON DELETE RESTRICT`, so a category that still has products attached to it can't be deleted by accident — you'd have to reassign or remove the products first.

### orders

`status` is constrained to a fixed set of values (`pending`, `processing`, `shipped`, `delivered`, `cancelled`) via a `CHECK` constraint, so the column can't silently drift into typos or made-up states. `total_amount` is stored directly on the order rather than computed on the fly every time; in the sample data I set it by hand to match the sum of that order's line items. In a real application I'd maintain it with an `AFTER INSERT/UPDATE/DELETE` trigger on `order_items` instead, so it can never fall out of sync with the actual line items.

### order_items

The junction table that resolves the many-to-many relationship between orders and products. Two things worth calling out:

- `unit_price` freezes the product's price at the moment of purchase. Without this, a later price change on `products` would quietly rewrite the cost of every past order that included that product — which is obviously wrong.
- `UNIQUE (order_id, product_id)` stops the same product from ending up as two separate rows on the same order. If a customer wants two units of something, that's `quantity = 2` on a single row, not two rows.

### payments

Modeled as its own table rather than as extra columns on `orders`. The main reason is that an order should, in principle, be able to have more than one payment attached to it — a partial payment, or a second attempt after a failed one. `ON DELETE CASCADE` on the foreign key means deleting an order also removes its payment records, which makes sense since a payment without an order to belong to isn't meaningful data.

## Indexes

PostgreSQL doesn't automatically index foreign key columns, so every FK column that gets used as a join key in `03_queries.sql` is indexed explicitly in the schema: `products.category_id`, `orders.customer_id`, `order_items.order_id`, `order_items.product_id`, and `payments.order_id`.

## Sample data

5 customers, 4 categories, 9 products (spread across all four categories), 6 orders, 10 order lines, and 6 payments. One customer (Ana) has two orders, so the one-to-many relationship between customers and orders is actually exercised rather than just declared in the schema.

## Queries

`03_queries.sql` has seven queries, each with a comment explaining its purpose and the SQL feature it's meant to demonstrate:

1. **Full order history for one customer** — multi-table `JOIN`, `ORDER BY`.
2. **Products in a category under a price threshold** — `JOIN` with a `WHERE` range condition.
3. **Revenue per category** — `JOIN` across four tables, `GROUP BY`, `SUM`, `ROUND`.
4. **Customers who've never ordered anything** — `LEFT JOIN` with `IS NULL`, as an alternative to `NOT EXISTS` / `NOT IN`.
5. **Top 3 best-selling products by quantity** — `GROUP BY`, `SUM`, `ORDER BY` + `LIMIT`.
6. *(bonus)* **Orders with a pending or failed payment** — `JOIN`, `WHERE ... IN`.
7. *(bonus)* **Customers whose average order value beats the store-wide average** — `GROUP BY` + `HAVING`, `AVG`, correlated subquery.

## Running it locally

```bash
createdb online_store
psql -d online_store -f 01_schema.sql
psql -d online_store -f 02_sample_data.sql
psql -d online_store -f 03_queries.sql
```

`01_schema.sql` drops any existing tables first (children before parents), so it's safe to re-run the whole set from scratch at any point.
