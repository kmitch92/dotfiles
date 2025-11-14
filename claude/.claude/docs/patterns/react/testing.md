# React Testing Library Patterns

This guide covers behavior-focused testing for React components using React Testing Library, emphasizing user interactions over implementation details.

## Core Philosophy

**Test behavior, not implementation.** Tests should verify what users see and do, treating component internals as a black box.

**Key principles:**
- ✓ Test through user interactions (clicks, typing, form submission)
- ✓ Query by accessible roles, labels, and text content
- ✓ Assert on visible outcomes (rendered text, DOM changes, aria attributes)
- ✗ Never access component state, props, or internal methods
- ✗ No shallow rendering or enzyme-style testing

## Query Priority

React Testing Library provides multiple query methods. Use this priority order:

### 1. Accessible Queries (Preferred)

**getByRole** - Query by ARIA role (most robust):
```typescript
// Buttons
screen.getByRole('button', { name: 'Submit' });
screen.getByRole('button', { name: /submit/i }); // Case-insensitive regex

// Links
screen.getByRole('link', { name: 'Learn More' });

// Inputs
screen.getByRole('textbox', { name: 'Email' });
screen.getByRole('checkbox', { name: 'Accept terms' });
screen.getByRole('radio', { name: 'Option 1' });

// Other elements
screen.getByRole('heading', { name: 'Welcome' });
screen.getByRole('img', { name: 'Product photo' });
screen.getByRole('list');
screen.getByRole('listitem');
```

**Common ARIA roles:**
- `button` - `<button>`, `<input type="button">`, `role="button"`
- `link` - `<a href>`
- `textbox` - `<input type="text">`, `<textarea>`
- `checkbox` - `<input type="checkbox">`
- `radio` - `<input type="radio">`
- `heading` - `<h1>` through `<h6>`
- `img` - `<img>`, `role="img"`
- `list` - `<ul>`, `<ol>`
- `listitem` - `<li>`
- `navigation` - `<nav>`, `role="navigation"`
- `main` - `<main>`, `role="main"`

**getByLabelText** - Query inputs by associated label:
```typescript
// Via <label> element
<label htmlFor="email">Email</label>
<input id="email" />
screen.getByLabelText('Email');

// Via aria-label
<input aria-label="Search" />
screen.getByLabelText('Search');

// Via aria-labelledby
<span id="email-label">Email</span>
<input aria-labelledby="email-label" />
screen.getByLabelText('Email');
```

**getByPlaceholderText** - Query by placeholder (use sparingly):
```typescript
<input placeholder="Enter email" />
screen.getByPlaceholderText('Enter email');
```

### 2. Semantic Queries

**getByText** - Query by text content:
```typescript
// Exact match
screen.getByText('Welcome back');

// Regex (case-insensitive)
screen.getByText(/welcome back/i);

// Function matcher
screen.getByText((content, element) => {
  return element?.tagName.toLowerCase() === 'p' && content.startsWith('Total:');
});
```

**getByAltText** - Query images by alt text:
```typescript
<img alt="Product photo" src="..." />
screen.getByAltText('Product photo');
```

**getByTitle** - Query by title attribute:
```typescript
<span title="Close dialog">×</span>
screen.getByTitle('Close dialog');
```

### 3. Test IDs (Last Resort)

**getByTestId** - Only when other queries don't work:
```typescript
<div data-testid="custom-element">Content</div>
screen.getByTestId('custom-element');
```

**When to use data-testid:**
- No accessible role or label
- Content is dynamic or internationalized
- Need to test implementation-specific element

**Prefer improving markup instead:**
```typescript
// ❌ Using test ID unnecessarily
<div data-testid="submit-button" onClick={submit}>Submit</div>
screen.getByTestId('submit-button');

// ✓ Use semantic HTML
<button onClick={submit}>Submit</button>
screen.getByRole('button', { name: 'Submit' });
```

## Query Variants

### get* vs query* vs find*

```typescript
// getBy* - Throws error if not found (use for elements that should exist)
const button = screen.getByRole('button', { name: 'Submit' });

// queryBy* - Returns null if not found (use for conditional elements)
const error = screen.queryByText('Error occurred');
expect(error).not.toBeInTheDocument(); // Assert element doesn't exist

// findBy* - Returns promise, waits for element (use for async content)
const message = await screen.findByText('Success!', {}, { timeout: 3000 });
```

