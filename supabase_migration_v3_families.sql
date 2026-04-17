-- ================================================
-- SmartMeal Supabase Database Schema Migration v3
-- ================================================
-- Adds Family (Haushalt) feature: shared meal plans + shopping lists
-- Run AFTER supabase_migration_v2.sql

-- ================================================
-- FAMILIES TABLE
-- ================================================
CREATE TABLE IF NOT EXISTS families (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    invite_code TEXT UNIQUE NOT NULL,
    max_members INT DEFAULT 6,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_families_owner ON families(owner_id);
CREATE INDEX IF NOT EXISTS idx_families_invite_code ON families(invite_code);

-- ================================================
-- FAMILY MEMBERS TABLE
-- ================================================
-- One user can only be in ONE family (enforced via UNIQUE on user_id).
CREATE TABLE IF NOT EXISTS family_members (
    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'member')),
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (family_id, user_id),
    UNIQUE (user_id)
);

CREATE INDEX IF NOT EXISTS idx_family_members_user ON family_members(user_id);

-- ================================================
-- EXTEND EXISTING TABLES WITH family_id + added_by
-- ================================================

-- meal_plans
ALTER TABLE meal_plans ADD COLUMN IF NOT EXISTS family_id UUID REFERENCES families(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_meal_plans_family ON meal_plans(family_id);

-- planned_meals
ALTER TABLE planned_meals ADD COLUMN IF NOT EXISTS added_by UUID REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE planned_meals ADD COLUMN IF NOT EXISTS cooked_by UUID REFERENCES auth.users(id) ON DELETE SET NULL;

-- shopping_lists
ALTER TABLE shopping_lists ADD COLUMN IF NOT EXISTS family_id UUID REFERENCES families(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_shopping_lists_family ON shopping_lists(family_id);

-- shopping_list_items
ALTER TABLE shopping_list_items ADD COLUMN IF NOT EXISTS added_by UUID REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE shopping_list_items ADD COLUMN IF NOT EXISTS purchased_by UUID REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE shopping_list_items ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- ================================================
-- HELPER FUNCTION: is_family_member
-- ================================================
CREATE OR REPLACE FUNCTION is_family_member(fam_id UUID)
RETURNS BOOLEAN
LANGUAGE SQL
SECURITY DEFINER
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1 FROM family_members
        WHERE family_id = fam_id AND user_id = auth.uid()
    );
$$;

-- ================================================
-- ROW LEVEL SECURITY — families
-- ================================================
ALTER TABLE families ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can view their family" ON families;
CREATE POLICY "Members can view their family" ON families
    FOR SELECT USING (is_family_member(id) OR owner_id = auth.uid());

DROP POLICY IF EXISTS "Users can create family" ON families;
CREATE POLICY "Users can create family" ON families
    FOR INSERT WITH CHECK (owner_id = auth.uid());

DROP POLICY IF EXISTS "Owner can update family" ON families;
CREATE POLICY "Owner can update family" ON families
    FOR UPDATE USING (owner_id = auth.uid());

DROP POLICY IF EXISTS "Owner can delete family" ON families;
CREATE POLICY "Owner can delete family" ON families
    FOR DELETE USING (owner_id = auth.uid());

-- Allow anyone to look up families by invite code (for joining)
DROP POLICY IF EXISTS "Anyone can lookup by invite_code" ON families;
CREATE POLICY "Anyone can lookup by invite_code" ON families
    FOR SELECT USING (true);

-- ================================================
-- ROW LEVEL SECURITY — family_members
-- ================================================
ALTER TABLE family_members ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can view co-members" ON family_members;
CREATE POLICY "Members can view co-members" ON family_members
    FOR SELECT USING (
        user_id = auth.uid()
        OR is_family_member(family_id)
    );

DROP POLICY IF EXISTS "Users can join a family" ON family_members;
CREATE POLICY "Users can join a family" ON family_members
    FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can leave a family" ON family_members;
CREATE POLICY "Users can leave a family" ON family_members
    FOR DELETE USING (
        user_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM families
            WHERE families.id = family_members.family_id
            AND families.owner_id = auth.uid()
        )
    );

-- ================================================
-- EXTEND RLS on meal_plans / shopping_lists for family access
-- ================================================

-- Drop old restrictive policies (if they exist) and recreate
DROP POLICY IF EXISTS "Users can manage own meal plans" ON meal_plans;
CREATE POLICY "User or family can access meal plans" ON meal_plans
    FOR ALL USING (
        user_id = auth.uid()
        OR (family_id IS NOT NULL AND is_family_member(family_id))
    );

DROP POLICY IF EXISTS "Users can manage own planned meals" ON planned_meals;
CREATE POLICY "User or family can access planned meals" ON planned_meals
    FOR ALL USING (
        meal_plan_id IN (
            SELECT id FROM meal_plans
            WHERE user_id = auth.uid()
            OR (family_id IS NOT NULL AND is_family_member(family_id))
        )
    );

DROP POLICY IF EXISTS "Users can manage own shopping lists" ON shopping_lists;
CREATE POLICY "User or family can access shopping lists" ON shopping_lists
    FOR ALL USING (
        user_id = auth.uid()
        OR (family_id IS NOT NULL AND is_family_member(family_id))
    );

DROP POLICY IF EXISTS "Users can manage own shopping list items" ON shopping_list_items;
CREATE POLICY "User or family can access shopping list items" ON shopping_list_items
    FOR ALL USING (
        shopping_list_id IN (
            SELECT id FROM shopping_lists
            WHERE user_id = auth.uid()
            OR (family_id IS NOT NULL AND is_family_member(family_id))
        )
    );

-- ================================================
-- AUTO-UPDATE TIMESTAMP triggers
-- ================================================
DROP TRIGGER IF EXISTS update_families_updated_at ON families;
CREATE TRIGGER update_families_updated_at
    BEFORE UPDATE ON families
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_shopping_list_items_updated_at ON shopping_list_items;
CREATE TRIGGER update_shopping_list_items_updated_at
    BEFORE UPDATE ON shopping_list_items
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ================================================
-- Auto-add owner as member on family creation
-- ================================================
CREATE OR REPLACE FUNCTION add_owner_as_member()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO family_members (family_id, user_id, role)
    VALUES (NEW.id, NEW.owner_id, 'owner')
    ON CONFLICT DO NOTHING;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_add_owner_as_member ON families;
CREATE TRIGGER trg_add_owner_as_member
    AFTER INSERT ON families
    FOR EACH ROW
    EXECUTE FUNCTION add_owner_as_member();
