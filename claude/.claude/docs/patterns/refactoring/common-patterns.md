# Common Refactoring Patterns

This guide covers the most frequently useful refactoring patterns with step-by-step examples.

---

## Extract Function

### When to Apply

- Function is too long (>20 lines for complex logic)
- Function mixes abstraction levels
- Section of code has a clear, distinct purpose
- Code section could benefit from descriptive naming

### Pattern

Extract cohesive blocks of code into well-named functions:

```typescript
// BEFORE: Mixed abstraction levels
const processOrder = (order: Order): ProcessedOrder => {
  // Low-level calculation details
  const itemsTotal = order.items.reduce(
    (sum, item) => sum + item.price * item.quantity,
    0
  );

  // Business rule buried in implementation
  const shippingCost = itemsTotal > 50 ? 0 : order.shippingCost;

  return { ...order, shippingCost, total: itemsTotal + shippingCost };
};

// AFTER: Clear abstraction levels
const calculateItemsTotal = (items: OrderItem[]): number => {
  return items.reduce((sum, item) => sum + item.price * item.quantity, 0);
};

const determineShippingCost = (itemsTotal: number, standardCost: number): number => {
  const FREE_SHIPPING_THRESHOLD = 50;
  return itemsTotal > FREE_SHIPPING_THRESHOLD ? 0 : standardCost;
};

const processOrder = (order: Order): ProcessedOrder => {
  const itemsTotal = calculateItemsTotal(order.items);
  const shippingCost = determineShippingCost(itemsTotal, order.shippingCost);
  return { ...order, shippingCost, total: itemsTotal + shippingCost };
};
```

### Benefits

- Each function has single, clear purpose
- Function names document what code does
- Easier to test each piece independently
- Reusable components emerge naturally

---

## Extract Constant

### When to Apply

- Magic numbers appear in code
- String literals used repeatedly
- Configuration values hardcoded
- Business rules expressed as literals

### Pattern

Replace literals with well-named constants:

```typescript
// BEFORE: Magic numbers
const calculateShipping = (weight: number, distance: number): number => {
  if (weight > 20) return distance * 2.5;
  if (distance > 500) return 15.99;
  return 9.99;
};

const validatePayment = (amount: number): boolean => {
  return amount > 0 && amount <= 10000;
};

// AFTER: Named constants
const HEAVY_ITEM_THRESHOLD_KG = 20;
const HEAVY_ITEM_RATE_PER_KM = 2.5;
const LONG_DISTANCE_THRESHOLD_KM = 500;
const LONG_DISTANCE_FLAT_RATE = 15.99;
const STANDARD_SHIPPING_RATE = 9.99;

const MAX_PAYMENT_AMOUNT = 10000;

const calculateShipping = (weight: number, distance: number): number => {
  if (weight > HEAVY_ITEM_THRESHOLD_KG) {
    return distance * HEAVY_ITEM_RATE_PER_KM;
  }

  if (distance > LONG_DISTANCE_THRESHOLD_KM) {
    return LONG_DISTANCE_FLAT_RATE;
  }

  return STANDARD_SHIPPING_RATE;
};

const validatePayment = (amount: number): boolean => {
  return amount > 0 && amount <= MAX_PAYMENT_AMOUNT;
};
```

### Benefits

- Business rules self-documenting
- Single place to update values
- Intent explicit in code
- Configuration centralized

---

## Replace Conditional with Polymorphism

### When to Apply

- Complex if/else chains based on type
- Switch statements on type field
- Same operation with type-specific behavior
- Behavior selection based on category

### Pattern: Strategy Pattern

Replace type-based conditionals with polymorphic strategy objects:

```typescript
// BEFORE: Type-based conditionals
const calculateDiscount = (customer: Customer, amount: number): number => {
  if (customer.type === "premium") {
    return amount * 0.2;
  } else if (customer.type === "regular") {
    return amount * 0.1;
  } else if (customer.type === "guest") {
    return 0;
  } else {
    throw new Error("Unknown customer type");
  }
};

const calculateShippingCost = (customer: Customer, weight: number): number => {
  if (customer.type === "premium") {
    return 0; // Free shipping
  } else if (customer.type === "regular") {
    return weight * 0.5;
  } else {
    return weight * 1.0;
  }
};

// AFTER: Strategy pattern
type CustomerType = "premium" | "regular" | "guest";

type CustomerStrategy = {
  calculateDiscount: (amount: number) => number;
  calculateShippingCost: (weight: number) => number;
};

const premiumStrategy: CustomerStrategy = {
  calculateDiscount: (amount) => amount * 0.2,
  calculateShippingCost: () => 0, // Free shipping
};

const regularStrategy: CustomerStrategy = {
  calculateDiscount: (amount) => amount * 0.1,
  calculateShippingCost: (weight) => weight * 0.5,
};

const guestStrategy: CustomerStrategy = {
  calculateDiscount: () => 0,
  calculateShippingCost: (weight) => weight * 1.0,
};

const customerStrategies: Record<CustomerType, CustomerStrategy> = {
  premium: premiumStrategy,
  regular: regularStrategy,
  guest: guestStrategy,
};

const getCustomerStrategy = (type: CustomerType): CustomerStrategy => {
  return customerStrategies[type];
};

// Usage - clean and extensible
const strategy = getCustomerStrategy(customer.type);
const discount = strategy.calculateDiscount(amount);
const shippingCost = strategy.calculateShippingCost(weight);
```

