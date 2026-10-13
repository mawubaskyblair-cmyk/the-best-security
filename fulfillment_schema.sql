-- ============================================================================
-- E-Commerce Inventory & Order Fulfillment Database Schema
-- Language: SQL (PostgreSQL / ANSI SQL Compatible)
-- Description: Relational structure for products, inventory tracking,
--              customer orders, fulfillment auditing, and automatic triggers.
-- ============================================================================

-- Drop tables if re-executing script to ensure a clean state
DROP TABLE IF EXISTS fulfillment_audit CASCADE;
DROP TABLE IF EXISTS order_line_items CASCADE;
DROP TABLE IF EXISTS customer_orders CASCADE;
DROP TABLE IF EXISTS inventory_items CASCADE;

-- 1. Inventory Items Catalog
CREATE TABLE inventory_items (
    sku VARCHAR(30) PRIMARY KEY,
    item_name VARCHAR(120) NOT NULL,
    unit_price NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0),
    stock_quantity INT NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    aisle_location INT NOT NULL,
    shelf_location INT NOT NULL,
    last_restocked TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Customer Orders Master Table
CREATE TABLE customer_orders (
    order_id VARCHAR(40) PRIMARY KEY,
    customer_id VARCHAR(40) NOT NULL,
    order_status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    total_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Order Line Items Table
CREATE TABLE order_line_items (
    line_id SERIAL PRIMARY KEY,
    order_id VARCHAR(40) NOT NULL,
    sku VARCHAR(30) NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(10, 2) NOT NULL,
    CONSTRAINT fk_order_master FOREIGN KEY (order_id) REFERENCES customer_orders(order_id) ON DELETE CASCADE,
    CONSTRAINT fk_item_sku FOREIGN KEY (sku) REFERENCES inventory_items(sku)
);

-- 4. Fulfillment Audit Log
CREATE TABLE fulfillment_audit (
    audit_id SERIAL PRIMARY KEY,
    order_id VARCHAR(40) NOT NULL,
    previous_status VARCHAR(30),
    new_status VARCHAR(30) NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexing for fast search during route planning and status checks
CREATE INDEX idx_inventory_location ON inventory_items(aisle_location, shelf_location);
CREATE INDEX idx_order_status ON customer_orders(order_status);

-- Ingestion of initial warehouse inventory
INSERT INTO inventory_items (sku, item_name, unit_price, stock_quantity, aisle_location, shelf_location) VALUES
('SKU-A100', 'Ergonomic Mechanical Keyboard', 29.99, 50, 3, 12),
('SKU-B200', '27-Inch 4K Gaming Monitor', 149.50, 5, 1, 4),
('SKU-C300', 'USB-C Docking Station Multi-port', 45.00, 100, 8, 2),
('SKU-D400', 'Wireless Noise-Canceling Mouse', 22.50, 30, 2, 10);

-- Ingestion of sample customer order
INSERT INTO customer_orders (order_id, customer_id, order_status, total_amount) VALUES
('ORD-891A', 'CUST-9982', 'STOCK_RESERVED', 209.48);

INSERT INTO order_line_items (order_id, sku, quantity, unit_price) VALUES
('ORD-891A', 'SKU-A100', 2, 29.99),
('ORD-891A', 'SKU-B200', 1, 149.50);

-- Order Summary View for Warehouse Dispatchers
CREATE VIEW v_order_picking_manifest AS
SELECT 
    co.order_id,
    co.customer_id,
    oli.sku,
    ii.item_name,
    oli.quantity,
    ii.aisle_location,
    ii.shelf_location
FROM customer_orders co
JOIN order_line_items oli ON co.order_id = oli.order_id
JOIN inventory_items ii ON oli.sku = ii.sku
WHERE co.order_status = 'STOCK_RESERVED'
ORDER BY ii.aisle_location, ii.shelf_location;