# Database Indexing Strategies

## Overview
Indexes dramatically improve query performance but add overhead to writes. This guide provides practical strategies for creating, maintaining, and optimizing database indexes.

## When to Create Indexes

### Always Index
**Primary keys** (automatic in most databases):
```sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY,  -- Automatically indexed
  email VARCHAR(255),
  name VARCHAR(100)
);
```

**Foreign keys** (not automatic in all databases):
```sql
CREATE TABLE posts (
  id SERIAL PRIMARY KEY,
  author_id INTEGER REFERENCES users(id),
  title VARCHAR(255)
);

-- Create index on foreign key
CREATE INDEX idx_posts_author_id ON posts(author_id);

-- Without index: Full table scan to find user's posts
-- With index: Instant lookup
SELECT * FROM posts WHERE author_id = 123;
```

**Columns in WHERE clauses** (frequent filters):
```sql
-- Frequently query by email
SELECT * FROM users WHERE email = 'user@example.com';

-- Index the email column
CREATE INDEX idx_users_email ON users(email);
```

**Columns in ORDER BY** (sorting):
```sql
-- Frequently query with ordering
SELECT * FROM posts ORDER BY created_at DESC LIMIT 10;

-- Index for efficient sorting
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);
```

### Consider Indexing
**Columns in JOIN conditions**:
```sql
-- Query joins orders and users
SELECT * FROM orders o
JOIN users u ON o.user_id = u.id
WHERE u.email = 'user@example.com';

-- Index join columns
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_users_email ON users(email);
```

**Columns in GROUP BY**:
```sql
-- Aggregation query
SELECT status, COUNT(*) FROM orders GROUP BY status;

-- Index helps grouping
CREATE INDEX idx_orders_status ON orders(status);
```

**LIKE patterns (prefix searches)**:
```sql
-- Prefix search
SELECT * FROM users WHERE name LIKE 'John%';

-- B-tree index works for prefix searches
CREATE INDEX idx_users_name ON users(name);

-- ❌ Suffix search cannot use B-tree index
SELECT * FROM users WHERE name LIKE '%Doe';  -- Full scan

-- ✓ Full-text search index for pattern matching
CREATE INDEX idx_users_name_fulltext ON users USING GIN (to_tsvector('english', name));
```

## Index Types

### B-Tree Index (Default)
Most common index type, supports equality and range queries.

```sql
CREATE INDEX idx_users_email ON users(email);

-- Efficient queries
SELECT * FROM users WHERE email = 'user@example.com';  -- Equality
SELECT * FROM users WHERE created_at > '2024-01-01';   -- Range
SELECT * FROM users WHERE age BETWEEN 18 AND 65;       -- Range
SELECT * FROM users ORDER BY email;                    -- Ordering
```

### Unique Index
Enforces uniqueness, automatically created for UNIQUE constraints.

```sql
-- Unique constraint (creates unique index)
ALTER TABLE users ADD CONSTRAINT users_email_unique UNIQUE (email);

-- Explicit unique index
CREATE UNIQUE INDEX idx_users_email ON users(email);

-- Prevents duplicates
INSERT INTO users (email) VALUES ('user@example.com');  -- OK
INSERT INTO users (email) VALUES ('user@example.com');  -- Error: duplicate key
```

### Partial Index
Index only subset of rows (PostgreSQL, SQLite).

```sql
-- Index only active users
CREATE INDEX idx_active_users_email ON users(email)
WHERE status = 'active';

-- Uses partial index (fast)
SELECT * FROM users WHERE email = 'user@example.com' AND status = 'active';

-- Does NOT use partial index (full scan)
SELECT * FROM users WHERE email = 'user@example.com' AND status = 'inactive';
```

**Benefits**:
- Smaller index size
- Faster index scans
- Reduced write overhead

**Use cases**:
- Filtering soft-deleted records (`WHERE deleted_at IS NULL`)
- Active/inactive status (`WHERE status = 'active'`)
- Recent data (`WHERE created_at > '2024-01-01'`)

