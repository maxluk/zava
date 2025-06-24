-- Test Runner Script for Zava Database
-- This script sets up the database, loads test data, and runs all unit tests
-- Usage: psql -d your_database -f run_tests.sql

\echo 'Starting Zava Database Test Suite...'
\echo '=================================='

-- Set up environment for testing
\set ON_ERROR_STOP on
\timing on

-- Check if schema exists
\echo 'Checking database schema...'
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'suppliers') THEN
        RAISE EXCEPTION 'Database schema not found. Please run zava_postgres_schema.sql first.';
    END IF;
END $$;

\echo 'Schema validation: OK'

-- Load test data
\echo ''
\echo 'Loading test data...'
\i test_data.sql

-- Load unit test procedures
\echo ''
\echo 'Loading unit test procedures...'
\i unit_tests.sql

-- Run all tests
\echo ''
\echo 'Running unit tests...'
\echo '===================='

-- Execute test suite
SELECT * FROM test_framework.run_all_tests();

\echo ''
\echo 'Test Summary:'
\echo '============='

-- Display test summary
SELECT * FROM test_framework.get_test_summary();

\echo ''
\echo 'Detailed Test Results:'
\echo '====================='

-- Show all test results with formatted output
SELECT 
    test_name,
    test_category,
    status,
    CASE 
        WHEN status = 'PASS' THEN '✓'
        WHEN status = 'FAIL' THEN '✗'
        WHEN status = 'ERROR' THEN '!'
        ELSE '-'
    END as result_icon,
    COALESCE(error_message, 'Success') as message,
    execution_time,
    executed_at
FROM test_framework.test_results 
WHERE status != 'COMPLETED'
ORDER BY 
    CASE test_category
        WHEN 'Constraints' THEN 1
        WHEN 'Business Logic' THEN 2
        WHEN 'Calculations' THEN 3
        WHEN 'Foreign Keys' THEN 4
        WHEN 'Data Integrity' THEN 5
        ELSE 6
    END,
    test_name;

-- Check for any failed tests
DO $$
DECLARE
    failed_count INTEGER;
    error_count INTEGER;
BEGIN
    SELECT 
        COUNT(*) FILTER (WHERE status = 'FAIL'),
        COUNT(*) FILTER (WHERE status = 'ERROR')
    INTO failed_count, error_count
    FROM test_framework.test_results
    WHERE status != 'COMPLETED';
    
    RAISE NOTICE '';
    IF failed_count = 0 AND error_count = 0 THEN
        RAISE NOTICE 'SUCCESS: All tests passed! ✓';
    ELSE
        RAISE NOTICE 'ATTENTION: % test(s) failed, % error(s) occurred', failed_count, error_count;
    END IF;
END $$;

\echo ''
\echo 'Test suite completed.'
\echo ''

-- Show database state after tests
\echo 'Database State Summary:'
\echo '======================'

SELECT 
    'Suppliers' as table_name, 
    COUNT(*) as total_records,
    COUNT(*) FILTER (WHERE is_active = true) as active_records
FROM suppliers
UNION ALL
SELECT 
    'Products', 
    COUNT(*),
    COUNT(*) FILTER (WHERE is_active = true)
FROM products
UNION ALL
SELECT 
    'Purchase Orders', 
    COUNT(*),
    COUNT(*) FILTER (WHERE status NOT IN ('cancelled', 'closed'))
FROM purchase_orders
UNION ALL
SELECT 
    'Order Items', 
    COUNT(*),
    COUNT(*) FILTER (WHERE quality_status = 'approved')
FROM order_items;

\echo ''
\echo 'Test data and unit tests are now available for development and testing.'
\echo 'Use test_framework.run_all_tests() to re-run tests anytime.'