-- Unit Tests for Zava Apparel Design Shop Database
-- This file contains stored procedures that perform unit tests on the database schema
-- Tests cover data integrity, business logic, constraints, and edge cases

-- Create a schema for test procedures
CREATE SCHEMA IF NOT EXISTS test_framework;

-- Test results table to track test outcomes
CREATE TABLE IF NOT EXISTS test_framework.test_results (
    test_id SERIAL PRIMARY KEY,
    test_name VARCHAR(255) NOT NULL,
    test_category VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('PASS', 'FAIL', 'ERROR')),
    error_message TEXT,
    execution_time INTERVAL,
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Helper function to log test results
CREATE OR REPLACE FUNCTION test_framework.log_test_result(
    p_test_name VARCHAR(255),
    p_test_category VARCHAR(100),
    p_status VARCHAR(20),
    p_error_message TEXT DEFAULT NULL,
    p_start_time TIMESTAMP DEFAULT NULL
) RETURNS VOID AS $$
DECLARE
    execution_time INTERVAL;
BEGIN
    IF p_start_time IS NOT NULL THEN
        execution_time := CURRENT_TIMESTAMP - p_start_time;
    END IF;
    
    INSERT INTO test_framework.test_results (test_name, test_category, status, error_message, execution_time)
    VALUES (p_test_name, p_test_category, p_status, p_error_message, execution_time);
END;
$$ LANGUAGE plpgsql;

-- Test procedure to validate supplier constraints
CREATE OR REPLACE FUNCTION test_framework.test_supplier_constraints() RETURNS VOID AS $$
DECLARE
    start_time TIMESTAMP := CURRENT_TIMESTAMP;
    test_count INTEGER := 0;
    error_msg TEXT;
BEGIN
    -- Test 1: Valid supplier type constraint
    BEGIN
        INSERT INTO suppliers (company_name, supplier_type) VALUES ('Test Supplier', 'fabric');
        DELETE FROM suppliers WHERE company_name = 'Test Supplier';
        test_count := test_count + 1;
    EXCEPTION WHEN OTHERS THEN
        error_msg := 'Valid supplier type test failed: ' || SQLERRM;
        PERFORM test_framework.log_test_result('Supplier Valid Type', 'Constraints', 'FAIL', error_msg, start_time);
        RETURN;
    END;
    
    -- Test 2: Invalid supplier type constraint
    BEGIN
        INSERT INTO suppliers (company_name, supplier_type) VALUES ('Test Supplier', 'invalid_type');
        error_msg := 'Invalid supplier type was allowed';
        PERFORM test_framework.log_test_result('Supplier Invalid Type', 'Constraints', 'FAIL', error_msg, start_time);
        RETURN;
    EXCEPTION 
        WHEN check_violation THEN
            test_count := test_count + 1;
        WHEN OTHERS THEN
            error_msg := 'Unexpected error in invalid supplier type test: ' || SQLERRM;
            PERFORM test_framework.log_test_result('Supplier Invalid Type', 'Constraints', 'ERROR', error_msg, start_time);
            RETURN;
    END;
    
    -- Test 3: Required fields
    BEGIN
        INSERT INTO suppliers (supplier_type) VALUES ('fabric');
        error_msg := 'Required company_name was allowed to be NULL';
        PERFORM test_framework.log_test_result('Supplier Required Fields', 'Constraints', 'FAIL', error_msg, start_time);
        RETURN;
    EXCEPTION 
        WHEN not_null_violation THEN
            test_count := test_count + 1;
        WHEN OTHERS THEN
            error_msg := 'Unexpected error in required fields test: ' || SQLERRM;
            PERFORM test_framework.log_test_result('Supplier Required Fields', 'Constraints', 'ERROR', error_msg, start_time);
            RETURN;
    END;
    
    PERFORM test_framework.log_test_result('Supplier Constraints', 'Constraints', 'PASS', 'All ' || test_count || ' tests passed', start_time);
END;
$$ LANGUAGE plpgsql;

-- Test procedure to validate product constraints
CREATE OR REPLACE FUNCTION test_framework.test_product_constraints() RETURNS VOID AS $$
DECLARE
    start_time TIMESTAMP := CURRENT_TIMESTAMP;
    test_count INTEGER := 0;
    error_msg TEXT;
    test_supplier_id INTEGER;
