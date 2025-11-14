# API Design Patterns and Principles

Comprehensive guide for designing RESTful and GraphQL APIs with clear contracts, consistent patterns, and maintainable structures.

## Core API Design Principles

1. **Contract-First Development**: Design API contract before implementation
2. **Consistency**: Uniform patterns across all endpoints
3. **Versioning**: Plan for evolution from the start
4. **Resource-Oriented**: Model domain entities as resources
5. **Self-Documenting**: Clear, predictable endpoint structure
6. **Backward Compatibility**: Don't break existing clients

## REST API Resource Naming

### Plural Nouns for Resources

```
✅ GOOD: Plural nouns, clean structure
GET    /api/users
GET    /api/users/:id
POST   /api/users
PUT    /api/users/:id
PATCH  /api/users/:id
DELETE /api/users/:id

GET    /api/users/:userId/orders
POST   /api/users/:userId/orders

✅ GOOD: Nested resources (max 2 levels)
GET    /api/orders/:orderId/items
POST   /api/orders/:orderId/items
GET    /api/orders/:orderId/items/:itemId

❌ BAD: Verbs in URLs
GET    /api/getUsers
POST   /api/createUser
GET    /api/deleteUser/:id

❌ BAD: Mixed singular/plural
GET    /api/user
GET    /api/users

❌ BAD: Too deep nesting (hard to understand, maintain)
GET    /api/users/:userId/orders/:orderId/items/:itemId/reviews
```

**Rule**: Resources are nouns (plural), actions are HTTP methods.

## HTTP Methods

```
GET    /api/resources          List all resources (paginated)
GET    /api/resources/:id      Get single resource
POST   /api/resources          Create new resource
PUT    /api/resources/:id      Full update (replace entire resource)
PATCH  /api/resources/:id      Partial update (modify specific fields)
DELETE /api/resources/:id      Delete resource

HEAD   /api/resources/:id      Check existence (no body returned)
OPTIONS /api/resources         Get allowed methods (CORS preflight)
```

### When to Use Each Method

**GET**: Retrieve data, idempotent, cacheable, no side effects
**POST**: Create resource, non-idempotent, returns created resource
**PUT**: Full replacement, idempotent, requires all fields
**PATCH**: Partial update, idempotent, only changed fields
**DELETE**: Remove resource, idempotent, returns 204 No Content

## Request Schema Design

```typescript
import { z } from "zod";

// GET /api/users - Query parameters for filtering/pagination
const ListUsersQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  sort: z.enum(["createdAt", "name", "email"]).default("createdAt"),
  order: z.enum(["asc", "desc"]).default("desc"),
  status: z.enum(["active", "suspended", "pending"]).optional(),
  search: z.string().max(100).optional(),
});

type ListUsersQuery = z.infer<typeof ListUsersQuerySchema>;

// POST /api/users - Request body for creation
const CreateUserRequestSchema = z.object({
  email: z.string().email().max(255),
  name: z.string().min(1).max(100),
  role: z.enum(["user", "admin", "moderator"]),
  metadata: z.record(z.unknown()).optional(),
});

type CreateUserRequest = z.infer<typeof CreateUserRequestSchema>;

// PATCH /api/users/:id - Partial update (all fields optional)
const UpdateUserRequestSchema = CreateUserRequestSchema.partial();

type UpdateUserRequest = z.infer<typeof UpdateUserRequestSchema>;

// PUT /api/users/:id - Full replacement (all required fields)
const ReplaceUserRequestSchema = CreateUserRequestSchema;
```

## Response Schema Design

### Single Resource Response

```typescript
type UserResponse = {
  id: string;
  email: string;
  name: string;
  role: "user" | "admin" | "moderator";
  status: "active" | "suspended" | "pending";
  createdAt: string;  // ISO 8601
  updatedAt: string;  // ISO 8601
  metadata?: Record<string, unknown>;
};

// Example response
{
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "name": "John Doe",
    "role": "user",
    "status": "active",
    "createdAt": "2025-01-15T10:30:00Z",
    "updatedAt": "2025-01-15T10:30:00Z"
  }
}
```

