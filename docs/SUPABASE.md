# Supabase Configuration Guide

This guide covers the complete Supabase backend setup for the InstaClone app, including database schema, authentication, storage, and real-time features.

## Table of Contents

1. [Database Schema](#database-schema)
2. [Authentication](#authentication)
3. [Row Level Security](#row-level-security)
4. [Storage](#storage)
5. [Real-time](#real-time)
6. [Edge Functions (Optional)](#edge-functions-optional)
7. [Supabase Client Code](#supabase-client-code)

---

## Database Schema

Run these SQL statements in the Supabase SQL Editor to create the required tables.

### Users Table

```sql
-- Create custom users table that extends Supabase auth.users
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  display_name TEXT,
  avatar_url TEXT,
  bio TEXT,
  website TEXT,
  is_private BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Create profile on user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, display_name, avatar_url)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data->>'username',
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

### Posts Table

```sql
-- Posts table
CREATE TABLE public.posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  caption TEXT,
  image_url TEXT NOT NULL,
  likes_count INTEGER DEFAULT 0,
  comments_count INTEGER DEFAULT 0,
  is_archived BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
```

### Comments Table

```sql
-- Comments table
CREATE TABLE public.comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
```

### Likes Table

```sql
-- Likes table
CREATE TABLE public.likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, post_id)
);

ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;
```

### Follows Table

```sql
-- Follows table
CREATE TABLE public.follows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  following_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(follower_id, following_id)
);

ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;
```

### Messages Table

```sql
-- Conversations table
CREATE TABLE public.conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Messages table
CREATE TABLE public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE NOT NULL,
  sender_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  content TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
```

### Stories Table

```sql
-- Stories table
CREATE TABLE public.stories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  image_url TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.stories ENABLE ROW LEVEL SECURITY;
```

### Notifications Table

```sql
-- Notifications table
CREATE TABLE public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL,
  from_user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  post_id UUID REFERENCES public.posts(id) ON DELETE SET NULL,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
```

---

## Authentication

### Enable Providers

1. Go to **Authentication** → **Providers**
2. Enable **Email** (Email + Password)
3. Enable **Google** (optional)

### Email Configuration

For production, configure email in **Authentication** → **Email**:

- **Confirm email**: Enable for email verification
- **Password reset**: Enable for forgot password flow
- **Secure password**: Set minimum requirements (8 characters recommended)

### Google OAuth Setup

1. Go to **Authentication** → **Providers** → **Google**
2. Enable the provider
3. Enter your Google Cloud OAuth credentials:
   - Client ID
   - Client Secret
4. Add redirect URI: `https://your-project.supabase.co/auth/v1/callback`

---

## Row Level Security (RLS)

### Profiles Policy

```sql
-- Users can read all public profiles
CREATE POLICY "Public profiles are viewable by everyone"
ON public.profiles FOR SELECT
USING (is_private = false);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
ON public.profiles FOR UPDATE
USING (auth.uid() = id);
```

### Posts Policy

```sql
-- Anyone can view posts
CREATE POLICY "Posts are public"
ON public.posts FOR SELECT
USING (true);

-- Users can create posts
CREATE POLICY "Users can create posts"
ON public.posts FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users can update own posts
CREATE POLICY "Users can update own posts"
ON public.posts FOR UPDATE
USING (auth.uid() = user_id);

-- Users can delete own posts
CREATE POLICY "Users can delete own posts"
ON public.posts FOR DELETE
USING (auth.uid() = user_id);
```

### Follows Policy

```sql
-- Anyone can view follows
CREATE POLICY "Follows are public"
ON public.follows FOR SELECT
USING (true);

-- Users can follow others
CREATE POLICY "Users can follow"
ON public.follows FOR INSERT
WITH CHECK (auth.uid() = follower_id);

-- Users can unfollow
CREATE POLICY "Users can unfollow"
ON public.follows FOR DELETE
USING (auth.uid() = follower_id);
```

### Messages Policy

```sql
-- Users can only see their own conversations
CREATE POLICY "Users see own conversations"
ON public.conversations FOR SELECT
USING (
  id IN (
    SELECT conversation_id FROM public.messages 
    WHERE sender_id = auth.uid()
  )
);

-- Users can only see messages in their conversations
CREATE POLICY "Users see own messages"
ON public.messages FOR SELECT
USING (
  sender_id = auth.uid() OR 
  conversation_id IN (
    SELECT id FROM public.conversations WHERE true
  )
);

-- Users can send messages
CREATE POLICY "Users can send messages"
ON public.messages FOR INSERT
WITH CHECK (auth.uid() = sender_id);
```

---

## Storage

### Create Storage Buckets

Go to **Storage** → **New Bucket**:

1. **posts** - For post images
   - Public bucket: Yes
   - File size limit: 10MB
   - Allowed types: images, video

2. **avatars** - For profile pictures
   - Public bucket: Yes
   - File size limit: 2MB
   - Allowed types: images

3. **stories** - For story images
   - Public bucket: Yes
   - File size limit: 10MB
   - Allowed types: images

### Storage Policies

```sql
-- Anyone can view images
CREATE POLICY "Public access to posts"
ON storage.objects FOR SELECT
USING (bucket_id = 'posts');

CREATE POLICY "Public access to avatars"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

CREATE POLICY "Public access to stories"
ON storage.objects FOR SELECT
USING (bucket_id = 'stories');

-- Users can upload to their folder
CREATE POLICY "Users upload posts"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'posts' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users upload avatars"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
```

---

## Real-time

### Enable Realtime

1. Go to **Database** → **Replication**
2. Enable replication for tables:
   - `messages`
   - `notifications`
   - `posts`

### Realtime Configuration

```sql
-- Enable realtime on messages
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;

-- Enable realtime on notifications
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;

-- Enable realtime on posts
ALTER PUBLICATION supabase_realtime ADD TABLE public.posts;
```

---

## Edge Functions (Optional)

For advanced features like push notifications, you can create Edge Functions.

### Example: Send Push Notification

```typescript
// supabase/functions/send-notification/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  const { user_id, title, body } = await req.json()

  // Fetch user's expo push token from database
  const { data: user } = await supabase
    .from('profiles')
    .select('push_token')
    .eq('id', user_id)
    .single()

  // Send push notification (implement your push service)
  // ...

  return new Response(JSON.stringify({ success: true }), {
    headers: { 'Content-Type': 'application/json' }
  })
})
```

---

## Supabase Client Code

The app uses the Supabase Flutter SDK. Here's how it's configured:

```dart
// lib/supabase/supabase_client.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:infected_insta/core/config/app_config.dart';

class SupabaseConfig {
  static Future<void> initialize() async {
    if (!AppConfig.isValidUrl(AppConfig.supabaseUrl)) {
      throw Exception('Invalid SUPABASE_URL');
    }
    
    if (AppConfig.supabaseAnonKey.isEmpty) {
      throw Exception('Invalid SUPABASE_ANON_KEY');
    }
    
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }
}

final supabase = Supabase.instance.client;

// Auth helpers
Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;
Session? get currentSession => supabase.auth.currentSession;
User? get currentUser => currentSession?.user;
```

### Using Supabase in Code

```dart
// Fetch posts
final posts = await supabase
  .from('posts')
  .select('*, profiles(username, avatar_url)')
  .order('created_at', ascending: false);

// Insert post
await supabase.from('posts').insert({
  'user_id': currentUser!.id,
  'caption': 'My new post!',
  'image_url': 'https://...',
});

// Real-time subscription
supabase
  .from('messages')
  .stream(primaryKey: ['id'])
  .eq('conversation_id', conversationId)
  .listen((messages) {
    // Handle new messages
  });
```

---

## Database Migrations

### Using Supabase CLI

```bash
# Login
supabase login

# Link to project
supabase link --project-ref YOUR_PROJECT_REF

# Push schema changes
supabase db push

# Pull existing schema
supabase db pull

# Open SQL editor
supabase projects api
```

---

## Troubleshooting

### Common Issues

1. **RLS Policy Error**: "row-level security policy"
   - Check that policies are created for all tables
   - Verify you're authenticated

2. **Storage Upload Failed**: "Object not found"
   - Check bucket policies
   - Verify file path format

3. **Realtime Not Working**: "channel not found"
   - Enable replication on tables
   - Check Supabase project status

4. **Auth Errors**: "Invalid login credentials"
   - Verify email/password
   - Check auth provider settings

---

## Next Steps

- [API Documentation](API.md) - Complete API reference
- [Contributing Guide](CONTRIBUTING.md) - Development workflow