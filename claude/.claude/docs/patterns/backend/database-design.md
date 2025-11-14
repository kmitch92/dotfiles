# Database Schema Design Patterns

Comprehensive guide for designing scalable, maintainable database schemas for SQL (PostgreSQL/MySQL) and NoSQL (DynamoDB) databases.

## Core Database Design Principles

1. **Schema-First**: Design data model before application code
2. **Normalization**: Eliminate redundancy to appropriate normal form
3. **Denormalization**: Strategic, only when performance requires it
4. **Referential Integrity**: Use foreign keys and constraints
5. **Index Strategy**: Index for queries, not just primary keys
6. **Migration Safety**: Never destructive without backups

## Relational Database (PostgreSQL/MySQL) Design

### Table Design with Constraints

```sql
-- ✅ GOOD: Clear table design with appropriate constraints
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) NOT NULL UNIQUE,
  name VARCHAR(100) NOT NULL,
  role VARCHAR(20) NOT NULL CHECK (role IN ('user', 'admin', 'moderator')),
  status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'pending')),
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMP  -- Soft delete pattern
);

-- Indexes for common queries
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status ON users(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_created_at ON users(created_at DESC);

-- Trigger for automatic updated_at maintenance
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

### Primary Key Strategies

```sql
-- Option 1: UUID (recommended for distributed systems)
id UUID PRIMARY KEY DEFAULT gen_random_uuid()

-- Pros: Globally unique, merge-friendly, no central sequence
-- Cons: Larger size (16 bytes), non-sequential (index fragmentation)

-- Option 2: BIGINT with sequence
id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY

-- Pros: Smaller size (8 bytes), sequential (better for indexes)
-- Cons: Requires central sequence, not globally unique

-- Option 3: Composite primary key (junction tables)
PRIMARY KEY (user_id, role_id)

-- Pros: Natural key, enforces uniqueness on relationship
-- Cons: More complex queries, larger foreign keys
```

## Relationships

### One-to-Many

```sql
-- User has many Orders
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  total_amount DECIMAL(10,2) NOT NULL CHECK (total_amount >= 0),
  status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'completed', 'cancelled')),
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Indexes for foreign key and common queries
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);

-- Composite index for combined queries
CREATE INDEX idx_orders_user_status ON orders(user_id, status);
```

**ON DELETE options**:
- `CASCADE`: Delete orders when user deleted (appropriate for owned data)
- `SET NULL`: Set user_id to NULL when user deleted (preserve order history)
- `RESTRICT`: Prevent user deletion if orders exist (safest)

### Many-to-Many with Junction Table

```sql
-- Users and Roles (many-to-many)
CREATE TABLE roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(50) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE user_roles (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  granted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  granted_by UUID REFERENCES users(id),  -- Audit: who granted this role
  PRIMARY KEY (user_id, role_id)
);

-- Indexes for both directions of lookup
CREATE INDEX idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX idx_user_roles_role_id ON user_roles(role_id);
```

### One-to-One

```sql
-- User has one Profile
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  bio TEXT,
  avatar_url VARCHAR(500),
  website VARCHAR(255),
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- UNIQUE constraint on user_id enforces one-to-one
```

## Normalization

### Third Normal Form (3NF) - Target for Most Cases

```sql
-- ❌ BAD: Denormalized (redundant data)
CREATE TABLE orders_bad (
  id UUID PRIMARY KEY,
  user_email VARCHAR(255),    -- Duplicates user data
  user_name VARCHAR(100),      -- Duplicates user data
  user_address TEXT,           -- Duplicates user data
  total_amount DECIMAL(10,2)
);
-- Problem: User data duplicated in every order
-- Updating user email requires updating all orders

-- ✅ GOOD: Normalized (3NF)
CREATE TABLE users (
  id UUID PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(100) NOT NULL
);

CREATE TABLE addresses (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  street VARCHAR(255) NOT NULL,
  city VARCHAR(100) NOT NULL,
  postal_code VARCHAR(20) NOT NULL
);

CREATE TABLE orders (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  total_amount DECIMAL(10,2) NOT NULL
);
-- Benefit: User data stored once, no duplication
```

### Strategic Denormalization for Performance

```sql
-- ✅ Denormalization justified by query patterns
CREATE TABLE orders_with_user_email (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  user_email VARCHAR(255) NOT NULL,  -- Denormalized
  total_amount DECIMAL(10,2) NOT NULL
);

-- When to denormalize:
-- 1. Email lookups are frequent (common query pattern)
-- 2. User updates are rare (low update overhead)
-- 3. Query performance gain is significant (measured)
-- 4. Consistency mechanism exists (trigger or app logic)

