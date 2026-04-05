# Flutter UI Generation Skills - Glassmorphism & Premium UI

## Skill: Flutter Glass UI Agent

### Description
AI-powered Flutter UI generation agent specializing in modern glassmorphism, premium UI effects, and professional mobile interfaces.

### Activation Phrases
- "Create glass UI"
- "Build premium Flutter interface"
- "Make a modern Flutter screen"

### Implementation Capabilities

#### 1. Glassmorphism (Frosted Glass Effect)
```dart
class GlassContainer extends StatelessWidget {
  Widget child;
  double blur;
  double opacity;
  Color color;

  // Glass effect with:
  // - BackdropFilter with ImageFilter.blur
  // - Semi-transparent background
  // - Subtle border/shadow
  // - BorderRadius for smooth edges
}
```

#### 2. Premium UI Components
| Component | Style |
|-----------|-------|
| Cards | Glassmorphism with shadows |
| Buttons | Gradient + glow effects |
| Inputs | Frosted glass borders |
| Bottom Nav | Floating glass bar |
| Headers | Blur + gradient overlay |
| Dialogs | Centered glass modal |
| Chips | Glass with gradient borders |

#### 3. Animation Patterns
- Page transitions (fade, slide, scale)
- Button press animations
- Card hover/tap effects
- Shimmer loading states
- Smooth scroll physics

#### 4. Color Schemes
- **Dark Mode**: Deep blacks (#0A0A0A), charcoal (#1A1A1A)
- **Glass**: White 10-20% opacity with blur
- **Accents**: Gradient (purple→blue), gold accents
- **Text**: White 87%, 60%, 38% opacity levels

---

## Skill: Premium Screen Generator

### Template: Social App Profile Screen
```dart
Scaffold(
  backgroundColor: Color(0xFF0A0A0A), // Deep black
  body: Stack(
    children: [
      // Gradient background image
      // Blur effect header
      // Glass profile card
      // Stats row with glass chips
      // Action buttons (Follow, Message)
      // Grid tabs (Posts, Media)
    ]
  )
)
```

### Template: Video Call Screen
```dart
Stack(
  children: [
    // Full-screen video renderer
    // Glass control bar (bottom)
    // Glass name badge (top)
    // Floating buttons (mute, camera, end)
  ]
)
```

---

## Skill: Advanced Flutter Animations

### Hero Animations
- Profile avatar → detail view
- Card → full-screen detail
- Button → form screen

### Micro-interactions
- Heart/like burst animation
- Share sheet animation
- Notification pop-in
- Pull-to-refresh custom

### Page Transitions
- iOS-style slide
- Android fade-through
- Custom curved motions

---

## Usage Examples

| Request | Action |
|---------|---------|
| "Create glass card" | Generates GlassContainer widget |
| "Add profile screen" | Full screen with glass UI |
| "Add dark mode" | Converts to dark theme variants |
| "Add animation" | Adds micro-interactions |
| "Premium button" | Gradient glow button |

---

## Key Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  # For glass effects
  # Built-in: BackdropFilter, ClipRRect, AnimatedContainer
```

## Built-in Flutter Glass Techniques

```dart
// 1. Basic Glass Container
Container(
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.1),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.white.withOpacity(0.2)),
  ),
)

// 2. Frosted Glass
BackdropFilter(
  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
  child: Container(...),
)

// 3. Gradient Glass
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]
    ),
  ),
)

// 4. Animated Glass
AnimatedContainer(
  duration: Duration(milliseconds: 200),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(animated ? 20 : 12),
  ),
)
```

---

## Complete Example: Glass Profile Card
```dart
class GlassProfileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(radius: 50, backgroundImage: ...),
                SizedBox(height: 16),
                Text("Username", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text("@handle", style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}