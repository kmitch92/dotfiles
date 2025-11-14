# OWASP Top 10 Security Risks (2021)

## Overview
The OWASP Top 10 represents the most critical web application security risks. This guide provides practical prevention strategies for Node.js/TypeScript applications.

## A01:2021 - Broken Access Control

### Description
Users can act outside their intended permissions, accessing unauthorized data or functionality.

### Common Vulnerabilities
- Missing authorization checks
- Insecure Direct Object References (IDOR)
- Privilege escalation
- CORS misconfiguration

### Examples
```typescript
// ❌ Vulnerable: No ownership check
app.delete('/api/posts/:id', authenticate, async (req, res) => {
  await db.post.delete({ where: { id: req.params.id } });
  res.json({ success: true });
});
// User can delete ANY post, not just their own

// ✓ Secure: Verify ownership
app.delete('/api/posts/:id', authenticate, async (req, res) => {
  const post = await db.post.findUnique({ where: { id: req.params.id } });

  if (!post) {
    return res.status(404).json({ error: 'Post not found' });
  }

  if (post.authorId !== req.user.id) {
    return res.status(403).json({ error: 'Forbidden' });
  }

  await db.post.delete({ where: { id: req.params.id } });
  res.json({ success: true });
});
```

### Prevention
- Deny by default (require explicit permission)
- Validate ownership on every request
- Use role-based access control (RBAC)
- Test with different user roles
- Log access control failures

## A02:2021 - Cryptographic Failures

### Description
Exposure of sensitive data due to weak or missing encryption.

### Common Vulnerabilities
- Storing passwords in plaintext
- Weak hashing algorithms (MD5, SHA1)
- Sensitive data in logs/error messages
- Unencrypted data transmission (HTTP)

### Examples
```typescript
// ❌ Vulnerable: Plaintext password
await db.user.create({
  data: { email, password } // Never store plaintext!
});

// ✓ Secure: Hash with bcrypt/argon2
import bcrypt from 'bcrypt';
const passwordHash = await bcrypt.hash(password, 12);
await db.user.create({
  data: { email, passwordHash }
});

// ❌ Vulnerable: Sensitive data in logs
logger.error('Payment failed', { creditCard: '4111111111111111' });

// ✓ Secure: Redact sensitive data
logger.error('Payment failed', { creditCard: '****1111' });
```

### Prevention
- Use TLS/HTTPS for all connections
- Hash passwords with bcrypt/argon2
- Encrypt sensitive data at rest
- Avoid sensitive data in URLs/logs
- Use strong encryption (AES-256)
- Implement key rotation

## A03:2021 - Injection

### Description
Untrusted data sent to interpreter as part of command/query, tricking it into executing unintended commands.

### Types
- SQL Injection
- NoSQL Injection
- Command Injection
- LDAP Injection

### SQL Injection Examples
```typescript
// ❌ Vulnerable: String concatenation
const query = `SELECT * FROM users WHERE email = '${userInput}'`;
// Input: ' OR '1'='1
// Result: SELECT * FROM users WHERE email = '' OR '1'='1'
// Returns all users!

// ✓ Secure: Parameterized queries
const query = 'SELECT * FROM users WHERE email = ?';
const result = await db.query(query, [userInput]);

// ✓ Secure: ORM (Prisma)
const user = await db.user.findUnique({
  where: { email: userInput } // Automatically parameterized
});
```

### Command Injection
```typescript
// ❌ Vulnerable: Executing shell commands with user input
const filename = req.query.file;
exec(`cat ${filename}`, (error, stdout) => {
  res.send(stdout);
});
// Input: file.txt; rm -rf /
// Executes: cat file.txt; rm -rf /

// ✓ Secure: Validate and sanitize input
const filename = path.basename(req.query.file); // Remove path traversal
const safePath = path.join(SAFE_DIRECTORY, filename);

// Check file is within allowed directory
if (!safePath.startsWith(SAFE_DIRECTORY)) {
  return res.status(400).json({ error: 'Invalid filename' });
}

// Use filesystem API instead of shell
const content = await fs.promises.readFile(safePath, 'utf-8');
res.send(content);
```

### Prevention
- Use parameterized queries (prepared statements)
- Use ORMs (Prisma, TypeORM)
- Validate and sanitize all input
- Use allow-lists for validation
- Avoid shell command execution with user input
- Principle of least privilege (limited DB permissions)

## A04:2021 - Insecure Design

### Description
Missing or ineffective security controls due to design flaws.

