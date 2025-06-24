-- Test Data for Zava Database Schema
-- This file contains realistic test data for all tables in the zava_complete database
-- Created: June 24, 2025

-- Clear existing test data (in reverse dependency order)
DELETE FROM order_items;
DELETE FROM purchase_orders;
DELETE FROM products;
DELETE FROM suppliers;

-- Reset sequences
ALTER SEQUENCE suppliers_supplier_id_seq RESTART WITH 1;
ALTER SEQUENCE products_product_id_seq RESTART WITH 1;
ALTER SEQUENCE purchase_orders_purchase_order_id_seq RESTART WITH 1;
ALTER SEQUENCE order_items_order_item_id_seq RESTART WITH 1;

-- Insert test data for suppliers
INSERT INTO suppliers (
    company_name, contact_person, email, phone, 
    address_line1, address_line2, city, state_province, postal_code, country,
    supplier_type, payment_terms, tax_id, is_active
) VALUES 
-- Fabric suppliers
('Premium Fabrics Inc', 'Sarah Johnson', 'sarah@premiumfabrics.com', '555-0101', 
 '123 Textile Ave', 'Suite 100', 'Los Angeles', 'CA', '90210', 'USA',
 'fabric', 'Net 30', 'TAX123456789', TRUE),

('Eco Cotton Supply', 'Michael Chen', 'mchen@ecocotton.com', '555-0102',
 '456 Organic Blvd', NULL, 'Portland', 'OR', '97201', 'USA',
 'fabric', 'Net 45', 'TAX987654321', TRUE),

('Luxury Silk Co', 'Maria Rodriguez', 'maria@luxurysilk.com', '555-0103',
 '789 Silk Road', 'Building A', 'New York', 'NY', '10001', 'USA',
 'fabric', 'Net 15', 'TAX456789123', FALSE), -- Inactive supplier

-- Trims suppliers
('Button & Trim Masters', 'David Kim', 'dkim@buttonmasters.com', '555-0201',
 '321 Notions St', NULL, 'Chicago', 'IL', '60601', 'USA',
 'trims', 'Net 30', 'TAX111222333', TRUE),

('Zipper Solutions Ltd', 'Jennifer Walsh', 'jen@zippersolutions.com', '555-0202',
 '654 Fastener Way', 'Unit 5', 'Detroit', 'MI', '48201', 'USA',
 'trims', 'Net 30', 'TAX444555666', TRUE),

-- Hardware suppliers
('Metal Hardware Co', 'Robert Brown', 'rbrown@metalhardware.com', '555-0301',
 '987 Steel Ave', NULL, 'Pittsburgh', 'PA', '15201', 'USA',
 'hardware', 'Net 45', 'TAX777888999', TRUE),

-- Manufacturing suppliers
('Ace Manufacturing', 'Lisa Thompson', 'lisa@acemanufacturing.com', '555-0401',
 '147 Production Dr', 'Floor 2', 'Atlanta', 'GA', '30301', 'USA',
 'manufacturing', 'Net 30', 'TAX000111222', TRUE),

-- Packaging suppliers
('Green Package Solutions', 'Tom Wilson', 'tom@greenpackage.com', '555-0501',
 '258 Eco Way', NULL, 'San Francisco', 'CA', '94101', 'USA',
 'packaging', 'Net 15', 'TAX333444555', TRUE);

-- Insert test data for products
INSERT INTO products (
    sku, product_name, description, product_type, brand, size, color, material,
    unit_of_measure, standard_cost, current_stock, reorder_level, reorder_quantity,
    supplier_id, is_active
) VALUES 
-- Raw materials (fabrics)
('FAB-COT-001', 'Organic Cotton Twill', 'Premium organic cotton twill fabric, 280gsm', 'raw_material', 
 'EcoCotton', '58" width', 'Natural', 'Organic Cotton', 'yard', 8.50, 150, 50, 200, 2, TRUE),

('FAB-SIL-001', 'Mulberry Silk Charmeuse', 'Luxurious 19 momme mulberry silk', 'raw_material',
 'LuxurySilk', '45" width', 'Ivory', 'Mulberry Silk', 'yard', 25.00, 0, 20, 100, 3, FALSE), -- Out of stock, inactive supplier

('FAB-COT-002', 'Premium Denim', 'Heavy weight cotton denim, 14oz', 'raw_material',
 'Premium', '60" width', 'Indigo Blue', 'Cotton Denim', 'yard', 12.75, 80, 30, 150, 1, TRUE),

-- Components (trims)
('TRM-BTN-001', 'Corozo Buttons 18mm', 'Natural corozo buttons, 4-hole', 'component',
 'ButtonMaster', '18mm', 'Natural', 'Corozo Nut', 'each', 0.45, 500, 100, 1000, 4, TRUE),

('TRM-ZIP-001', 'YKK Metal Zipper', 'Antique brass metal zipper', 'component',
 'YKK', '8"', 'Antique Brass', 'Metal', 'each', 2.25, 200, 50, 500, 5, TRUE),

