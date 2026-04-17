-- ================================================
-- v3b: expose family member emails via SECURITY DEFINER RPC
-- Run AFTER supabase_migration_v3_families.sql
-- ================================================

CREATE OR REPLACE FUNCTION get_family_member_emails(fam_id UUID)
RETURNS TABLE (user_id UUID, email TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Only family members may look up member emails
    IF NOT EXISTS (
        SELECT 1 FROM family_members
        WHERE family_id = fam_id AND family_members.user_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'Not a member of this family';
    END IF;

    RETURN QUERY
    SELECT fm.user_id, u.email::TEXT
    FROM family_members fm
    JOIN auth.users u ON u.id = fm.user_id
    WHERE fm.family_id = fam_id;
END;
$$;

-- Allow authenticated users to call it (the function itself checks membership)
GRANT EXECUTE ON FUNCTION get_family_member_emails(UUID) TO authenticated;
