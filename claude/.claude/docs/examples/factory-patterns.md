# Test Data Factory Patterns

This guide demonstrates comprehensive test factory patterns for creating test data that's maintainable, type-safe, and easy to customize. Based on proven patterns from citypaul's factory guidance.

## Core Principles

1. **Partial Overrides:** Factories accept partial objects to override defaults
2. **Schema Validation:** Factory output is validated with Zod schemas
3. **Semantic Defaults:** Default values should make semantic sense
4. **Composability:** Factories should build on other factories
5. **Type Safety:** Full TypeScript support with inference

---

## Pattern 1: Simple Object Factory

The foundation of all factories - accepts partial overrides, returns validated object.

```typescript
// user.ts
import { z } from 'zod';

const UserSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  username: z.string().min(3).max(20),
  role: z.enum(['user', 'admin', 'moderator']),
  isActive: z.boolean(),
  createdAt: z.date()
});

type User = z.infer<typeof UserSchema>;

export { UserSchema };
export type { User };
```

```typescript
// user.test-factory.ts
import { type User, UserSchema } from './user';

type UserOverrides = Partial<User>;

const createTestUser = (overrides?: UserOverrides): User => {
  const user: User = {
    id: crypto.randomUUID(),
    email: 'test@example.com',
    username: 'testuser',
    role: 'user',
    isActive: true,
    createdAt: new Date(),
    ...overrides
  };

  // Validate factory output with schema
  return UserSchema.parse(user);
};

export { createTestUser };
```

```typescript
// user.test.ts
import { describe, it, expect } from 'vitest';
import { createTestUser } from './user.test-factory';

describe('User Factory', () => {
  it('should create user with defaults', () => {
    const user = createTestUser();

    expect(user.email).toBe('test@example.com');
    expect(user.username).toBe('testuser');
    expect(user.role).toBe('user');
    expect(user.isActive).toBe(true);
  });

  it('should create admin user with override', () => {
    const admin = createTestUser({
      email: 'admin@example.com',
      role: 'admin'
    });

    expect(admin.email).toBe('admin@example.com');
    expect(admin.role).toBe('admin');
    expect(admin.username).toBe('testuser'); // other defaults preserved
  });

  it('should create inactive user', () => {
    const inactive = createTestUser({ isActive: false });

    expect(inactive.isActive).toBe(false);
  });
});
```

