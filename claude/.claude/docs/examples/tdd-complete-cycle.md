# Complete TDD Cycle - Order Processing Example

This example demonstrates a full Test-Driven Development cycle using an order processing domain. It shows multiple iterations of Red-Green-Refactor with schema-first design, behavioral testing, and factory functions.

## Iteration 1: Creating an Order

### Red: Write Failing Test

```typescript
// order.test.ts
import { describe, it, expect } from 'vitest';
import { createOrder, type Order } from './order';

describe('Order Processing', () => {
  it('should create a valid order with items', () => {
    const order = createOrder({
      customerId: 'cust-123',
      items: [
        { productId: 'prod-1', quantity: 2, unitPrice: 10.00 }
      ]
    });

    expect(order.id).toBeDefined();
    expect(order.customerId).toBe('cust-123');
    expect(order.items).toHaveLength(1);
    expect(order.status).toBe('pending');
    expect(order.total).toBe(20.00);
    expect(order.createdAt).toBeInstanceOf(Date);
  });
});
```

**Run test:** ❌ Fails - `createOrder` doesn't exist

### Green: Minimum Code to Pass

```typescript
// order.ts
import { z } from 'zod';

// Schema first: Define structure with Zod
const OrderItemSchema = z.object({
  productId: z.string().min(1),
  quantity: z.number().int().positive(),
  unitPrice: z.number().positive()
});

const OrderSchema = z.object({
  id: z.string(),
  customerId: z.string().min(1),
  items: z.array(OrderItemSchema).min(1),
  status: z.enum(['pending', 'processing', 'completed', 'cancelled']),
  total: z.number().nonnegative(),
  createdAt: z.date()
});

// Derive types from schemas
type OrderItem = z.infer<typeof OrderItemSchema>;
type Order = z.infer<typeof OrderSchema>;

type CreateOrderInput = {
  customerId: string;
  items: OrderItem[];
};

// Factory function with minimal logic
const createOrder = (input: CreateOrderInput): Order => {
  const total = input.items.reduce(
    (sum, item) => sum + (item.quantity * item.unitPrice),
    0
  );

  const order = {
    id: `order-${Date.now()}`,
    customerId: input.customerId,
    items: input.items,
    status: 'pending' as const,
    total,
    createdAt: new Date()
  };

  return OrderSchema.parse(order);
};

export { createOrder, OrderSchema, OrderItemSchema };
export type { Order, OrderItem };
```

**Run test:** ✅ Passes

### Refactor: Assess Opportunities

**Analysis:**
- Code is simple and clear
- Single responsibility
- Schema validation ensures correctness
- No duplication or complexity

**Decision:** No refactoring needed yet - code is already clean.

---

## Iteration 2: Adding Order Validation

### Red: Write Failing Test

```typescript
// order.test.ts (add to existing describe block)
it('should throw error for empty items array', () => {
  expect(() =>
    createOrder({
      customerId: 'cust-123',
      items: []
    })
  ).toThrow();
});

it('should throw error for negative quantities', () => {
  expect(() =>
    createOrder({
      customerId: 'cust-123',
      items: [
        { productId: 'prod-1', quantity: -1, unitPrice: 10.00 }
      ]
    })
  ).toThrow();
});

it('should throw error for invalid customer ID', () => {
  expect(() =>
    createOrder({
      customerId: '',
      items: [
        { productId: 'prod-1', quantity: 1, unitPrice: 10.00 }
      ]
    })
  ).toThrow();
});
```

**Run tests:** ✅ All pass - Schema already validates these cases!

**Learning:** Schema-first design caught edge cases automatically. No production code changes needed.

---

## Iteration 3: Processing Orders

### Red: Write Failing Test

```typescript
// order.test.ts (add to existing describe block)
it('should process a pending order', () => {
  const order = createOrder({
    customerId: 'cust-123',
    items: [
      { productId: 'prod-1', quantity: 1, unitPrice: 10.00 }
    ]
  });

  const processed = processOrder(order);

  expect(processed.status).toBe('processing');
  expect(processed.id).toBe(order.id);
  expect(processed.customerId).toBe(order.customerId);
});

it('should throw error when processing non-pending order', () => {
  const order = createOrder({
    customerId: 'cust-123',
    items: [
      { productId: 'prod-1', quantity: 1, unitPrice: 10.00 }
    ]
  });

  const processed = processOrder(order);

  // Can't process an already processing order
  expect(() => processOrder(processed)).toThrow('Can only process pending orders');
});
```

**Run tests:** ❌ Fails - `processOrder` doesn't exist

### Green: Minimum Code to Pass

```typescript
// order.ts (add to existing file)

const processOrder = (order: Order): Order => {
  if (order.status !== 'pending') {
    throw new Error('Can only process pending orders');
  }

  const processed = {
    ...order,
    status: 'processing' as const
  };

  return OrderSchema.parse(processed);
};

export { createOrder, processOrder, OrderSchema, OrderItemSchema };
```

**Run tests:** ✅ All pass

### Refactor: Assess Opportunities