### Examples
```typescript
// ❌ Vulnerable: Forgot password without rate limiting
app.post('/forgot-password', async (req, res) => {
  const { email } = req.body;
  await sendPasswordResetEmail(email);
  res.json({ success: true });
});
// Attacker can enumerate valid emails by sending many requests

// ✓ Secure: Rate limiting + generic response
import rateLimit from 'express-rate-limit';

const forgotPasswordLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 3, // 3 attempts per hour
});

app.post('/forgot-password', forgotPasswordLimiter, async (req, res) => {
  const { email } = req.body;

  const user = await db.user.findUnique({ where: { email } });
  if (user) {
    await sendPasswordResetEmail(email);
  }

  // Always return success (don't reveal if email exists)
  res.json({ message: 'If account exists, reset email sent' });
});
```

### Prevention
- Threat modeling during design phase
- Security requirements in user stories
- Secure by default (deny by default)
- Rate limiting on sensitive endpoints
- Input validation at design level
- Security code review

## A05:2021 - Security Misconfiguration

### Description
Missing security hardening, default credentials, verbose error messages.

### Examples
```typescript
// ❌ Vulnerable: Exposing stack traces
app.use((err, req, res, next) => {
  res.status(500).json({
    error: err.message,
    stack: err.stack // Exposes internal structure!
  });
});

// ✓ Secure: Generic error in production
app.use((err, req, res, next) => {
  logger.error('Unhandled error', { error: err });

  if (process.env.NODE_ENV === 'production') {
    res.status(500).json({ error: 'Internal server error' });
  } else {
    res.status(500).json({ error: err.message, stack: err.stack });
  }
});

// ❌ Vulnerable: CORS allow all
app.use(cors({ origin: '*' }));

// ✓ Secure: Specific origins
app.use(cors({
  origin: ['https://myapp.com', 'https://www.myapp.com'],
  credentials: true,
}));
```

### Prevention
- Disable directory listing
- Remove default accounts
- Keep dependencies updated
- Minimal error messages in production
- Security headers (helmet.js)
- Regular security scanning

## A06:2021 - Vulnerable and Outdated Components

### Description
Using components with known vulnerabilities.

### Prevention
```bash
# Check for vulnerabilities
npm audit

# Fix automatically (where possible)
npm audit fix

# Use Dependabot/Renovate for automated updates
```

```typescript
// Use Snyk to scan for vulnerabilities
// .github/workflows/security.yml
name: Security Scan
on: [push, pull_request]
jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
```

### Best Practices
- Monitor security advisories
- Keep dependencies updated
- Remove unused dependencies
- Use lock files (package-lock.json)
- Automated dependency updates
- Regular security audits

## A07:2021 - Identification and Authentication Failures

### Description
Broken authentication allowing attackers to compromise accounts.

### Examples
```typescript
// ❌ Vulnerable: Weak session timeout
app.use(session({
  cookie: { maxAge: 30 * 24 * 60 * 60 * 1000 } // 30 days!
}));

// ✓ Secure: Short session timeout + refresh tokens
app.use(session({
  cookie: {
    maxAge: 15 * 60 * 1000, // 15 minutes
    httpOnly: true,
    secure: true,
    sameSite: 'strict',
  }
}));

// ❌ Vulnerable: Weak password requirements
if (password.length < 6) {
  return res.status(400).json({ error: 'Password too short' });
}

// ✓ Secure: Strong password policy
if (password.length < 12) {
  return res.status(400).json({ error: 'Password must be at least 12 characters' });
}

if (await isPasswordBreached(password)) {
  return res.status(400).json({ error: 'Password found in breach database' });
}
```

### Prevention
- Implement multi-factor authentication
- Strong password requirements (12+ chars)
- Check against breach databases
- Rate limiting on login attempts
- Secure session management
- No default credentials

**See:** [Authentication Patterns](./authentication.md)

## A08:2021 - Software and Data Integrity Failures

### Description
Code/infrastructure that doesn't protect against integrity violations.

### Examples
```typescript
// ❌ Vulnerable: Deserializing untrusted data
const userData = JSON.parse(req.body.data);
eval(userData.code); // NEVER use eval with user data!

// ✓ Secure: Validate before deserialization
import { z } from 'zod';

const UserSchema = z.object({
  name: z.string().max(100),
  email: z.string().email(),
  age: z.number().int().min(0).max(120),
});

const userData = UserSchema.parse(req.body.data); // Throws if invalid

// ❌ Vulnerable: Unsigned updates
app.post('/webhook', async (req, res) => {
  const payload = req.body;
  await processWebhook(payload); // Trust external data!
});

// ✓ Secure: Verify signature
app.post('/webhook', async (req, res) => {
  const signature = req.headers['x-signature'];
  const payload = JSON.stringify(req.body);

  const expectedSignature = crypto
    .createHmac('sha256', WEBHOOK_SECRET)
    .update(payload)
    .digest('hex');

  if (signature !== expectedSignature) {
    return res.status(401).json({ error: 'Invalid signature' });
  }

  await processWebhook(req.body);
  res.json({ success: true });
});
```

### Prevention
- Verify digital signatures
- Use Zod/validation libraries
- Subresource Integrity (SRI) for CDN assets
- Verify package checksums
- Code review for updates
- CI/CD pipeline security

