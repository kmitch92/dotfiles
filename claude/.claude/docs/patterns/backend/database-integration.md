# Database Integration Patterns

## Overview
This guide covers production-ready patterns for integrating databases (DynamoDB, RDS/Prisma, MongoDB) in Node.js/TypeScript applications.

## DynamoDB Client Patterns

### DocumentClient Best Practices
```typescript
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, PutCommand, GetCommand, QueryCommand } from '@aws-sdk/lib-dynamodb';

// Create base client
const client = new DynamoDBClient({
  region: process.env.AWS_REGION || 'us-east-1',
});

// Create DocumentClient with marshalling options
const dynamodb = DynamoDBDocumentClient.from(client, {
  marshallOptions: {
    removeUndefinedValues: true, // Remove undefined fields
    convertEmptyValues: false,   // Don't convert empty strings to null
  },
  unmarshallOptions: {
    wrapNumbers: false, // Return numbers as JS numbers (not BigInt)
  },
});

// Repository pattern
class UserRepository {
  private tableName = process.env.USERS_TABLE!;

  async create(user: CreateUserInput): Promise<User> {
    const item = {
      PK: `USER#${user.id}`,
      SK: 'PROFILE',
      ...user,
      createdAt: new Date().toISOString(),
    };

    await dynamodb.send(
      new PutCommand({
        TableName: this.tableName,
        Item: item,
        ConditionExpression: 'attribute_not_exists(PK)', // Prevent overwrites
      })
    );

    return item;
  }

  async findById(userId: string): Promise<User | null> {
    const result = await dynamodb.send(
      new GetCommand({
        TableName: this.tableName,
        Key: {
          PK: `USER#${userId}`,
          SK: 'PROFILE',
        },
      })
    );

    return result.Item as User | null;
  }

  async findByEmail(email: string): Promise<User | null> {
    const result = await dynamodb.send(
      new QueryCommand({
        TableName: this.tableName,
        IndexName: 'EmailIndex',
        KeyConditionExpression: 'email = :email',
        ExpressionAttributeValues: {
          ':email': email,
        },
        Limit: 1,
      })
    );

    return result.Items?.[0] as User | null;
  }

  async update(userId: string, updates: Partial<User>): Promise<User> {
    // Build update expression dynamically
    const updateExpression: string[] = [];
    const expressionAttributeNames: Record<string, string> = {};
    const expressionAttributeValues: Record<string, unknown> = {};

    Object.entries(updates).forEach(([key, value], index) => {
      updateExpression.push(`#${key} = :val${index}`);
      expressionAttributeNames[`#${key}`] = key;
      expressionAttributeValues[`:val${index}`] = value;
    });

    const result = await dynamodb.send(
      new UpdateCommand({
        TableName: this.tableName,
        Key: {
          PK: `USER#${userId}`,
          SK: 'PROFILE',
        },
        UpdateExpression: `SET ${updateExpression.join(', ')}`,
        ExpressionAttributeNames: expressionAttributeNames,
        ExpressionAttributeValues: expressionAttributeValues,
        ReturnValues: 'ALL_NEW',
      })
    );

    return result.Attributes as User;
  }
}
```

### Single-Table Design Pattern
```typescript
// Entity types in single table
type Entity =
  | { PK: `USER#${string}`; SK: 'PROFILE'; email: string; name: string }
  | { PK: `USER#${string}`; SK: `ORDER#${string}`; total: number; status: string }
  | { PK: `ORDER#${string}`; SK: 'METADATA'; userId: string; createdAt: string };

// Query all orders for user
async function getUserOrders(userId: string): Promise<Order[]> {
  const result = await dynamodb.send(
    new QueryCommand({
      TableName: 'app-table',
      KeyConditionExpression: 'PK = :pk AND begins_with(SK, :sk)',
      ExpressionAttributeValues: {
        ':pk': `USER#${userId}`,
        ':sk': 'ORDER#',
      },
    })
  );

  return result.Items as Order[];
}

// GSI for reverse lookup (find user by order)
async function findUserByOrder(orderId: string): Promise<User | null> {
  const result = await dynamodb.send(
    new QueryCommand({
      TableName: 'app-table',
      IndexName: 'GSI1', // GSI1PK = ORDER#123, GSI1SK = USER#456
      KeyConditionExpression: 'GSI1PK = :pk',
      ExpressionAttributeValues: {
        ':pk': `ORDER#${orderId}`,
      },
    })
  );

  return result.Items?.[0] as User | null;
}
```

### Pagination Pattern
```typescript
interface PaginatedResponse<T> {
  items: T[];
  nextToken?: string;
}

