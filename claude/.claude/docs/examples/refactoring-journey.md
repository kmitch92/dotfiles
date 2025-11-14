# Refactoring Journey - From Poor to Good Code

This guide demonstrates progressive refactoring through multiple steps, showing WHY each change improves the code. All examples include complete, working code at each stage.

## Example 1: User Registration Flow

### Step 0: Poor Code (Starting Point)

```typescript
// user-registration.ts - BEFORE
import { z } from 'zod';

const UserSchema = z.object({
  id: z.string(),
  email: z.string().email(),
  username: z.string(),
  password: z.string(),
  isActive: z.boolean(),
  createdAt: z.date()
});

type User = z.infer<typeof UserSchema>;

function registerUser(email: string, username: string, password: string) {
  // Validation
  if (!email || email.length === 0) {
    throw new Error('Email is required');
  }
  if (!email.includes('@')) {
    throw new Error('Invalid email format');
  }
  if (!username || username.length < 3) {
    throw new Error('Username must be at least 3 characters');
  }
  if (username.length > 20) {
    throw new Error('Username must be at most 20 characters');
  }
  if (!password || password.length < 8) {
    throw new Error('Password must be at least 8 characters');
  }
  if (!/[A-Z]/.test(password)) {
    throw new Error('Password must contain uppercase letter');
  }
  if (!/[a-z]/.test(password)) {
    throw new Error('Password must contain lowercase letter');
  }
  if (!/[0-9]/.test(password)) {
    throw new Error('Password must contain number');
  }

  // Normalize email
  const normalizedEmail = email.toLowerCase().trim();

  // Check if user exists
  const existing = findUserByEmail(normalizedEmail);
  if (existing !== null) {
    throw new Error('User already exists');
  }

  // Hash password
  const hashedPassword = hashPassword(password);

  // Create user
  const user = {
    id: generateId(),
    email: normalizedEmail,
    username: username.trim(),
    password: hashedPassword,
    isActive: true,
    createdAt: new Date()
  };

  // Save to database
  saveUser(user);

  // Send welcome email
  sendEmail(user.email, 'Welcome!', 'Thanks for registering');

  return user;
}

// Mock implementations
function findUserByEmail(email: string): User | null { return null; }
function hashPassword(password: string): string { return 'hashed'; }
function generateId(): string { return 'id-123'; }
function saveUser(user: User): void {}
function sendEmail(to: string, subject: string, body: string): void {}
```

**Problems:**
- Manual validation instead of using schemas
- Nested conditionals (guard clauses needed)
- Multiple responsibilities (validation, normalization, persistence, email)
- No separation of concerns
- Hard to test
- Side effects mixed with logic

---

### Step 1: Use Schema for Validation

**Refactoring:** Replace manual validation with Zod schema validation

```typescript
// user-registration.ts - STEP 1
import { z } from 'zod';

const UserSchema = z.object({
  id: z.string(),
  email: z.string().email().transform(e => e.toLowerCase().trim()),
  username: z.string().min(3).max(20).transform(u => u.trim()),
  password: z.string(),
  isActive: z.boolean(),
  createdAt: z.date()
});

const RegisterUserInputSchema = z.object({
  email: z.string().email(),
  username: z.string().min(3).max(20),
  password: z.string()
    .min(8)
    .regex(/[A-Z]/, 'Password must contain uppercase letter')
    .regex(/[a-z]/, 'Password must contain lowercase letter')
    .regex(/[0-9]/, 'Password must contain number')
});

type User = z.infer<typeof UserSchema>;
type RegisterUserInput = z.infer<typeof RegisterUserInputSchema>;

function registerUser(input: RegisterUserInput) {
  // Validation happens automatically via schema
  const validated = RegisterUserInputSchema.parse(input);

  // Check if user exists
  const existing = findUserByEmail(validated.email.toLowerCase().trim());
  if (existing !== null) {
    throw new Error('User already exists');
  }

  // Hash password
  const hashedPassword = hashPassword(validated.password);

  // Create user
  const user = {
    id: generateId(),
    email: validated.email.toLowerCase().trim(),
    username: validated.username.trim(),
    password: hashedPassword,
    isActive: true,
    createdAt: new Date()
  };

  // Save to database
  saveUser(user);

  // Send welcome email
  sendEmail(user.email, 'Welcome!', 'Thanks for registering');

  return user;
}

// Mock implementations
function findUserByEmail(email: string): User | null { return null; }
function hashPassword(password: string): string { return 'hashed'; }
function generateId(): string { return 'id-123'; }
function saveUser(user: User): void {}
function sendEmail(to: string, subject: string, body: string): void {}
```

