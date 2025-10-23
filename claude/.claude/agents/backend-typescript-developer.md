---
name: TypeScript Backend Development Guide
description: Comprehensive guide for building AWS serverless backends with TypeScript. Covers Lambda handlers, HTTP clients, database patterns, validation, and best practices for AI-assisted development.
tools: all
model: inherit
---

# TypeScript Backend Development Guide

## Core Principles

### Serverless-First Architecture
- Prefer managed services (Lambda, DynamoDB, API Gateway) over self-managed infrastructure
- Pay-per-use pricing, automatic scaling, reduced operational overhead
- Lambda functions should be stateless and focused on single responsibilities

### Handler Pattern: Thin Handlers, Fat Services

```typescript
// ✅ GOOD: Thin handler, business logic separated
// src/handlers/users/get.ts
import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { getUserById } from '../../services/user-service';
import { errorResponse, successResponse } from '../../utils/responses';

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    const userId = event.pathParameters?.id;
    if (!userId) return errorResponse(400, 'User ID is required');
    
    const user = await getUserById(userId);
    if (!user) return errorResponse(404, 'User not found');
    
    return successResponse(200, user);
  } catch (error) {
    console.error('Error fetching user:', error);
    return errorResponse(500, 'Internal server error');
  }
};

// src/services/user-service.ts
// Pure TypeScript - no AWS dependencies, easily testable
export async function getUserById(userId: string): Promise<User | null> {
  // Business logic here
}
```

**Why**: Business logic is testable without Lambda runtime, clear separation of concerns.

## Lambda Best Practices

### 1. Initialize Clients Outside Handler (Critical for Performance)

```typescript
// ✅ GOOD: Initialize once, reuse across invocations
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

export const handler = async (event: APIGatewayProxyEvent) => {
  // Use docClient - already initialized
  const result = await docClient.send(new GetCommand({...}));
};

// ❌ BAD: Creates new client on every invocation
export const handler = async (event: APIGatewayProxyEvent) => {
  const client = new DynamoDBClient({}); // Cold start penalty!
};
```

### 2. Environment Variables & Configuration

```typescript
// src/config/environment.ts
export const config = {
  tableName: process.env.TABLE_NAME!,
  region: process.env.AWS_REGION!,
  stage: process.env.STAGE || 'dev',
} as const;

// Validate at startup (fails fast)
if (!config.tableName) {
  throw new Error('TABLE_NAME environment variable is required');
}
```

## HTTP Libraries: When and What to Use

### For Lambda Functions: Use Native APIs

**Important**: API Gateway already parses HTTP for you. You usually DON'T need Express/Fastify.

```typescript
// ✅ Lambda with API Gateway - No framework needed
import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  // Event contains parsed HTTP data:
  const body = event.body ? JSON.parse(event.body) : {};
  const headers = event.headers;
  const pathParams = event.pathParameters;
  const queryParams = event.queryStringParameters;
  
  return {
    statusCode: 200,
    headers: { 
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*' 
    },
    body: JSON.stringify({ message: 'Success' }),
  };
};
```

**Only use Express/Fastify in Lambda when**:
- Migrating existing Express app
- Sharing code between Lambda and containers
- Need specific middleware ecosystem

### For Containers (ECS/Fargate): Use Fastify

```typescript
import Fastify from 'fastify';
import { Type } from '@sinclair/typebox';

const fastify = Fastify({ logger: true });

fastify.get('/users/:id', {
  schema: {
    params: Type.Object({ id: Type.String({ format: 'uuid' }) }),
    response: {
      200: Type.Object({
        id: Type.String(),
        name: Type.String(),
        email: Type.String({ format: 'email' }),
      }),
    },
  },
}, async (request, reply) => {
  const user = await getUserById(request.params.id);
  return user;
});

await fastify.listen({ port: 3000, host: '0.0.0.0' });
```

**Why Fastify**: Faster than Express, native TypeScript support, excellent schema validation.

## HTTP Client Libraries (Making Outbound Requests)

### Selection Matrix

| Library | Use Case | Pros | Cons |
|---------|----------|------|------|
| Native `fetch` | Node 18+, simple APIs | Built-in, standard, no deps | Limited retry support |
| `undici` | High performance | Fastest, HTTP/2, connection pooling | More complex API |
| `axios` | Feature-rich needs | Interceptors, retries, transforms | Larger bundle |
| AWS SDK | AWS services | Auto retries, credentials | Only for AWS |

### 1. Native Fetch (Recommended for Most Cases)