### Benefits

- Adding new types requires no conditional changes
- Each strategy isolated and testable
- Type-specific behavior grouped together
- Open-closed principle: open for extension, closed for modification

---

## Replace Nested Conditionals with Guard Clauses

### When to Apply

- Deeply nested if statements (>2 levels)
- Error conditions checked throughout function
- Multiple exit conditions
- Hard to follow control flow

### Pattern

Use early returns to flatten structure:

```typescript
// BEFORE: Nested conditionals
const processRefund = (order: Order, reason: string): Refund => {
  if (order.status === "completed") {
    if (order.paidAmount > 0) {
      if (reason.length > 10) {
        if (order.refundable) {
          // Actual processing logic buried 4 levels deep
          return createRefund(order, reason);
        } else {
          throw new Error("Order not refundable");
        }
      } else {
        throw new Error("Reason too short");
      }
    } else {
      throw new Error("No payment to refund");
    }
  } else {
    throw new Error("Order not completed");
  }
};

// AFTER: Guard clauses
const processRefund = (order: Order, reason: string): Refund => {
  // Error conditions checked first with early returns
  if (order.status !== "completed") {
    throw new Error("Order not completed");
  }

  if (order.paidAmount <= 0) {
    throw new Error("No payment to refund");
  }

  if (reason.length <= 10) {
    throw new Error("Reason too short");
  }

  if (!order.refundable) {
    throw new Error("Order not refundable");
  }

  // Happy path at top level - easy to find
  return createRefund(order, reason);
};
```

### Benefits

- Linear control flow
- Error conditions explicit and upfront
- Happy path clearly visible
- Each condition independently understandable

---

## Replace Type Code with Discriminated Union

### When to Apply

- String/number literals represent distinct types
- Type-specific fields exist
- Type checking needed at runtime
- Polymorphic behavior based on type

### Pattern

Use TypeScript discriminated unions for type-safe polymorphism:

```typescript
// BEFORE: Weak typing with optional fields
type Payment = {
  type: string;
  amount: number;
  // Credit card specific
  cardNumber?: string;
  expiryDate?: string;
  cvv?: string;
  // Bank transfer specific
  accountNumber?: string;
  routingNumber?: string;
  // Crypto specific
  walletAddress?: string;
  network?: string;
};

const processPayment = (payment: Payment): ProcessedPayment => {
  if (payment.type === "credit_card") {
    // TypeScript can't verify cardNumber exists
    validateCard(payment.cardNumber!, payment.cvv!);
  } else if (payment.type === "bank_transfer") {
    validateBankAccount(payment.accountNumber!, payment.routingNumber!);
  }
  // ... more conditionals
};

// AFTER: Discriminated union
type CreditCardPayment = {
  type: "credit_card";
  amount: number;
  cardNumber: string;
  expiryDate: string;
  cvv: string;
};

type BankTransferPayment = {
  type: "bank_transfer";
  amount: number;
  accountNumber: string;
  routingNumber: string;
};

type CryptoPayment = {
  type: "crypto";
  amount: number;
  walletAddress: string;
  network: string;
};

type Payment = CreditCardPayment | BankTransferPayment | CryptoPayment;

const processPayment = (payment: Payment): ProcessedPayment => {
  switch (payment.type) {
    case "credit_card":
      // TypeScript knows payment is CreditCardPayment here
      validateCard(payment.cardNumber, payment.cvv);
      return processCreditCard(payment);

    case "bank_transfer":
      // TypeScript knows payment is BankTransferPayment here
      validateBankAccount(payment.accountNumber, payment.routingNumber);
      return processBankTransfer(payment);

    case "crypto":
      // TypeScript knows payment is CryptoPayment here
      validateWallet(payment.walletAddress, payment.network);
      return processCrypto(payment);

    default:
      // TypeScript ensures exhaustiveness
      const exhaustiveCheck: never = payment;
      throw new Error(`Unknown payment type: ${exhaustiveCheck}`);
  }
};

// Type-specific processors with correct types
const processCreditCard = (payment: CreditCardPayment): ProcessedPayment => {
  // All credit card fields available without type assertions
  return {
    transactionId: generateId(),
    amount: payment.amount,
    last4: payment.cardNumber.slice(-4),
  };
};
```

