# Database Normalization Reference

## Overview
Normalization organizes data to reduce redundancy and improve integrity. This guide covers the first three normal forms (1NF, 2NF, 3NF) with practical examples and guidance on when to denormalize.

## First Normal Form (1NF)

### Definition
Each column contains atomic (indivisible) values, and each row is unique.

### Rules
1. No repeating groups or arrays in columns
2. Each cell contains single value
3. Each row is uniquely identifiable (has primary key)
4. Column order doesn't matter

### Violations

**Repeating columns**:
```sql
-- ❌ Violates 1NF: Repeating columns
CREATE TABLE employees (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100),
  phone1 VARCHAR(20),
  phone2 VARCHAR(20),
  phone3 VARCHAR(20)
);

-- Adding 4th phone requires schema change
```

**Multi-valued columns**:
```sql
-- ❌ Violates 1NF: Comma-separated values
CREATE TABLE projects (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100),
  team_members VARCHAR(500)  -- 'John,Jane,Bob'
);

-- Cannot query "projects where Bob is member"
-- Cannot enforce referential integrity
```

**Non-atomic values**:
```sql
-- ❌ Violates 1NF: JSON/object in column
CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  customer_name VARCHAR(100),
  address TEXT  -- '123 Main St, City, State, ZIP'
);

-- Cannot query by city or state
-- Cannot validate address format
```

### Solution: Normalize to 1NF

**Repeating columns → Separate table**:
```sql
-- ✓ 1NF: Separate phones table
CREATE TABLE employees (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100)
);

CREATE TABLE employee_phones (
  id SERIAL PRIMARY KEY,
  employee_id INTEGER REFERENCES employees(id),
  phone_number VARCHAR(20),
  phone_type VARCHAR(20)  -- 'mobile', 'work', 'home'
);

-- Easy to query
SELECT e.name, p.phone_number
FROM employees e
JOIN employee_phones p ON e.id = p.employee_id
WHERE e.id = 123;
```

**Multi-valued columns → Junction table**:
```sql
-- ✓ 1NF: Many-to-many relationship
CREATE TABLE projects (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100)
);

CREATE TABLE employees (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100)
);

CREATE TABLE project_members (
  project_id INTEGER REFERENCES projects(id),
  employee_id INTEGER REFERENCES employees(id),
  PRIMARY KEY (project_id, employee_id)
);

-- Easy to query projects by team member
SELECT p.name
FROM projects p
JOIN project_members pm ON p.id = pm.project_id
WHERE pm.employee_id = 123;
```

**Non-atomic values → Separate columns**:
```sql
-- ✓ 1NF: Atomic address components
CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  customer_name VARCHAR(100),
  street_address VARCHAR(200),
  city VARCHAR(100),
  state VARCHAR(50),
  postal_code VARCHAR(20),
  country VARCHAR(100)
);

-- Easy to query by city
SELECT * FROM orders WHERE city = 'New York';
```

## Second Normal Form (2NF)

### Definition
Must be in 1NF, and all non-key columns depend on entire primary key (no partial dependencies).

**Only applies to tables with composite primary keys.**

### Violation: Partial Dependency

```sql
-- ❌ Violates 2NF: Composite key with partial dependencies
CREATE TABLE order_items (
  order_id INTEGER,
  product_id INTEGER,
  quantity INTEGER,
  unit_price DECIMAL(10, 2),
  customer_name VARCHAR(100),    -- Depends only on order_id
  customer_email VARCHAR(255),   -- Depends only on order_id
  product_name VARCHAR(200),     -- Depends only on product_id
  product_category VARCHAR(100), -- Depends only on product_id
  PRIMARY KEY (order_id, product_id)
);
```

**Problems**:
- Redundancy: customer_name repeated for each item in order
- Update anomaly: Changing customer name requires updating multiple rows
- Insertion anomaly: Cannot store customer without order
- Deletion anomaly: Deleting last order item loses customer data

### Solution: Normalize to 2NF

```sql
-- ✓ 2NF: Separate tables for each entity
CREATE TABLE customers (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100),
  email VARCHAR(255)
);

CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  name VARCHAR(200),
  category VARCHAR(100),
  unit_price DECIMAL(10, 2)
);

CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  customer_id INTEGER REFERENCES customers(id),
  order_date TIMESTAMP DEFAULT NOW()
);

CREATE TABLE order_items (
  order_id INTEGER REFERENCES orders(id),
  product_id INTEGER REFERENCES products(id),
  quantity INTEGER,
  unit_price DECIMAL(10, 2),  -- Snapshot of price at order time
  PRIMARY KEY (order_id, product_id)
);
```

**Benefits**:
- No redundancy: customer_name stored once
- Update once: Change customer name in one place
- Can store customers without orders
- Deleting order doesn't lose customer data

## Third Normal Form (3NF)

### Definition
Must be in 2NF, and no non-key column depends on another non-key column (no transitive dependencies).

### Violation: Transitive Dependency

```sql
-- ❌ Violates 3NF: Transitive dependency
CREATE TABLE employees (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100),
  department VARCHAR(100),
  department_head VARCHAR(100),  -- Depends on department (non-key)
  department_budget DECIMAL(12, 2)  -- Depends on department (non-key)
);

-- employee → department → department_head (transitive)
```

