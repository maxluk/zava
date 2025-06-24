-- Test Data for Zava Apparel Design Shop Database
-- This file contains comprehensive test data for all tables
-- Run after creating the schema to populate with test data

-- Clear existing data (for testing purposes)
DELETE FROM order_items;
DELETE FROM purchase_orders;
DELETE FROM products;
DELETE FROM suppliers;

-- Reset sequences
ALTER SEQUENCE suppliers_supplier_id_seq RESTART WITH 1;
ALTER SEQUENCE products_product_id_seq RESTART WITH 1;
ALTER SEQUENCE purchase_orders_purchase_order_id_seq RESTART WITH 1;
ALTER SEQUENCE order_items_order_item_id_seq RESTART WITH 1;

-- Insert test suppliers covering all supplier types
INSERT INTO suppliers (company_name, contact_person, email, phone, address_line1, city, state_province, postal_code, country, supplier_type, payment_terms, tax_id, is_active) VALUES
('Premium Fabrics LLC', 'Sarah Johnson', 'sarah@premiumfabrics.com', '555-0101', '123 Textile Ave', 'New York', 'NY', '10001', 'USA', 'fabric', 'Net 30', '12-3456789', TRUE),
('Zipper World Inc', 'Mike Chen', 'mike@zipperworld.com', '555-0102', '456 Hardware St', 'Los Angeles', 'CA', '90210', 'USA', 'hardware', 'Net 15', '98-7654321', TRUE),
('Button & Trim Co', 'Lisa Williams', 'lisa@buttonandtrim.com', '555-0103', '789 Trim Blvd', 'Chicago', 'IL', '60601', 'USA', 'trims', 'COD', '11-2233445', TRUE),
('Elite Manufacturing', 'David Rodriguez', 'david@elitemfg.com', '555-0104', '321 Factory Rd', 'Miami', 'FL', '33101', 'USA', 'manufacturing', 'Net 45', '44-5566778', TRUE),
('EcoPack Solutions', 'Emma Davis', 'emma@ecopack.com', '555-0105', '654 Green Way', 'Seattle', 'WA', '98101', 'USA', 'packaging', 'Net 30', '77-8899001', TRUE),
('Inactive Supplier', 'John Doe', 'john@inactive.com', '555-0199', '999 Old St', 'Nowhere', 'XX', '00000', 'USA', 'fabric', 'Net 30', '00-0000000', FALSE);

-- Insert test products covering all product types
INSERT INTO products (sku, product_name, description, product_type, brand, size, color, material, unit_of_measure, standard_cost, current_stock, reorder_level, reorder_quantity, supplier_id, is_active) VALUES
('COTTON-001', 'Organic Cotton Fabric', 'High-quality organic cotton fabric for premium garments', 'raw_material', 'Premium', 'Per Yard', 'Natural', 'Organic Cotton', 'yard', 12.50, 500, 100, 200, 1, TRUE),
('ZIP-BLK-12', 'Black Metal Zipper 12 inch', 'Heavy-duty black metal zipper', 'component', 'ZipperWorld', '12 inch', 'Black', 'Metal', 'each', 3.25, 1000, 200, 500, 2, TRUE),
('BTN-WHT-20', 'White Shell Button 20mm', 'Natural shell button', 'component', 'ButtonCo', '20mm', 'White', 'Shell', 'each', 0.75, 2000, 500, 1000, 3, TRUE),
('SHIRT-M-BLU', 'Blue Cotton Shirt Medium', 'Finished cotton shirt in blue', 'finished_good', 'Zava', 'Medium', 'Blue', 'Cotton', 'each', 25.00, 50, 10, 25, 4, TRUE),
('BAG-ECO-001', 'Eco-Friendly Packaging Bag', 'Biodegradable packaging bag', 'accessory', 'EcoPack', 'Standard', 'Brown', 'Recycled Paper', 'each', 0.50, 10000, 1000, 5000, 5, TRUE),
('LACE-VIN-001', 'Vintage Lace Trim', 'Delicate vintage-style lace trim', 'component', 'ButtonCo', 'Per Yard', 'Ivory', 'Lace', 'yard', 8.75, 0, 50, 100, 3, TRUE),
('THREAD-RED', 'Red Polyester Thread', 'High-strength polyester thread', 'raw_material', 'Premium', 'Spool', 'Red', 'Polyester', 'spool', 2.10, 5, 20, 50, 1, FALSE);

-- Insert test purchase orders in various statuses
INSERT INTO purchase_orders (po_number, supplier_id, order_date, required_date, expected_delivery_date, status, currency, subtotal, tax_rate, tax_amount, shipping_cost, total_amount, payment_terms, notes, created_by) VALUES
('PO-2024-001', 1, '2024-01-15', '2024-02-01', '2024-01-30', 'received', 'USD', 2500.00, 0.0875, 218.75, 50.00, 2768.75, 'Net 30', 'First order of the year', 'admin'),
('PO-2024-002', 2, '2024-01-20', '2024-02-10', '2024-02-05', 'confirmed', 'USD', 1625.00, 0.0875, 142.19, 25.00, 1792.19, 'Net 15', 'Zipper restock', 'buyer1'),
('PO-2024-003', 3, '2024-01-25', '2024-02-15', '2024-02-12', 'partial_received', 'USD', 1500.00, 0.0875, 131.25, 30.00, 1661.25, 'COD', 'Button and trim order', 'buyer2'),
('PO-2024-004', 4, '2024-02-01', '2024-03-01', '2024-02-28', 'sent', 'USD', 5000.00, 0.0875, 437.50, 100.00, 5537.50, 'Net 45', 'Large manufacturing order', 'admin'),
('PO-2024-005', 5, '2024-02-05', '2024-02-20', '2024-02-18', 'draft', 'USD', 250.00, 0.0875, 21.88, 15.00, 286.88, 'Net 30', 'Packaging supplies', 'buyer1'),
('PO-2024-006', 1, '2024-02-10', '2024-03-10', NULL, 'cancelled', 'USD', 0.00, 0.0875, 0.00, 0.00, 0.00, 'Net 30', 'Cancelled due to supplier issues', 'admin');