**Key Benefits:**
- Override only what you care about in each test
- Test intent is clear (overrides highlight what's being tested)
- Schema validation catches invalid test data at setup time

---

## Pattern 2: Nested Object Factories

Factories that compose other factories for complex nested structures.

```typescript
// address.ts
import { z } from 'zod';

const AddressSchema = z.object({
  street: z.string(),
  city: z.string(),
  state: z.string().length(2),
  zipCode: z.string().regex(/^\d{5}(-\d{4})?$/)
});

type Address = z.infer<typeof AddressSchema>;

export { AddressSchema };
export type { Address };
```

```typescript
// address.test-factory.ts
import { type Address, AddressSchema } from './address';

type AddressOverrides = Partial<Address>;

const createTestAddress = (overrides?: AddressOverrides): Address => {
  const address: Address = {
    street: '123 Main St',
    city: 'Springfield',
    state: 'IL',
    zipCode: '62701',
    ...overrides
  };

  return AddressSchema.parse(address);
};

export { createTestAddress };
```

```typescript
// customer.ts
import { z } from 'zod';
import { AddressSchema } from './address';

const CustomerSchema = z.object({
  id: z.string().uuid(),
  name: z.string(),
  email: z.string().email(),
  shippingAddress: AddressSchema,
  billingAddress: AddressSchema
});

type Customer = z.infer<typeof CustomerSchema>;

export { CustomerSchema };
export type { Customer };
```

```typescript
// customer.test-factory.ts
import { type Customer, CustomerSchema } from './customer';
import { type Address, createTestAddress } from './address.test-factory';

type CustomerOverrides = Partial<{
  id: string;
  name: string;
  email: string;
  shippingAddress: Address;
  billingAddress: Address;
}>;

const createTestCustomer = (overrides?: CustomerOverrides): Customer => {
  const customer: Customer = {
    id: crypto.randomUUID(),
    name: 'John Doe',
    email: 'john@example.com',
    shippingAddress: createTestAddress(),
    billingAddress: createTestAddress(),
    ...overrides
  };

  return CustomerSchema.parse(customer);
};

export { createTestCustomer };
```

```typescript
// customer.test.ts
import { describe, it, expect } from 'vitest';
import { createTestCustomer } from './customer.test-factory';
import { createTestAddress } from './address.test-factory';

describe('Customer Factory', () => {
  it('should create customer with default addresses', () => {
    const customer = createTestCustomer();

    expect(customer.shippingAddress.city).toBe('Springfield');
    expect(customer.billingAddress.city).toBe('Springfield');
  });

  it('should create customer with custom shipping address', () => {
    const customer = createTestCustomer({
      shippingAddress: createTestAddress({
        city: 'Chicago',
        zipCode: '60601'
      })
    });

    expect(customer.shippingAddress.city).toBe('Chicago');
    expect(customer.shippingAddress.zipCode).toBe('60601');
    expect(customer.billingAddress.city).toBe('Springfield'); // default preserved
  });

  it('should create customer with different billing and shipping', () => {
    const customer = createTestCustomer({
      shippingAddress: createTestAddress({ state: 'NY' }),
      billingAddress: createTestAddress({ state: 'CA' })
    });

    expect(customer.shippingAddress.state).toBe('NY');
    expect(customer.billingAddress.state).toBe('CA');
  });
});
```

**Key Benefits:**
- Compose factories for nested structures
- Override at any level of nesting
- Maintain type safety throughout

---

## Pattern 3: Builder Pattern for Complex Objects

For objects with many optional fields or complex setup requirements.

```typescript
// order.ts
import { z } from 'zod';

const OrderItemSchema = z.object({
  productId: z.string(),
  productName: z.string(),
  quantity: z.number().int().positive(),
  unitPrice: z.number().positive(),
  subtotal: z.number().nonnegative()
});

const OrderSchema = z.object({
  id: z.string().uuid(),
  customerId: z.string(),
  items: z.array(OrderItemSchema).min(1),
  subtotal: z.number().nonnegative(),
  tax: z.number().nonnegative(),
  shipping: z.number().nonnegative(),
  total: z.number().nonnegative(),
  status: z.enum(['pending', 'paid', 'shipped', 'delivered', 'cancelled']),
  createdAt: z.date()
});

type OrderItem = z.infer<typeof OrderItemSchema>;
type Order = z.infer<typeof OrderSchema>;

export { OrderSchema, OrderItemSchema };
export type { Order, OrderItem };
```

```typescript
// order.test-factory.ts
import { type Order, type OrderItem, OrderSchema, OrderItemSchema } from './order';

class TestOrderBuilder {
  private order: Partial<Order> = {
    id: crypto.randomUUID(),
    customerId: 'cust-default',
    items: [],
    subtotal: 0,
    tax: 0,
    shipping: 0,
    total: 0,
    status: 'pending',
    createdAt: new Date()
  };

  withId(id: string): this {
    this.order.id = id;
    return this;
  }

  withCustomerId(customerId: string): this {
    this.order.customerId = customerId;
    return this;
  }

  withItem(productId: string, productName: string, quantity: number, unitPrice: number): this {
    const subtotal = quantity * unitPrice;
    const item: OrderItem = {
      productId,
      productName,
      quantity,
      unitPrice,
      subtotal
    };

    const validated = OrderItemSchema.parse(item);
    this.order.items = [...(this.order.items || []), validated];

    return this;
  }

  withStatus(status: Order['status']): this {
    this.order.status = status;
    return this;
  }

  withShipping(shipping: number): this {
    this.order.shipping = shipping;
    return this;
  }

  withTaxRate(taxRate: number): this {
    const subtotal = this.calculateSubtotal();
    this.order.subtotal = subtotal;
    this.order.tax = subtotal * taxRate;
    return this;
  }

  private calculateSubtotal(): number {
    return (this.order.items || []).reduce((sum, item) => sum + item.subtotal, 0);
  }

  private calculateTotal(): number {
    return (this.order.subtotal || 0) + (this.order.tax || 0) + (this.order.shipping || 0);
  }

  build(): Order {
    // Calculate totals before building
    this.order.subtotal = this.calculateSubtotal();
    this.order.total = this.calculateTotal();

    return OrderSchema.parse(this.order as Order);
  }
}

const createTestOrderBuilder = (): TestOrderBuilder => new TestOrderBuilder();

const createTestOrder = (builderFn?: (builder: TestOrderBuilder) => TestOrderBuilder): Order => {
  const builder = createTestOrderBuilder()
    .withItem('prod-1', 'Default Product', 1, 10.00);

  const configured = builderFn ? builderFn(builder) : builder;
  return configured.build();
};

export { createTestOrderBuilder, createTestOrder };
```

```typescript
// order.test.ts
import { describe, it, expect } from 'vitest';
import { createTestOrder, createTestOrderBuilder } from './order.test-factory';

describe('Order Factory', () => {
  it('should create order with single default item', () => {
    const order = createTestOrder();

    expect(order.items).toHaveLength(1);
    expect(order.items[0].productId).toBe('prod-1');
    expect(order.subtotal).toBe(10.00);
    expect(order.total).toBe(10.00);
  });

  it('should create order with multiple items', () => {
    const order = createTestOrder(builder =>
      builder
        .withItem('prod-1', 'Product 1', 2, 10.00)
        .withItem('prod-2', 'Product 2', 1, 25.00)
    );

    expect(order.items).toHaveLength(2);
    expect(order.subtotal).toBe(45.00);
    expect(order.total).toBe(45.00);
  });

  it('should calculate tax and shipping', () => {
    const order = createTestOrder(builder =>
      builder
        .withItem('prod-1', 'Product', 2, 10.00)
        .withTaxRate(0.08)
        .withShipping(5.00)
    );

    expect(order.subtotal).toBe(20.00);
    expect(order.tax).toBe(1.60); // 8% of 20.00
    expect(order.shipping).toBe(5.00);
    expect(order.total).toBe(26.60);
  });

  it('should create shipped order', () => {
    const order = createTestOrder(builder =>
      builder
        .withStatus('shipped')
    );

    expect(order.status).toBe('shipped');
  });

  it('should use builder directly for complex setup', () => {
    const order = createTestOrderBuilder()
      .withCustomerId('cust-premium')
      .withItem('prod-1', 'Widget', 3, 15.00)
      .withItem('prod-2', 'Gadget', 1, 50.00)
      .withTaxRate(0.10)
      .withShipping(10.00)
      .withStatus('paid')
      .build();

    expect(order.customerId).toBe('cust-premium');
    expect(order.items).toHaveLength(2);
    expect(order.subtotal).toBe(95.00);
    expect(order.tax).toBe(9.50);
    expect(order.shipping).toBe(10.00);
    expect(order.total).toBe(114.50);
    expect(order.status).toBe('paid');
  });
});
```

**Key Benefits:**
- Fluent API for complex object construction
- Automatic calculation of derived fields
- Type-safe chaining
- Readable test setup

---

## Pattern 4: Factories for Related Entities

Factories that create related entities with proper foreign key relationships.

```typescript
// blog.test-factory.ts
import { type User } from './user';
import { type Post } from './post';
import { type Comment } from './comment';
import { createTestUser } from './user.test-factory';

type PostOverrides = Partial<Omit<Post, 'authorId'> & { author?: User }>;
type CommentOverrides = Partial<Omit<Comment, 'authorId' | 'postId'> & { author?: User; post?: Post }>;

// Create post with author
const createTestPost = (overrides?: PostOverrides): { post: Post; author: User } => {
  const author = overrides?.author || createTestUser();

  const post: Post = {
    id: crypto.randomUUID(),
    authorId: author.id,
    title: 'Test Post',
    content: 'This is a test post content.',
    published: false,
    createdAt: new Date(),
    ...overrides
  };

  return { post, author };
};

// Create comment with author and post
const createTestComment = (overrides?: CommentOverrides): { comment: Comment; author: User; post: Post } => {
  const { post, author: postAuthor } = overrides?.post
    ? { post: overrides.post, author: createTestUser() }
    : createTestPost();

  const author = overrides?.author || createTestUser();

  const comment: Comment = {
    id: crypto.randomUUID(),
    postId: post.id,
    authorId: author.id,
    content: 'This is a test comment.',
    createdAt: new Date(),
    ...overrides
  };

  return { comment, author, post };
};

export { createTestPost, createTestComment };
```

```typescript
// blog.test.ts
import { describe, it, expect } from 'vitest';
import { createTestPost, createTestComment } from './blog.test-factory';
import { createTestUser } from './user.test-factory';

describe('Blog Factories', () => {
  it('should create post with author', () => {
    const { post, author } = createTestPost();

    expect(post.authorId).toBe(author.id);
    expect(post.title).toBe('Test Post');
  });

  it('should create post with specific author', () => {
    const specificAuthor = createTestUser({
      username: 'authorname',
      email: 'author@example.com'
    });

    const { post, author } = createTestPost({ author: specificAuthor });

    expect(post.authorId).toBe(specificAuthor.id);
    expect(author.username).toBe('authorname');
  });

  it('should create comment with author and post', () => {
    const { comment, author, post } = createTestComment();

    expect(comment.postId).toBe(post.id);
    expect(comment.authorId).toBe(author.id);
  });

  it('should create comment on existing post', () => {
    const { post: existingPost } = createTestPost({ title: 'Existing Post' });

    const { comment, post } = createTestComment({ post: existingPost });

    expect(comment.postId).toBe(existingPost.id);
    expect(post.title).toBe('Existing Post');
  });

  it('should create comment with specific author on existing post', () => {
    const { post: existingPost } = createTestPost();
    const commenter = createTestUser({ username: 'commenter' });

    const { comment, author } = createTestComment({
      post: existingPost,
      author: commenter
    });

    expect(comment.postId).toBe(existingPost.id);
    expect(comment.authorId).toBe(commenter.id);
    expect(author.username).toBe('commenter');
  });
});
```

**Key Benefits:**
- Automatic foreign key management
- Return all related entities for assertions
- Override relationships as needed
- Maintain referential integrity

---

## Pattern 5: Date/Time Factories

Factories for creating consistent, testable date/time values.

```typescript
// date.test-factory.ts

// Base reference date for consistent tests
const BASE_DATE = new Date('2024-01-01T00:00:00.000Z');

type DateOffset = {
  days?: number;
  hours?: number;
  minutes?: number;
  seconds?: number;
};

const createTestDate = (offset?: DateOffset): Date => {
  const date = new Date(BASE_DATE);

  if (offset?.days) date.setDate(date.getDate() + offset.days);
  if (offset?.hours) date.setHours(date.getHours() + offset.hours);
  if (offset?.minutes) date.setMinutes(date.getMinutes() + offset.minutes);
  if (offset?.seconds) date.setSeconds(date.getSeconds() + offset.seconds);

  return date;
};

const createPastDate = (daysAgo: number): Date =>
  createTestDate({ days: -daysAgo });

const createFutureDate = (daysFromNow: number): Date =>
  createTestDate({ days: daysFromNow });

const createRecentDate = (): Date =>
  createTestDate({ hours: -2 });

export { createTestDate, createPastDate, createFutureDate, createRecentDate, BASE_DATE };
```

```typescript
// subscription.test-factory.ts
import { createTestDate, createPastDate, createFutureDate } from './date.test-factory';

type Subscription = {
  id: string;
  userId: string;
  startDate: Date;
  endDate: Date;
  status: 'active' | 'expired' | 'cancelled';
};

type SubscriptionOverrides = Partial<Subscription>;

const createTestSubscription = (overrides?: SubscriptionOverrides): Subscription => {
  const subscription: Subscription = {
    id: crypto.randomUUID(),
    userId: 'user-default',
    startDate: createPastDate(30),
    endDate: createFutureDate(335), // 1 year subscription
    status: 'active',
    ...overrides
  };

  return subscription;
};

const createExpiredSubscription = (overrides?: SubscriptionOverrides): Subscription =>
  createTestSubscription({
    startDate: createPastDate(400),
    endDate: createPastDate(35),
    status: 'expired',
    ...overrides
  });

const createNewSubscription = (overrides?: SubscriptionOverrides): Subscription =>
  createTestSubscription({
    startDate: createTestDate(),
    endDate: createFutureDate(365),
    status: 'active',
    ...overrides
  });

export { createTestSubscription, createExpiredSubscription, createNewSubscription };
```

```typescript
// subscription.test.ts
import { describe, it, expect } from 'vitest';
import { createTestSubscription, createExpiredSubscription, createNewSubscription } from './subscription.test-factory';
import { BASE_DATE, createPastDate, createFutureDate } from './date.test-factory';

describe('Subscription Factories', () => {
  it('should create active subscription', () => {
    const subscription = createTestSubscription();

    expect(subscription.status).toBe('active');
    expect(subscription.startDate).toEqual(createPastDate(30));
    expect(subscription.endDate).toEqual(createFutureDate(335));
  });

  it('should create expired subscription', () => {
    const subscription = createExpiredSubscription();

    expect(subscription.status).toBe('expired');
    expect(subscription.endDate.getTime()).toBeLessThan(BASE_DATE.getTime());
  });

  it('should create new subscription starting today', () => {
    const subscription = createNewSubscription();

    expect(subscription.status).toBe('active');
    expect(subscription.startDate).toEqual(BASE_DATE);
  });
});
```

**Key Benefits:**
- Consistent, predictable dates in tests
- Easy to create relative dates (past, future, recent)
- Avoid flaky tests from current date/time
- Clear intent with named factory functions

---

## Pattern 6: Sequences and Uniqueness

Factories that generate unique values across test runs.

```typescript
// sequence.test-factory.ts

type SequenceCounters = {
  [key: string]: number;
};

const sequences: SequenceCounters = {};

const sequence = (name: string, start: number = 1): number => {
  if (!(name in sequences)) {
    sequences[name] = start;
  }
  return sequences[name]++;
};

const resetSequence = (name: string): void => {
  delete sequences[name];
};

const resetAllSequences = (): void => {
  Object.keys(sequences).forEach(key => delete sequences[key]);
};

export { sequence, resetSequence, resetAllSequences };
```

```typescript
// user.test-factory.ts (with sequences)
import { type User, UserSchema } from './user';
import { sequence } from './sequence.test-factory';

type UserOverrides = Partial<User>;

const createTestUser = (overrides?: UserOverrides): User => {
  const userNumber = sequence('user');

  const user: User = {
    id: crypto.randomUUID(),
    email: `user${userNumber}@example.com`,
    username: `user${userNumber}`,
    role: 'user',
    isActive: true,
    createdAt: new Date(),
    ...overrides
  };

  return UserSchema.parse(user);
};

export { createTestUser };
```

```typescript
// user.test.ts (with sequences)
import { describe, it, expect, beforeEach } from 'vitest';
import { createTestUser } from './user.test-factory';
import { resetAllSequences } from './sequence.test-factory';

describe('User Factory with Sequences', () => {
  beforeEach(() => {
    resetAllSequences();
  });

  it('should create users with unique emails', () => {
    const user1 = createTestUser();
    const user2 = createTestUser();
    const user3 = createTestUser();

    expect(user1.email).toBe('user1@example.com');
    expect(user2.email).toBe('user2@example.com');
    expect(user3.email).toBe('user3@example.com');
  });

  it('should allow email override with sequence', () => {
    const user1 = createTestUser();
    const user2 = createTestUser({ email: 'custom@example.com' });
    const user3 = createTestUser();

    expect(user1.email).toBe('user1@example.com');
    expect(user2.email).toBe('custom@example.com');
    expect(user3.email).toBe('user3@example.com');
  });
});
```

**Key Benefits:**
- Automatic unique values across test runs
- Avoids unique constraint violations
- Clear, predictable patterns
- Resettable for test isolation

---

## Summary: Factory Pattern Recommendations

1. **Start Simple:** Use Partial overrides for most factories
2. **Compose Factories:** Build complex objects from simpler factories
3. **Use Builders for Complexity:** Builder pattern when objects have many optional fields or computed values
4. **Maintain Relationships:** Factories for related entities should handle foreign keys automatically
5. **Consistent Dates:** Use date factories for predictable, testable dates
6. **Ensure Uniqueness:** Use sequences when uniqueness matters (emails, usernames, IDs)
7. **Validate Output:** Always validate factory output with schemas
8. **Override What Matters:** Test intent should be clear from overrides
9. **Semantic Defaults:** Choose defaults that make sense in context
10. **Type Safety:** Use TypeScript types and Zod schemas throughout

These patterns create maintainable, readable, and type-safe test data that makes test intent clear and reduces duplication.
