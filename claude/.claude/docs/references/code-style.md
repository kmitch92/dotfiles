# Code Style - Quick Reference

## Core Principles

1. **Immutability**: No data mutation
2. **Pure Functions**: Same input = same output
3. **Self-Documenting**: No comments needed
4. **Early Returns**: No deep nesting
5. **Small Functions**: Single responsibility

---

## Immutability Patterns

### Arrays

**✅ DO:**
```typescript
// Add items
const newArray = [...oldArray, newItem];
const newArray = oldArray.concat(newItem);

// Remove items
const filtered = array.filter(item => item.id !== removeId);

// Update items
const updated = array.map(item =>
  item.id === targetId
    ? { ...item, status: 'updated' }
    : item
);

// Combine operations
const result = array
  .filter(item => item.active)
  .map(item => ({ ...item, processed: true }));
```

**❌ DON'T:**
```typescript
// Never mutate arrays
array.push(item);           // ❌
array.pop();                // ❌
array.shift();              // ❌
array.unshift(item);        // ❌
array.splice(0, 1);         // ❌
array[0] = newValue;        // ❌
array.sort();               // ❌ (mutates)
array.reverse();            // ❌ (mutates)
```

### Objects

**✅ DO:**
```typescript
// Add/update properties
const updated = { ...original, newProp: 'value' };

// Remove properties
const { removeProp, ...rest } = original;

// Nested updates
const updated = {
  ...original,
  nested: {
    ...original.nested,
    property: 'new value'
  }
};

// Conditional properties
const obj = {
  ...baseProps,
  ...(condition && { conditionalProp: 'value' })
};
```

**❌ DON'T:**
```typescript
// Never mutate objects
obj.property = 'value';     // ❌
obj['key'] = 'value';       // ❌
delete obj.property;        // ❌
Object.assign(obj, updates); // ❌ (mutates first arg)
```

### Correct Object.assign Usage

**✅ DO:**
```typescript
// Create new object (first arg is empty object)
const merged = Object.assign({}, obj1, obj2);

// Prefer spread operator (clearer)
const merged = { ...obj1, ...obj2 };
```

---

## Functional Patterns

### Pure Functions

**✅ DO:**
```typescript
// Pure: same input = same output
function calculateTotal(items: Item[]): number {
  return items.reduce((sum, item) => sum + item.price, 0);
}

// Pure: no side effects
function formatUser(user: User): FormattedUser {
  return {
    fullName: `${user.firstName} ${user.lastName}`,
    displayEmail: user.email.toLowerCase()
  };
}
```

**❌ DON'T:**
```typescript
// Impure: depends on external state
function calculateTotal(items: Item[]): number {
  return items.reduce((sum, item) => sum + item.price, taxRate); // ❌ taxRate external
}

// Impure: has side effects
function formatUser(user: User): FormattedUser {
  console.log(user);  // ❌ side effect
  logToAnalytics(user); // ❌ side effect
  return { /* ... */ };
}
```

### Side Effects

**✅ DO:**
```typescript
// Isolate side effects
async function saveUser(user: User): Promise<void> {
  // Pure validation
  const errors = validateUser(user);
  if (errors.length > 0) {
    throw new ValidationError(errors);
  }

  // Side effect clearly isolated
  await database.users.insert(user);
}

// Make side effects explicit
function processOrder(order: Order): OrderResult {
  const validated = validateOrder(order);
  const calculated = calculateTotals(validated);

  // Side effects returned, not executed
  return {
    data: calculated,
    sideEffects: {
      sendEmail: () => emailService.send(order.email, calculated),
      logEvent: () => analytics.track('order_processed', calculated)
    }
  };
}
```

### Array Methods (Pure)

**✅ DO:**
```typescript
// Use pure array methods
const active = users.filter(u => u.active);
const names = users.map(u => u.name);
const total = items.reduce((sum, item) => sum + item.price, 0);
const hasAdmin = users.some(u => u.role === 'admin');
const allValid = items.every(item => item.valid);
const found = users.find(u => u.id === targetId);
```

**❌ DON'T:**
```typescript
// Don't use forEach for transformations
const names: string[] = [];
users.forEach(u => names.push(u.name)); // ❌ use .map()

// Don't mutate inside array methods
items.map(item => {
  item.processed = true; // ❌ mutation
  return item;
});
```

---

## Naming Conventions

### Functions

**✅ DO:**
```typescript
// Verbs for actions
function calculateTotal(items: Item[]): number
function validateUser(user: User): ValidationError[]
function formatDate(date: Date): string

// Boolean predicates: is/has/can/should
function isValid(user: User): boolean
function hasPermission(user: User, resource: Resource): boolean
function canAccess(user: User, resource: Resource): boolean

// Event handlers: handle/on prefix
function handleClick(event: MouseEvent): void
function onUserLogin(user: User): void
```