**Improvements:**
- Removed 15 lines of manual validation
- Schema provides single source of truth
- Validation errors are consistent and clear
- Normalization happens in schema transforms

**Why better:**
Schema-first design centralizes validation logic, making it reusable and eliminating duplication.

---

### Step 2: Extract Early Returns (Guard Clauses)

**Refactoring:** Move existence check earlier, use guard clause pattern

```typescript
// user-registration.ts - STEP 2
import { z } from 'zod';

const UserSchema = z.object({
  id: z.string(),
  email: z.string().email().transform(e => e.toLowerCase().trim()),
  username: z.string().min(3).max(20).transform(u => u.trim()),
  password: z.string(),
  isActive: z.boolean(),
  createdAt: z.date()
});

const RegisterUserInputSchema = z.object({
  email: z.string().email(),
  username: z.string().min(3).max(20),
  password: z.string()
    .min(8)
    .regex(/[A-Z]/, 'Password must contain uppercase letter')
    .regex(/[a-z]/, 'Password must contain lowercase letter')
    .regex(/[0-9]/, 'Password must contain number')
});

type User = z.infer<typeof UserSchema>;
type RegisterUserInput = z.infer<typeof RegisterUserInputSchema>;

function registerUser(input: RegisterUserInput) {
  const validated = RegisterUserInputSchema.parse(input);
  const normalizedEmail = validated.email.toLowerCase().trim();

  // Guard clause: check early and exit
  const existing = findUserByEmail(normalizedEmail);
  if (existing !== null) {
    throw new Error('User already exists');
  }

  const hashedPassword = hashPassword(validated.password);

  const user = {
    id: generateId(),
    email: normalizedEmail,
    username: validated.username.trim(),
    password: hashedPassword,
    isActive: true,
    createdAt: new Date()
  };

  saveUser(user);
  sendEmail(user.email, 'Welcome!', 'Thanks for registering');

  return user;
}

// Mock implementations
function findUserByEmail(email: string): User | null { return null; }
function hashPassword(password: string): string { return 'hashed'; }
function generateId(): string { return 'id-123'; }
function saveUser(user: User): void {}
function sendEmail(to: string, subject: string, body: string): void {}
```

**Improvements:**
- Early exit on error condition
- Reduced nesting depth
- Main logic flow is clearer

**Why better:**
Guard clauses reduce cognitive load by handling edge cases upfront, leaving the happy path unnested.

---

### Step 3: Extract Functions (Single Responsibility)

**Refactoring:** Separate concerns into focused functions

```typescript
// user-registration.ts - STEP 3
import { z } from 'zod';

const UserSchema = z.object({
  id: z.string(),
  email: z.string().email().transform(e => e.toLowerCase().trim()),
  username: z.string().min(3).max(20).transform(u => u.trim()),
  password: z.string(),
  isActive: z.boolean(),
  createdAt: z.date()
});

const RegisterUserInputSchema = z.object({
  email: z.string().email(),
  username: z.string().min(3).max(20),
  password: z.string()
    .min(8)
    .regex(/[A-Z]/, 'Password must contain uppercase letter')
    .regex(/[a-z]/, 'Password must contain lowercase letter')
    .regex(/[0-9]/, 'Password must contain number')
});

type User = z.infer<typeof UserSchema>;
type RegisterUserInput = z.infer<typeof RegisterUserInputSchema>;

// Pure function: validate uniqueness
function ensureEmailUnique(email: string): void {
  const existing = findUserByEmail(email);
  if (existing !== null) {
    throw new Error('User already exists');
  }
}

// Pure function: create user entity
function createUserEntity(input: RegisterUserInput, hashedPassword: string): User {
  return {
    id: generateId(),
    email: input.email.toLowerCase().trim(),
    username: input.username.trim(),
    password: hashedPassword,
    isActive: true,
    createdAt: new Date()
  };
}

// Pure function: send welcome notification
function sendWelcomeNotification(email: string): void {
  sendEmail(email, 'Welcome!', 'Thanks for registering');
}

// Orchestrator function: coordinates the flow
function registerUser(input: RegisterUserInput): User {
  const validated = RegisterUserInputSchema.parse(input);
  const normalizedEmail = validated.email.toLowerCase().trim();

  ensureEmailUnique(normalizedEmail);

  const hashedPassword = hashPassword(validated.password);
  const user = createUserEntity(validated, hashedPassword);

  saveUser(user);
  sendWelcomeNotification(user.email);

  return user;
}

// Mock implementations
function findUserByEmail(email: string): User | null { return null; }
function hashPassword(password: string): string { return 'hashed'; }
function generateId(): string { return 'id-123'; }
function saveUser(user: User): void {}
function sendEmail(to: string, subject: string, body: string): void {}
```

