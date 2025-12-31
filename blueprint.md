# Instagram Clone Blueprint

## Overview

This document outlines the architecture and implementation of a production-ready Instagram clone built with Flutter. The application features a dynamic, state-driven UI, a clear separation of concerns, and a polished, modern design. It includes core features like profile viewing, editing, a comprehensive settings screen, and a flexible navigation system.

## Style, Design, and Features

### Architecture
- **State Management**: `provider` is used for robust and scalable state management. `ChangeNotifierProvider` is used for managing UI state, with `SettingsProvider` and `ProfileProvider` at the core.
- **Navigation**: `go_router` handles all routing, providing a declarative and flexible navigation system.
- **Project Structure**: The project is organized by feature, with a clear separation of presentation, application, and domain layers.

### UI/UX
- **Theme**: A modern, dark theme is implemented for a sleek and professional look. The theme can be toggled between light and dark modes.
- **Profile Screen**: A dynamic profile screen that displays the user's name, username, bio, and profile picture. It also includes stats for posts, followers, and following.
- **Edit Profile Screen**: A functional screen that allows users to edit their name, username, and bio. It includes business logic to restrict username changes to twice every 14 days.
- **Profile Picture**: Users can select a profile picture from their device's gallery.
- **Settings Screen**: A comprehensive settings screen that mirrors the essential options found in the original Instagram app. It includes account settings, privacy options, a theme toggle, and a logout feature.

### Implemented Features
- **Profile Management**:
  - View and edit profile information.
  - Update profile picture from the gallery.
  - Business logic to enforce username change restrictions.
- **State-Driven UI**:
  - The UI is fully connected to the `ProfileProvider` and `SettingsProvider`, ensuring that all data is live and dynamically updated.
- **Navigation**:
  - A clear and intuitive navigation flow between the profile, edit profile, and settings screens.
- **Settings**:
  - Toggle between light and dark themes.
  - Toggle a private account setting.
  - A logout button.

## Current Plan

The immediate next step is to run the application and ensure all implemented features are working as expected. This includes:
- Verifying that the profile data is correctly displayed and updated.
- Testing the profile picture selection and update functionality.
- Confirming that the username change restrictions are enforced.
- Ensuring the navigation between screens is smooth and bug-free.
- Testing the settings screen functionality, including the theme toggle and private account switch.

After successful testing, the application will be ready for further feature development, such as implementing a post feed, following/unfollowing users, and adding social authentication.
