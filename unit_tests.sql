-- Simplified Unit Tests for Zava Apparel Design Shop Database
-- This file contains stored procedures that perform unit tests on the database schema

-- Create a schema for test procedures
CREATE SCHEMA IF NOT EXISTS test_framework;

-- Test results table to track test outcomes
CREATE TABLE IF NOT EXISTS test_framework.test_results (
    test_id SERIAL PRIMARY KEY,
    test_name VARCHAR(255) NOT NULL,
    test_category VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('PASS', 'FAIL', 'ERROR', 'COMPLETED')),
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

-- Test data integrity with existing test data
CREATE OR REPLACE FUNCTION test_framework.test_data_integrity() RETURNS VOID AS $$
DECLARE
    start_time TIMESTAMP := CURRENT_TIMESTAMP;
    test_count INTEGER := 0;
    error_msg TEXT;
    record_count INTEGER;
    orphan_count INTEGER;
BEGIN
    -- Test 1: Check all suppliers have valid types
    SELECT COUNT(*) INTO record_count FROM suppliers WHERE supplier_type NOT IN ('fabric', 'trims', 'hardware', 'manufacturing', 'packaging');
    IF record_count = 0 THEN
        test_count := test_count + 1;
        PERFORM test_framework.log_test_result('Supplier Type Integrity', 'Data Integrity', 'PASS', 'All supplier types are valid', start_time);
    ELSE
        error_msg := 'Found ' || record_count || ' suppliers with invalid types';
        PERFORM test_framework.log_test_result('Supplier Type Integrity', 'Data Integrity', 'FAIL', error_msg, start_time);
    END IF;
    
    -- Test 2: Check all products have valid types
    SELECT COUNT(*) INTO record_count FROM products WHERE product_type NOT IN ('finished_good', 'raw_material', 'component', 'accessory');
    IF record_count = 0 THEN
        test_count := test_count + 1;
        PERFORM test_framework.log_test_result('Product Type Integrity', 'Data Integrity', 'PASS', 'All product types are valid', start_time);
    ELSE
        error_msg := 'Found ' || record_count || ' products with invalid types';
        PERFORM test_framework.log_test_result('Product Type Integrity', 'Data Integrity', 'FAIL', error_msg, start_time);
    END IF;
    
    -- Test 3: Check for orphaned products
    SELECT COUNT(*) INTO orphan_count 
    FROM products p 
    LEFT JOIN suppliers s ON p.supplier_id = s.supplier_id 
    WHERE p.supplier_id IS NOT NULL AND s.supplier_id IS NULL;
    
    IF orphan_count = 0 THEN
        test_count := test_count + 1;
        PERFORM test_framework.log_test_result('Product Orphan Check', 'Data Integrity', 'PASS', 'No orphaned products found', start_time);
    ELSE
        error_msg := 'Found ' || orphan_count || ' orphaned products';
        PERFORM test_framework.log_test_result('Product Orphan Check', 'Data Integrity', 'FAIL', error_msg, start_time);
    END IF;
    
    -- Test 4: Check order item calculations are correct
    SELECT COUNT(*) INTO record_count 
    FROM order_items 
    WHERE line_total != (quantity_ordered * unit_cost) 
       OR net_amount != (line_total - discount_amount);
    
    IF record_count = 0 THEN
        test_count := test_count + 1;
        PERFORM test_framework.log_test_result('Order Item Calculations', 'Data Integrity', 'PASS', 'All calculations are correct', start_time);
    ELSE
        error_msg := 'Found ' || record_count || ' order items with incorrect calculations';
        PERFORM test_framework.log_test_result('Order Item Calculations', 'Data Integrity', 'FAIL', error_msg, start_time);
    END IF;
    
    -- Test 5: Check quantity constraints
    SELECT COUNT(*) INTO record_count 
    FROM order_items 
    WHERE quantity_received > quantity_ordered 
       OR quantity_ordered <= 0 
       OR quantity_received < 0;
    
    IF record_count = 0 THEN
        test_count := test_count + 1;
        PERFORM test_framework.log_test_result('Quantity Constraints', 'Data Integrity', 'PASS', 'All quantity constraints satisfied', start_time);
    ELSE
        error_msg := 'Found ' || record_count || ' order items with invalid quantities';
        PERFORM test_framework.log_test_result('Quantity Constraints', 'Data Integrity', 'FAIL', error_msg, start_time);
    END IF;
    
END;
$$ LANGUAGE plpgsql;

-- Test constraint violations by attempting invalid operations
CREATE OR REPLACE FUNCTION test_framework.test_constraint_enforcement() RETURNS VOID AS $$
DECLARE
    start_time TIMESTAMP := CURRENT_TIMESTAMP;
    test_count INTEGER := 0;
    error_msg TEXT;
    test_supplier_id INTEGER;