**Decision tree:**
```
Should element exist now?
  Yes → getBy*
  No → queryBy* (for asserting absence)

Will element appear after async operation?
  Yes → findBy* (waits up to 1000ms by default)
```

### getAllBy*, queryAllBy*, findAllBy*

Query multiple elements:
```typescript
// All buttons
const buttons = screen.getAllByRole('button');
expect(buttons).toHaveLength(3);

// All list items
const items = screen.getAllByRole('listitem');
expect(items).toHaveLength(5);

// Multiple matches with text
const errors = screen.getAllByText(/error/i);
```

## User Interactions

### userEvent (Preferred)

```typescript
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

describe('LoginForm', () => {
  it('should submit login credentials', async () => {
    const onSubmit = jest.fn();
    render(<LoginForm onSubmit={onSubmit} />);

    // Type into inputs
    await userEvent.type(screen.getByLabelText('Email'), 'user@example.com');
    await userEvent.type(screen.getByLabelText('Password'), 'password123');

    // Click submit button
    await userEvent.click(screen.getByRole('button', { name: 'Sign In' }));

    // Assert callback called with correct data
    expect(onSubmit).toHaveBeenCalledWith({
      email: 'user@example.com',
      password: 'password123'
    });
  });
});
```

**userEvent methods:**
```typescript
// Click interactions
await userEvent.click(element);
await userEvent.dblClick(element);

// Keyboard interactions
await userEvent.type(element, 'Hello world');
await userEvent.clear(element);
await userEvent.keyboard('{Enter}');
await userEvent.tab(); // Focus next element

// Select interactions
await userEvent.selectOptions(selectElement, 'value');
await userEvent.deselectOptions(selectElement, 'value');

// Upload files
const file = new File(['content'], 'file.txt', { type: 'text/plain' });
await userEvent.upload(inputElement, file);

// Hover
await userEvent.hover(element);
await userEvent.unhover(element);
```

### fireEvent (Simpler, Synchronous)

```typescript
import { fireEvent } from '@testing-library/react';

// Basic click
fireEvent.click(button);

// Change input value
fireEvent.change(input, { target: { value: 'new value' } });

// Submit form
fireEvent.submit(form);

// Custom events
fireEvent.mouseEnter(element);
fireEvent.focus(element);
fireEvent.blur(element);
```

**userEvent vs fireEvent:**
- Use `userEvent` for realistic user interactions (types one character at a time, dispatches multiple events)
- Use `fireEvent` for simple unit-like tests where exact user simulation isn't needed
- `userEvent` is async, `fireEvent` is synchronous

## Testing Async Behavior

### waitFor - Wait for Assertion

```typescript
import { waitFor } from '@testing-library/react';

it('should display error message after failed submission', async () => {
  render(<RegistrationForm />);

  await userEvent.type(screen.getByLabelText('Email'), 'invalid');
  await userEvent.click(screen.getByRole('button', { name: 'Register' }));

  // Wait for error message to appear
  await waitFor(() => {
    expect(screen.getByText('Invalid email format')).toBeInTheDocument();
  });
});

// With custom timeout and interval
await waitFor(
  () => {
    expect(screen.getByText('Loaded')).toBeInTheDocument();
  },
  { timeout: 3000, interval: 100 }
);
```

### findBy* - Simpler Async Queries

```typescript
// ✓ Preferred - cleaner
const message = await screen.findByText('Success!');
expect(message).toBeInTheDocument();

// ❌ Verbose - equivalent using waitFor
await waitFor(() => {
  expect(screen.getByText('Success!')).toBeInTheDocument();
});
```

### waitForElementToBeRemoved

```typescript
it('should remove loading spinner after data loads', async () => {
  render(<DataTable />);

  const spinner = screen.getByText('Loading...');

  await waitForElementToBeRemoved(spinner);

  expect(screen.getByText('Data loaded')).toBeInTheDocument();
});
```

## Common Testing Patterns

### Form Submission