**❌ DON'T:**
```typescript
// Vague names
function doStuff(data: any): any        // ❌
function process(input: any): any       // ❌
function manager(x: any): any           // ❌

// Misleading names
function getUser(id: string): Promise<User>  // ❌ implies sync
function calculateTotal(items: Item[]): Promise<number> // ❌ implies async
```

### Types

**✅ DO:**
```typescript
// Nouns, PascalCase
type User = { /* ... */ };
type UserProfile = { /* ... */ };
type ValidationError = { /* ... */ };

// Descriptive, specific
type CreateUserRequest = { /* ... */ };
type UpdateUserResponse = { /* ... */ };
type UserPermissions = { /* ... */ };
```

**❌ DON'T:**
```typescript
// Generic names
type Data = { /* ... */ };      // ❌
type Info = { /* ... */ };      // ❌
type Item = { /* ... */ };      // ❌ (unless genuinely generic)

// Abbreviations
type UsrProf = { /* ... */ };   // ❌
type ValErr = { /* ... */ };    // ❌
```

### Constants

**✅ DO:**
```typescript
// UPPER_SNAKE_CASE for true constants
const MAX_RETRY_ATTEMPTS = 3;
const API_BASE_URL = 'https://api.example.com';
const DEFAULT_TIMEOUT_MS = 5000;

// camelCase for derived/computed constants
const defaultConfig = { /* ... */ };
const validationRules = { /* ... */ };
```

### Variables

**✅ DO:**
```typescript
// Descriptive, camelCase
const userProfile = getUserProfile(userId);
const validationErrors = validateInput(formData);
const isAuthenticated = checkAuth(token);

// Boolean: is/has/can/should prefix
const isValid = true;
const hasPermission = false;
const canEdit = true;
const shouldRetry = false;
```

**❌ DON'T:**
```typescript
// Single letter (except loop indices)
const u = getUser();     // ❌
const d = new Date();    // ❌
const x = calculate();   // ❌

// Abbreviations
const usr = getUser();   // ❌
const cfg = getConfig(); // ❌
const msg = getMessage(); // ❌
```

### Files

**✅ DO:**
```typescript
// kebab-case for files
user-service.ts
auth-middleware.ts
validation-utils.ts

// Match primary export
user-profile.tsx        // exports UserProfile component
calculate-total.ts      // exports calculateTotal function
```

---

## Structure Preferences

### Early Returns (Guard Clauses)

**✅ DO:**
```typescript
function processUser(user: User | null): ProcessedUser {
  if (!user) {
    throw new Error('User is required');
  }

  if (!user.active) {
    throw new Error('User is not active');
  }

  if (!user.email) {
    throw new Error('User email is required');
  }

  return {
    id: user.id,
    email: user.email,
    displayName: formatDisplayName(user)
  };
}
```

**❌ DON'T:**
```typescript
function processUser(user: User | null): ProcessedUser {
  if (user) {
    if (user.active) {
      if (user.email) {
        return {
          id: user.id,
          email: user.email,
          displayName: formatDisplayName(user)
        };
      } else {
        throw new Error('User email is required');
      }
    } else {
      throw new Error('User is not active');
    }
  } else {
    throw new Error('User is required');
  }
}
```

### No Deep Nesting (Max 2 Levels)

**✅ DO:**
```typescript
function processOrders(orders: Order[]): ProcessedOrder[] {
  return orders
    .filter(isValidOrder)
    .map(calculateTotals)
    .map(applyDiscounts);
}

function isValidOrder(order: Order): boolean {
  if (!order.items.length) return false;
  if (!order.customerId) return false;
  return true;
}
```

**❌ DON'T:**
```typescript
function processOrders(orders: Order[]): ProcessedOrder[] {
  const results: ProcessedOrder[] = [];

  for (const order of orders) {
    if (order.items.length > 0) {
      if (order.customerId) {
        let total = 0;
        for (const item of order.items) {
          if (item.price > 0) {
            total += item.price;
          }
        }
        results.push({ ...order, total });
      }
    }
  }

  return results;
}
```

### Extract Helper Functions

**✅ DO:**
```typescript
function createUser(request: CreateUserRequest): User {
  validateRequest(request);
  const hashedPassword = hashPassword(request.password);
  const user = buildUserObject(request, hashedPassword);
  return user;
}

function validateRequest(request: CreateUserRequest): void {
  if (!request.email) throw new Error('Email required');
  if (!request.password) throw new Error('Password required');
}

function hashPassword(password: string): string {
  return bcrypt.hashSync(password, 10);
}

function buildUserObject(request: CreateUserRequest, hashedPassword: string): User {
  return {
    id: generateId(),
    email: request.email,
    password: hashedPassword,
    createdAt: new Date()
  };
}
```

---

## Self-Documenting Code

### Function Names

**✅ DO:**
```typescript
// Name explains purpose
function calculateTotalWithTax(items: Item[], taxRate: number): number {
  const subtotal = items.reduce((sum, item) => sum + item.price, 0);
  return subtotal * (1 + taxRate);
}

function isEligibleForDiscount(user: User): boolean {
  return user.isPremium && user.ordersCount > 10;
}
```

