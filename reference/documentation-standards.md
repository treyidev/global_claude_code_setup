# Documentation Standards Reference

> Comprehensive guide for writing rich, verbose documentation.
> Read this when writing new classes, methods, modules, or when
> documentation quality is questioned.

---

## Philosophy

**Documentation is NOT optional. It is a first-class deliverable.**

Code will be read many more times than it is written. Documentation must enable:

| Goal | Question It Answers |
|------|---------------------|
| **Understanding** | What does this do? |
| **Reasoning** | Why was this approach chosen? |
| **Limitations** | What can't this do? What are the boundaries? |
| **Alternatives** | What other approaches were considered? |
| **Maintenance** | How do I safely modify this? |

---

## Required Documentation Elements

### For All Public APIs

| Element | Purpose | Required |
|---------|---------|----------|
| **Summary** | One-line description | Always |
| **Description** | Detailed behavior explanation | Always |
| **Parameters** | Type, purpose, valid values, defaults | Always |
| **Returns** | What's returned, including edge cases | Always |
| **Raises/Throws** | Exceptions and conditions | If applicable |
| **Example** | Runnable usage code | Always |
| **Reasoning** | Why this approach was chosen | Non-trivial code |
| **Alternatives Considered** | Other approaches and why rejected | Design decisions |
| **Limitations** | What it can't do, boundaries | Always |
| **Workarounds** | How to handle limitations | If applicable |
| **Edge Cases** | Behavior with empty, null, boundary inputs | Always |
| **Thread Safety** | Concurrency considerations | If applicable |
| **Performance** | Time/space complexity | For algorithms |
| **See Also** | Related APIs, documentation | If applicable |

---

## Quality Spectrum

### Level 1: Unacceptable (Reject in Review)
```python
def process(data):
    """Process the data."""
    pass
```

**Problems:**
- No type information
- No explanation of what "process" means
- No parameters documented
- No return value documented
- No examples

### Level 2: Minimal (Needs Improvement)
```python
def process(data: List[Item]) -> Result:
    """
    Process a list of items.
    
    Args:
        data: Items to process.
    
    Returns:
        Processing result.
    """
    pass
```

**Problems:**
- No detailed behavior explanation
- No edge cases
- No examples
- No limitations
- No reasoning

### Level 3: Acceptable (Baseline)
```python
def process(data: List[Item], strict: bool = False) -> ProcessResult:
    """
    Process a batch of items with optional validation.

    Iterates through items, applies transformations, and aggregates
    results. Processing continues even if individual items fail
    (unless strict mode is enabled).

    Args:
        data: Items to process. Empty list returns empty result.
            Each item must have 'id' and 'value' attributes.
        strict: If True, raises on first failure. If False (default),
            collects failures and continues processing.

    Returns:
        ProcessResult containing:
        - successful: List of processed items
        - failed: List of (item, error) tuples
        - stats: Processing statistics dict

    Raises:
        ProcessingError: In strict mode, when any item fails.
        ValueError: If data is None.

    Example:
        >>> items = [Item(id=1, value="a"), Item(id=2, value="b")]
        >>> result = process(items)
        >>> print(f"Processed {len(result.successful)} items")
        Processed 2 items
    """
    pass
```