### Collection Response with Pagination

```typescript
type ListUsersResponse = {
  data: UserResponse[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
  links: {
    self: string;
    first: string;
    last: string;
    next?: string;
    prev?: string;
  };
};

// Example response
{
  "data": [
    { /* user 1 */ },
    { /* user 2 */ }
  ],
  "pagination": {
    "page": 2,
    "limit": 20,
    "total": 150,
    "totalPages": 8
  },
  "links": {
    "self": "/api/users?page=2&limit=20",
    "first": "/api/users?page=1&limit=20",
    "last": "/api/users?page=8&limit=20",
    "next": "/api/users?page=3&limit=20",
    "prev": "/api/users?page=1&limit=20"
  }
}
```

### Created Resource Response

```typescript
type CreateUserResponse = {
  data: UserResponse;
  links: {
    self: string;
  };
};

// Example response (201 Created)
{
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "name": "John Doe",
    "role": "user",
    "status": "active",
    "createdAt": "2025-01-15T10:30:00Z",
    "updatedAt": "2025-01-15T10:30:00Z"
  },
  "links": {
    "self": "/api/users/550e8400-e29b-41d4-a716-446655440000"
  }
}
```

## Error Response Standard

```typescript
type ErrorResponse = {
  error: {
    code: string;           // Machine-readable error code
    message: string;        // Human-readable message
    details?: ErrorDetail[]; // Validation errors, field-specific issues
    requestId?: string;     // For support/debugging
    timestamp: string;      // ISO 8601
  };
};

type ErrorDetail = {
  field?: string;    // Which field caused error
  message: string;   // Specific error message
  code?: string;     // Field-specific error code
};
```

### Error Response Examples

```javascript
// 400 Bad Request - Validation error
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Request validation failed",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format",
        "code": "INVALID_EMAIL"
      },
      {
        "field": "age",
        "message": "Must be at least 18",
        "code": "AGE_TOO_LOW"
      }
    ],
    "requestId": "req_abc123",
    "timestamp": "2025-01-15T10:30:00Z"
  }
}

// 404 Not Found
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "User not found",
    "requestId": "req_def456",
    "timestamp": "2025-01-15T10:30:00Z"
  }
}

// 409 Conflict - Duplicate resource
{
  "error": {
    "code": "RESOURCE_CONFLICT",
    "message": "User with this email already exists",
    "requestId": "req_ghi789",
    "timestamp": "2025-01-15T10:30:00Z"
  }
}

// 500 Internal Server Error
{
  "error": {
    "code": "INTERNAL_ERROR",
    "message": "An unexpected error occurred",
    "requestId": "req_jkl012",
    "timestamp": "2025-01-15T10:30:00Z"
  }
}
```

## HTTP Status Codes

### Success Codes

```
200 OK              GET, PATCH successful - returns resource
201 Created         POST successful - returns created resource + Location header
204 No Content      DELETE successful - no response body needed
```

### Client Error Codes

```
400 Bad Request     Invalid input, validation failed
401 Unauthorized    Missing or invalid authentication token
403 Forbidden       Valid auth but insufficient permissions
404 Not Found       Resource doesn't exist
409 Conflict        Resource conflict (duplicate email, version mismatch)
422 Unprocessable   Semantic validation error (valid format, invalid business logic)
429 Too Many Requests Rate limit exceeded
```

### Server Error Codes

```
500 Internal Error  Unexpected server error
502 Bad Gateway     Upstream service error
503 Service Unavailable Temporary outage, maintenance
504 Gateway Timeout Upstream timeout
```

## API Versioning

### URL Versioning (Recommended)

```
✅ GOOD: Version in URL path
GET /api/v1/users
GET /api/v2/users
GET /api/v3/users

Pros:
- Clear, visible versioning
- Easy to route in API gateway
- Simple to understand
- Easy to test manually

Cons:
- Breaks REST principles (same resource, different URLs)
- Need to maintain multiple codebases
```