BEGIN
    -- Create a test supplier for foreign key tests
    INSERT INTO suppliers (company_name, supplier_type) VALUES ('Test Supplier Products', 'fabric') RETURNING supplier_id INTO test_supplier_id;
    
    -- Test 1: Valid product type constraint
    BEGIN
        INSERT INTO products (sku, product_name, product_type, supplier_id) VALUES ('TEST-001', 'Test Product', 'raw_material', test_supplier_id);
        DELETE FROM products WHERE sku = 'TEST-001';
        test_count := test_count + 1;
    EXCEPTION WHEN OTHERS THEN
        error_msg := 'Valid product type test failed: ' || SQLERRM;
        PERFORM test_framework.log_test_result('Product Valid Type', 'Constraints', 'FAIL', error_msg, start_time);
        DELETE FROM suppliers WHERE supplier_id = test_supplier_id;
        RETURN;
    END;
    
    -- Test 2: Invalid product type constraint
    BEGIN
        INSERT INTO products (sku, product_name, product_type, supplier_id) VALUES ('TEST-002', 'Test Product', 'invalid_type', test_supplier_id);
        error_msg := 'Invalid product type was allowed';
        PERFORM test_framework.log_test_result('Product Invalid Type', 'Constraints', 'FAIL', error_msg, start_time);
        DELETE FROM suppliers WHERE supplier_id = test_supplier_id;
        RETURN;
    EXCEPTION WHEN check_violation THEN
        test_count := test_count + 1;
    EXCEPTION WHEN OTHERS THEN
        error_msg := 'Unexpected error in invalid product type test: ' || SQLERRM;
        PERFORM test_framework.log_test_result('Product Invalid Type', 'Constraints', 'ERROR', error_msg, start_time);
        DELETE FROM suppliers WHERE supplier_id = test_supplier_id;
        RETURN;
    END;
    
    -- Test 3: SKU uniqueness
    BEGIN
        INSERT INTO products (sku, product_name, product_type, supplier_id) VALUES ('UNIQUE-001', 'Test Product 1', 'raw_material', test_supplier_id);
        INSERT INTO products (sku, product_name, product_type, supplier_id) VALUES ('UNIQUE-001', 'Test Product 2', 'raw_material', test_supplier_id);
        error_msg := 'Duplicate SKU was allowed';
        PERFORM test_framework.log_test_result('Product SKU Uniqueness', 'Constraints', 'FAIL', error_msg, start_time);
        DELETE FROM suppliers WHERE supplier_id = test_supplier_id;
        RETURN;
    EXCEPTION WHEN unique_violation THEN
        test_count := test_count + 1;
        DELETE FROM products WHERE sku = 'UNIQUE-001';
    EXCEPTION WHEN OTHERS THEN
        error_msg := 'Unexpected error in SKU uniqueness test: ' || SQLERRM;
        PERFORM test_framework.log_test_result('Product SKU Uniqueness', 'Constraints', 'ERROR', error_msg, start_time);
        DELETE FROM suppliers WHERE supplier_id = test_supplier_id;
        RETURN;
    END;
    
    -- Clean up test supplier
    DELETE FROM suppliers WHERE supplier_id = test_supplier_id;
    
    PERFORM test_framework.log_test_result('Product Constraints', 'Constraints', 'PASS', 'All ' || test_count || ' tests passed', start_time);
END;
$$ LANGUAGE plpgsql;

-- Test procedure to validate purchase order constraints and business logic
CREATE OR REPLACE FUNCTION test_framework.test_purchase_order_logic() RETURNS VOID AS $$
DECLARE
    start_time TIMESTAMP := CURRENT_TIMESTAMP;
    test_count INTEGER := 0;
    error_msg TEXT;
    test_supplier_id INTEGER;
    test_po_id INTEGER;