async function listUsers(limit = 20, nextToken?: string): Promise<PaginatedResponse<User>> {
  const result = await dynamodb.send(
    new QueryCommand({
      TableName: 'users-table',
      KeyConditionExpression: 'PK = :pk',
      ExpressionAttributeValues: { ':pk': 'USERS' },
      Limit: limit,
      ExclusiveStartKey: nextToken ? JSON.parse(Buffer.from(nextToken, 'base64').toString()) : undefined,
    })
  );

  return {
    items: result.Items as User[],
    nextToken: result.LastEvaluatedKey
      ? Buffer.from(JSON.stringify(result.LastEvaluatedKey)).toString('base64')
      : undefined,
  };
}
```

## RDS/Prisma Patterns

### Connection Management
```typescript
import { PrismaClient } from '@prisma/client';

// Singleton pattern for connection reuse
declare global {
  var prisma: PrismaClient | undefined;
}

export const prisma = global.prisma || new PrismaClient({
  log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
});

if (process.env.NODE_ENV !== 'production') {
  global.prisma = prisma;
}

// Graceful shutdown
process.on('beforeExit', async () => {
  await prisma.$disconnect();
});
```

### Lambda Connection Handling
```typescript
// Create client outside handler (reused across warm invocations)
const prisma = new PrismaClient({
  datasources: {
    db: {
      url: process.env.DATABASE_URL,
    },
  },
});

export const handler = async (event: APIGatewayEvent) => {
  try {
    // Use existing connection
    const users = await prisma.user.findMany();
    return { statusCode: 200, body: JSON.stringify(users) };
  } catch (error) {
    console.error(error);
    return { statusCode: 500, body: JSON.stringify({ error: 'Internal error' }) };
  }
  // Don't disconnect (reuse connection on next invocation)
};
```

### Migration Strategy
```typescript
// Run migrations in CI/CD, not in application code

// package.json scripts
{
  "scripts": {
    "prisma:generate": "prisma generate",
    "prisma:migrate:dev": "prisma migrate dev",
    "prisma:migrate:deploy": "prisma migrate deploy",
    "prisma:studio": "prisma studio"
  }
}

// Deploy migrations in CD pipeline
// .github/workflows/deploy.yml
// - name: Run migrations
//   run: npm run prisma:migrate:deploy
```

### Repository Pattern with Prisma
```typescript
import { PrismaClient, User, Prisma } from '@prisma/client';

export class UserRepository {
  constructor(private prisma: PrismaClient) {}

  async create(data: Prisma.UserCreateInput): Promise<User> {
    return this.prisma.user.create({ data });
  }

  async findById(id: string): Promise<User | null> {
    return this.prisma.user.findUnique({ where: { id } });
  }

  async findByEmail(email: string): Promise<User | null> {
    return this.prisma.user.findUnique({ where: { email } });
  }

  async update(id: string, data: Prisma.UserUpdateInput): Promise<User> {
    return this.prisma.user.update({
      where: { id },
      data,
    });
  }

  async delete(id: string): Promise<void> {
    await this.prisma.user.delete({ where: { id } });
  }

  async findMany(params: {
    skip?: number;
    take?: number;
    where?: Prisma.UserWhereInput;
    orderBy?: Prisma.UserOrderByWithRelationInput;
  }): Promise<User[]> {
    return this.prisma.user.findMany(params);
  }
}

// Usage with dependency injection
const userRepo = new UserRepository(prisma);
const user = await userRepo.findByEmail('user@example.com');
```

### Transaction Pattern
```typescript
// Transfer funds between accounts
async function transferFunds(fromId: string, toId: string, amount: number): Promise<void> {
  await prisma.$transaction(async (tx) => {
    // Deduct from sender
    const sender = await tx.account.update({
      where: { id: fromId },
      data: { balance: { decrement: amount } },
    });

    // Verify sufficient funds
    if (sender.balance < 0) {
      throw new Error('Insufficient funds');
    }

    // Add to recipient
    await tx.account.update({
      where: { id: toId },
      data: { balance: { increment: amount } },
    });

    // Record transaction
    await tx.transaction.create({
      data: {
        fromAccountId: fromId,
        toAccountId: toId,
        amount,
        type: 'TRANSFER',
      },
    });
  });
  // All operations succeed or all fail
}
```

### Optimistic Locking
```typescript
// Prevent lost updates with version field
// schema.prisma
// model Post {
//   id      String @id @default(uuid())
//   title   String
//   version Int    @default(0)
// }

