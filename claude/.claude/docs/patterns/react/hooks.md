# React Hooks Patterns

This guide covers custom hooks, context patterns with TypeScript, dependency management, and when to create custom hooks vs inline logic.

## Custom Hook Fundamentals

### Typed Custom Hook - Basic Pattern

```typescript
function useLocalStorage<T>(key: string, initialValue: T) {
  const [storedValue, setStoredValue] = useState<T>(() => {
    try {
      const item = window.localStorage.getItem(key);
      return item ? JSON.parse(item) : initialValue;
    } catch {
      return initialValue;
    }
  });

  const setValue = (value: T | ((val: T) => T)) => {
    const valueToStore = value instanceof Function ? value(storedValue) : value;
    setStoredValue(valueToStore);
    window.localStorage.setItem(key, JSON.stringify(valueToStore));
  };

  return [storedValue, setValue] as const;
}

// Usage with full type inference
const [theme, setTheme] = useLocalStorage<'light' | 'dark'>('theme', 'light');
const [user, setUser] = useLocalStorage<User | null>('user', null);

setTheme('dark'); // Type-safe - only 'light' | 'dark' allowed
```

**Key patterns:**
- ✓ Generic type parameter for flexibility
- ✓ Lazy initialization with function (only runs once)
- ✓ Return `as const` for tuple type inference
- ✓ Handle both direct values and updater functions
- ✓ Error handling for localStorage failures

**Return type patterns:**
```typescript
// Tuple - useState-like API
return [value, setValue] as const;

// Object - named properties
return { value, setValue, reset };

// Single value - simple hooks
return value;
```

## Context Patterns with TypeScript

### Basic Context Setup

```typescript
interface AuthContextType {
  user: User | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  isLoading: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
}

interface AuthProviderProps {
  children: React.ReactNode;
}

function AuthProvider({ children }: AuthProviderProps) {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    checkAuth().then(setUser).finally(() => setIsLoading(false));
  }, []);

  const login = async (email: string, password: string) => {
    const user = await loginUser(email, password);
    setUser(user);
  };

  const logout = () => {
    logoutUser();
    setUser(null);
  };

  const value = { user, login, logout, isLoading };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

// Usage
function App() {
  return (
    <AuthProvider>
      <Dashboard />
    </AuthProvider>
  );
}

function Dashboard() {
  const { user, logout, isLoading } = useAuth(); // Type-safe

  if (isLoading) return <Spinner />;
  if (!user) return <Login />;

  return (
    <div>
      <p>Welcome, {user.name}</p>
      <button onClick={logout}>Logout</button>
    </div>
  );
}
```

**Why `undefined` in context type:**
- Context starts as `undefined` before provider mounts
- Forces consumers to handle missing provider case
- Hook throws descriptive error instead of runtime null errors

**Alternative: Default value (avoid)**
```typescript
// ❌ Avoid - masks missing provider errors
const AuthContext = createContext<AuthContextType>({
  user: null,
  login: async () => {},
  logout: () => {},
  isLoading: false
});
```

### Advanced Context: Actions and State Separation

