"""
Data Migration Script: SQLite + JSON → Supabase
=================================================
This script exports data from local SQLite databases and JSON files,
then imports it into Supabase PostgreSQL database.

Requirements:
    pip install supabase python-dotenv

Usage:
    1. Create a .env file with your Supabase credentials:
       SUPABASE_URL=https://your-project.supabase.co
       SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

    2. Run the migration:
       python migrate_to_supabase.py
"""

import sqlite3
import json
import os
import sys
from datetime import datetime
from typing import Dict, List, Any
from supabase import create_client, Client
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

# Database paths
RECIPES_DB = "database/recipes.db"
DEALS_JSON = "deals_cache.json"


class SupabaseMigration:
    def __init__(self):
        if not SUPABASE_URL or not SUPABASE_KEY:
            raise ValueError(
                "Missing Supabase credentials! Please set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in .env"
            )

        self.supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
        print(f"✓ Connected to Supabase: {SUPABASE_URL}")

    def export_categories(self) -> List[Dict]:
        """Export categories from SQLite"""
        conn = sqlite3.connect(RECIPES_DB)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()

        cursor.execute("SELECT id, name, name_de, description, icon FROM categories")
        categories = [dict(row) for row in cursor.fetchall()]
        conn.close()

        print(f"✓ Exported {len(categories)} categories from SQLite")
        return categories

    def export_tags(self) -> List[Dict]:
        """Export tags from SQLite"""
        conn = sqlite3.connect(RECIPES_DB)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()

        cursor.execute("SELECT id, name, name_de, type FROM tags")
        tags = [dict(row) for row in cursor.fetchall()]
        conn.close()

        print(f"✓ Exported {len(tags)} tags from SQLite")
        return tags

    def export_recipes(self) -> List[Dict]:
        """Export recipes from SQLite"""
        conn = sqlite3.connect(RECIPES_DB)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()

        cursor.execute("""
            SELECT
                id, name, description, image_url,
                prep_time, cook_time, servings, difficulty,
                category_id, calories, protein, carbs, fat, fiber
            FROM recipes
        """)
        recipes = [dict(row) for row in cursor.fetchall()]
        conn.close()

        print(f"✓ Exported {len(recipes)} recipes from SQLite")
        return recipes

    def export_recipe_tags(self) -> List[Dict]:
        """Export recipe-tag relationships from SQLite"""
        conn = sqlite3.connect(RECIPES_DB)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()

        cursor.execute("SELECT recipe_id, tag_id FROM recipe_tags")
        recipe_tags = [dict(row) for row in cursor.fetchall()]
        conn.close()

        print(f"✓ Exported {len(recipe_tags)} recipe-tag relationships from SQLite")
        return recipe_tags

    def export_ingredients(self) -> List[Dict]:
        """Export recipe ingredients from SQLite"""
        conn = sqlite3.connect(RECIPES_DB)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()

        cursor.execute("""
            SELECT
                recipe_id, ingredient_name, quantity, unit,
                is_optional, ingredient_order
            FROM recipe_ingredients
            ORDER BY recipe_id, ingredient_order
        """)
        ingredients = [dict(row) for row in cursor.fetchall()]
        conn.close()

        print(f"✓ Exported {len(ingredients)} ingredients from SQLite")
        return ingredients

    def export_instructions(self) -> List[Dict]:
        """Export recipe instructions from SQLite"""
        conn = sqlite3.connect(RECIPES_DB)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()

        cursor.execute("""
            SELECT recipe_id, step_number, instruction
            FROM recipe_instructions
            ORDER BY recipe_id, step_number
        """)
        instructions = [dict(row) for row in cursor.fetchall()]
        conn.close()

        print(f"✓ Exported {len(instructions)} instructions from SQLite")
        return instructions

    def export_ingredient_keywords(self) -> List[Dict]:
        """Export ingredient keywords from SQLite"""
        conn = sqlite3.connect(RECIPES_DB)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()

        cursor.execute("""
            SELECT ingredient_name, keyword, priority
            FROM ingredient_keywords
        """)
        keywords = [dict(row) for row in cursor.fetchall()]
        conn.close()

        print(f"✓ Exported {len(keywords)} ingredient keywords from SQLite")
        return keywords

    def export_deals(self) -> List[Dict]:
        """Export deals from JSON file"""
        if not os.path.exists(DEALS_JSON):
            print(f"⚠ No deals file found at {DEALS_JSON}")
            return []

        with open(DEALS_JSON, 'r', encoding='utf-8') as f:
            deals_data = json.load(f)

        deals = []
        for deal in deals_data:
            # Skip deals with missing required fields
            if not deal.get('product_name') or not deal.get('store_name'):
                continue

            # Skip deals with invalid prices
            original_price = deal.get('original_price')
            discount_price = deal.get('discount_price')
            discount_percentage = deal.get('discount_percentage')

            if original_price is None or discount_price is None:
                continue

            # Convert to Supabase format
            deals.append({
                'product_name': deal.get('product_name'),
                'store_name': deal.get('store_name'),
                'store_logo_url': deal.get('store_logo_url'),
                'original_price': float(original_price),
                'discount_price': float(discount_price),
                'discount_percentage': float(discount_percentage) if discount_percentage is not None else 0.0,
                'image_url': deal.get('image_url'),
                'valid_from': deal.get('valid_from'),
                'valid_until': deal.get('valid_until'),
                'category': deal.get('category'),
                'description': deal.get('description'),
            })

        print(f"✓ Exported {len(deals)} deals from JSON")
        return deals

    def import_categories(self, categories: List[Dict]):
        """Import categories to Supabase"""
        if not categories:
            print("⚠ No categories to import")
            return

        result = self.supabase.table('categories').insert(categories).execute()
        print(f"✓ Imported {len(categories)} categories to Supabase")

    def import_tags(self, tags: List[Dict]):
        """Import tags to Supabase"""
        if not tags:
            print("⚠ No tags to import")
            return

        result = self.supabase.table('tags').insert(tags).execute()
        print(f"✓ Imported {len(tags)} tags to Supabase")

    def import_recipes(self, recipes: List[Dict]):
        """Import recipes to Supabase"""
        if not recipes:
            print("⚠ No recipes to import")
            return

        # Process in batches of 100 to avoid rate limits
        batch_size = 100
        for i in range(0, len(recipes), batch_size):
            batch = recipes[i:i + batch_size]
            result = self.supabase.table('recipes').insert(batch).execute()
            print(f"✓ Imported batch {i // batch_size + 1} ({len(batch)} recipes)")

        print(f"✓ Imported {len(recipes)} recipes to Supabase")

    def import_recipe_tags(self, recipe_tags: List[Dict]):
        """Import recipe-tag relationships to Supabase"""
        if not recipe_tags:
            print("⚠ No recipe-tag relationships to import")
            return

        result = self.supabase.table('recipe_tags').insert(recipe_tags).execute()
        print(f"✓ Imported {len(recipe_tags)} recipe-tag relationships to Supabase")

    def import_ingredients(self, ingredients: List[Dict]):
        """Import recipe ingredients to Supabase"""
        if not ingredients:
            print("⚠ No ingredients to import")
            return

        # Process in batches
        batch_size = 500
        for i in range(0, len(ingredients), batch_size):
            batch = ingredients[i:i + batch_size]
            result = self.supabase.table('recipe_ingredients').insert(batch).execute()
            print(f"✓ Imported batch {i // batch_size + 1} ({len(batch)} ingredients)")

        print(f"✓ Imported {len(ingredients)} ingredients to Supabase")

    def import_instructions(self, instructions: List[Dict]):
        """Import recipe instructions to Supabase"""
        if not instructions:
            print("⚠ No instructions to import")
            return

        # Process in batches
        batch_size = 500
        for i in range(0, len(instructions), batch_size):
            batch = instructions[i:i + batch_size]
            result = self.supabase.table('recipe_instructions').insert(batch).execute()
            print(f"✓ Imported batch {i // batch_size + 1} ({len(batch)} instructions)")

        print(f"✓ Imported {len(instructions)} instructions to Supabase")

    def import_ingredient_keywords(self, keywords: List[Dict]):
        """Import ingredient keywords to Supabase"""
        if not keywords:
            print("⚠ No ingredient keywords to import")
            return

        result = self.supabase.table('ingredient_keywords').insert(keywords).execute()
        print(f"✓ Imported {len(keywords)} ingredient keywords to Supabase")

    def import_deals(self, deals: List[Dict]):
        """Import deals to Supabase"""
        if not deals:
            print("⚠ No deals to import")
            return

        result = self.supabase.table('deals').insert(deals).execute()
        print(f"✓ Imported {len(deals)} deals to Supabase")

    def clear_existing_data(self):
        """Clear existing data from Supabase tables"""
        print("\n🗑️  CLEARING EXISTING DATA...")

        # Delete in reverse order due to foreign keys
        tables = [
            'recipe_instructions',
            'recipe_ingredients',
            'recipe_tags',
            'ingredient_keywords',
            'deals',
            'recipes',
            'tags',
            'categories',
        ]

        for table in tables:
            try:
                self.supabase.table(table).delete().neq('id', 0).execute()  # Delete all rows
                print(f"✓ Cleared {table}")
            except Exception as e:
                print(f"⚠ Failed to clear {table}: {str(e)}")

    def migrate(self):
        """Run full migration"""
        print("\n" + "=" * 60)
        print("Starting Migration: SQLite + JSON → Supabase")
        print("=" * 60 + "\n")

        try:
            # Clear existing data
            self.clear_existing_data()

            # Export from SQLite
            print("\n📦 EXPORTING DATA FROM SQLite...")
            categories = self.export_categories()
            tags = self.export_tags()
            recipes = self.export_recipes()
            recipe_tags = self.export_recipe_tags()
            ingredients = self.export_ingredients()
            instructions = self.export_instructions()
            keywords = self.export_ingredient_keywords()

            # Export from JSON
            print("\n📦 EXPORTING DATA FROM JSON...")
            deals = self.export_deals()

            # Import to Supabase
            print("\n⬆️  IMPORTING DATA TO SUPABASE...")
            print("Note: Categories and tags must be imported first (foreign key dependencies)")

            self.import_categories(categories)
            self.import_tags(tags)
            self.import_recipes(recipes)
            self.import_recipe_tags(recipe_tags)
            self.import_ingredients(ingredients)
            self.import_instructions(instructions)
            self.import_ingredient_keywords(keywords)
            self.import_deals(deals)

            print("\n" + "=" * 60)
            print("✓ MIGRATION COMPLETE!")
            print("=" * 60)
            print(f"""
Summary:
  - Categories: {len(categories)}
  - Tags: {len(tags)}
  - Recipes: {len(recipes)}
  - Recipe Tags: {len(recipe_tags)}
  - Ingredients: {len(ingredients)}
  - Instructions: {len(instructions)}
  - Keywords: {len(keywords)}
  - Deals: {len(deals)}
""")

        except Exception as e:
            print(f"\n❌ ERROR during migration: {str(e)}")
            import traceback
            traceback.print_exc()
            sys.exit(1)


