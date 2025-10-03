

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgsodium";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "ltree" WITH SCHEMA "public";






CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pg_trgm" WITH SCHEMA "public";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."archive_old_notifications"() RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  DELETE FROM notifications
  WHERE created_at < NOW() - INTERVAL '30 days'
  AND is_read = true;
END;
$$;


ALTER FUNCTION "public"."archive_old_notifications"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."award_xp"("p_user_id" "uuid", "p_action" "text", "p_amount" integer DEFAULT NULL::integer) RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
DECLARE
  xp_amount INTEGER;
  new_total_xp INTEGER;
  new_level INTEGER;
BEGIN
  -- Get XP amount (use provided amount or calculate from action)
  xp_amount := COALESCE(p_amount,
    CASE p_action
      WHEN 'thread_created' THEN 10
      WHEN 'comment_created' THEN 5
      WHEN 'thread_upvoted' THEN 2
      WHEN 'comment_upvoted' THEN 1
      WHEN 'daily_visit' THEN 3
      WHEN 'report_confirmed' THEN 15
      WHEN 'moderation_action' THEN 20
      ELSE 0
    END
  );

  -- Update user XP and level
  UPDATE users
  SET
    xp = xp + xp_amount,
    level = calculate_user_level(xp + xp_amount),
    updated_at = NOW()
  WHERE id = p_user_id
  RETURNING xp, level INTO new_total_xp, new_level;

  -- Record transaction
  INSERT INTO xp_transactions (
    user_id,
    action,
    amount,
    balance,
    created_at
  ) VALUES (
    p_user_id,
    p_action,
    xp_amount,
    new_total_xp,
    NOW()
  );
END;
$$;


