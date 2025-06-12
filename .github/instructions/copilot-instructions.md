# 📐 GitHub Copilot Custom Instructions for Pertukekem Online Bookstore

**Online Bookstore App — Flutter + Firebase**
Maintain clean, scalable, and maintainable code. Consistency is key. All pull requests must adhere to these conventions.

---

## 💡 Architectural Overview

- Adopt the **MVVM** (Model-View-ViewModel) architecture.
- Use **Provider** (`ChangeNotifierProvider`, `Consumer`) for state management.
- Feature-first folder structure: each module has its own UI, logic, and models.
- Business logic belongs in ViewModels and service layers — not in the UI.

---

## 📁 Folder Structure & Modularity

```
lib/
├── core/
│   ├── router/       # Routing and navigation
│   ├── services/     # Shared services (e.g., Firebase interactions)
│   ├── theme/        # App-wide themes and styles
│   ├── utils/        # Utility functions, extensions, constants
│   └── widgets/      # Reusable widgets
├── features/         # Each folder = one feature/module
│   ├── auth/
│   │   ├── view/          # UI screens & widgets (Stateless)
│   │   ├── viewmodel/     # Business logic (`ChangeNotifier`)
│   │   └── model/         # DTOs, form data, Firestore types
│   ├── book_catalog/
│   ├── cart/
│   ├── order/
│   └── profile/
└── main.dart
```

- Register all feature `ChangeNotifierProviders` in `main.dart` or a dedicated `providers.dart` using `MultiProvider`.

---

## 🧠 Dart & Flutter Code Guidelines

### Code Style

- Use `const` constructors everywhere possible.
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) rules.
- Extract complex or long widgets into separate widget classes.
- Avoid methods over 50 lines—break into smaller, testable units.

### Naming Conventions

| Element       | Format         | Example                     |
| ------------- | -------------- | --------------------------- |
| Classes       | PascalCase     | `BookViewModel`, `AuthForm` |
| Methods       | camelCase      | `fetchBookDetails()`        |
| Variables     | camelCase      | `userName`, `bookList`      |
| Constants     | SCREAMING_CAPS | `MAX_ITEM_LIMIT`            |
| Files/Folders | snake_case     | `book_details_screen.dart`  |

### Analysis Options & Formatting

- Include `analysis_options.yaml` at the repo root with:

  ```yaml
  include: package:flutter_lints/flutter.yaml
  linter:
    rules:
      - prefer_const_constructors
      - avoid_print
      - curly_braces_in_flow_control_structures
  ```

- Enable auto-format on save (`editor.formatOnSave: true`).
- Enforce max line length of 80 characters.
- Use single quotes for strings where possible.

---

## 🎨 UI & UX Standards

- Use Material 3 widgets and theming (`ThemeData`, `ColorScheme`).
- Follow accessibility guidelines: adequate contrast, minimum tap sizes, scalable fonts.
- Use `Theme.of(context)` and `MediaQuery` for responsive layouts.
- Design for phones and tablets; test on different screen sizes.

---

## 🔐 Firebase & Firestore Design

- Enforce **Role-Based Access Control (RBAC)** in Firestore security rules.
- Avoid deep document nesting beyond 2–3 levels.
- Use indexed queries (`.where()`); avoid heavy client-side filtering.
- Centralize Firestore paths in a constants file; do not hardcode strings.

---

## 🛠 Error Handling & Logging

- Wrap all async operations in `try/catch`.
- Surface user-friendly messages via `SnackBar` or `AlertDialog`.
- Provide fallback UI components: `ErrorWidget`, `EmptyStateWidget`, `RetryButton`.
- Log errors with contextual information for debugging.

---

## ✅ Code Review Checklist

- [ ] Folder structure matches MVVM + feature-first layout.
- [ ] Classes, files, and methods follow naming conventions.
- [ ] Widgets are stateless by default; state resides in ViewModels.
- [ ] Business logic is separated from UI.
- [ ] Firebase reads/writes handled in service or ViewModel, not UI.
- [ ] All new code includes relevant tests and documentation.
- [ ] Error and loading states are gracefully handled.