```typescript
// ✅ Initialize outside handler
const API_TOKEN = process.env.API_TOKEN;

export async function fetchUser(userId: string): Promise<User> {
  const response = await fetch(`https://api.example.com/users/${userId}`, {
    method: 'GET',
    headers: {
      'Authorization': `Bearer ${API_TOKEN}`,
      'Content-Type': 'application/json',
    },
  });
  
  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`);
  }
  
  return response.json();
}

// With timeout
export async function fetchWithTimeout(
  url: string,
  options: RequestInit = {},
  timeoutMs = 5000
): Promise<Response> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  
  try {
    return await fetch(url, { ...options, signal: controller.signal });
  } finally {
    clearTimeout(timeout);
  }
}

// With retry logic
export async function fetchWithRetry(
  url: string,
  options: RequestInit = {},
  maxRetries = 3
): Promise<Response> {
  for (let i = 0; i < maxRetries; i++) {
    try {
      const response = await fetch(url, options);
      
      // Don't retry client errors (4xx)
      if (response.status >= 400 && response.status < 500) return response;
      if (response.ok || i === maxRetries - 1) return response;
      
      // Exponential backoff
      await new Promise(resolve => setTimeout(resolve, Math.pow(2, i) * 1000));
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      await new Promise(resolve => setTimeout(resolve, Math.pow(2, i) * 1000));
    }
  }
  throw new Error('Max retries exceeded');
}
```

### 2. Undici (High Performance)

```typescript
import { request, Agent, setGlobalDispatcher } from 'undici';

// ✅ Initialize outside handler - connection pooling
const agent = new Agent({
  connections: 100,
  pipelining: 10,
  keepAliveTimeout: 60000,
});

setGlobalDispatcher(agent);

export async function fetchUser(userId: string): Promise<User> {
  const { statusCode, body } = await request(
    `https://api.example.com/users/${userId}`,
    { 
      method: 'GET',
      headers: { 'Authorization': `Bearer ${process.env.API_TOKEN}` }
    }
  );
  
  if (statusCode !== 200) throw new Error(`HTTP error! status: ${statusCode}`);
  return body.json();
}
```

### 3. Axios (Feature-Rich)

```typescript
import axios, { AxiosInstance } from 'axios';

// ✅ Initialize outside handler
const apiClient: AxiosInstance = axios.create({
  baseURL: 'https://api.example.com',
  timeout: 10000,
  headers: { 'Content-Type': 'application/json' },
});

// Request interceptor
apiClient.interceptors.request.use((config) => {
  config.headers.Authorization = `Bearer ${process.env.API_TOKEN}`;
  return config;
});

// Response interceptor with retry
apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;
    if (error.response?.status >= 500 && !originalRequest._retry) {
      originalRequest._retry = true;
      await new Promise(resolve => setTimeout(resolve, 1000));
      return apiClient(originalRequest);
    }
    return Promise.reject(error);
  }
);

export async function fetchUser(userId: string): Promise<User> {
  const { data } = await apiClient.get<User>(`/users/${userId}`);
  return data;
}
```

### 4. AWS SDK (For AWS Services)

```typescript
import { S3Client, GetObjectCommand } from '@aws-sdk/client-s3';
import { SQSClient, SendMessageCommand } from '@aws-sdk/client-sqs';

// ✅ Initialize outside handler
const s3Client = new S3Client({ 
  region: process.env.AWS_REGION,
  maxAttempts: 3 // Automatic retries
});

export async function getFileFromS3(bucket: string, key: string): Promise<string> {
  const response = await s3Client.send(
    new GetObjectCommand({ Bucket: bucket, Key: key })
  );
  return response.Body!.transformToString();
}
```

## Schema Validation & Type Safety

### Always Validate External Input with Zod

```typescript
import { z } from 'zod';

// Define schema
export const CreateUserSchema = z.object({
  name: z.string().min(1).max(100),
  email: z.string().email(),
  age: z.number().int().min(18).optional(),
});

export const UserIdSchema = z.string().uuid();

// Infer TypeScript types from schema
export type CreateUserInput = z.infer<typeof CreateUserSchema>;

// Use in handler
export const handler = async (event: APIGatewayProxyEvent) => {
  try {
    const body = JSON.parse(event.body || '{}');
    const validatedInput = CreateUserSchema.parse(body);
    
    const user = await createUser(validatedInput);
    return successResponse(201, user);
  } catch (error) {
    if (error instanceof z.ZodError) {
      return errorResponse(400, 'Validation error', error.errors);
    }
    return errorResponse(500, 'Internal server error');
  }
};
```

## Database Patterns

### DynamoDB: Single Table Design

```typescript
// Entity structure:
// User: PK=USER#${id}, SK=METADATA
// User Email Index: GSI1PK=EMAIL#${email}, GSI1SK=USER#${id}
// Order: PK=USER#${userId}, SK=ORDER#${orderId}

