# AWS Lambda Best Practices

Comprehensive guide for building production-grade AWS Lambda functions with TypeScript. Focus on performance, maintainability, and cost optimization.

## Handler Pattern: Thin Handlers, Fat Services

Lambda handlers should be thin orchestration layers, delegating business logic to pure TypeScript services.

**Why**: Business logic becomes testable without Lambda runtime, clear separation of concerns, easier to migrate if needed.

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

## Critical Performance Rule: Initialize Clients Outside Handler

**The most important Lambda optimization**: Initialize all clients (DB, HTTP, AWS SDK) OUTSIDE the handler function to enable container reuse.

**Why**: Lambda containers are reused across invocations. Global scope executes once per container lifetime, handler scope executes every invocation. Client initialization is expensive (DNS lookup, connection establishment, TLS handshake).

**Impact**: 200-500ms saved per warm invocation.

### AWS SDK Clients

```typescript
// ✅ GOOD: Initialize once, reuse across invocations
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient } from '@aws-sdk/lib-dynamodb';

// Executed once per container
const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

export const handler = async (event: APIGatewayProxyEvent) => {
  // Use docClient - already initialized
  const result = await docClient.send(new GetCommand({
    TableName: 'Users',
    Key: { id: event.pathParameters?.id }
  }));

  return successResponse(200, result.Item);
};

// ❌ BAD: Creates new client on every invocation
export const handler = async (event: APIGatewayProxyEvent) => {
  const client = new DynamoDBClient({}); // Cold start penalty on every invocation!
  const docClient = DynamoDBDocumentClient.from(client);
  // ...
};
```

### HTTP Clients

```typescript
// ✅ GOOD: Initialize HTTP client outside handler
import axios, { AxiosInstance } from 'axios';

const apiClient: AxiosInstance = axios.create({
  baseURL: 'https://api.example.com',
  timeout: 10000,
  headers: { 'Content-Type': 'application/json' },
});

// Request interceptor (runs once)
apiClient.interceptors.request.use((config) => {
  config.headers.Authorization = `Bearer ${process.env.API_TOKEN}`;
  return config;
});

export const handler = async (event: APIGatewayProxyEvent) => {
  const { data } = await apiClient.get('/users');
  return successResponse(200, data);
};
```

### Database Clients

```typescript
// DynamoDB
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, GetCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

export const handler = async (event: APIGatewayProxyEvent) => {
  const result = await docClient.send(new GetCommand({...}));
};

// Prisma (RDS)
import { PrismaClient } from '@prisma/client';

declare global {
  var prisma: PrismaClient | undefined;
}

export const prisma = global.prisma || new PrismaClient({
  log: ['query', 'error', 'warn'],
});

if (process.env.NODE_ENV !== 'production') {
  global.prisma = prisma;
}

export const handler = async (event: APIGatewayProxyEvent) => {
  const user = await prisma.user.findUnique({ where: { id: userId } });
};
```

## Environment Variables & Configuration

**Pattern**: Load and validate environment variables at startup (global scope), fail fast if missing required values.

```typescript
// src/config/environment.ts
export const config = {
  tableName: process.env.TABLE_NAME!,
  region: process.env.AWS_REGION!,
  stage: process.env.STAGE || 'dev',
  apiKey: process.env.API_KEY!,
} as const;

// Validate at startup (fails fast on container initialization)
if (!config.tableName) {
  throw new Error('TABLE_NAME environment variable is required');
}

if (!config.apiKey) {
  throw new Error('API_KEY environment variable is required');
}

// Usage in handler
import { config } from './config/environment';

export const handler = async (event: APIGatewayProxyEvent) => {
  const result = await docClient.send(new GetCommand({
    TableName: config.tableName,
    Key: { id: event.pathParameters?.id }
  }));
};
```

## Error Handling in Lambda

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