### Header Versioning

```
GET /api/users
Accept: application/vnd.myapp.v2+json

Pros:
- Same URL for all versions
- Follows REST principles
- Clean URLs

Cons:
- Less visible (hard to see which version)
- Harder to test manually (need to set headers)
- More complex routing
```

### Breaking vs Non-Breaking Changes

```typescript
// ✅ Non-Breaking Changes (Same version, backward compatible):
// - Adding optional fields to request
// - Adding new fields to response
// - Adding new endpoints
// - Adding new query parameters (optional)
// - Making required fields optional

// Example: v1 can add optional field
const CreateUserV1Schema = z.object({
  email: z.string().email(),
  name: z.string(),
  phone: z.string().optional(), // New optional field - non-breaking
});

// ❌ Breaking Changes (New version required):
// - Removing fields from request/response
// - Renaming fields
// - Changing field types
// - Making optional fields required
// - Changing endpoint URLs
// - Changing response structure

// Example: v2 renames field (breaking)
const CreateUserV1Schema = z.object({
  email: z.string().email(),
  name: z.string(), // Single name field
});

const CreateUserV2Schema = z.object({
  email: z.string().email(),
  firstName: z.string(), // Split into firstName/lastName
  lastName: z.string(),
});
```

## Pagination

### Cursor-Based (Recommended for Large Datasets)

```typescript
// Query parameters
type CursorPaginationQuery = {
  limit?: number;      // Items per page (default 20, max 100)
  cursor?: string;     // Opaque cursor for next page
};

// Response
type CursorPaginationResponse<T> = {
  data: T[];
  pagination: {
    nextCursor?: string;
    hasMore: boolean;
  };
};

// Example request
GET /api/users?limit=20&cursor=eyJpZCI6MTIzfQ

// Example response
{
  "data": [/* users */],
  "pagination": {
    "nextCursor": "eyJpZCI6MTQzfQ",
    "hasMore": true
  }
}
```

**Pros**: Efficient for large datasets, handles concurrent changes, no skipped/duplicate results
**Cons**: Can't jump to arbitrary page, more complex to implement

### Offset-Based (Simpler, Less Efficient)

```typescript
// Query parameters
type OffsetPaginationQuery = {
  page?: number;    // Page number (1-indexed)
  limit?: number;   // Items per page
};

// Response
type OffsetPaginationResponse<T> = {
  data: T[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
};

// Example request
GET /api/users?page=2&limit=20

// Example response
{
  "data": [/* users */],
  "pagination": {
    "page": 2,
    "limit": 20,
    "total": 150,
    "totalPages": 8
  }
}
```

**Pros**: Simple to understand, can jump to arbitrary page, shows total count
**Cons**: Inefficient for large offsets, results can be inconsistent with concurrent changes

## Filtering, Sorting, Search

```typescript
// Filtering by field values
GET /api/users?status=active&role=admin

// Sorting (single field)
GET /api/users?sort=createdAt&order=desc

// Alternative: minus for descending
GET /api/users?sort=-createdAt

// Search (fuzzy text search)
GET /api/users?search=john

// Field selection (sparse fieldsets)
GET /api/users?fields=id,name,email

// Combined query
GET /api/users?status=active&role=admin&search=john&sort=-createdAt&limit=50
```

### Implementation with Zod

```typescript
const ListUsersQuerySchema = z.object({
  // Filtering
  status: z.enum(["active", "suspended", "pending"]).optional(),
  role: z.enum(["user", "admin", "moderator"]).optional(),

  // Sorting
  sort: z.enum(["createdAt", "name", "email"]).default("createdAt"),
  order: z.enum(["asc", "desc"]).default("desc"),

  // Search
  search: z.string().max(100).optional(),

  // Pagination
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),

  // Field selection
  fields: z.string().optional().transform(val => val?.split(',')),
});
```

## Authentication & Authorization

### Authorization Header (Recommended)

```
GET /api/users
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...

Response status codes:
401 Unauthorized    No auth token or invalid token
403 Forbidden       Valid token but insufficient permissions
```

