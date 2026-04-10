# Contributing Guide

Thank you for your interest in contributing to InstaClone! This guide will help you get started with the development workflow.

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Ways to Contribute](#ways-to-contribute)
3. [Getting Started](#getting-started)
4. [Development Workflow](#development-workflow)
5. [Coding Standards](#coding-standards)
6. [Git Conventions](#git-conventions)
7. [Pull Request Process](#pull-request-process)
8. [Reporting Issues](#reporting-issues)
9. [Recognition](#recognition)

---

## Code of Conduct

We are committed to providing a welcoming and inclusive experience. Please read our full [Code of Conduct](CODE_OF_CONDUCT.md) before participating.

### Key Points

- Be respectful and inclusive
- Use welcoming language
- Be collaborative and supportive
- Accept constructive criticism gracefully
- Focus on what is best for the community

---

## Ways to Contribute

### 🎯 Report Bugs
- Report bugs that you find in the issue tracker
- Include detailed steps to reproduce
- Include environment details (Flutter version, OS, etc.)

### 💡 Suggest Features
- Use the issue tracker to suggest new features
- Explain why this feature would be useful
- Provide examples of how it should work

### 🛠️ Code Contributions
- Fix bugs or implement features
- Improve documentation
- Add tests
- Refactor existing code

### 📖 Improve Documentation
- Fix typos or grammatical errors
- Add examples to APIs
- Create tutorials or guides
- Translate documentation

---

## Getting Started

### Prerequisites

Before you start, ensure you have:

1. **Flutter SDK** (3.9.x or higher) installed
2. **Git** configured with your identity
3. **Supabase account** (for backend development)
4. **Code editor** (VS Code or Android Studio recommended)

### Setup Development Environment

```bash
# 1. Fork the repository
# Click "Fork" on GitHub

# 2. Clone your fork
git clone https://github.com/YOUR_USERNAME/myapp.git
cd myapp

# 3. Add upstream remote
git remote add upstream https://github.com/ORIGINAL_REPO/myapp.git

# 4. Create a feature branch
git checkout -b feature/your-feature-name

# 5. Install dependencies
flutter pub get
```

### Running Tests

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run a specific test file
flutter test test/path/to/test_file_test.dart
```

---

## Development Workflow

### 1. Choose an Issue

- Look at the [issue tracker](https://github.com/ORIGINAL_REPO/myapp/issues)
- Find an issue labeled `good first issue` for beginners
- Comment on the issue to let others know you're working on it

### 2. Create a Branch

```bash
# Ensure you're on the latest main
git fetch upstream
git checkout main
git merge upstream/main

# Create your feature branch
git checkout -b feature/issue-description
# or
git checkout -b fix/bug-description
```

### 3. Make Changes

```bash
# Make your code changes
# Use your editor

# Check your changes
git status

# View diff
git diff
```

### 4. Write Tests (if applicable)

```dart
// test/features/auth/auth_provider_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthProvider', () {
    test('signIn should return user on success', () async {
      // Arrange
      final authProvider = AuthNotifier(mockSupabase);
      
      // Act
      await authProvider.signIn('test@example.com', 'password');
      
      // Assert
      expect(authProvider.state.isAuthenticated, true);
    });
  });
}
```

### 5. Commit Changes

Follow our [commit message conventions](#commit-messages):

```bash
# Stage changes
git add .

# Commit with a descriptive message
git commit -m "feat(auth): add Google OAuth sign-in support

- Implement GoogleSignInClient
- Add OAuth callback handling
- Update auth state management
- Add integration tests

Closes #123"
```

### 6. Push and Create PR

```bash
# Push to your fork
git push origin feature/your-feature-name

# Go to GitHub and create a Pull Request
# Fill in the PR template
```

---

## Coding Standards

### Dart/Flutter Standards

1. **Formatting**: Use `flutter format` or Dart formatter
2. **Linting**: Follow rules in `analysis_options.yaml`
3. **Naming**: Use meaningful names

```dart
// ❌ Bad
var d, x, fn;

// ✅ Good
var displayName, userProfile, fetchUserProfile;
```

### File Organization

```
lib/
├── features/
│   └── feature_name/
│       ├── data/           # Data layer
│       │   ├── models/
│       │   └── repositories/
│       ├── domain/         # Business logic
│       │   └── entities/
│       └── presentation/  # UI layer
│           ├── screens/
│           ├── widgets/
│           └── providers/
```

### Code Style

```dart
// Class definitions
class UserProfile {
  final String id;
  final String name;
  final String? avatarUrl;
  
  const UserProfile({
    required this.id,
    required this.name,
    this.avatarUrl,
  });
  
  // Use copyWith for immutable objects
  UserProfile copyWith({String? name}) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      avatarUrl: avatarUrl,
    );
  }
}

// Use trailing commas for better formatting
final list = [
  'item1',
  'item2',
  'item3',
];
```

### State Management

Use Riverpod following these patterns:

```dart
// Providers should be at the top of the file
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(supabase));
});

