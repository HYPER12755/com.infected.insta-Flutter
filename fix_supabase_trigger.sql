-- ============================================================================
-- SQL to find and fix the "email_confirmed" trigger issue
-- Run this in your Supabase SQL Editor (Dashboard > SQL Editor)
-- ============================================================================

-- STEP 1: Find all triggers on auth.users table that might have the email_confirmed issue
SELECT 
    tgname AS trigger_name,
    proname AS function_name,
    pg_get_triggerdef(OID) AS trigger_definition
FROM pg_trigger
JOIN pg_proc ON pronoid = tgfoid
JOIN pg_class ON relname = 'users' AND relnamespace = 'auth'::regnamespace::oid
WHERE NOT tgname LIKE '%_pg_drop%';

-- STEP 2: Drop the broken triggers (run this if any triggers are found)
-- UNCOMMENT after reviewing the triggers above:
-- DROP TRIGGER IF EXISTS trigger_name ON auth.users;

-- STEP 3: Recreate handle_new_user trigger correctly (without email_confirmed)
-- This is the correct version that matches Supabase's auth.users schema
/*
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Handle email confirmation check (using correct field name)
  IF NEW.email_confirmed_at IS NOT NULL THEN
    -- User has confirmed their email
    INSERT INTO public.profiles (id, username, display_name, avatar_url)
    VALUES (
      NEW.id,
      COALESCE(NEW.raw_user_meta_data->>'username', NEW.email),
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'avatar_url'
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
*/

-- STEP 4: Check auth.users schema to verify correct field names
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_schema = 'auth' AND table_name = 'users'
ORDER BY ordinal_position;