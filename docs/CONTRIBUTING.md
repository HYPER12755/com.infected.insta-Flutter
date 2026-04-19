# Contributing Guide

---

## Development Setup

```bash
git clone <repo-url>
cd com.infected.insta-Flutter
flutter pub get
flutter run
```

See [SETUP.md](SETUP.md) for full environment configuration.

---

## Code Standards

### Dart Style
- Follow official [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Run `flutter analyze` before every commit — zero warnings
- Run `flutter format .` to auto-format

### State Management
- **Riverpod only** — no `setState` in top-level screens (local widget state is fine)
- Use `StateNotifier` for mutable state with business logic
- Use `FutureProvider` for one-shot async data
- Use `StreamProvider` for real-time/live data

### Repository Pattern
- All DB access goes through a repository class extending `BaseRepository`
- Every async method returns `Result<T>` — never throws to UI
- No raw Supabase calls in widgets or providers

### No Mock Data
- Never use hardcoded fake data in production code
- Empty states must show proper UI (icon + message), not placeholder text

---

## Branch Strategy

```
main          ← production-ready, tagged releases
develop       ← integration branch
feature/xyz   ← individual features
fix/xyz       ← bug fixes
```

### PR Checklist
- [ ] `flutter analyze` passes with zero issues
- [ ] `flutter format .` applied
- [ ] No debug `print()` statements
- [ ] All new DB operations use `Result<T>`
- [ ] New screens have shimmer loading state
- [ ] RLS policies updated in SUPABASE.md if new tables added

---

## Adding a New Feature

1. Create folder: `lib/features/my_feature/`
2. Structure:
   ```
   my_feature/
   ├── models/      # Data models specific to this feature
   ├── providers/   # Riverpod providers
   ├── screens/     # UI
   └── widgets/     # Reusable sub-widgets
   ```
3. Add repository method to existing repo or create new one in `lib/data/repositories/`
4. Add route to `lib/router.dart`
5. Update [API.md](API.md) with new methods
6. Add Supabase schema changes to [SUPABASE.md](SUPABASE.md)

---

## Adding a Database Table

1. Write the `CREATE TABLE` SQL + RLS policies
2. Add to [SUPABASE.md](SUPABASE.md) in the schema section
3. Create/update the relevant repository
4. Enable Realtime if needed: `ALTER PUBLICATION supabase_realtime ADD TABLE public.my_table;`

---

## Reporting Issues

Include:
- Flutter/Dart version (`flutter --version`)
- Device / OS / Android API level
- Steps to reproduce
- Expected vs actual behaviour
- Relevant error logs