```typescript
describe('ContactForm', () => {
  it('should submit form with valid data', async () => {
    const onSubmit = jest.fn();
    render(<ContactForm onSubmit={onSubmit} />);

    // Fill out form
    await userEvent.type(screen.getByLabelText('Name'), 'John Doe');
    await userEvent.type(screen.getByLabelText('Email'), 'john@example.com');
    await userEvent.type(screen.getByLabelText('Message'), 'Hello world');

    // Submit
    await userEvent.click(screen.getByRole('button', { name: 'Send' }));

    // Assert submission
    expect(onSubmit).toHaveBeenCalledTimes(1);
    expect(onSubmit).toHaveBeenCalledWith({
      name: 'John Doe',
      email: 'john@example.com',
      message: 'Hello world'
    });
  });

  it('should show validation errors for invalid input', async () => {
    render(<ContactForm onSubmit={jest.fn()} />);

    // Submit empty form
    await userEvent.click(screen.getByRole('button', { name: 'Send' }));

    // Assert validation errors visible
    expect(screen.getByText('Name is required')).toBeInTheDocument();
    expect(screen.getByText('Email is required')).toBeInTheDocument();
  });
});
```

### Conditional Rendering

```typescript
describe('UserProfile', () => {
  it('should show loading state initially', () => {
    render(<UserProfile userId="123" />);

    expect(screen.getByText('Loading...')).toBeInTheDocument();
    expect(screen.queryByText('Profile')).not.toBeInTheDocument();
  });

  it('should show user data after loading', async () => {
    render(<UserProfile userId="123" />);

    // Wait for data to load
    const heading = await screen.findByRole('heading', { name: 'John Doe' });
    expect(heading).toBeInTheDocument();

    // Loading spinner should be gone
    expect(screen.queryByText('Loading...')).not.toBeInTheDocument();
  });

  it('should show error state on failure', async () => {
    // Mock API to fail
    jest.spyOn(api, 'fetchUser').mockRejectedValue(new Error('API error'));

    render(<UserProfile userId="123" />);

    // Wait for error message
    const error = await screen.findByText('Failed to load user');
    expect(error).toBeInTheDocument();
  });
});
```

### Toggle/Show/Hide

```typescript
describe('Dropdown', () => {
  it('should show menu when clicked', async () => {
    render(<Dropdown />);

    // Menu initially hidden
    expect(screen.queryByRole('menu')).not.toBeInTheDocument();

    // Click trigger
    await userEvent.click(screen.getByRole('button', { name: 'Options' }));

    // Menu now visible
    expect(screen.getByRole('menu')).toBeInTheDocument();
    expect(screen.getByRole('menuitem', { name: 'Edit' })).toBeInTheDocument();
  });

  it('should hide menu when clicking outside', async () => {
    render(<Dropdown />);

    // Open menu
    await userEvent.click(screen.getByRole('button', { name: 'Options' }));
    expect(screen.getByRole('menu')).toBeInTheDocument();

    // Click outside
    await userEvent.click(document.body);

    // Menu closed
    expect(screen.queryByRole('menu')).not.toBeInTheDocument();
  });
});
```

### List Rendering

```typescript
describe('TodoList', () => {
  it('should render all todo items', () => {
    const todos = [
      { id: '1', text: 'Buy milk', completed: false },
      { id: '2', text: 'Walk dog', completed: true },
      { id: '3', text: 'Write code', completed: false }
    ];

    render(<TodoList todos={todos} />);

    const items = screen.getAllByRole('listitem');
    expect(items).toHaveLength(3);

    expect(screen.getByText('Buy milk')).toBeInTheDocument();
    expect(screen.getByText('Walk dog')).toBeInTheDocument();
    expect(screen.getByText('Write code')).toBeInTheDocument();
  });

  it('should toggle todo completion on click', async () => {
    const onToggle = jest.fn();
    const todos = [{ id: '1', text: 'Buy milk', completed: false }];

    render(<TodoList todos={todos} onToggle={onToggle} />);

    // Click checkbox
    const checkbox = screen.getByRole('checkbox', { name: 'Buy milk' });
    await userEvent.click(checkbox);

    expect(onToggle).toHaveBeenCalledWith('1');
  });
});
```