// State classes should be immutable
@immutable
class AuthState {
  final bool isLoading;
  final User? user;
  final String? error;
  
  const AuthState({
    this.isLoading = false,
    this.user,
    this.error,
  });
  
  AuthState copyWith({
    bool? isLoading,
    User? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
    );
  }
}
```

### Documentation

```dart
/// Fetches the user's profile from the database.
///
/// Requires authentication. Returns [UserProfile] on success
/// or throws [AuthException] if not authenticated.
///
/// Example:
/// ```dart
/// final profile = await userRepository.getProfile('user-123');
/// ```
Future<UserProfile> getProfile(String userId) async {
  // implementation
}
```

---

## Git Conventions

### Branch Naming

- `feature/description` - New features
- `fix/description` - Bug fixes
- `refactor/description` - Code refactoring
- `docs/description` - Documentation
- `test/description` - Test additions

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting
- `refactor`: Code restructuring
- `test`: Tests
- `chore`: Maintenance

**Examples:**

```
feat(auth): add password reset functionality
fix(feed): resolve duplicate posts issue
docs(readme): update installation instructions
refactor(call): extract WebRTC logic to service
test(provider): add unit tests for AuthProvider
```

---

## Pull Request Process

### PR Template

```markdown
## Description
Brief description of what this PR does

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
Describe how you tested the changes

## Checklist
- [ ] My code follows the style guidelines
- [ ] I have performed a self-review
- [ ] I have commented my code where needed
- [ ] I have updated the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix works
- [ ] New and existing tests pass locally
```

### Review Process

1. **Automated Checks** - CI runs tests and linting
2. **Code Review** - Maintainers review your code
3. **Feedback** - Address any requested changes
4. **Approval** - PR gets approved
5. **Merge** - Changes are merged to main

### What Makes a Good PR

- ✅ Small and focused
- ✅ Includes tests
- ✅ Updates documentation
- ✅ Has clear description
- ✅ Follows coding standards

---

## Reporting Issues

### Before Reporting

1. Search existing issues to avoid duplicates
2. Try to reproduce the issue
3. Check if it's already fixed in the latest version

### Issue Template

```markdown
## Description
Clear and concise description of the issue

## Steps to Reproduce
1. Go to '...'
2. Click on '...'
3. Scroll down to '...'
4. See error

## Expected Behavior
What should happen instead

## Actual Behavior
What actually happens

## Environment
- Flutter version:
- Device:
- OS version:

## Screenshots
If applicable, add screenshots

## Additional Context
Any other context about the problem
```

---

## Recognition

### Contributors

We appreciate all contributions! Contributors will be:

- Listed in the README.md
- Added to the CONTRIBUTORS file
- Mentioned in release notes

### Recognition Levels

- 🐛 Bug Hunter - Report 5+ bugs
- 💡 Idea Generator - Suggest 3+ features
- 📖 Documentation Hero - Improve docs significantly
- 🏆 Top Contributor - Multiple high-quality PRs

---

## Resources

- [Flutter Documentation](https://docs.flutter.dev)
- [Riverpod Docs](https://riverpod.dev)
- [Supabase Docs](https://supabase.com/docs)
- [GoRouter Docs](https://pub.dev/packages/go_router)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)

---

## Questions?

- 📧 Email: maintainer@example.com
- 💬 GitHub Discussions
- 💭 Discord Community Channel

Thank you for contributing to InstaClone! 🎉