```typescript
interface TodoState {
  todos: Todo[];
  filter: 'all' | 'active' | 'completed';
}

interface TodoActions {
  addTodo: (text: string) => void;
  toggleTodo: (id: string) => void;
  deleteTodo: (id: string) => void;
  setFilter: (filter: TodoState['filter']) => void;
}

// Separate contexts for state and actions (optimization)
const TodoStateContext = createContext<TodoState | undefined>(undefined);
const TodoActionsContext = createContext<TodoActions | undefined>(undefined);

function useTodoState() {
  const context = useContext(TodoStateContext);
  if (!context) throw new Error('useTodoState must be used within TodoProvider');
  return context;
}

function useTodoActions() {
  const context = useContext(TodoActionsContext);
  if (!context) throw new Error('useTodoActions must be used within TodoProvider');
  return context;
}

function TodoProvider({ children }: { children: React.ReactNode }) {
  const [todos, setTodos] = useState<Todo[]>([]);
  const [filter, setFilter] = useState<'all' | 'active' | 'completed'>('all');

  // Actions memoized to prevent unnecessary re-renders
  const actions = useMemo<TodoActions>(() => ({
    addTodo: (text: string) => {
      setTodos(prev => [...prev, { id: crypto.randomUUID(), text, completed: false }]);
    },
    toggleTodo: (id: string) => {
      setTodos(prev => prev.map(t => t.id === id ? { ...t, completed: !t.completed } : t));
    },
    deleteTodo: (id: string) => {
      setTodos(prev => prev.filter(t => t.id !== id));
    },
    setFilter
  }), []);

  const state = { todos, filter };

  return (
    <TodoStateContext.Provider value={state}>
      <TodoActionsContext.Provider value={actions}>
        {children}
      </TodoActionsContext.Provider>
    </TodoStateContext.Provider>
  );
}

// Usage - components only re-render when used context changes
function TodoList() {
  const { todos, filter } = useTodoState(); // Re-renders on state change
  const { toggleTodo } = useTodoActions(); // Doesn't cause re-renders

  const filtered = todos.filter(t => {
    if (filter === 'active') return !t.completed;
    if (filter === 'completed') return t.completed;
    return true;
  });

  return (
    <ul>
      {filtered.map(todo => (
        <li key={todo.id} onClick={() => toggleTodo(todo.id)}>
          {todo.text}
        </li>
      ))}
    </ul>
  );
}
```

**Benefits of split contexts:**
- ✓ Components using only actions don't re-render on state changes
- ✓ Better performance for large apps
- ✓ Clearer separation of concerns

**When to split:**
- Large context with frequent updates
- Many components need actions but not state
- Performance profiling shows unnecessary re-renders

## Common Custom Hooks

### useDebounce - Delay Rapid Updates

```typescript
function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value);

  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value);
    }, delay);

    return () => {
      clearTimeout(handler);
    };
  }, [value, delay]);

  return debouncedValue;
}

// Usage - search input with API call
function SearchResults() {
  const [query, setQuery] = useState('');
  const debouncedQuery = useDebounce(query, 500);

  useEffect(() => {
    if (debouncedQuery) {
      searchAPI(debouncedQuery).then(setResults);
    }
  }, [debouncedQuery]);

  return <input value={query} onChange={(e) => setQuery(e.target.value)} />;
}
```

**Use cases:**
- Search input (avoid API call on every keystroke)
- Window resize handlers
- Auto-save functionality
- Real-time validation

### usePrevious - Track Previous Value

```typescript
function usePrevious<T>(value: T): T | undefined {
  const ref = useRef<T>();

  useEffect(() => {
    ref.current = value;
  }, [value]);

  return ref.current;
}

// Usage - compare current and previous
function Counter() {
  const [count, setCount] = useState(0);
  const prevCount = usePrevious(count);

  return (
    <div>
      <p>Current: {count}</p>
      <p>Previous: {prevCount ?? 'N/A'}</p>
      <p>Changed by: {prevCount !== undefined ? count - prevCount : 0}</p>
      <button onClick={() => setCount(c => c + 1)}>Increment</button>
    </div>
  );
}
```

**Use cases:**
- Animation directions (slide left vs right)
- Detecting value changes
- Undo/redo functionality
- Comparing render values

### useMediaQuery - Responsive Hooks