### Benefits

- Type safety - no optional fields or type assertions
- Exhaustiveness checking - TypeScript ensures all cases handled
- Impossible states impossible - can't have cardNumber on bank_transfer
- IntelliSense support for type-specific fields

---

## Introduce Parameter Object

### When to Apply

- Functions take many parameters (>3)
- Same group of parameters passed together
- Parameters represent cohesive concept
- Adding related parameters frequently

### Pattern

Group related parameters into typed object:

```typescript
// BEFORE: Parameter soup
const createUser = (
  firstName: string,
  lastName: string,
  email: string,
  street: string,
  city: string,
  state: string,
  zipCode: string,
  country: string,
  phoneNumber: string
): User => {
  // Implementation
};

// AFTER: Parameter object
type PersonalInfo = {
  firstName: string;
  lastName: string;
  email: string;
  phoneNumber: string;
};

type Address = {
  street: string;
  city: string;
  state: string;
  zipCode: string;
  country: string;
};

type CreateUserParams = {
  personalInfo: PersonalInfo;
  address: Address;
};

const createUser = (params: CreateUserParams): User => {
  const { personalInfo, address } = params;
  // Implementation with grouped, meaningful parameters
};

// Usage
const user = createUser({
  personalInfo: {
    firstName: "John",
    lastName: "Doe",
    email: "john@example.com",
    phoneNumber: "555-1234",
  },
  address: {
    street: "123 Main St",
    city: "Springfield",
    state: "IL",
    zipCode: "62701",
    country: "USA",
  },
});
```

### Benefits

- Parameters organized by concept
- Easy to add related parameters
- Reusable parameter types
- Named parameters improve call sites

---

## Replace Loop with Pipeline

### When to Apply

- Loop performs multiple transformations
- Temporary variables accumulate
- Imperative-style collection processing
- Complex filtering and mapping

### Pattern

Use functional pipeline (map, filter, reduce):

```typescript
// BEFORE: Imperative loop
const processOrders = (orders: Order[]): OrderSummary[] => {
  const results: OrderSummary[] = [];

  for (const order of orders) {
    if (order.status === "completed") {
      if (order.total > 100) {
        const summary = {
          id: order.id,
          customerName: order.customer.name,
          total: order.total,
          discountApplied: order.total * 0.1,
        };
        results.push(summary);
      }
    }
  }

  return results;
};

// AFTER: Functional pipeline
const processOrders = (orders: Order[]): OrderSummary[] => {
  return orders
    .filter((order) => order.status === "completed")
    .filter((order) => order.total > 100)
    .map((order) => ({
      id: order.id,
      customerName: order.customer.name,
      total: order.total,
      discountApplied: order.total * 0.1,
    }));
};

// Even better: Extract steps for clarity
const isCompleted = (order: Order): boolean => order.status === "completed";
const isHighValue = (order: Order): boolean => order.total > 100;
const toSummary = (order: Order): OrderSummary => ({
  id: order.id,
  customerName: order.customer.name,
  total: order.total,
  discountApplied: order.total * 0.1,
});

const processOrders = (orders: Order[]): OrderSummary[] => {
  return orders.filter(isCompleted).filter(isHighValue).map(toSummary);
};
```

### Benefits

- Declarative - says what, not how
- Each step independently understandable
- Easy to add/remove/reorder transformations
- Immutable - no temporary variables

---

## Summary

Common refactoring patterns:

1. **Extract Function** - Break long functions into focused pieces
2. **Extract Constant** - Name magic numbers and strings
3. **Replace Conditional with Polymorphism** - Use strategy pattern for type-based behavior
4. **Replace Nested Conditionals** - Flatten with guard clauses
5. **Replace Type Code with Discriminated Union** - Type-safe polymorphism
6. **Introduce Parameter Object** - Group related parameters
7. **Replace Loop with Pipeline** - Functional transformations

**Remember**: Apply patterns when they improve the code, not for their own sake. The goal is clarity, maintainability, and correctness - not following patterns blindly.