('TRM-LBL-001', 'Woven Brand Label', 'Custom woven brand label', 'component',
 'ButtonMaster', '2" x 1"', 'Navy Blue', 'Cotton', 'each', 0.15, 1000, 200, 2000, 4, TRUE),

-- Hardware
('HRW-RIV-001', 'Copper Rivets 6mm', 'Solid copper rivets for denim', 'component',
 'MetalHardware', '6mm', 'Copper', 'Copper', 'each', 0.08, 2000, 500, 5000, 6, TRUE),

-- Finished goods
('FG-JEAN-001', 'Classic Straight Jeans', 'Premium cotton denim straight-leg jeans', 'finished_good',
 'ZavaDesign', '32W x 34L', 'Indigo', 'Cotton Denim', 'each', 45.00, 25, 10, 50, 7, TRUE),

('FG-SHIRT-001', 'Organic Cotton T-Shirt', 'Basic crew neck t-shirt in organic cotton', 'finished_good',
 'ZavaDesign', 'Medium', 'White', 'Organic Cotton', 'each', 18.50, 40, 15, 100, 7, TRUE),

-- Accessories
('ACC-BAG-001', 'Eco-Friendly Garment Bag', 'Biodegradable garment packaging bag', 'accessory',
 'GreenPackage', 'Large', 'Clear', 'Biodegradable Plastic', 'each', 0.35, 800, 200, 1000, 8, TRUE);

-- Insert test data for purchase_orders
INSERT INTO purchase_orders (
    po_number, supplier_id, order_date, required_date, expected_delivery_date,
    status, currency, subtotal, tax_rate, tax_amount, shipping_cost, 
    discount_amount, total_amount, payment_terms, shipping_method,
    delivery_address_line1, delivery_city, delivery_state_province, 
    delivery_postal_code, delivery_country, notes, created_by, approved_by, approved_date
) VALUES 
-- Draft order
('PO-2025-001', 1, '2025-06-20', '2025-07-01', '2025-06-28',
 'draft', 'USD', 0.00, 0.0875, 0.00, 25.00, 0.00, 25.00, 'Net 30', 'UPS Ground',
 '100 Main St', 'Anytown', 'CA', '90210', 'USA', 'Rush order for new collection', 'john.designer', NULL, NULL),

-- Sent order  
('PO-2025-002', 2, '2025-06-18', '2025-07-10', '2025-07-05',
 'sent', 'USD', 1700.00, 0.0875, 148.75, 35.00, 0.00, 1883.75, 'Net 45', 'FedEx',
 '100 Main St', 'Anytown', 'CA', '90210', 'USA', 'Organic cotton for summer line', 'jane.buyer', 'mike.manager', '2025-06-18 14:30:00'),

-- Confirmed order
('PO-2025-003', 4, '2025-06-15', '2025-06-30', '2025-06-25',
 'confirmed', 'USD', 950.00, 0.0875, 83.13, 15.00, 47.50, 1000.63, 'Net 30', 'USPS Priority',
 '100 Main St', 'Anytown', 'CA', '90210', 'USA', 'Buttons and labels for production run', 'sarah.production', 'mike.manager', '2025-06-15 10:15:00'),

-- Partially received order
('PO-2025-004', 5, '2025-06-10', '2025-06-25', '2025-06-22',
 'partial_received', 'USD', 1125.00, 0.0875, 98.44, 20.00, 0.00, 1243.44, 'Net 30', 'UPS 2-Day',
 '100 Main St', 'Anytown', 'CA', '90210', 'USA', 'Zippers for jacket production', 'tom.production', 'mike.manager', '2025-06-10 09:00:00'),

-- Received order
('PO-2025-005', 6, '2025-06-05', '2025-06-20', '2025-06-18',
 'received', 'USD', 400.00, 0.0875, 35.00, 10.00, 0.00, 445.00, 'Net 45', 'UPS Ground',
 '100 Main St', 'Anytown', 'CA', '90210', 'USA', 'Hardware for denim line', 'bill.designer', 'mike.manager', '2025-06-05 16:45:00'),

-- Closed order
('PO-2025-006', 8, '2025-05-28', '2025-06-15', '2025-06-12',
 'closed', 'USD', 350.00, 0.0875, 30.63, 12.00, 17.50, 375.13, 'Net 15', 'FedEx Ground',
 '100 Main St', 'Anytown', 'CA', '90210', 'USA', 'Packaging materials', 'lisa.logistics', 'mike.manager', '2025-05-28 11:20:00'),

-- Cancelled order
('PO-2025-007', 3, '2025-06-22', '2025-07-15', '2025-07-10',
 'cancelled', 'USD', 0.00, 0.0875, 0.00, 0.00, 0.00, 0.00, 'Net 15', 'FedEx',
 '100 Main St', 'Anytown', 'CA', '90210', 'USA', 'Cancelled due to supplier issues', 'mary.buyer', NULL, NULL);

