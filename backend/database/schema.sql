-- SmartMeal Recipe Database Schema
-- Professional recipe management system with ingredient matching

-- Categories table
CREATE TABLE IF NOT EXISTS categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    name_de TEXT NOT NULL,
    description TEXT,
    icon TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tags table for flexible filtering
CREATE TABLE IF NOT EXISTS tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    name_de TEXT NOT NULL,
    type TEXT NOT NULL, -- 'dietary', 'cooking_method', 'meal_type', 'difficulty', 'cuisine'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Recipes table
CREATE TABLE IF NOT EXISTS recipes (
    id TEXT PRIMARY KEY, -- UUID
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    image_url TEXT,
    prep_time INTEGER NOT NULL, -- minutes
    cook_time INTEGER NOT NULL, -- minutes
    servings INTEGER NOT NULL,
    difficulty TEXT NOT NULL, -- 'easy', 'medium', 'hard'
    category_id INTEGER,
    calories INTEGER,
    protein REAL,
    carbs REAL,
    fat REAL,
    fiber REAL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(id)
);

-- Recipe tags junction table
CREATE TABLE IF NOT EXISTS recipe_tags (
    recipe_id TEXT NOT NULL,
    tag_id INTEGER NOT NULL,
    PRIMARY KEY (recipe_id, tag_id),
    FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);

-- Recipe ingredients
CREATE TABLE IF NOT EXISTS recipe_ingredients (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    recipe_id TEXT NOT NULL,
    ingredient_name TEXT NOT NULL,
    quantity TEXT NOT NULL,
    unit TEXT NOT NULL,
    is_optional BOOLEAN DEFAULT 0,
    ingredient_order INTEGER NOT NULL,
    FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE
);

-- Recipe instructions
CREATE TABLE IF NOT EXISTS recipe_instructions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    recipe_id TEXT NOT NULL,
    step_number INTEGER NOT NULL,
    instruction TEXT NOT NULL,
    FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE
);

-- Ingredient keywords for matching with deals
CREATE TABLE IF NOT EXISTS ingredient_keywords (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ingredient_name TEXT NOT NULL,
    keyword TEXT NOT NULL,
    priority INTEGER DEFAULT 1, -- Higher priority = better match
    UNIQUE(ingredient_name, keyword)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_recipes_category ON recipes(category_id);
CREATE INDEX IF NOT EXISTS idx_recipes_difficulty ON recipes(difficulty);
CREATE INDEX IF NOT EXISTS idx_recipe_ingredients_recipe ON recipe_ingredients(recipe_id);
CREATE INDEX IF NOT EXISTS idx_recipe_instructions_recipe ON recipe_instructions(recipe_id);
CREATE INDEX IF NOT EXISTS idx_ingredient_keywords_keyword ON ingredient_keywords(keyword);
CREATE INDEX IF NOT EXISTS idx_recipe_tags_recipe ON recipe_tags(recipe_id);
CREATE INDEX IF NOT EXISTS idx_recipe_tags_tag ON recipe_tags(tag_id);

-- Insert default categories
INSERT OR IGNORE INTO categories (name, name_de, description, icon) VALUES
    ('german', 'Deutsch', 'Traditionelle deutsche Küche', '🇩🇪'),
    ('italian', 'Italienisch', 'Mediterrane italienische Gerichte', '🇮🇹'),
    ('asian', 'Asiatisch', 'Asiatische Küche', '🍜'),
    ('fitness', 'Fitness', 'Gesunde, proteinreiche Gerichte', '💪'),
    ('vegetarian', 'Vegetarisch', 'Fleischlose Gerichte', '🥗'),
    ('vegan', 'Vegan', 'Rein pflanzliche Gerichte', '🌱'),
    ('dessert', 'Dessert', 'Süße Nachspeisen', '🍰'),
    ('breakfast', 'Frühstück', 'Frühstücksgerichte', '🥐'),
    ('quick', 'Schnell', 'Gerichte unter 30 Minuten', '⚡'),
    ('comfort', 'Hausmannskost', 'Herzhafte Hausmannskost', '🍲');

-- Insert default tags
INSERT OR IGNORE INTO tags (name, name_de, type) VALUES
    -- Dietary tags
    ('high-protein', 'High-Protein', 'dietary'),
    ('low-carb', 'Low-Carb', 'dietary'),
    ('low-fat', 'Fettarm', 'dietary'),
    ('gluten-free', 'Glutenfrei', 'dietary'),
    ('dairy-free', 'Laktosefrei', 'dietary'),
    ('keto', 'Keto', 'dietary'),
    ('paleo', 'Paleo', 'dietary'),

    -- Meal type tags
    ('breakfast', 'Frühstück', 'meal_type'),
    ('lunch', 'Mittagessen', 'meal_type'),
    ('dinner', 'Abendessen', 'meal_type'),
    ('snack', 'Snack', 'meal_type'),
    ('dessert', 'Dessert', 'meal_type'),

    -- Cooking method tags
    ('one-pot', 'Ein-Topf', 'cooking_method'),
    ('no-cook', 'Ohne Kochen', 'cooking_method'),
    ('grilled', 'Gegrillt', 'cooking_method'),
    ('baked', 'Gebacken', 'cooking_method'),
    ('fried', 'Gebraten', 'cooking_method'),

    -- Other tags
    ('meal-prep', 'Meal-Prep', 'other'),
    ('budget-friendly', 'Günstig', 'other'),
    ('family-friendly', 'Familienfreundlich', 'other'),
    ('romantic', 'Romantisch', 'other'),
    ('party', 'Party', 'other');
