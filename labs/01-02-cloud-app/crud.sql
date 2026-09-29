-- Run on a free hosted PostgreSQL service to demonstrate real cloud CRUD.
CREATE TABLE IF NOT EXISTS products (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  price NUMERIC(10,2) NOT NULL CHECK (price >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
-- Keep the returned id and use it for UPDATE/DELETE (replace 1 below).
INSERT INTO products(name, price) VALUES ('Lab keyboard', 799.00) RETURNING *;
SELECT * FROM products;
UPDATE products SET price=749.00 WHERE id=1 RETURNING *;
DELETE FROM products WHERE id=1 RETURNING *;