```typescript
function useMediaQuery(query: string): boolean {
  const [matches, setMatches] = useState(() => {
    if (typeof window === 'undefined') return false;
    return window.matchMedia(query).matches;
  });

  useEffect(() => {
    const mediaQuery = window.matchMedia(query);
    const handler = (event: MediaQueryListEvent) => setMatches(event.matches);

    mediaQuery.addEventListener('change', handler);
    return () => mediaQuery.removeEventListener('change', handler);
  }, [query]);

  return matches;
}

// Usage - responsive components
function Navigation() {
  const isMobile = useMediaQuery('(max-width: 768px)');

  return isMobile ? <MobileNav /> : <DesktopNav />;
}

// Common breakpoints
const useIsMobile = () => useMediaQuery('(max-width: 768px)');
const useIsTablet = () => useMediaQuery('(min-width: 769px) and (max-width: 1024px)');
const useIsDesktop = () => useMediaQuery('(min-width: 1025px)');
```

### useOnClickOutside - Detect Outside Clicks

```typescript
function useOnClickOutside<T extends HTMLElement>(
  ref: React.RefObject<T>,
  handler: (event: MouseEvent | TouchEvent) => void
): void {
  useEffect(() => {
    const listener = (event: MouseEvent | TouchEvent) => {
      const element = ref.current;
      if (!element || element.contains(event.target as Node)) {
        return;
      }
      handler(event);
    };

    document.addEventListener('mousedown', listener);
    document.addEventListener('touchstart', listener);

    return () => {
      document.removeEventListener('mousedown', listener);
      document.removeEventListener('touchstart', listener);
    };
  }, [ref, handler]);
}

// Usage - close dropdown on outside click
function Dropdown() {
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);

  useOnClickOutside(dropdownRef, () => setIsOpen(false));

  return (
    <div ref={dropdownRef}>
      <button onClick={() => setIsOpen(!isOpen)}>Toggle</button>
      {isOpen && <div className="dropdown-menu">Content</div>}
    </div>
  );
}
```

## Hook Best Practices

### useState: Functional Updates

```typescript
// ❌ Avoid - stale closure issue
const [count, setCount] = useState(0);

useEffect(() => {
  const interval = setInterval(() => {
    setCount(count + 1); // Always uses initial count (0)
  }, 1000);
  return () => clearInterval(interval);
}, []); // Missing count in deps - incorrect

// ✓ Correct - functional update
useEffect(() => {
  const interval = setInterval(() => {
    setCount(prev => prev + 1); // Always uses current state
  }, 1000);
  return () => clearInterval(interval);
}, []); // Empty deps correct - no external dependencies
```

**When to use functional updates:**
- New state depends on previous state
- State updater used in callbacks with empty deps
- Avoiding stale closure bugs

### useState: Lazy Initialization

```typescript
// ❌ Expensive computation runs every render
const [data, setData] = useState(expensiveComputation());

// ✓ Computation runs only once on mount
const [data, setData] = useState(() => expensiveComputation());

// Examples of expensive initialization
const [cart, setCart] = useState(() => JSON.parse(localStorage.getItem('cart') || '[]'));
const [config, setConfig] = useState(() => loadConfigFromIndexedDB());
const [sortedData, setSortedData] = useState(() => hugeArray.sort());
```

**When to use lazy initialization:**
- Reading from localStorage/sessionStorage
- Parsing large data structures
- Computing derived state from props
- Any synchronous operation taking >1ms

### useEffect: Cleanup Functions

```typescript
// ✓ Cleanup subscriptions
useEffect(() => {
  const subscription = subscribeToData(userId);
  return () => subscription.unsubscribe();
}, [userId]);

// ✓ Cleanup timers
useEffect(() => {
  const timer = setTimeout(() => showNotification(), 3000);
  return () => clearTimeout(timer);
}, []);

// ✓ Cleanup event listeners
useEffect(() => {
  const handler = () => console.log('resize');
  window.addEventListener('resize', handler);
  return () => window.removeEventListener('resize', handler);
}, []);

// ✓ Cleanup AbortController for fetch
useEffect(() => {
  const controller = new AbortController();

  async function loadData() {
    try {
      const data = await fetchData({ signal: controller.signal });
      setData(data);
    } catch (error) {
      if (error.name !== 'AbortError') {
        console.error(error);
      }
    }
  }

  loadData();
  return () => controller.abort();
}, []);
```

