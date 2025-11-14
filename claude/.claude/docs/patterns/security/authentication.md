# Authentication Patterns

## Overview
Authentication verifies identity ("who are you?"), while authorization determines access rights ("what can you do?"). This guide covers production-ready authentication patterns.

## Authentication vs Authorization

**Authentication**: Identity verification
- Login with username/password
- OAuth login (Google, GitHub)
- Multi-factor authentication
- Session/token validation

**Authorization**: Access control
- Role-based access control (RBAC)
- Permission checks
- Resource ownership validation
- API scopes

**Key principle**: Authenticate first, then authorize. Never conflate the two.

## JWT Patterns

### Access + Refresh Token Strategy
```typescript
// Access token: Short-lived, contains user claims
const accessToken = jwt.sign(
  {
    userId: user.id,
    email: user.email,
    role: user.role,
  },
  ACCESS_TOKEN_SECRET,
  { expiresIn: '15m' } // Short expiry
);

// Refresh token: Long-lived, opaque, stored in database
const refreshToken = crypto.randomBytes(32).toString('hex');
await db.refreshToken.create({
  data: {
    token: refreshToken,
    userId: user.id,
    expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
  },
});

// Return both tokens
res.json({
  accessToken,
  refreshToken,
  expiresIn: 900, // 15 minutes in seconds
});
```

**Why two tokens:**
- **Access token**: Stateless, fast validation, expires quickly
- **Refresh token**: Stored in DB, allows revocation, long-lived

### Token Refresh Flow
```typescript
app.post('/auth/refresh', async (req, res) => {
  const { refreshToken } = req.body;

  // Validate refresh token from database
  const storedToken = await db.refreshToken.findUnique({
    where: { token: refreshToken },
    include: { user: true },
  });

  if (!storedToken) {
    return res.status(401).json({ error: 'Invalid refresh token' });
  }

  if (storedToken.expiresAt < new Date()) {
    await db.refreshToken.delete({ where: { id: storedToken.id } });
    return res.status(401).json({ error: 'Refresh token expired' });
  }

  // Issue new access token
  const accessToken = jwt.sign(
    {
      userId: storedToken.user.id,
      email: storedToken.user.email,
      role: storedToken.user.role,
    },
    ACCESS_TOKEN_SECRET,
    { expiresIn: '15m' }
  );

  res.json({ accessToken, expiresIn: 900 });
});
```

### JWT Claims Best Practices
```typescript
// GOOD: Minimal claims, short expiry
{
  sub: "user-id-123",           // Subject (user ID)
  email: "user@example.com",
  role: "user",                 // High-level role only
  iat: 1699564800,              // Issued at
  exp: 1699565700,              // Expires at (15 min)
  iss: "myapp.com",             // Issuer
  aud: "myapp-api"              // Audience
}

// BAD: Too many claims, sensitive data, long expiry
{
  sub: "user-id-123",
  email: "user@example.com",
  firstName: "John",            // ❌ Unnecessary claims
  lastName: "Doe",              // ❌ Increases token size
  permissions: [...100 items],  // ❌ Huge token
  creditCard: "****1234",       // ❌ Sensitive data
  exp: 1699999999               // ❌ 30 day expiry
}
```

**Guidelines:**
- Keep tokens small (<1KB)
- No sensitive data (PII, secrets)
- Short expiry (5-15 minutes)
- Include only essential claims
- Use refresh tokens for long sessions

### Token Storage

**Client-side storage options:**

1. **httpOnly Cookie** (recommended for web apps)
```typescript
res.cookie('accessToken', token, {
  httpOnly: true,    // Not accessible via JavaScript
  secure: true,      // HTTPS only
  sameSite: 'strict', // CSRF protection
  maxAge: 15 * 60 * 1000, // 15 minutes
});
```

2. **localStorage** (vulnerable to XSS)
```typescript
// ❌ Avoid: Accessible to any script
localStorage.setItem('accessToken', token);
```

3. **Memory only** (secure but lost on refresh)
```typescript
// ✓ Best for SPAs with refresh token in httpOnly cookie
let accessToken = null; // In-memory variable
```