export class UnauthorizedError extends AppError {
  constructor(message: string = 'Unauthorized') {
    super(401, message);
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

function getErrorCode(statusCode: number): string {
  const codes: Record<number, string> = {
    400: 'BAD_REQUEST',
    401: 'UNAUTHORIZED',
    403: 'FORBIDDEN',
    404: 'NOT_FOUND',
    409: 'CONFLICT',
    422: 'UNPROCESSABLE_ENTITY',
    429: 'RATE_LIMIT_EXCEEDED',
    500: 'INTERNAL_ERROR',
    502: 'BAD_GATEWAY',
    503: 'SERVICE_UNAVAILABLE',
  };
  return codes[statusCode] || 'UNKNOWN_ERROR';
}
```

### Handler with Error Handling

```typescript
import { APIGatewayProxyEvent, APIGatewayProxyResult, Context } from 'aws-lambda';
import { z } from 'zod';

export const handler = async (
  event: APIGatewayProxyEvent,
  context: Context
): Promise<APIGatewayProxyResult> => {
  const requestId = context.requestId;

  try {
    // Parse and validate input
    const body = JSON.parse(event.body || '{}');
    const validatedInput = CreateUserSchema.parse(body);

    // Execute business logic
    const user = await createUser(validatedInput);

    return successResponse(201, user, requestId);
  } catch (error) {
    // Zod validation errors
    if (error instanceof z.ZodError) {
      return errorResponse(400, 'Validation error', error.errors, requestId);
    }

    // Custom application errors
    if (error instanceof AppError) {
      return errorResponse(error.statusCode, error.message, error.details, requestId);
    }

    // Unknown errors
    console.error('Unexpected error:', error);
    return errorResponse(500, 'Internal server error', undefined, requestId);
  }
};
```

## Structured Logging

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

  warn(message: string, data?: any) {
    console.warn(JSON.stringify({
      level: 'WARN',
      message,
      ...this.context,
      ...data,
      timestamp: new Date().toISOString(),
    }));
  }
}

// Usage in handler
export const handler = async (event: APIGatewayProxyEvent, context: Context) => {
  const logger = new Logger({ requestId: context.requestId });
  logger.info('Request received', {
    path: event.path,
    method: event.httpMethod
  });

  try {
    const result = await processRequest(event);
    logger.info('Request successful', { statusCode: 200 });
    return successResponse(200, result);
  } catch (error) {
    logger.error('Request failed', error, { path: event.path });
    return errorResponse(500, 'Internal server error');
  }
};
```

## Cold Start Optimization

### Minimize Package Size

```typescript
// ❌ BAD: Imports entire SDK (massive bundle)
import * as AWS from 'aws-sdk';

// ✅ GOOD: Import only needed clients
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, GetCommand } from '@aws-sdk/lib-dynamodb';
```

### Lazy Loading for Rare Code Paths

```typescript
// ✅ GOOD: Lazy load heavy dependencies for rare operations
export const handler = async (event: APIGatewayProxyEvent) => {
  if (event.path === '/export-pdf') {
    // Only load PDF library when actually needed
    const { generatePDF } = await import('./utils/pdf-generator');
    const pdf = await generatePDF(data);
    return successResponse(200, pdf);
  }

  // Normal path doesn't pay for PDF library
  const data = await processNormalRequest(event);
  return successResponse(200, data);
};
```

### Provisioned Concurrency for Critical Paths

```typescript
// CDK: Reserve capacity for zero cold starts
const userApiFunction = new lambda.Function(this, 'UserApi', {
  // ... other config
});

userApiFunction.addAlias('prod', {
  provisionedConcurrentExecutions: 10, // Always warm
});
```

## Complete Example: Production-Grade Lambda

```typescript
// src/handlers/users/create.ts
import { APIGatewayProxyEvent, APIGatewayProxyResult, Context } from 'aws-lambda';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, PutCommand } from '@aws-sdk/lib-dynamodb';
import { z } from 'zod';
import { Logger } from '../../utils/logger';
import { errorResponse, successResponse } from '../../utils/responses';
import { config } from '../../config/environment';

// Initialize client outside handler
const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

// Schema validation
const CreateUserSchema = z.object({
  email: z.string().email().max(255),
  name: z.string().min(1).max(100),
  role: z.enum(['user', 'admin', 'moderator']),
});

type CreateUserInput = z.infer<typeof CreateUserSchema>;

// Handler
export const handler = async (
  event: APIGatewayProxyEvent,
  context: Context
): Promise<APIGatewayProxyResult> => {
  const logger = new Logger({ requestId: context.requestId });
  logger.info('Create user request received');

  try {
    // Parse and validate input
    const body = JSON.parse(event.body || '{}');
    const input = CreateUserSchema.parse(body);

    // Check if user exists
    const existingUser = await getUserByEmail(input.email);
    if (existingUser) {
      return errorResponse(409, 'User with this email already exists');
    }

    // Create user
    const user = await createUser(input);

    logger.info('User created successfully', { userId: user.id });
    return successResponse(201, user, context.requestId);
  } catch (error) {
    if (error instanceof z.ZodError) {
      logger.warn('Validation error', { errors: error.errors });
      return errorResponse(400, 'Validation error', error.errors, context.requestId);
    }

    logger.error('Failed to create user', error);
    return errorResponse(500, 'Internal server error', undefined, context.requestId);
  }
};

// Business logic (pure TypeScript, testable)
async function createUser(input: CreateUserInput) {
  const id = crypto.randomUUID();
  const now = new Date().toISOString();

  const user = {
    id,
    ...input,
    status: 'active',
    createdAt: now,
    updatedAt: now,
  };

  await docClient.send(new PutCommand({
    TableName: config.tableName,
    Item: user,
    ConditionExpression: 'attribute_not_exists(id)',
  }));

  return user;
}

async function getUserByEmail(email: string) {
  // Implementation
}
```

## Key Takeaways

1. **Initialize clients outside handler** - Most important performance optimization
2. **Thin handlers, fat services** - Keep Lambda code thin, business logic in testable services
3. **Validate environment variables at startup** - Fail fast if configuration missing
4. **Structured logging** - JSON logs for CloudWatch Insights
5. **Standard error responses** - Consistent error format across all handlers
6. **Minimize bundle size** - Only import what you need from AWS SDK v3
7. **Type safety end-to-end** - Use Zod for runtime validation, TypeScript for compile-time safety