**Always cleanup:**
- Subscriptions (WebSocket, EventSource, RxJS)
- Timers (setTimeout, setInterval)
- Event listeners (window, document)
- Fetch requests (AbortController)
- Animation frames (requestAnimationFrame)

### Dependency Arrays: Common Patterns

```typescript
// ✓ Run once on mount
useEffect(() => {
  initializeApp();
}, []);

// ✓ Run when specific values change
useEffect(() => {
  loadUser(userId);
}, [userId]);

// ✓ Run when any dependency changes
useEffect(() => {
  saveData(formData, userId, timestamp);
}, [formData, userId, timestamp]);

// ❌ Avoid - missing dependencies (ESLint error)
useEffect(() => {
  loadUser(userId); // userId should be in deps
}, []);

// ✓ Include all dependencies
useEffect(() => {
  const handler = () => processData(data);
  window.addEventListener('resize', handler);
  return () => window.removeEventListener('resize', handler);
}, [data]); // Include data - handler uses it

// ✓ Or use ref for stable reference
const dataRef = useRef(data);
dataRef.current = data;

useEffect(() => {
  const handler = () => processData(dataRef.current);
  window.addEventListener('resize', handler);
  return () => window.removeEventListener('resize', handler);
}, []); // Empty deps - dataRef never changes
```

### useRef: Mutable Values Without Re-renders

```typescript
// ✓ DOM references
const inputRef = useRef<HTMLInputElement>(null);

useEffect(() => {
  inputRef.current?.focus();
}, []);

return <input ref={inputRef} />;

// ✓ Store mutable values (doesn't trigger re-render)
const intervalRef = useRef<number | null>(null);

const startTimer = () => {
  intervalRef.current = setInterval(() => tick(), 1000);
};

const stopTimer = () => {
  if (intervalRef.current) {
    clearInterval(intervalRef.current);
    intervalRef.current = null;
  }
};

// ✓ Track previous value (see usePrevious hook)
const prevValueRef = useRef<string>();

useEffect(() => {
  prevValueRef.current = value;
}, [value]);

// ✓ Store callback without triggering re-renders
const callbackRef = useRef(callback);
callbackRef.current = callback;

useEffect(() => {
  const handler = () => callbackRef.current();
  // handler always calls latest callback
}, []); // Empty deps - ref never changes
```

**useRef vs useState:**
- Use `useState` when change should trigger re-render
- Use `useRef` when change should NOT trigger re-render
- Refs persist across renders but don't cause updates

## When to Create Custom Hooks

### Good Candidates for Custom Hooks

**✓ Reusable stateful logic:**
```typescript
// Used in multiple components
useLocalStorage, useDebounce, useMediaQuery
```

**✓ Complex logic with multiple hooks:**
```typescript
function useForm<T>(initialValues: T) {
  const [values, setValues] = useState(initialValues);
  const [errors, setErrors] = useState({});
  const [touched, setTouched] = useState({});

  // Multiple hooks working together
  return { values, errors, touched, handleChange, handleBlur, handleSubmit };
}
```

**✓ Side effects with cleanup:**
```typescript
function useWebSocket(url: string) {
  const [data, setData] = useState(null);
  const [isConnected, setIsConnected] = useState(false);

  useEffect(() => {
    const ws = new WebSocket(url);
    ws.onopen = () => setIsConnected(true);
    ws.onmessage = (e) => setData(JSON.parse(e.data));
    return () => ws.close();
  }, [url]);

  return { data, isConnected };
}
```

### Keep Inline Instead

**❌ Single useState with no logic:**
```typescript
// Don't create hook - too simple
function useCounter() {
  return useState(0);
}

// Keep inline
const [count, setCount] = useState(0);
```

