# Database Testing Documentation

This document describes the testing infrastructure for the Zava apparel design shop database.

## Overview

The testing infrastructure provides comprehensive test data and unit tests for validating the database schema, constraints, business logic, and data integrity.

## Files Structure

- `zava_postgres_schema.sql` - Main database schema
- `test_data.sql` - Comprehensive test data for all tables
- `unit_tests.sql` - Stored procedures for unit testing
- `run_tests.sql` - Test runner script
- `README_TESTING.md` - This documentation

## Test Categories

### 1. Constraints Testing
- **Supplier Constraints**: Validates supplier_type check constraints and required fields
- **Product Constraints**: Tests product_type constraints, SKU uniqueness
- **Purchase Order Logic**: Validates PO status constraints and number uniqueness
- **Order Item Constraints**: Tests quantity and calculation constraints

### 2. Business Logic Testing
- **Status Validation**: Ensures only valid status values are accepted
- **Quantity Rules**: Validates quantity_received ≤ quantity_ordered
- **Calculation Logic**: Tests computed columns (line_total, net_amount)

### 3. Foreign Key Relationships
- **Referential Integrity**: Tests all foreign key constraints
- **Cascade Operations**: Validates cascade delete behavior
- **Orphan Detection**: Checks for orphaned records

### 4. Data Integrity
- **Existing Data Validation**: Tests integrity of loaded test data
- **Calculation Accuracy**: Verifies all computed values are correct
- **Constraint Compliance**: Ensures all data meets business rules

## Test Data Coverage

The test data includes:

### Suppliers (8 records)
- All supplier types: fabric, trims, hardware, manufacturing, packaging
- Active and inactive suppliers
- Domestic and international suppliers
- Various payment terms and contact information

### Products (8 records)
- All product types: finished_good, raw_material, component, accessory
- Active and inactive products
- Various units of measure and cost structures
- Different stock levels (including out-of-stock scenarios)

### Purchase Orders (7 records)
- All status types: draft, sent, confirmed, partial_received, received, closed, cancelled
- Domestic and international orders
- Various currencies and exchange rates
- Different shipping and payment terms

### Order Items (6 records)
- Various quantity scenarios (full received, partial, pending)
- Different quality statuses
- Discount applications
- Edge cases and business scenarios

## Running Tests

### Prerequisites
1. PostgreSQL database with schema created:
   ```sql
   \i zava_postgres_schema.sql
   ```

### Option 1: Complete Test Suite
Run the full test suite including data loading:
```bash
psql -d your_database -f run_tests.sql
```

### Option 2: Individual Components
Load components separately:
```sql
-- Load test data only
\i test_data.sql

-- Load test procedures only
\i unit_tests.sql

-- Run tests on existing data
SELECT * FROM test_framework.run_all_tests();
```

### Option 3: Specific Test Categories
Run individual test procedures:
```sql
-- Test only constraints
SELECT test_framework.test_supplier_constraints();
SELECT test_framework.test_product_constraints();

-- Test only business logic
SELECT test_framework.test_purchase_order_logic();
SELECT test_framework.test_order_item_calculations();

-- Test only relationships
SELECT test_framework.test_foreign_key_relationships();

-- Test data integrity
SELECT test_framework.test_data_integrity();
```

## Test Results

### Understanding Results
- **PASS**: Test completed successfully
- **FAIL**: Test detected an issue (expected for negative tests)
- **ERROR**: Unexpected error occurred during test execution

### Test Summary
Get a summary of all test results:
```sql
SELECT * FROM test_framework.get_test_summary();
```

### Detailed Results
View detailed test results:
```sql
SELECT * FROM test_framework.test_results ORDER BY test_id;
```

## Test Framework Schema

The testing infrastructure uses a separate `test_framework` schema containing:

- `test_results` table: Stores all test execution results
- `log_test_result()` function: Helper for logging test outcomes
- `run_all_tests()` function: Executes complete test suite
- `get_test_summary()` function: Provides test summary statistics

## Customizing Tests

### Adding New Tests
1. Create a new test function in `unit_tests.sql`:
   ```sql
   CREATE OR REPLACE FUNCTION test_framework.test_my_feature() RETURNS VOID AS $$
   DECLARE
       start_time TIMESTAMP := CURRENT_TIMESTAMP;
       -- test variables
   BEGIN
       -- Your test logic here
       
       PERFORM test_framework.log_test_result(
           'My Feature Test', 
           'Custom', 
           'PASS', 
           'Test description', 
           start_time
       );
   END;
   $$ LANGUAGE plpgsql;
   ```

2. Add the function call to `run_all_tests()`:
   ```sql
   PERFORM test_framework.test_my_feature();
   ```

### Modifying Test Data
Edit `test_data.sql` to add or modify test scenarios. Remember to:
- Maintain referential integrity
- Cover edge cases
- Include both valid and boundary conditions

## Best Practices

### Test Development
1. **Isolation**: Each test should be independent
2. **Cleanup**: Tests should clean up their own data
3. **Coverage**: Test both positive and negative scenarios
4. **Documentation**: Include clear test descriptions

### Data Management
1. **Consistency**: Keep test data realistic but predictable
2. **Completeness**: Cover all business scenarios
3. **Maintenance**: Update test data when schema changes

### Performance
1. **Efficiency**: Tests should run quickly
2. **Resource Usage**: Minimize temporary data creation
3. **Cleanup**: Remove test data that's no longer needed

## Troubleshooting

### Common Issues

1. **Schema Not Found**: Ensure `zava_postgres_schema.sql` was run first
2. **Permission Errors**: Check database user has necessary privileges
3. **Foreign Key Violations**: Verify test data maintains referential integrity
4. **Test Failures**: Review error messages and check data consistency

### Debugging Tests
1. Run individual test procedures to isolate issues
2. Check `test_framework.test_results` for detailed error messages
3. Verify test data integrity before running tests
4. Use PostgreSQL logs for additional debugging information

## Integration with Development Workflow

### Continuous Testing
- Run tests after any schema changes
- Validate test data after modifications
- Include testing in deployment procedures

### Development Practices
- Use test data for development and debugging
- Create additional test scenarios for new features
- Maintain test documentation with code changes

## Support

For questions or issues with the testing infrastructure:
1. Review this documentation
2. Check PostgreSQL logs for error details
3. Examine test_results table for failure information
4. Verify database permissions and schema integrity