**Improvements:**
- Each function has single responsibility
- `registerUser` is now a readable orchestrator
- Functions can be tested independently
- Side effects are isolated

**Why better:**
Single Responsibility Principle makes code easier to understand, test, and modify. Each function does one thing well.

---

### Step 4: Dependency Injection (Testability)

**Refactoring:** Inject dependencies to enable testing and flexibility

```typescript
// user-registration.ts - STEP 4 (FINAL)
import { z } from 'zod';

const UserSchema = z.object({
  id: z.string(),
  email: z.string().email().transform(e => e.toLowerCase().trim()),
  username: z.string().min(3).max(20).transform(u => u.trim()),
  password: z.string(),
  isActive: z.boolean(),
  createdAt: z.date()
});

const RegisterUserInputSchema = z.object({
  email: z.string().email(),
  username: z.string().min(3).max(20),
  password: z.string()
    .min(8)
    .regex(/[A-Z]/, 'Password must contain uppercase letter')
    .regex(/[a-z]/, 'Password must contain lowercase letter')
    .regex(/[0-9]/, 'Password must contain number')
});

type User = z.infer<typeof UserSchema>;
type RegisterUserInput = z.infer<typeof RegisterUserInputSchema>;

// Dependencies interface
type UserRepository = {
  findByEmail: (email: string) => User | null;
  save: (user: User) => void;
};

type PasswordHasher = {
  hash: (password: string) => string;
};

type EmailService = {
  send: (to: string, subject: string, body: string) => void;
};

type IdGenerator = {
  generate: () => string;
};

// Pure functions (no external dependencies)
function ensureEmailUnique(email: string, repository: UserRepository): void {
  const existing = repository.findByEmail(email);
  if (existing !== null) {
    throw new Error('User already exists');
  }
}

function createUserEntity(
  input: RegisterUserInput,
  hashedPassword: string,
  idGenerator: IdGenerator
): User {
  return {
    id: idGenerator.generate(),
    email: input.email.toLowerCase().trim(),
    username: input.username.trim(),
    password: hashedPassword,
    isActive: true,
    createdAt: new Date()
  };
}

function sendWelcomeNotification(email: string, emailService: EmailService): void {
  emailService.send(email, 'Welcome!', 'Thanks for registering');
}

// Factory function: returns configured registration function
function createRegisterUser(
  repository: UserRepository,
  hasher: PasswordHasher,
  emailService: EmailService,
  idGenerator: IdGenerator
) {
  return (input: RegisterUserInput): User => {
    const validated = RegisterUserInputSchema.parse(input);
    const normalizedEmail = validated.email.toLowerCase().trim();

    ensureEmailUnique(normalizedEmail, repository);

    const hashedPassword = hasher.hash(validated.password);
    const user = createUserEntity(validated, hashedPassword, idGenerator);

    repository.save(user);
    sendWelcomeNotification(user.email, emailService);

    return user;
  };
}

// Production dependencies
const productionDependencies = {
  repository: {
    findByEmail: (email: string) => null,
    save: (user: User) => {}
  },
  hasher: {
    hash: (password: string) => 'hashed'
  },
  emailService: {
    send: (to: string, subject: string, body: string) => {}
  },
  idGenerator: {
    generate: () => `id-${Date.now()}`
  }
};

// Configured production function
const registerUser = createRegisterUser(
  productionDependencies.repository,
  productionDependencies.hasher,
  productionDependencies.emailService,
  productionDependencies.idGenerator
);

export { registerUser, createRegisterUser, RegisterUserInputSchema };
export type { User, RegisterUserInput, UserRepository, PasswordHasher, EmailService, IdGenerator };
```

**Test Example:**