## Mocking Patterns

### Mock API Calls with MSW (Recommended)

```typescript
import { rest } from 'msw';
import { setupServer } from 'msw/node';

const server = setupServer(
  rest.get('/api/users/:id', (req, res, ctx) => {
    return res(
      ctx.json({
        id: req.params.id,
        name: 'John Doe',
        email: 'john@example.com'
      })
    );
  })
);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

describe('UserProfile', () => {
  it('should fetch and display user data', async () => {
    render(<UserProfile userId="123" />);

    const name = await screen.findByText('John Doe');
    expect(name).toBeInTheDocument();
  });

  it('should handle API errors', async () => {
    // Override handler for this test
    server.use(
      rest.get('/api/users/:id', (req, res, ctx) => {
        return res(ctx.status(500), ctx.json({ error: 'Server error' }));
      })
    );

    render(<UserProfile userId="123" />);

    const error = await screen.findByText('Failed to load user');
    expect(error).toBeInTheDocument();
  });
});
```

### Mock Functions (Jest)

```typescript
describe('PaymentForm', () => {
  it('should call onSubmit with payment details', async () => {
    const onSubmit = jest.fn();
    render(<PaymentForm onSubmit={onSubmit} />);

    await userEvent.type(screen.getByLabelText('Card Number'), '4242424242424242');
    await userEvent.type(screen.getByLabelText('CVV'), '123');
    await userEvent.click(screen.getByRole('button', { name: 'Pay' }));

    expect(onSubmit).toHaveBeenCalledTimes(1);
    expect(onSubmit).toHaveBeenCalledWith({
      cardNumber: '4242424242424242',
      cvv: '123'
    });
  });

  it('should not submit while processing', async () => {
    const onSubmit = jest.fn(() => new Promise(() => {})); // Never resolves
    render(<PaymentForm onSubmit={onSubmit} />);

    const button = screen.getByRole('button', { name: 'Pay' });

    await userEvent.click(button);

    // Button disabled during processing
    expect(button).toBeDisabled();

    // Second click doesn't call onSubmit again
    await userEvent.click(button);
    expect(onSubmit).toHaveBeenCalledTimes(1);
  });
});
```

### Mock Context Providers

```typescript
function renderWithAuth(ui: React.ReactElement, user: User | null = null) {
  const mockAuthContext = {
    user,
    login: jest.fn(),
    logout: jest.fn(),
    isLoading: false
  };

  return render(
    <AuthContext.Provider value={mockAuthContext}>
      {ui}
    </AuthContext.Provider>
  );
}

describe('Dashboard', () => {
  it('should show user name when logged in', () => {
    const user = { id: '1', name: 'John Doe', email: 'john@example.com' };
    renderWithAuth(<Dashboard />, user);

    expect(screen.getByText('Welcome, John Doe')).toBeInTheDocument();
  });

  it('should redirect when not logged in', () => {
    renderWithAuth(<Dashboard />, null);

    expect(screen.getByText('Please sign in')).toBeInTheDocument();
  });
});
```

## Factory Functions for Test Data

```typescript
// Factory with defaults and overrides
function getMockUser(overrides?: Partial<User>): User {
  return {
    id: '1',
    name: 'John Doe',
    email: 'john@example.com',
    role: 'user',
    createdAt: new Date('2024-01-01'),
    ...overrides
  };
}

function getMockProduct(overrides?: Partial<Product>): Product {
  return {
    id: '1',
    name: 'Widget',
    price: 29.99,
    inStock: true,
    category: 'electronics',
    ...overrides
  };
}

// Usage in tests
describe('ProductCard', () => {
  it('should display product name and price', () => {
    const product = getMockProduct({ name: 'Gadget', price: 49.99 });
    render(<ProductCard product={product} />);

    expect(screen.getByText('Gadget')).toBeInTheDocument();
    expect(screen.getByText('$49.99')).toBeInTheDocument();
  });

  it('should show out of stock message', () => {
    const product = getMockProduct({ inStock: false });
    render(<ProductCard product={product} />);

    expect(screen.getByText('Out of stock')).toBeInTheDocument();
  });
});

// Nested factories
function getMockAddress(overrides?: Partial<Address>): Address {
  return {
    street: '123 Main St',
    city: 'Springfield',
    state: 'IL',
    zip: '62701',
    ...overrides
  };
}

function getMockUserWithAddress(overrides?: Partial<User>): User {
  return getMockUser({
    address: getMockAddress(),
    ...overrides
  });
}
```