### Level 4: Excellent (Target Quality)
```python
def process(data: List[Item], strict: bool = False) -> ProcessResult:
    """
    Process a batch of items with optional strict validation.

    Iterates through items, applies transformations, and aggregates
    results. Uses a fail-soft approach by default, collecting errors
    rather than stopping on first failure.

    Args:
        data: Items to process. Empty list returns empty result.
            Each item must have 'id' and 'value' attributes.
            Maximum recommended batch size: 10,000 items.
        strict: Validation mode.
            - False (default): Collect failures, continue processing.
              Use for batch jobs where partial success is acceptable.
            - True: Raise on first failure.
              Use for transactions requiring all-or-nothing.

    Returns:
        ProcessResult containing:
        - successful: List of transformed items (order preserved)
        - failed: List of (item, error) tuples. Empty if strict=True.
        - stats: Dict with 'total', 'succeeded', 'failed', 'duration_ms'

    Raises:
        ProcessingError: In strict mode, when any item fails.
            Contains the failing item and root cause.
        ValueError: If data is None. Use empty list for "no items".

    Reasoning:
        Fail-soft default chosen because:
        1. Batch processing typically tolerates partial failure
        2. Allows inspection of all failures in one run
        3. Strict mode available when atomicity required

    Alternatives Considered:
        - Generator approach: Rejected because callers need full stats
          and random access to failed items.
        - Parallel processing: Deferred to ProcessorPool class to
          keep this method simple and predictable.

    Limitations:
        - Maximum practical batch: 10,000 items (memory constraint)
        - Items processed sequentially; see ProcessorPool for parallel
        - Not thread-safe; external synchronization required
        - Does not support nested Item structures

    Workarounds:
        - Large batches: Use process_chunked() for automatic batching
        - Nested items: Flatten with Item.flatten() first
        - Concurrency: Wrap in ProcessorPool for thread-safe parallel

    Edge Cases:
        - Empty list: Returns empty ProcessResult (no error)
        - All items fail: Returns ProcessResult with empty successful
        - Single item: Works, but consider process_single() for clarity

    Performance:
        - Time: O(n) where n = len(data)
        - Memory: O(n) for result accumulation
        - For streaming large datasets, use process_stream() instead

    Example:
        >>> # Basic usage
        >>> items = [Item(id=1, value="a"), Item(id=2, value="b")]
        >>> result = process(items)
        >>> print(f"Processed {len(result.successful)} items")
        Processed 2 items

        >>> # Handling partial failures
        >>> result = process(items_with_errors, strict=False)
        >>> for item, error in result.failed:
        ...     logger.warning(f"Item {item.id}: {error}")

        >>> # Atomic processing
        >>> try:
        ...     result = process(critical_items, strict=True)
        ... except ProcessingError as e:
        ...     rollback(e.failed_item)

    See Also:
        - process_single: For single-item processing
        - process_chunked: For automatic batching of large datasets
        - process_stream: For memory-efficient streaming
        - ProcessorPool: For parallel processing
    """
    pass
```

---

## Class Documentation Template
```python
class TransactionManager:
    """
    Manages database transactions with automatic rollback.

    Provides a context manager interface for transactional operations,
    ensuring atomicity and proper resource cleanup.

    Design Decisions:
        - Context manager pattern: Chosen for guaranteed cleanup via
          __exit__, even on exceptions. Alternative decorator pattern
          rejected due to less flexibility with nested transactions.
        - Savepoint support: Enables nested transactions. Implementation
          uses database-native savepoints rather than application-level
          simulation for reliability.

    Architecture:
        TransactionManager delegates to ConnectionPool for connections
        and to Transaction objects for actual transaction state.

        ┌─────────────────────┐
        │ TransactionManager  │ ← Coordinator (knows WHO)
        └──────────┬──────────┘
                   │
        ┌──────────▼──────────┐
        │   ConnectionPool    │ ← Resource provider
        └──────────┬──────────┘
                   │
        ┌──────────▼──────────┐
        │     Transaction     │ ← Worker (does WHAT)
        └─────────────────────┘

    Attributes:
        pool: ConnectionPool instance for database connections.
        timeout: Transaction timeout in seconds (default: 30).
        savepoints: Whether savepoints are enabled for nesting.

    Thread Safety:
        Thread-safe. Each thread gets isolated connection from pool.
        Do not share Transaction objects across threads.

    Limitations:
        - Single database: Does not support distributed transactions.
          For multi-database, see DistributedTransactionManager.
        - Connection limit: Bounded by pool size (default: 10).
        - Timeout: Transactions auto-rollback after timeout.

    Example:
        >>> # Basic usage
        >>> with TransactionManager() as txn:
        ...     txn.execute("INSERT INTO users ...")
        ...     txn.execute("UPDATE accounts ...")
        ... # Auto-commits on success, auto-rollbacks on exception

        >>> # Nested transactions with savepoints
        >>> with TransactionManager() as outer:
        ...     outer.execute("INSERT INTO orders ...")
        ...     try:
        ...         with outer.savepoint() as inner:
        ...             inner.execute("INSERT INTO items ...")
        ...             raise ValueError("Oops")
        ...     except ValueError:
        ...         pass  # Inner rolled back, outer continues
        ...     outer.execute("UPDATE orders SET status = 'partial'")

    See Also:
        - Transaction: The underlying transaction object
        - ConnectionPool: Connection management
        - DistributedTransactionManager: For multi-database transactions
    """

    def __init__(
        self,
        pool: Optional[ConnectionPool] = None,
        timeout: int = 30,
        savepoints: bool = True,
    ) -> None:
        """
        Initialize the transaction manager.

        Args:
            pool: Connection pool to use. If None, creates default pool.
                Custom pools useful for testing or specific configurations.
            timeout: Transaction timeout in seconds. After this duration,
                the transaction automatically rolls back. Default: 30.
                Set to 0 to disable timeout (not recommended).
            savepoints: Enable savepoint support for nested transactions.
                Default: True. Disable if database doesn't support them.

        Raises:
            ConnectionError: If pool creation fails (when pool is None).
            ValueError: If timeout is negative.

        Example:
            >>> # Default configuration
            >>> manager = TransactionManager()

            >>> # Custom pool and timeout
            >>> pool = ConnectionPool(max_connections=20)
            >>> manager = TransactionManager(pool=pool, timeout=60)
        """
        pass
```

