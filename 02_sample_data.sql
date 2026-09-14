-- =========================================================
--  ONLINE STORE DATABASE
--  Script 2 of 3 : Sample Data
--  Run 01_schema.sql first.
-- =========================================================

-- ---------------------------------------------------------
-- Customers (5 rows)
-- ---------------------------------------------------------
INSERT INTO customers (first_name, last_name, email, phone, address, created_at) VALUES
('Ana',    'Kovac',  'ana.kovac@example.com',    '+385911234567', 'Ulica Kralja Tomislava 5, Varaždin', '2025-01-10'),
('Marko',  'Horvat', 'marko.horvat@example.com', '+385912345678', 'Zagrebačka 12, Zagreb',              '2025-02-03'),
('Ivana',  'Novak',  'ivana.novak@example.com',  '+385913456789', 'Trg Slobode 3, Osijek',              '2025-02-20'),
('Petar',  'Jurić',  'petar.juric@example.com',  '+385914567890', 'Dubrovačka 8, Split',                '2025-03-05'),
('Lucija', 'Babić',  'lucija.babic@example.com', '+385915678901', 'Ilica 45, Zagreb',                   '2025-03-18');

-- ---------------------------------------------------------
-- Categories (4 rows)
-- ---------------------------------------------------------
INSERT INTO categories (name, description) VALUES
('Electronics',    'Phones, laptops, and other electronic devices'),
('Books',          'Fiction, non-fiction, and academic books'),
('Home & Kitchen', 'Appliances and accessories for the home'),
('Sports',         'Equipment and clothing for sports and outdoor activities');

-- ---------------------------------------------------------
-- Products (9 rows, spread across all 4 categories)
-- ---------------------------------------------------------
INSERT INTO products (name, description, price, stock_quantity, category_id) VALUES
('Wireless Mouse',              'Ergonomic wireless mouse with USB receiver',          19.99, 120, 1),
('Mechanical Keyboard',         'RGB backlit mechanical keyboard, blue switches',      59.90,  45, 1),
('Noise-Cancelling Headphones', 'Over-ear Bluetooth headphones',                       89.50,  30, 1),
('Clean Code',                  'Book by Robert C. Martin on software craftsmanship', 34.99,  60, 2),
('Database System Concepts',    'Textbook on database theory and design',             54.00,  25, 2),
('Coffee Maker',                'Drip coffee maker, 1.2L capacity',                   39.99,  40, 3),
('Non-stick Frying Pan',        '28cm non-stick frying pan',                          24.50,  70, 3),
('Yoga Mat',                    'Non-slip yoga mat, 6mm thickness',                   17.90, 100, 4),
('Running Shoes',               'Lightweight running shoes, size 42',                 64.99,  35, 4);

-- ---------------------------------------------------------
-- Orders (6 rows, one per customer except Ana who has 2)
--
-- total_amount below equals SUM(quantity * unit_price) of
-- that order's line items in order_items (see calculation
-- next to each row). Kept consistent by hand here; in a
-- production system this column would instead be maintained
-- automatically with an AFTER INSERT/UPDATE/DELETE trigger
-- on order_items so it can never drift out of sync.
-- ---------------------------------------------------------
INSERT INTO orders (customer_id, order_date, status, total_amount) VALUES
(1, '2025-04-01', 'delivered',   72.88), -- 19.99 + 34.99 + 17.90
(2, '2025-04-03', 'delivered',   54.00), -- 54.00
(3, '2025-04-10', 'shipped',    114.00), -- 89.50 + 24.50
(1, '2025-04-15', 'processing',  64.99), -- 64.99
(4, '2025-04-18', 'pending',     59.98), -- 39.99 + 19.99
(5, '2025-04-20', 'delivered',   89.50); -- 89.50

-- ---------------------------------------------------------
-- Order items
-- Each row freezes unit_price at the moment of purchase,
-- so later changes to products.price never distort history.
-- ---------------------------------------------------------
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(1, 1, 1, 19.99), -- Order 1: Wireless Mouse
(1, 4, 1, 34.99), -- Order 1: Clean Code
(1, 8, 1, 17.90), -- Order 1: Yoga Mat
(2, 5, 1, 54.00), -- Order 2: Database System Concepts
(3, 3, 1, 89.50), -- Order 3: Noise-Cancelling Headphones
(3, 7, 1, 24.50), -- Order 3: Non-stick Frying Pan
(4, 9, 1, 64.99), -- Order 4: Running Shoes
(5, 6, 1, 39.99), -- Order 5: Coffee Maker
(5, 1, 1, 19.99), -- Order 5: Wireless Mouse
(6, 3, 1, 89.50); -- Order 6: Noise-Cancelling Headphones

-- ---------------------------------------------------------
-- Payments
-- Every order in this sample is paid in a single
-- transaction, so amount matches the order's total_amount.
-- ---------------------------------------------------------
INSERT INTO payments (order_id, payment_date, amount, payment_method, status) VALUES
(1, '2025-04-01',  72.88, 'card',            'completed'),
(2, '2025-04-03',  54.00, 'paypal',          'completed'),
(3, '2025-04-10', 114.00, 'card',            'completed'),
(4, '2025-04-15',  64.99, 'bank_transfer',   'pending'),
(5, '2025-04-18',  59.98, 'cash_on_delivery','pending'),
(6, '2025-04-20',  89.50, 'card',            'completed');
