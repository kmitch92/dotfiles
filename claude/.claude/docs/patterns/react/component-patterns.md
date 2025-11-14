# React Component Patterns

This guide covers TypeScript patterns for React components, including prop typing, generic components, discriminated unions, children patterns, and event handlers.

## Basic Component Props

### Props with Type Safety and Defaults

```typescript
interface ButtonProps {
  variant: 'primary' | 'secondary' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  children: React.ReactNode;
  onClick?: () => void;
  disabled?: boolean;
}

function Button({
  variant,
  size = 'md',
  children,
  onClick,
  disabled = false
}: ButtonProps) {
  return (
    <button
      className={`btn-${variant} btn-${size}`}
      onClick={onClick}
      disabled={disabled}
    >
      {children}
    </button>
  );
}
```

**When to use:**
- Component has a clear set of required and optional props
- Need default values for optional props
- Props have specific allowed values (union types)

**Common pitfalls:**
- ❌ Using `string` instead of union types - loses type safety
- ❌ Making all props optional - unclear which are required
- ❌ Forgetting to document required behavior in types

## Extending HTML Attributes

### Inheriting Native Element Props

```typescript
interface CustomButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant: 'primary' | 'secondary';
  isLoading?: boolean;
}

function CustomButton({
  variant,
  isLoading,
  children,
  ...props
}: CustomButtonProps) {
  return (
    <button
      {...props}
      className={`btn-${variant}`}
    >
      {isLoading ? 'Loading...' : children}
    </button>
  );
}

// Usage - all native button props available
<CustomButton
  variant="primary"
  disabled
  aria-label="Submit form"
  onClick={handleClick}
>
  Submit
</CustomButton>
```

**When to use:**
- Building custom wrappers around native HTML elements
- Want to preserve all native element capabilities (accessibility, events)
- Need both custom props AND standard HTML attributes

**Available HTML type interfaces:**
- `React.ButtonHTMLAttributes<HTMLButtonElement>`
- `React.InputHTMLAttributes<HTMLInputElement>`
- `React.HTMLAttributes<HTMLElement>` (generic)
- `React.AnchorHTMLAttributes<HTMLAnchorElement>`
- `React.FormHTMLAttributes<HTMLFormElement>`
- `React.ImgHTMLAttributes<HTMLImageElement>`

**Common pitfalls:**
- ❌ Not spreading `...props` - loses native functionality
- ❌ Overwriting className instead of merging - breaks Tailwind utilities
- ❌ Using wrong element type generic - causes type mismatches

**Best practice - merge className:**
```typescript
import { cn } from '@/lib/utils'; // Utility for className merging

<button
  {...props}
  className={cn(`btn-${variant}`, props.className)}
>
  {children}
</button>
```

## Generic Components

### Type-Safe List Component

```typescript
interface ListProps<T> {
  items: T[];
  renderItem: (item: T, index: number) => React.ReactNode;
  keyExtractor: (item: T) => string | number;
}

function List<T>({ items, renderItem, keyExtractor }: ListProps<T>) {
  return (
    <ul>
      {items.map((item, index) => (
        <li key={keyExtractor(item)}>
          {renderItem(item, index)}
        </li>
      ))}
    </ul>
  );
}

// Usage with full type inference
interface Product {
  id: string;
  name: string;
  price: number;
}

<List<Product>
  items={products}
  renderItem={(product, index) => (
    <div>
      {index + 1}. {product.name} - ${product.price}
    </div>
  )}
  keyExtractor={(product) => product.id}
/>
```

**When to use:**
- Component logic doesn't depend on specific item type
- Rendering lists, tables, grids with different data shapes
- Building reusable data display components

**Benefits:**
- ✓ Full type safety for item properties
- ✓ Autocomplete in renderItem function
- ✓ Reusable across different data types
- ✓ Type errors caught at compile time

