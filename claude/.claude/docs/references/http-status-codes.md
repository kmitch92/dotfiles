# HTTP Status Codes Reference

## Overview
HTTP status codes indicate the outcome of HTTP requests. This reference provides practical guidance for RESTful API development.

## Quick Reference

| Code | Name | Use Case |
|------|------|----------|
| 200 | OK | Successful GET, PUT, PATCH (returns data) |
| 201 | Created | Successful POST (resource created) |
| 204 | No Content | Successful DELETE, PUT, PATCH (no data returned) |
| 400 | Bad Request | Invalid input/validation error |
| 401 | Unauthorized | Missing or invalid authentication |
| 403 | Forbidden | Valid auth but insufficient permissions |
| 404 | Not Found | Resource doesn't exist |
| 409 | Conflict | Resource state conflict (e.g., duplicate) |
| 422 | Unprocessable Entity | Semantic validation error |
| 500 | Internal Server Error | Unexpected server error |
| 503 | Service Unavailable | Temporary unavailability |

## 1xx Informational

### 100 Continue
Server received request headers, client should send body.

**Use case**: Large file uploads with `Expect: 100-continue` header.

**Example**:
```typescript
// Client sends headers first
// Server responds with 100 Continue
// Client sends body
```

**Rare in REST APIs.** Most HTTP clients handle automatically.

### 101 Switching Protocols
Switching to WebSocket or HTTP/2.

**Use case**: WebSocket upgrade.

```typescript
// HTTP/1.1 101 Switching Protocols
// Upgrade: websocket
// Connection: Upgrade
```

## 2xx Success

### 200 OK
Request succeeded, response contains data.

**Use case**:
- GET requests returning data
- PUT/PATCH returning updated resource
- POST returning data (if not creating resource)

**Examples**:
```typescript
// GET /users/123
app.get('/users/:id', async (req, res) => {
  const user = await db.user.findUnique({ where: { id: req.params.id } });
  if (!user) {
    return res.status(404).json({ error: 'User not found' });
  }
  res.status(200).json(user);
});

// PUT /users/123 (returning updated resource)
app.put('/users/:id', async (req, res) => {
  const user = await db.user.update({
    where: { id: req.params.id },
    data: req.body,
  });
  res.status(200).json(user);
});
```

### 201 Created
Resource successfully created.

**Requirements**:
- Include `Location` header with new resource URL
- Return created resource in body (optional but recommended)

**Example**:
```typescript
app.post('/users', async (req, res) => {
  const user = await db.user.create({ data: req.body });
  res
    .status(201)
    .location(`/users/${user.id}`)
    .json(user);
});
```

### 202 Accepted
Request accepted for processing, but not completed.

**Use case**: Async operations (background jobs, webhooks).

**Example**:
```typescript
app.post('/reports/generate', async (req, res) => {
  const jobId = await queue.enqueue('generate-report', req.body);
  res.status(202).json({
    message: 'Report generation started',
    jobId,
    statusUrl: `/jobs/${jobId}`,
  });
});
```

### 204 No Content
Request succeeded, no content to return.

**Use case**:
- DELETE operations
- PUT/PATCH when not returning updated resource
- Actions that don't produce data

**Example**:
```typescript
app.delete('/users/:id', async (req, res) => {
  await db.user.delete({ where: { id: req.params.id } });
  res.status(204).send();
});

app.patch('/users/:id/activate', async (req, res) => {
  await db.user.update({
    where: { id: req.params.id },
    data: { status: 'active' },
  });
  res.status(204).send();
});
```

### 206 Partial Content
Partial GET request (range request).

**Use case**: Large file downloads, video streaming.