### Full-Text Search Index
For text search queries (PostgreSQL GIN/GiST, MySQL FULLTEXT).

**PostgreSQL**:
```sql
-- Create GIN index for full-text search
CREATE INDEX idx_posts_content_fulltext ON posts
USING GIN (to_tsvector('english', content));

-- Full-text search query
SELECT * FROM posts
WHERE to_tsvector('english', content) @@ to_tsquery('english', 'database & optimization');
```

**MySQL**:
```sql
-- Create FULLTEXT index
CREATE FULLTEXT INDEX idx_posts_content ON posts(content);

-- Full-text search query
SELECT * FROM posts
WHERE MATCH(content) AGAINST('database optimization' IN NATURAL LANGUAGE MODE);
```

### Hash Index
Equality-only lookups (PostgreSQL, MySQL).

```sql
-- PostgreSQL hash index
CREATE INDEX idx_users_email_hash ON users USING HASH (email);

-- Efficient for equality only
SELECT * FROM users WHERE email = 'user@example.com';  -- Uses hash index

-- Cannot use hash index (no range support)
SELECT * FROM users WHERE email > 'a@example.com';  -- Full scan
```

**Use cases**:
- Columns with high cardinality
- Only equality queries (no ranges)
- Space-constrained environments (hash smaller than B-tree)

## Composite Indexes

### Column Order Matters
Left-to-right prefix rule: Index `(A, B, C)` can serve queries on:
- `A`
- `A, B`
- `A, B, C`

But NOT:
- `B`
- `C`
- `B, C`

**Example**:
```sql
-- Create composite index
CREATE INDEX idx_orders_user_status ON orders(user_id, status, created_at);

-- Uses index (left prefix)
SELECT * FROM orders WHERE user_id = 123;
SELECT * FROM orders WHERE user_id = 123 AND status = 'pending';
SELECT * FROM orders WHERE user_id = 123 AND status = 'pending' AND created_at > '2024-01-01';

-- Does NOT use index (missing left prefix)
SELECT * FROM orders WHERE status = 'pending';
SELECT * FROM orders WHERE created_at > '2024-01-01';
```

### Ordering Composite Indexes

**Rule**: Most selective column first (highest cardinality).

```sql
-- BAD: status has low cardinality (few distinct values)
CREATE INDEX idx_orders_status_user ON orders(status, user_id);

-- GOOD: user_id has high cardinality (many distinct values)
CREATE INDEX idx_orders_user_status ON orders(user_id, status);
```

**Cardinality examples**:
- **Low cardinality**: status (3 values: pending, completed, cancelled)
- **Medium cardinality**: country (200 values)
- **High cardinality**: user_id (millions of values), email (unique)

### Covering Indexes
Include all columns needed by query (avoid table lookup).

```sql
-- Query needs id, name, email
SELECT id, name, email FROM users WHERE status = 'active';

-- Covering index includes all columns
CREATE INDEX idx_users_status_covering ON users(status, id, name, email);

-- PostgreSQL explicit INCLUDE
CREATE INDEX idx_users_status_covering ON users(status) INCLUDE (id, name, email);

-- Query satisfied entirely by index (no table access)
```

**Benefits**:
- Faster queries (no table lookup)
- Reduced I/O
- Index-only scans

**Trade-offs**:
- Larger index size
- Slower writes
- More storage

## Index Maintenance

### Monitoring Index Usage

**PostgreSQL**:
```sql
-- Find unused indexes
SELECT
  schemaname,
  tablename,
  indexname,
  idx_scan AS index_scans,
  pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE idx_scan = 0
  AND indexrelname NOT LIKE '%_pkey'  -- Exclude primary keys
ORDER BY pg_relation_size(indexrelid) DESC;

-- Find duplicate indexes
SELECT
  a.tablename,
  a.indexname AS index1,
  b.indexname AS index2,
  a.indexdef
FROM pg_indexes a
JOIN pg_indexes b ON a.tablename = b.tablename
  AND a.indexname < b.indexname
  AND a.indexdef = b.indexdef
WHERE a.schemaname = 'public';
```

