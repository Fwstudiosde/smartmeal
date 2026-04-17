-- ================================================
-- v3c: lock down families visibility + safe join-by-code
-- Run AFTER v3 and v3b
-- ================================================

-- 1) Remove the catch-all SELECT policy that leaked all families to everyone.
DROP POLICY IF EXISTS "Anyone can lookup by invite_code" ON families;

-- The "Members can view their family" policy remains in place:
--    FOR SELECT USING (is_family_member(id) OR owner_id = auth.uid())
-- so non-members truly cannot see any family row.

-- 2) Safe join-by-code RPC. SECURITY DEFINER so it bypasses RLS to look
--    up the family, but enforces max_members and returns only minimal info.
CREATE OR REPLACE FUNCTION join_family_by_code(code TEXT)
RETURNS UUID  -- family_id on success
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    fam_id UUID;
    max_m INT;
    current_count INT;
    caller UUID := auth.uid();
    already_in UUID;
BEGIN
    IF caller IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT id, max_members INTO fam_id, max_m
    FROM families
    WHERE invite_code = upper(trim(code));

    IF fam_id IS NULL THEN
        RAISE EXCEPTION 'invalid_code';
    END IF;

    -- Enforce one-family-per-user at DB level (also enforced by UNIQUE(user_id))
    SELECT family_id INTO already_in FROM family_members WHERE user_id = caller;
    IF already_in IS NOT NULL THEN
        IF already_in = fam_id THEN
            RETURN fam_id;
        END IF;
        RAISE EXCEPTION 'already_in_family';
    END IF;

    SELECT count(*) INTO current_count FROM family_members WHERE family_id = fam_id;
    IF current_count >= max_m THEN
        RAISE EXCEPTION 'family_full';
    END IF;

    INSERT INTO family_members (family_id, user_id, role)
    VALUES (fam_id, caller, 'member');

    RETURN fam_id;
END;
$$;

GRANT EXECUTE ON FUNCTION join_family_by_code(TEXT) TO authenticated;