BEGIN
    -- Create a test supplier
    INSERT INTO suppliers (company_name, supplier_type) VALUES ('Test Supplier PO', 'fabric') RETURNING supplier_id INTO test_supplier_id;
    
    -- Test 1: Valid PO status constraint
    BEGIN
        INSERT INTO purchase_orders (po_number, supplier_id, status) VALUES ('TEST-PO-001', test_supplier_id, 'draft') RETURNING purchase_order_id INTO test_po_id;
        DELETE FROM purchase_orders WHERE purchase_order_id = test_po_id;
        test_count := test_count + 1;
    EXCEPTION WHEN OTHERS THEN
        error_msg := 'Valid PO status test failed: ' || SQLERRM;
        PERFORM test_framework.log_test_result('PO Valid Status', 'Business Logic', 'FAIL', error_msg, start_time);
        DELETE FROM suppliers WHERE supplier_id = test_supplier_id;
        RETURN;
    END;
    
    -- Test 2: Invalid PO status constraint
    BEGIN
        INSERT INTO purchase_orders (po_number, supplier_id, status) VALUES ('TEST-PO-002', test_supplier_id, 'invalid_status');
        error_msg := 'Invalid PO status was allowed';
        PERFORM test_framework.log_test_result('PO Invalid Status', 'Business Logic', 'FAIL', error_msg, start_time);
        DELETE FROM suppliers WHERE supplier_id = test_supplier_id;
        RETURN;
    EXCEPTION WHEN check_violation THEN
        test_count := test_count + 1;
    EXCEPTION WHEN OTHERS THEN
        error_msg := 'Unexpected error in invalid PO status test: ' || SQLERRM;
        PERFORM test_framework.log_test_result('PO Invalid Status', 'Business Logic', 'ERROR', error_msg, start_time);
        DELETE FROM suppliers WHERE supplier_id = test_supplier_id;
        RETURN;
    END;
    
    -- Test 3: PO number uniqueness
    BEGIN
        INSERT INTO purchase_orders (po_number, supplier_id) VALUES ('UNIQUE-PO-001', test_supplier_id);
        INSERT INTO purchase_orders (po_number, supplier_id) VALUES ('UNIQUE-PO-001', test_supplier_id);
        error_msg := 'Duplicate PO number was allowed';
        PERFORM test_framework.log_test_result('PO Number Uniqueness', 'Business Logic', 'FAIL', error_msg, start_time);
        DELETE FROM suppliers WHERE supplier_id = test_supplier_id;
        RETURN;
    EXCEPTION WHEN unique_violation THEN
        test_count := test_count + 1;
        DELETE FROM purchase_orders WHERE po_number = 'UNIQUE-PO-001';
    EXCEPTION WHEN OTHERS THEN
        error_msg := 'Unexpected error in PO uniqueness test: ' || SQLERRM;
        PERFORM test_framework.log_test_result('PO Number Uniqueness', 'Business Logic', 'ERROR', error_msg, start_time);
        DELETE FROM suppliers WHERE supplier_id = test_supplier_id;
        RETURN;
    END;
    
    -- Clean up test supplier
    DELETE FROM suppliers WHERE supplier_id = test_supplier_id;
    
    PERFORM test_framework.log_test_result('Purchase Order Logic', 'Business Logic', 'PASS', 'All ' || test_count || ' tests passed', start_time);
END;
$$ LANGUAGE plpgsql;

-- Test procedure to validate order item constraints and calculations
CREATE OR REPLACE FUNCTION test_framework.test_order_item_calculations() RETURNS VOID AS $$
DECLARE
    start_time TIMESTAMP := CURRENT_TIMESTAMP;
    test_count INTEGER := 0;
    error_msg TEXT;
    test_supplier_id INTEGER;
    test_product_id INTEGER;
    test_po_id INTEGER;
    calculated_line_total DECIMAL(12,2);
    calculated_net_amount DECIMAL(12,2);