**Analysis:**
- Two status transition functions will emerge (process, complete, cancel)
- Each will have similar structure: check current status → create new order with updated status
- Potential for duplication

**Decision:** Wait until we have 3 instances (Rule of Three) before abstracting.

---

## Iteration 4: Completing and Cancelling Orders

### Red: Write Failing Tests

```typescript
// order.test.ts (add to existing describe block)
it('should complete a processing order', () => {
  const order = createOrder({
    customerId: 'cust-123',
    items: [
      { productId: 'prod-1', quantity: 1, unitPrice: 10.00 }
    ]
  });

  const processing = processOrder(order);
  const completed = completeOrder(processing);

  expect(completed.status).toBe('completed');
  expect(completed.id).toBe(order.id);
});

it('should throw error when completing non-processing order', () => {
  const order = createOrder({
    customerId: 'cust-123',
    items: [
      { productId: 'prod-1', quantity: 1, unitPrice: 10.00 }
    ]
  });

  expect(() => completeOrder(order)).toThrow('Can only complete processing orders');
});

it('should cancel a pending order', () => {
  const order = createOrder({
    customerId: 'cust-123',
    items: [
      { productId: 'prod-1', quantity: 1, unitPrice: 10.00 }
    ]
  });

  const cancelled = cancelOrder(order);

  expect(cancelled.status).toBe('cancelled');
  expect(cancelled.id).toBe(order.id);
});

it('should throw error when cancelling non-pending order', () => {
  const order = createOrder({
    customerId: 'cust-123',
    items: [
      { productId: 'prod-1', quantity: 1, unitPrice: 10.00 }
    ]
  });

  const processing = processOrder(order);

  expect(() => cancelOrder(processing)).toThrow('Can only cancel pending orders');
});
```

**Run tests:** ❌ Fails - `completeOrder` and `cancelOrder` don't exist

### Green: Minimum Code to Pass

```typescript
// order.ts (add to existing file)

const completeOrder = (order: Order): Order => {
  if (order.status !== 'processing') {
    throw new Error('Can only complete processing orders');
  }

  const completed = {
    ...order,
    status: 'completed' as const
  };

  return OrderSchema.parse(completed);
};

const cancelOrder = (order: Order): Order => {
  if (order.status !== 'pending') {
    throw new Error('Can only cancel pending orders');
  }

  const cancelled = {
    ...order,
    status: 'cancelled' as const
  };

  return OrderSchema.parse(cancelled);
};

export {
  createOrder,
  processOrder,
  completeOrder,
  cancelOrder,
  OrderSchema,
  OrderItemSchema
};
```

**Run tests:** ✅ All pass

### Refactor: Extract Common Pattern

**Analysis:**
Now we have 3 functions with identical structure:
1. Check if order is in expected status
2. Create new order with updated status
3. Validate with schema

This is **structural duplication** worth removing.

```typescript
// order.ts (refactored)

type OrderStatus = Order['status'];

type StatusTransition = {
  from: OrderStatus;
  to: OrderStatus;
  errorMessage: string;
};

const transitionOrderStatus = (
  order: Order,
  transition: StatusTransition
): Order => {
  if (order.status !== transition.from) {
    throw new Error(transition.errorMessage);
  }

  const updated = {
    ...order,
    status: transition.to
  };

  return OrderSchema.parse(updated);
};

const processOrder = (order: Order): Order =>
  transitionOrderStatus(order, {
    from: 'pending',
    to: 'processing',
    errorMessage: 'Can only process pending orders'
  });

const completeOrder = (order: Order): Order =>
  transitionOrderStatus(order, {
    from: 'processing',
    to: 'completed',
    errorMessage: 'Can only complete processing orders'
  });

const cancelOrder = (order: Order): Order =>
  transitionOrderStatus(order, {
    from: 'pending',
    to: 'cancelled',
    errorMessage: 'Can only cancel pending orders'
  });

export {
  createOrder,
  processOrder,
  completeOrder,
  cancelOrder,
  OrderSchema,
  OrderItemSchema
};
export type { Order, OrderItem };
```

**Run tests:** ✅ All still pass (behavior unchanged)

**Refactoring benefits:**
- Single source of truth for status transitions
- Easier to add new transitions
- Consistent error handling
- Less code to maintain

---

## Iteration 5: Test Factories

### Refactor: Create Test Factories

Our tests have duplication in order creation. Let's extract factory functions.

```typescript
// order.test-factory.ts
import { type Order, type OrderItem } from './order';

type OrderItemOverrides = Partial<OrderItem>;
type OrderOverrides = Partial<{
  customerId: string;
  items: OrderItem[];
}>;

const createTestOrderItem = (overrides?: OrderItemOverrides): OrderItem => ({
  productId: 'prod-default',
  quantity: 1,
  unitPrice: 10.00,
  ...overrides
});

const createTestOrderInput = (overrides?: OrderOverrides) => ({
  customerId: 'cust-default',
  items: [createTestOrderItem()],
  ...overrides
});

export { createTestOrderItem, createTestOrderInput };
```

