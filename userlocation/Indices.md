# PostgreSQL Index Types Guide

This guide explains different PostgreSQL index types, when to use them, and their performance characteristics based on the exercises above.

## 1. Hash Indexes

### What they are:
Hash indexes use a hash function to map values to bucket locations, providing O(1) average lookup time.

### When to use:
- **Equality comparisons only** (`=`, `IN`)
- High-cardinality columns with frequent exact matches
- When you never need range queries

### When NOT to use:
- Range queries (`<`, `>`, `BETWEEN`)
- Pattern matching (`LIKE`, `ILIKE`)
- Sorting operations
- Very low-cardinality data

### Example:
```sql
-- Good use case
CREATE INDEX orders_composition_hash_idx ON orders USING HASH (composition_id);
SELECT * FROM orders WHERE composition_id = 'buk1'; -- Uses index

-- Won't use hash index
SELECT * FROM orders WHERE composition_id < 'c'; -- Sequential scan
```

## 2. B-tree Indexes (Default)

### What they are:
Balanced tree structures that maintain sorted data, supporting both equality and range operations.

### When to use:
- **Most common choice** - PostgreSQL default
- Equality comparisons (`=`, `IN`)
- Range queries (`<`, `>`, `<=`, `>=`, `BETWEEN`)
- Sorting operations (`ORDER BY`)
- Pattern matching with anchored prefixes (`LIKE 'prefix%'`)

### When NOT to use:
- Full-text search requirements
- Geometric/spatial data
- Array containment operations

### Example:
```sql
CREATE INDEX orders_composition_btree_idx ON orders USING BTREE (composition_id);

-- All these can use the B-tree index:
SELECT * FROM orders WHERE composition_id = 'buk1';
SELECT * FROM orders WHERE composition_id < 'c';
SELECT * FROM orders WHERE composition_id >= 'c';
SELECT * FROM orders ORDER BY composition_id;
```

## 3. Pattern Matching Indexes

### What they are:
B-tree indexes with special operator classes optimized for pattern matching.

### When to use:
- Frequent `LIKE` queries with prefixes (`'prefix%'`)
- `ILIKE` operations
- Regular expression matching with `~` operator

### When NOT to use:
- Patterns without anchored prefixes (`'%middle%'`, `'%suffix'`)
- Full-text search (use GIN instead)

### Example:
```sql
-- Standard index won't help with LIKE
CREATE INDEX orders_remarks_idx ON orders (remarks);
SELECT * FROM orders WHERE remarks LIKE 'do%'; -- May not use index

-- Pattern-optimized index
CREATE INDEX orders_remarks_pattern_idx ON orders (remarks varchar_pattern_ops);
SELECT * FROM orders WHERE remarks LIKE 'do%'; -- Uses index
```

## 4. Multi-column (Composite) Indexes

### What they are:
Indexes on multiple columns, with column order affecting performance.

### When to use:
- Queries filtering on multiple columns with `AND`
- Column order matters: most selective column first
- Queries on leading columns only

### When NOT to use:
- `OR` conditions between indexed columns
- Queries only on non-leading columns
- Too many columns (diminishing returns)

### Example:
```sql
CREATE INDEX orders_multi_idx ON orders (client_id, recipient_id, composition_id);

-- Uses composite index efficiently
SELECT * FROM orders WHERE client_id = 'client1' AND recipient_id = 4 AND composition_id = 'buk1';

-- Uses index partially (client_id only)
SELECT * FROM orders WHERE client_id = 'client1';

-- Won't use composite index efficiently
SELECT * FROM orders WHERE composition_id = 'buk1'; -- Only last column
SELECT * FROM orders WHERE client_id = 'client1' OR recipient_id = 6; -- OR condition
```

## 5. Partial Indexes

### What they are:
Indexes with a `WHERE` clause, indexing only rows meeting specific conditions.

### When to use:
- Queries frequently filtering on specific conditions
- Sparse data (only small percentage meets condition)
- Reducing index size and maintenance overhead

### When NOT to use:
- Conditions change frequently
- Most rows meet the condition

### Example:
```sql
CREATE INDEX orders_paid_client_idx ON orders (client_id) WHERE paid;

-- Uses partial index
SELECT * FROM orders WHERE client_id = 'client1' AND paid; -- Uses index

-- Cannot use partial index
SELECT * FROM orders WHERE client_id = 'client1' AND NOT paid; -- Sequential scan
```

## 6. Expression Indexes

### What they are:
Indexes on computed expressions or function results rather than raw column values.

### When to use:
- Queries frequently using functions on columns
- Case-insensitive searches
- Complex calculations in WHERE clauses

### When NOT to use:
- Simple column comparisons
- Functions that aren't immutable

### Example:
```sql
CREATE INDEX clients_city_lower_idx ON clients (lower(city));

-- Uses expression index
SELECT * FROM clients WHERE lower(city) LIKE 'krak%'; -- Uses index

-- Won't use expression index
SELECT * FROM clients WHERE city = 'Krakow'; -- Different expression
```

## 7. GiST Indexes (Generalized Search Tree)

### What they are:
Extensible indexing framework supporting geometric data types, arrays, and full-text search.

### When to use:
- **Geometric/spatial data** (point, circle, polygon)
- Array operations (`@>`, `<@`)
- Full-text search (with `tsvector`)
- Range types
- Network address types (`inet`, `cidr`)

### When NOT to use:
- Simple equality or range queries on scalar types
- High-frequency updates (more maintenance overhead)

### Example:
```sql
CREATE INDEX orders_location_gist_idx ON orders USING GIST (location);

-- Uses GiST index for spatial operations
SELECT * FROM orders WHERE location <@ circle '((50,50),10)'; -- Uses index

-- Cannot use GiST index for array-style access
SELECT * FROM orders WHERE location[0] < 50 AND location[1] > 50; -- Sequential scan
```

## Index Selection Quick Reference

| Query Type | Best Index Type | Example |
|------------|----------------|---------|
| Equality only | Hash or B-tree | `WHERE id = 123` |
| Range queries | B-tree | `WHERE date > '2024-01-01'` |
| Sorting | B-tree | `ORDER BY name` |
| Pattern matching | B-tree with pattern ops | `WHERE name LIKE 'John%'` |
| Multiple AND conditions | Multi-column B-tree | `WHERE a = 1 AND b = 2` |
| Sparse conditions | Partial index | `WHERE active = true` (if few active) |
| Function calls | Expression index | `WHERE lower(name) = 'john'` |
| Spatial queries | GiST | `WHERE location <@ circle '((0,0),5)'` |
| Array operations | GiST or GIN | `WHERE tags @> ARRAY['tag1']` |

## Performance Tips

1. **Monitor index usage**: Use `pg_stat_user_indexes` to check if indexes are being used
2. **Column order in composite indexes matters**: Most selective column first
3. **Don't over-index**: Each index has maintenance overhead
4. **Use `EXPLAIN ANALYZE`** to verify index usage
5. **Consider partial indexes** for frequently filtered sparse data
6. **Update statistics** with `ANALYZE` after significant data changes