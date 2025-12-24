# Instagram Clone Blueprint

## Overview

This document outlines the style, design, and features of an Instagram clone created with Flutter.

## Style and Design

The app features a clean and modern design with a light and dark theme. The color scheme is based on the Instagram brand, with a focus on black, white, and grey. The typography is simple and easy to read. The UI is built with standard Flutter widgets and placeholder data to simulate a real user experience. I have polished the UI to be more consistent with the Instagram UI, including adding a staggered grid view to the search screen, and updating the profile screen to have a more modern and clean UI. The creation of new posts is handled through a modal bottom sheet for a seamless user experience.

## Features

- **Splash Screen**: The first screen the user sees when they open the app.
- **Login Screen**: A simple login screen that allows a user to enter their credentials.
- **Feed Screen**: Displays a list of posts with likes, comments, and share buttons. The username and caption are tappable.
- **Search Screen**: Features a staggered grid layout for a more visually appealing presentation of search results.
- **Create Post Screen**: Allows users to select an image from their gallery, write a caption, and upload the new post. The image is stored in Firebase Storage and the post data is saved to Firestore. This screen is presented as a modal bottom sheet.
- **Reels Screen**: Displays a list of reels in a `PageView` with an overlay for user information and a follow button.
- **Profile Screen**: Features a modern and clean UI with a circular profile picture, a "Follow" button, and tappable stats.
- **Bottom Navigation Bar**: Allows users to easily switch between the Feed, Search, Reels, and Profile screens. Tapping the 'Create' icon opens a modal sheet for creating a new post.