**Problems**:
- Redundancy: department_head repeated for each employee in department
- Update anomaly: Changing department head requires updating all employees
- Insertion anomaly: Cannot store department without employees
- Deletion anomaly: Deleting last employee loses department data

### Solution: Normalize to 3NF

```sql
-- ✓ 3NF: Separate departments table
CREATE TABLE departments (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) UNIQUE,
  head_name VARCHAR(100),
  budget DECIMAL(12, 2)
);

CREATE TABLE employees (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100),
  department_id INTEGER REFERENCES departments(id)
);
```

**Benefits**:
- No redundancy: department data stored once
- Update once: Change department head in one place
- Can store departments without employees
- Deleting employee doesn't lose department data

### Another Example: Product Pricing

```sql
-- ❌ Violates 3NF: Price depends on currency
CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  name VARCHAR(200),
  price DECIMAL(10, 2),
  currency VARCHAR(3),  -- 'USD', 'EUR', 'GBP'
  exchange_rate DECIMAL(10, 4)  -- Depends on currency (non-key)
);

-- product → currency → exchange_rate (transitive)

-- ✓ 3NF: Separate currencies table
CREATE TABLE currencies (
  code VARCHAR(3) PRIMARY KEY,
  name VARCHAR(50),
  exchange_rate DECIMAL(10, 4)
);

CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  name VARCHAR(200),
  price DECIMAL(10, 2),
  currency_code VARCHAR(3) REFERENCES currencies(code)
);
```

## Normalization Examples

### Example 1: Blog System

**Denormalized (violates 2NF, 3NF)**:
```sql
CREATE TABLE posts (
  id SERIAL PRIMARY KEY,
  title VARCHAR(200),
  content TEXT,
  author_name VARCHAR(100),
  author_email VARCHAR(255),
  author_bio TEXT,
  category_name VARCHAR(100),
  category_description TEXT
);
```

**Normalized (3NF)**:
```sql
CREATE TABLE authors (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100),
  email VARCHAR(255) UNIQUE,
  bio TEXT
);

CREATE TABLE categories (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) UNIQUE,
  description TEXT
);

CREATE TABLE posts (
  id SERIAL PRIMARY KEY,
  title VARCHAR(200),
  content TEXT,
  author_id INTEGER REFERENCES authors(id),
  category_id INTEGER REFERENCES categories(id),
  created_at TIMESTAMP DEFAULT NOW()
);
```

### Example 2: E-Commerce Order

**Denormalized**:
```sql
CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  customer_name VARCHAR(100),
  customer_email VARCHAR(255),
  customer_address TEXT,
  product_name VARCHAR(200),
  product_price DECIMAL(10, 2),
  quantity INTEGER,
  total_price DECIMAL(10, 2)
);
```

**Problems**:
- Repeating customer data for each order
- Cannot have orders with multiple products
- Cannot update customer email without updating all orders

**Normalized (3NF)**:
```sql
CREATE TABLE customers (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100),
  email VARCHAR(255) UNIQUE,
  address TEXT
);

CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  name VARCHAR(200),
  price DECIMAL(10, 2)
);

CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  customer_id INTEGER REFERENCES customers(id),
  order_date TIMESTAMP DEFAULT NOW(),
  total DECIMAL(10, 2)
);

CREATE TABLE order_items (
  id SERIAL PRIMARY KEY,
  order_id INTEGER REFERENCES orders(id),
  product_id INTEGER REFERENCES products(id),
  quantity INTEGER,
  unit_price DECIMAL(10, 2)  -- Price at time of order
);
```

## When to Denormalize

### Performance Optimization
Normalization improves data integrity but can hurt read performance.

**Example: Frequently accessed aggregates**:
```sql
-- Normalized: Requires aggregation
SELECT
  o.id,
  o.order_date,
  SUM(oi.quantity * oi.unit_price) AS total
FROM orders o
JOIN order_items oi ON o.id = oi.order_id
WHERE o.customer_id = 123
GROUP BY o.id, o.order_date;

-- Denormalized: Pre-calculated total
SELECT id, order_date, total
FROM orders
WHERE customer_id = 123;

-- Add denormalized total column
ALTER TABLE orders ADD COLUMN total DECIMAL(10, 2);

-- Update on order item changes (trigger or application logic)
```

### Read-Heavy Applications
When reads vastly outnumber writes, denormalization can improve performance.

**Example: Article view counts**:
```sql
-- Normalized: Count views
SELECT a.title, COUNT(v.id) AS views
FROM articles a
LEFT JOIN article_views v ON a.id = v.article_id
GROUP BY a.id, a.title;

-- Denormalized: Cached count
ALTER TABLE articles ADD COLUMN view_count INTEGER DEFAULT 0;

-- Increment on view (faster reads, acceptable write overhead)
UPDATE articles SET view_count = view_count + 1 WHERE id = 123;
```

### Common Denormalization Patterns