**Example**:
```typescript
app.get('/videos/:id', (req, res) => {
  const range = req.headers.range;
  if (!range) {
    return res.status(200).sendFile(videoPath);
  }

  const videoSize = fs.statSync(videoPath).size;
  const [start, end] = range.replace(/bytes=/, '').split('-').map(Number);
  const chunkSize = (end || videoSize - 1) - start + 1;

  res.status(206)
    .header('Content-Range', `bytes ${start}-${end || videoSize - 1}/${videoSize}`)
    .header('Accept-Ranges', 'bytes')
    .header('Content-Length', chunkSize)
    .header('Content-Type', 'video/mp4');

  fs.createReadStream(videoPath, { start, end }).pipe(res);
});
```

## 3xx Redirection

### 301 Moved Permanently
Resource permanently moved to new URL.

**Use case**: URL structure changes, API versioning.

**Example**:
```typescript
app.get('/api/v1/users', (req, res) => {
  res.redirect(301, '/api/v2/users');
});
```

### 302 Found / 307 Temporary Redirect
Resource temporarily at different URL.

**Difference**:
- 302: May change method to GET
- 307: Preserves method

**Example**:
```typescript
app.post('/login', async (req, res) => {
  const user = await authenticateUser(req.body);
  res.redirect(307, '/dashboard'); // Maintains POST
});
```

### 304 Not Modified
Resource not modified since last request (caching).

**Use case**: Conditional requests with `If-None-Match` or `If-Modified-Since`.

**Example**:
```typescript
app.get('/users/:id', async (req, res) => {
  const user = await db.user.findUnique({ where: { id: req.params.id } });
  const etag = `"${user.updatedAt.getTime()}"`;

  if (req.headers['if-none-match'] === etag) {
    return res.status(304).end();
  }

  res.setHeader('ETag', etag);
  res.status(200).json(user);
});
```

## 4xx Client Errors

### 400 Bad Request
Generic client error for invalid requests.

**Use case**:
- Malformed JSON
- Missing required fields
- Invalid data types
- General validation errors

**Example**:
```typescript
app.post('/users', async (req, res) => {
  try {
    const user = UserSchema.parse(req.body); // Zod validation
    const created = await db.user.create({ data: user });
    res.status(201).json(created);
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({
        error: 'Validation failed',
        details: error.errors,
      });
    }
    throw error;
  }
});
```

### 401 Unauthorized
Missing or invalid authentication.

**Use case**:
- No auth token provided
- Invalid/expired token
- Invalid credentials

**Example**:
```typescript
function authenticate(req: Request, res: Response, next: NextFunction) {
  const token = req.headers.authorization?.replace('Bearer ', '');

  if (!token) {
    return res.status(401).json({
      error: 'Authentication required',
      message: 'Please provide a valid access token',
    });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(401).json({
      error: 'Invalid token',
      message: 'Token expired or invalid',
    });
  }
}
```

### 403 Forbidden
Valid authentication but insufficient permissions.

**Use case**:
- Role-based access control
- Resource ownership validation
- Feature flags

**Example**:
```typescript
app.delete('/posts/:id', authenticate, async (req, res) => {
  const post = await db.post.findUnique({ where: { id: req.params.id } });

  if (!post) {
    return res.status(404).json({ error: 'Post not found' });
  }

  // Check ownership or admin role
  if (post.authorId !== req.user.id && req.user.role !== 'admin') {
    return res.status(403).json({
      error: 'Forbidden',
      message: 'You do not have permission to delete this post',
    });
  }

  await db.post.delete({ where: { id: req.params.id } });
  res.status(204).send();
});
```

### 404 Not Found
Resource doesn't exist.

**Use case**:
- Invalid resource ID
- Endpoint doesn't exist
- Resource was deleted

**Example**:
```typescript
app.get('/users/:id', async (req, res) => {
  const user = await db.user.findUnique({ where: { id: req.params.id } });

  if (!user) {
    return res.status(404).json({
      error: 'Not found',
      message: 'User does not exist',
    });
  }

  res.status(200).json(user);
});
```

### 405 Method Not Allowed
HTTP method not supported for endpoint.

**Requirements**: Include `Allow` header with supported methods.

