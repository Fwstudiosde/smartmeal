-- ================================================
-- SmartMeal Supabase Database Schema Migration v2
-- ================================================
-- Adds user management, meal planning, and pantry tables
-- Run this AFTER the initial migration (supabase_migration.sql)

-- ================================================
-- USER PROFILES TABLE
-- ================================================
-- Uses Supabase Auth user IDs as foreign keys
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT,
    community_name TEXT UNIQUE,
    preferred_supermarkets TEXT[] DEFAULT '{}',
    dietary_preferences TEXT[] DEFAULT '{}',
    notifications_enabled BOOLEAN DEFAULT true,
    deal_alerts_enabled BOOLEAN DEFAULT true,
    metric_units BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================
-- PANTRY ITEMS TABLE
-- ================================================
CREATE TABLE IF NOT EXISTS pantry_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    barcode TEXT NOT NULL,
    name TEXT NOT NULL,
    brand TEXT,
    image_url TEXT,
    nutri_score TEXT,
    calories INTEGER,
    protein DOUBLE PRECISION,
    carbs DOUBLE PRECISION,
    fat DOUBLE PRECISION,
    fiber DOUBLE PRECISION,
    allergens TEXT[] DEFAULT '{}',
    category TEXT DEFAULT 'Sonstiges',
    quantity INTEGER DEFAULT 1,
    packaging_size TEXT,
    expiry_date DATE,
    added_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pantry_items_user ON pantry_items(user_id);
CREATE INDEX IF NOT EXISTS idx_pantry_items_barcode ON pantry_items(barcode);
CREATE INDEX IF NOT EXISTS idx_pantry_items_expiry ON pantry_items(expiry_date);

-- ================================================
-- MEAL PLANS TABLE
-- ================================================
CREATE TABLE IF NOT EXISTS meal_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    week_start DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, week_start)
);

CREATE INDEX IF NOT EXISTS idx_meal_plans_user ON meal_plans(user_id);
CREATE INDEX IF NOT EXISTS idx_meal_plans_week ON meal_plans(week_start);

-- ================================================
-- PLANNED MEALS TABLE
-- ================================================
CREATE TABLE IF NOT EXISTS planned_meals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    meal_plan_id UUID NOT NULL REFERENCES meal_plans(id) ON DELETE CASCADE,
    recipe_id UUID REFERENCES recipes(id) ON DELETE SET NULL,
    date DATE NOT NULL,
    meal_type TEXT NOT NULL CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
    servings INTEGER DEFAULT 2,
    is_cooked BOOLEAN DEFAULT false,
    recipe_data JSONB, -- Cached recipe+deal data for offline access
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_planned_meals_plan ON planned_meals(meal_plan_id);
CREATE INDEX IF NOT EXISTS idx_planned_meals_date ON planned_meals(date);

-- ================================================
-- SHOPPING LISTS TABLE
-- ================================================
CREATE TABLE IF NOT EXISTS shopping_lists (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    meal_plan_id UUID REFERENCES meal_plans(id) ON DELETE SET NULL,
    name TEXT DEFAULT 'Einkaufsliste',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_shopping_lists_user ON shopping_lists(user_id);

-- ================================================
-- SHOPPING LIST ITEMS TABLE
-- ================================================
CREATE TABLE IF NOT EXISTS shopping_list_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shopping_list_id UUID NOT NULL REFERENCES shopping_lists(id) ON DELETE CASCADE,
    ingredient_name TEXT NOT NULL,
    quantity DOUBLE PRECISION DEFAULT 1.0,
    unit TEXT DEFAULT 'Stueck',
    category TEXT,
    store_name TEXT,
    is_purchased BOOLEAN DEFAULT false,
    deal_id UUID REFERENCES deals(id) ON DELETE SET NULL,
    price DOUBLE PRECISION,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_shopping_list_items_list ON shopping_list_items(shopping_list_id);

-- ================================================
-- RECIPE LIKES TABLE (if not exists)
-- ================================================
CREATE TABLE IF NOT EXISTS recipe_likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    recipe_id TEXT NOT NULL, -- Custom recipe ID from Supabase
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, recipe_id)
);

CREATE INDEX IF NOT EXISTS idx_recipe_likes_user ON recipe_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_recipe_likes_recipe ON recipe_likes(recipe_id);

-- ================================================
-- ROW LEVEL SECURITY POLICIES
-- ================================================

-- User Profiles
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Pantry Items
ALTER TABLE pantry_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own pantry" ON pantry_items
    FOR ALL USING (auth.uid() = user_id);

-- Meal Plans
ALTER TABLE meal_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own meal plans" ON meal_plans
    FOR ALL USING (auth.uid() = user_id);

-- Planned Meals
ALTER TABLE planned_meals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own planned meals" ON planned_meals
    FOR ALL USING (
        meal_plan_id IN (
            SELECT id FROM meal_plans WHERE user_id = auth.uid()
        )
    );

-- Shopping Lists
ALTER TABLE shopping_lists ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own shopping lists" ON shopping_lists
    FOR ALL USING (auth.uid() = user_id);

-- Shopping List Items
ALTER TABLE shopping_list_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own shopping list items" ON shopping_list_items
    FOR ALL USING (
        shopping_list_id IN (
            SELECT id FROM shopping_lists WHERE user_id = auth.uid()
        )
    );

-- Recipe Likes
ALTER TABLE recipe_likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own likes" ON recipe_likes
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Anyone can view like counts" ON recipe_likes
    FOR SELECT USING (true);

-- ================================================
-- AUTO-UPDATE TIMESTAMPS
-- ================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pantry_items_updated_at
    BEFORE UPDATE ON pantry_items
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_meal_plans_updated_at
    BEFORE UPDATE ON meal_plans
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_shopping_lists_updated_at
    BEFORE UPDATE ON shopping_lists
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ================================================
-- DEALS TABLE: Add unique constraint for upserts
-- ================================================
-- This allows the backend to upsert deals without duplicates
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'deals_unique_product_store'
    ) THEN
        ALTER TABLE deals ADD CONSTRAINT deals_unique_product_store
            UNIQUE (product_name, store_name, valid_from);
    END IF;
END
$$;