**1. Calculated fields**:
```sql
-- Instead of: SELECT SUM(price) FROM order_items WHERE order_id = ?
-- Denormalize: orders.total (updated on item changes)
```

**2. Snapshot data**:
```sql
-- order_items.unit_price snapshots product.price at order time
-- Preserves historical accuracy
```

**3. Derived data**:
```sql
-- users.post_count = COUNT(posts WHERE author_id = user.id)
-- Updated on post create/delete
```

**4. Lookup caching**:
```sql
-- posts.author_name (copy of authors.name)
-- Avoids JOIN for display lists
```

### Maintaining Denormalized Data

**Application logic**:
```typescript
// Update derived field in application
async function createOrderItem(orderId: string, item: OrderItem) {
  await prisma.$transaction([
    // Insert order item
    prisma.orderItem.create({ data: item }),

    // Update order total
    prisma.order.update({
      where: { id: orderId },
      data: {
        total: {
          increment: item.quantity * item.unitPrice,
        },
      },
    }),
  ]);
}
```

**Database triggers** (PostgreSQL):
```sql
-- Update order total on item insert/update/delete
CREATE OR REPLACE FUNCTION update_order_total()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE orders
  SET total = (
    SELECT COALESCE(SUM(quantity * unit_price), 0)
    FROM order_items
    WHERE order_id = NEW.order_id
  )
  WHERE id = NEW.order_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER order_items_total
AFTER INSERT OR UPDATE OR DELETE ON order_items
FOR EACH ROW
EXECUTE FUNCTION update_order_total();
```

## Normalization Checklist

### 1NF Checklist
- [ ] Each column contains single value (atomic)
- [ ] No repeating groups (phone1, phone2, phone3)
- [ ] No comma-separated values
- [ ] Each row has unique identifier (primary key)

### 2NF Checklist
- [ ] Table is in 1NF
- [ ] All non-key columns depend on entire primary key
- [ ] No partial dependencies (for composite keys)

### 3NF Checklist
- [ ] Table is in 2NF
- [ ] No non-key column depends on another non-key column
- [ ] No transitive dependencies

### Denormalization Checklist
- [ ] Performance problem measured (not assumed)
- [ ] Read:write ratio heavily skewed to reads
- [ ] Maintenance strategy defined (triggers/application logic)
- [ ] Data consistency guaranteed
- [ ] Benefits outweigh complexity

## Common Mistakes

### Over-Normalization
```sql
-- ❌ Over-normalized: Separate table for states
CREATE TABLE states (
  code VARCHAR(2) PRIMARY KEY,
  name VARCHAR(50)
);

CREATE TABLE addresses (
  id SERIAL PRIMARY KEY,
  street VARCHAR(200),
  city VARCHAR(100),
  state_code VARCHAR(2) REFERENCES states(code)
);

-- ✓ States are stable, small set (50 values)
-- Better: Use ENUM or VARCHAR with CHECK constraint
CREATE TABLE addresses (
  id SERIAL PRIMARY KEY,
  street VARCHAR(200),
  city VARCHAR(100),
  state VARCHAR(2) CHECK (state IN ('AL', 'AK', 'AZ', ...))
);
```

### Premature Denormalization
```sql
-- ❌ Denormalized without measuring
ALTER TABLE posts ADD COLUMN author_name VARCHAR(100);

-- Better: Measure first
EXPLAIN ANALYZE
SELECT p.title, a.name
FROM posts p
JOIN authors a ON p.author_id = a.id;

-- If fast enough, keep normalized
```

### Inconsistent Denormalized Data
```sql
-- ❌ Forgot to update denormalized field
UPDATE authors SET name = 'New Name' WHERE id = 123;
-- posts.author_name is now stale!

-- ✓ Update both or use trigger
UPDATE authors SET name = 'New Name' WHERE id = 123;
UPDATE posts SET author_name = 'New Name' WHERE author_id = 123;
```

## Testing Normalization

```typescript
// Test data integrity with normalized schema
describe('Order normalization', () => {
  test('updating product price does not affect old orders', async () => {
    // Create order with product at $10
    const order = await createOrder({ productId: 1, quantity: 2 });
    expect(order.total).toBe(20); // 2 * $10

    // Update product price to $15
    await updateProduct(1, { price: 15 });

    // Old order total unchanged (historical accuracy)
    const oldOrder = await getOrder(order.id);
    expect(oldOrder.total).toBe(20);

    // New order uses new price
    const newOrder = await createOrder({ productId: 1, quantity: 2 });
    expect(newOrder.total).toBe(30); // 2 * $15
  });

  test('deleting customer does not delete orders', async () => {
    const customer = await createCustomer({ name: 'John' });
    const order = await createOrder({ customerId: customer.id });

    await deleteCustomer(customer.id);

    // Order still exists (with foreign key ON DELETE SET NULL or CASCADE to audit table)
    const existingOrder = await getOrder(order.id);
    expect(existingOrder).toBeDefined();
  });
});
```

## Related
- [Indexing Strategies](./indexing-strategies.md)
- [Database Integration](../patterns/backend/database-integration.md)
- [Database Optimization](../patterns/performance/database-optimization.md)