BEGIN
    -- Set up test data
    INSERT INTO suppliers (company_name, supplier_type) VALUES ('Test Supplier OI', 'fabric') RETURNING supplier_id INTO test_supplier_id;
    INSERT INTO products (sku, product_name, product_type, supplier_id) VALUES ('TEST-CALC-001', 'Test Product', 'raw_material', test_supplier_id) RETURNING product_id INTO test_product_id;
    INSERT INTO purchase_orders (po_number, supplier_id) VALUES ('TEST-CALC-PO', test_supplier_id) RETURNING purchase_order_id INTO test_po_id;
    
    -- Test 1: Line total calculation
    BEGIN
        INSERT INTO order_items (purchase_order_id, line_number, product_id, product_description, quantity_ordered, unit_cost) 
        VALUES (test_po_id, 1, test_product_id, 'Test Product', 10, 5.50);
        
        SELECT line_total INTO calculated_line_total 
        FROM order_items 
        WHERE purchase_order_id = test_po_id AND line_number = 1;
        
        IF calculated_line_total = 55.00 THEN
            test_count := test_count + 1;
        ELSE
            error_msg := 'Line total calculation incorrect. Expected 55.00, got ' || calculated_line_total;
            PERFORM test_framework.log_test_result('Order Item Line Total', 'Calculations', 'FAIL', error_msg, start_time);
            DELETE FROM suppliers WHERE supplier_id = test_supplier_id;
            RETURN;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        error_msg := 'Line total calculation test failed: ' || SQLERRM;
        PERFORM test_framework.log_test_result('Order Item Line Total', 'Calculations', 'FAIL', error_msg, start_time);
        DELETE FROM suppliers WHERE supplier_id = test_supplier_id;
        RETURN;
    END;
    
    -- Test 2: Net amount calculation with discount
    BEGIN
        UPDATE order_items SET discount_amount = 5.00 
        WHERE purchase_order_id = test_po_id AND line_number = 1;
        
        SELECT net_amount INTO calculated_net_amount 
        FROM order_items 
        WHERE purchase_order_id = test_po_id AND line_number = 1;
        
        IF calculated_net_amount = 50.00 THEN
            test_count := test_count + 1;
        ELSE
            error_msg := 'Net amount calculation incorrect. Expected 50.00, got ' || calculated_net_amount;
            PERFORM test_framework.log_test_result('Order Item Net Amount', 'Calculations', 'FAIL', error_msg, start_time);
            DELETE FROM suppliers WHERE supplier_id = test_supplier_id;
            RETURN;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        error_msg := 'Net amount calculation test failed: ' || SQLERRM;
        PERFORM test_framework.log_test_result('Order Item Net Amount', 'Calculations', 'FAIL', error_msg, start_time);
        DELETE FROM suppliers WHERE supplier_id = test_supplier_id;
        RETURN;
    END;
    
    -- Test 3: Quantity received constraint
    BEGIN
        UPDATE order_items SET quantity_received = 15 
        WHERE purchase_order_id = test_po_id AND line_number = 1;
        error_msg := 'Quantity received > quantity ordered was allowed';
        PERFORM test_framework.log_test_result('Order Item Quantity Constraint', 'Constraints', 'FAIL', error_msg, start_time);
        DELETE FROM suppliers WHERE supplier_id = test_supplier_id;
        RETURN;
    EXCEPTION WHEN check_violation THEN
        test_count := test_count + 1;
    EXCEPTION WHEN OTHERS THEN
        error_msg := 'Unexpected error in quantity constraint test: ' || SQLERRM;
        PERFORM test_framework.log_test_result('Order Item Quantity Constraint', 'Constraints', 'ERROR', error_msg, start_time);
        DELETE FROM suppliers WHERE supplier_id = test_supplier_id;
        RETURN;
    END;
    
    -- Test 4: Negative quantity constraint
    BEGIN
        INSERT INTO order_items (purchase_order_id, line_number, product_id, product_description, quantity_ordered, unit_cost) 
        VALUES (test_po_id, 2, test_product_id, 'Test Product', -5, 5.50);
        error_msg := 'Negative quantity ordered was allowed';
        PERFORM test_framework.log_test_result('Order Item Negative Quantity', 'Constraints', 'FAIL', error_msg, start_time);
        DELETE FROM suppliers WHERE supplier_id = test_supplier_id;
        RETURN;
    EXCEPTION WHEN check_violation THEN
        test_count := test_count + 1;
    EXCEPTION WHEN OTHERS THEN
        error_msg := 'Unexpected error in negative quantity test: ' || SQLERRM;
        PERFORM test_framework.log_test_result('Order Item Negative Quantity', 'Constraints', 'ERROR', error_msg, start_time);
        DELETE FROM suppliers WHERE supplier_id = test_supplier_id;
        RETURN;
    END;
    
    -- Clean up test data
    DELETE FROM suppliers WHERE supplier_id = test_supplier_id;
    
    PERFORM test_framework.log_test_result('Order Item Calculations', 'Calculations', 'PASS', 'All ' || test_count || ' tests passed', start_time);