if __name__ == "__main__":
    print("""
╔════════════════════════════════════════════════════════════╗
║         SmartMeal Data Migration to Supabase              ║
║                                                            ║
║  This script will migrate all data from SQLite and        ║
║  JSON files to your Supabase PostgreSQL database.         ║
╚════════════════════════════════════════════════════════════╝
""")

    # Check if .env exists
    if not os.path.exists(".env"):
        print("❌ ERROR: .env file not found!")
        print("\nPlease create a .env file with:")
        print("  SUPABASE_URL=https://your-project.supabase.co")
        print("  SUPABASE_SERVICE_ROLE_KEY=your-service-role-key")
        print("\nYou can find these values in your Supabase project settings.")
        sys.exit(1)

    # Check if databases exist
    if not os.path.exists(RECIPES_DB):
        print(f"❌ ERROR: Recipe database not found at {RECIPES_DB}")
        sys.exit(1)

    # Confirm before proceeding
    print("\n⚠️  AUTO-RUNNING migration (confirmation skipped for CLI execution)")
    # response = input("\n⚠️  This will INSERT data into Supabase. Continue? (yes/no): ")
    # if response.lower() not in ['yes', 'y']:
    #     print("Migration cancelled.")
    #     sys.exit(0)

    # Run migration
    migration = SupabaseMigration()
    migration.migrate()