**MySQL**:
```sql
-- Show index usage
SELECT
  table_name,
  index_name,
  cardinality
FROM information_schema.statistics
WHERE table_schema = 'mydb'
ORDER BY table_name, index_name;

-- Enable slow query log to identify missing indexes
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 1;  -- Log queries > 1 second
```

### Analyzing Query Plans

**PostgreSQL**:
```sql
EXPLAIN ANALYZE
SELECT * FROM orders WHERE user_id = 123 AND status = 'pending';

-- Look for:
-- - Seq Scan (bad: full table scan)
-- - Index Scan (good: using index)
-- - Bitmap Heap Scan (acceptable: combines multiple indexes)
-- - Actual time vs Estimated rows (large diff = outdated stats)
```

**MySQL**:
```sql
EXPLAIN
SELECT * FROM orders WHERE user_id = 123 AND status = 'pending';

-- Look for:
-- - type = ALL (bad: full table scan)
-- - type = index (good: index scan)
-- - type = ref (good: non-unique index lookup)
-- - type = eq_ref (best: unique index lookup)
-- - rows = high number (bad: scanning many rows)
```

### Updating Statistics
Database query planners rely on statistics to choose indexes.

**PostgreSQL**:
```sql
-- Analyze single table
ANALYZE users;

-- Analyze all tables
ANALYZE;

-- Auto-vacuum configuration (postgresql.conf)
-- autovacuum = on
-- autovacuum_vacuum_threshold = 50
-- autovacuum_analyze_threshold = 50
```

**MySQL**:
```sql
-- Analyze table
ANALYZE TABLE users;

-- Optimize table (rebuilds indexes)
OPTIMIZE TABLE users;
```

### Rebuilding Indexes
Indexes can become fragmented over time.

**PostgreSQL**:
```sql
-- Reindex single index
REINDEX INDEX idx_users_email;

-- Reindex table (all indexes)
REINDEX TABLE users;

-- Reindex concurrently (doesn't block writes)
REINDEX INDEX CONCURRENTLY idx_users_email;
```

**MySQL**:
```sql
-- Rebuild all indexes
OPTIMIZE TABLE users;

-- Rebuild specific index (drop and recreate)
ALTER TABLE users DROP INDEX idx_users_email;
CREATE INDEX idx_users_email ON users(email);
```

## Over-Indexing Pitfalls

### Write Performance Impact
Each index adds overhead to INSERT, UPDATE, DELETE.

```sql
-- Table with 5 indexes
CREATE TABLE users (
  id SERIAL PRIMARY KEY,             -- Index 1: Primary key
  email VARCHAR(255),
  name VARCHAR(100),
  status VARCHAR(20),
  created_at TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);           -- Index 2
CREATE INDEX idx_users_name ON users(name);             -- Index 3
CREATE INDEX idx_users_status ON users(status);         -- Index 4
CREATE INDEX idx_users_created_at ON users(created_at); -- Index 5

-- INSERT must update all 5 indexes (slow writes)
INSERT INTO users (email, name, status, created_at)
VALUES ('user@example.com', 'John Doe', 'active', NOW());
```

**Impact**:
- INSERT: Updates all indexes
- UPDATE: Updates affected indexes
- DELETE: Updates all indexes
- Storage: 5x table size in indexes

### Identifying Over-Indexing
**Signs**:
- Slow writes (INSERT/UPDATE/DELETE)
- High disk usage
- Many unused indexes
- Duplicate/redundant indexes

**Solution**:
```sql
-- Drop unused indexes
DROP INDEX idx_users_status;  -- Only 3% of queries use this

-- Replace redundant indexes with composite
DROP INDEX idx_orders_user_id;
DROP INDEX idx_orders_status;
CREATE INDEX idx_orders_user_status ON orders(user_id, status);
```

