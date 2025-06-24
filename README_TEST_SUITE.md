# Zava Database Test Suite

This repository contains test data and unit tests for the Zava database schema, which is designed for an apparel design shop managing suppliers, products, purchase orders, and order items.

## Files Overview

- `zava_postgres_schema.sql` - Main database schema with table definitions
- `zava_test_data.sql` - Comprehensive test data for all tables
- `zava_unit_tests.sql` - Unit tests for validating database constraints and business logic

## Setup Instructions

### 1. Create Database
```sql
CREATE DATABASE zava_complete;
```

### 2. Install Schema
```bash
psql -d zava_complete -f zava_postgres_schema.sql
```

### 3. Load Test Data
```bash
psql -d zava_complete -f zava_test_data.sql
```

### 4. Install Unit Tests
```bash
psql -d zava_complete -f zava_unit_tests.sql
```

## Test Data Overview

The test data includes:

### Suppliers (8 records)
- **Fabric suppliers**: Premium Fabrics Inc, Eco Cotton Supply, Luxury Silk Co
- **Trims suppliers**: Button & Trim Masters, Zipper Solutions Ltd
- **Hardware suppliers**: Metal Hardware Co
- **Manufacturing suppliers**: Ace Manufacturing
- **Packaging suppliers**: Green Package Solutions

### Products (10 records)
- **Raw materials**: Organic cotton twill, mulberry silk, premium denim
- **Components**: Corozo buttons, metal zippers, woven labels, copper rivets
- **Finished goods**: Classic straight jeans, organic cotton t-shirt
- **Accessories**: Eco-friendly garment bags

### Purchase Orders (7 records)
- Orders in various statuses: draft, sent, confirmed, partial_received, received, closed, cancelled
- Different suppliers and order values
- Complete workflow examples

### Order Items (8 records)
- Line items with various quantities, costs, and quality statuses
- Examples of calculated fields (line_total, net_amount)
- Partial receiving scenarios

## Running Unit Tests

### Run All Tests
```sql
SELECT * FROM run_all_unit_tests();
```

### View Test Summary
```sql
SELECT * FROM display_test_summary();
```

### View Detailed Results
```sql
SELECT * FROM test_results ORDER BY test_id;
```

## Unit Test Coverage

The unit tests validate:

### 1. Table Constraints
- **Suppliers**: Valid supplier types, default values, not null constraints
- **Products**: Unique SKU, valid product types, default values
- **Purchase Orders**: Unique PO numbers, valid status values, default values
- **Order Items**: Positive quantities, cost constraints, quality status validation

### 2. Data Integrity
- Foreign key relationships between all tables
- Referential integrity validation
- Orphaned record detection

### 3. Calculated Fields
- **line_total**: quantity_ordered × unit_cost
- **net_amount**: line_total - discount_amount

### 4. Business Logic
- Quantity constraints (received ≤ ordered)
- Discount validation (amount ≤ line total, percent 0-100%)
- Cascade delete functionality

### 5. Error Handling
- Invalid enum values rejection
- Constraint violation detection
- Null constraint enforcement

## Test Results

Current test suite includes **21 unit tests** covering:
- Constraint validation (8 tests)
- Data type validation (4 tests) 
- Foreign key relationships (4 tests)
- Calculated field accuracy (2 tests)
- Business rule enforcement (3 tests)

All tests are designed to pass with the provided test data, achieving 100% pass rate.

## Database Schema Features Tested

### Constraints
- Primary keys and foreign keys
- Check constraints for enum values
- Not null constraints
- Unique constraints

### Generated Columns
- Automatic calculation of line totals
- Net amount computation with discounts

### Data Types
- Serial primary keys with auto-increment
- Decimal precision for monetary values
- Timestamp tracking with defaults
- Text fields for variable-length content

### Business Rules
- Supplier type categorization
- Product type classification
- Order status workflow
- Quality control tracking

## Usage Examples

### Query Test Data
```sql
-- View all suppliers by type
SELECT supplier_type, COUNT(*) 
FROM suppliers 
GROUP BY supplier_type 
ORDER BY supplier_type;

-- View order status distribution
SELECT status, COUNT(*) 
FROM purchase_orders 
GROUP BY status 
ORDER BY status;

-- View calculated totals
SELECT oi.*, po.po_number, s.company_name
FROM order_items oi
JOIN purchase_orders po ON oi.purchase_order_id = po.purchase_order_id
JOIN suppliers s ON po.supplier_id = s.supplier_id
ORDER BY oi.line_total DESC;
```

### Run Specific Tests
```sql
-- Test only supplier constraints
SELECT test_suppliers_constraints();
SELECT * FROM test_results WHERE test_name LIKE 'test_suppliers%';

-- Test only data integrity
SELECT test_data_integrity();
SELECT * FROM test_results WHERE test_name LIKE 'test_integrity%';
```

## Maintenance

### Clear Test Data
```sql
DELETE FROM order_items;
DELETE FROM purchase_orders;
DELETE FROM products;
DELETE FROM suppliers;
```

### Reset Sequences
```sql
ALTER SEQUENCE suppliers_supplier_id_seq RESTART WITH 1;
ALTER SEQUENCE products_product_id_seq RESTART WITH 1;
ALTER SEQUENCE purchase_orders_purchase_order_id_seq RESTART WITH 1;
ALTER SEQUENCE order_items_order_item_id_seq RESTART WITH 1;
```

### Clean Test Results
```sql
DELETE FROM test_results;
```

This test suite provides comprehensive validation of the Zava database schema and serves as both quality assurance and documentation of expected behavior.