END;
$$ LANGUAGE plpgsql;

-- Test procedure to validate foreign key relationships
CREATE OR REPLACE FUNCTION test_framework.test_foreign_key_relationships() RETURNS VOID AS $$
DECLARE
    start_time TIMESTAMP := CURRENT_TIMESTAMP;
    test_count INTEGER := 0;
    error_msg TEXT;
    test_supplier_id INTEGER;
    test_product_id INTEGER;
    test_po_id INTEGER;
BEGIN
    -- Create test data
    INSERT INTO suppliers (company_name, supplier_type) VALUES ('Test Supplier FK', 'fabric') RETURNING supplier_id INTO test_supplier_id;
    INSERT INTO products (sku, product_name, product_type, supplier_id) VALUES ('TEST-FK-001', 'Test Product', 'raw_material', test_supplier_id) RETURNING product_id INTO test_product_id;
    INSERT INTO purchase_orders (po_number, supplier_id) VALUES ('TEST-FK-PO', test_supplier_id) RETURNING purchase_order_id INTO test_po_id;
    
    -- Test 1: Product with invalid supplier_id
    BEGIN
        INSERT INTO products (sku, product_name, product_type, supplier_id) VALUES ('TEST-FK-002', 'Test Product', 'raw_material', 99999);
        error_msg := 'Product with invalid supplier_id was allowed';
        PERFORM test_framework.log_test_result('Product FK Constraint', 'Foreign Keys', 'FAIL', error_msg, start_time);
        DELETE FROM suppliers WHERE supplier_id = test_supplier_id;
        RETURN;
    EXCEPTION WHEN foreign_key_violation THEN
        test_count := test_count + 1;
    EXCEPTION WHEN OTHERS THEN
        error_msg := 'Unexpected error in product FK test: ' || SQLERRM;
        PERFORM test_framework.log_test_result('Product FK Constraint', 'Foreign Keys', 'ERROR', error_msg, start_time);
        DELETE FROM suppliers WHERE supplier_id = test_supplier_id;
        RETURN;
    END;
    
    -- Test 2: Purchase order with invalid supplier_id
    BEGIN
        INSERT INTO purchase_orders (po_number, supplier_id) VALUES ('TEST-FK-PO-2', 99999);
        error_msg := 'Purchase order with invalid supplier_id was allowed';
        PERFORM test_framework.log_test_result('PO FK Constraint', 'Foreign Keys', 'FAIL', error_msg, start_time);
        DELETE FROM suppliers WHERE supplier_id = test_supplier_id;
        RETURN;
    EXCEPTION WHEN foreign_key_violation THEN
        test_count := test_count + 1;
    EXCEPTION WHEN OTHERS THEN
        error_msg := 'Unexpected error in PO FK test: ' || SQLERRM;
        PERFORM test_framework.log_test_result('PO FK Constraint', 'Foreign Keys', 'ERROR', error_msg, start_time);
        DELETE FROM suppliers WHERE supplier_id = test_supplier_id;
        RETURN;
    END;
    
    -- Test 3: Order item with invalid purchase_order_id
    BEGIN
        INSERT INTO order_items (purchase_order_id, line_number, product_id, product_description, quantity_ordered, unit_cost) 
        VALUES (99999, 1, test_product_id, 'Test Product', 10, 5.50);
        error_msg := 'Order item with invalid purchase_order_id was allowed';
        PERFORM test_framework.log_test_result('Order Item PO FK Constraint', 'Foreign Keys', 'FAIL', error_msg, start_time);
        DELETE FROM suppliers WHERE supplier_id = test_supplier_id;
        RETURN;
    EXCEPTION WHEN foreign_key_violation THEN
        test_count := test_count + 1;
    EXCEPTION WHEN OTHERS THEN
        error_msg := 'Unexpected error in order item PO FK test: ' || SQLERRM;
        PERFORM test_framework.log_test_result('Order Item PO FK Constraint', 'Foreign Keys', 'ERROR', error_msg, start_time);
        DELETE FROM suppliers WHERE supplier_id = test_supplier_id;
        RETURN;
    END;
    
    -- Test 4: Cascade delete test
    BEGIN
        INSERT INTO order_items (purchase_order_id, line_number, product_id, product_description, quantity_ordered, unit_cost) 
        VALUES (test_po_id, 1, test_product_id, 'Test Product', 10, 5.50);
        
        DELETE FROM purchase_orders WHERE purchase_order_id = test_po_id;
        
        -- Check if order items were cascaded
        IF EXISTS (SELECT 1 FROM order_items WHERE purchase_order_id = test_po_id) THEN
            error_msg := 'Order items were not cascade deleted';
            PERFORM test_framework.log_test_result('Cascade Delete', 'Foreign Keys', 'FAIL', error_msg, start_time);
            DELETE FROM suppliers WHERE supplier_id = test_supplier_id;
            RETURN;
        ELSE
            test_count := test_count + 1;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        error_msg := 'Cascade delete test failed: ' || SQLERRM;
        PERFORM test_framework.log_test_result('Cascade Delete', 'Foreign Keys', 'FAIL', error_msg, start_time);
        DELETE FROM suppliers WHERE supplier_id = test_supplier_id;
        RETURN;
    END;
    
    -- Clean up test data
    DELETE FROM suppliers WHERE supplier_id = test_supplier_id;
    
    PERFORM test_framework.log_test_result('Foreign Key Relationships', 'Foreign Keys', 'PASS', 'All ' || test_count || ' tests passed', start_time);