**Common pitfalls:**
- ❌ Using `any` for items - defeats purpose of generics
- ❌ Not constraining generic when needed - allows invalid types
- ❌ Over-engineering simple components - use generics only when truly reusable

**Advanced: Constraining generics**
```typescript
interface HasId {
  id: string | number;
}

interface ListProps<T extends HasId> {
  items: T[];
  renderItem: (item: T) => React.ReactNode;
  // keyExtractor not needed - can use item.id
}

function List<T extends HasId>({ items, renderItem }: ListProps<T>) {
  return (
    <ul>
      {items.map((item) => (
        <li key={item.id}>{renderItem(item)}</li>
      ))}
    </ul>
  );
}
```

## Discriminated Unions

### Type-Safe Conditional Props

```typescript
type AlertProps =
  | { variant: 'success'; message: string; onDismiss: () => void }
  | { variant: 'error'; message: string; error: Error; onRetry: () => void }
  | { variant: 'info'; message: string };

function Alert(props: AlertProps) {
  switch (props.variant) {
    case 'success':
      return (
        <div className="alert-success" onClick={props.onDismiss}>
          ✓ {props.message}
        </div>
      );
    case 'error':
      return (
        <div className="alert-error" onClick={props.onRetry}>
          ✗ {props.error.message}
        </div>
      );
    case 'info':
      return (
        <div className="alert-info">
          ℹ {props.message}
        </div>
      );
  }
}

// Usage - TypeScript enforces correct prop combinations
<Alert variant="success" message="Saved" onDismiss={() => {}} />
<Alert variant="error" message="Failed" error={new Error('...')} onRetry={() => {}} />
<Alert variant="info" message="Note" />

// ❌ Type error - missing required props for variant
<Alert variant="success" message="Saved" /> // Missing onDismiss
<Alert variant="error" message="Failed" onRetry={() => {}} /> // Missing error
```

**When to use:**
- Props vary based on a discriminator field (variant, type, status)
- Want compile-time guarantee of correct prop combinations
- Different variants require different callbacks or data

**Real-world examples:**
```typescript
// Form field with conditional validation
type FieldProps =
  | { type: 'text'; value: string; maxLength?: number }
  | { type: 'number'; value: number; min?: number; max?: number }
  | { type: 'date'; value: Date; minDate?: Date; maxDate?: Date };

// Modal with conditional actions
type ModalProps =
  | { mode: 'confirm'; onConfirm: () => void; onCancel: () => void }
  | { mode: 'alert'; onClose: () => void }
  | { mode: 'prompt'; onSubmit: (value: string) => void; onCancel: () => void };

// API request state
type RequestState<T> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: Error };
```

**Common pitfalls:**
- ❌ Making discriminator optional - breaks exhaustive checking
- ❌ Using optional props instead of unions - loses type safety
- ❌ Not using exhaustive switch - TypeScript can't catch missing cases

**Best practice - exhaustive checking:**
```typescript
function Alert(props: AlertProps) {
  switch (props.variant) {
    case 'success':
      return <SuccessAlert {...props} />;
    case 'error':
      return <ErrorAlert {...props} />;
    case 'info':
      return <InfoAlert {...props} />;
    default:
      // TypeScript error if new variant added without handling
      const _exhaustive: never = props;
      return _exhaustive;
  }
}
```

## Children Patterns

### ReactNode - Most Common

```typescript
interface CardProps {
  title: string;
  children: React.ReactNode;
}

function Card({ title, children }: CardProps) {
  return (
    <div className="card">
      <h2>{title}</h2>
      <div>{children}</div>
    </div>
  );
}

// Accepts any valid React content
<Card title="Profile">
  <p>Text content</p>
  <Button>Action</Button>
  {isLoading && <Spinner />}
  {items.map(item => <Item key={item.id} />)}
</Card>
```

**When to use:**
- Children can be any valid React content
- Most flexible children type
- Default choice for wrapper components