## A09:2021 - Security Logging and Monitoring Failures

### Description
Insufficient logging allowing attacks to go undetected.

### Examples
```typescript
// ❌ Vulnerable: No logging
app.post('/login', async (req, res) => {
  const user = await authenticateUser(req.body);
  if (!user) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }
  res.json({ success: true });
});

// ✓ Secure: Comprehensive logging
app.post('/login', async (req, res) => {
  const { email } = req.body;

  logger.info('Login attempt', {
    email,
    ip: req.ip,
    userAgent: req.headers['user-agent'],
  });

  const user = await authenticateUser(req.body);

  if (!user) {
    logger.warn('Failed login attempt', {
      email,
      ip: req.ip,
      reason: 'Invalid credentials',
    });
    return res.status(401).json({ error: 'Invalid credentials' });
  }

  logger.info('Successful login', {
    userId: user.id,
    email,
    ip: req.ip,
  });

  res.json({ success: true });
});
```

### What to Log
**Security events:**
- Login attempts (success/failure)
- Password resets
- Account changes
- Access control failures
- Input validation failures

**DO NOT log:**
- Passwords
- Session tokens
- Credit card numbers
- API keys
- Other sensitive data

### Prevention
- Log security-relevant events
- Include context (user ID, IP, timestamp)
- Centralized logging (CloudWatch, Datadog)
- Real-time alerts for suspicious activity
- Regular log review
- Tamper-proof logs

## A10:2021 - Server-Side Request Forgery (SSRF)

### Description
Fetching remote resources without validating user-supplied URL.

### Examples
```typescript
// ❌ Vulnerable: Fetch arbitrary URLs
app.get('/fetch', async (req, res) => {
  const url = req.query.url;
  const response = await fetch(url); // Attacker can access internal services!
  res.send(await response.text());
});
// Attack: /fetch?url=http://localhost:6379/
// Can access Redis, databases, cloud metadata endpoint

// ✓ Secure: Validate URL against allow-list
const ALLOWED_DOMAINS = ['api.example.com', 'cdn.example.com'];

app.get('/fetch', async (req, res) => {
  const url = new URL(req.query.url);

  // Check protocol
  if (!['http:', 'https:'].includes(url.protocol)) {
    return res.status(400).json({ error: 'Invalid protocol' });
  }

  // Check domain
  if (!ALLOWED_DOMAINS.includes(url.hostname)) {
    return res.status(400).json({ error: 'Domain not allowed' });
  }

  // Prevent IP addresses and localhost
  if (/^\d+\.\d+\.\d+\.\d+$/.test(url.hostname) || url.hostname === 'localhost') {
    return res.status(400).json({ error: 'IP addresses not allowed' });
  }

  const response = await fetch(url.toString());
  res.send(await response.text());
});
```

### Cloud Metadata Endpoints
```typescript
// AWS: Block access to instance metadata
const BLOCKED_IPS = [
  '169.254.169.254', // AWS metadata
  '::ffff:169.254.169.254',
  '127.0.0.1',
  'localhost',
];

function isBlockedIP(hostname: string): boolean {
  return BLOCKED_IPS.some(ip => hostname.includes(ip));
}
```

### Prevention
- URL allow-lists (not deny-lists)
- Disable HTTP redirects
- Network segmentation
- Block private IP ranges
- Validate and sanitize URLs
- Use dedicated service for external requests

## Security Testing Checklist

```typescript
// Example security test suite
describe('Security Tests', () => {
  test('prevents SQL injection', async () => {
    const response = await request(app)
      .get('/users')
      .query({ email: "' OR '1'='1" });

    expect(response.status).not.toBe(200);
  });

  test('requires authentication', async () => {
    const response = await request(app)
      .get('/api/profile');

    expect(response.status).toBe(401);
  });

  test('validates ownership', async () => {
    const response = await request(app)
      .delete(`/api/posts/${otherUserPost.id}`)
      .set('Authorization', `Bearer ${userToken}`);

    expect(response.status).toBe(403);
  });

  test('rate limits sensitive endpoints', async () => {
    const requests = Array.from({ length: 10 }, () =>
      request(app).post('/login').send({ email, password: 'wrong' })
    );

    const responses = await Promise.all(requests);
    const tooManyRequests = responses.filter(r => r.status === 429);

    expect(tooManyRequests.length).toBeGreaterThan(0);
  });
});
```

## Security Headers

```typescript
import helmet from 'helmet';

app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true,
  },
}));
```

## Resources
- [OWASP Top 10 2021](https://owasp.org/Top10/)
- [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/)
- [Node.js Security Best Practices](https://nodejs.org/en/docs/guides/security/)

## Related
- [Authentication Patterns](./authentication.md)
- [API Security](../api/security.md)
- [Input Validation](../general/validation.md)
