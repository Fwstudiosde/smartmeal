-- ================================================
-- v3d: self-service account deletion (Apple App Store requirement)
-- Run AFTER v3, v3b, v3c
-- ================================================
--
-- Apple requires apps with account creation to offer in-app account
-- deletion. This RPC lets an authenticated user delete their own
-- auth.users row; ON DELETE CASCADE on every user_id FK then removes
-- profiles, pantry items, meal plans, shopping lists, recipe likes,
-- family memberships, and owned families.
--
-- SECURITY DEFINER is required because auth.users is in a schema the
-- caller cannot DELETE from directly. The function only ever deletes
-- the row identified by auth.uid(), so a caller can never delete
-- another user's account.

CREATE OR REPLACE FUNCTION delete_my_account()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    caller UUID := auth.uid();
BEGIN
    IF caller IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Cascades remove every user_id-keyed row across the schema.
    DELETE FROM auth.users WHERE id = caller;
END;
$$;

GRANT EXECUTE ON FUNCTION delete_my_account() TO authenticated;
