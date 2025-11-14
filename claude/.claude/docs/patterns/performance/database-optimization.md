# Database Performance Optimization

## Overview
Database performance issues are among the most common production bottlenecks. This guide covers strategies for SQL and NoSQL databases used in modern web applications.

## N+1 Query Prevention

### The Problem
```typescript
// BAD: N+1 query pattern (1 + N queries)
const users = await db.user.findMany(); // 1 query

for (const user of users) {
  user.posts = await db.post.findMany({
    where: { userId: user.id } // N queries (one per user)
  });
}
// Total: 1 + 100 users = 101 queries
```

### Solution: Eager Loading
```typescript
// GOOD: Single query with join (or 2 queries max)
const users = await db.user.findMany({
  include: {
    posts: true // Joined in single query
  }
});
// Total: 1-2 queries regardless of user count
```

### DataLoader Pattern (GraphQL/Node.js)
Batches and caches database calls within single request:

```typescript
import DataLoader from 'dataloader';

const postLoader = new DataLoader(async (userIds) => {
  const posts = await db.post.findMany({
    where: { userId: { in: userIds } }
  });

  // Group posts by userId
  const postsByUserId = new Map();
  for (const post of posts) {
    if (!postsByUserId.has(post.userId)) {
      postsByUserId.set(post.userId, []);
    }
    postsByUserId.get(post.userId).push(post);
  }

  // Return in same order as userIds
  return userIds.map(id => postsByUserId.get(id) || []);
});

// Usage: Automatically batches calls
const user1Posts = await postLoader.load(user1.id);
const user2Posts = await postLoader.load(user2.id);
// Results in single query: SELECT * FROM posts WHERE userId IN (1, 2)
```

## Indexing Strategies

### When to Create Indexes
**Always index:**
- Primary keys (automatic)
- Foreign keys (join columns)
- WHERE clause columns (frequent filters)
- ORDER BY columns (sorting)

**Consider indexing:**
- Columns in GROUP BY
- Columns in DISTINCT queries
- Columns used in search (LIKE patterns)

### Single-Column Indexes
```sql
-- Index for filtering
CREATE INDEX idx_users_email ON users(email);

-- Query uses index
SELECT * FROM users WHERE email = 'user@example.com';
```

### Composite Indexes
Order matters! Most selective column first:

```sql
-- Index for multi-column filters
CREATE INDEX idx_orders_user_status ON orders(user_id, status);

-- Uses index (left-to-right prefix)
SELECT * FROM orders WHERE user_id = 123 AND status = 'pending';
SELECT * FROM orders WHERE user_id = 123; -- Also uses index

-- Does NOT use index (missing left prefix)
SELECT * FROM orders WHERE status = 'pending';
```

**Rule**: Composite index `(A, B, C)` can serve queries filtering on:
- `A`
- `A, B`
- `A, B, C`

But NOT:
- `B`
- `C`
- `B, C`

### Covering Indexes
Include all columns needed by query (avoid table lookup):

```sql
-- Index includes columns needed by SELECT
CREATE INDEX idx_users_email_name ON users(email, name);

-- Query satisfied entirely by index (no table access)
SELECT name FROM users WHERE email = 'user@example.com';
```

### Partial Indexes
Index only relevant subset:

```sql
-- Index only active users
CREATE INDEX idx_active_users_email ON users(email)
WHERE status = 'active';

-- Query uses partial index (smaller, faster)
SELECT * FROM users WHERE email = 'user@example.com' AND status = 'active';
```

### Index Monitoring
```sql
-- PostgreSQL: Find unused indexes
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY pg_relation_size(indexrelid) DESC;

-- MySQL: Check index usage
SHOW INDEX FROM users;
```

## Query Optimization

### Explain Plans
Understand query execution:

```sql
-- PostgreSQL
EXPLAIN ANALYZE
SELECT * FROM users
WHERE email = 'user@example.com';

-- Look for:
-- - Seq Scan (bad, missing index)
-- - Index Scan (good)
-- - Bitmap Heap Scan (acceptable for low selectivity)
```

**Key metrics:**
- **Seq Scan**: Full table scan (slow for large tables)
- **Index Scan**: Uses index (fast)
- **Cost**: Estimated query cost (lower is better)
- **Rows**: Estimated vs actual rows (large diff = outdated stats)

### SELECT Only Needed Columns
```typescript
// BAD: Fetches all columns (including large JSON/text)
const users = await db.user.findMany();

// GOOD: Fetches only needed columns
const users = await db.user.findMany({
  select: { id: true, email: true, name: true }
});
```