ALTER FUNCTION "public"."award_xp"("p_user_id" "uuid", "p_action" "text", "p_amount" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."calculate_category_path"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
DECLARE
  parent_path public.ltree;
BEGIN
  IF NEW.parent_id IS NULL THEN
    NEW.path = NEW.slug::public.ltree;
  ELSE
    SELECT path INTO parent_path FROM categories WHERE id = NEW.parent_id;
    NEW.path = parent_path || NEW.slug::public.ltree;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."calculate_category_path"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."calculate_comment_path"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
DECLARE
  parent_path public.ltree;
BEGIN
  IF NEW.parent_id IS NULL THEN
    NEW.path = NEW.id::text::public.ltree;
  ELSE
    SELECT path INTO parent_path FROM comments WHERE id = NEW.parent_id;
    NEW.path = parent_path || NEW.id::text::public.ltree;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."calculate_comment_path"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."calculate_hot_score"("upvotes" integer, "downvotes" integer, "created_at" timestamp with time zone) RETURNS numeric
    LANGUAGE "plpgsql" IMMUTABLE STRICT
    SET "search_path" TO ''
    AS $$
DECLARE
  score INTEGER;
  order_value NUMERIC;
  sign_value INTEGER;
  seconds_since_epoch NUMERIC;
BEGIN
  score := upvotes - downvotes;

  IF score > 0 THEN
    sign_value := 1;
  ELSIF score < 0 THEN
    sign_value := -1;
  ELSE
    sign_value := 0;
  END IF;

  order_value := GREATEST(ABS(score), 1);
  seconds_since_epoch := EXTRACT(EPOCH FROM created_at) - 1134028003;

  RETURN ROUND(sign_value * LOG(10, order_value) + seconds_since_epoch / 45000, 7);
END;
$$;


ALTER FUNCTION "public"."calculate_hot_score"("upvotes" integer, "downvotes" integer, "created_at" timestamp with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."calculate_user_level"("xp" integer) RETURNS integer
    LANGUAGE "plpgsql" IMMUTABLE STRICT
    SET "search_path" TO ''
    AS $$
BEGIN
  RETURN CASE
    WHEN xp < 100 THEN 1
    WHEN xp < 500 THEN 2
    WHEN xp < 1500 THEN 3
    WHEN xp < 5000 THEN 4
    ELSE 5
  END;
END;
$$;


ALTER FUNCTION "public"."calculate_user_level"("xp" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."calculate_wilson_score"("upvotes" integer, "downvotes" integer) RETURNS numeric
    LANGUAGE "plpgsql" IMMUTABLE STRICT
    SET "search_path" TO ''
    AS $$
DECLARE
  n NUMERIC;
  phat NUMERIC;
  z NUMERIC := 1.96; -- 95% confidence
  result NUMERIC;
BEGIN
  n := upvotes + downvotes;

  IF n = 0 THEN
    RETURN 0;
  END IF;

  phat := upvotes::NUMERIC / n;

  result := (phat + z*z/(2*n) - z * SQRT((phat*(1-phat) + z*z/(4*n))/n)) / (1 + z*z/n);

  RETURN ROUND(result, 4);
END;
$$;


ALTER FUNCTION "public"."calculate_wilson_score"("upvotes" integer, "downvotes" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_bot_criteria"("p_user_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
DECLARE
  criteria_met INTEGER := 0;
  post_frequency NUMERIC;
  short_post_ratio NUMERIC;
  report_count INTEGER;
BEGIN
  -- Check post frequency (more than 10 posts in an hour)
  SELECT COUNT(*) INTO post_frequency
  FROM threads
  WHERE user_id = p_user_id
  AND created_at > NOW() - INTERVAL '1 hour';

  IF post_frequency > 10 THEN
    criteria_met := criteria_met + 1;
  END IF;

  -- Check short post ratio (more than 70% posts under 40 chars)
  SELECT
    CASE
      WHEN COUNT(*) > 0 THEN
        SUM(CASE WHEN LENGTH(content) < 40 THEN 1 ELSE 0 END)::NUMERIC / COUNT(*)
      ELSE 0
    END INTO short_post_ratio
  FROM threads
  WHERE user_id = p_user_id;

  IF short_post_ratio > 0.7 THEN
    criteria_met := criteria_met + 1;
  END IF;

  -- Check bot reports
  SELECT COUNT(*) INTO report_count
  FROM bot_reports
  WHERE user_id = p_user_id
  AND confidence > 0.5;

  IF report_count > 2 THEN
    criteria_met := criteria_met + 1;
  END IF;

  -- Return true if 2 or more criteria met
  RETURN criteria_met >= 2;
END;
$$;


ALTER FUNCTION "public"."check_bot_criteria"("p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_report_rate_limit"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  recent_reports INT;
BEGIN
  -- Count reports by this user in the last hour
  SELECT COUNT(*) INTO recent_reports
  FROM content_reports
  WHERE reporter_id = NEW.reporter_id
    AND created_at > NOW() - INTERVAL '1 hour';

  -- Limit to 10 reports per hour
  IF recent_reports >= 10 THEN
    RAISE EXCEPTION 'Report rate limit exceeded. Maximum 10 reports per hour.';
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."check_report_rate_limit"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."cleanup_expired_sessions"() RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  DELETE FROM user_sessions WHERE expires_at < NOW();
  DELETE FROM temporary_bans WHERE expires_at < NOW() AND is_active = true;
  DELETE FROM user_warnings WHERE expires_at < NOW();
END;
$$;


ALTER FUNCTION "public"."cleanup_expired_sessions"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_user_profile"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  INSERT INTO users (
    id,
    email,
    username,
    display_name,
    created_at,
    updated_at
  ) VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)),
    NOW(),
    NOW()
  );

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."create_user_profile"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."create_user_profile"() IS 'Creates user profile in public.users table with secure defaults. Called automatically by trigger on auth.users INSERT. SECURITY DEFINER ensures it has permission to insert regardless of RLS policies.';



CREATE OR REPLACE FUNCTION "public"."evaluate_bot_status"("p_user_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
DECLARE
  avg_confidence NUMERIC;
  is_bot_detected BOOLEAN;
BEGIN
  -- Check if user meets bot criteria
  is_bot_detected := check_bot_criteria(p_user_id);

  -- Get average confidence from bot reports
  SELECT AVG(confidence) INTO avg_confidence
  FROM bot_reports
  WHERE user_id = p_user_id
  AND created_at > NOW() - INTERVAL '7 days';

  -- Update user if bot detected with high confidence
  IF is_bot_detected OR (avg_confidence IS NOT NULL AND avg_confidence > 0.7) THEN
    UPDATE users
    SET is_bot = TRUE,
        bot_probability = COALESCE(avg_confidence, 0.75),
        updated_at = NOW()
    WHERE id = p_user_id;
  END IF;
END;
$$;


ALTER FUNCTION "public"."evaluate_bot_status"("p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."generate_comment_path"("p_parent_id" "uuid") RETURNS "public"."ltree"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
DECLARE
  parent_path public.ltree;
  new_id TEXT;
BEGIN
  new_id := gen_random_uuid()::TEXT;

  IF p_parent_id IS NULL THEN
    RETURN new_id::public.ltree;
  ELSE
    SELECT path INTO parent_path FROM comments WHERE id = p_parent_id;
    RETURN parent_path || new_id::public.ltree;
  END IF;
END;
$$;


ALTER FUNCTION "public"."generate_comment_path"("p_parent_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_category_path"("p_category_id" "uuid") RETURNS "public"."ltree"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
DECLARE
  cat_path public.ltree;
BEGIN
  SELECT path INTO cat_path FROM categories WHERE id = p_category_id;
  RETURN cat_path;
END;
$$;


ALTER FUNCTION "public"."get_category_path"("p_category_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_category_subscriber_count"("category_id" "uuid") RETURNS integer
    LANGUAGE "plpgsql" STABLE
    AS $$
DECLARE
  count INTEGER;
BEGIN
  SELECT COUNT(*)::INTEGER
  INTO count
  FROM category_subscriptions
  WHERE category_subscriptions.category_id = get_category_subscriber_count.category_id;

  RETURN COALESCE(count, 0);
END;
$$;


ALTER FUNCTION "public"."get_category_subscriber_count"("category_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."get_category_subscriber_count"("category_id" "uuid") IS 'Returns the accurate subscriber count for a category';



CREATE OR REPLACE FUNCTION "public"."get_thread_stats"("p_thread_id" "uuid") RETURNS TABLE("comment_count" integer, "unique_commenters" integer, "total_votes" integer, "wilson_score" numeric)
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(c.id)::INTEGER AS comment_count,
    COUNT(DISTINCT c.user_id)::INTEGER AS unique_commenters,
    (t.upvotes + t.downvotes)::INTEGER AS total_votes,
    t.wilson_score
  FROM threads t
  LEFT JOIN comments c ON c.thread_id = t.id
  WHERE t.id = p_thread_id
  GROUP BY t.id, t.upvotes, t.downvotes, t.wilson_score;
END;
$$;


ALTER FUNCTION "public"."get_thread_stats"("p_thread_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_user_stats"("p_user_id" "uuid") RETURNS TABLE("thread_count" integer, "comment_count" integer, "total_upvotes" integer, "total_downvotes" integer)
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    (SELECT COUNT(*)::INTEGER FROM threads WHERE user_id = p_user_id) AS thread_count,
    (SELECT COUNT(*)::INTEGER FROM comments WHERE user_id = p_user_id) AS comment_count,
    (SELECT COALESCE(SUM(upvotes), 0)::INTEGER FROM threads WHERE user_id = p_user_id) AS total_upvotes,
    (SELECT COALESCE(SUM(downvotes), 0)::INTEGER FROM threads WHERE user_id = p_user_id) AS total_downvotes;
END;
$$;


ALTER FUNCTION "public"."get_user_stats"("p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_xp_for_action"("action_type" "text") RETURNS integer
    LANGUAGE "plpgsql" IMMUTABLE
    SET "search_path" TO ''
    AS $$
BEGIN
  RETURN CASE action_type
    WHEN 'thread_created' THEN 10
    WHEN 'comment_created' THEN 5
    WHEN 'thread_upvoted' THEN 2
    WHEN 'comment_upvoted' THEN 1
    WHEN 'daily_visit' THEN 3
    WHEN 'report_confirmed' THEN 15
    WHEN 'moderation_action' THEN 20
    ELSE 0
  END;
END;
$$;


ALTER FUNCTION "public"."get_xp_for_action"("action_type" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."increment_category_subscribers"("category_id" "uuid", "increment" integer) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  UPDATE categories
  SET subscriber_count = GREATEST(0, COALESCE(subscriber_count, 0) + increment)
  WHERE id = category_id;
END;
$$;


ALTER FUNCTION "public"."increment_category_subscribers"("category_id" "uuid", "increment" integer) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."increment_category_subscribers"("category_id" "uuid", "increment" integer) IS 'Safely increments or decrements the subscriber count for a category';



CREATE OR REPLACE FUNCTION "public"."prevent_duplicate_reports"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  -- Check if the same user already reported the same content
  IF EXISTS (
    SELECT 1 FROM content_reports
    WHERE reporter_id = NEW.reporter_id
      AND content_type = NEW.content_type
      AND content_id = NEW.content_id
      AND status = 'pending'
  ) THEN
    RAISE EXCEPTION 'You have already reported this content.';
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."prevent_duplicate_reports"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."recalculate_trust_scores"() RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  UPDATE users
  SET trust_score = GREATEST(0, LEAST(100,
    50 +
    (SELECT COUNT(*) FROM threads WHERE user_id = users.id AND NOT is_removed) * 2 +
    (SELECT COUNT(*) FROM comments WHERE user_id = users.id AND NOT is_removed) +
    (SELECT SUM(upvotes - downvotes) FROM threads WHERE user_id = users.id) / 10
  ))
  WHERE NOT is_bot;
END;
$$;


ALTER FUNCTION "public"."recalculate_trust_scores"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."search_threads"("search_query" "text", "p_category_id" "uuid" DEFAULT NULL::"uuid", "limit_count" integer DEFAULT 20) RETURNS TABLE("id" "uuid", "title" "text", "content" "text", "user_id" "uuid", "category_id" "uuid", "created_at" timestamp with time zone, "relevance" real)
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    t.id,
    t.title,
    t.content,
    t.user_id,
    t.category_id,
    t.created_at,
    ts_rank(t.search_vector, plainto_tsquery(search_query)) AS relevance
  FROM threads t
  WHERE
    t.search_vector @@ plainto_tsquery(search_query)
    AND (p_category_id IS NULL OR t.category_id = p_category_id)
    AND t.is_removed = FALSE
  ORDER BY relevance DESC, t.created_at DESC
  LIMIT limit_count;
END;
$$;


ALTER FUNCTION "public"."search_threads"("search_query" "text", "p_category_id" "uuid", "limit_count" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_comment_path"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
DECLARE
  parent_path public.ltree;
BEGIN
  IF NEW.parent_id IS NULL THEN
    NEW.path = NEW.id::text::public.ltree;
  ELSE
    SELECT path INTO parent_path FROM comments WHERE id = NEW.parent_id;
    IF parent_path IS NULL THEN
      RAISE EXCEPTION 'Parent comment not found';
    END IF;
    NEW.path = parent_path || NEW.id::text::public.ltree;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."set_comment_path"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_all_category_subscriber_counts"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  UPDATE categories c
  SET subscriber_count = (
    SELECT COUNT(*)
    FROM category_subscriptions cs
    WHERE cs.category_id = c.id
  );
END;
$$;


ALTER FUNCTION "public"."sync_all_category_subscriber_counts"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."sync_all_category_subscriber_counts"() IS 'Syncs all category subscriber counts with actual subscription data (maintenance)';



CREATE OR REPLACE FUNCTION "public"."track_post_length"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  IF TG_TABLE_NAME = 'threads' THEN
    NEW.content_length := LENGTH(NEW.content);
  ELSIF TG_TABLE_NAME = 'comments' THEN
    NEW.content_length := LENGTH(NEW.content);
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."track_post_length"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_bot_detection"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
DECLARE
  post_count INTEGER;
  time_span INTERVAL;
BEGIN
  -- Count posts in last hour
  SELECT COUNT(*) INTO post_count
  FROM threads
  WHERE user_id = NEW.user_id
  AND created_at > NOW() - INTERVAL '1 hour';

  -- Flag if suspicious
  IF post_count > 10 THEN
    INSERT INTO bot_reports (user_id, reason, confidence)
    VALUES (NEW.user_id, 'High posting frequency', 0.8);
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_bot_detection"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_bot_status"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  IF NEW.confidence > 0.8 AND NEW.status = 'pending' THEN
    UPDATE users
    SET
      is_bot = TRUE,
      bot_probability = NEW.confidence,
      updated_at = NOW()
    WHERE id = NEW.user_id;

    NEW.status = 'confirmed';
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_bot_status"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_category_post_count"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE categories
    SET post_count = post_count + 1,
        last_activity = NOW(),
        updated_at = NOW()
    WHERE id = NEW.category_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE categories
    SET post_count = post_count - 1,
        updated_at = NOW()
    WHERE id = OLD.category_id;
  END IF;

  RETURN NULL;
END;
$$;


ALTER FUNCTION "public"."update_category_post_count"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_category_subscriber_count"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE categories
    SET subscriber_count = COALESCE(subscriber_count, 0) + 1
    WHERE id = NEW.category_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE categories
    SET subscriber_count = GREATEST(0, COALESCE(subscriber_count, 0) - 1)
    WHERE id = OLD.category_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$;


ALTER FUNCTION "public"."update_category_subscriber_count"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_category_thread_count"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE categories
    SET thread_count = thread_count + 1
    WHERE id = NEW.category_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE categories
    SET thread_count = thread_count - 1
    WHERE id = OLD.category_id;
  END IF;

  RETURN NULL;
END;
$$;


ALTER FUNCTION "public"."update_category_thread_count"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_comment_vote_counts"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.vote_type = 1 THEN
      UPDATE comments SET upvotes = upvotes + 1 WHERE id = NEW.comment_id;
    ELSE
      UPDATE comments SET downvotes = downvotes + 1 WHERE id = NEW.comment_id;
    END IF;
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.vote_type = 1 AND NEW.vote_type = -1 THEN
      UPDATE comments SET upvotes = upvotes - 1, downvotes = downvotes + 1 WHERE id = NEW.comment_id;
    ELSIF OLD.vote_type = -1 AND NEW.vote_type = 1 THEN
      UPDATE comments SET downvotes = downvotes - 1, upvotes = upvotes + 1 WHERE id = NEW.comment_id;
    END IF;
  ELSIF TG_OP = 'DELETE' THEN
    IF OLD.vote_type = 1 THEN
      UPDATE comments SET upvotes = upvotes - 1 WHERE id = OLD.comment_id;
    ELSE
      UPDATE comments SET downvotes = downvotes - 1 WHERE id = OLD.comment_id;
    END IF;
  END IF;

  RETURN NULL;
END;
$$;


ALTER FUNCTION "public"."update_comment_vote_counts"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_comment_wilson_score"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  NEW.wilson_score := calculate_wilson_score(NEW.upvotes, NEW.downvotes);
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_comment_wilson_score"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_hot_threads"() RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  UPDATE threads
  SET hot_score = calculate_hot_score(upvotes, downvotes, created_at),
      is_hot = (calculate_hot_score(upvotes, downvotes, created_at) > 5)
  WHERE created_at > NOW() - INTERVAL '7 days'
  AND is_removed = false;
END;
$$;


ALTER FUNCTION "public"."update_hot_threads"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_subscriber_count"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE categories
    SET subscriber_count = subscriber_count + 1
    WHERE id = NEW.category_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE categories
    SET subscriber_count = subscriber_count - 1
    WHERE id = OLD.category_id;
  END IF;

  RETURN NULL;
END;
$$;


ALTER FUNCTION "public"."update_subscriber_count"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_thread_activity"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  UPDATE threads
  SET
    last_activity = NOW(),
    updated_at = NOW()
  WHERE id = NEW.thread_id;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_thread_activity"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_thread_comment_count"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE threads
    SET comment_count = comment_count + 1,
        last_activity = NOW()
    WHERE id = NEW.thread_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE threads
    SET comment_count = comment_count - 1
    WHERE id = OLD.thread_id;
  END IF;

  RETURN NULL;
END;
$$;


ALTER FUNCTION "public"."update_thread_comment_count"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_thread_hot_score"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  UPDATE threads
  SET
    hot_score = calculate_hot_score(NEW.upvotes, NEW.downvotes, NEW.created_at),
    updated_at = NOW()
  WHERE id = NEW.id;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_thread_hot_score"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_thread_vote_counts"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.vote_type = 1 THEN
      UPDATE threads SET upvotes = upvotes + 1 WHERE id = NEW.thread_id;
    ELSE
      UPDATE threads SET downvotes = downvotes + 1 WHERE id = NEW.thread_id;
    END IF;
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.vote_type = 1 AND NEW.vote_type = -1 THEN
      UPDATE threads SET upvotes = upvotes - 1, downvotes = downvotes + 1 WHERE id = NEW.thread_id;
    ELSIF OLD.vote_type = -1 AND NEW.vote_type = 1 THEN
      UPDATE threads SET downvotes = downvotes - 1, upvotes = upvotes + 1 WHERE id = NEW.thread_id;
    END IF;
  ELSIF TG_OP = 'DELETE' THEN
    IF OLD.vote_type = 1 THEN
      UPDATE threads SET upvotes = upvotes - 1 WHERE id = OLD.thread_id;
    ELSE
      UPDATE threads SET downvotes = downvotes - 1 WHERE id = OLD.thread_id;
    END IF;
  END IF;

  RETURN NULL;
END;
$$;


ALTER FUNCTION "public"."update_thread_vote_counts"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_user_activity"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
  INSERT INTO user_activity (
    user_id,
    action_type,
    metadata,
    created_at
  ) VALUES (
    NEW.user_id,
    TG_ARGV[0],
    jsonb_build_object(
      'table', TG_TABLE_NAME,
      'id', NEW.id
    ),
    NOW()
  );

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_user_activity"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."badges" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text" NOT NULL,
    "icon_url" "text",
    "type" "text",
    "tier" "text",
    "requirements" "jsonb" NOT NULL,
    "points_value" integer DEFAULT 0,
    "xp_reward" integer DEFAULT 0,
    "is_active" boolean DEFAULT true,
    "is_secret" boolean DEFAULT false,
    "created_at" timestamp without time zone DEFAULT "now"(),
    CONSTRAINT "badges_tier_check" CHECK (("tier" = ANY (ARRAY['bronze'::"text", 'silver'::"text", 'gold'::"text", 'platinum'::"text"]))),
    CONSTRAINT "badges_type_check" CHECK (("type" = ANY (ARRAY['activity'::"text", 'special'::"text", 'monthly'::"text", 'achievement'::"text"])))
);


ALTER TABLE "public"."badges" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."bot_detection" (
    "user_id" "uuid" NOT NULL,
    "short_post_count" integer DEFAULT 0,
    "total_post_count" integer DEFAULT 0,
    "short_post_percentage" numeric(5,2) GENERATED ALWAYS AS (
CASE
    WHEN ("total_post_count" > 0) THEN ((("short_post_count")::numeric / ("total_post_count")::numeric) * (100)::numeric)
    ELSE (0)::numeric
END) STORED,
    "bot_reports_count" integer DEFAULT 0,
    "moderator_reports_count" integer DEFAULT 0,
    "posting_frequency" numeric(5,2) DEFAULT 0,
    "duplicate_content_ratio" numeric(5,2) DEFAULT 0,
    "bot_score" numeric(5,2) DEFAULT 0,
    "is_bot" boolean DEFAULT false,
    "last_evaluated" timestamp without time zone DEFAULT "now"(),
    "flagged_at" timestamp without time zone,
    "banned_at" timestamp without time zone,
    "strikes" integer DEFAULT 0,
    "failed_captcha_count" integer DEFAULT 0,
    CONSTRAINT "bot_detection_strikes_check" CHECK ((("strikes" >= 0) AND ("strikes" <= 3))),
    CONSTRAINT "check_bot_score_range" CHECK ((("bot_score" >= (0)::numeric) AND ("bot_score" <= (100)::numeric)))
);


ALTER TABLE "public"."bot_detection" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."bot_reports" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "reported_user_id" "uuid",
    "reporter_id" "uuid",
    "reason" "text" NOT NULL,
    "evidence" "jsonb",
    "status" "text" DEFAULT 'pending'::"text",
    "created_at" timestamp without time zone DEFAULT "now"(),
    "reviewed_at" timestamp without time zone,
    "reviewed_by" "uuid",
    CONSTRAINT "bot_reports_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'reviewed'::"text", 'confirmed'::"text", 'dismissed'::"text"])))
);


ALTER TABLE "public"."bot_reports" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."categories" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "parent_id" "uuid",
    "name" "text" NOT NULL,
    "slug" "text" NOT NULL,
    "description" "text",
    "icon_url" "text",
    "color" "text" DEFAULT '#6366f1'::"text",
    "post_count" integer DEFAULT 0,
    "subscriber_count" integer DEFAULT 0,
    "is_active" boolean DEFAULT true,
    "is_default" boolean DEFAULT false,
    "created_at" timestamp without time zone DEFAULT "now"(),
    "updated_at" timestamp without time zone DEFAULT "now"(),
    "path" "public"."ltree",
    "depth" integer DEFAULT 0,
    "is_locked" boolean DEFAULT false,
    "min_level_to_post" integer DEFAULT 2,
    "min_level_to_comment" integer DEFAULT 2
);


ALTER TABLE "public"."categories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."category_digests" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "category_id" "uuid",
    "digest_date" "date" NOT NULL,
    "top_threads" "jsonb" NOT NULL,
    "total_posts" integer DEFAULT 0,
    "total_comments" integer DEFAULT 0,
    "active_users" integer DEFAULT 0,
    "trending_topics" "jsonb",
    "generated_at" timestamp without time zone DEFAULT "now"()
);


ALTER TABLE "public"."category_digests" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."category_rules" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "category_id" "uuid",
    "rule_number" integer NOT NULL,
    "title" "text" NOT NULL,
    "description" "text" NOT NULL,
    "created_at" timestamp without time zone DEFAULT "now"()
);


ALTER TABLE "public"."category_rules" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."category_subscriptions" (
    "user_id" "uuid" NOT NULL,
    "category_id" "uuid" NOT NULL,
    "notification_enabled" boolean DEFAULT true,
    "subscribed_at" timestamp without time zone DEFAULT "now"()
);


ALTER TABLE "public"."category_subscriptions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."comment_votes" (
    "user_id" "uuid" NOT NULL,
    "comment_id" "uuid" NOT NULL,
    "vote_type" "text" NOT NULL,
    "voted_at" timestamp without time zone DEFAULT "now"(),
    CONSTRAINT "comment_votes_vote_type_check" CHECK (("vote_type" = ANY (ARRAY['upvote'::"text", 'downvote'::"text"])))
);


ALTER TABLE "public"."comment_votes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."comments" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "thread_id" "uuid",
    "user_id" "uuid",
    "parent_id" "uuid",
    "content" "text" NOT NULL,
    "content_html" "text",
    "path" "public"."ltree" NOT NULL,
    "depth" integer DEFAULT 0,
    "upvotes" integer DEFAULT 0,
    "downvotes" integer DEFAULT 0,
    "is_removed" boolean DEFAULT false,
    "removal_reason" "text",
    "edited_at" timestamp without time zone,
    "created_at" timestamp without time zone DEFAULT "now"(),
    "updated_at" timestamp without time zone DEFAULT "now"(),
    "edit_count" integer DEFAULT 0,
    "removed_by" "uuid",
    "removed_at" timestamp without time zone,
    "wilson_score" numeric GENERATED ALWAYS AS ("public"."calculate_wilson_score"("upvotes", "downvotes")) STORED,
    CONSTRAINT "check_content_length" CHECK ((("length"("content") >= 1) AND ("length"("content") <= 5000))),
    CONSTRAINT "check_depth_limit" CHECK ((("depth" >= 0) AND ("depth" <= 10))),
    CONSTRAINT "check_downvotes_positive" CHECK (("downvotes" >= 0)),
    CONSTRAINT "check_upvotes_positive" CHECK (("upvotes" >= 0))
);


ALTER TABLE "public"."comments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."content_reports" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "reporter_id" "uuid",
    "content_type" "text",
    "content_id" "uuid" NOT NULL,
    "report_type" "text",
    "reason" "text",
    "status" "text" DEFAULT 'pending'::"text",
    "moderator_id" "uuid",
    "moderator_notes" "text",
    "created_at" timestamp without time zone DEFAULT "now"(),
    "resolved_at" timestamp without time zone,
    CONSTRAINT "content_reports_content_type_check" CHECK (("content_type" = ANY (ARRAY['thread'::"text", 'comment'::"text"]))),
    CONSTRAINT "content_reports_report_type_check" CHECK (("report_type" = ANY (ARRAY['spam'::"text", 'harassment'::"text", 'hate_speech'::"text", 'misinformation'::"text", 'low_effort'::"text", 'off_topic'::"text", 'other'::"text"]))),
    CONSTRAINT "content_reports_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'reviewing'::"text", 'resolved'::"text", 'dismissed'::"text"])))
);


ALTER TABLE "public"."content_reports" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."election_votes" (
    "election_id" "uuid" NOT NULL,
    "voter_id" "uuid" NOT NULL,
    "vote" "text",
    "voted_at" timestamp without time zone DEFAULT "now"(),
    CONSTRAINT "election_votes_vote_check" CHECK (("vote" = ANY (ARRAY['for'::"text", 'against'::"text"])))
);


ALTER TABLE "public"."election_votes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."moderation_logs" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "moderator_id" "uuid",
    "target_user_id" "uuid",
    "target_content_id" "uuid",
    "content_type" "text",
    "action" "text",
    "reason" "text",
    "metadata" "jsonb",
    "created_at" timestamp without time zone DEFAULT "now"(),
    CONSTRAINT "moderation_logs_action_check" CHECK (("action" = ANY (ARRAY['remove_post'::"text", 'lock_thread'::"text", 'pin_thread'::"text", 'unpin_thread'::"text", 'warn_user'::"text", 'ban_user'::"text", 'unban_user'::"text", 'shadowban_user'::"text"]))),
    CONSTRAINT "moderation_logs_content_type_check" CHECK (("content_type" = ANY (ARRAY['thread'::"text", 'comment'::"text", 'user'::"text"])))
);


ALTER TABLE "public"."moderation_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."moderator_bot_reports" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "reported_user_id" "uuid",
    "moderator_id" "uuid",
    "category_context" "text",
    "reason" "text" NOT NULL,
    "evidence" "jsonb",
    "created_at" timestamp without time zone DEFAULT "now"()
);