```typescript
// user-registration.test.ts
import { describe, it, expect, vi } from 'vitest';
import { createRegisterUser, type UserRepository, type PasswordHasher, type EmailService, type IdGenerator } from './user-registration';

describe('User Registration', () => {
  it('should register new user with valid input', () => {
    // Mock dependencies
    const mockRepository: UserRepository = {
      findByEmail: vi.fn(() => null),
      save: vi.fn()
    };

    const mockHasher: PasswordHasher = {
      hash: vi.fn(() => 'hashed-password')
    };

    const mockEmailService: EmailService = {
      send: vi.fn()
    };

    const mockIdGenerator: IdGenerator = {
      generate: vi.fn(() => 'test-id-123')
    };

    // Create testable function
    const registerUser = createRegisterUser(
      mockRepository,
      mockHasher,
      mockEmailService,
      mockIdGenerator
    );

    // Execute
    const user = registerUser({
      email: 'TEST@EXAMPLE.COM',
      username: 'testuser',
      password: 'SecurePass1'
    });

    // Assert
    expect(user.id).toBe('test-id-123');
    expect(user.email).toBe('test@example.com'); // normalized
    expect(user.username).toBe('testuser');
    expect(mockRepository.findByEmail).toHaveBeenCalledWith('test@example.com');
    expect(mockHasher.hash).toHaveBeenCalledWith('SecurePass1');
    expect(mockRepository.save).toHaveBeenCalledWith(user);
    expect(mockEmailService.send).toHaveBeenCalledWith(
      'test@example.com',
      'Welcome!',
      'Thanks for registering'
    );
  });

  it('should throw error when user already exists', () => {
    const mockRepository: UserRepository = {
      findByEmail: vi.fn(() => ({
        id: 'existing',
        email: 'test@example.com',
        username: 'existing',
        password: 'hashed',
        isActive: true,
        createdAt: new Date()
      })),
      save: vi.fn()
    };

    const registerUser = createRegisterUser(
      mockRepository,
      { hash: () => 'hashed' },
      { send: () => {} },
      { generate: () => 'id' }
    );

    expect(() =>
      registerUser({
        email: 'test@example.com',
        username: 'testuser',
        password: 'SecurePass1'
      })
    ).toThrow('User already exists');
  });
});
```

**Improvements:**
- Fully testable without real database, email service, etc.
- Dependencies are explicit and replaceable
- Easy to mock in tests
- Production and test configurations separate

**Why better:**
Dependency injection enables testing, makes dependencies explicit, and allows runtime configuration flexibility.

---

## Example 2: Avoiding DRY Semantic vs Structural Trap

### Poor Abstraction (Over-DRY)

```typescript
// BEFORE - Structural duplication extracted (BAD)
function processData(
  data: unknown[],
  validator: (item: unknown) => boolean,
  transformer: (item: unknown) => unknown,
  aggregator: (acc: unknown, item: unknown) => unknown,
  initialValue: unknown
): unknown {
  return data
    .filter(validator)
    .map(transformer)
    .reduce(aggregator, initialValue);
}

// Usage is confusing - what does this do?
const result1 = processData(
  orders,
  (o: any) => o.status === 'paid',
  (o: any) => o.total,
  (sum: number, total: number) => sum + total,
  0
);

const result2 = processData(
  users,
  (u: any) => u.isActive,
  (u: any) => u.email,
  (emails: string[], email: string) => [...emails, email],
  []
);
```

**Problems:**
- Abstraction hides intent
- Generic names provide no meaning
- Hard to understand what's happening
- Types are lost (using `unknown`)

---

### Good Semantic Separation (AFTER)

```typescript
// AFTER - Semantic functions (GOOD)
const OrderSchema = z.object({
  id: z.string(),
  status: z.enum(['pending', 'paid', 'shipped']),
  total: z.number()
});

const UserSchema = z.object({
  id: z.string(),
  email: z.string().email(),
  isActive: z.boolean()
});

type Order = z.infer<typeof OrderSchema>;
type User = z.infer<typeof UserSchema>;

// Each function has semantic meaning
function calculatePaidOrdersTotal(orders: Order[]): number {
  return orders
    .filter(order => order.status === 'paid')
    .reduce((sum, order) => sum + order.total, 0);
}

function getActiveUserEmails(users: User[]): string[] {
  return users
    .filter(user => user.isActive)
    .map(user => user.email);
}

// Usage is clear - intent is obvious
const totalRevenue = calculatePaidOrdersTotal(orders);
const activeEmails = getActiveUserEmails(users);
```

**Improvements:**
- Function names describe business intent
- Types are preserved
- Self-documenting code
- Easy to test and modify

**Why better:**
**Semantic duplication** (doing different things that happen to look similar) should NOT be extracted. **Structural duplication** (doing the same thing multiple times) should be extracted. Know the difference.

---

## Key Refactoring Takeaways

1. **Schema-First Design:**
   - Replace manual validation with schemas
   - Centralize validation logic
   - Use schema transformations for normalization

2. **Guard Clauses:**
   - Check error conditions early and exit
   - Reduce nesting depth
   - Make happy path obvious

3. **Single Responsibility:**
   - Each function does one thing
   - Easier to test, understand, modify
   - Orchestrator functions coordinate flow

4. **Dependency Injection:**
   - Make dependencies explicit
   - Enable testing without real services
   - Runtime configuration flexibility

5. **DRY Principle:**
   - Extract **structural** duplication (same logic repeated)
   - Keep **semantic** duplication (different purposes, similar structure)
   - Prioritize clarity over brevity

6. **Refactoring Process:**
   - Make small, incremental changes
   - Keep tests passing at each step
   - Assess value of each refactoring
   - Stop when code is clear and maintainable
