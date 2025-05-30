# 📐 Coding Standards & Architecture Guide

**Online Bookstore App — Flutter + Firebase**

> Maintain clean, scalable, and maintainable code. Consistency is key. All pull requests must adhere to these conventions.

---

## 💡 Architectural Overview

- Adopt the **MVVM** (Model-View-ViewModel) architecture.
- Use `Provider` or `Riverpod` for state management.
- Feature-first folder structure: each module has its own UI, logic, and models.
- Business logic belongs in ViewModels and service layers — not in the UI.

---

## 🧠 Dart & Flutter Code Guidelines

### Code Style

- Use `const` constructors wherever possible.
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) style recommendations.
- Extract complex or long widgets into separate widget classes.
- Avoid methods over 50 lines — break into smaller units.

### Naming Conventions

| Element       | Format         | Example                     |
| ------------- | -------------- | --------------------------- |
| Classes       | PascalCase     | `BookViewModel`, `AuthForm` |
| Methods       | camelCase      | `fetchBookDetails()`        |
| Variables     | camelCase      | `userName`, `bookList`      |
| Constants     | SCREAMING_CAPS | `MAX_ITEM_LIMIT`            |
| Files/Folders | snake_case     | `book_details_screen.dart`  |

---

## 📁 Folder Structure & Modularity

```
lib/
├── core/
│   ├── router/ # Routing and navigation
│   ├── services/ # Firebase services
│   ├── theme/ # App-wide themes and styles
│   └── utils/ # Utility functions and extensions including: constants, helpers, apputils
│   ├── widgets/ # Reusable widgets
│
├── features/               # Each folder = 1 feature/module
│   ├── auth/
│   │   ├── view/ # UI screens & widgets
│   │   ├── viewmodel/ # Business logic
│   │   └── model/ # Data models
│   ├── bookstore/
│   ├── cart/
│   ├── order/
│   └── profile/
└── main.dart
```

### Feature Folder Structure

Each `features/<module>/` should contain:

- `view/` — Screens & widgets (Stateless by default)
- `viewmodel/` — Business logic using `ChangeNotifier`
- `model/` — DTOs, form data, Firestore-specific types

---

## 🎨 UI & UX Standards

- Use `Material 3` widgets where supported.
- Follow accessibility guidelines: sufficient contrast, minimum tap size, readable fonts.
- Use `Theme.of(context)` and `MediaQuery` for theming and responsiveness.
- Design for both small and large screens (phones and tablets).

---

## 🔐 Firebase Integration & Firestore Design

- Enforce **Role-Based Access Control (RBAC)** in Firestore security rules.
- Avoid deep document nesting beyond 2-3 levels.
- Use `.where()` and indexing efficiently — avoid client-side filtering.
- Do not hardcode Firestore paths — centralize them in a constants file.

---

## 🧪 Testing Strategy

- Write **unit tests** for ViewModels, services, and helpers.
- Add **widget tests** for screens like `LoginScreen`, `CartScreen`, etc.
- Organize tests as:
  ```
  test/
  ├── auth/
  ├── bookstore/
  └── core/
  ```
- Mock Firebase using tools like `mockito`, `cloud_firestore_mocks`, or `firebase_auth_mocks`.

---

## 🛠 Error Handling & Logging

- Use `try-catch` for all async Firebase operations.
- Avoid exposing technical error messages — use friendly feedback via `SnackBar` or `AlertDialog`.
- Use fallback UI widgets like `ErrorWidget`, `EmptyStateWidget`, and `RetryButton`.
- Log errors with context for easy debugging.

---

## ✅ Code Review Checklist

- [ ] Folder structure matches MVVM + feature-first layout.
- [ ] Classes, files, and methods follow naming conventions.
- [ ] Widgets are stateless unless state is needed.
- [ ] Business logic is separated from UI.
- [ ] Firebase reads/writes are handled in service or ViewModel, not in UI.
- [ ] All new code has relevant tests and is well-documented.
- [ ] Error states are gracefully handled.
