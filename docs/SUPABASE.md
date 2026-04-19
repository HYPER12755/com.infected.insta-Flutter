# Supabase Configuration

Complete SQL schema, RLS policies, Storage setup, and Realtime configuration.

Run all SQL in **Supabase Dashboard → SQL Editor**.

---

## Database Schema

### Core Tables

```sql
-- ════════════════════════════════════════
-- PROFILES (extends auth.users)
-- ════════════════════════════════════════
CREATE TABLE public.profiles (
  id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username      TEXT UNIQUE NOT NULL,
  full_name     TEXT,
  avatar_url    TEXT,
  bio           TEXT DEFAULT '',
  website       TEXT DEFAULT '',
  is_private    BOOLEAN DEFAULT false,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, full_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username',
             split_part(NEW.email, '@', 1)),
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'avatar_url'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ════════════════════════════════════════
-- FOLLOWS
-- ════════════════════════════════════════
CREATE TABLE public.follows (
  follower_id   UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  following_id  UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (follower_id, following_id)
);

-- ════════════════════════════════════════
-- FOLLOW REQUESTS (private accounts)
-- ════════════════════════════════════════
CREATE TABLE public.follow_requests (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id  UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  target_id     UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  status        TEXT DEFAULT 'pending' CHECK (status IN ('pending','accepted','rejected')),
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (requester_id, target_id)
);

-- ════════════════════════════════════════
-- BLOCKS
-- ════════════════════════════════════════
CREATE TABLE public.blocks (
  blocker_id    UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  blocked_id    UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (blocker_id, blocked_id)
);

-- ════════════════════════════════════════
-- POSTS
-- ════════════════════════════════════════
CREATE TABLE public.posts (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  image_url     TEXT NOT NULL,
  caption       TEXT DEFAULT '',
  location      TEXT DEFAULT '',
  is_archived   BOOLEAN DEFAULT false,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ════════════════════════════════════════
-- POST LIKES
-- ════════════════════════════════════════
CREATE TABLE public.post_likes (
  post_id    UUID REFERENCES public.posts(id) ON DELETE CASCADE,
  user_id    UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (post_id, user_id)
);

-- ════════════════════════════════════════
-- SAVED POSTS
-- ════════════════════════════════════════
CREATE TABLE public.saved_posts (
  post_id    UUID REFERENCES public.posts(id) ON DELETE CASCADE,
  user_id    UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (post_id, user_id)
);

-- ════════════════════════════════════════
-- POST TAGS
-- ════════════════════════════════════════
CREATE TABLE public.post_tags (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id         UUID REFERENCES public.posts(id) ON DELETE CASCADE,
  tagged_user_id  UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ════════════════════════════════════════
-- COMMENTS
-- ════════════════════════════════════════
CREATE TABLE public.comments (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id    UUID REFERENCES public.posts(id) ON DELETE CASCADE NOT NULL,
  user_id    UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  text       TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ════════════════════════════════════════
-- STORIES
-- ════════════════════════════════════════
CREATE TABLE public.stories (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  image_url  TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '24 hours')
);

-- ════════════════════════════════════════
-- NOTES (top of DM inbox, 24hr)
-- ════════════════════════════════════════
CREATE TABLE public.notes (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  text       TEXT NOT NULL CHECK (char_length(text) <= 60),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '24 hours')
);

-- ════════════════════════════════════════
-- CONVERSATIONS
-- ════════════════════════════════════════
CREATE TABLE public.conversations (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  participant_ids  UUID[] NOT NULL,
  last_message     TEXT DEFAULT '',
  last_sender_id   UUID,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast participant lookup
CREATE INDEX idx_conversations_participants
  ON public.conversations USING GIN (participant_ids);

-- ════════════════════════════════════════
-- MESSAGES
-- ════════════════════════════════════════
CREATE TABLE public.messages (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id  UUID REFERENCES public.conversations(id) ON DELETE CASCADE NOT NULL,
  sender_id        UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  text             TEXT NOT NULL DEFAULT '',
  is_read          BOOLEAN DEFAULT false,
  is_deleted       BOOLEAN DEFAULT false,
  reply_to_id      UUID REFERENCES public.messages(id) ON DELETE SET NULL,
  reply_text       TEXT,
  reply_sender     TEXT,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

-- ════════════════════════════════════════
-- MESSAGE REACTIONS
-- ════════════════════════════════════════
CREATE TABLE public.message_reactions (
  message_id UUID REFERENCES public.messages(id) ON DELETE CASCADE,
  user_id    UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  emoji      TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (message_id, user_id)
);

-- ════════════════════════════════════════
-- TYPING INDICATORS
-- ════════════════════════════════════════
CREATE TABLE public.typing_indicators (
  conversation_id  UUID REFERENCES public.conversations(id) ON DELETE CASCADE,
  user_id          UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  is_typing        BOOLEAN DEFAULT false,
  updated_at       TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (conversation_id, user_id)
);

-- ════════════════════════════════════════
-- NOTIFICATIONS
-- ════════════════════════════════════════
CREATE TABLE public.notifications (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  actor_id        UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  actor_username  TEXT,
  actor_avatar    TEXT,
  type            TEXT NOT NULL CHECK (type IN ('like','comment','follow','mention','follow_request')),
  post_id         UUID REFERENCES public.posts(id) ON DELETE CASCADE,
  post_image      TEXT,
  comment_text    TEXT,
  message         TEXT,
  is_read         BOOLEAN DEFAULT false,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ════════════════════════════════════════
-- CALLS
-- ════════════════════════════════════════
CREATE TABLE public.calls (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  caller_id     UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  callee_id     UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  caller_name   TEXT DEFAULT '',
  caller_avatar TEXT DEFAULT '',
  callee_name   TEXT DEFAULT '',
  room_id       UUID DEFAULT gen_random_uuid() UNIQUE NOT NULL,
  status        TEXT DEFAULT 'ringing' CHECK (status IN ('ringing','accepted','declined','ended','missed')),
  call_type     TEXT DEFAULT 'audio' CHECK (call_type IN ('audio','video')),
  started_at    TIMESTAMPTZ,
  ended_at      TIMESTAMPTZ,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- WebRTC signaling
CREATE TABLE public.call_signals (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  call_id     UUID REFERENCES public.calls(id) ON DELETE CASCADE NOT NULL,
  sender_id   UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  signal_type TEXT NOT NULL,
  signal_data JSONB,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
```