async function updatePost(id: string, title: string, currentVersion: number): Promise<Post> {
  const updated = await prisma.post.updateMany({
    where: {
      id,
      version: currentVersion, // Only update if version matches
    },
    data: {
      title,
      version: { increment: 1 },
    },
  });

  if (updated.count === 0) {
    throw new Error('Post was modified by another user');
  }

  return prisma.post.findUnique({ where: { id } })!;
}
```

## MongoDB Patterns

### Connection Pooling
```typescript
import { MongoClient, Db } from 'mongodb';

let cachedDb: Db | null = null;

async function connectToDatabase(): Promise<Db> {
  if (cachedDb) {
    return cachedDb;
  }

  const client = await MongoClient.connect(process.env.MONGODB_URI!, {
    maxPoolSize: 10,
    minPoolSize: 2,
    maxIdleTimeMS: 30000,
    serverSelectionTimeoutMS: 5000,
  });

  cachedDb = client.db('myapp');
  return cachedDb;
}

// Usage in Lambda
export const handler = async (event: APIGatewayEvent) => {
  const db = await connectToDatabase(); // Reuses connection
  const users = await db.collection('users').find().toArray();
  return { statusCode: 200, body: JSON.stringify(users) };
};
```

### Type-Safe Collections
```typescript
import { Collection, ObjectId } from 'mongodb';

interface User {
  _id?: ObjectId;
  email: string;
  name: string;
  createdAt: Date;
}

class UserRepository {
  private collection: Collection<User>;

  constructor(db: Db) {
    this.collection = db.collection<User>('users');
  }

  async create(user: Omit<User, '_id'>): Promise<User> {
    const result = await this.collection.insertOne(user);
    return { ...user, _id: result.insertedId };
  }

  async findById(id: string): Promise<User | null> {
    return this.collection.findOne({ _id: new ObjectId(id) });
  }

  async findByEmail(email: string): Promise<User | null> {
    return this.collection.findOne({ email });
  }

  async update(id: string, updates: Partial<User>): Promise<void> {
    await this.collection.updateOne(
      { _id: new ObjectId(id) },
      { $set: updates }
    );
  }

  async delete(id: string): Promise<void> {
    await this.collection.deleteOne({ _id: new ObjectId(id) });
  }
}
```

### Index Creation
```typescript
// Create indexes at startup (idempotent)
async function ensureIndexes(db: Db): Promise<void> {
  const users = db.collection('users');

  await users.createIndex({ email: 1 }, { unique: true });
  await users.createIndex({ createdAt: -1 });
  await users.createIndex({ 'profile.location': 1 }, { sparse: true });

  // Compound index
  await users.createIndex({ status: 1, createdAt: -1 });

  // Text search index
  await users.createIndex({ name: 'text', bio: 'text' });
}
```

## Error Handling

### DynamoDB Errors
```typescript
import { ConditionalCheckFailedException } from '@aws-sdk/client-dynamodb';

try {
  await dynamodb.send(
    new PutCommand({
      TableName: 'users',
      Item: user,
      ConditionExpression: 'attribute_not_exists(PK)',
    })
  );
} catch (error) {
  if (error instanceof ConditionalCheckFailedException) {
    throw new Error('User already exists');
  }
  throw error;
}
```

### Prisma Errors
```typescript
import { Prisma } from '@prisma/client';

try {
  await prisma.user.create({ data: { email: 'user@example.com' } });
} catch (error) {
  if (error instanceof Prisma.PrismaClientKnownRequestError) {
    // Unique constraint violation
    if (error.code === 'P2002') {
      throw new Error('Email already exists');
    }
    // Record not found
    if (error.code === 'P2025') {
      throw new Error('User not found');
    }
  }
  throw error;
}
```

### MongoDB Errors
```typescript
import { MongoError } from 'mongodb';

try {
  await collection.insertOne(user);
} catch (error) {
  if (error instanceof MongoError) {
    // Duplicate key error
    if (error.code === 11000) {
      throw new Error('Email already exists');
    }
  }
  throw error;
}
```

## Testing Database Integration

### In-Memory Database (Prisma)
```typescript
// Use SQLite in-memory for tests
// prisma/schema.test.prisma
datasource db {
  provider = "sqlite"
  url      = "file::memory:?cache=shared"
}