### Avoid Functions in WHERE Clause
```sql
-- BAD: Cannot use index (function applied to indexed column)
SELECT * FROM users WHERE LOWER(email) = 'user@example.com';

-- GOOD: Store normalized data, use index
SELECT * FROM users WHERE email = 'user@example.com';
-- Alternative: Use functional index
CREATE INDEX idx_users_email_lower ON users(LOWER(email));
```

### Limit Early
```sql
-- BAD: Sorts all rows then limits
SELECT * FROM orders ORDER BY created_at DESC LIMIT 10;

-- GOOD: Use index on created_at (if exists)
CREATE INDEX idx_orders_created ON orders(created_at DESC);
SELECT * FROM orders ORDER BY created_at DESC LIMIT 10;
```

## Connection Pooling

### The Problem
Creating database connections is expensive (100-300ms):

```typescript
// BAD: New connection every request
app.get('/users', async (req, res) => {
  const client = await createConnection(); // Slow!
  const users = await client.query('SELECT * FROM users');
  await client.close();
  res.json(users);
});
```

### Solution: Connection Pool
```typescript
import { Pool } from 'pg';

// Create pool once at startup
const pool = new Pool({
  host: 'localhost',
  database: 'myapp',
  max: 20, // Max connections
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Reuse connections from pool
app.get('/users', async (req, res) => {
  const client = await pool.connect(); // Fast (reuses existing)
  try {
    const result = await client.query('SELECT * FROM users');
    res.json(result.rows);
  } finally {
    client.release(); // Return to pool
  }
});
```

**Pool sizing guidelines:**
- **Web applications**: `connections = ((core_count * 2) + effective_spindle_count)`
- **Typical**: 10-20 connections per app instance
- **Lambda/serverless**: Use connection pooler (RDS Proxy, PgBouncer)

### Prisma Connection Pooling
```typescript
// prisma/schema.prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
  // Connection pool configuration
  // Format: postgresql://user:pass@host:5432/db?connection_limit=10
}

// Recommended: Use Prisma Accelerate for serverless
import { PrismaClient } from '@prisma/client/edge';
import { withAccelerate } from '@prisma/extension-accelerate';

const prisma = new PrismaClient().$extends(withAccelerate());
```

## Caching Strategies

### Application-Level Cache (Redis)
```typescript
import { Redis } from 'ioredis';

const redis = new Redis();

async function getUser(userId: string) {
  // Try cache first
  const cached = await redis.get(`user:${userId}`);
  if (cached) {
    return JSON.parse(cached);
  }

  // Cache miss: query database
  const user = await db.user.findUnique({ where: { id: userId } });

  // Store in cache (TTL: 5 minutes)
  await redis.setex(`user:${userId}`, 300, JSON.stringify(user));

  return user;
}

// Invalidate cache on update
async function updateUser(userId: string, data: UpdateUserInput) {
  const user = await db.user.update({
    where: { id: userId },
    data,
  });

  // Invalidate cache
  await redis.del(`user:${userId}`);

  return user;
}
```

**When to cache:**
- Expensive queries (joins, aggregations)
- Frequently accessed data (user profiles, config)
- Relatively static data (categories, tags)

**When NOT to cache:**
- Rapidly changing data (real-time feeds)
- User-specific data with low reuse
- Data where stale reads cause issues

### Query Result Cache
```typescript
// In-memory cache with TTL
const cache = new Map<string, { value: unknown; expiresAt: number }>();

function cached<T>(
  key: string,
  fn: () => Promise<T>,
  ttlSeconds: number
): Promise<T> {
  const now = Date.now();
  const entry = cache.get(key);

  if (entry && entry.expiresAt > now) {
    return Promise.resolve(entry.value as T);
  }

  return fn().then(value => {
    cache.set(key, {
      value,
      expiresAt: now + ttlSeconds * 1000,
    });
    return value;
  });
}

// Usage
const users = await cached(
  'all-users',
  () => db.user.findMany(),
  60 // Cache for 60 seconds
);
```

### HTTP Cache Headers
```typescript
app.get('/api/users/:id', async (req, res) => {
  const user = await getUser(req.params.id);

  // Cache in browser/CDN for 5 minutes
  res.setHeader('Cache-Control', 'public, max-age=300');
  res.json(user);
});
```

## Batch Operations