---

## Row Level Security (RLS)

Enable RLS and add policies for each table:

```sql
-- ── Profiles ──────────────────────────────────────────────────────────────
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Profiles are viewable by everyone"
  ON public.profiles FOR SELECT USING (true);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- ── Posts ──────────────────────────────────────────────────────────────────
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Posts are viewable by everyone"
  ON public.posts FOR SELECT USING (true);

CREATE POLICY "Users can insert own posts"
  ON public.posts FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own posts"
  ON public.posts FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own posts"
  ON public.posts FOR DELETE USING (auth.uid() = user_id);

-- ── Post Likes ────────────────────────────────────────────────────────────
ALTER TABLE public.post_likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Likes viewable by everyone"
  ON public.post_likes FOR SELECT USING (true);

CREATE POLICY "Users can like posts"
  ON public.post_likes FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unlike posts"
  ON public.post_likes FOR DELETE USING (auth.uid() = user_id);

-- ── Saved Posts ───────────────────────────────────────────────────────────
ALTER TABLE public.saved_posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own saved posts"
  ON public.saved_posts FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can save posts"
  ON public.saved_posts FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unsave posts"
  ON public.saved_posts FOR DELETE USING (auth.uid() = user_id);

-- ── Comments ──────────────────────────────────────────────────────────────
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Comments viewable by everyone"
  ON public.comments FOR SELECT USING (true);

CREATE POLICY "Users can add comments"
  ON public.comments FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own comments"
  ON public.comments FOR DELETE USING (auth.uid() = user_id);

-- ── Follows ───────────────────────────────────────────────────────────────
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Follows viewable by everyone"
  ON public.follows FOR SELECT USING (true);

CREATE POLICY "Users can follow"
  ON public.follows FOR INSERT WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Users can unfollow"
  ON public.follows FOR DELETE USING (auth.uid() = follower_id);

-- ── Stories ───────────────────────────────────────────────────────────────
ALTER TABLE public.stories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Active stories viewable by everyone"
  ON public.stories FOR SELECT
  USING (expires_at > NOW());

CREATE POLICY "Users can create stories"
  ON public.stories FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own stories"
  ON public.stories FOR DELETE USING (auth.uid() = user_id);

-- ── Notes ─────────────────────────────────────────────────────────────────
ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Active notes viewable by everyone"
  ON public.notes FOR SELECT USING (expires_at > NOW());

CREATE POLICY "Users can create notes"
  ON public.notes FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own notes"
  ON public.notes FOR DELETE USING (auth.uid() = user_id);

-- ── Conversations ─────────────────────────────────────────────────────────
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their conversations"
  ON public.conversations FOR SELECT
  USING (auth.uid() = ANY(participant_ids));

CREATE POLICY "Users can create conversations"
  ON public.conversations FOR INSERT
  WITH CHECK (auth.uid() = ANY(participant_ids));

CREATE POLICY "Participants can update conversation"
  ON public.conversations FOR UPDATE
  USING (auth.uid() = ANY(participant_ids));

-- ── Messages ──────────────────────────────────────────────────────────────
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Conversation participants can view messages"
  ON public.messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = conversation_id
      AND auth.uid() = ANY(c.participant_ids)
    )
  );

CREATE POLICY "Users can send messages"
  ON public.messages FOR INSERT
  WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can update own messages"
  ON public.messages FOR UPDATE USING (auth.uid() = sender_id);

-- ── Message Reactions ─────────────────────────────────────────────────────
ALTER TABLE public.message_reactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Reactions viewable by conversation participants"
  ON public.message_reactions FOR SELECT USING (true);

CREATE POLICY "Users can react"
  ON public.message_reactions FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can change own reaction"
  ON public.message_reactions FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can remove own reaction"
  ON public.message_reactions FOR DELETE USING (auth.uid() = user_id);

-- ── Typing Indicators ─────────────────────────────────────────────────────
ALTER TABLE public.typing_indicators ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Typing indicators viewable by conversation participants"
  ON public.typing_indicators FOR ALL USING (true);

-- ── Notifications ─────────────────────────────────────────────────────────
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own notifications"
  ON public.notifications FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "System can insert notifications"
  ON public.notifications FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update own notifications"
  ON public.notifications FOR UPDATE USING (auth.uid() = user_id);

-- ── Calls ─────────────────────────────────────────────────────────────────
ALTER TABLE public.calls ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Call participants can view calls"
  ON public.calls FOR SELECT
  USING (auth.uid() = caller_id OR auth.uid() = callee_id);

CREATE POLICY "Callers can create calls"
  ON public.calls FOR INSERT WITH CHECK (auth.uid() = caller_id);

CREATE POLICY "Participants can update call status"
  ON public.calls FOR UPDATE
  USING (auth.uid() = caller_id OR auth.uid() = callee_id);

-- ── Blocks ────────────────────────────────────────────────────────────────
ALTER TABLE public.blocks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own blocks"
  ON public.blocks FOR SELECT USING (auth.uid() = blocker_id);

CREATE POLICY "Users can block"
  ON public.blocks FOR INSERT WITH CHECK (auth.uid() = blocker_id);

CREATE POLICY "Users can unblock"
  ON public.blocks FOR DELETE USING (auth.uid() = blocker_id);
```