**Best practice**: Store refresh token in httpOnly cookie, keep access token in memory.

## Session Management

### Server-Side Sessions
```typescript
import session from 'express-session';
import RedisStore from 'connect-redis';
import { createClient } from 'redis';

const redisClient = createClient();

app.use(
  session({
    store: new RedisStore({ client: redisClient }),
    secret: SESSION_SECRET,
    resave: false,
    saveUninitialized: false,
    cookie: {
      httpOnly: true,
      secure: true,
      sameSite: 'strict',
      maxAge: 24 * 60 * 60 * 1000, // 24 hours
    },
  })
);

// Set session data
app.post('/login', async (req, res) => {
  const user = await authenticateUser(req.body);
  req.session.userId = user.id;
  req.session.role = user.role;
  res.json({ success: true });
});

// Access session data
app.get('/profile', (req, res) => {
  if (!req.session.userId) {
    return res.status(401).json({ error: 'Not authenticated' });
  }
  // User is authenticated
});

// Destroy session (logout)
app.post('/logout', (req, res) => {
  req.session.destroy(err => {
    if (err) return res.status(500).json({ error: 'Logout failed' });
    res.clearCookie('connect.sid');
    res.json({ success: true });
  });
});
```

**Session vs JWT:**
- **Sessions**: Stateful, easy revocation, larger server memory
- **JWT**: Stateless, scalable, harder revocation
- **Hybrid**: JWT with refresh tokens in database (best of both)

### Session Fixation Prevention
```typescript
// Regenerate session ID after login
app.post('/login', async (req, res) => {
  const user = await authenticateUser(req.body);

  // Regenerate session (prevents fixation attack)
  req.session.regenerate(err => {
    if (err) return res.status(500).json({ error: 'Login failed' });

    req.session.userId = user.id;
    res.json({ success: true });
  });
});
```

## OAuth 2.0 / OIDC Patterns

### Authorization Code Flow (Recommended)
```typescript
import { AuthorizationCode } from 'simple-oauth2';

const oauth2 = new AuthorizationCode({
  client: {
    id: GOOGLE_CLIENT_ID,
    secret: GOOGLE_CLIENT_SECRET,
  },
  auth: {
    tokenHost: 'https://oauth2.googleapis.com',
    tokenPath: '/token',
    authorizePath: 'https://accounts.google.com/o/oauth2/v2/auth',
  },
});

// Step 1: Redirect to OAuth provider
app.get('/auth/google', (req, res) => {
  const authorizationUri = oauth2.authorizeURL({
    redirect_uri: 'https://myapp.com/auth/google/callback',
    scope: 'openid email profile',
    state: crypto.randomBytes(16).toString('hex'), // CSRF protection
  });

  // Store state in session for validation
  req.session.oauthState = authorizationUri.state;

  res.redirect(authorizationUri);
});

// Step 2: Handle callback
app.get('/auth/google/callback', async (req, res) => {
  const { code, state } = req.query;

  // Validate state (CSRF protection)
  if (state !== req.session.oauthState) {
    return res.status(403).json({ error: 'Invalid state' });
  }

  // Exchange code for tokens
  const result = await oauth2.getToken({
    code,
    redirect_uri: 'https://myapp.com/auth/google/callback',
  });

  const { access_token, id_token } = result.token;

  // Verify and decode ID token
  const userInfo = jwt.decode(id_token);

  // Create or update user
  const user = await db.user.upsert({
    where: { email: userInfo.email },
    create: {
      email: userInfo.email,
      name: userInfo.name,
      oauthProvider: 'google',
      oauthId: userInfo.sub,
    },
    update: {
      name: userInfo.name,
    },
  });

  // Create session
  req.session.userId = user.id;
  res.redirect('/dashboard');
});
```

### PKCE for Public Clients
Use PKCE (Proof Key for Code Exchange) for mobile/SPA apps:

