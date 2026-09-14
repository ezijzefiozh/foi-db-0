# Online Store Database — Implementation Documentation

## 1. Overview

This folder contains the PostgreSQL implementation of the database model designed in Part 2 of the project (see `ERD_OnlineStore.mermaid` for the diagram). The database represents a simple **online store**, where customers place orders that contain one or several products, and orders are settled through one or more payments.

## 2. Files in this repository

| File | Content |
|---|---|
| `01_schema.sql` | `CREATE TABLE` statements, primary keys, foreign keys, `CHECK` constraints, and indexes |
| `02_sample_data.sql` | Sample rows for every table, used to test and demonstrate the queries |
| `03_queries.sql` | Seven SQL queries demonstrating the key features of the database |
| `README.md` | This documentation file |

## 3. How to run the project (PostgreSQL)

```bash
# 1. Create a new empty database
createdb online_store

# 2. Run the scripts in order
psql -d online_store -f 01_schema.sql
psql -d online_store -f 02_sample_data.sql
psql -d online_store -f 03_queries.sql
```

The project can also be opened directly in **pgAdmin** or **DBeaver**: create a new database, then execute the three `.sql` files in the same order (schema → data → queries).

## 4. Structure of the database

The database has six tables:

- **customers** — people who can place orders. Each customer has a unique e-mail address.
- **categories** — the product categories (Electronics, Books, Home & Kitchen, Sports).
- **products** — the items sold in the store. Each product belongs to exactly one category (`category_id` foreign key).
- **orders** — one row per order placed by a customer (`customer_id` foreign key). The `status` column is restricted by a `CHECK` constraint to a fixed list of values (`pending`, `processing`, `shipped`, `delivered`, `cancelled`).
- **order_items** — the *junction table* that resolves the many-to-many relationship between `orders` and `products`: one order can contain several products, and one product can appear in several orders. It stores the `unit_price` at the time of purchase, not a reference to the current product price, so that historical orders are not affected if a product's price changes later.
- **payments** — one or more payments linked to an order (`order_id` foreign key), each with a payment method and a status.

### Primary and foreign keys

Every table uses a `SERIAL` surrogate primary key (`customer_id`, `product_id`, etc.), which is a common practice recommended for relational databases because it keeps the key stable even if a "natural" attribute (like an e-mail address) changes. Foreign keys enforce **referential integrity**: for example, it is impossible to insert an order for a `customer_id` that does not exist in the `customers` table.

### Constraints used

- `NOT NULL` on all attributes that must always have a value (names, prices, quantities).
- `UNIQUE` on `customers.email` and `categories.name`, so the same customer or category cannot be duplicated.
- `CHECK` constraints on `price`, `stock_quantity`, `quantity` and `amount` to forbid negative numbers, and on `status`/`payment_method` to restrict them to a fixed set of valid values (this replaces what would sometimes be modelled with an ENUM type or a separate lookup table).
- `ON DELETE RESTRICT` on the foreign keys from `products` and `orders`, so that a category or a customer that still has related rows cannot be deleted by mistake. `ON DELETE CASCADE` is used from `order_items` and `payments` to `orders`, because deleting an order should also remove its own items and payments.

### Design trade-off: `total_amount` in `orders`

The `orders.total_amount` column is a small denormalization: in theory it could always be recomputed with `SUM(quantity * unit_price)` from `order_items`, which would respect a stricter normal form (closer to 3NF/BCNF, since `total_amount` is functionally dependent on data in another table). It is kept here as a stored column for simplicity and because, in a real system, it would typically be maintained automatically with a trigger or with application logic, and having it directly on the order avoids repeating the aggregation in every query that lists orders.

## 5. Explanation of the queries (`03_queries.sql`)

1. **Customer order history** — joins four tables to show, for one specific customer, every product bought, the order date and the line total.
2. **Product search by category and price** — a typical "storefront" search: filter products by category name and a maximum price.
3. **Revenue per category** — uses `GROUP BY` and `SUM` to show which product category brings in the most money.
4. **Customers with no orders** — uses a `LEFT JOIN … WHERE … IS NULL` pattern to find customers who registered but never bought anything.
5. **Top-selling products** — ranks products by total quantity sold, using `GROUP BY`, `ORDER BY` and `LIMIT`.
6. **Unpaid / failed payments** — a simple accounting query to find orders that still need payment follow-up.
7. **Above-average customers (bonus)** — uses `GROUP BY … HAVING` with a subquery to find customers whose average order value is higher than the store's overall average, which shows a slightly more advanced use of aggregate functions.

## 6. Possible extensions

- Add a `reviews` table (many-to-many between customers and products) to model product ratings.
- Add a `suppliers` table linked to `products` for inventory management.
- Replace the `status` `CHECK` constraints with proper lookup tables if the list of statuses is expected to change often.

## 7. Note on AI use

Parts of the SQL boilerplate (formatting of `CREATE TABLE` statements and comments) were drafted with the help of an AI assistant (Claude, Anthropic) based on a database model I designed myself. All constraints, relationships, sample data and queries were reviewed, tested, and adjusted by me, and I am able to explain and justify every design choice described above.
ChatGPT from OpenAI has also been used to improve english and structure of `README.md` file.