ALTER TABLE "public"."moderator_bot_reports" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."moderator_elections" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "category_id" "uuid",
    "election_type" "text",
    "target_user_id" "uuid",
    "initiated_by" "uuid",
    "votes_for" integer DEFAULT 0,
    "votes_against" integer DEFAULT 0,
    "eligible_voter_count" integer DEFAULT 0,
    "status" "text",
    "winner_id" "uuid",
    "started_at" timestamp without time zone DEFAULT "now"(),
    "ends_at" timestamp without time zone NOT NULL,
    "completed_at" timestamp without time zone,
    CONSTRAINT "moderator_elections_election_type_check" CHECK (("election_type" = ANY (ARRAY['new'::"text", 'removal'::"text"]))),
    CONSTRAINT "moderator_elections_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'completed'::"text", 'cancelled'::"text"])))
);


ALTER TABLE "public"."moderator_elections" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."moderators" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "user_id" "uuid",
    "category_id" "uuid",
    "elected_at" timestamp without time zone DEFAULT "now"(),
    "votes_received" integer NOT NULL,
    "term_starts_at" timestamp without time zone DEFAULT "now"(),
    "term_ends_at" timestamp without time zone,
    "is_active" boolean DEFAULT true,
    "removal_reason" "text",
    "actions_count" integer DEFAULT 0,
    "warnings_issued" integer DEFAULT 0
);


ALTER TABLE "public"."moderators" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."notification_preferences" (
    "user_id" "uuid" NOT NULL,
    "email_enabled" boolean DEFAULT true,
    "push_enabled" boolean DEFAULT false,
    "replies" boolean DEFAULT true,
    "mentions" boolean DEFAULT true,
    "upvotes" boolean DEFAULT false,
    "badges" boolean DEFAULT true,
    "moderator_actions" boolean DEFAULT true,
    "elections" boolean DEFAULT true,
    "digests" boolean DEFAULT true,
    "updated_at" timestamp without time zone DEFAULT "now"()
);


ALTER TABLE "public"."notification_preferences" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."notifications" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "user_id" "uuid",
    "type" "text",
    "title" "text" NOT NULL,
    "content" "text" NOT NULL,
    "link" "text",
    "is_read" boolean DEFAULT false,
    "read_at" timestamp without time zone,
    "created_at" timestamp without time zone DEFAULT "now"(),
    CONSTRAINT "notifications_type_check" CHECK (("type" = ANY (ARRAY['reply'::"text", 'mention'::"text", 'upvote'::"text", 'badge_earned'::"text", 'moderator_action'::"text", 'election_started'::"text", 'warning_received'::"text"])))
);


ALTER TABLE "public"."notifications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."schema_migrations" (
    "version" integer NOT NULL,
    "description" "text",
    "applied_at" timestamp without time zone DEFAULT "now"()
);


ALTER TABLE "public"."schema_migrations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."session_votes" (
    "session_id" "uuid" NOT NULL,
    "voter_id" "uuid" NOT NULL,
    "entry_id" "uuid",
    "voted_at" timestamp without time zone DEFAULT "now"()
);


ALTER TABLE "public"."session_votes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."spam_logs" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "user_id" "uuid",
    "content_type" "text",
    "content_id" "uuid" NOT NULL,
    "spam_score" numeric(5,2) NOT NULL,
    "patterns_matched" "jsonb",
    "action_taken" "text",
    "created_at" timestamp without time zone DEFAULT "now"(),
    CONSTRAINT "spam_logs_action_taken_check" CHECK (("action_taken" = ANY (ARRAY['allow'::"text", 'flag'::"text", 'queue_review'::"text", 'block'::"text"]))),
    CONSTRAINT "spam_logs_content_type_check" CHECK (("content_type" = ANY (ARRAY['thread'::"text", 'comment'::"text"])))
);


ALTER TABLE "public"."spam_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."spam_patterns" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "pattern_name" "text" NOT NULL,
    "pattern_type" "text",
    "pattern_regex" "text",
    "weight" numeric(3,2) DEFAULT 1.0,
    "match_count" integer DEFAULT 0,
    "is_active" boolean DEFAULT true,
    "created_at" timestamp without time zone DEFAULT "now"(),
    CONSTRAINT "spam_patterns_pattern_type_check" CHECK (("pattern_type" = ANY (ARRAY['content'::"text", 'behavior'::"text", 'timing'::"text"])))
);


ALTER TABLE "public"."spam_patterns" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."thread_summaries" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "thread_id" "uuid",
    "category_id" "uuid",
    "summary_text" "text" NOT NULL,
    "key_points" "jsonb",
    "sentiment_score" numeric(3,2),
    "engagement_score" numeric(5,2),
    "generated_at" timestamp without time zone DEFAULT "now"(),
    "summary_date" "date" DEFAULT CURRENT_DATE
);


ALTER TABLE "public"."thread_summaries" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."thread_votes" (
    "user_id" "uuid" NOT NULL,
    "thread_id" "uuid" NOT NULL,
    "vote_type" "text" NOT NULL,
    "voted_at" timestamp without time zone DEFAULT "now"(),
    CONSTRAINT "thread_votes_vote_type_check" CHECK (("vote_type" = ANY (ARRAY['upvote'::"text", 'downvote'::"text"])))
);


ALTER TABLE "public"."thread_votes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."threads" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "user_id" "uuid",
    "category_id" "uuid" NOT NULL,
    "title" "text" NOT NULL,
    "content" "text" NOT NULL,
    "content_html" "text",
    "upvotes" integer DEFAULT 0,
    "downvotes" integer DEFAULT 0,
    "comment_count" integer DEFAULT 0,
    "view_count" integer DEFAULT 0,
    "hot_score" numeric(10,4) DEFAULT 0,
    "is_hot" boolean DEFAULT false,
    "is_pinned" boolean DEFAULT false,
    "is_locked" boolean DEFAULT false,
    "is_removed" boolean DEFAULT false,
    "removal_reason" "text",
    "spam_score" numeric(5,2) DEFAULT 0,
    "is_spam" boolean DEFAULT false,
    "edited_at" timestamp without time zone,
    "created_at" timestamp without time zone DEFAULT "now"(),
    "updated_at" timestamp without time zone DEFAULT "now"(),
    "edit_count" integer DEFAULT 0,
    "last_activity_at" timestamp without time zone DEFAULT "now"(),
    "removed_by" "uuid",
    "removed_at" timestamp without time zone,
    "wilson_score" numeric GENERATED ALWAYS AS ("public"."calculate_wilson_score"("upvotes", "downvotes")) STORED,
    CONSTRAINT "check_comment_count_positive" CHECK (("comment_count" >= 0)),
    CONSTRAINT "check_content_length" CHECK (("length"("content") >= 40)),
    CONSTRAINT "check_downvotes_positive" CHECK (("downvotes" >= 0)),
    CONSTRAINT "check_spam_score_range" CHECK ((("spam_score" >= (0)::numeric) AND ("spam_score" <= (100)::numeric))),
    CONSTRAINT "check_title_length" CHECK ((("length"("title") >= 5) AND ("length"("title") <= 200))),
    CONSTRAINT "check_upvotes_positive" CHECK (("upvotes" >= 0)),
    CONSTRAINT "check_view_count_positive" CHECK (("view_count" >= 0))
);


ALTER TABLE "public"."threads" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."trust_factors" (
    "user_id" "uuid" NOT NULL,
    "verified_email" boolean DEFAULT false,
    "verified_phone" boolean DEFAULT false,
    "positive_interactions" integer DEFAULT 0,
    "negative_interactions" integer DEFAULT 0,
    "moderator_warnings" integer DEFAULT 0,
    "successful_reports" integer DEFAULT 0,
    "false_reports" integer DEFAULT 0,
    "updated_at" timestamp without time zone DEFAULT "now"()
);


ALTER TABLE "public"."trust_factors" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."users" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "username" "text" NOT NULL,
    "email" "text" NOT NULL,
    "password_hash" "text",
    "avatar_url" "text",
    "bio" "text",
    "level" integer DEFAULT 1,
    "xp" integer DEFAULT 0,
    "trust_score" numeric(5,2) DEFAULT 50.00,
    "post_count" integer DEFAULT 0,
    "comment_count" integer DEFAULT 0,
    "helpful_votes" integer DEFAULT 0,
    "account_status" "text" DEFAULT 'active'::"text",
    "last_active" timestamp without time zone DEFAULT "now"(),
    "created_at" timestamp without time zone DEFAULT "now"(),
    "updated_at" timestamp without time zone DEFAULT "now"(),
    "ban_expires_at" timestamp without time zone,
    "ban_reason" "text",
    CONSTRAINT "check_level_range" CHECK ((("level" >= 1) AND ("level" <= 5))),
    CONSTRAINT "check_trust_score_range" CHECK ((("trust_score" >= (0)::numeric) AND ("trust_score" <= (100)::numeric))),
    CONSTRAINT "check_xp_positive" CHECK (("xp" >= 0)),
    CONSTRAINT "users_account_status_check" CHECK (("account_status" = ANY (ARRAY['active'::"text", 'restricted'::"text", 'shadowbanned'::"text", 'banned'::"text"])))
);


ALTER TABLE "public"."users" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."trust_factors_with_age" AS
 SELECT "tf"."user_id",
    "tf"."verified_email",
    "tf"."verified_phone",
    "tf"."positive_interactions",
    "tf"."negative_interactions",
    "tf"."moderator_warnings",
    "tf"."successful_reports",
    "tf"."false_reports",
    "tf"."updated_at",
    (EXTRACT(day FROM ("now"() - ("u"."created_at")::timestamp with time zone)))::integer AS "account_age_days"
   FROM ("public"."trust_factors" "tf"
     JOIN "public"."users" "u" ON (("tf"."user_id" = "u"."id")));


ALTER TABLE "public"."trust_factors_with_age" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_activity" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "user_id" "uuid",
    "activity_type" "text",
    "metadata" "jsonb",
    "ip_address" "inet",
    "user_agent" "text",
    "created_at" timestamp without time zone DEFAULT "now"(),
    CONSTRAINT "user_activity_activity_type_check" CHECK (("activity_type" = ANY (ARRAY['login'::"text", 'logout'::"text", 'post_created'::"text", 'comment_created'::"text", 'vote_cast'::"text", 'report_submitted'::"text", 'badge_earned'::"text"])))
);


ALTER TABLE "public"."user_activity" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_badges" (
    "user_id" "uuid" NOT NULL,
    "badge_id" "uuid" NOT NULL,
    "awarded_at" timestamp without time zone DEFAULT "now"(),
    "awarded_for" "text"
);


ALTER TABLE "public"."user_badges" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_sessions" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "user_id" "uuid",
    "token" "text" NOT NULL,
    "ip_address" "inet",
    "user_agent" "text",
    "expires_at" timestamp without time zone NOT NULL,
    "created_at" timestamp without time zone DEFAULT "now"()
);


ALTER TABLE "public"."user_sessions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_warnings" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "user_id" "uuid",
    "moderator_id" "uuid",
    "category_id" "uuid",
    "reason" "text" NOT NULL,
    "severity" "text",
    "expires_at" timestamp without time zone,
    "created_at" timestamp without time zone DEFAULT "now"(),
    CONSTRAINT "user_warnings_severity_check" CHECK (("severity" = ANY (ARRAY['minor'::"text", 'moderate'::"text", 'severe'::"text"])))
);


ALTER TABLE "public"."user_warnings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."voting_entries" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "session_id" "uuid",
    "nominee_id" "uuid",
    "nomination_reason" "text",
    "votes_received" integer DEFAULT 0,
    "created_at" timestamp without time zone DEFAULT "now"()
);


ALTER TABLE "public"."voting_entries" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."voting_sessions" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "month" "date" NOT NULL,
    "title" "text" NOT NULL,
    "description" "text",
    "participation_badge_id" "uuid",
    "winner_badge_id" "uuid",
    "status" "text",
    "total_votes" integer DEFAULT 0,
    "winner_id" "uuid",
    "starts_at" timestamp without time zone,
    "ends_at" timestamp without time zone,
    "created_at" timestamp without time zone DEFAULT "now"(),
    CONSTRAINT "voting_sessions_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'active'::"text", 'completed'::"text"])))
);


ALTER TABLE "public"."voting_sessions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."xp_transactions" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "user_id" "uuid",
    "amount" integer NOT NULL,
    "reason" "text" NOT NULL,
    "source_type" "text",
    "source_id" "uuid",
    "created_at" timestamp without time zone DEFAULT "now"(),
    CONSTRAINT "xp_transactions_source_type_check" CHECK (("source_type" = ANY (ARRAY['post_created'::"text", 'comment_created'::"text", 'received_upvote'::"text", 'badge_earned'::"text", 'daily_login'::"text", 'moderation_action'::"text"])))
);