-- Insert test order items with various scenarios
INSERT INTO order_items (purchase_order_id, line_number, product_id, product_description, sku, quantity_ordered, quantity_received, unit_of_measure, unit_cost, discount_percent, discount_amount, expected_delivery_date, quality_status, notes) VALUES
-- PO-2024-001 (received)
(1, 1, 1, 'Organic Cotton Fabric', 'COTTON-001', 200, 200, 'yard', 12.50, 0.00, 0.00, '2024-01-30', 'approved', 'Good quality fabric'),
-- PO-2024-002 (confirmed) 
(2, 1, 2, 'Black Metal Zipper 12 inch', 'ZIP-BLK-12', 500, 0, 'each', 3.25, 0.00, 0.00, '2024-02-05', 'pending', 'Standard zippers'),
-- PO-2024-003 (partial_received)
(3, 1, 3, 'White Shell Button 20mm', 'BTN-WHT-20', 1000, 800, 'each', 0.75, 5.00, 37.50, '2024-02-12', 'approved', 'Partial delivery - 200 buttons pending'),
(3, 2, 6, 'Vintage Lace Trim', 'LACE-VIN-001', 100, 50, 'yard', 8.75, 0.00, 0.00, '2024-02-12', 'needs_inspection', 'Quality check required'),
-- PO-2024-004 (sent)
(4, 1, 4, 'Blue Cotton Shirt Medium', 'SHIRT-M-BLU', 200, 0, 'each', 25.00, 10.00, 500.00, '2024-02-28', 'pending', 'Volume discount applied'),
-- PO-2024-005 (draft)
(5, 1, 5, 'Eco-Friendly Packaging Bag', 'BAG-ECO-001', 500, 0, 'each', 0.50, 0.00, 0.00, '2024-02-18', 'pending', 'Eco packaging trial');

-- Update product stock based on received quantities
UPDATE products SET current_stock = current_stock + 200 WHERE product_id = 1; -- Cotton fabric
UPDATE products SET current_stock = current_stock + 800 WHERE product_id = 3; -- White buttons
UPDATE products SET current_stock = current_stock + 50 WHERE product_id = 6; -- Lace trim

-- Update purchase order totals to match line items
UPDATE purchase_orders SET 
    subtotal = (SELECT COALESCE(SUM(net_amount), 0) FROM order_items WHERE purchase_order_id = purchase_orders.purchase_order_id),
    tax_amount = subtotal * tax_rate,
    total_amount = subtotal + tax_amount + shipping_cost
WHERE purchase_order_id IN (1, 2, 3, 4, 5);

-- Add some edge case data for testing
INSERT INTO suppliers (company_name, contact_person, email, phone, address_line1, city, state_province, postal_code, country, supplier_type, payment_terms, tax_id, is_active) VALUES
('International Fabric Ltd', 'Maria Garcia', 'maria@intlfabric.com', '+44-20-1234-5678', '10 London Rd', 'London', 'England', 'SW1A 1AA', 'UK', 'fabric', 'Net 30', 'GB123456789', TRUE);

INSERT INTO products (sku, product_name, description, product_type, brand, size, color, material, unit_of_measure, standard_cost, current_stock, reorder_level, reorder_quantity, supplier_id, is_active) VALUES
('SILK-LUX-001', 'Luxury Silk Fabric', 'Premium silk fabric imported from overseas', 'raw_material', 'International', 'Per Meter', 'Champagne', 'Silk', 'meter', 45.00, 25, 10, 50, 7, TRUE);

-- Insert edge case purchase order (high value, international)
INSERT INTO purchase_orders (po_number, supplier_id, order_date, required_date, expected_delivery_date, status, currency, exchange_rate, subtotal, tax_rate, tax_amount, shipping_cost, total_amount, payment_terms, delivery_country, notes, created_by) VALUES
('PO-2024-INT-001', 7, '2024-02-15', '2024-03-30', '2024-03-25', 'confirmed', 'GBP', 1.2500, 1000.00, 0.2000, 200.00, 150.00, 1350.00, 'Letter of Credit', 'UK', 'International luxury fabric order', 'admin');

INSERT INTO order_items (purchase_order_id, line_number, product_id, product_description, sku, quantity_ordered, quantity_received, unit_of_measure, unit_cost, discount_percent, discount_amount, expected_delivery_date, quality_status, notes) VALUES
(7, 1, 8, 'Luxury Silk Fabric', 'SILK-LUX-001', 50, 0, 'meter', 20.00, 0.00, 0.00, '2024-03-25', 'pending', 'Premium quality silk - handle with care');

-- Commit the test data
COMMIT;

-- Display summary of test data inserted
SELECT 'Suppliers' as table_name, COUNT(*) as record_count FROM suppliers
UNION ALL
SELECT 'Products', COUNT(*) FROM products  
UNION ALL
SELECT 'Purchase Orders', COUNT(*) FROM purchase_orders
UNION ALL
SELECT 'Order Items', COUNT(*) FROM order_items;