**Example**:
```typescript
app.all('/users/:id', (req, res) => {
  const allowedMethods = ['GET', 'PUT', 'DELETE'];

  if (!allowedMethods.includes(req.method)) {
    return res
      .status(405)
      .header('Allow', allowedMethods.join(', '))
      .json({
        error: 'Method not allowed',
        message: `${req.method} not supported for this endpoint`,
      });
  }

  // Handle allowed methods
});
```

### 409 Conflict
Request conflicts with current resource state.

**Use case**:
- Duplicate resource (unique constraint violation)
- Concurrent modification
- Resource state conflict

**Example**:
```typescript
app.post('/users', async (req, res) => {
  try {
    const user = await db.user.create({ data: req.body });
    res.status(201).json(user);
  } catch (error) {
    if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
      return res.status(409).json({
        error: 'Conflict',
        message: 'User with this email already exists',
      });
    }
    throw error;
  }
});
```

### 410 Gone
Resource permanently deleted (vs 404: never existed).

**Use case**: Soft-deleted resources, expired offers.

**Example**:
```typescript
app.get('/posts/:id', async (req, res) => {
  const post = await db.post.findUnique({ where: { id: req.params.id } });

  if (!post) {
    return res.status(404).json({ error: 'Post not found' });
  }

  if (post.deletedAt) {
    return res.status(410).json({
      error: 'Gone',
      message: 'This post has been permanently deleted',
    });
  }

  res.status(200).json(post);
});
```

### 422 Unprocessable Entity
Semantic validation error (syntax valid, semantics invalid).

**Use case**:
- Business rule violations
- Invalid state transitions
- Semantic constraints

**Example**:
```typescript
app.post('/orders', async (req, res) => {
  const { items } = req.body;

  // Syntax valid (correct JSON, types), but semantics invalid
  if (items.length === 0) {
    return res.status(422).json({
      error: 'Unprocessable entity',
      message: 'Order must contain at least one item',
    });
  }

  const product = await db.product.findUnique({ where: { id: items[0].productId } });

  if (product.stock < items[0].quantity) {
    return res.status(422).json({
      error: 'Unprocessable entity',
      message: 'Insufficient stock for this product',
    });
  }

  const order = await db.order.create({ data: req.body });
  res.status(201).json(order);
});
```

### 429 Too Many Requests
Rate limit exceeded.

**Requirements**: Include `Retry-After` header.

**Example**:
```typescript
import rateLimit from 'express-rate-limit';

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // 100 requests per window
  standardHeaders: true, // Return rate limit info in headers
  legacyHeaders: false,
  handler: (req, res) => {
    res.status(429).json({
      error: 'Too many requests',
      message: 'Rate limit exceeded, please try again later',
    });
  },
});

app.use('/api', limiter);
```

## 5xx Server Errors

### 500 Internal Server Error
Generic server error.

**Use case**: Unexpected errors, unhandled exceptions.

**Example**:
```typescript
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  logger.error('Unhandled error', { error: err, path: req.path });

  if (process.env.NODE_ENV === 'production') {
    res.status(500).json({
      error: 'Internal server error',
      message: 'An unexpected error occurred',
    });
  } else {
    res.status(500).json({
      error: 'Internal server error',
      message: err.message,
      stack: err.stack,
    });
  }
});
```

### 502 Bad Gateway
Invalid response from upstream server.

**Use case**: Proxy/gateway received invalid response.

**Example**:
```typescript
app.get('/external-api', async (req, res) => {
  try {
    const response = await fetch('https://external-api.com/data');

    if (!response.ok) {
      return res.status(502).json({
        error: 'Bad gateway',
        message: 'Upstream service returned invalid response',
      });
    }

    const data = await response.json();
    res.status(200).json(data);
  } catch (error) {
    res.status(502).json({
      error: 'Bad gateway',
      message: 'Failed to reach upstream service',
    });
  }
});
```

### 503 Service Unavailable
Server temporarily unavailable.