ALTER TABLE "public"."xp_transactions" OWNER TO "postgres";


ALTER TABLE ONLY "public"."badges"
    ADD CONSTRAINT "badges_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."badges"
    ADD CONSTRAINT "badges_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."bot_detection"
    ADD CONSTRAINT "bot_detection_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."bot_reports"
    ADD CONSTRAINT "bot_reports_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."bot_reports"
    ADD CONSTRAINT "bot_reports_reported_user_id_reporter_id_key" UNIQUE ("reported_user_id", "reporter_id");



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_parent_id_slug_key" UNIQUE ("parent_id", "slug");



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_slug_unique" UNIQUE ("slug");



ALTER TABLE ONLY "public"."category_digests"
    ADD CONSTRAINT "category_digests_category_id_digest_date_key" UNIQUE ("category_id", "digest_date");



ALTER TABLE ONLY "public"."category_digests"
    ADD CONSTRAINT "category_digests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."category_rules"
    ADD CONSTRAINT "category_rules_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."category_subscriptions"
    ADD CONSTRAINT "category_subscriptions_pkey" PRIMARY KEY ("user_id", "category_id");



ALTER TABLE ONLY "public"."comment_votes"
    ADD CONSTRAINT "comment_votes_pkey" PRIMARY KEY ("user_id", "comment_id");



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."content_reports"
    ADD CONSTRAINT "content_reports_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."election_votes"
    ADD CONSTRAINT "election_votes_pkey" PRIMARY KEY ("election_id", "voter_id");



ALTER TABLE ONLY "public"."moderation_logs"
    ADD CONSTRAINT "moderation_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."moderator_bot_reports"
    ADD CONSTRAINT "moderator_bot_reports_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."moderator_bot_reports"
    ADD CONSTRAINT "moderator_bot_reports_reported_user_id_moderator_id_key" UNIQUE ("reported_user_id", "moderator_id");



ALTER TABLE ONLY "public"."moderator_elections"
    ADD CONSTRAINT "moderator_elections_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."moderators"
    ADD CONSTRAINT "moderators_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notification_preferences"
    ADD CONSTRAINT "notification_preferences_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."schema_migrations"
    ADD CONSTRAINT "schema_migrations_pkey" PRIMARY KEY ("version");



ALTER TABLE ONLY "public"."session_votes"
    ADD CONSTRAINT "session_votes_pkey" PRIMARY KEY ("session_id", "voter_id");



ALTER TABLE ONLY "public"."spam_logs"
    ADD CONSTRAINT "spam_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."spam_patterns"
    ADD CONSTRAINT "spam_patterns_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."thread_summaries"
    ADD CONSTRAINT "thread_summaries_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."thread_votes"
    ADD CONSTRAINT "thread_votes_pkey" PRIMARY KEY ("user_id", "thread_id");



ALTER TABLE ONLY "public"."threads"
    ADD CONSTRAINT "threads_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."trust_factors"
    ADD CONSTRAINT "trust_factors_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."bot_reports"
    ADD CONSTRAINT "unique_reporter_per_user" UNIQUE ("reported_user_id", "reporter_id");



ALTER TABLE ONLY "public"."category_rules"
    ADD CONSTRAINT "unique_rule_number" UNIQUE ("category_id", "rule_number");



ALTER TABLE ONLY "public"."moderators"
    ADD CONSTRAINT "unique_user_category" UNIQUE ("user_id", "category_id");



ALTER TABLE ONLY "public"."user_activity"
    ADD CONSTRAINT "user_activity_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_badges"
    ADD CONSTRAINT "user_badges_pkey" PRIMARY KEY ("user_id", "badge_id");



ALTER TABLE ONLY "public"."user_sessions"
    ADD CONSTRAINT "user_sessions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_sessions"
    ADD CONSTRAINT "user_sessions_token_key" UNIQUE ("token");



ALTER TABLE ONLY "public"."user_warnings"
    ADD CONSTRAINT "user_warnings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_username_key" UNIQUE ("username");



ALTER TABLE ONLY "public"."voting_entries"
    ADD CONSTRAINT "voting_entries_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."voting_sessions"
    ADD CONSTRAINT "voting_sessions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."xp_transactions"
    ADD CONSTRAINT "xp_transactions_pkey" PRIMARY KEY ("id");



CREATE INDEX "idx_bot_detection_score" ON "public"."bot_detection" USING "btree" ("bot_score");



CREATE INDEX "idx_bot_detection_strikes" ON "public"."bot_detection" USING "btree" ("strikes") WHERE ("strikes" >= 2);



CREATE INDEX "idx_bot_reports_reported_user" ON "public"."bot_reports" USING "btree" ("reported_user_id") WHERE ("status" = 'pending'::"text");



CREATE INDEX "idx_categories_active" ON "public"."categories" USING "btree" ("is_active") WHERE ("is_active" = true);



CREATE INDEX "idx_categories_is_active" ON "public"."categories" USING "btree" ("is_active");



CREATE INDEX "idx_categories_parent" ON "public"."categories" USING "btree" ("parent_id");



CREATE INDEX "idx_categories_parent_id" ON "public"."categories" USING "btree" ("parent_id");



CREATE INDEX "idx_categories_path_gist" ON "public"."categories" USING "gist" ("path");



CREATE INDEX "idx_categories_slug" ON "public"."categories" USING "btree" ("slug");



CREATE INDEX "idx_category_digests_category_date" ON "public"."category_digests" USING "btree" ("category_id", "digest_date" DESC);



CREATE INDEX "idx_comment_votes_comment" ON "public"."comment_votes" USING "btree" ("comment_id");



CREATE INDEX "idx_comments_path_gist" ON "public"."comments" USING "gist" ("path");



CREATE INDEX "idx_comments_thread" ON "public"."comments" USING "btree" ("thread_id");



CREATE INDEX "idx_comments_thread_created" ON "public"."comments" USING "btree" ("thread_id", "created_at");



CREATE INDEX "idx_comments_thread_wilson" ON "public"."comments" USING "btree" ("thread_id", "wilson_score" DESC);



CREATE INDEX "idx_comments_wilson_score" ON "public"."comments" USING "btree" ("wilson_score" DESC);



CREATE INDEX "idx_content_reports_content" ON "public"."content_reports" USING "btree" ("content_type", "content_id");



CREATE INDEX "idx_content_reports_moderation" ON "public"."content_reports" USING "btree" ("status", "created_at" DESC);



CREATE INDEX "idx_content_reports_reporter" ON "public"."content_reports" USING "btree" ("reporter_id");



CREATE INDEX "idx_content_reports_status" ON "public"."content_reports" USING "btree" ("status");



CREATE INDEX "idx_moderation_logs_moderator" ON "public"."moderation_logs" USING "btree" ("moderator_id");



CREATE INDEX "idx_moderation_logs_target_user" ON "public"."moderation_logs" USING "btree" ("target_user_id");



CREATE INDEX "idx_moderators_category" ON "public"."moderators" USING "btree" ("category_id");



CREATE INDEX "idx_moderators_user" ON "public"."moderators" USING "btree" ("user_id");



CREATE INDEX "idx_notifications_user_unread" ON "public"."notifications" USING "btree" ("user_id", "is_read") WHERE ("is_read" = false);



CREATE INDEX "idx_session_votes_session" ON "public"."session_votes" USING "btree" ("session_id");



CREATE INDEX "idx_thread_summaries_thread" ON "public"."thread_summaries" USING "btree" ("thread_id");



CREATE INDEX "idx_thread_votes_thread" ON "public"."thread_votes" USING "btree" ("thread_id");



CREATE INDEX "idx_threads_category" ON "public"."threads" USING "btree" ("category_id");



CREATE INDEX "idx_threads_category_created" ON "public"."threads" USING "btree" ("category_id", "created_at" DESC) WHERE ("is_removed" = false);



CREATE INDEX "idx_threads_category_id" ON "public"."threads" USING "btree" ("category_id");



CREATE INDEX "idx_threads_category_wilson" ON "public"."threads" USING "btree" ("category_id", "wilson_score" DESC);



CREATE INDEX "idx_threads_hot" ON "public"."threads" USING "btree" ("is_hot", "hot_score" DESC);



CREATE INDEX "idx_threads_user" ON "public"."threads" USING "btree" ("user_id");



CREATE INDEX "idx_threads_wilson_score" ON "public"."threads" USING "btree" ("wilson_score" DESC);



CREATE INDEX "idx_user_activity_created" ON "public"."user_activity" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_user_activity_user" ON "public"."user_activity" USING "btree" ("user_id");



CREATE INDEX "idx_user_badges_badge" ON "public"."user_badges" USING "btree" ("badge_id");



CREATE INDEX "idx_user_badges_user" ON "public"."user_badges" USING "btree" ("user_id");



CREATE INDEX "idx_users_created_at" ON "public"."users" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_users_email" ON "public"."users" USING "btree" ("email");



CREATE INDEX "idx_users_email_lower" ON "public"."users" USING "btree" ("lower"("email"));



CREATE INDEX "idx_users_level" ON "public"."users" USING "btree" ("level");



CREATE INDEX "idx_users_trust_score" ON "public"."users" USING "btree" ("trust_score" DESC) WHERE ("account_status" = 'active'::"text");



CREATE INDEX "idx_users_username" ON "public"."users" USING "btree" ("username");



CREATE INDEX "idx_users_username_lower" ON "public"."users" USING "btree" ("lower"("username"));



CREATE INDEX "idx_voting_entries_session" ON "public"."voting_entries" USING "btree" ("session_id");



CREATE INDEX "idx_voting_sessions_status" ON "public"."voting_sessions" USING "btree" ("status");



CREATE OR REPLACE TRIGGER "enforce_report_rate_limit" BEFORE INSERT ON "public"."content_reports" FOR EACH ROW EXECUTE FUNCTION "public"."check_report_rate_limit"();



CREATE OR REPLACE TRIGGER "prevent_duplicate_reports_trigger" BEFORE INSERT ON "public"."content_reports" FOR EACH ROW EXECUTE FUNCTION "public"."prevent_duplicate_reports"();



CREATE OR REPLACE TRIGGER "set_category_path" BEFORE INSERT OR UPDATE ON "public"."categories" FOR EACH ROW EXECUTE FUNCTION "public"."calculate_category_path"();



CREATE OR REPLACE TRIGGER "track_bot_detection" AFTER INSERT ON "public"."threads" FOR EACH ROW EXECUTE FUNCTION "public"."update_bot_detection"();



CREATE OR REPLACE TRIGGER "trigger_comment_delete" AFTER DELETE ON "public"."comments" FOR EACH ROW EXECUTE FUNCTION "public"."update_thread_comment_count"();



CREATE OR REPLACE TRIGGER "trigger_comment_insert" AFTER INSERT ON "public"."comments" FOR EACH ROW EXECUTE FUNCTION "public"."update_thread_comment_count"();



CREATE OR REPLACE TRIGGER "trigger_comment_vote_delete" AFTER DELETE ON "public"."comment_votes" FOR EACH ROW EXECUTE FUNCTION "public"."update_comment_vote_counts"();



CREATE OR REPLACE TRIGGER "trigger_comment_vote_insert" AFTER INSERT ON "public"."comment_votes" FOR EACH ROW EXECUTE FUNCTION "public"."update_comment_vote_counts"();



CREATE OR REPLACE TRIGGER "trigger_comment_vote_update" AFTER UPDATE ON "public"."comment_votes" FOR EACH ROW EXECUTE FUNCTION "public"."update_comment_vote_counts"();



CREATE OR REPLACE TRIGGER "trigger_set_comment_path" BEFORE INSERT ON "public"."comments" FOR EACH ROW EXECUTE FUNCTION "public"."set_comment_path"();



CREATE OR REPLACE TRIGGER "trigger_subscription_delete" AFTER DELETE ON "public"."category_subscriptions" FOR EACH ROW EXECUTE FUNCTION "public"."update_subscriber_count"();



CREATE OR REPLACE TRIGGER "trigger_subscription_insert" AFTER INSERT ON "public"."category_subscriptions" FOR EACH ROW EXECUTE FUNCTION "public"."update_subscriber_count"();



CREATE OR REPLACE TRIGGER "trigger_thread_delete" AFTER DELETE ON "public"."threads" FOR EACH ROW EXECUTE FUNCTION "public"."update_category_thread_count"();



CREATE OR REPLACE TRIGGER "trigger_thread_insert" AFTER INSERT ON "public"."threads" FOR EACH ROW EXECUTE FUNCTION "public"."update_category_thread_count"();



CREATE OR REPLACE TRIGGER "trigger_thread_vote_delete" AFTER DELETE ON "public"."thread_votes" FOR EACH ROW EXECUTE FUNCTION "public"."update_thread_vote_counts"();



CREATE OR REPLACE TRIGGER "trigger_thread_vote_insert" AFTER INSERT ON "public"."thread_votes" FOR EACH ROW EXECUTE FUNCTION "public"."update_thread_vote_counts"();



CREATE OR REPLACE TRIGGER "trigger_thread_vote_update" AFTER UPDATE ON "public"."thread_votes" FOR EACH ROW EXECUTE FUNCTION "public"."update_thread_vote_counts"();



CREATE OR REPLACE TRIGGER "trigger_track_comment_length" AFTER INSERT ON "public"."comments" FOR EACH ROW EXECUTE FUNCTION "public"."track_post_length"();



CREATE OR REPLACE TRIGGER "trigger_track_thread_length" AFTER INSERT ON "public"."threads" FOR EACH ROW EXECUTE FUNCTION "public"."track_post_length"();



CREATE OR REPLACE TRIGGER "trigger_update_activity_comment" AFTER INSERT ON "public"."comments" FOR EACH ROW EXECUTE FUNCTION "public"."update_user_activity"();



CREATE OR REPLACE TRIGGER "trigger_update_activity_thread" AFTER INSERT ON "public"."threads" FOR EACH ROW EXECUTE FUNCTION "public"."update_user_activity"();



CREATE OR REPLACE TRIGGER "trigger_update_bot_status" BEFORE INSERT OR UPDATE ON "public"."bot_reports" FOR EACH ROW EXECUTE FUNCTION "public"."update_bot_status"();



