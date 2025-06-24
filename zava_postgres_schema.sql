-- PostgreSQL Database Schema for Apparel Design Shop
-- Database: zava_complete
-- Created: June 23, 2025

-- Create suppliers table
CREATE TABLE suppliers (
    supplier_id SERIAL PRIMARY KEY,
    company_name VARCHAR(255) NOT NULL,
    contact_person VARCHAR(100),
    email VARCHAR(255),
    phone VARCHAR(20),
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state_province VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100) DEFAULT 'USA',
    supplier_type VARCHAR(50) CHECK (supplier_type IN ('fabric', 'trims', 'hardware', 'manufacturing', 'packaging')),
    payment_terms VARCHAR(100),
    tax_id VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create products table
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    sku VARCHAR(100) UNIQUE NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    description TEXT,
    product_type VARCHAR(20) CHECK (product_type IN ('finished_good', 'raw_material', 'component', 'accessory')),
    brand VARCHAR(100),
    size VARCHAR(20),
    color VARCHAR(50),
    material VARCHAR(100),
    unit_of_measure VARCHAR(20) DEFAULT 'each',
    standard_cost DECIMAL(10,2),
    current_stock INTEGER DEFAULT 0,
    reorder_level INTEGER DEFAULT 10,
    reorder_quantity INTEGER DEFAULT 50,
    supplier_id INTEGER REFERENCES suppliers(supplier_id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create purchase_orders table
CREATE TABLE purchase_orders (
    purchase_order_id SERIAL PRIMARY KEY,
    po_number VARCHAR(50) UNIQUE NOT NULL,
    supplier_id INTEGER NOT NULL REFERENCES suppliers(supplier_id),
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    required_date DATE,
    expected_delivery_date DATE,
    actual_delivery_date DATE,
    status VARCHAR(20) DEFAULT 'draft' CHECK (
        status IN ('draft', 'sent', 'confirmed', 'partial_received', 'received', 'closed', 'cancelled')
    ),
    currency VARCHAR(3) DEFAULT 'USD',
    exchange_rate DECIMAL(10,4) DEFAULT 1.0000,
    subtotal DECIMAL(12,2) DEFAULT 0.00,
    tax_rate DECIMAL(5,4) DEFAULT 0.0000,
    tax_amount DECIMAL(10,2) DEFAULT 0.00,
    shipping_cost DECIMAL(10,2) DEFAULT 0.00,
    discount_amount DECIMAL(10,2) DEFAULT 0.00,
    total_amount DECIMAL(12,2) DEFAULT 0.00,
    payment_terms VARCHAR(100),
    shipping_method VARCHAR(50),
    delivery_address_line1 VARCHAR(255),
    delivery_address_line2 VARCHAR(255),
    delivery_city VARCHAR(100),
    delivery_state_province VARCHAR(100),
    delivery_postal_code VARCHAR(20),
    delivery_country VARCHAR(100),
    notes TEXT,
    internal_notes TEXT,
    created_by VARCHAR(100),
    approved_by VARCHAR(100),
    approved_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create order_items table
CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    purchase_order_id INTEGER NOT NULL REFERENCES purchase_orders(purchase_order_id) ON DELETE CASCADE,
    line_number INTEGER NOT NULL,
    product_id INTEGER REFERENCES products(product_id),
    product_description VARCHAR(255) NOT NULL,
    sku VARCHAR(100),
    manufacturer_part_number VARCHAR(100),
    quantity_ordered INTEGER NOT NULL CHECK (quantity_ordered > 0),
    quantity_received INTEGER DEFAULT 0 CHECK (quantity_received >= 0),
    unit_of_measure VARCHAR(20) DEFAULT 'each',
    unit_cost DECIMAL(10,2) NOT NULL CHECK (unit_cost >= 0),
    line_total DECIMAL(12,2) GENERATED ALWAYS AS (quantity_ordered * unit_cost) STORED,
    discount_percent DECIMAL(5,2) DEFAULT 0.00 CHECK (discount_percent >= 0 AND discount_percent <= 100),
    discount_amount DECIMAL(10,2) DEFAULT 0.00 CHECK (discount_amount >= 0),
    net_amount DECIMAL(12,2) GENERATED ALWAYS AS ((quantity_ordered * unit_cost) - discount_amount) STORED,
    expected_delivery_date DATE,
    actual_delivery_date DATE,
    quality_status VARCHAR(20) DEFAULT 'pending' CHECK (
        quality_status IN ('pending', 'approved', 'rejected', 'partial', 'needs_inspection')
    ),
    color VARCHAR(50),
    size VARCHAR(20),
    material VARCHAR(100),
    care_instructions TEXT,
    notes TEXT,
    receiving_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(purchase_order_id, line_number),
    CHECK (quantity_received <= quantity_ordered),
    CHECK (discount_amount <= (quantity_ordered * unit_cost))
);

-- Comments for documentation
COMMENT ON TABLE suppliers IS 'Stores information about fabric and material suppliers for the apparel design shop';
COMMENT ON TABLE products IS 'Product catalog including raw materials, components, and finished goods';
COMMENT ON TABLE purchase_orders IS 'Central table for managing supplier purchase orders with complete workflow tracking';
COMMENT ON TABLE order_items IS 'Detailed line items for each purchase order with quantity and quality tracking';

COMMENT ON COLUMN suppliers.supplier_type IS 'Type of supplier: fabric, trims, hardware, manufacturing, packaging';
COMMENT ON COLUMN products.product_type IS 'Type of product: finished_good, raw_material, component, accessory';
COMMENT ON COLUMN purchase_orders.status IS 'Order status: draft, sent, confirmed, partial_received, received, closed, cancelled';
COMMENT ON COLUMN order_items.quality_status IS 'Quality status: pending, approved, rejected, partial, needs_inspection';