import { DynamoDBDocumentClient, QueryCommand, GetCommand } from '@aws-sdk/lib-dynamodb';

export class DynamoDBUserRepository {
  constructor(
    private readonly docClient: DynamoDBDocumentClient,
    private readonly tableName: string
  ) {}
  
  async get(id: string): Promise<UserEntity | null> {
    const result = await this.docClient.send(
      new GetCommand({
        TableName: this.tableName,
        Key: { PK: `USER#${id}`, SK: 'METADATA' },
      })
    );
    return result.Item as UserEntity | null;
  }
  
  async getUserByEmail(email: string): Promise<UserEntity | null> {
    const result = await this.docClient.send(
      new QueryCommand({
        TableName: this.tableName,
        IndexName: 'GSI1',
        KeyConditionExpression: 'GSI1PK = :email',
        ExpressionAttributeValues: { ':email': `EMAIL#${email}` },
      })
    );
    return result.Items?.[0] as UserEntity | null;
  }
  
  async getUserOrders(userId: string): Promise<OrderEntity[]> {
    const result = await this.docClient.send(
      new QueryCommand({
        TableName: this.tableName,
        KeyConditionExpression: 'PK = :pk AND begins_with(SK, :sk)',
        ExpressionAttributeValues: {
          ':pk': `USER#${userId}`,
          ':sk': 'ORDER#',
        },
      })
    );
    return result.Items as OrderEntity[];
  }
}
```

### RDS with Prisma

```typescript
import { PrismaClient } from '@prisma/client';

// Singleton pattern for Lambda container reuse
declare global {
  var prisma: PrismaClient | undefined;
}

export const prisma = global.prisma || new PrismaClient({
  log: ['query', 'error', 'warn'],
});

if (process.env.NODE_ENV !== 'production') {
  global.prisma = prisma;
}

// Usage
export async function getUserById(id: string) {
  return prisma.user.findUnique({ where: { id } });
}

export async function createUser(data: { name: string; email: string }) {
  return prisma.user.create({ data });
}
```

## Error Handling

### Custom Error Classes

```typescript
export class AppError extends Error {
  constructor(
    public statusCode: number,
    message: string,
    public details?: any
  ) {
    super(message);
    this.name = this.constructor.name;
    Error.captureStackTrace(this, this.constructor);
  }
}

export class ValidationError extends AppError {
  constructor(message: string, details?: any) {
    super(400, message, details);
  }
}

export class NotFoundError extends AppError {
  constructor(resource: string, id: string) {
    super(404, `${resource} with id ${id} not found`);
  }
}
```

### Response Utilities

```typescript
export interface ErrorResponse {
  error: {
    code: string;
    message: string;
    details?: any;
  };
  requestId?: string;
}

export function errorResponse(
  statusCode: number,
  message: string,
  details?: any,
  requestId?: string
): APIGatewayProxyResult {
  return {
    statusCode,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    },
    body: JSON.stringify({
      error: {
        code: getErrorCode(statusCode),
        message,
        details,
      },
      requestId,
    }),
  };
}

export function successResponse<T>(
  statusCode: number,
  data: T,
  requestId?: string
): APIGatewayProxyResult {
  return {
    statusCode,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    },
    body: JSON.stringify({ data, requestId }),
  };
}
```

### Structured Logging

```typescript
export class Logger {
  constructor(private context: { requestId: string; userId?: string }) {}
  
  info(message: string, data?: any) {
    console.log(JSON.stringify({
      level: 'INFO',
      message,
      ...this.context,
      ...data,
      timestamp: new Date().toISOString(),
    }));
  }
  
  error(message: string, error: any, data?: any) {
    console.error(JSON.stringify({
      level: 'ERROR',
      message,
      error: {
        name: error.name,
        message: error.message,
        stack: error.stack,
      },
      ...this.context,
      ...data,
      timestamp: new Date().toISOString(),
    }));
  }
}

// Usage
export const handler = async (event: APIGatewayProxyEvent, context: Context) => {
  const logger = new Logger({ requestId: context.requestId });
  logger.info('Request received', { path: event.path });
  
  try {
    const result = await processRequest(event);
    logger.info('Request successful');
    return successResponse(200, result);
  } catch (error) {
    logger.error('Request failed', error);
    return errorResponse(500, 'Internal server error');
  }
};
```

## Security Best Practices

### Input Sanitization

```typescript
import { z } from 'zod';
import DOMPurify from 'isomorphic-dompurify';