END;
$$ LANGUAGE plpgsql;

-- Test procedure to validate data integrity with existing test data
CREATE OR REPLACE FUNCTION test_framework.test_data_integrity() RETURNS VOID AS $$
DECLARE
    start_time TIMESTAMP := CURRENT_TIMESTAMP;
    test_count INTEGER := 0;
    error_msg TEXT;
    record_count INTEGER;
    orphan_count INTEGER;
BEGIN
    -- Test 1: Check all suppliers have valid types
    BEGIN
        SELECT COUNT(*) INTO record_count FROM suppliers WHERE supplier_type NOT IN ('fabric', 'trims', 'hardware', 'manufacturing', 'packaging');
        IF record_count = 0 THEN
            test_count := test_count + 1;
        ELSE
            error_msg := 'Found ' || record_count || ' suppliers with invalid types';
            PERFORM test_framework.log_test_result('Supplier Type Integrity', 'Data Integrity', 'FAIL', error_msg, start_time);
            RETURN;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        error_msg := 'Supplier type integrity test failed: ' || SQLERRM;
        PERFORM test_framework.log_test_result('Supplier Type Integrity', 'Data Integrity', 'ERROR', error_msg, start_time);
        RETURN;
    END;
    
    -- Test 2: Check all products have valid types
    BEGIN
        SELECT COUNT(*) INTO record_count FROM products WHERE product_type NOT IN ('finished_good', 'raw_material', 'component', 'accessory');
        IF record_count = 0 THEN
            test_count := test_count + 1;
        ELSE
            error_msg := 'Found ' || record_count || ' products with invalid types';
            PERFORM test_framework.log_test_result('Product Type Integrity', 'Data Integrity', 'FAIL', error_msg, start_time);
            RETURN;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        error_msg := 'Product type integrity test failed: ' || SQLERRM;
        PERFORM test_framework.log_test_result('Product Type Integrity', 'Data Integrity', 'ERROR', error_msg, start_time);
        RETURN;
    END;
    
    -- Test 3: Check for orphaned products (supplier_id not in suppliers table)
    BEGIN
        SELECT COUNT(*) INTO orphan_count 
        FROM products p 
        LEFT JOIN suppliers s ON p.supplier_id = s.supplier_id 
        WHERE p.supplier_id IS NOT NULL AND s.supplier_id IS NULL;
        
        IF orphan_count = 0 THEN
            test_count := test_count + 1;
        ELSE
            error_msg := 'Found ' || orphan_count || ' orphaned products';
            PERFORM test_framework.log_test_result('Product Orphan Check', 'Data Integrity', 'FAIL', error_msg, start_time);
            RETURN;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        error_msg := 'Product orphan check failed: ' || SQLERRM;
        PERFORM test_framework.log_test_result('Product Orphan Check', 'Data Integrity', 'ERROR', error_msg, start_time);
        RETURN;
    END;
    
    -- Test 4: Check order item calculations are correct
    BEGIN
        SELECT COUNT(*) INTO record_count 
        FROM order_items 
        WHERE line_total != (quantity_ordered * unit_cost) 
           OR net_amount != (line_total - discount_amount);
        
        IF record_count = 0 THEN
            test_count := test_count + 1;
        ELSE
            error_msg := 'Found ' || record_count || ' order items with incorrect calculations';
            PERFORM test_framework.log_test_result('Order Item Calculation Integrity', 'Data Integrity', 'FAIL', error_msg, start_time);
            RETURN;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        error_msg := 'Order item calculation integrity test failed: ' || SQLERRM;
        PERFORM test_framework.log_test_result('Order Item Calculation Integrity', 'Data Integrity', 'ERROR', error_msg, start_time);
        RETURN;
    END;
    
    -- Test 5: Check quantity constraints
    BEGIN
        SELECT COUNT(*) INTO record_count 
        FROM order_items 
        WHERE quantity_received > quantity_ordered 
           OR quantity_ordered <= 0 
           OR quantity_received < 0;
        
        IF record_count = 0 THEN
            test_count := test_count + 1;
        ELSE
            error_msg := 'Found ' || record_count || ' order items with invalid quantities';
            PERFORM test_framework.log_test_result('Quantity Constraint Integrity', 'Data Integrity', 'FAIL', error_msg, start_time);
            RETURN;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        error_msg := 'Quantity constraint integrity test failed: ' || SQLERRM;
        PERFORM test_framework.log_test_result('Quantity Constraint Integrity', 'Data Integrity', 'ERROR', error_msg, start_time);
        RETURN;
    END;
    
    PERFORM test_framework.log_test_result('Data Integrity', 'Data Integrity', 'PASS', 'All ' || test_count || ' tests passed', start_time);
