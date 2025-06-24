-- Unit Tests for Zava Database Schema (Simplified Version)
-- This file contains stored procedures that perform unit tests on the zava_complete database
-- Created: June 24, 2025

-- Create a test results table to track test outcomes
CREATE TABLE IF NOT EXISTS test_results (
    test_id SERIAL PRIMARY KEY,
    test_name VARCHAR(255) NOT NULL,
    test_description TEXT,
    status VARCHAR(10) CHECK (status IN ('PASS', 'FAIL')) NOT NULL,
    error_message TEXT,
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Helper function to log test results
CREATE OR REPLACE FUNCTION log_test_result(
    p_test_name VARCHAR(255),
    p_test_description TEXT,
    p_status VARCHAR(10),
    p_error_message TEXT DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
    INSERT INTO test_results (test_name, test_description, status, error_message)
    VALUES (p_test_name, p_test_description, p_status, p_error_message);
END;
$$ LANGUAGE plpgsql;

-- Test 1: Test suppliers table constraints
CREATE OR REPLACE FUNCTION test_suppliers_constraints() RETURNS VOID AS $$
DECLARE
    test_supplier_id INTEGER;
    error_msg TEXT;
BEGIN
    -- Test valid supplier type
    INSERT INTO suppliers (company_name, supplier_type) 
    VALUES ('Test Supplier Valid', 'fabric') RETURNING supplier_id INTO test_supplier_id;
    DELETE FROM suppliers WHERE supplier_id = test_supplier_id;
    PERFORM log_test_result('test_suppliers_valid_type', 'Test valid supplier type insertion', 'PASS');

    -- Test default values
    INSERT INTO suppliers (company_name, supplier_type) 
    VALUES ('Test Supplier Defaults', 'trims') RETURNING supplier_id INTO test_supplier_id;
    
    IF (SELECT country FROM suppliers WHERE supplier_id = test_supplier_id) = 'USA' AND
       (SELECT is_active FROM suppliers WHERE supplier_id = test_supplier_id) = TRUE THEN
        PERFORM log_test_result('test_suppliers_defaults', 'Test default values for country and is_active', 'PASS');
    ELSE
        PERFORM log_test_result('test_suppliers_defaults', 'Test default values for country and is_active', 'FAIL', 'Default values not set correctly');
    END IF;
    
    DELETE FROM suppliers WHERE supplier_id = test_supplier_id;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
    PERFORM log_test_result('test_suppliers_error', 'Suppliers test encountered error', 'FAIL', error_msg);
END;
$$ LANGUAGE plpgsql;

-- Test invalid supplier type (separate function to handle expected exceptions)
CREATE OR REPLACE FUNCTION test_invalid_supplier_type() RETURNS VOID AS $$
BEGIN
    INSERT INTO suppliers (company_name, supplier_type) 
    VALUES ('Test Supplier Invalid', 'invalid_type');
    -- If we reach here, the test failed
    PERFORM log_test_result('test_suppliers_invalid_type', 'Test invalid supplier type rejection', 'FAIL', 'Should have rejected invalid supplier type');
EXCEPTION 
    WHEN check_violation THEN
        PERFORM log_test_result('test_suppliers_invalid_type', 'Test invalid supplier type rejection', 'PASS');
    WHEN OTHERS THEN
        PERFORM log_test_result('test_suppliers_invalid_type', 'Test invalid supplier type rejection', 'FAIL', SQLERRM);
END;
$$ LANGUAGE plpgsql;

-- Test null company name (separate function to handle expected exceptions)
CREATE OR REPLACE FUNCTION test_null_company_name() RETURNS VOID AS $$
BEGIN
    INSERT INTO suppliers (company_name, supplier_type) VALUES (NULL, 'fabric');
    -- If we reach here, the test failed
    PERFORM log_test_result('test_suppliers_null_name', 'Test company name not null constraint', 'FAIL', 'Should have rejected null company name');
EXCEPTION 
    WHEN not_null_violation THEN
        PERFORM log_test_result('test_suppliers_null_name', 'Test company name not null constraint', 'PASS');
    WHEN OTHERS THEN
        PERFORM log_test_result('test_suppliers_null_name', 'Test company name not null constraint', 'FAIL', SQLERRM);
END;
$$ LANGUAGE plpgsql;

-- Test 2: Test products table constraints
CREATE OR REPLACE FUNCTION test_products_constraints() RETURNS VOID AS $$
DECLARE
    test_product_id INTEGER;
    error_msg TEXT;
BEGIN
    -- Test valid product type
    INSERT INTO products (sku, product_name, product_type) 
    VALUES ('TEST-VALID-001', 'Test Product Valid', 'finished_good') RETURNING product_id INTO test_product_id;
    DELETE FROM products WHERE product_id = test_product_id;
    PERFORM log_test_result('test_products_valid_type', 'Test valid product type insertion', 'PASS');

    -- Test default values
    INSERT INTO products (sku, product_name, product_type) 
    VALUES ('TEST-DEFAULTS-001', 'Test Product Defaults', 'component') RETURNING product_id INTO test_product_id;
    
    IF (SELECT unit_of_measure FROM products WHERE product_id = test_product_id) = 'each' AND
       (SELECT current_stock FROM products WHERE product_id = test_product_id) = 0 AND
       (SELECT reorder_level FROM products WHERE product_id = test_product_id) = 10 AND
       (SELECT reorder_quantity FROM products WHERE product_id = test_product_id) = 50 AND
       (SELECT is_active FROM products WHERE product_id = test_product_id) = TRUE THEN
        PERFORM log_test_result('test_products_defaults', 'Test default values for products', 'PASS');
    ELSE
        PERFORM log_test_result('test_products_defaults', 'Test default values for products', 'FAIL', 'Default values not set correctly');
    END IF;
    
    DELETE FROM products WHERE product_id = test_product_id;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
    PERFORM log_test_result('test_products_error', 'Products test encountered error', 'FAIL', error_msg);
END;
$$ LANGUAGE plpgsql;

-- Test unique SKU constraint (separate function)
CREATE OR REPLACE FUNCTION test_unique_sku() RETURNS VOID AS $$
DECLARE
    test_product_id INTEGER;
BEGIN
    INSERT INTO products (sku, product_name, product_type) 
    VALUES ('TEST-UNIQUE-001', 'Test Product 1', 'raw_material') RETURNING product_id INTO test_product_id;
    
    INSERT INTO products (sku, product_name, product_type) 
    VALUES ('TEST-UNIQUE-001', 'Test Product 2', 'raw_material');
    
    -- If we reach here, the test failed
    PERFORM log_test_result('test_products_unique_sku', 'Test unique SKU constraint', 'FAIL', 'Should have rejected duplicate SKU');
EXCEPTION 
    WHEN unique_violation THEN
        PERFORM log_test_result('test_products_unique_sku', 'Test unique SKU constraint', 'PASS');
        DELETE FROM products WHERE product_id = test_product_id;
    WHEN OTHERS THEN
        PERFORM log_test_result('test_products_unique_sku', 'Test unique SKU constraint', 'FAIL', SQLERRM);
END;
$$ LANGUAGE plpgsql;

-- Test invalid product type (separate function)
CREATE OR REPLACE FUNCTION test_invalid_product_type() RETURNS VOID AS $$
BEGIN
    INSERT INTO products (sku, product_name, product_type) 
    VALUES ('TEST-INVALID-001', 'Test Product Invalid', 'invalid_type');
    -- If we reach here, the test failed
    PERFORM log_test_result('test_products_invalid_type', 'Test invalid product type rejection', 'FAIL', 'Should have rejected invalid product type');
EXCEPTION 
    WHEN check_violation THEN
        PERFORM log_test_result('test_products_invalid_type', 'Test invalid product type rejection', 'PASS');
    WHEN OTHERS THEN
        PERFORM log_test_result('test_products_invalid_type', 'Test invalid product type rejection', 'FAIL', SQLERRM);
END;
$$ LANGUAGE plpgsql;

-- Test 3: Test purchase orders constraints
CREATE OR REPLACE FUNCTION test_purchase_orders_constraints() RETURNS VOID AS $$
DECLARE
    test_po_id INTEGER;
    test_supplier_id INTEGER;
    error_msg TEXT;
BEGIN
    -- Create test supplier first
    INSERT INTO suppliers (company_name, supplier_type) 
    VALUES ('Test PO Supplier', 'fabric') RETURNING supplier_id INTO test_supplier_id;

    -- Test valid status values
    INSERT INTO purchase_orders (po_number, supplier_id, status) 
    VALUES ('TEST-PO-VALID-001', test_supplier_id, 'confirmed') RETURNING purchase_order_id INTO test_po_id;
    DELETE FROM purchase_orders WHERE purchase_order_id = test_po_id;
    PERFORM log_test_result('test_po_valid_status', 'Test valid PO status insertion', 'PASS');

    -- Test default values
    INSERT INTO purchase_orders (po_number, supplier_id) 
    VALUES ('TEST-PO-DEFAULTS-001', test_supplier_id) RETURNING purchase_order_id INTO test_po_id;
    
    IF (SELECT status FROM purchase_orders WHERE purchase_order_id = test_po_id) = 'draft' AND
       (SELECT currency FROM purchase_orders WHERE purchase_order_id = test_po_id) = 'USD' AND
       (SELECT exchange_rate FROM purchase_orders WHERE purchase_order_id = test_po_id) = 1.0000 THEN
        PERFORM log_test_result('test_po_defaults', 'Test default values for purchase orders', 'PASS');
    ELSE
        PERFORM log_test_result('test_po_defaults', 'Test default values for purchase orders', 'FAIL', 'Default values not set correctly');
    END IF;
    
    DELETE FROM purchase_orders WHERE purchase_order_id = test_po_id;

    -- Cleanup
    DELETE FROM suppliers WHERE supplier_id = test_supplier_id;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
    PERFORM log_test_result('test_po_error', 'Purchase orders test encountered error', 'FAIL', error_msg);
END;
$$ LANGUAGE plpgsql;

-- Test unique PO number constraint (separate function)
CREATE OR REPLACE FUNCTION test_unique_po_number() RETURNS VOID AS $$
DECLARE
    test_po_id INTEGER;
    test_supplier_id INTEGER;
BEGIN
    -- Create test supplier first
    INSERT INTO suppliers (company_name, supplier_type) 
    VALUES ('Test Unique PO Supplier', 'fabric') RETURNING supplier_id INTO test_supplier_id;

    INSERT INTO purchase_orders (po_number, supplier_id) 
    VALUES ('TEST-UNIQUE-PO-001', test_supplier_id) RETURNING purchase_order_id INTO test_po_id;
    
    INSERT INTO purchase_orders (po_number, supplier_id) 
    VALUES ('TEST-UNIQUE-PO-001', test_supplier_id);
    
    -- If we reach here, the test failed
    PERFORM log_test_result('test_po_unique_number', 'Test unique PO number constraint', 'FAIL', 'Should have rejected duplicate PO number');
EXCEPTION 
    WHEN unique_violation THEN
        PERFORM log_test_result('test_po_unique_number', 'Test unique PO number constraint', 'PASS');
        DELETE FROM purchase_orders WHERE purchase_order_id = test_po_id;
        DELETE FROM suppliers WHERE supplier_id = test_supplier_id;
    WHEN OTHERS THEN
        PERFORM log_test_result('test_po_unique_number', 'Test unique PO number constraint', 'FAIL', SQLERRM);
END;
$$ LANGUAGE plpgsql;

-- Test invalid PO status (separate function)
CREATE OR REPLACE FUNCTION test_invalid_po_status() RETURNS VOID AS $$
DECLARE
    test_supplier_id INTEGER;
BEGIN
    -- Create test supplier first
    INSERT INTO suppliers (company_name, supplier_type) 
    VALUES ('Test Invalid Status Supplier', 'fabric') RETURNING supplier_id INTO test_supplier_id;

    INSERT INTO purchase_orders (po_number, supplier_id, status) 
    VALUES ('TEST-INVALID-STATUS-001', test_supplier_id, 'invalid_status');
    
    -- If we reach here, the test failed
    PERFORM log_test_result('test_po_invalid_status', 'Test invalid PO status rejection', 'FAIL', 'Should have rejected invalid status');
EXCEPTION 
    WHEN check_violation THEN
        PERFORM log_test_result('test_po_invalid_status', 'Test invalid PO status rejection', 'PASS');
        DELETE FROM suppliers WHERE supplier_id = test_supplier_id;
    WHEN OTHERS THEN
        PERFORM log_test_result('test_po_invalid_status', 'Test invalid PO status rejection', 'FAIL', SQLERRM);
END;
$$ LANGUAGE plpgsql;

-- Test 4: Test order items constraints
CREATE OR REPLACE FUNCTION test_order_items_constraints() RETURNS VOID AS $$
DECLARE
    test_supplier_id INTEGER;
    test_po_id INTEGER;
    test_item_id INTEGER;
    calculated_line_total DECIMAL(12,2);
    calculated_net_amount DECIMAL(12,2);
    error_msg TEXT;
BEGIN
    -- Create test data
    INSERT INTO suppliers (company_name, supplier_type) 
    VALUES ('Test Item Supplier', 'fabric') RETURNING supplier_id INTO test_supplier_id;
    
    INSERT INTO purchase_orders (po_number, supplier_id) 
    VALUES ('TEST-ITEM-PO-001', test_supplier_id) RETURNING purchase_order_id INTO test_po_id;

    -- Test valid order item insertion
    INSERT INTO order_items (purchase_order_id, line_number, product_description, quantity_ordered, unit_cost)
    VALUES (test_po_id, 1, 'Test Item Valid', 5, 10.00) RETURNING order_item_id INTO test_item_id;
    
    PERFORM log_test_result('test_items_valid_insert', 'Test valid order item insertion', 'PASS');
    DELETE FROM order_items WHERE order_item_id = test_item_id;

    -- Test line_total calculation (quantity_ordered * unit_cost)
    INSERT INTO order_items (purchase_order_id, line_number, product_description, quantity_ordered, unit_cost)
    VALUES (test_po_id, 2, 'Test Calc Item', 10, 5.50) RETURNING order_item_id INTO test_item_id;
    
    SELECT line_total INTO calculated_line_total FROM order_items WHERE order_item_id = test_item_id;
    
    IF calculated_line_total = 55.00 THEN
        PERFORM log_test_result('test_calc_line_total', 'Test line_total calculated field', 'PASS');
    ELSE
        PERFORM log_test_result('test_calc_line_total', 'Test line_total calculated field', 'FAIL', 
            'Expected 55.00, got ' || calculated_line_total::TEXT);
    END IF;
    
    DELETE FROM order_items WHERE order_item_id = test_item_id;

    -- Test net_amount calculation (line_total - discount_amount)
    INSERT INTO order_items (purchase_order_id, line_number, product_description, quantity_ordered, unit_cost, discount_amount)
    VALUES (test_po_id, 3, 'Test Calc Item 2', 20, 3.00, 10.00) RETURNING order_item_id INTO test_item_id;
    
    SELECT net_amount INTO calculated_net_amount FROM order_items WHERE order_item_id = test_item_id;
    
    IF calculated_net_amount = 50.00 THEN
        PERFORM log_test_result('test_calc_net_amount', 'Test net_amount calculated field', 'PASS');
    ELSE
        PERFORM log_test_result('test_calc_net_amount', 'Test net_amount calculated field', 'FAIL', 
            'Expected 50.00, got ' || calculated_net_amount::TEXT);
    END IF;
    
    DELETE FROM order_items WHERE order_item_id = test_item_id;

    -- Cleanup
    DELETE FROM purchase_orders WHERE purchase_order_id = test_po_id;
    DELETE FROM suppliers WHERE supplier_id = test_supplier_id;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
    PERFORM log_test_result('test_items_error', 'Order items test encountered error', 'FAIL', error_msg);
END;
$$ LANGUAGE plpgsql;

-- Test constraint violations for order items (separate functions)
CREATE OR REPLACE FUNCTION test_zero_quantity_ordered() RETURNS VOID AS $$
DECLARE
    test_supplier_id INTEGER;
    test_po_id INTEGER;
BEGIN
    -- Create test data
    INSERT INTO suppliers (company_name, supplier_type) 
    VALUES ('Test Zero Qty Supplier', 'fabric') RETURNING supplier_id INTO test_supplier_id;
    
    INSERT INTO purchase_orders (po_number, supplier_id) 
    VALUES ('TEST-ZERO-QTY-PO', test_supplier_id) RETURNING purchase_order_id INTO test_po_id;

    INSERT INTO order_items (purchase_order_id, line_number, product_description, quantity_ordered, unit_cost)
    VALUES (test_po_id, 1, 'Test Item', 0, 10.00);
    
    PERFORM log_test_result('test_items_positive_qty', 'Test quantity_ordered > 0 constraint', 'FAIL', 'Should have rejected zero quantity');
EXCEPTION 
    WHEN check_violation THEN
        PERFORM log_test_result('test_items_positive_qty', 'Test quantity_ordered > 0 constraint', 'PASS');
        DELETE FROM purchase_orders WHERE purchase_order_id = test_po_id;
        DELETE FROM suppliers WHERE supplier_id = test_supplier_id;
    WHEN OTHERS THEN
        PERFORM log_test_result('test_items_positive_qty', 'Test quantity_ordered > 0 constraint', 'FAIL', SQLERRM);
END;
$$ LANGUAGE plpgsql;

-- Test 5: Data integrity and consistency
CREATE OR REPLACE FUNCTION test_data_integrity() RETURNS VOID AS $$
DECLARE
    record_count INTEGER;
    error_msg TEXT;
BEGIN
    -- Check that all products with supplier_id reference existing suppliers
    SELECT COUNT(*) INTO record_count
    FROM products p
    LEFT JOIN suppliers s ON p.supplier_id = s.supplier_id
    WHERE p.supplier_id IS NOT NULL AND s.supplier_id IS NULL;
    
    IF record_count = 0 THEN
        PERFORM log_test_result('test_integrity_product_supplier', 'Test product-supplier referential integrity', 'PASS');
    ELSE
        PERFORM log_test_result('test_integrity_product_supplier', 'Test product-supplier referential integrity', 'FAIL', 
            record_count || ' orphaned product records found');
    END IF;

    -- Check that all purchase orders reference existing suppliers
    SELECT COUNT(*) INTO record_count
    FROM purchase_orders po
    LEFT JOIN suppliers s ON po.supplier_id = s.supplier_id
    WHERE s.supplier_id IS NULL;
    
    IF record_count = 0 THEN
        PERFORM log_test_result('test_integrity_po_supplier', 'Test purchase order-supplier referential integrity', 'PASS');
    ELSE
        PERFORM log_test_result('test_integrity_po_supplier', 'Test purchase order-supplier referential integrity', 'FAIL', 
            record_count || ' orphaned purchase order records found');
    END IF;

    -- Check that all order items reference existing purchase orders
    SELECT COUNT(*) INTO record_count
    FROM order_items oi
    LEFT JOIN purchase_orders po ON oi.purchase_order_id = po.purchase_order_id
    WHERE po.purchase_order_id IS NULL;
    
    IF record_count = 0 THEN
        PERFORM log_test_result('test_integrity_item_po', 'Test order item-purchase order referential integrity', 'PASS');
    ELSE
        PERFORM log_test_result('test_integrity_item_po', 'Test order item-purchase order referential integrity', 'FAIL', 
            record_count || ' orphaned order item records found');
    END IF;

    -- Check that calculated fields are correct for existing data
    SELECT COUNT(*) INTO record_count
    FROM order_items
    WHERE line_total != (quantity_ordered * unit_cost)
       OR net_amount != (line_total - discount_amount);
    
    IF record_count = 0 THEN
        PERFORM log_test_result('test_integrity_calculations', 'Test calculated field integrity', 'PASS');
    ELSE
        PERFORM log_test_result('test_integrity_calculations', 'Test calculated field integrity', 'FAIL', 
            record_count || ' records with incorrect calculated values found');
    END IF;

    -- Check that quantity_received <= quantity_ordered for all items
    SELECT COUNT(*) INTO record_count
    FROM order_items
    WHERE quantity_received > quantity_ordered;
    
    IF record_count = 0 THEN
        PERFORM log_test_result('test_integrity_quantities', 'Test quantity constraints integrity', 'PASS');
    ELSE
        PERFORM log_test_result('test_integrity_quantities', 'Test quantity constraints integrity', 'FAIL', 
            record_count || ' records with received > ordered found');
    END IF;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
    PERFORM log_test_result('test_integrity_error', 'Data integrity test encountered error', 'FAIL', error_msg);
END;
$$ LANGUAGE plpgsql;

-- Function to run all unit tests
CREATE OR REPLACE FUNCTION run_all_unit_tests() RETURNS TABLE(
    test_name VARCHAR(255),
    status VARCHAR(10),
    error_message TEXT
) AS $$
BEGIN
    -- Clear previous test results
    DELETE FROM test_results;
    
    -- Run all unit tests
    PERFORM test_suppliers_constraints();
    PERFORM test_invalid_supplier_type();
    PERFORM test_null_company_name();
    PERFORM test_products_constraints();
    PERFORM test_unique_sku();
    PERFORM test_invalid_product_type();
    PERFORM test_purchase_orders_constraints();
    PERFORM test_unique_po_number();
    PERFORM test_invalid_po_status();
    PERFORM test_order_items_constraints();
    PERFORM test_zero_quantity_ordered();
    PERFORM test_data_integrity();
    
    -- Return test results
    RETURN QUERY
    SELECT tr.test_name, tr.status, tr.error_message
    FROM test_results tr
    ORDER BY tr.test_id;
END;
$$ LANGUAGE plpgsql;

-- Helper function to display test summary
CREATE OR REPLACE FUNCTION display_test_summary() RETURNS TABLE(
    total_tests INTEGER,
    passed_tests INTEGER,
    failed_tests INTEGER,
    pass_rate DECIMAL(5,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as total_tests,
        COUNT(CASE WHEN status = 'PASS' THEN 1 END)::INTEGER as passed_tests,
        COUNT(CASE WHEN status = 'FAIL' THEN 1 END)::INTEGER as failed_tests,
        CASE 
            WHEN COUNT(*) = 0 THEN 0.00
            ELSE ROUND(
                (COUNT(CASE WHEN status = 'PASS' THEN 1 END)::DECIMAL / COUNT(*)::DECIMAL * 100), 
                2
            )
        END as pass_rate
    FROM test_results;
END;
$$ LANGUAGE plpgsql;

-- Display instructions for running tests
SELECT 'Zava Database Unit Tests Created Successfully!' as message;
SELECT 'To run all unit tests, execute: SELECT * FROM run_all_unit_tests();' as instruction;
SELECT 'To view test summary, execute: SELECT * FROM display_test_summary();' as instruction2;
SELECT 'To view detailed results, execute: SELECT * FROM test_results ORDER BY test_id;' as instruction3;