---

## Module Documentation Template
```python
"""
transaction/manager.py - Transaction lifecycle management.

This module provides the TransactionManager class for handling
database transactions with automatic commit/rollback semantics.

Architecture Context:
    Part of the persistence layer. Sits between service layer
    (business logic) and connection layer (raw database access).

    Service Layer
         │
         ▼
    TransactionManager (this module)
         │
         ▼
    ConnectionPool

Module Contents:
    - TransactionManager: Main class for transaction management
    - TransactionError: Base exception for transaction failures
    - TimeoutError: Raised when transaction exceeds timeout

Dependencies:
    - connection_pool: For database connections
    - transaction: For transaction state management
    - exceptions: For TransactionError hierarchy

Design Decisions:
    - Separated from ConnectionPool: To honor Single Responsibility.
      ConnectionPool manages connections; TransactionManager manages
      transaction lifecycle.
    - Context manager interface: For Pythonic usage and guaranteed
      cleanup via __exit__.
    - Explicit over implicit: No auto-commit on close. User must
      complete the context manager block.

Usage:
    >>> from transaction.manager import TransactionManager
    >>> 
    >>> with TransactionManager() as txn:
    ...     txn.execute("INSERT INTO users ...")
    ...     # Auto-commits on block exit
    ...
    >>> # Or with explicit connection pool
    >>> pool = ConnectionPool(max_connections=5)
    >>> with TransactionManager(pool=pool) as txn:
    ...     txn.execute("UPDATE accounts ...")

Changelog:
    - 2024-01: Initial implementation
    - 2024-03: Added savepoint support for nested transactions
    - 2024-06: Added configurable timeout with auto-rollback

Author: Abhijit Bandyopadhyay
"""
```

---

## Inline Comments for Complex Logic

Use inline comments to explain WHY, not WHAT. The code shows WHAT.
```python
def calculate_optimal_partition(
    items: List[Item],
    max_weight: int,
) -> List[List[Item]]:
    """Partition items optimally by weight using dynamic programming."""
    
    # Using dynamic programming approach (0/1 knapsack variant)
    # 
    # Why DP over greedy?
    # - Greedy (sort by value/weight ratio) gives ~85% optimal
    # - DP guarantees optimal but O(n * max_weight) space
    # - For our use case (n < 1000, max_weight < 10000), DP is acceptable
    #
    # Alternative considered: Branch and bound
    # - Better for sparse solutions
    # - Rejected: Our data is dense, DP performs better empirically
    #   (benchmarked with production data, DP 3x faster)
    
    n = len(items)
    
    # dp[i][w] = maximum value achievable using items 0..i-1 with capacity w
    # Extra row/col for base case (0 items, 0 capacity)
    dp = [[0] * (max_weight + 1) for _ in range(n + 1)]
    
    for i, item in enumerate(items, 1):
        for w in range(max_weight + 1):
            if item.weight <= w:
                # Choice: exclude item OR include item
                # Include: value of item + best value with remaining capacity
                dp[i][w] = max(
                    dp[i-1][w],                              # Exclude
                    dp[i-1][w - item.weight] + item.value,   # Include
                )
            else:
                # Item too heavy for current capacity, must exclude
                dp[i][w] = dp[i-1][w]
    
    # Backtrack to find which items were selected
    # Start from dp[n][max_weight] and work backwards
    selected = []
    w = max_weight
    for i in range(n, 0, -1):
        # If value differs from previous row, item i-1 was included
        if dp[i][w] != dp[i-1][w]:
            selected.append(items[i-1])
            w -= items[i-1].weight
    
    # selected is in reverse order due to backtracking
    return list(reversed(selected))
```

---

## Language-Specific Formats

### Python (Google-style)
```python
def method(self, arg: str, flag: bool = False) -> Result:
    """
    One-line summary ending with period.

    Extended description with multiple paragraphs if needed.
    Explain behavior in detail.

    Args:
        arg: Description of argument. Include valid values,
            constraints, and defaults if any.
        flag: Description of flag. Default is False.
            Explain when to use True vs False.

    Returns:
        Description of return value. For complex returns,
        describe each field or element.

    Raises:
        ValueError: When arg is empty or invalid.
        RuntimeError: When processing fails.

    Reasoning:
        Explain why this approach was taken.

    Limitations:
        - First limitation
        - Second limitation

    Example:
        >>> result = obj.method("test")
        >>> print(result.status)
        'success'

    See Also:
        - other_method: Related functionality
        - SomeClass: For advanced usage
    """
```