**What ReactNode includes:**
- JSX elements (`<div>`, `<Component />`)
- Strings and numbers
- Arrays of elements
- `null`, `undefined`, `false` (renders nothing)
- Portals

### Render Props Pattern

```typescript
interface DataLoaderProps<T> {
  url: string;
  children: (data: T, isLoading: boolean, error: Error | null) => React.ReactNode;
}

function DataLoader<T>({ url, children }: DataLoaderProps<T>) {
  const [data, setData] = useState<T | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    fetchData(url).then(setData).catch(setError).finally(() => setIsLoading(false));
  }, [url]);

  return <>{children(data as T, isLoading, error)}</>;
}

// Usage - full control over rendering
<DataLoader<User> url="/api/user">
  {(user, isLoading, error) => {
    if (isLoading) return <Spinner />;
    if (error) return <ErrorMessage error={error} />;
    return <UserProfile user={user} />;
  }}
</DataLoader>
```

**When to use:**
- Need to pass data/state to children
- Children need control over rendering logic
- Building reusable data-fetching or state management wrappers

**Benefits:**
- ✓ Inverts control - children decide how to render
- ✓ Type-safe data passing
- ✓ Flexible composition

**Alternative: Render prop as explicit prop**
```typescript
interface TabsProps {
  activeTab: string;
  renderTab: (tabId: string, isActive: boolean) => React.ReactNode;
}

<Tabs activeTab="profile" renderTab={(id, isActive) => (
  <div className={isActive ? 'active' : ''}>{id}</div>
)} />
```

### Restricted Children Types

```typescript
// Only accepts specific component types
interface TabsProps {
  children: React.ReactElement<TabProps> | React.ReactElement<TabProps>[];
}

function Tabs({ children }: TabsProps) {
  const tabs = React.Children.toArray(children);
  return <div className="tabs">{tabs}</div>;
}

// Usage
<Tabs>
  <Tab id="1">First</Tab>
  <Tab id="2">Second</Tab>
</Tabs>

// ❌ Type error - wrong component
<Tabs>
  <div>Not allowed</div>
</Tabs>
```

**When to use:**
- Component expects specific child component types
- Need to validate or process children
- Building compound components (Tabs/Tab, Accordion/Panel)

**Common pitfalls:**
- ❌ Over-restricting when `ReactNode` would work
- ❌ Not handling single vs array of children
- ❌ Complex child validation - use runtime checks instead

## Event Handler Typing

### Basic Event Handlers

```typescript
interface FormProps {
  onSubmit: (data: FormData) => void;
  onCancel: () => void;
}

function Form({ onSubmit, onCancel }: FormProps) {
  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const formData = new FormData(e.currentTarget);
    onSubmit(formData);
  };

  return (
    <form onSubmit={handleSubmit}>
      <button type="submit">Submit</button>
      <button type="button" onClick={onCancel}>Cancel</button>
    </form>
  );
}
```

**Common event types:**
- `React.MouseEvent<HTMLElement>` - Click, mouse events
- `React.KeyboardEvent<HTMLElement>` - Key press events
- `React.FormEvent<HTMLFormElement>` - Form submission
- `React.ChangeEvent<HTMLInputElement>` - Input changes
- `React.FocusEvent<HTMLElement>` - Focus/blur events

### Input Change Handlers

```typescript
interface InputProps {
  value: string;
  onChange: (value: string) => void;
  onBlur?: () => void;
}

function Input({ value, onChange, onBlur }: InputProps) {
  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    onChange(e.target.value);
  };

  return (
    <input
      type="text"
      value={value}
      onChange={handleChange}
      onBlur={onBlur}
    />
  );
}
```

**Benefits of lifting event details:**
- ✓ Parent doesn't need to know about DOM events
- ✓ Cleaner API - parent receives values, not events
- ✓ Easier to test - pass values directly

**When to pass events directly:**
```typescript
// When parent needs event details (e.g., preventDefault)
interface FormProps {
  onSubmit: (e: React.FormEvent<HTMLFormElement>) => void;
}
```