---

## Realtime

Enable Realtime for tables that need live updates:

```sql
-- Enable realtime publications
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE public.typing_indicators;
ALTER PUBLICATION supabase_realtime ADD TABLE public.calls;
ALTER PUBLICATION supabase_realtime ADD TABLE public.call_signals;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notes;
```

---

## Storage Buckets

Create these in **Supabase → Storage → New Bucket**:

```sql
-- Run in SQL editor to create buckets programmatically
INSERT INTO storage.buckets (id, name, public)
VALUES
  ('posts',    'posts',    true),
  ('avatars',  'avatars',  true),
  ('stories',  'stories',  true),
  ('messages', 'messages', true);

-- Storage policies
CREATE POLICY "Anyone can view post images"
  ON storage.objects FOR SELECT USING (bucket_id = 'posts');

CREATE POLICY "Authenticated users can upload posts"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'posts' AND auth.role() = 'authenticated');

CREATE POLICY "Users can delete own post images"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'posts' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Anyone can view avatars"
  ON storage.objects FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY "Authenticated users can upload avatars"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'avatars' AND auth.role() = 'authenticated');

CREATE POLICY "Anyone can view stories"
  ON storage.objects FOR SELECT USING (bucket_id = 'stories');

CREATE POLICY "Authenticated users can upload stories"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'stories' AND auth.role() = 'authenticated');

CREATE POLICY "Conversation participants can view DM media"
  ON storage.objects FOR SELECT USING (bucket_id = 'messages');

CREATE POLICY "Authenticated users can upload DM media"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'messages' AND auth.role() = 'authenticated');
```

