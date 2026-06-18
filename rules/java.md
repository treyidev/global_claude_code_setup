---
paths:
  - "**/*.java"
---

# Java standards (auto-loaded on `**/*.java`)

Deep Java-specific standards. **Path-scoped**: loaded deterministically by the harness only when
you read or edit Java (see *Instruction architecture* in `~/.claude/CLAUDE.md`). Cross-language
principles (SOLID, clean code, architecture, documentation, fail-fast) live in `CLAUDE.md` and
apply on top of this.

## Null Handling (Required)
```java
// ✅ CORRECT - Optional for nullable returns
public Optional<User> findUser(String id) {
    return Optional.ofNullable(repository.find(id));
}

// ✅ CORRECT - @Nullable/@NonNull annotations
public void process(@NonNull String input, @Nullable Config config) { }

// ❌ WRONG - Returning null without indication
public User findUser(String id) {
    return null;  // NO! Use Optional
}
```

## Immutability (Prefer)
```java
// ✅ CORRECT - Immutable with records (Java 16+)
public record User(String id, String name, String email) {}

// ✅ CORRECT - Final fields, no setters
public final class User {
    private final String id;
    private final String name;

    public User(String id, String name) {
        this.id = id;
        this.name = name;
    }
}

// ❌ WRONG - Mutable bean
public class User {
    private String id;
    public void setId(String id) { this.id = id; }  // NO!
}
```

## Streams (Idiomatic)
```java
// ✅ CORRECT - Stream API for collections
List<String> names = users.stream()
    .filter(User::isActive)
    .map(User::getName)
    .collect(Collectors.toList());

// ❌ WRONG - Manual iteration for transformations
List<String> names = new ArrayList<>();
for (User user : users) {
    if (user.isActive()) {
        names.add(user.getName());
    }
}
```

## Dependency Injection
```java
// ✅ CORRECT - Constructor injection
public class UserService {
    private final UserRepository repository;

    public UserService(UserRepository repository) {
        this.repository = repository;
    }
}

// ❌ WRONG - Field injection
public class UserService {
    @Inject
    private UserRepository repository;  // Harder to test
}
```