### Generic Event Handlers

```typescript
interface SelectProps<T> {
  value: T;
  options: T[];
  onChange: (value: T) => void;
  getLabel: (option: T) => string;
  getValue: (option: T) => string;
}

function Select<T>({ value, options, onChange, getLabel, getValue }: SelectProps<T>) {
  const handleChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const selectedValue = e.target.value;
    const selected = options.find(opt => getValue(opt) === selectedValue);
    if (selected) onChange(selected);
  };

  return (
    <select value={getValue(value)} onChange={handleChange}>
      {options.map(opt => (
        <option key={getValue(opt)} value={getValue(opt)}>
          {getLabel(opt)}
        </option>
      ))}
    </select>
  );
}

// Usage with full type safety
<Select<Country>
  value={selectedCountry}
  options={countries}
  onChange={setSelectedCountry}
  getLabel={c => c.name}
  getValue={c => c.code}
/>
```

## Complete Example: Type-Safe Form Component

```typescript
interface FormField {
  name: string;
  label: string;
  type: 'text' | 'email' | 'number';
  required?: boolean;
}

interface FormProps<T extends Record<string, any>> {
  fields: FormField[];
  initialValues: T;
  onSubmit: (values: T) => void | Promise<void>;
  onCancel?: () => void;
  submitLabel?: string;
  children?: React.ReactNode;
}

function Form<T extends Record<string, any>>({
  fields,
  initialValues,
  onSubmit,
  onCancel,
  submitLabel = 'Submit',
  children
}: FormProps<T>) {
  const [values, setValues] = useState<T>(initialValues);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleChange = (name: keyof T) => (value: string) => {
    setValues(prev => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setIsSubmitting(true);
    try {
      await onSubmit(values);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      {fields.map(field => (
        <div key={field.name}>
          <label>{field.label}</label>
          <input
            type={field.type}
            name={field.name}
            value={String(values[field.name] ?? '')}
            onChange={(e) => handleChange(field.name)(e.target.value)}
            required={field.required}
          />
        </div>
      ))}
      {children}
      <div className="flex gap-2">
        <button type="submit" disabled={isSubmitting}>
          {isSubmitting ? 'Submitting...' : submitLabel}
        </button>
        {onCancel && (
          <button type="button" onClick={onCancel}>
            Cancel
          </button>
        )}
      </div>
    </form>
  );
}

// Usage
interface UserFormData {
  name: string;
  email: string;
  age: number;
}

<Form<UserFormData>
  fields={[
    { name: 'name', label: 'Name', type: 'text', required: true },
    { name: 'email', label: 'Email', type: 'email', required: true },
    { name: 'age', label: 'Age', type: 'number' }
  ]}
  initialValues={{ name: '', email: '', age: 0 }}
  onSubmit={async (data) => {
    await saveUser(data);
  }}
  onCancel={() => router.back()}
  submitLabel="Create User"
>
  <p className="text-sm text-gray-500">
    All fields marked with * are required
  </p>
</Form>
```

## Summary

**Choose the right pattern:**
- **Basic props** - Simple components with clear requirements
- **Extending HTML attributes** - Native element wrappers
- **Generics** - Truly reusable components across types
- **Discriminated unions** - Variant-specific prop requirements
- **ReactNode children** - Flexible content (default choice)
- **Render props** - Pass data/state to children
- **Restricted children** - Compound components

**Common mistakes to avoid:**
- Using `any` instead of proper types
- Not extending HTML attributes when wrapping native elements
- Over-engineering with generics when not needed
- Making discriminators optional
- Using optional props instead of discriminated unions
- Passing DOM events when values would be cleaner

**Remember:**
- TypeScript should make components easier to use, not harder
- Types document expected behavior
- Let TypeScript inference work - don't over-annotate
- Test your component API by using it - if types are cumbersome, simplify