CREATE OR REPLACE TRIGGER "trigger_update_comment_wilson_score" BEFORE UPDATE OF "upvotes", "downvotes" ON "public"."comments" FOR EACH ROW EXECUTE FUNCTION "public"."update_comment_wilson_score"();



CREATE OR REPLACE TRIGGER "trigger_update_thread_hot_score" AFTER UPDATE OF "upvotes", "downvotes" ON "public"."threads" FOR EACH ROW EXECUTE FUNCTION "public"."update_thread_hot_score"();



CREATE OR REPLACE TRIGGER "update_category_counts" AFTER INSERT OR DELETE ON "public"."threads" FOR EACH ROW EXECUTE FUNCTION "public"."update_category_post_count"();



CREATE OR REPLACE TRIGGER "update_category_subscriber_count_trigger" AFTER INSERT OR DELETE ON "public"."category_subscriptions" FOR EACH ROW EXECUTE FUNCTION "public"."update_category_subscriber_count"();



CREATE OR REPLACE TRIGGER "update_thread_on_comment" AFTER INSERT ON "public"."comments" FOR EACH ROW EXECUTE FUNCTION "public"."update_thread_activity"();



ALTER TABLE ONLY "public"."bot_detection"
    ADD CONSTRAINT "bot_detection_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."bot_reports"
    ADD CONSTRAINT "bot_reports_reported_user_id_fkey" FOREIGN KEY ("reported_user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."bot_reports"
    ADD CONSTRAINT "bot_reports_reporter_id_fkey" FOREIGN KEY ("reporter_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."bot_reports"
    ADD CONSTRAINT "bot_reports_reviewed_by_fkey" FOREIGN KEY ("reviewed_by") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_parent_id_fkey" FOREIGN KEY ("parent_id") REFERENCES "public"."categories"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."category_digests"
    ADD CONSTRAINT "category_digests_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."categories"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."category_rules"
    ADD CONSTRAINT "category_rules_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."categories"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."category_subscriptions"
    ADD CONSTRAINT "category_subscriptions_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."categories"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."category_subscriptions"
    ADD CONSTRAINT "category_subscriptions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."comment_votes"
    ADD CONSTRAINT "comment_votes_comment_id_fkey" FOREIGN KEY ("comment_id") REFERENCES "public"."comments"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."comment_votes"
    ADD CONSTRAINT "comment_votes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_parent_id_fkey" FOREIGN KEY ("parent_id") REFERENCES "public"."comments"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_removed_by_fkey" FOREIGN KEY ("removed_by") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_thread_id_fkey" FOREIGN KEY ("thread_id") REFERENCES "public"."threads"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."comments"
    ADD CONSTRAINT "comments_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."content_reports"
    ADD CONSTRAINT "content_reports_moderator_id_fkey" FOREIGN KEY ("moderator_id") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."content_reports"
    ADD CONSTRAINT "content_reports_reporter_id_fkey" FOREIGN KEY ("reporter_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."election_votes"
    ADD CONSTRAINT "election_votes_election_id_fkey" FOREIGN KEY ("election_id") REFERENCES "public"."moderator_elections"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."election_votes"
    ADD CONSTRAINT "election_votes_voter_id_fkey" FOREIGN KEY ("voter_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."moderation_logs"
    ADD CONSTRAINT "moderation_logs_moderator_id_fkey" FOREIGN KEY ("moderator_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."moderation_logs"
    ADD CONSTRAINT "moderation_logs_target_user_id_fkey" FOREIGN KEY ("target_user_id") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."moderator_bot_reports"
    ADD CONSTRAINT "moderator_bot_reports_moderator_id_fkey" FOREIGN KEY ("moderator_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."moderator_bot_reports"
    ADD CONSTRAINT "moderator_bot_reports_reported_user_id_fkey" FOREIGN KEY ("reported_user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."moderator_elections"
    ADD CONSTRAINT "moderator_elections_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."categories"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."moderator_elections"
    ADD CONSTRAINT "moderator_elections_initiated_by_fkey" FOREIGN KEY ("initiated_by") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."moderator_elections"
    ADD CONSTRAINT "moderator_elections_target_user_id_fkey" FOREIGN KEY ("target_user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."moderator_elections"
    ADD CONSTRAINT "moderator_elections_winner_id_fkey" FOREIGN KEY ("winner_id") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."moderators"
    ADD CONSTRAINT "moderators_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."categories"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."moderators"
    ADD CONSTRAINT "moderators_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notification_preferences"
    ADD CONSTRAINT "notification_preferences_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."session_votes"
    ADD CONSTRAINT "session_votes_entry_id_fkey" FOREIGN KEY ("entry_id") REFERENCES "public"."voting_entries"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."session_votes"
    ADD CONSTRAINT "session_votes_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "public"."voting_sessions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."session_votes"
    ADD CONSTRAINT "session_votes_voter_id_fkey" FOREIGN KEY ("voter_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."spam_logs"
    ADD CONSTRAINT "spam_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."thread_summaries"
    ADD CONSTRAINT "thread_summaries_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."categories"("id");



ALTER TABLE ONLY "public"."thread_summaries"
    ADD CONSTRAINT "thread_summaries_thread_id_fkey" FOREIGN KEY ("thread_id") REFERENCES "public"."threads"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."thread_votes"
    ADD CONSTRAINT "thread_votes_thread_id_fkey" FOREIGN KEY ("thread_id") REFERENCES "public"."threads"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."thread_votes"
    ADD CONSTRAINT "thread_votes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."threads"
    ADD CONSTRAINT "threads_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."categories"("id");



ALTER TABLE ONLY "public"."threads"
    ADD CONSTRAINT "threads_removed_by_fkey" FOREIGN KEY ("removed_by") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."threads"
    ADD CONSTRAINT "threads_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."trust_factors"
    ADD CONSTRAINT "trust_factors_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_activity"
    ADD CONSTRAINT "user_activity_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_badges"
    ADD CONSTRAINT "user_badges_badge_id_fkey" FOREIGN KEY ("badge_id") REFERENCES "public"."badges"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_badges"
    ADD CONSTRAINT "user_badges_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_sessions"
    ADD CONSTRAINT "user_sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_warnings"
    ADD CONSTRAINT "user_warnings_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."categories"("id");



ALTER TABLE ONLY "public"."user_warnings"
    ADD CONSTRAINT "user_warnings_moderator_id_fkey" FOREIGN KEY ("moderator_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_warnings"
    ADD CONSTRAINT "user_warnings_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."voting_entries"
    ADD CONSTRAINT "voting_entries_nominee_id_fkey" FOREIGN KEY ("nominee_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."voting_entries"
    ADD CONSTRAINT "voting_entries_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "public"."voting_sessions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."voting_sessions"
    ADD CONSTRAINT "voting_sessions_participation_badge_id_fkey" FOREIGN KEY ("participation_badge_id") REFERENCES "public"."badges"("id");



ALTER TABLE ONLY "public"."voting_sessions"
    ADD CONSTRAINT "voting_sessions_winner_badge_id_fkey" FOREIGN KEY ("winner_badge_id") REFERENCES "public"."badges"("id");



ALTER TABLE ONLY "public"."voting_sessions"
    ADD CONSTRAINT "voting_sessions_winner_id_fkey" FOREIGN KEY ("winner_id") REFERENCES "public"."users"("id");



ALTER TABLE ONLY "public"."xp_transactions"
    ADD CONSTRAINT "xp_transactions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



CREATE POLICY "Anyone can view active badges" ON "public"."badges" FOR SELECT USING ((("is_active" = true) OR (NOT "is_secret")));



CREATE POLICY "Anyone can view active moderators" ON "public"."moderators" FOR SELECT USING (("is_active" = true));



CREATE POLICY "Anyone can view active spam patterns" ON "public"."spam_patterns" FOR SELECT USING (("is_active" = true));



CREATE POLICY "Anyone can view category digests" ON "public"."category_digests" FOR SELECT USING (true);



CREATE POLICY "Anyone can view moderator elections" ON "public"."moderator_elections" FOR SELECT USING (true);



CREATE POLICY "Anyone can view thread summaries" ON "public"."thread_summaries" FOR SELECT USING (true);



CREATE POLICY "Anyone can view user badges" ON "public"."user_badges" FOR SELECT USING (true);



CREATE POLICY "Anyone can view voting entries" ON "public"."voting_entries" FOR SELECT USING (true);



CREATE POLICY "Anyone can view voting sessions" ON "public"."voting_sessions" FOR SELECT USING (true);



CREATE POLICY "Eligible users can vote in elections" ON "public"."election_votes" FOR INSERT WITH CHECK ((("voter_id" = "auth"."uid"()) AND (EXISTS ( SELECT 1
   FROM "public"."moderator_elections"
  WHERE (("moderator_elections"."id" = "election_votes"."election_id") AND ("moderator_elections"."status" = 'active'::"text"))))));



CREATE POLICY "Level 2+ users can create comments" ON "public"."comments" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."users"
  WHERE (("users"."id" = "auth"."uid"()) AND ("users"."level" >= 2) AND ("users"."account_status" = 'active'::"text")))));



CREATE POLICY "Level 2+ users can create threads" ON "public"."threads" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."users"
  WHERE (("users"."id" = "auth"."uid"()) AND ("users"."level" >= 2) AND ("users"."account_status" = 'active'::"text")))));



CREATE POLICY "Level 3+ users can create reports" ON "public"."content_reports" FOR INSERT WITH CHECK ((("reporter_id" = "auth"."uid"()) AND (EXISTS ( SELECT 1
   FROM "public"."users"
  WHERE (("users"."id" = "auth"."uid"()) AND ("users"."level" >= 3) AND ("users"."account_status" = 'active'::"text"))))));



CREATE POLICY "Level 4+ users can create elections" ON "public"."moderator_elections" FOR INSERT WITH CHECK ((("initiated_by" = "auth"."uid"()) AND (EXISTS ( SELECT 1
   FROM "public"."users"
  WHERE (("users"."id" = "auth"."uid"()) AND ("users"."level" >= 4) AND ("users"."account_status" = 'active'::"text"))))));



CREATE POLICY "Level 4+ users can create voting sessions" ON "public"."voting_sessions" FOR INSERT WITH CHECK ((("winner_id" = "auth"."uid"()) AND (EXISTS ( SELECT 1
   FROM "public"."users"
  WHERE (("users"."id" = "auth"."uid"()) AND ("users"."level" >= 4) AND ("users"."account_status" = 'active'::"text"))))));



CREATE POLICY "Moderators can create bot reports" ON "public"."moderator_bot_reports" FOR INSERT WITH CHECK ((("moderator_id" = "auth"."uid"()) AND (EXISTS ( SELECT 1
   FROM "public"."moderators"
  WHERE (("moderators"."user_id" = "auth"."uid"()) AND ("moderators"."is_active" = true))))));



CREATE POLICY "Moderators can create moderation logs" ON "public"."moderation_logs" FOR INSERT WITH CHECK ((("moderator_id" = "auth"."uid"()) AND (EXISTS ( SELECT 1
   FROM "public"."moderators"
  WHERE (("moderators"."user_id" = "auth"."uid"()) AND ("moderators"."is_active" = true))))));



CREATE POLICY "Moderators can issue warnings" ON "public"."user_warnings" FOR INSERT WITH CHECK ((("moderator_id" = "auth"."uid"()) AND (EXISTS ( SELECT 1
   FROM "public"."moderators"
  WHERE (("moderators"."user_id" = "auth"."uid"()) AND ("moderators"."is_active" = true))))));



CREATE POLICY "Moderators can update report status" ON "public"."content_reports" FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM "public"."moderators"
  WHERE (("moderators"."user_id" = "auth"."uid"()) AND ("moderators"."is_active" = true))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."moderators"
  WHERE (("moderators"."user_id" = "auth"."uid"()) AND ("moderators"."is_active" = true)))));



CREATE POLICY "Moderators can view all reports" ON "public"."content_reports" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."moderators"
  WHERE (("moderators"."user_id" = "auth"."uid"()) AND ("moderators"."is_active" = true)))));



CREATE POLICY "Moderators can view all warnings" ON "public"."user_warnings" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."moderators"
  WHERE (("moderators"."user_id" = "auth"."uid"()) AND ("moderators"."is_active" = true)))));



CREATE POLICY "Moderators can view moderation logs" ON "public"."moderation_logs" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."moderators"
  WHERE (("moderators"."user_id" = "auth"."uid"()) AND ("moderators"."is_active" = true)))));



CREATE POLICY "Moderators can view moderator bot reports" ON "public"."moderator_bot_reports" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."moderators"
  WHERE (("moderators"."user_id" = "auth"."uid"()) AND ("moderators"."is_active" = true)))));



CREATE POLICY "Moderators can view spam logs" ON "public"."spam_logs" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."moderators"
  WHERE (("moderators"."user_id" = "auth"."uid"()) AND ("moderators"."is_active" = true)))));



CREATE POLICY "Prevent direct user inserts" ON "public"."users" FOR INSERT WITH CHECK (false);



CREATE POLICY "Public comments are viewable" ON "public"."comments" FOR SELECT USING ((("is_removed" = false) OR ("user_id" = "auth"."uid"())));



CREATE POLICY "Public threads are viewable" ON "public"."threads" FOR SELECT USING ((("is_removed" = false) OR ("user_id" = "auth"."uid"())));



CREATE POLICY "Session creators can add entries" ON "public"."voting_entries" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."voting_sessions"
  WHERE (("voting_sessions"."id" = "voting_entries"."session_id") AND ("voting_sessions"."winner_id" = "auth"."uid"())))));



CREATE POLICY "Users can manage own notification preferences" ON "public"."notification_preferences" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can report suspected bots" ON "public"."bot_reports" FOR INSERT WITH CHECK ((("reporter_id" = "auth"."uid"()) AND (EXISTS ( SELECT 1
   FROM "public"."users"
  WHERE (("users"."id" = "auth"."uid"()) AND ("users"."account_status" = 'active'::"text") AND ("users"."level" >= 3))))));



CREATE POLICY "Users can update own notifications" ON "public"."notifications" FOR UPDATE USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can update own profile" ON "public"."users" FOR UPDATE USING (("id" = "auth"."uid"())) WITH CHECK (("id" = "auth"."uid"()));



CREATE POLICY "Users can view active users" ON "public"."users" FOR SELECT USING ((("account_status" <> 'shadowbanned'::"text") OR ("id" = "auth"."uid"())));