---

## Automatic Notification Triggers (Optional)

```sql
-- Notify on like
CREATE OR REPLACE FUNCTION notify_on_like()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  post_owner UUID;
  liker_username TEXT;
  liker_avatar TEXT;
BEGIN
  SELECT user_id INTO post_owner FROM public.posts WHERE id = NEW.post_id;
  SELECT username, avatar_url INTO liker_username, liker_avatar
    FROM public.profiles WHERE id = NEW.user_id;

  IF post_owner != NEW.user_id THEN
    INSERT INTO public.notifications (user_id, actor_id, actor_username, actor_avatar, type, post_id)
    VALUES (post_owner, NEW.user_id, liker_username, liker_avatar, 'like', NEW.post_id);
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_post_like
  AFTER INSERT ON public.post_likes
  FOR EACH ROW EXECUTE FUNCTION notify_on_like();

-- Notify on follow
CREATE OR REPLACE FUNCTION notify_on_follow()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  follower_username TEXT;
  follower_avatar TEXT;
BEGIN
  SELECT username, avatar_url INTO follower_username, follower_avatar
    FROM public.profiles WHERE id = NEW.follower_id;

  INSERT INTO public.notifications (user_id, actor_id, actor_username, actor_avatar, type)
  VALUES (NEW.following_id, NEW.follower_id, follower_username, follower_avatar, 'follow');
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_follow
  AFTER INSERT ON public.follows
  FOR EACH ROW EXECUTE FUNCTION notify_on_follow();

-- Notify on comment
CREATE OR REPLACE FUNCTION notify_on_comment()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  post_owner UUID;
  commenter_username TEXT;
  commenter_avatar TEXT;
BEGIN
  SELECT user_id INTO post_owner FROM public.posts WHERE id = NEW.post_id;
  SELECT username, avatar_url INTO commenter_username, commenter_avatar
    FROM public.profiles WHERE id = NEW.user_id;

  IF post_owner != NEW.user_id THEN
    INSERT INTO public.notifications
      (user_id, actor_id, actor_username, actor_avatar, type, post_id, comment_text)
    VALUES (post_owner, NEW.user_id, commenter_username, commenter_avatar,
            'comment', NEW.post_id, substring(NEW.text from 1 for 100));
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_comment
  AFTER INSERT ON public.comments
  FOR EACH ROW EXECUTE FUNCTION notify_on_comment();
```