-- Trigger to keep denormalized field in sync
CREATE TRIGGER update_order_user_email
  AFTER UPDATE OF email ON users
  FOR EACH ROW
  EXECUTE FUNCTION sync_order_user_email();
```

## Indexing Strategy

### Index Selection Based on Query Patterns

```sql
-- Query: Find active users by email
SELECT * FROM users WHERE email = ? AND status = 'active';

-- ✅ GOOD: Composite index with high-selectivity column first
CREATE INDEX idx_users_email_status ON users(email, status);

-- Query: List recent orders for a user
SELECT * FROM orders WHERE user_id = ? ORDER BY created_at DESC LIMIT 20;

-- ✅ GOOD: Composite index includes ORDER BY column
CREATE INDEX idx_orders_user_created ON orders(user_id, created_at DESC);

-- Query: Find active users (WHERE clause only)
SELECT * FROM users WHERE status = 'active';

-- ✅ GOOD: Partial index (smaller, faster)
CREATE INDEX idx_active_users ON users(id, email, name) WHERE status = 'active';
```

### Covering Indexes

```sql
-- Query: Select specific columns from active users
SELECT id, email, name FROM users WHERE status = 'active';

-- ✅ GOOD: Covering index includes all queried columns
CREATE INDEX idx_users_active_covering ON users(status, id, email, name);

