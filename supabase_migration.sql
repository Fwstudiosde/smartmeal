-- ================================================
-- SmartMeal Supabase Database Schema Migration
-- ================================================
-- This script creates all necessary tables for the SmartMeal app
-- Run this in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ================================================
-- DROP EXISTING TABLES (if they exist)
-- ================================================
-- Drop in reverse order to avoid foreign key constraint errors
DROP TABLE IF EXISTS recipe_instructions CASCADE;
DROP TABLE IF EXISTS recipe_ingredients CASCADE;
DROP TABLE IF EXISTS recipe_tags CASCADE;
DROP TABLE IF EXISTS ingredient_keywords CASCADE;
DROP TABLE IF EXISTS deals CASCADE;
DROP TABLE IF EXISTS recipes CASCADE;
DROP TABLE IF EXISTS tags CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS supermarkets CASCADE;

-- ================================================
-- CATEGORIES TABLE
-- ================================================
CREATE TABLE IF NOT EXISTS categories (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    name_de TEXT NOT NULL,
    description TEXT,
    icon TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================
-- TAGS TABLE
-- ================================================
CREATE TABLE IF NOT EXISTS tags (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    name_de TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('dietary', 'cooking_method', 'meal_type', 'difficulty', 'cuisine', 'other')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================
-- RECIPES TABLE
-- ================================================
CREATE TABLE IF NOT EXISTS recipes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    image_url TEXT,
    prep_time INTEGER NOT NULL,
    cook_time INTEGER NOT NULL,
    servings INTEGER NOT NULL,
    difficulty TEXT NOT NULL CHECK (difficulty IN ('easy', 'medium', 'hard')),
    category_id BIGINT,
    calories INTEGER,
    protein REAL,
    carbs REAL,
    fat REAL,
    fiber REAL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================
-- RECIPE TAGS (Many-to-Many)
-- ================================================
CREATE TABLE IF NOT EXISTS recipe_tags (
    recipe_id UUID NOT NULL,
    tag_id BIGINT NOT NULL,
    PRIMARY KEY (recipe_id, tag_id)
);

-- ================================================
-- RECIPE INGREDIENTS
-- ================================================
CREATE TABLE IF NOT EXISTS recipe_ingredients (
    id BIGSERIAL PRIMARY KEY,
    recipe_id UUID NOT NULL,
    ingredient_name TEXT NOT NULL,
    quantity TEXT NOT NULL,
    unit TEXT NOT NULL,
    is_optional BOOLEAN DEFAULT FALSE,
    ingredient_order INTEGER NOT NULL
);

-- ================================================
-- RECIPE INSTRUCTIONS
-- ================================================
CREATE TABLE IF NOT EXISTS recipe_instructions (
    id BIGSERIAL PRIMARY KEY,
    recipe_id UUID NOT NULL,
    step_number INTEGER NOT NULL,
    instruction TEXT NOT NULL
);

-- ================================================
-- INGREDIENT KEYWORDS (For Deal Matching)
-- ================================================
CREATE TABLE IF NOT EXISTS ingredient_keywords (
    id BIGSERIAL PRIMARY KEY,
    ingredient_name TEXT NOT NULL,
    keyword TEXT NOT NULL,
    priority INTEGER DEFAULT 1,
    UNIQUE(ingredient_name, keyword)
);

-- ================================================
-- SUPERMARKETS TABLE
-- ================================================
CREATE TABLE IF NOT EXISTS supermarkets (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    logo_url TEXT,
    color TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================
-- DEALS TABLE (Weekly Deals)
-- ================================================
CREATE TABLE IF NOT EXISTS deals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_name TEXT NOT NULL,
    store_name TEXT NOT NULL,
    store_logo_url TEXT,
    original_price REAL NOT NULL,
    discount_price REAL NOT NULL,
    discount_percentage REAL NOT NULL,
    image_url TEXT,
    valid_from TIMESTAMPTZ NOT NULL,
    valid_until TIMESTAMPTZ NOT NULL,
    category TEXT,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================
-- FOREIGN KEY CONSTRAINTS
-- ================================================
-- Add foreign key constraints after all tables are created

-- Recipes -> Categories
ALTER TABLE recipes
ADD CONSTRAINT fk_recipes_category
FOREIGN KEY (category_id) REFERENCES categories(id);

-- Recipe Tags -> Recipes and Tags
ALTER TABLE recipe_tags
ADD CONSTRAINT fk_recipe_tags_recipe
FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE;

ALTER TABLE recipe_tags
ADD CONSTRAINT fk_recipe_tags_tag
FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE;

-- Recipe Ingredients -> Recipes
ALTER TABLE recipe_ingredients
ADD CONSTRAINT fk_recipe_ingredients_recipe
FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE;

-- Recipe Instructions -> Recipes
ALTER TABLE recipe_instructions
ADD CONSTRAINT fk_recipe_instructions_recipe
FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE;

-- ================================================
-- INDEXES FOR PERFORMANCE
-- ================================================
CREATE INDEX IF NOT EXISTS idx_recipes_category ON recipes(category_id);
CREATE INDEX IF NOT EXISTS idx_recipes_difficulty ON recipes(difficulty);
CREATE INDEX IF NOT EXISTS idx_recipe_ingredients_recipe ON recipe_ingredients(recipe_id);
CREATE INDEX IF NOT EXISTS idx_recipe_instructions_recipe ON recipe_instructions(recipe_id);
CREATE INDEX IF NOT EXISTS idx_ingredient_keywords_keyword ON ingredient_keywords(keyword);
CREATE INDEX IF NOT EXISTS idx_recipe_tags_recipe ON recipe_tags(recipe_id);
CREATE INDEX IF NOT EXISTS idx_recipe_tags_tag ON recipe_tags(tag_id);
CREATE INDEX IF NOT EXISTS idx_deals_valid_until ON deals(valid_until);
CREATE INDEX IF NOT EXISTS idx_deals_store_name ON deals(store_name);

-- ================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ================================================

-- Enable RLS on all tables
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_instructions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ingredient_keywords ENABLE ROW LEVEL SECURITY;
ALTER TABLE supermarkets ENABLE ROW LEVEL SECURITY;
ALTER TABLE deals ENABLE ROW LEVEL SECURITY;

-- Public READ access for all tables (everyone can read)
CREATE POLICY "Public read access for categories" ON categories FOR SELECT USING (true);
CREATE POLICY "Public read access for tags" ON tags FOR SELECT USING (true);
CREATE POLICY "Public read access for recipes" ON recipes FOR SELECT USING (true);
CREATE POLICY "Public read access for recipe_tags" ON recipe_tags FOR SELECT USING (true);
CREATE POLICY "Public read access for recipe_ingredients" ON recipe_ingredients FOR SELECT USING (true);
CREATE POLICY "Public read access for recipe_instructions" ON recipe_instructions FOR SELECT USING (true);
CREATE POLICY "Public read access for ingredient_keywords" ON ingredient_keywords FOR SELECT USING (true);
CREATE POLICY "Public read access for supermarkets" ON supermarkets FOR SELECT USING (true);
CREATE POLICY "Public read access for deals" ON deals FOR SELECT USING (true);

-- WRITE access only for authenticated admin users
-- You can add admin role checking later
CREATE POLICY "Admin write access for categories" ON categories FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Admin write access for tags" ON tags FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Admin write access for recipes" ON recipes FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Admin write access for recipe_tags" ON recipe_tags FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Admin write access for recipe_ingredients" ON recipe_ingredients FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Admin write access for recipe_instructions" ON recipe_instructions FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Admin write access for ingredient_keywords" ON ingredient_keywords FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Admin write access for supermarkets" ON supermarkets FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Admin write access for deals" ON deals FOR ALL USING (auth.role() = 'authenticated');

-- ================================================
-- TRIGGERS FOR UPDATED_AT
-- ================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_recipes_updated_at BEFORE UPDATE ON recipes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_deals_updated_at BEFORE UPDATE ON deals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ================================================
-- INITIAL DATA: Supermarkets
-- ================================================
INSERT INTO supermarkets (id, name, logo_url, color) VALUES
    ('lidl', 'Lidl', 'https://upload.wikimedia.org/wikipedia/commons/9/91/Lidl-Logo.svg', '#0050AA'),
    ('aldi', 'Aldi', 'https://upload.wikimedia.org/wikipedia/commons/4/4a/Aldi_Nord_Logo.svg', '#00A0E3'),
    ('rewe', 'REWE', 'https://upload.wikimedia.org/wikipedia/commons/1/1f/REWE_Logo.svg', '#D40000'),
    ('edeka', 'EDEKA', 'https://upload.wikimedia.org/wikipedia/commons/c/cf/EDEKA_Logo.svg', '#FFCC00'),
    ('kaufland', 'Kaufland', 'https://upload.wikimedia.org/wikipedia/commons/a/a2/Kaufland_Logo.svg', '#EE1C23'),
    ('penny', 'Penny', 'https://upload.wikimedia.org/wikipedia/commons/6/6f/Penny_Market_Logo.svg', '#E60000'),
    ('netto', 'Netto', 'https://upload.wikimedia.org/wikipedia/commons/3/3d/Netto_Logo.svg', '#FFCC00')
ON CONFLICT (id) DO NOTHING;

COMMIT;