**❌ DON'T:**
```typescript
// Name doesn't explain purpose
function calc(items: Item[], rate: number): number { // What is rate?
  const s = items.reduce((sum, item) => sum + item.price, 0);
  return s * (1 + rate);
}

// Comment needed = bad name
function check(user: User): boolean { // Check what?
  // Check if user is eligible for discount
  return user.isPremium && user.ordersCount > 10;
}
```

### Variable Names

**✅ DO:**
```typescript
const activeUsers = users.filter(u => u.active);
const totalPrice = items.reduce((sum, item) => sum + item.price, 0);
const isAdminUser = user.role === 'admin';
```

**❌ DON'T:**
```typescript
const a = users.filter(u => u.active);  // What is 'a'?
const t = items.reduce((sum, item) => sum + item.price, 0); // What is 't'?
const f = user.role === 'admin'; // What is 'f'?
```

### Type Definitions

**✅ DO:**
```typescript
type CreateUserRequest = {
  email: string;
  password: string;
  firstName: string;
  lastName: string;
};

type UserPermissions = {
  canRead: boolean;
  canWrite: boolean;
  canDelete: boolean;
};
```

**❌ DON'T:**
```typescript
type Request = { // Request for what?
  e: string;  // What is 'e'?
  p: string;  // What is 'p'?
  fn: string; // What is 'fn'?
  ln: string; // What is 'ln'?
};
```

---

## Function Parameters

### Options Object (>3 Parameters)

**✅ DO:**
```typescript
type CreateUserOptions = {
  email: string;
  password: string;
  firstName: string;
  lastName: string;
  role?: 'user' | 'admin';
  sendWelcomeEmail?: boolean;
};

function createUser(options: CreateUserOptions): User {
  const {
    email,
    password,
    firstName,
    lastName,
    role = 'user',
    sendWelcomeEmail = true
  } = options;

  // Implementation
}

// Usage: clear and self-documenting
createUser({
  email: 'user@example.com',
  password: 'secret',
  firstName: 'John',
  lastName: 'Doe',
  sendWelcomeEmail: false
});
```

**❌ DON'T:**
```typescript
function createUser(
  email: string,
  password: string,
  firstName: string,
  lastName: string,
  role?: string,
  sendWelcomeEmail?: boolean
): User {
  // Implementation
}

// Usage: unclear parameter order, easy to mix up
createUser('user@example.com', 'secret', 'John', 'Doe', undefined, false);
```

### Boolean Parameters

**✅ DO:**
```typescript
type FetchUsersOptions = {
  includeInactive?: boolean;
  includeDeleted?: boolean;
};

function fetchUsers(options: FetchUsersOptions = {}): User[] {
  // Implementation
}

// Usage: self-documenting
fetchUsers({ includeInactive: true });
```

**❌ DON'T:**
```typescript
function fetchUsers(includeInactive: boolean, includeDeleted: boolean): User[] {
  // Implementation
}

// Usage: unclear what true/false means
fetchUsers(true, false); // Which is which?
```

---

## TypeScript Preferences

### Use `type` Over `interface`

**✅ DO:**
```typescript
type User = {
  id: string;
  email: string;
  name: string;
};

type Admin = User & {
  permissions: string[];
};
```

**❌ DON'T (unless extending library interfaces):**
```typescript
interface User {
  id: string;
  email: string;
  name: string;
}

interface Admin extends User {
  permissions: string[];
}
```

### Avoid Type Assertions

**✅ DO:**
```typescript
// Use type guards
function isUser(value: unknown): value is User {
  return (
    typeof value === 'object' &&
    value !== null &&
    'id' in value &&
    'email' in value
  );
}

if (isUser(data)) {
  console.log(data.email); // TypeScript knows it's User
}
```

**❌ DON'T:**
```typescript
// Type assertion bypasses type checking
const user = data as User; // ❌ What if data isn't User?
```

### No `any` Types

**✅ DO:**
```typescript
// Use unknown for truly unknown types
function processData(data: unknown): ProcessedData {
  if (!isValidData(data)) {
    throw new Error('Invalid data');
  }
  return transformData(data);
}

// Use generics for reusable functions
function identity<T>(value: T): T {
  return value;
}
```

**❌ DON'T:**
```typescript
function processData(data: any): any { // ❌
  return data.something; // No type safety
}
```

---

## Quick Checklist

**Before committing, verify:**
- [ ] No data mutation (arrays, objects)
- [ ] Functions are pure (or side effects isolated)
- [ ] No nested conditionals (use early returns)
- [ ] No comments (code is self-documenting)
- [ ] Function/variable names describe purpose
- [ ] Functions <50 lines
- [ ] Max 2 levels of nesting
- [ ] No `any` types
- [ ] Prefer `type` over `interface`
- [ ] Options object for >3 parameters
- [ ] No boolean parameters (use options object)