END;
$$ LANGUAGE plpgsql;

-- Master test runner procedure
CREATE OR REPLACE FUNCTION test_framework.run_all_tests() RETURNS TABLE(
    test_name VARCHAR(255),
    test_category VARCHAR(100),
    status VARCHAR(20),
    error_message TEXT,
    execution_time INTERVAL,
    executed_at TIMESTAMP
) AS $$
DECLARE
    start_time TIMESTAMP := CURRENT_TIMESTAMP;
BEGIN
    -- Clear previous test results
    DELETE FROM test_framework.test_results;
    
    -- Run all test procedures
    PERFORM test_framework.test_supplier_constraints();
    PERFORM test_framework.test_product_constraints();
    PERFORM test_framework.test_purchase_order_logic();
    PERFORM test_framework.test_order_item_calculations();
    PERFORM test_framework.test_foreign_key_relationships();
    PERFORM test_framework.test_data_integrity();
    
    -- Log overall test completion
    PERFORM test_framework.log_test_result('All Tests', 'Summary', 'COMPLETED', 'Test suite completed', start_time);
    
    -- Return test results
    RETURN QUERY SELECT * FROM test_framework.test_results ORDER BY test_id;
END;
$$ LANGUAGE plpgsql;

-- Function to get test summary
CREATE OR REPLACE FUNCTION test_framework.get_test_summary() RETURNS TABLE(
    total_tests BIGINT,
    passed BIGINT,
    failed BIGINT,
    errors BIGINT,
    pass_rate NUMERIC(5,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_tests,
        COUNT(*) FILTER (WHERE status = 'PASS') as passed,
        COUNT(*) FILTER (WHERE status = 'FAIL') as failed,
        COUNT(*) FILTER (WHERE status = 'ERROR') as errors,
        ROUND(
            (COUNT(*) FILTER (WHERE status = 'PASS')::NUMERIC / 
             NULLIF(COUNT(*) FILTER (WHERE status != 'COMPLETED'), 0)) * 100, 2
        ) as pass_rate
    FROM test_framework.test_results
    WHERE status != 'COMPLETED';
END;
$$ LANGUAGE plpgsql;