BEGIN
    -- Set up test supplier
    INSERT INTO suppliers (company_name, supplier_type) VALUES ('Test Constraint Supplier', 'fabric') RETURNING supplier_id INTO test_supplier_id;
    
    -- Test 1: Invalid supplier type should fail
    BEGIN
        INSERT INTO suppliers (company_name, supplier_type) VALUES ('Bad Supplier', 'invalid_type');
        PERFORM test_framework.log_test_result('Invalid Supplier Type Test', 'Constraints', 'FAIL', 'Invalid supplier type was allowed', start_time);
    EXCEPTION 
        WHEN OTHERS THEN
            test_count := test_count + 1;
            PERFORM test_framework.log_test_result('Invalid Supplier Type Test', 'Constraints', 'PASS', 'Invalid supplier type correctly rejected', start_time);
    END;
    
    -- Test 2: Invalid product type should fail
    BEGIN
        INSERT INTO products (sku, product_name, product_type, supplier_id) VALUES ('BAD-001', 'Bad Product', 'invalid_type', test_supplier_id);
        PERFORM test_framework.log_test_result('Invalid Product Type Test', 'Constraints', 'FAIL', 'Invalid product type was allowed', start_time);
    EXCEPTION 
        WHEN OTHERS THEN
            test_count := test_count + 1;
            PERFORM test_framework.log_test_result('Invalid Product Type Test', 'Constraints', 'PASS', 'Invalid product type correctly rejected', start_time);
    END;
    
    -- Test 3: Duplicate SKU should fail
    BEGIN
        INSERT INTO products (sku, product_name, product_type, supplier_id) VALUES ('DUP-001', 'First Product', 'raw_material', test_supplier_id);
        INSERT INTO products (sku, product_name, product_type, supplier_id) VALUES ('DUP-001', 'Second Product', 'raw_material', test_supplier_id);
        PERFORM test_framework.log_test_result('Duplicate SKU Test', 'Constraints', 'FAIL', 'Duplicate SKU was allowed', start_time);
    EXCEPTION 
        WHEN OTHERS THEN
            test_count := test_count + 1;
            PERFORM test_framework.log_test_result('Duplicate SKU Test', 'Constraints', 'PASS', 'Duplicate SKU correctly rejected', start_time);
    END;
    
    -- Clean up test data (delete products first due to foreign key)
    DELETE FROM products WHERE supplier_id = test_supplier_id;
    DELETE FROM suppliers WHERE supplier_id = test_supplier_id;
    
END;
$$ LANGUAGE plpgsql;

-- Test business logic calculations
CREATE OR REPLACE FUNCTION test_framework.test_business_logic() RETURNS VOID AS $$
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
    INSERT INTO suppliers (company_name, supplier_type) VALUES ('Test Logic Supplier', 'fabric') RETURNING supplier_id INTO test_supplier_id;
    INSERT INTO products (sku, product_name, product_type, supplier_id) VALUES ('LOGIC-001', 'Test Product', 'raw_material', test_supplier_id) RETURNING product_id INTO test_product_id;
    INSERT INTO purchase_orders (po_number, supplier_id) VALUES ('LOGIC-PO', test_supplier_id) RETURNING purchase_order_id INTO test_po_id;
    
    -- Test 1: Line total calculation
    INSERT INTO order_items (purchase_order_id, line_number, product_id, product_description, quantity_ordered, unit_cost) 
    VALUES (test_po_id, 1, test_product_id, 'Test Product', 10, 5.50);
    
    SELECT line_total INTO calculated_line_total 
    FROM order_items 
    WHERE purchase_order_id = test_po_id AND line_number = 1;
    
    IF calculated_line_total = 55.00 THEN
        test_count := test_count + 1;
        PERFORM test_framework.log_test_result('Line Total Calculation', 'Business Logic', 'PASS', 'Line total calculated correctly: ' || calculated_line_total, start_time);
    ELSE
        error_msg := 'Line total calculation incorrect. Expected 55.00, got ' || calculated_line_total;
        PERFORM test_framework.log_test_result('Line Total Calculation', 'Business Logic', 'FAIL', error_msg, start_time);
    END IF;
    
    -- Test 2: Net amount calculation with discount
    UPDATE order_items SET discount_amount = 5.00 
    WHERE purchase_order_id = test_po_id AND line_number = 1;
    
    SELECT net_amount INTO calculated_net_amount 
    FROM order_items 
    WHERE purchase_order_id = test_po_id AND line_number = 1;
    
    IF calculated_net_amount = 50.00 THEN
        test_count := test_count + 1;
        PERFORM test_framework.log_test_result('Net Amount Calculation', 'Business Logic', 'PASS', 'Net amount calculated correctly: ' || calculated_net_amount, start_time);
    ELSE
        error_msg := 'Net amount calculation incorrect. Expected 50.00, got ' || calculated_net_amount;
        PERFORM test_framework.log_test_result('Net Amount Calculation', 'Business Logic', 'FAIL', error_msg, start_time);
    END IF;
    
    -- Test 3: Quantity constraint enforcement
    BEGIN
        UPDATE order_items SET quantity_received = 15 
        WHERE purchase_order_id = test_po_id AND line_number = 1;
        PERFORM test_framework.log_test_result('Quantity Constraint Test', 'Business Logic', 'FAIL', 'Quantity received > quantity ordered was allowed', start_time);
    EXCEPTION 
        WHEN OTHERS THEN
            test_count := test_count + 1;
            PERFORM test_framework.log_test_result('Quantity Constraint Test', 'Business Logic', 'PASS', 'Quantity constraint correctly enforced', start_time);
    END;
    
    -- Clean up test data (delete in correct order to respect foreign keys)
    DELETE FROM order_items WHERE purchase_order_id = test_po_id;
    DELETE FROM purchase_orders WHERE purchase_order_id = test_po_id;
    DELETE FROM products WHERE product_id = test_product_id;
    DELETE FROM suppliers WHERE supplier_id = test_supplier_id;
    
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
    PERFORM test_framework.test_data_integrity();
    PERFORM test_framework.test_constraint_enforcement();
    PERFORM test_framework.test_business_logic();
    
    -- Log overall test completion
    PERFORM test_framework.log_test_result('All Tests', 'Summary', 'COMPLETED', 'Test suite completed', start_time);
    
    -- Return test results
    RETURN QUERY SELECT 
        tr.test_name,
        tr.test_category,
        tr.status,
        tr.error_message,
        tr.execution_time,
        tr.executed_at
    FROM test_framework.test_results tr ORDER BY tr.test_id;
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