-- Insert test data for order_items
INSERT INTO order_items (
    purchase_order_id, line_number, product_id, product_description, sku,
    manufacturer_part_number, quantity_ordered, quantity_received, unit_of_measure,
    unit_cost, discount_percent, discount_amount, expected_delivery_date,
    actual_delivery_date, quality_status, color, size, material, notes
) VALUES 
-- Items for PO-2025-001 (draft)
(1, 1, 1, 'Organic Cotton Twill for summer collection', 'FAB-COT-001',
 'ECO-COT-280', 100, 0, 'yard', 8.50, 0.00, 0.00, '2025-06-28',
 NULL, 'pending', 'Natural', '58" width', 'Organic Cotton', 'Priority item'),

-- Items for PO-2025-002 (sent)
(2, 1, 1, 'Organic Cotton Twill', 'FAB-COT-001',
 'ECO-COT-280', 200, 0, 'yard', 8.50, 0.00, 0.00, '2025-07-05',
 NULL, 'pending', 'Natural', '58" width', 'Organic Cotton', 'Large quantity order'),

-- Items for PO-2025-003 (confirmed)
(3, 1, 4, 'Corozo Buttons 18mm', 'TRM-BTN-001',
 'BTN-COR-18-4H', 1000, 0, 'each', 0.45, 5.00, 22.50, '2025-06-25',
 NULL, 'pending', 'Natural', '18mm', 'Corozo Nut', 'Volume discount applied'),
(3, 2, 6, 'Woven Brand Label', 'TRM-LBL-001',
 'LBL-WOV-2x1', 1000, 0, 'each', 0.15, 0.00, 0.00, '2025-06-25',
 NULL, 'pending', 'Navy Blue', '2" x 1"', 'Cotton', NULL),
(3, 3, 4, 'Corozo Buttons 15mm', 'TRM-BTN-002',
 'BTN-COR-15-4H', 500, 0, 'each', 0.40, 5.00, 10.00, '2025-06-25',
 NULL, 'pending', 'Natural', '15mm', 'Corozo Nut', 'Different size buttons'),

-- Items for PO-2025-004 (partial_received)  
(4, 1, 5, 'YKK Metal Zipper 8"', 'TRM-ZIP-001',
 'YKK-MTL-8-AB', 500, 300, 'each', 2.25, 0.00, 0.00, '2025-06-22',
 '2025-06-20', 'approved', 'Antique Brass', '8"', 'Metal', 'Partial shipment received'),

-- Items for PO-2025-005 (received)
(5, 1, 7, 'Copper Rivets 6mm', 'HRW-RIV-001',
 'MTL-RIV-6MM-CU', 5000, 5000, 'each', 0.08, 0.00, 0.00, '2025-06-18',
 '2025-06-18', 'approved', 'Copper', '6mm', 'Copper', 'Full shipment received and approved'),

-- Items for PO-2025-006 (closed)
(6, 1, 10, 'Eco-Friendly Garment Bag', 'ACC-BAG-001',
 'PKG-ECO-LRG', 1000, 1000, 'each', 0.35, 5.00, 17.50, '2025-06-12',
 '2025-06-12', 'approved', 'Clear', 'Large', 'Biodegradable Plastic', 'Order completed and closed');

-- Update purchase order totals based on line items
UPDATE purchase_orders SET 
    subtotal = (
        SELECT COALESCE(SUM(net_amount), 0) 
        FROM order_items 
        WHERE purchase_order_id = purchase_orders.purchase_order_id
    );

UPDATE purchase_orders SET 
    tax_amount = subtotal * tax_rate,
    total_amount = subtotal * (1 + tax_rate) + shipping_cost - discount_amount;

-- Refresh updated_at timestamps
UPDATE suppliers SET updated_at = CURRENT_TIMESTAMP;
UPDATE products SET updated_at = CURRENT_TIMESTAMP;
UPDATE purchase_orders SET updated_at = CURRENT_TIMESTAMP;
UPDATE order_items SET updated_at = CURRENT_TIMESTAMP;

-- Display summary of test data
SELECT 'Test data summary:' as info;
SELECT 'Suppliers' as table_name, COUNT(*) as record_count FROM suppliers
UNION ALL
SELECT 'Products', COUNT(*) FROM products  
UNION ALL
SELECT 'Purchase Orders', COUNT(*) FROM purchase_orders
UNION ALL  
SELECT 'Order Items', COUNT(*) FROM order_items;

SELECT 'Supplier types:' as info;
SELECT supplier_type, COUNT(*) as count FROM suppliers GROUP BY supplier_type ORDER BY supplier_type;

SELECT 'Product types:' as info;
SELECT product_type, COUNT(*) as count FROM products GROUP BY product_type ORDER BY product_type;

SELECT 'Order statuses:' as info;
SELECT status, COUNT(*) as count FROM purchase_orders GROUP BY status ORDER BY status;

SELECT 'Quality statuses:' as info;
SELECT quality_status, COUNT(*) as count FROM order_items GROUP BY quality_status ORDER BY quality_status;