const UserInputSchema = z.object({
  name: z.string().min(1).max(100).transform(val => DOMPurify.sanitize(val)),
  email: z.string().email(),
  bio: z.string().max(500).optional().transform(val => 
    val ? DOMPurify.sanitize(val) : undefined
  ),
});
```

### Secrets Management

```typescript
import { SecretsManagerClient, GetSecretValueCommand } from '@aws-sdk/client-secrets-manager';

const secretsClient = new SecretsManagerClient({});

export async function getSecret(secretArn: string): Promise<any> {
  const result = await secretsClient.send(
    new GetSecretValueCommand({ SecretId: secretArn })
  );
  return JSON.parse(result.SecretString!);
}
```

## Performance Patterns

### Connection Pooling for External APIs

```typescript
import { Agent as HttpsAgent } from 'https';
import axios from 'axios';

// Initialize outside handler
const httpsAgent = new HttpsAgent({
  keepAlive: true,
  maxSockets: 50,
  maxFreeSockets: 10,
  timeout: 60000,
  keepAliveMsecs: 30000,
});

const apiClient = axios.create({
  baseURL: 'https://api.example.com',
  httpsAgent,
  timeout: 10000,
});
```

### Circuit Breaker Pattern

```typescript
export class CircuitBreaker {
  private failures = 0;
  private lastFailureTime?: number;
  private state: 'CLOSED' | 'OPEN' | 'HALF_OPEN' = 'CLOSED';
  
  constructor(
    private threshold: number = 5,
    private timeout: number = 60000
  ) {}
  
  async execute<T>(fn: () => Promise<T>): Promise<T> {
    if (this.state === 'OPEN') {
      if (Date.now() - this.lastFailureTime! > this.timeout) {
        this.state = 'HALF_OPEN';
      } else {
        throw new Error('Circuit breaker is OPEN');
      }
    }
    
    try {
      const result = await fn();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }
  
  private onSuccess() {
    this.failures = 0;
    this.state = 'CLOSED';
  }
  
  private onFailure() {
    this.failures++;
    this.lastFailureTime = Date.now();
    if (this.failures >= this.threshold) {
      this.state = 'OPEN';
    }
  }
}
```

## Critical Rules for AI Agents

### ✅ DO

1. **Initialize clients outside handler** - All DB clients, HTTP clients, AWS SDK clients
2. **Use native fetch for simple HTTP** - Built into Node 18+, no dependencies needed
3. **Validate all external input** - Use Zod for runtime validation
4. **Separate handler from business logic** - Thin handlers, testable services
5. **Use structured logging** - JSON format for CloudWatch Insights
6. **Implement retry logic** - With exponential backoff for external APIs
7. **Use connection pooling** - For HTTP clients accessing external APIs
8. **Type safety end-to-end** - Prisma for DB, Zod for validation
9. **Handle errors gracefully** - Custom error classes, structured responses
10. **Use TypeScript strict mode** - Catch errors at compile time

### ❌ DON'T

1. **Don't create clients inside handler** - Causes cold start penalty
2. **Don't use Express/Fastify in Lambda** - Unless migrating or sharing with containers
3. **Don't skip input validation** - Security and data integrity risk
4. **Don't use overly broad IAM permissions** - Principle of least privilege
5. **Don't create new HTTP client per request** - Wastes connections
6. **Don't forget timeouts on HTTP requests** - Can cause Lambda timeouts
7. **Don't mix handler and business logic** - Makes testing difficult
8. **Don't use synchronous code** - Blocks event loop
9. **Don't ignore error handling** - Silent failures are worse than crashes
10. **Don't hardcode secrets** - Use environment variables or Secrets Manager

## Quick Reference

### HTTP Client Selection Guide

- **Simple GET/POST**: Native fetch
- **High performance/throughput**: undici
- **Need interceptors/transforms**: axios
- **AWS services**: AWS SDK
- **Complex retry/streaming**: got

### Database Selection Guide

- **Flexible schema, high writes**: DynamoDB
- **Complex relationships, ACID**: Aurora Postgres with Prisma
- **Time-series data**: Timestream
- **Caching**: ElastiCache or DAX

---

## Further Reading

1. **AWS Lambda Best Practices**: https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html
2. **Zod Documentation**: https://zod.dev/
3. **Prisma Guide**: https://www.prisma.io/docs/getting-started
4. **Undici Documentation**: https://undici.nodejs.org/