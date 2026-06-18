---
paths:
  - "**/*.kt"
  - "**/*.kts"
---

# Kotlin standards (auto-loaded on `**/*.kt`, `**/*.kts`)

Deep Kotlin-specific standards. **Path-scoped**: loaded deterministically by the harness only
when you read or edit Kotlin (see *Instruction architecture* in `~/.claude/CLAUDE.md`). Cross-
language principles (SOLID, clean code, architecture, documentation, fail-fast) live in
`CLAUDE.md` and apply on top of this.

## Null Safety (Required)
```kotlin
// ✅ CORRECT - Explicit nullability
fun findUser(id: String): User?  // May return null
fun getUser(id: String): User    // Never returns null, throws if not found

// ✅ CORRECT - Safe calls and elvis
val name = user?.profile?.displayName ?: "Anonymous"

// ❌ WRONG - Forcing non-null without check
val name = user!!.name  // Avoid !! unless absolutely certain
```

## Data Classes (Prefer)
```kotlin
// ✅ CORRECT - Immutable data class
data class User(
    val id: String,
    val name: String,
    val email: String,
)

// ❌ WRONG - Mutable with var
data class User(
    var id: String,    // NO! Use val
    var name: String,
)
```

## Extension Functions (Idiomatic)
```kotlin
// ✅ CORRECT - Extend existing types
fun String.toSlug(): String =
    this.lowercase().replace(" ", "-")

// Usage
val slug = "Hello World".toSlug()  // "hello-world"
```

## Coroutines (Structured)
```kotlin
// ✅ CORRECT - Structured concurrency
suspend fun fetchData(): Data = coroutineScope {
    val user = async { fetchUser() }
    val posts = async { fetchPosts() }
    Data(user.await(), posts.await())
}

// ❌ WRONG - GlobalScope (unstructured)
GlobalScope.launch { ... }  // NO! Use structured scope
```