```typescript
// Generate code verifier and challenge
const codeVerifier = crypto.randomBytes(32).toString('base64url');
const codeChallenge = crypto
  .createHash('sha256')
  .update(codeVerifier)
  .digest('base64url');

// Authorization request with PKCE
const authUrl = oauth2.authorizeURL({
  redirect_uri: 'myapp://callback',
  code_challenge: codeChallenge,
  code_challenge_method: 'S256',
});

// Token request with code verifier
const result = await oauth2.getToken({
  code,
  redirect_uri: 'myapp://callback',
  code_verifier: codeVerifier,
});
```

## Password Security

### Hashing with bcrypt
```typescript
import bcrypt from 'bcrypt';

// Hash password (register)
const SALT_ROUNDS = 12; // Higher = more secure but slower
const hashedPassword = await bcrypt.hash(plainPassword, SALT_ROUNDS);

await db.user.create({
  data: {
    email,
    passwordHash: hashedPassword,
  },
});

// Verify password (login)
const user = await db.user.findUnique({ where: { email } });
if (!user) {
  return res.status(401).json({ error: 'Invalid credentials' });
}

const isValid = await bcrypt.compare(plainPassword, user.passwordHash);
if (!isValid) {
  return res.status(401).json({ error: 'Invalid credentials' });
}

// Valid credentials
```

### Argon2 (More Secure Alternative)
```typescript
import argon2 from 'argon2';

// Hash password
const hashedPassword = await argon2.hash(plainPassword);

// Verify password
const isValid = await argon2.verify(hashedPassword, plainPassword);
```

**Why Argon2:**
- Winner of Password Hashing Competition (2015)
- Resistant to GPU/ASIC attacks
- Memory-hard algorithm
- Recommended by OWASP

**Choose bcrypt if:**
- Legacy system compatibility required
- Team familiarity

**Choose argon2 if:**
- New project
- Maximum security needed
- Modern infrastructure

### Password Policies
```typescript
function validatePassword(password: string): { valid: boolean; errors: string[] } {
  const errors: string[] = [];

  if (password.length < 12) {
    errors.push('Password must be at least 12 characters');
  }

  if (!/[a-z]/.test(password)) {
    errors.push('Password must contain lowercase letter');
  }

  if (!/[A-Z]/.test(password)) {
    errors.push('Password must contain uppercase letter');
  }

  if (!/[0-9]/.test(password)) {
    errors.push('Password must contain number');
  }

  if (!/[^a-zA-Z0-9]/.test(password)) {
    errors.push('Password must contain special character');
  }

  // Check against common passwords
  if (COMMON_PASSWORDS.includes(password.toLowerCase())) {
    errors.push('Password is too common');
  }

  return {
    valid: errors.length === 0,
    errors,
  };
}
```

**NIST 800-63B Guidelines:**
- Minimum 12 characters (not 8)
- No complexity requirements (allow passphrases)
- Check against breach databases
- No periodic rotation requirements
- Allow all printable ASCII + spaces

## Multi-Factor Authentication

### TOTP (Time-Based One-Time Password)
```typescript
import speakeasy from 'speakeasy';
import QRCode from 'qrcode';

// Generate secret for user
app.post('/mfa/setup', async (req, res) => {
  const secret = speakeasy.generateSecret({
    name: `MyApp (${user.email})`,
  });

  // Store secret in database
  await db.user.update({
    where: { id: user.id },
    data: { mfaSecret: secret.base32 },
  });

  // Generate QR code
  const qrCodeUrl = await QRCode.toDataURL(secret.otpauth_url);

  res.json({
    secret: secret.base32,
    qrCode: qrCodeUrl,
  });
});

// Verify TOTP code
app.post('/mfa/verify', async (req, res) => {
  const { code } = req.body;

  const verified = speakeasy.totp.verify({
    secret: user.mfaSecret,
    encoding: 'base32',
    token: code,
    window: 1, // Allow 1 step before/after
  });

  if (!verified) {
    return res.status(401).json({ error: 'Invalid MFA code' });
  }

  // Mark MFA as enabled
  await db.user.update({
    where: { id: user.id },
    data: { mfaEnabled: true },
  });

  res.json({ success: true });
});
```