### API Key (Service-to-Service)

```
GET /api/users
X-API-Key: sk_live_abc123...
```

### Error Responses

```javascript
// 401 Unauthorized
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Missing or invalid authentication token"
  }
}

// 403 Forbidden
{
  "error": {
    "code": "FORBIDDEN",
    "message": "Insufficient permissions to access this resource"
  }
}
```

## Rate Limiting

### Rate Limit Headers

```
HTTP/1.1 200 OK
X-RateLimit-Limit: 1000        Request allowed per window
X-RateLimit-Remaining: 998     Requests remaining
X-RateLimit-Reset: 1642435200  Unix timestamp when limit resets
```

### Rate Limit Exceeded Response

```
HTTP/1.1 429 Too Many Requests
Retry-After: 60                Seconds until retry allowed

{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "API rate limit exceeded. Please try again in 60 seconds.",
    "retryAfter": 60
  }
}
```

### Configuration by Endpoint

```typescript
type RateLimitConfig = {
  "/api/users": {
    windowMs: 15 * 60 * 1000,  // 15 minutes
    max: 100,                   // 100 requests
  },
  "/api/auth/login": {
    windowMs: 15 * 60 * 1000,
    max: 5,                     // Stricter for auth endpoints
  },
};
```

## Complete API Example

```typescript
import { z } from "zod";
import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";

// Schemas
const CreateUserSchema = z.object({
  email: z.string().email().max(255),
  name: z.string().min(1).max(100),
  role: z.enum(["user", "admin", "moderator"]),
});

const UpdateUserSchema = CreateUserSchema.partial();

const ListUsersQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  status: z.enum(["active", "suspended", "pending"]).optional(),
  sort: z.enum(["createdAt", "name"]).default("createdAt"),
  order: z.enum(["asc", "desc"]).default("desc"),
});

// Handler: POST /api/users
export const createUserHandler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  try {
    const body = JSON.parse(event.body || '{}');
    const input = CreateUserSchema.parse(body);

    const user = await createUser(input);

    return {
      statusCode: 201,
      headers: {
        'Content-Type': 'application/json',
        'Location': `/api/users/${user.id}`,
      },
      body: JSON.stringify({
        data: user,
        links: {
          self: `/api/users/${user.id}`,
        },
      }),
    };
  } catch (error) {
    if (error instanceof z.ZodError) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          error: {
            code: 'VALIDATION_ERROR',
            message: 'Request validation failed',
            details: error.errors,
          },
        }),
      };
    }

    return {
      statusCode: 500,
      body: JSON.stringify({
        error: {
          code: 'INTERNAL_ERROR',
          message: 'An unexpected error occurred',
        },
      }),
    };
  }
};
```

## API Design Checklist

- [ ] Resource names are plural nouns
- [ ] HTTP methods used correctly (GET, POST, PUT, PATCH, DELETE)
- [ ] Consistent naming convention (camelCase or snake_case throughout)
- [ ] Request/response schemas defined with Zod
- [ ] Error responses standardized across all endpoints
- [ ] HTTP status codes appropriate for each scenario
- [ ] Pagination implemented (cursor or offset)
- [ ] Filtering, sorting, search supported
- [ ] Versioning strategy defined and documented
- [ ] Authentication/authorization requirements clear
- [ ] Rate limiting configured appropriately
- [ ] OpenAPI/Swagger spec generated
- [ ] Backward compatibility considered for changes
- [ ] Security reviewed (input validation, auth, rate limits)

## Key Takeaways

1. **Resource-oriented**: Model domain entities as resources with plural nouns
2. **HTTP semantics**: Use correct methods and status codes
3. **Consistent structure**: Same patterns across all endpoints
4. **Validate everything**: Use Zod for request validation
5. **Standard errors**: Consistent error response format
6. **Version carefully**: Breaking changes require new API version
7. **Paginate collections**: Always paginate list endpoints
8. **Security first**: Authentication, authorization, rate limiting from day one
