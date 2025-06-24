# Zava - Apparel Design Shop Database

A PostgreSQL database schema for managing suppliers, products, purchase orders, and inventory for an apparel design shop.

## Files

- `zava_postgres_schema.sql` - Main database schema
- `zava_test_data.sql` - Comprehensive test data
- `zava_unit_tests.sql` - Unit tests for schema validation
- `README_TEST_SUITE.md` - Detailed documentation for test suite

## Quick Start

1. Create database: `CREATE DATABASE zava_complete;`
2. Install schema: `psql -d zava_complete -f zava_postgres_schema.sql`
3. Load test data: `psql -d zava_complete -f zava_test_data.sql`
4. Install unit tests: `psql -d zava_complete -f zava_unit_tests.sql`
5. Run tests: `SELECT * FROM run_all_unit_tests();`

See `README_TEST_SUITE.md` for complete documentation.