### Backup Codes
```typescript
// Generate backup codes
function generateBackupCodes(count = 10): string[] {
  return Array.from({ length: count }, () =>
    crypto.randomBytes(4).toString('hex').toUpperCase()
  );
}

// Store hashed backup codes
const backupCodes = generateBackupCodes();
await db.backupCode.createMany({
  data: backupCodes.map(code => ({
    userId: user.id,
    codeHash: crypto.createHash('sha256').update(code).digest('hex'),
  })),
});

// Return plaintext codes to user (show once)
res.json({ backupCodes });

// Verify backup code (use once)
const codeHash = crypto.createHash('sha256').update(code).digest('hex');
const backupCode = await db.backupCode.findFirst({
  where: { userId: user.id, codeHash, used: false },
});

if (backupCode) {
  await db.backupCode.update({
    where: { id: backupCode.id },
    data: { used: true, usedAt: new Date() },
  });
}
```

## Common Vulnerabilities

### Timing Attacks
```typescript
// ❌ Vulnerable: Different response times reveal valid usernames
const user = await db.user.findUnique({ where: { email } });
if (!user) {
  return res.status(401).json({ error: 'User not found' });
}

const isValid = await bcrypt.compare(password, user.passwordHash);
if (!isValid) {
  return res.status(401).json({ error: 'Invalid password' });
}

// ✓ Secure: Constant-time comparison
const user = await db.user.findUnique({ where: { email } });
const dummyHash = '$2b$12$dummyhashforinvalidusers';
const hashToCompare = user ? user.passwordHash : dummyHash;

const isValid = await bcrypt.compare(password, hashToCompare);

if (!user || !isValid) {
  return res.status(401).json({ error: 'Invalid credentials' });
}
```

### Session Hijacking
**Prevention:**
- Use httpOnly cookies
- Set secure flag (HTTPS only)
- Regenerate session ID on login
- Implement session timeout
- Bind session to IP address (optional)

### Brute Force Attacks
```typescript
import rateLimit from 'express-rate-limit';

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 attempts
  message: 'Too many login attempts, please try again later',
  standardHeaders: true,
  legacyHeaders: false,
});

app.post('/login', loginLimiter, async (req, res) => {
  // Login logic
});
```

### Credential Stuffing
Check against breach databases:

```typescript
import axios from 'axios';
import crypto from 'crypto';

async function isPasswordBreached(password: string): Promise<boolean> {
  // Use HaveIBeenPwned API (k-anonymity)
  const hash = crypto.createHash('sha1').update(password).digest('hex').toUpperCase();
  const prefix = hash.substring(0, 5);
  const suffix = hash.substring(5);

  const response = await axios.get(`https://api.pwnedpasswords.com/range/${prefix}`);
  const hashes = response.data.split('\n');

  return hashes.some((line: string) => line.startsWith(suffix));
}
```

## Testing Authentication
```typescript
describe('Authentication', () => {
  test('issues JWT on valid credentials', async () => {
    const response = await request(app)
      .post('/login')
      .send({ email: 'user@example.com', password: 'password123' });

    expect(response.status).toBe(200);
    expect(response.body.accessToken).toBeDefined();
    expect(response.body.refreshToken).toBeDefined();

    // Verify token is valid
    const decoded = jwt.verify(response.body.accessToken, ACCESS_TOKEN_SECRET);
    expect(decoded.userId).toBe(user.id);
  });

  test('rejects invalid credentials', async () => {
    const response = await request(app)
      .post('/login')
      .send({ email: 'user@example.com', password: 'wrong' });

    expect(response.status).toBe(401);
    expect(response.body.accessToken).toBeUndefined();
  });

  test('refresh token flow works', async () => {
    const { refreshToken } = await loginUser();

    const response = await request(app)
      .post('/auth/refresh')
      .send({ refreshToken });

    expect(response.status).toBe(200);
    expect(response.body.accessToken).toBeDefined();
  });
});
```

## Related
- [OWASP Top 10](./owasp-top-10.md)
- [Security Best Practices](../general/security.md)
- [API Security](../api/security.md)