**Use case**:
- Maintenance mode
- Overloaded server
- Dependency unavailable

**Requirements**: Include `Retry-After` header.

**Example**:
```typescript
app.use((req, res, next) => {
  if (process.env.MAINTENANCE_MODE === 'true') {
    return res
      .status(503)
      .header('Retry-After', '3600') // 1 hour
      .json({
        error: 'Service unavailable',
        message: 'System maintenance in progress',
      });
  }
  next();
});
```

### 504 Gateway Timeout
Upstream server didn't respond in time.

**Use case**: Timeout waiting for upstream service.

**Example**:
```typescript
app.get('/slow-api', async (req, res) => {
  const timeout = setTimeout(() => {
    res.status(504).json({
      error: 'Gateway timeout',
      message: 'Upstream service took too long to respond',
    });
  }, 10000); // 10 second timeout

  try {
    const response = await fetch('https://slow-api.com/data');
    clearTimeout(timeout);

    const data = await response.json();
    res.status(200).json(data);
  } catch (error) {
    clearTimeout(timeout);
    res.status(504).json({
      error: 'Gateway timeout',
      message: 'Request to upstream service timed out',
    });
  }
});
```

## Common Patterns

### 200 vs 201
```typescript
// 201: Resource created (POST)
app.post('/users', async (req, res) => {
  const user = await db.user.create({ data: req.body });
  res.status(201).location(`/users/${user.id}`).json(user);
});

// 200: Data returned, no creation (GET, PUT, PATCH)
app.get('/users/:id', async (req, res) => {
  const user = await db.user.findUnique({ where: { id: req.params.id } });
  res.status(200).json(user);
});
```

### 400 vs 422
```typescript
// 400: Syntactic error (invalid JSON, wrong types)
app.post('/users', (req, res) => {
  if (typeof req.body.email !== 'string') {
    return res.status(400).json({ error: 'Email must be a string' });
  }
  // ...
});

// 422: Semantic error (valid syntax, invalid meaning)
app.post('/users', (req, res) => {
  if (!req.body.email.includes('@')) {
    return res.status(422).json({ error: 'Email must be valid format' });
  }
  // ...
});
```

### 401 vs 403
```typescript
// 401: Not authenticated
app.get('/profile', (req, res) => {
  if (!req.headers.authorization) {
    return res.status(401).json({ error: 'Authentication required' });
  }
  // ...
});

// 403: Authenticated but not authorized
app.delete('/users/:id', authenticate, (req, res) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Admin access required' });
  }
  // ...
});
```

### 404 vs 410
```typescript
// 404: Resource never existed or doesn't exist
app.get('/users/:id', async (req, res) => {
  const user = await db.user.findUnique({ where: { id: req.params.id } });
  if (!user) {
    return res.status(404).json({ error: 'User not found' });
  }
  // ...
});

// 410: Resource existed but permanently removed
app.get('/users/:id', async (req, res) => {
  const user = await db.user.findUnique({ where: { id: req.params.id } });
  if (user?.deletedAt) {
    return res.status(410).json({ error: 'User permanently deleted' });
  }
  // ...
});
```

## Response Format Best Practices

### Success Response
```typescript
// Simple data
{ "id": "123", "name": "John Doe", "email": "john@example.com" }

// Collection
{ "items": [...], "total": 100, "page": 1, "pageSize": 20 }

// Action result
{ "success": true, "message": "User activated" }
```

### Error Response
```typescript
// Minimal
{ "error": "Not found", "message": "User does not exist" }

// With details
{
  "error": "Validation failed",
  "message": "Request contains invalid data",
  "details": [
    { "field": "email", "message": "Invalid email format" },
    { "field": "age", "message": "Must be at least 18" }
  ]
}
```

## Related
- [API Design Patterns](../patterns/api/rest-design.md)
- [Error Handling](../patterns/general/error-handling.md)
- [Authentication](../patterns/security/authentication.md)