// Test setup
import { PrismaClient } from '@prisma/client';

let prisma: PrismaClient;

beforeAll(async () => {
  prisma = new PrismaClient();
  await prisma.$executeRaw`PRAGMA foreign_keys = ON`;
});

afterAll(async () => {
  await prisma.$disconnect();
});

beforeEach(async () => {
  // Clear all tables
  const tables = await prisma.$queryRaw<{ name: string }[]>`
    SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'
  `;

  for (const { name } of tables) {
    await prisma.$executeRawUnsafe(`DELETE FROM ${name}`);
  }
});
```

### Mocking DynamoDB
```typescript
import { mockClient } from 'aws-sdk-client-mock';
import { DynamoDBDocumentClient, GetCommand } from '@aws-sdk/lib-dynamodb';

const dynamoMock = mockClient(DynamoDBDocumentClient);

beforeEach(() => {
  dynamoMock.reset();
});

test('fetches user by id', async () => {
  dynamoMock.on(GetCommand).resolves({
    Item: { PK: 'USER#123', SK: 'PROFILE', email: 'user@example.com' },
  });

  const user = await userRepo.findById('123');
  expect(user?.email).toBe('user@example.com');
});
```

### Integration Tests with Testcontainers
```typescript
import { GenericContainer, StartedTestContainer } from 'testcontainers';
import { PrismaClient } from '@prisma/client';

let container: StartedTestContainer;
let prisma: PrismaClient;

beforeAll(async () => {
  // Start PostgreSQL container
  container = await new GenericContainer('postgres:15')
    .withEnvironment({
      POSTGRES_USER: 'test',
      POSTGRES_PASSWORD: 'test',
      POSTGRES_DB: 'test',
    })
    .withExposedPorts(5432)
    .start();

  const connectionString = `postgresql://test:test@${container.getHost()}:${container.getMappedPort(5432)}/test`;

  prisma = new PrismaClient({
    datasources: { db: { url: connectionString } },
  });

  // Run migrations
  await exec(`DATABASE_URL="${connectionString}" npx prisma migrate deploy`);
}, 60000);

afterAll(async () => {
  await prisma.$disconnect();
  await container.stop();
});
```

## Performance Monitoring

### Query Logging
```typescript
// Prisma query logging
const prisma = new PrismaClient({
  log: [
    { emit: 'event', level: 'query' },
    { emit: 'event', level: 'error' },
  ],
});

prisma.$on('query', (e) => {
  if (e.duration > 1000) {
    logger.warn('Slow query detected', {
      query: e.query,
      duration: e.duration,
      params: e.params,
    });
  }
});
```

### Connection Pool Monitoring
```typescript
// Monitor Prisma connection pool
setInterval(() => {
  const metrics = prisma.$metrics.json();
  logger.info('Database metrics', {
    activeConnections: metrics.counters.find(c => c.key === 'prisma_client_queries_active')?.value,
    totalConnections: metrics.counters.find(c => c.key === 'prisma_client_queries_total')?.value,
  });
}, 60000); // Every minute
```

## Common Pitfalls

### N+1 Queries
```typescript
// ❌ N+1 query problem
const users = await prisma.user.findMany();
for (const user of users) {
  user.posts = await prisma.post.findMany({ where: { authorId: user.id } });
}

// ✓ Eager loading
const users = await prisma.user.findMany({
  include: { posts: true },
});
```

### Connection Leaks
```typescript
// ❌ Creates new connection every time
export const handler = async () => {
  const prisma = new PrismaClient(); // Leak!
  const users = await prisma.user.findMany();
  return { statusCode: 200, body: JSON.stringify(users) };
};

// ✓ Reuse connection across invocations
const prisma = new PrismaClient();

export const handler = async () => {
  const users = await prisma.user.findMany();
  return { statusCode: 200, body: JSON.stringify(users) };
};
```

### Missing Error Handling
```typescript
// ❌ Unhandled database errors crash application
const user = await prisma.user.create({ data: { email } });

// ✓ Handle specific errors
try {
  const user = await prisma.user.create({ data: { email } });
} catch (error) {
  if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
    throw new ConflictError('Email already exists');
  }
  throw new InternalServerError('Database error');
}
```

## Related
- [Database Optimization](../performance/database-optimization.md)
- [Error Handling](../general/error-handling.md)
- [Testing Patterns](../testing/integration-tests.md)