**❌ One-off component-specific logic:**
```typescript
// Don't extract if only used in one place
function useSpecificFormLogic() {
  // Complex but specific to one component
}
```

**❌ Simple derived values:**
```typescript
// Don't create hook - use useMemo inline
function useFullName(firstName: string, lastName: string) {
  return useMemo(() => `${firstName} ${lastName}`, [firstName, lastName]);
}

// Keep inline
const fullName = useMemo(() => `${firstName} ${lastName}`, [firstName, lastName]);
// Or even simpler if not expensive:
const fullName = `${firstName} ${lastName}`;
```

### Decision Tree

```
Does logic involve React hooks? → No → Regular function
                                → Yes ↓

Is it used in 2+ components? → No → Keep inline
                              → Yes ↓

Does it manage related state/effects? → No → Keep inline
                                      → Yes ↓

CREATE CUSTOM HOOK
```

## Complete Example: Custom Hook with TypeScript

```typescript
interface UseAsyncOptions<T> {
  immediate?: boolean;
  onSuccess?: (data: T) => void;
  onError?: (error: Error) => void;
}

interface UseAsyncReturn<T, Args extends any[]> {
  data: T | null;
  error: Error | null;
  isLoading: boolean;
  execute: (...args: Args) => Promise<void>;
  reset: () => void;
}

function useAsync<T, Args extends any[]>(
  asyncFn: (...args: Args) => Promise<T>,
  options: UseAsyncOptions<T> = {}
): UseAsyncReturn<T, Args> {
  const [data, setData] = useState<T | null>(null);
  const [error, setError] = useState<Error | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const execute = useCallback(
    async (...args: Args) => {
      setIsLoading(true);
      setError(null);

      try {
        const result = await asyncFn(...args);
        setData(result);
        options.onSuccess?.(result);
      } catch (err) {
        const error = err instanceof Error ? err : new Error(String(err));
        setError(error);
        options.onError?.(error);
      } finally {
        setIsLoading(false);
      }
    },
    [asyncFn, options]
  );

  const reset = useCallback(() => {
    setData(null);
    setError(null);
    setIsLoading(false);
  }, []);

  useEffect(() => {
    if (options.immediate) {
      execute();
    }
  }, [options.immediate, execute]);

  return { data, error, isLoading, execute, reset };
}

// Usage
function UserProfile({ userId }: { userId: string }) {
  const {
    data: user,
    error,
    isLoading,
    execute: loadUser
  } = useAsync(
    (id: string) => fetchUser(id),
    {
      immediate: true,
      onSuccess: (user) => console.log('User loaded:', user.name),
      onError: (error) => console.error('Failed to load user:', error)
    }
  );

  if (isLoading) return <Spinner />;
  if (error) return <ErrorMessage error={error} retry={() => loadUser(userId)} />;
  if (!user) return null;

  return <div>Welcome, {user.name}</div>;
}
```

## Summary

**Custom hooks checklist:**
- ✓ Name starts with `use` (React convention)
- ✓ Generic type parameters for reusability
- ✓ Return types explicitly declared (`as const` for tuples)
- ✓ Cleanup functions for side effects
- ✓ Memoize callbacks with useCallback
- ✓ Handle loading, error, and success states

**Context checklist:**
- ✓ Type as `Type | undefined`, not `Type | null`
- ✓ Custom hook validates context exists
- ✓ Split state/actions for performance (large apps)
- ✓ Memoize context values when appropriate

**Dependency arrays:**
- ✓ Include ALL dependencies (follow ESLint exhaustive-deps)
- ✓ Use functional updates to reduce dependencies
- ✓ Use refs for stable references when needed
- ✓ Extract constants outside component to avoid deps

**When to create custom hook:**
- Logic reused in 2+ components
- Combines multiple hooks with related purpose
- Encapsulates complex side effects with cleanup
- NOT for trivial logic or one-off use cases