CREATE POLICY "Users can view own activity" ON "public"."user_activity" FOR SELECT USING (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can view own election votes" ON "public"."election_votes" FOR SELECT USING (("voter_id" = "auth"."uid"()));



CREATE POLICY "Users can view own notifications" ON "public"."notifications" FOR SELECT USING (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can view own reports" ON "public"."content_reports" FOR SELECT USING (("reporter_id" = "auth"."uid"()));



CREATE POLICY "Users can view own session votes" ON "public"."session_votes" FOR SELECT USING (("voter_id" = "auth"."uid"()));



CREATE POLICY "Users can view own warnings" ON "public"."user_warnings" FOR SELECT USING (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can view own xp transactions" ON "public"."xp_transactions" FOR SELECT USING (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can vote in sessions" ON "public"."session_votes" FOR INSERT WITH CHECK ((("voter_id" = "auth"."uid"()) AND (EXISTS ( SELECT 1
   FROM "public"."voting_sessions" "vs"
  WHERE (("vs"."id" = "session_votes"."session_id") AND ("vs"."status" = 'active'::"text"))))));



CREATE POLICY "Users can vote on comments" ON "public"."comment_votes" USING ((EXISTS ( SELECT 1
   FROM "public"."users"
  WHERE (("users"."id" = "auth"."uid"()) AND ("users"."account_status" = 'active'::"text")))));



CREATE POLICY "Users can vote on threads" ON "public"."thread_votes" USING ((EXISTS ( SELECT 1
   FROM "public"."users"
  WHERE (("users"."id" = "auth"."uid"()) AND ("users"."account_status" = 'active'::"text")))));



ALTER TABLE "public"."badges" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."bot_reports" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."category_digests" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."comment_votes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."comments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."content_reports" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."election_votes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."moderation_logs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."moderator_bot_reports" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."moderator_elections" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."moderators" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."notification_preferences" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."notifications" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."session_votes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."spam_logs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."spam_patterns" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."thread_summaries" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."thread_votes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."threads" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_activity" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_badges" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_warnings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."users" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."voting_entries" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."voting_sessions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."xp_transactions" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";





GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_in"("cstring") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_in"("cstring") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_in"("cstring") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_in"("cstring") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_out"("public"."gtrgm") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_out"("public"."gtrgm") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_out"("public"."gtrgm") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_out"("public"."gtrgm") TO "service_role";



GRANT ALL ON FUNCTION "public"."lquery_in"("cstring") TO "postgres";
GRANT ALL ON FUNCTION "public"."lquery_in"("cstring") TO "anon";
GRANT ALL ON FUNCTION "public"."lquery_in"("cstring") TO "authenticated";
GRANT ALL ON FUNCTION "public"."lquery_in"("cstring") TO "service_role";



GRANT ALL ON FUNCTION "public"."lquery_out"("public"."lquery") TO "postgres";
GRANT ALL ON FUNCTION "public"."lquery_out"("public"."lquery") TO "anon";
GRANT ALL ON FUNCTION "public"."lquery_out"("public"."lquery") TO "authenticated";
GRANT ALL ON FUNCTION "public"."lquery_out"("public"."lquery") TO "service_role";



GRANT ALL ON FUNCTION "public"."lquery_recv"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."lquery_recv"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."lquery_recv"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."lquery_recv"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."lquery_send"("public"."lquery") TO "postgres";
GRANT ALL ON FUNCTION "public"."lquery_send"("public"."lquery") TO "anon";
GRANT ALL ON FUNCTION "public"."lquery_send"("public"."lquery") TO "authenticated";
GRANT ALL ON FUNCTION "public"."lquery_send"("public"."lquery") TO "service_role";



GRANT ALL ON FUNCTION "public"."ltree_in"("cstring") TO "postgres";
GRANT ALL ON FUNCTION "public"."ltree_in"("cstring") TO "anon";
GRANT ALL ON FUNCTION "public"."ltree_in"("cstring") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ltree_in"("cstring") TO "service_role";



GRANT ALL ON FUNCTION "public"."ltree_out"("public"."ltree") TO "postgres";
GRANT ALL ON FUNCTION "public"."ltree_out"("public"."ltree") TO "anon";
GRANT ALL ON FUNCTION "public"."ltree_out"("public"."ltree") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ltree_out"("public"."ltree") TO "service_role";



GRANT ALL ON FUNCTION "public"."ltree_recv"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."ltree_recv"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."ltree_recv"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ltree_recv"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."ltree_send"("public"."ltree") TO "postgres";
GRANT ALL ON FUNCTION "public"."ltree_send"("public"."ltree") TO "anon";
GRANT ALL ON FUNCTION "public"."ltree_send"("public"."ltree") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ltree_send"("public"."ltree") TO "service_role";



GRANT ALL ON FUNCTION "public"."ltree_gist_in"("cstring") TO "postgres";
GRANT ALL ON FUNCTION "public"."ltree_gist_in"("cstring") TO "anon";
GRANT ALL ON FUNCTION "public"."ltree_gist_in"("cstring") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ltree_gist_in"("cstring") TO "service_role";



GRANT ALL ON FUNCTION "public"."ltree_gist_out"("public"."ltree_gist") TO "postgres";
GRANT ALL ON FUNCTION "public"."ltree_gist_out"("public"."ltree_gist") TO "anon";
GRANT ALL ON FUNCTION "public"."ltree_gist_out"("public"."ltree_gist") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ltree_gist_out"("public"."ltree_gist") TO "service_role";



GRANT ALL ON FUNCTION "public"."ltxtq_in"("cstring") TO "postgres";
GRANT ALL ON FUNCTION "public"."ltxtq_in"("cstring") TO "anon";
GRANT ALL ON FUNCTION "public"."ltxtq_in"("cstring") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ltxtq_in"("cstring") TO "service_role";



GRANT ALL ON FUNCTION "public"."ltxtq_out"("public"."ltxtquery") TO "postgres";
GRANT ALL ON FUNCTION "public"."ltxtq_out"("public"."ltxtquery") TO "anon";
GRANT ALL ON FUNCTION "public"."ltxtq_out"("public"."ltxtquery") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ltxtq_out"("public"."ltxtquery") TO "service_role";



GRANT ALL ON FUNCTION "public"."ltxtq_recv"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."ltxtq_recv"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."ltxtq_recv"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ltxtq_recv"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."ltxtq_send"("public"."ltxtquery") TO "postgres";
GRANT ALL ON FUNCTION "public"."ltxtq_send"("public"."ltxtquery") TO "anon";
GRANT ALL ON FUNCTION "public"."ltxtq_send"("public"."ltxtquery") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ltxtq_send"("public"."ltxtquery") TO "service_role";


























































































































































































GRANT ALL ON FUNCTION "public"."_lt_q_regex"("public"."ltree"[], "public"."lquery"[]) TO "postgres";
GRANT ALL ON FUNCTION "public"."_lt_q_regex"("public"."ltree"[], "public"."lquery"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."_lt_q_regex"("public"."ltree"[], "public"."lquery"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."_lt_q_regex"("public"."ltree"[], "public"."lquery"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."_lt_q_rregex"("public"."lquery"[], "public"."ltree"[]) TO "postgres";
GRANT ALL ON FUNCTION "public"."_lt_q_rregex"("public"."lquery"[], "public"."ltree"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."_lt_q_rregex"("public"."lquery"[], "public"."ltree"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."_lt_q_rregex"("public"."lquery"[], "public"."ltree"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."_ltq_extract_regex"("public"."ltree"[], "public"."lquery") TO "postgres";
GRANT ALL ON FUNCTION "public"."_ltq_extract_regex"("public"."ltree"[], "public"."lquery") TO "anon";
GRANT ALL ON FUNCTION "public"."_ltq_extract_regex"("public"."ltree"[], "public"."lquery") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ltq_extract_regex"("public"."ltree"[], "public"."lquery") TO "service_role";



GRANT ALL ON FUNCTION "public"."_ltq_regex"("public"."ltree"[], "public"."lquery") TO "postgres";
GRANT ALL ON FUNCTION "public"."_ltq_regex"("public"."ltree"[], "public"."lquery") TO "anon";
GRANT ALL ON FUNCTION "public"."_ltq_regex"("public"."ltree"[], "public"."lquery") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ltq_regex"("public"."ltree"[], "public"."lquery") TO "service_role";



GRANT ALL ON FUNCTION "public"."_ltq_rregex"("public"."lquery", "public"."ltree"[]) TO "postgres";
GRANT ALL ON FUNCTION "public"."_ltq_rregex"("public"."lquery", "public"."ltree"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."_ltq_rregex"("public"."lquery", "public"."ltree"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ltq_rregex"("public"."lquery", "public"."ltree"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."_ltree_compress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."_ltree_compress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."_ltree_compress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ltree_compress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."_ltree_consistent"("internal", "public"."ltree"[], smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."_ltree_consistent"("internal", "public"."ltree"[], smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."_ltree_consistent"("internal", "public"."ltree"[], smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ltree_consistent"("internal", "public"."ltree"[], smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."_ltree_extract_isparent"("public"."ltree"[], "public"."ltree") TO "postgres";
GRANT ALL ON FUNCTION "public"."_ltree_extract_isparent"("public"."ltree"[], "public"."ltree") TO "anon";
GRANT ALL ON FUNCTION "public"."_ltree_extract_isparent"("public"."ltree"[], "public"."ltree") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ltree_extract_isparent"("public"."ltree"[], "public"."ltree") TO "service_role";



GRANT ALL ON FUNCTION "public"."_ltree_extract_risparent"("public"."ltree"[], "public"."ltree") TO "postgres";
GRANT ALL ON FUNCTION "public"."_ltree_extract_risparent"("public"."ltree"[], "public"."ltree") TO "anon";
GRANT ALL ON FUNCTION "public"."_ltree_extract_risparent"("public"."ltree"[], "public"."ltree") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ltree_extract_risparent"("public"."ltree"[], "public"."ltree") TO "service_role";



GRANT ALL ON FUNCTION "public"."_ltree_gist_options"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."_ltree_gist_options"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."_ltree_gist_options"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ltree_gist_options"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."_ltree_isparent"("public"."ltree"[], "public"."ltree") TO "postgres";
GRANT ALL ON FUNCTION "public"."_ltree_isparent"("public"."ltree"[], "public"."ltree") TO "anon";
GRANT ALL ON FUNCTION "public"."_ltree_isparent"("public"."ltree"[], "public"."ltree") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ltree_isparent"("public"."ltree"[], "public"."ltree") TO "service_role";



GRANT ALL ON FUNCTION "public"."_ltree_penalty"("internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."_ltree_penalty"("internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."_ltree_penalty"("internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ltree_penalty"("internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."_ltree_picksplit"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."_ltree_picksplit"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."_ltree_picksplit"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ltree_picksplit"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."_ltree_r_isparent"("public"."ltree", "public"."ltree"[]) TO "postgres";
GRANT ALL ON FUNCTION "public"."_ltree_r_isparent"("public"."ltree", "public"."ltree"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."_ltree_r_isparent"("public"."ltree", "public"."ltree"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ltree_r_isparent"("public"."ltree", "public"."ltree"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."_ltree_r_risparent"("public"."ltree", "public"."ltree"[]) TO "postgres";
GRANT ALL ON FUNCTION "public"."_ltree_r_risparent"("public"."ltree", "public"."ltree"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."_ltree_r_risparent"("public"."ltree", "public"."ltree"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ltree_r_risparent"("public"."ltree", "public"."ltree"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."_ltree_risparent"("public"."ltree"[], "public"."ltree") TO "postgres";
GRANT ALL ON FUNCTION "public"."_ltree_risparent"("public"."ltree"[], "public"."ltree") TO "anon";
GRANT ALL ON FUNCTION "public"."_ltree_risparent"("public"."ltree"[], "public"."ltree") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ltree_risparent"("public"."ltree"[], "public"."ltree") TO "service_role";



GRANT ALL ON FUNCTION "public"."_ltree_same"("public"."ltree_gist", "public"."ltree_gist", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."_ltree_same"("public"."ltree_gist", "public"."ltree_gist", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."_ltree_same"("public"."ltree_gist", "public"."ltree_gist", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ltree_same"("public"."ltree_gist", "public"."ltree_gist", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."_ltree_union"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."_ltree_union"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."_ltree_union"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ltree_union"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."_ltxtq_exec"("public"."ltree"[], "public"."ltxtquery") TO "postgres";
GRANT ALL ON FUNCTION "public"."_ltxtq_exec"("public"."ltree"[], "public"."ltxtquery") TO "anon";
GRANT ALL ON FUNCTION "public"."_ltxtq_exec"("public"."ltree"[], "public"."ltxtquery") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ltxtq_exec"("public"."ltree"[], "public"."ltxtquery") TO "service_role";



GRANT ALL ON FUNCTION "public"."_ltxtq_extract_exec"("public"."ltree"[], "public"."ltxtquery") TO "postgres";
GRANT ALL ON FUNCTION "public"."_ltxtq_extract_exec"("public"."ltree"[], "public"."ltxtquery") TO "anon";
GRANT ALL ON FUNCTION "public"."_ltxtq_extract_exec"("public"."ltree"[], "public"."ltxtquery") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ltxtq_extract_exec"("public"."ltree"[], "public"."ltxtquery") TO "service_role";



GRANT ALL ON FUNCTION "public"."_ltxtq_rexec"("public"."ltxtquery", "public"."ltree"[]) TO "postgres";
GRANT ALL ON FUNCTION "public"."_ltxtq_rexec"("public"."ltxtquery", "public"."ltree"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."_ltxtq_rexec"("public"."ltxtquery", "public"."ltree"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."_ltxtq_rexec"("public"."ltxtquery", "public"."ltree"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."archive_old_notifications"() TO "anon";
GRANT ALL ON FUNCTION "public"."archive_old_notifications"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."archive_old_notifications"() TO "service_role";



GRANT ALL ON FUNCTION "public"."award_xp"("p_user_id" "uuid", "p_action" "text", "p_amount" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."award_xp"("p_user_id" "uuid", "p_action" "text", "p_amount" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."award_xp"("p_user_id" "uuid", "p_action" "text", "p_amount" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."calculate_category_path"() TO "anon";
GRANT ALL ON FUNCTION "public"."calculate_category_path"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."calculate_category_path"() TO "service_role";



GRANT ALL ON FUNCTION "public"."calculate_comment_path"() TO "anon";
GRANT ALL ON FUNCTION "public"."calculate_comment_path"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."calculate_comment_path"() TO "service_role";



GRANT ALL ON FUNCTION "public"."calculate_hot_score"("upvotes" integer, "downvotes" integer, "created_at" timestamp with time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."calculate_hot_score"("upvotes" integer, "downvotes" integer, "created_at" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."calculate_hot_score"("upvotes" integer, "downvotes" integer, "created_at" timestamp with time zone) TO "service_role";



GRANT ALL ON FUNCTION "public"."calculate_user_level"("xp" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."calculate_user_level"("xp" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."calculate_user_level"("xp" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."calculate_wilson_score"("upvotes" integer, "downvotes" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."calculate_wilson_score"("upvotes" integer, "downvotes" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."calculate_wilson_score"("upvotes" integer, "downvotes" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."check_bot_criteria"("p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."check_bot_criteria"("p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_bot_criteria"("p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."check_report_rate_limit"() TO "anon";
GRANT ALL ON FUNCTION "public"."check_report_rate_limit"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_report_rate_limit"() TO "service_role";



GRANT ALL ON FUNCTION "public"."cleanup_expired_sessions"() TO "anon";
GRANT ALL ON FUNCTION "public"."cleanup_expired_sessions"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."cleanup_expired_sessions"() TO "service_role";



GRANT ALL ON FUNCTION "public"."create_user_profile"() TO "anon";
GRANT ALL ON FUNCTION "public"."create_user_profile"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_user_profile"() TO "service_role";



GRANT ALL ON FUNCTION "public"."evaluate_bot_status"("p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."evaluate_bot_status"("p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."evaluate_bot_status"("p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."generate_comment_path"("p_parent_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."generate_comment_path"("p_parent_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."generate_comment_path"("p_parent_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_category_path"("p_category_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_category_path"("p_category_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_category_path"("p_category_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_category_subscriber_count"("category_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_category_subscriber_count"("category_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_category_subscriber_count"("category_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_thread_stats"("p_thread_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_thread_stats"("p_thread_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_thread_stats"("p_thread_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_user_stats"("p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_user_stats"("p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_user_stats"("p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_xp_for_action"("action_type" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_xp_for_action"("action_type" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_xp_for_action"("action_type" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_query_trgm"("text", "internal", smallint, "internal", "internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_query_trgm"("text", "internal", smallint, "internal", "internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_query_trgm"("text", "internal", smallint, "internal", "internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_query_trgm"("text", "internal", smallint, "internal", "internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_value_trgm"("text", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_value_trgm"("text", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_value_trgm"("text", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_value_trgm"("text", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_trgm_consistent"("internal", smallint, "text", integer, "internal", "internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_trgm_consistent"("internal", smallint, "text", integer, "internal", "internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_trgm_consistent"("internal", smallint, "text", integer, "internal", "internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_trgm_consistent"("internal", smallint, "text", integer, "internal", "internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_trgm_triconsistent"("internal", smallint, "text", integer, "internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_trgm_triconsistent"("internal", smallint, "text", integer, "internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_trgm_triconsistent"("internal", smallint, "text", integer, "internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_trgm_triconsistent"("internal", smallint, "text", integer, "internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_compress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_compress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_compress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_compress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_consistent"("internal", "text", smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_consistent"("internal", "text", smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_consistent"("internal", "text", smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_consistent"("internal", "text", smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_decompress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_decompress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_decompress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_decompress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_distance"("internal", "text", smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_distance"("internal", "text", smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_distance"("internal", "text", smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_distance"("internal", "text", smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_options"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_options"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_options"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_options"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_penalty"("internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_penalty"("internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_penalty"("internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_penalty"("internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_picksplit"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_picksplit"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_picksplit"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_picksplit"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_same"("public"."gtrgm", "public"."gtrgm", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_same"("public"."gtrgm", "public"."gtrgm", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_same"("public"."gtrgm", "public"."gtrgm", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_same"("public"."gtrgm", "public"."gtrgm", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_union"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_union"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_union"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_union"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."increment_category_subscribers"("category_id" "uuid", "increment" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."increment_category_subscribers"("category_id" "uuid", "increment" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."increment_category_subscribers"("category_id" "uuid", "increment" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."index"("public"."ltree", "public"."ltree") TO "postgres";
GRANT ALL ON FUNCTION "public"."index"("public"."ltree", "public"."ltree") TO "anon";
GRANT ALL ON FUNCTION "public"."index"("public"."ltree", "public"."ltree") TO "authenticated";
GRANT ALL ON FUNCTION "public"."index"("public"."ltree", "public"."ltree") TO "service_role";



GRANT ALL ON FUNCTION "public"."index"("public"."ltree", "public"."ltree", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."index"("public"."ltree", "public"."ltree", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."index"("public"."ltree", "public"."ltree", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."index"("public"."ltree", "public"."ltree", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."lca"("public"."ltree"[]) TO "postgres";
GRANT ALL ON FUNCTION "public"."lca"("public"."ltree"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."lca"("public"."ltree"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."lca"("public"."ltree"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."lca"("public"."ltree", "public"."ltree") TO "postgres";
GRANT ALL ON FUNCTION "public"."lca"("public"."ltree", "public"."ltree") TO "anon";
GRANT ALL ON FUNCTION "public"."lca"("public"."ltree", "public"."ltree") TO "authenticated";
GRANT ALL ON FUNCTION "public"."lca"("public"."ltree", "public"."ltree") TO "service_role";



GRANT ALL ON FUNCTION "public"."lca"("public"."ltree", "public"."ltree", "public"."ltree") TO "postgres";
GRANT ALL ON FUNCTION "public"."lca"("public"."ltree", "public"."ltree", "public"."ltree") TO "anon";
GRANT ALL ON FUNCTION "public"."lca"("public"."ltree", "public"."ltree", "public"."ltree") TO "authenticated";
GRANT ALL ON FUNCTION "public"."lca"("public"."ltree", "public"."ltree", "public"."ltree") TO "service_role";



GRANT ALL ON FUNCTION "public"."lca"("public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree") TO "postgres";
GRANT ALL ON FUNCTION "public"."lca"("public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree") TO "anon";
GRANT ALL ON FUNCTION "public"."lca"("public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree") TO "authenticated";
GRANT ALL ON FUNCTION "public"."lca"("public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree") TO "service_role";



GRANT ALL ON FUNCTION "public"."lca"("public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree") TO "postgres";
GRANT ALL ON FUNCTION "public"."lca"("public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree") TO "anon";
GRANT ALL ON FUNCTION "public"."lca"("public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree") TO "authenticated";
GRANT ALL ON FUNCTION "public"."lca"("public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree") TO "service_role";



GRANT ALL ON FUNCTION "public"."lca"("public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree") TO "postgres";
GRANT ALL ON FUNCTION "public"."lca"("public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree") TO "anon";
GRANT ALL ON FUNCTION "public"."lca"("public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree") TO "authenticated";
GRANT ALL ON FUNCTION "public"."lca"("public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree") TO "service_role";



GRANT ALL ON FUNCTION "public"."lca"("public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree") TO "postgres";
GRANT ALL ON FUNCTION "public"."lca"("public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree") TO "anon";
GRANT ALL ON FUNCTION "public"."lca"("public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree") TO "authenticated";
GRANT ALL ON FUNCTION "public"."lca"("public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree") TO "service_role";



GRANT ALL ON FUNCTION "public"."lca"("public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree") TO "postgres";
GRANT ALL ON FUNCTION "public"."lca"("public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree") TO "anon";
GRANT ALL ON FUNCTION "public"."lca"("public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree") TO "authenticated";
GRANT ALL ON FUNCTION "public"."lca"("public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree", "public"."ltree") TO "service_role";



GRANT ALL ON FUNCTION "public"."lt_q_regex"("public"."ltree", "public"."lquery"[]) TO "postgres";
GRANT ALL ON FUNCTION "public"."lt_q_regex"("public"."ltree", "public"."lquery"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."lt_q_regex"("public"."ltree", "public"."lquery"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."lt_q_regex"("public"."ltree", "public"."lquery"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."lt_q_rregex"("public"."lquery"[], "public"."ltree") TO "postgres";
GRANT ALL ON FUNCTION "public"."lt_q_rregex"("public"."lquery"[], "public"."ltree") TO "anon";
GRANT ALL ON FUNCTION "public"."lt_q_rregex"("public"."lquery"[], "public"."ltree") TO "authenticated";
GRANT ALL ON FUNCTION "public"."lt_q_rregex"("public"."lquery"[], "public"."ltree") TO "service_role";



GRANT ALL ON FUNCTION "public"."ltq_regex"("public"."ltree", "public"."lquery") TO "postgres";
GRANT ALL ON FUNCTION "public"."ltq_regex"("public"."ltree", "public"."lquery") TO "anon";
GRANT ALL ON FUNCTION "public"."ltq_regex"("public"."ltree", "public"."lquery") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ltq_regex"("public"."ltree", "public"."lquery") TO "service_role";



GRANT ALL ON FUNCTION "public"."ltq_rregex"("public"."lquery", "public"."ltree") TO "postgres";
GRANT ALL ON FUNCTION "public"."ltq_rregex"("public"."lquery", "public"."ltree") TO "anon";
GRANT ALL ON FUNCTION "public"."ltq_rregex"("public"."lquery", "public"."ltree") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ltq_rregex"("public"."lquery", "public"."ltree") TO "service_role";



GRANT ALL ON FUNCTION "public"."ltree2text"("public"."ltree") TO "postgres";
GRANT ALL ON FUNCTION "public"."ltree2text"("public"."ltree") TO "anon";
GRANT ALL ON FUNCTION "public"."ltree2text"("public"."ltree") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ltree2text"("public"."ltree") TO "service_role";



GRANT ALL ON FUNCTION "public"."ltree_addltree"("public"."ltree", "public"."ltree") TO "postgres";
GRANT ALL ON FUNCTION "public"."ltree_addltree"("public"."ltree", "public"."ltree") TO "anon";
GRANT ALL ON FUNCTION "public"."ltree_addltree"("public"."ltree", "public"."ltree") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ltree_addltree"("public"."ltree", "public"."ltree") TO "service_role";



GRANT ALL ON FUNCTION "public"."ltree_addtext"("public"."ltree", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."ltree_addtext"("public"."ltree", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."ltree_addtext"("public"."ltree", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ltree_addtext"("public"."ltree", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."ltree_cmp"("public"."ltree", "public"."ltree") TO "postgres";
GRANT ALL ON FUNCTION "public"."ltree_cmp"("public"."ltree", "public"."ltree") TO "anon";
GRANT ALL ON FUNCTION "public"."ltree_cmp"("public"."ltree", "public"."ltree") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ltree_cmp"("public"."ltree", "public"."ltree") TO "service_role";



GRANT ALL ON FUNCTION "public"."ltree_compress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."ltree_compress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."ltree_compress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ltree_compress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."ltree_consistent"("internal", "public"."ltree", smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."ltree_consistent"("internal", "public"."ltree", smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."ltree_consistent"("internal", "public"."ltree", smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ltree_consistent"("internal", "public"."ltree", smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."ltree_decompress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."ltree_decompress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."ltree_decompress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ltree_decompress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."ltree_eq"("public"."ltree", "public"."ltree") TO "postgres";
GRANT ALL ON FUNCTION "public"."ltree_eq"("public"."ltree", "public"."ltree") TO "anon";
GRANT ALL ON FUNCTION "public"."ltree_eq"("public"."ltree", "public"."ltree") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ltree_eq"("public"."ltree", "public"."ltree") TO "service_role";



GRANT ALL ON FUNCTION "public"."ltree_ge"("public"."ltree", "public"."ltree") TO "postgres";
GRANT ALL ON FUNCTION "public"."ltree_ge"("public"."ltree", "public"."ltree") TO "anon";
GRANT ALL ON FUNCTION "public"."ltree_ge"("public"."ltree", "public"."ltree") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ltree_ge"("public"."ltree", "public"."ltree") TO "service_role";



GRANT ALL ON FUNCTION "public"."ltree_gist_options"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."ltree_gist_options"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."ltree_gist_options"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ltree_gist_options"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."ltree_gt"("public"."ltree", "public"."ltree") TO "postgres";
GRANT ALL ON FUNCTION "public"."ltree_gt"("public"."ltree", "public"."ltree") TO "anon";
GRANT ALL ON FUNCTION "public"."ltree_gt"("public"."ltree", "public"."ltree") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ltree_gt"("public"."ltree", "public"."ltree") TO "service_role";



GRANT ALL ON FUNCTION "public"."ltree_isparent"("public"."ltree", "public"."ltree") TO "postgres";
GRANT ALL ON FUNCTION "public"."ltree_isparent"("public"."ltree", "public"."ltree") TO "anon";
GRANT ALL ON FUNCTION "public"."ltree_isparent"("public"."ltree", "public"."ltree") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ltree_isparent"("public"."ltree", "public"."ltree") TO "service_role";



GRANT ALL ON FUNCTION "public"."ltree_le"("public"."ltree", "public"."ltree") TO "postgres";
GRANT ALL ON FUNCTION "public"."ltree_le"("public"."ltree", "public"."ltree") TO "anon";
GRANT ALL ON FUNCTION "public"."ltree_le"("public"."ltree", "public"."ltree") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ltree_le"("public"."ltree", "public"."ltree") TO "service_role";



GRANT ALL ON FUNCTION "public"."ltree_lt"("public"."ltree", "public"."ltree") TO "postgres";
GRANT ALL ON FUNCTION "public"."ltree_lt"("public"."ltree", "public"."ltree") TO "anon";
GRANT ALL ON FUNCTION "public"."ltree_lt"("public"."ltree", "public"."ltree") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ltree_lt"("public"."ltree", "public"."ltree") TO "service_role";



GRANT ALL ON FUNCTION "public"."ltree_ne"("public"."ltree", "public"."ltree") TO "postgres";
GRANT ALL ON FUNCTION "public"."ltree_ne"("public"."ltree", "public"."ltree") TO "anon";
GRANT ALL ON FUNCTION "public"."ltree_ne"("public"."ltree", "public"."ltree") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ltree_ne"("public"."ltree", "public"."ltree") TO "service_role";



GRANT ALL ON FUNCTION "public"."ltree_penalty"("internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."ltree_penalty"("internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."ltree_penalty"("internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ltree_penalty"("internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."ltree_picksplit"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."ltree_picksplit"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."ltree_picksplit"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ltree_picksplit"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."ltree_risparent"("public"."ltree", "public"."ltree") TO "postgres";
GRANT ALL ON FUNCTION "public"."ltree_risparent"("public"."ltree", "public"."ltree") TO "anon";
GRANT ALL ON FUNCTION "public"."ltree_risparent"("public"."ltree", "public"."ltree") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ltree_risparent"("public"."ltree", "public"."ltree") TO "service_role";



GRANT ALL ON FUNCTION "public"."ltree_same"("public"."ltree_gist", "public"."ltree_gist", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."ltree_same"("public"."ltree_gist", "public"."ltree_gist", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."ltree_same"("public"."ltree_gist", "public"."ltree_gist", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ltree_same"("public"."ltree_gist", "public"."ltree_gist", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."ltree_textadd"("text", "public"."ltree") TO "postgres";
GRANT ALL ON FUNCTION "public"."ltree_textadd"("text", "public"."ltree") TO "anon";
GRANT ALL ON FUNCTION "public"."ltree_textadd"("text", "public"."ltree") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ltree_textadd"("text", "public"."ltree") TO "service_role";



GRANT ALL ON FUNCTION "public"."ltree_union"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."ltree_union"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."ltree_union"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ltree_union"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."ltreeparentsel"("internal", "oid", "internal", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."ltreeparentsel"("internal", "oid", "internal", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."ltreeparentsel"("internal", "oid", "internal", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."ltreeparentsel"("internal", "oid", "internal", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."ltxtq_exec"("public"."ltree", "public"."ltxtquery") TO "postgres";
GRANT ALL ON FUNCTION "public"."ltxtq_exec"("public"."ltree", "public"."ltxtquery") TO "anon";
GRANT ALL ON FUNCTION "public"."ltxtq_exec"("public"."ltree", "public"."ltxtquery") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ltxtq_exec"("public"."ltree", "public"."ltxtquery") TO "service_role";



GRANT ALL ON FUNCTION "public"."ltxtq_rexec"("public"."ltxtquery", "public"."ltree") TO "postgres";
GRANT ALL ON FUNCTION "public"."ltxtq_rexec"("public"."ltxtquery", "public"."ltree") TO "anon";
GRANT ALL ON FUNCTION "public"."ltxtq_rexec"("public"."ltxtquery", "public"."ltree") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ltxtq_rexec"("public"."ltxtquery", "public"."ltree") TO "service_role";



GRANT ALL ON FUNCTION "public"."nlevel"("public"."ltree") TO "postgres";
GRANT ALL ON FUNCTION "public"."nlevel"("public"."ltree") TO "anon";
GRANT ALL ON FUNCTION "public"."nlevel"("public"."ltree") TO "authenticated";
GRANT ALL ON FUNCTION "public"."nlevel"("public"."ltree") TO "service_role";



GRANT ALL ON FUNCTION "public"."prevent_duplicate_reports"() TO "anon";
GRANT ALL ON FUNCTION "public"."prevent_duplicate_reports"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."prevent_duplicate_reports"() TO "service_role";



GRANT ALL ON FUNCTION "public"."recalculate_trust_scores"() TO "anon";
GRANT ALL ON FUNCTION "public"."recalculate_trust_scores"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."recalculate_trust_scores"() TO "service_role";



GRANT ALL ON FUNCTION "public"."search_threads"("search_query" "text", "p_category_id" "uuid", "limit_count" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."search_threads"("search_query" "text", "p_category_id" "uuid", "limit_count" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."search_threads"("search_query" "text", "p_category_id" "uuid", "limit_count" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."set_comment_path"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_comment_path"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_comment_path"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_limit"(real) TO "postgres";
GRANT ALL ON FUNCTION "public"."set_limit"(real) TO "anon";
GRANT ALL ON FUNCTION "public"."set_limit"(real) TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_limit"(real) TO "service_role";



GRANT ALL ON FUNCTION "public"."show_limit"() TO "postgres";
GRANT ALL ON FUNCTION "public"."show_limit"() TO "anon";
GRANT ALL ON FUNCTION "public"."show_limit"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."show_limit"() TO "service_role";



GRANT ALL ON FUNCTION "public"."show_trgm"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."show_trgm"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."show_trgm"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."show_trgm"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."similarity"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."similarity"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."similarity"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."similarity"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."similarity_dist"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."similarity_dist"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."similarity_dist"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."similarity_dist"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."similarity_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."similarity_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."similarity_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."similarity_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity_commutator_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_commutator_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_commutator_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_commutator_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_commutator_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_commutator_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_commutator_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_commutator_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."subltree"("public"."ltree", integer, integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."subltree"("public"."ltree", integer, integer) TO "anon";
GRANT ALL ON FUNCTION "public"."subltree"("public"."ltree", integer, integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."subltree"("public"."ltree", integer, integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."subpath"("public"."ltree", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."subpath"("public"."ltree", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."subpath"("public"."ltree", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."subpath"("public"."ltree", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."subpath"("public"."ltree", integer, integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."subpath"("public"."ltree", integer, integer) TO "anon";
GRANT ALL ON FUNCTION "public"."subpath"("public"."ltree", integer, integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."subpath"("public"."ltree", integer, integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_all_category_subscriber_counts"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_all_category_subscriber_counts"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_all_category_subscriber_counts"() TO "service_role";



GRANT ALL ON FUNCTION "public"."text2ltree"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."text2ltree"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."text2ltree"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."text2ltree"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."track_post_length"() TO "anon";
GRANT ALL ON FUNCTION "public"."track_post_length"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."track_post_length"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_bot_detection"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_bot_detection"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_bot_detection"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_bot_status"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_bot_status"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_bot_status"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_category_post_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_category_post_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_category_post_count"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_category_subscriber_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_category_subscriber_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_category_subscriber_count"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_category_thread_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_category_thread_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_category_thread_count"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_comment_vote_counts"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_comment_vote_counts"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_comment_vote_counts"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_comment_wilson_score"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_comment_wilson_score"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_comment_wilson_score"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_hot_threads"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_hot_threads"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_hot_threads"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_subscriber_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_subscriber_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_subscriber_count"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_thread_activity"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_thread_activity"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_thread_activity"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_thread_comment_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_thread_comment_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_thread_comment_count"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_thread_hot_score"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_thread_hot_score"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_thread_hot_score"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_thread_vote_counts"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_thread_vote_counts"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_thread_vote_counts"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_user_activity"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_user_activity"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_user_activity"() TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity_commutator_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity_commutator_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity_commutator_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity_commutator_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity_dist_commutator_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_commutator_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_commutator_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_commutator_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity_dist_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity_op"("text", "text") TO "service_role";


















GRANT ALL ON TABLE "public"."badges" TO "anon";
GRANT ALL ON TABLE "public"."badges" TO "authenticated";
GRANT ALL ON TABLE "public"."badges" TO "service_role";



GRANT ALL ON TABLE "public"."bot_detection" TO "anon";
GRANT ALL ON TABLE "public"."bot_detection" TO "authenticated";
GRANT ALL ON TABLE "public"."bot_detection" TO "service_role";



GRANT ALL ON TABLE "public"."bot_reports" TO "anon";
GRANT ALL ON TABLE "public"."bot_reports" TO "authenticated";
GRANT ALL ON TABLE "public"."bot_reports" TO "service_role";



GRANT ALL ON TABLE "public"."categories" TO "anon";
GRANT ALL ON TABLE "public"."categories" TO "authenticated";
GRANT ALL ON TABLE "public"."categories" TO "service_role";



GRANT ALL ON TABLE "public"."category_digests" TO "anon";
GRANT ALL ON TABLE "public"."category_digests" TO "authenticated";
GRANT ALL ON TABLE "public"."category_digests" TO "service_role";



GRANT ALL ON TABLE "public"."category_rules" TO "anon";
GRANT ALL ON TABLE "public"."category_rules" TO "authenticated";
GRANT ALL ON TABLE "public"."category_rules" TO "service_role";



GRANT ALL ON TABLE "public"."category_subscriptions" TO "anon";
GRANT ALL ON TABLE "public"."category_subscriptions" TO "authenticated";
GRANT ALL ON TABLE "public"."category_subscriptions" TO "service_role";



GRANT ALL ON TABLE "public"."comment_votes" TO "anon";
GRANT ALL ON TABLE "public"."comment_votes" TO "authenticated";
GRANT ALL ON TABLE "public"."comment_votes" TO "service_role";



GRANT ALL ON TABLE "public"."comments" TO "anon";
GRANT ALL ON TABLE "public"."comments" TO "authenticated";
GRANT ALL ON TABLE "public"."comments" TO "service_role";



GRANT ALL ON TABLE "public"."content_reports" TO "anon";
GRANT ALL ON TABLE "public"."content_reports" TO "authenticated";
GRANT ALL ON TABLE "public"."content_reports" TO "service_role";



GRANT ALL ON TABLE "public"."election_votes" TO "anon";
GRANT ALL ON TABLE "public"."election_votes" TO "authenticated";
GRANT ALL ON TABLE "public"."election_votes" TO "service_role";



GRANT ALL ON TABLE "public"."moderation_logs" TO "anon";
GRANT ALL ON TABLE "public"."moderation_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."moderation_logs" TO "service_role";



GRANT ALL ON TABLE "public"."moderator_bot_reports" TO "anon";
GRANT ALL ON TABLE "public"."moderator_bot_reports" TO "authenticated";
GRANT ALL ON TABLE "public"."moderator_bot_reports" TO "service_role";



GRANT ALL ON TABLE "public"."moderator_elections" TO "anon";
GRANT ALL ON TABLE "public"."moderator_elections" TO "authenticated";
GRANT ALL ON TABLE "public"."moderator_elections" TO "service_role";



GRANT ALL ON TABLE "public"."moderators" TO "anon";
GRANT ALL ON TABLE "public"."moderators" TO "authenticated";
GRANT ALL ON TABLE "public"."moderators" TO "service_role";



GRANT ALL ON TABLE "public"."notification_preferences" TO "anon";
GRANT ALL ON TABLE "public"."notification_preferences" TO "authenticated";
GRANT ALL ON TABLE "public"."notification_preferences" TO "service_role";



GRANT ALL ON TABLE "public"."notifications" TO "anon";
GRANT ALL ON TABLE "public"."notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."notifications" TO "service_role";



GRANT ALL ON TABLE "public"."schema_migrations" TO "anon";
GRANT ALL ON TABLE "public"."schema_migrations" TO "authenticated";
GRANT ALL ON TABLE "public"."schema_migrations" TO "service_role";



GRANT ALL ON TABLE "public"."session_votes" TO "anon";
GRANT ALL ON TABLE "public"."session_votes" TO "authenticated";
GRANT ALL ON TABLE "public"."session_votes" TO "service_role";



GRANT ALL ON TABLE "public"."spam_logs" TO "anon";
GRANT ALL ON TABLE "public"."spam_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."spam_logs" TO "service_role";



GRANT ALL ON TABLE "public"."spam_patterns" TO "anon";
GRANT ALL ON TABLE "public"."spam_patterns" TO "authenticated";
GRANT ALL ON TABLE "public"."spam_patterns" TO "service_role";



GRANT ALL ON TABLE "public"."thread_summaries" TO "anon";
GRANT ALL ON TABLE "public"."thread_summaries" TO "authenticated";
GRANT ALL ON TABLE "public"."thread_summaries" TO "service_role";



GRANT ALL ON TABLE "public"."thread_votes" TO "anon";
GRANT ALL ON TABLE "public"."thread_votes" TO "authenticated";
GRANT ALL ON TABLE "public"."thread_votes" TO "service_role";



GRANT ALL ON TABLE "public"."threads" TO "anon";
GRANT ALL ON TABLE "public"."threads" TO "authenticated";
GRANT ALL ON TABLE "public"."threads" TO "service_role";



GRANT ALL ON TABLE "public"."trust_factors" TO "anon";
GRANT ALL ON TABLE "public"."trust_factors" TO "authenticated";
GRANT ALL ON TABLE "public"."trust_factors" TO "service_role";



GRANT ALL ON TABLE "public"."users" TO "anon";
GRANT ALL ON TABLE "public"."users" TO "authenticated";
GRANT ALL ON TABLE "public"."users" TO "service_role";



GRANT ALL ON TABLE "public"."trust_factors_with_age" TO "anon";
GRANT ALL ON TABLE "public"."trust_factors_with_age" TO "authenticated";
GRANT ALL ON TABLE "public"."trust_factors_with_age" TO "service_role";



GRANT ALL ON TABLE "public"."user_activity" TO "anon";
GRANT ALL ON TABLE "public"."user_activity" TO "authenticated";
GRANT ALL ON TABLE "public"."user_activity" TO "service_role";



GRANT ALL ON TABLE "public"."user_badges" TO "anon";
GRANT ALL ON TABLE "public"."user_badges" TO "authenticated";
GRANT ALL ON TABLE "public"."user_badges" TO "service_role";



GRANT ALL ON TABLE "public"."user_sessions" TO "anon";
GRANT ALL ON TABLE "public"."user_sessions" TO "authenticated";
GRANT ALL ON TABLE "public"."user_sessions" TO "service_role";



GRANT ALL ON TABLE "public"."user_warnings" TO "anon";
GRANT ALL ON TABLE "public"."user_warnings" TO "authenticated";
GRANT ALL ON TABLE "public"."user_warnings" TO "service_role";



GRANT ALL ON TABLE "public"."voting_entries" TO "anon";
GRANT ALL ON TABLE "public"."voting_entries" TO "authenticated";
GRANT ALL ON TABLE "public"."voting_entries" TO "service_role";



GRANT ALL ON TABLE "public"."voting_sessions" TO "anon";
GRANT ALL ON TABLE "public"."voting_sessions" TO "authenticated";
GRANT ALL ON TABLE "public"."voting_sessions" TO "service_role";



GRANT ALL ON TABLE "public"."xp_transactions" TO "anon";
GRANT ALL ON TABLE "public"."xp_transactions" TO "authenticated";
GRANT ALL ON TABLE "public"."xp_transactions" TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "service_role";






























RESET ALL;