### Java (Javadoc)
```java
/**
 * One-line summary ending with period.
 *
 * <p>Extended description with multiple paragraphs if needed.
 * Explain behavior in detail.
 *
 * <h3>Reasoning</h3>
 * <p>Explain why this approach was taken.
 *
 * <h3>Limitations</h3>
 * <ul>
 *   <li>First limitation</li>
 *   <li>Second limitation</li>
 * </ul>
 *
 * <h3>Example</h3>
 * <pre>{@code
 * Result result = obj.method("test");
 * System.out.println(result.getStatus());
 * }</pre>
 *
 * @param arg description of argument, including valid values
 * @param flag description of flag (default: false)
 * @return description of return value
 * @throws IllegalArgumentException when arg is empty
 * @throws RuntimeException when processing fails
 * @see #otherMethod() for related functionality
 * @see SomeClass for advanced usage
 * @since 1.0
 */
public Result method(String arg, boolean flag) {
    // ...
}
```

### C++ (Doxygen)
```cpp
/**
 * @brief One-line summary ending with period.
 *
 * Extended description with multiple paragraphs if needed.
 * Explain behavior in detail.
 *
 * @section reasoning Reasoning
 * Explain why this approach was taken.
 *
 * @section limitations Limitations
 * - First limitation
 * - Second limitation
 *
 * @param arg Description of argument, including valid values.
 * @param flag Description of flag (default: false).
 * @return Description of return value.
 * @throws std::invalid_argument When arg is empty.
 * @throws std::runtime_error When processing fails.
 *
 * @note Any important notes about usage.
 * @warning Any warnings about potential issues.
 *
 * @code
 * auto result = obj.method("test");
 * std::cout << result.status() << std::endl;
 * @endcode
 *
 * @see other_method() For related functionality.
 * @see SomeClass For advanced usage.
 */
Result method(const std::string& arg, bool flag = false);
```

### Kotlin (KDoc)
```kotlin
/**
 * One-line summary ending with period.
 *
 * Extended description with multiple paragraphs if needed.
 * Explain behavior in detail.
 *
 * ## Reasoning
 * Explain why this approach was taken.
 *
 * ## Limitations
 * - First limitation
 * - Second limitation
 *
 * @param arg Description of argument, including valid values.
 * @param flag Description of flag (default: false).
 * @return Description of return value.
 * @throws IllegalArgumentException When arg is empty.
 * @throws RuntimeException When processing fails.
 * @sample com.example.MethodSamples.basicUsage
 * @see otherMethod For related functionality.
 * @see SomeClass For advanced usage.
 */
fun method(arg: String, flag: Boolean = false): Result {
    // ...
}
```

---

## Documentation Anti-Patterns

### Don't State the Obvious
```python
# BAD - Just restates the code
def get_name(self) -> str:
    """Get the name."""  # We can see that from the method name!
    return self.name

# GOOD - Adds value
def get_name(self) -> str:
    """
    Get the display name for this user.
    
    Returns the preferred name if set, otherwise falls back
    to the username. Never returns None or empty string.
    
    Returns:
        Non-empty display name suitable for UI presentation.
    """
    return self.preferred_name or self.username
```

### Don't Leave TODOs in Public Docs
```python
# BAD
def process(data):
    """
    Process the data.
    
    TODO: Add better documentation later.
    """

# GOOD - Document now, not later
def process(data: List[Item]) -> Result:
    """
    Process items and return aggregated result.
    
    [Full documentation here]
    """
```

### Don't Document Private Details
```python
# BAD - Exposes implementation
def get_users(self) -> List[User]:
    """
    Get users from the _user_cache dict, falling back to
    self._db.query() if cache miss.
    """

# GOOD - Documents behavior, not implementation
def get_users(self) -> List[User]:
    """
    Retrieve all active users.
    
    Results may be cached for performance. Cache invalidation
    occurs on user creation, update, or deletion.
    
    Returns:
        List of active User objects, ordered by creation date.
    """
```

---

## Checklist for Documentation Review

- [ ] Summary is one line, ends with period
- [ ] All parameters documented with types and valid values
- [ ] Return value documented including edge cases
- [ ] All exceptions documented with conditions
- [ ] At least one example provided
- [ ] Limitations explicitly stated
- [ ] Reasoning provided for non-trivial decisions
- [ ] Alternatives mentioned for significant design choices
- [ ] Edge cases documented
- [ ] See Also references added where helpful
- [ ] No TODOs or placeholders
- [ ] No implementation details exposed
- [ ] Language-appropriate format used (Google/Javadoc/Doxygen/KDoc)