## Index Strategy Examples

### E-Commerce Orders Table
```sql
CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id),
  status VARCHAR(20) NOT NULL,  -- 'pending', 'completed', 'cancelled'
  total DECIMAL(10, 2) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Index strategy
CREATE INDEX idx_orders_user_id ON orders(user_id);  -- Foreign key, frequent JOIN
CREATE INDEX idx_orders_status ON orders(status);    -- Frequent filter
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);  -- Sorting, recent orders

-- Composite for common query pattern
CREATE INDEX idx_orders_user_status_created ON orders(user_id, status, created_at DESC);
-- Serves: WHERE user_id = ? AND status = ? ORDER BY created_at DESC

-- Partial index for active orders only
CREATE INDEX idx_orders_pending ON orders(user_id, created_at DESC)
WHERE status = 'pending';
```

### Social Media Posts Table
```sql
CREATE TABLE posts (
  id SERIAL PRIMARY KEY,
  author_id INTEGER NOT NULL REFERENCES users(id),
  content TEXT NOT NULL,
  visibility VARCHAR(20) NOT NULL,  -- 'public', 'private', 'followers'
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Index strategy
CREATE INDEX idx_posts_author_id ON posts(author_id);  -- User's posts
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);  -- Timeline

-- Composite for public posts feed
CREATE INDEX idx_posts_public_feed ON posts(visibility, created_at DESC)
WHERE visibility = 'public';

-- Full-text search
CREATE INDEX idx_posts_content_fulltext ON posts
USING GIN (to_tsvector('english', content));

-- Covering index for list queries
CREATE INDEX idx_posts_author_list ON posts(author_id, created_at DESC)
INCLUDE (id, content, visibility);
```

## Testing Index Performance

### Before/After Comparison
```sql
-- Disable seq_scan to force index usage (PostgreSQL)
SET enable_seqscan = OFF;

-- Measure query time without index
EXPLAIN ANALYZE
SELECT * FROM orders WHERE status = 'pending';
-- Planning time: 0.5ms
-- Execution time: 1500ms (Seq Scan)

-- Create index
CREATE INDEX idx_orders_status ON orders(status);

-- Measure query time with index
EXPLAIN ANALYZE
SELECT * FROM orders WHERE status = 'pending';
-- Planning time: 0.5ms
-- Execution time: 2ms (Index Scan)

-- Re-enable seq_scan
SET enable_seqscan = ON;
```

### Load Testing Write Performance
```typescript
// Test write performance with/without indexes
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function benchmarkInserts() {
  const start = Date.now();

  for (let i = 0; i < 10000; i++) {
    await prisma.user.create({
      data: {
        email: `user${i}@example.com`,
        name: `User ${i}`,
        status: 'active',
      },
    });
  }

  const duration = Date.now() - start;
  console.log(`10,000 inserts: ${duration}ms (${10000 / duration * 1000} inserts/sec)`);
}

benchmarkInserts();
// Without indexes: 5000ms (2000 inserts/sec)
// With 5 indexes: 12000ms (833 inserts/sec)
```

## Best Practices Summary

**DO**:
- Index foreign keys
- Index columns in WHERE, ORDER BY, JOIN
- Use composite indexes for multi-column queries
- Use partial indexes for filtered queries
- Monitor index usage and drop unused indexes
- Update statistics regularly
- Test query performance with EXPLAIN ANALYZE

**DON'T**:
- Create indexes on every column
- Create redundant indexes
- Index low-cardinality columns alone (status, boolean)
- Create indexes before measuring performance
- Forget to maintain indexes (REINDEX, ANALYZE)
- Use indexes on small tables (<1000 rows)

## Related
- [Database Optimization](../patterns/performance/database-optimization.md)
- [Normalization](./normalization.md)
- [Query Patterns](../patterns/backend/database-integration.md)