-- Benefit: Index-only scan (doesn't need to read table)
```

### Index Anti-Patterns

```sql
-- ❌ BAD: Over-indexing (slows writes, wastes space)
CREATE INDEX idx_users_name ON users(name);  -- If never queried by name alone

-- ❌ BAD: Wrong column order (low selectivity first)
SELECT * FROM orders WHERE status = 'completed' AND user_id = ?;
CREATE INDEX idx_orders_wrong ON orders(status, user_id);

-- ✅ GOOD: High selectivity first
CREATE INDEX idx_orders_correct ON orders(user_id, status);

-- ❌ BAD: Redundant indexes
CREATE INDEX idx_user_id ON orders(user_id);
CREATE INDEX idx_user_status ON orders(user_id, status);  -- Makes first redundant

-- ✅ GOOD: Keep only composite index (covers both queries)
CREATE INDEX idx_user_status ON orders(user_id, status);
```

## Query Optimization

### N+1 Query Problem

```typescript
// ❌ BAD: N+1 query problem
const users = await db.users.findAll();
for (const user of users) {
  user.orders = await db.orders.findByUserId(user.id);  // N additional queries!
}
// Total queries: 1 + N (very slow for large N)

// ✅ GOOD: Single query with join
const users = await db.query(`
  SELECT
    u.id,
    u.email,
    u.name,
    json_agg(
      json_build_object(
        'id', o.id,
        'totalAmount', o.total_amount,
        'status', o.status
      )
    ) as orders
  FROM users u
  LEFT JOIN orders o ON o.user_id = u.id
  GROUP BY u.id, u.email, u.name
`);
// Total queries: 1 (fast regardless of N)
```

### SELECT Optimization

```sql
-- ❌ BAD: SELECT * (fetches unnecessary data)
SELECT * FROM orders WHERE user_id = ?;

-- ✅ GOOD: Select only needed columns
SELECT id, total_amount, status, created_at FROM orders WHERE user_id = ?;

-- Benefit: Less data transferred, potential for index-only scan
```

### OR vs UNION

```sql
-- ❌ BAD: OR with different columns (can't use indexes efficiently)
SELECT * FROM users WHERE email = ? OR name = ?;

-- ✅ GOOD: UNION for different indexes
SELECT * FROM users WHERE email = ?
UNION
SELECT * FROM users WHERE name = ?;

-- Benefit: Each query uses appropriate index
```

## Pagination Patterns

### Cursor-Based Pagination (Efficient)

```sql
-- OFFSET pagination (slow for large offsets)
SELECT * FROM orders ORDER BY created_at DESC LIMIT 20 OFFSET 10000;
-- Problem: Database scans and discards first 10000 rows

-- ✅ GOOD: Cursor-based (keyset pagination)
SELECT * FROM orders
WHERE created_at < ?  -- Cursor: last seen created_at
ORDER BY created_at DESC
LIMIT 20;
-- Benefit: Uses index efficiently, no large offset scan
```

### Pagination Implementation

```typescript
// First page (no cursor)
const firstPage = await db.query(`
  SELECT id, created_at, total_amount
  FROM orders
  ORDER BY created_at DESC
  LIMIT 21  -- Fetch limit + 1 to check if more exist
`);

const hasMore = firstPage.length > 20;
const items = firstPage.slice(0, 20);
const nextCursor = hasMore ? items[items.length - 1].created_at : null;

// Subsequent pages (with cursor)
const nextPage = await db.query(`
  SELECT id, created_at, total_amount
  FROM orders
  WHERE created_at < $1
  ORDER BY created_at DESC
  LIMIT 21
`, [cursor]);
```

## NoSQL Database (DynamoDB) Design

### Single Table Design Pattern

```typescript
// Single table containing multiple entity types
type TableItem =
  | UserItem
  | OrderItem
  | OrderLineItem;

// User entity
type UserItem = {
  PK: `USER#${string}`;      // USER#user_123
  SK: `PROFILE`;              // PROFILE (constant for user metadata)
  GSI1PK: `EMAIL#${string}`;  // EMAIL#user@example.com
  GSI1SK: `USER`;             // USER
  email: string;
  name: string;
  role: string;
  status: string;
  createdAt: string;
};

// Order entity
type OrderItem = {
  PK: `USER#${string}`;       // USER#user_123 (partition by user)
  SK: `ORDER#${string}`;      // ORDER#order_456
  GSI1PK: `ORDER#${string}`;  // ORDER#order_456 (lookup by order ID)
  GSI1SK: `USER#${string}`;   // USER#user_123
  totalAmount: number;
  status: string;
  createdAt: string;
};

// Order line item entity
type OrderLineItem = {
  PK: `ORDER#${string}`;      // ORDER#order_456
  SK: `ITEM#${string}`;       // ITEM#item_789
  productId: string;
  quantity: number;
  price: number;
};
```

### Access Patterns Drive Design

```typescript
// Design based on access patterns, not entity structure

// Access Pattern 1: Get user by ID
// Query: PK = USER#user_123, SK = PROFILE

// Access Pattern 2: Get user by email
// Query: GSI1 where GSI1PK = EMAIL#user@example.com

// Access Pattern 3: List user's orders
// Query: PK = USER#user_123, SK begins_with ORDER#

// Access Pattern 4: Get order by ID
// Query: GSI1 where GSI1PK = ORDER#order_456

// Access Pattern 5: List order items
// Query: PK = ORDER#order_456, SK begins_with ITEM#
```

### DynamoDB Patterns

#### Composite Sort Key for Hierarchical Data

```typescript
// Comments on posts with timestamp ordering
type CommentItem = {
  PK: `POST#${string}`;                      // POST#post_123
  SK: `COMMENT#${string}#${string}`;         // COMMENT#2025-01-15T10:30:00Z#comment_456
  commentId: string;
  userId: string;
  content: string;
  createdAt: string;
};

// Query all comments for post, ordered by time
// PK = POST#post_123, SK begins_with COMMENT#
// Results automatically sorted by timestamp in SK
```

#### Sparse Index for Specific Queries

```typescript
// Only premium users have GSI2 attributes
type UserWithPremiumItem = UserItem & {
  GSI2PK?: `PREMIUM`;        // Only set for premium users
  GSI2SK?: string;           // Subscription expiration date
};

// Query only premium users via GSI2
// GSI2PK = PREMIUM
// Much smaller index than full user table
```

## Migration Patterns

### Safe Migration Strategy

```sql
-- Multi-step migration for backward compatibility

-- Step 1: Add new column (optional, nullable)
ALTER TABLE users ADD COLUMN new_email VARCHAR(255);

-- Step 2: Backfill data (in batches to avoid locking)
DO $$
DECLARE
  batch_size INT := 1000;
  affected_rows INT;
BEGIN
  LOOP
    UPDATE users
    SET new_email = email
    WHERE new_email IS NULL
    LIMIT batch_size;

    GET DIAGNOSTICS affected_rows = ROW_COUNT;
    EXIT WHEN affected_rows = 0;

    COMMIT;  -- Release locks between batches
  END LOOP;
END $$;

-- Step 3: Make new column NOT NULL (after backfill complete)
ALTER TABLE users ALTER COLUMN new_email SET NOT NULL;

-- Step 4: Add unique constraint
ALTER TABLE users ADD CONSTRAINT users_new_email_unique UNIQUE (new_email);

-- Step 5: Create index
CREATE INDEX idx_users_new_email ON users(new_email);

-- Step 6: Drop old column (in next release, after app updated)
ALTER TABLE users DROP COLUMN email;
```

### Migration Anti-Patterns

```sql
-- ❌ BAD: Breaking migration (destroys data)
ALTER TABLE users DROP COLUMN email;  -- Data loss!

-- ❌ BAD: Immediate rename (breaks running app)
ALTER TABLE users RENAME COLUMN email TO new_email;

-- ❌ BAD: Adding NOT NULL without default (fails if rows exist)
ALTER TABLE users ADD COLUMN phone VARCHAR(20) NOT NULL;

-- ✅ GOOD: Add with default, make NOT NULL optional later
ALTER TABLE users ADD COLUMN phone VARCHAR(20) DEFAULT '';
```

## Migration Implementation (TypeScript)

```typescript
// migrations/001_create_users_table.ts
import { Kysely, sql } from "kysely";

export async function up(db: Kysely<any>): Promise<void> {
  await db.schema
    .createTable("users")
    .addColumn("id", "uuid", (col) =>
      col.primaryKey().defaultTo(sql`gen_random_uuid()`)
    )
    .addColumn("email", "varchar(255)", (col) => col.notNull().unique())
    .addColumn("name", "varchar(100)", (col) => col.notNull())
    .addColumn("role", "varchar(20)", (col) => col.notNull())
    .addColumn("status", "varchar(20)", (col) =>
      col.notNull().defaultTo("active")
    )
    .addColumn("created_at", "timestamp", (col) =>
      col.notNull().defaultTo(sql`now()`)
    )
    .addColumn("updated_at", "timestamp", (col) =>
      col.notNull().defaultTo(sql`now()`)
    )
    .execute();

  // Indexes
  await db.schema
    .createIndex("idx_users_email")
    .on("users")
    .column("email")
    .execute();

  await db.schema
    .createIndex("idx_users_status")
    .on("users")
    .column("status")
    .where("deleted_at", "is", null)
    .execute();
}

export async function down(db: Kysely<any>): Promise<void> {
  await db.schema.dropTable("users").cascade().execute();
}
```

## Database Choice Decision Tree

### Choose SQL (PostgreSQL/MySQL) When:

✅ Complex relationships between entities (many joins)
✅ Strong consistency required (ACID transactions)
✅ Complex queries with aggregations, joins, subqueries
✅ Ad-hoc reporting and analytics needed
✅ Data structure well-defined and stable
✅ Need for referential integrity constraints
✅ Mature tooling and wide support

**Examples**: User management, order processing, financial transactions, CRM systems

### Choose NoSQL (DynamoDB/MongoDB) When:

✅ Horizontal scaling required (massive scale)
✅ Flexible schema needed (evolving data model)
✅ Simple access patterns (key-value, single-table)
✅ High write throughput (millions of writes/sec)
✅ Eventual consistency acceptable
✅ Predictable, single-digit millisecond latency
✅ Serverless, fully managed infrastructure

**Examples**: Session storage, activity logs, time-series data, IoT data, caching

## Schema Versioning

```sql
-- Track schema version in database
CREATE TABLE schema_migrations (
  version VARCHAR(255) PRIMARY KEY,
  applied_at TIMESTAMP NOT NULL DEFAULT NOW(),
  description TEXT
);

-- Insert migration record when applied
INSERT INTO schema_migrations (version, description)
VALUES ('20250115_001', 'Create users table');
```

```typescript
// Application checks schema version on startup
const requiredVersion = "20250115_001";
const currentVersion = await db.getCurrentSchemaVersion();

if (currentVersion !== requiredVersion) {
  throw new Error(
    `Schema version mismatch. Required: ${requiredVersion}, Current: ${currentVersion}. Run migrations.`
  );
}
```

## Database Design Checklist

Before finalizing schema:

- [ ] All tables have primary keys (UUID or BIGINT)
- [ ] Foreign key constraints defined with appropriate ON DELETE behavior
- [ ] Indexes created for all common query patterns
- [ ] Check constraints for data validation (status enums, positive amounts)
- [ ] NOT NULL constraints where appropriate
- [ ] Unique constraints for unique data (email, username)
- [ ] Default values for columns where sensible
- [ ] Normalized to appropriate level (usually 3NF)
- [ ] Strategic denormalization documented with rationale
- [ ] Migration strategy defined (backward-compatible steps)
- [ ] Rollback plan exists and tested
- [ ] Indexes support all major queries (verify with EXPLAIN)
- [ ] No over-indexing (write performance considered)
- [ ] Soft delete pattern considered (deleted_at timestamp)
- [ ] Audit fields included (created_at, updated_at, created_by)

## Key Takeaways

1. **Design schema first** - Data model drives application design
2. **Normalize by default** - Eliminate redundancy unless performance requires it
3. **Index for queries** - Every common query should have supporting index
4. **Foreign keys enforce integrity** - Use them unless you have good reason not to
5. **Migrations must be safe** - Backward-compatible, reversible, tested
6. **Measure before denormalizing** - Premature optimization is wasteful
7. **Access patterns drive NoSQL design** - Start with queries, design schema second
8. **Test migrations on staging** - Never run untested migrations on production
