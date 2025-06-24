# zava

A PostgreSQL database schema for an apparel design shop, including comprehensive test data and unit testing infrastructure.

## Database Schema

The database includes tables for:
- **Suppliers**: Fabric, trims, hardware, manufacturing, and packaging suppliers
- **Products**: Raw materials, components, finished goods, and accessories
- **Purchase Orders**: Complete order management with status tracking
- **Order Items**: Detailed line items with quantity and quality tracking

## Testing Infrastructure

This repository includes a complete testing framework:

### Files
- `zava_postgres_schema.sql` - Main database schema
- `test_data.sql` - Comprehensive test data for all tables
- `unit_tests.sql` - Stored procedures for unit testing
- `run_tests.sql` - Test runner script
- `README_TESTING.md` - Detailed testing documentation

### Quick Start
1. Create the database schema:
   ```bash
   psql -d your_database -f zava_postgres_schema.sql
   ```

2. Run the complete test suite:
   ```bash
   psql -d your_database -f run_tests.sql
   ```

### Test Coverage
- **Data Integrity**: Validates all constraints and business rules
- **Constraint Enforcement**: Tests invalid data rejection
- **Business Logic**: Verifies calculations and quantity rules
- **11 unit tests** with **100% pass rate**

See `README_TESTING.md` for detailed testing documentation.