---
paths:
  - "**/*.cpp"
  - "**/*.cc"
  - "**/*.cxx"
  - "**/*.h"
  - "**/*.hpp"
  - "**/*.hh"
---

# C++ standards (auto-loaded on `**/*.cpp`, `**/*.h`, …)

Deep C++-specific standards. **Path-scoped**: loaded deterministically by the harness only when
you read or edit C++ (see *Instruction architecture* in `~/.claude/CLAUDE.md`). Cross-language
principles (SOLID, clean code, architecture, documentation, fail-fast) live in `CLAUDE.md` and
apply on top of this.

## Memory Management (RAII)
```cpp
// ✅ CORRECT - Smart pointers
auto user = std::make_unique<User>("Alice");
auto shared = std::make_shared<Config>();

// ❌ WRONG - Raw new/delete
User* user = new User("Alice");  // NO! Memory leak risk
delete user;
```

## Const Correctness (Required)
```cpp
// ✅ CORRECT - Const where possible
class UserService {
public:
    const User& getUser(const std::string& id) const;
    void updateUser(const User& user);  // Takes const ref
};

// ❌ WRONG - Missing const
User& getUser(std::string id);  // Non-const, copies string
```

## Modern C++ (C++17/20)
```cpp
// ✅ CORRECT - Structured bindings
auto [name, age, email] = getUser();

// ✅ CORRECT - std::optional for nullable
std::optional<User> findUser(const std::string& id);

// ✅ CORRECT - Range-based for
for (const auto& item : items) { ... }

// ❌ WRONG - C-style
for (int i = 0; i < items.size(); i++) { ... }  // Prefer range-based
```

## Error Handling
```cpp
// ✅ CORRECT - Exceptions for errors, optional for absence
std::optional<User> findUser(const std::string& id);  // May not exist
User getUser(const std::string& id);  // Throws if not found

// ✅ CORRECT - noexcept where guaranteed
void swap(User& a, User& b) noexcept;
```

## Includes (Grouped, Explicit)
```cpp
// ✅ CORRECT - std headers, then project headers
#include <memory>
#include <string>
#include <vector>

#include "project/domain/user.hpp"
#include "project/repository/user_repository.hpp"

// ❌ NEVER
#include <bits/stdc++.h>  // non-portable; pulls in the entire stdlib
```

## Type clarity (`auto` judiciously)
```cpp
// ✅ CORRECT - explicit where the type matters; auto where it aids readability
std::vector<User> users;
auto it = configs.find(key);   // auto OK — type is obvious from context

// ❌ WRONG - auto that obscures the type
auto x = getValue();           // what is x?
```