### Bulk Inserts
```typescript
// BAD: Individual inserts (N queries)
for (const user of users) {
  await db.user.create({ data: user });
}

// GOOD: Bulk insert (1 query)
await db.user.createMany({
  data: users,
  skipDuplicates: true,
});
```

### Bulk Updates
```sql
-- PostgreSQL: Update from values
UPDATE users AS u SET
  status = v.status,
  updated_at = v.updated_at
FROM (VALUES
  (1, 'active', NOW()),
  (2, 'inactive', NOW()),
  (3, 'pending', NOW())
) AS v(id, status, updated_at)
WHERE u.id = v.id;
```

### Transactions for Consistency
```typescript
// Atomic multi-table update
await db.$transaction(async (tx) => {
  // Deduct from sender
  await tx.account.update({
    where: { id: senderId },
    data: { balance: { decrement: amount } },
  });

  // Add to recipient
  await tx.account.update({
    where: { id: recipientId },
    data: { balance: { increment: amount } },
  });

  // Record transaction
  await tx.transaction.create({
    data: { from: senderId, to: recipientId, amount },
  });
});
// All succeed or all fail (no partial updates)
```

## NoSQL Optimization (DynamoDB)

### Single-Table Design
Store multiple entity types in one table:

```typescript
// Table: app-data
// PK: USER#123, SK: PROFILE
// PK: USER#123, SK: ORDER#456
// PK: USER#123, SK: ORDER#789

// Fetch user and all orders in single query
const result = await dynamodb.query({
  TableName: 'app-data',
  KeyConditionExpression: 'PK = :pk',
  ExpressionAttributeValues: { ':pk': 'USER#123' },
});
```

### GSI for Alternative Access Patterns
```typescript
// GSI: email-index (PK: email, SK: timestamp)
// Query by email without knowing userId
const user = await dynamodb.query({
  TableName: 'app-data',
  IndexName: 'email-index',
  KeyConditionExpression: 'email = :email',
  ExpressionAttributeValues: { ':email': 'user@example.com' },
});
```

### Batch Operations
```typescript
// Batch get (up to 100 items)
const result = await dynamodb.batchGet({
  RequestItems: {
    'app-data': {
      Keys: [
        { PK: 'USER#123', SK: 'PROFILE' },
        { PK: 'USER#456', SK: 'PROFILE' },
      ],
    },
  },
});

// Batch write (up to 25 items)
await dynamodb.batchWrite({
  RequestItems: {
    'app-data': [
      { PutRequest: { Item: { PK: 'USER#123', SK: 'ORDER#789', ... } } },
      { DeleteRequest: { Key: { PK: 'USER#456', SK: 'ORDER#012' } } },
    ],
  },
});
```

## Monitoring and Alerts

### Key Metrics
- **Query duration**: p50, p95, p99 latency
- **Slow query log**: Queries >1s
- **Connection pool usage**: Active vs idle connections
- **Cache hit rate**: >80% for cached queries
- **Index usage**: Unused indexes, missing indexes

### PostgreSQL Monitoring
```sql
-- Long-running queries
SELECT pid, now() - query_start AS duration, query
FROM pg_stat_activity
WHERE state = 'active'
  AND now() - query_start > interval '5 seconds'
ORDER BY duration DESC;

-- Table bloat (needs VACUUM)
SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename))
FROM pg_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### Application-Level Monitoring
```typescript
// Log slow queries
const start = Date.now();
const result = await db.query('SELECT ...');
const duration = Date.now() - start;

if (duration > 1000) {
  logger.warn('Slow query detected', { query, duration });
}
```

## Common Pitfalls

### Over-Indexing
- Each index adds overhead to writes
- Maintain only indexes that improve query performance
- Monitor index usage and drop unused indexes

### SELECT *
- Fetches unnecessary columns (wastes bandwidth)
- Prevents covering indexes
- Makes schema changes more brittle

### Missing Connection Limits
- Serverless functions can overwhelm database
- Always use connection pooling (RDS Proxy, PgBouncer)

### No Query Timeout
```typescript
// Set statement timeout to prevent runaway queries
await client.query('SET statement_timeout = 5000'); // 5 seconds
```

## Performance Budget
- Query duration: <100ms p95, <500ms p99
- N+1 queries: Zero tolerance
- Connection pool: <80% utilization
- Cache hit rate: >80% for cacheable queries
- Index scans: >95% of queries use indexes

## Related
- [React Optimization](./react-optimization.md)
- [Indexing Strategies](../../references/indexing-strategies.md)
- [Normalization](../../references/normalization.md)
- [Database Integration](../backend/database-integration.md)