## Avoiding Implementation Details

### ❌ Bad: Testing Implementation

```typescript
// ❌ Accessing component state
expect(wrapper.state('isOpen')).toBe(true);

// ❌ Testing internal methods
expect(component.validateEmail).toHaveBeenCalled();

// ❌ Checking props
expect(wrapper.find(Button).props().disabled).toBe(false);

// ❌ Shallow rendering
const wrapper = shallow(<Component />);

// ❌ Testing implementation details of hooks
expect(useEffect).toHaveBeenCalled();
```

### ✓ Good: Testing Behavior

```typescript
// ✓ Test visible output
expect(screen.getByText('Menu is open')).toBeInTheDocument();

// ✓ Test through user actions
await userEvent.type(screen.getByLabelText('Email'), 'invalid');
expect(screen.getByText('Invalid email')).toBeInTheDocument();

// ✓ Test DOM changes
const button = screen.getByRole('button');
expect(button).not.toBeDisabled();

// ✓ Full rendering
render(<Component />);

// ✓ Test side effects through observable behavior
await userEvent.click(screen.getByRole('button', { name: 'Save' }));
expect(await screen.findByText('Saved successfully')).toBeInTheDocument();
```

## Accessibility Testing

```typescript
import { axe, toHaveNoViolations } from 'jest-axe';

expect.extend(toHaveNoViolations);

describe('LoginForm', () => {
  it('should have no accessibility violations', async () => {
    const { container } = render(<LoginForm />);
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('should have proper ARIA labels', () => {
    render(<LoginForm />);

    expect(screen.getByLabelText('Email')).toHaveAttribute('type', 'email');
    expect(screen.getByLabelText('Password')).toHaveAttribute('type', 'password');
    expect(screen.getByRole('button', { name: 'Sign In' })).toBeEnabled();
  });
});
```

## Custom Render Utilities

```typescript
// Custom render with common providers
function renderWithProviders(
  ui: React.ReactElement,
  {
    theme = 'light',
    user = null,
    ...renderOptions
  }: {
    theme?: 'light' | 'dark';
    user?: User | null;
  } = {}
) {
  const Wrapper = ({ children }: { children: React.ReactNode }) => (
    <ThemeProvider theme={theme}>
      <AuthProvider initialUser={user}>
        <Router>
          {children}
        </Router>
      </AuthProvider>
    </ThemeProvider>
  );

  return render(ui, { wrapper: Wrapper, ...renderOptions });
}

// Usage
describe('Dashboard', () => {
  it('should render with dark theme', () => {
    renderWithProviders(<Dashboard />, { theme: 'dark' });
    expect(document.body).toHaveClass('dark');
  });

  it('should show user content when logged in', () => {
    const user = getMockUser();
    renderWithProviders(<Dashboard />, { user });
    expect(screen.getByText(`Welcome, ${user.name}`)).toBeInTheDocument();
  });
});
```

## Summary

**Query priority:**
1. `getByRole` (most robust, tests accessibility)
2. `getByLabelText` (forms)
3. `getByText` (content)
4. `getByTestId` (last resort)

**Interaction priority:**
1. `userEvent` (realistic user simulation)
2. `fireEvent` (simple synchronous events)

**Testing checklist:**
- ✓ Test through user interactions (click, type, submit)
- ✓ Query by accessible attributes (role, label, text)
- ✓ Assert on visible outcomes (rendered content, DOM state)
- ✓ Use async queries (`findBy*`) for delayed content
- ✓ Mock external dependencies (API, context, localStorage)
- ✓ Create factory functions for complex test data
- ✗ Never access component internals (state, props, methods)
- ✗ Never shallow render
- ✗ Never test implementation details

**Remember:** If you're testing how the component works internally rather than what the user sees and does, you're testing the wrong thing.