```typescript
// order.test.ts (refactored with factories)
import { describe, it, expect } from 'vitest';
import { createOrder, processOrder, completeOrder, cancelOrder } from './order';
import { createTestOrderInput, createTestOrderItem } from './order.test-factory';

describe('Order Processing', () => {
  it('should create a valid order with items', () => {
    const order = createOrder(
      createTestOrderInput({
        customerId: 'cust-123',
        items: [createTestOrderItem({ productId: 'prod-1', quantity: 2 })]
      })
    );

    expect(order.id).toBeDefined();
    expect(order.customerId).toBe('cust-123');
    expect(order.items).toHaveLength(1);
    expect(order.status).toBe('pending');
    expect(order.total).toBe(20.00);
    expect(order.createdAt).toBeInstanceOf(Date);
  });

  it('should throw error for empty items array', () => {
    expect(() =>
      createOrder(createTestOrderInput({ items: [] }))
    ).toThrow();
  });

  it('should throw error for negative quantities', () => {
    expect(() =>
      createOrder(
        createTestOrderInput({
          items: [createTestOrderItem({ quantity: -1 })]
        })
      )
    ).toThrow();
  });

  it('should process a pending order', () => {
    const order = createOrder(createTestOrderInput());
    const processed = processOrder(order);

    expect(processed.status).toBe('processing');
    expect(processed.id).toBe(order.id);
  });

  it('should complete a processing order', () => {
    const order = createOrder(createTestOrderInput());
    const processing = processOrder(order);
    const completed = completeOrder(processing);

    expect(completed.status).toBe('completed');
  });

  it('should cancel a pending order', () => {
    const order = createOrder(createTestOrderInput());
    const cancelled = cancelOrder(order);

    expect(cancelled.status).toBe('cancelled');
  });
});
```

**Benefits:**
- Tests focus on what's being tested (overrides highlight intent)
- Reduced duplication in test setup
- Easy to add new default values
- Tests remain readable and maintainable

---

## Complete Final Code

### order.ts
```typescript
import { z } from 'zod';

// Schema-first design
const OrderItemSchema = z.object({
  productId: z.string().min(1),
  quantity: z.number().int().positive(),
  unitPrice: z.number().positive()
});

const OrderSchema = z.object({
  id: z.string(),
  customerId: z.string().min(1),
  items: z.array(OrderItemSchema).min(1),
  status: z.enum(['pending', 'processing', 'completed', 'cancelled']),
  total: z.number().nonnegative(),
  createdAt: z.date()
});

type OrderItem = z.infer<typeof OrderItemSchema>;
type Order = z.infer<typeof OrderSchema>;
type OrderStatus = Order['status'];

type CreateOrderInput = {
  customerId: string;
  items: OrderItem[];
};

type StatusTransition = {
  from: OrderStatus;
  to: OrderStatus;
  errorMessage: string;
};

const createOrder = (input: CreateOrderInput): Order => {
  const total = input.items.reduce(
    (sum, item) => sum + (item.quantity * item.unitPrice),
    0
  );

  const order = {
    id: `order-${Date.now()}`,
    customerId: input.customerId,
    items: input.items,
    status: 'pending' as const,
    total,
    createdAt: new Date()
  };

  return OrderSchema.parse(order);
};

const transitionOrderStatus = (
  order: Order,
  transition: StatusTransition
): Order => {
  if (order.status !== transition.from) {
    throw new Error(transition.errorMessage);
  }

  const updated = {
    ...order,
    status: transition.to
  };

  return OrderSchema.parse(updated);
};

const processOrder = (order: Order): Order =>
  transitionOrderStatus(order, {
    from: 'pending',
    to: 'processing',
    errorMessage: 'Can only process pending orders'
  });

const completeOrder = (order: Order): Order =>
  transitionOrderStatus(order, {
    from: 'processing',
    to: 'completed',
    errorMessage: 'Can only complete processing orders'
  });

const cancelOrder = (order: Order): Order =>
  transitionOrderStatus(order, {
    from: 'pending',
    to: 'cancelled',
    errorMessage: 'Can only cancel pending orders'
  });

export {
  createOrder,
  processOrder,
  completeOrder,
  cancelOrder,
  OrderSchema,
  OrderItemSchema
};
export type { Order, OrderItem };
```

---

## Key Takeaways

1. **Red-Green-Refactor Cycle:**
   - Red: Write failing test first
   - Green: Minimum code to pass
   - Refactor: Assess and improve (only when valuable)

2. **Schema-First Design:**
   - Define Zod schemas before types
   - Derive types from schemas
   - Schema validation catches edge cases automatically

3. **Behavioral Testing:**
   - Test through public API only
   - Focus on observable outcomes
   - Don't test implementation details

4. **Refactoring Discipline:**
   - Wait for patterns to emerge (Rule of Three)
   - Extract structural duplication (not semantic)
   - Keep tests passing throughout

5. **Factory Functions:**
   - Reduce test duplication
   - Make test intent clear through overrides
   - Maintain readability and maintainability
