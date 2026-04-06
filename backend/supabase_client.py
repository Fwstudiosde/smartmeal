"""
Supabase Client Wrapper
Provides database access using Supabase instead of SQLite
"""
import os
from typing import List, Dict, Optional, Any
from supabase import create_client, Client
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")


class SupabaseClient:
    """Wrapper for Supabase database operations"""

    def __init__(self):
        if not SUPABASE_URL or not SUPABASE_KEY:
            raise ValueError(
                "Missing Supabase credentials! Please set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in .env"
            )

        self.client: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

    # ========== RECIPE METHODS ==========

    def get_all_recipes(self, category: Optional[str] = None, limit: Optional[int] = None) -> List[Dict]:
        """Get all recipes with optional filtering"""
        query = self.client.table('recipes').select('''
            id,
            name,
            description,
            image_url,
            prep_time,
            cook_time,
            servings,
            difficulty,
            calories,
            protein,
            carbs,
            fat,
            fiber,
            created_at,
            updated_at,
            categories(name, name_de)
        ''')

        if category:
            # Filter by category name or name_de
            query = query.or_(f'categories.name.eq.{category},categories.name_de.eq.{category}')

        if limit:
            query = query.limit(limit)

        result = query.execute()
        return result.data

    def get_recipe_by_id(self, recipe_id: str) -> Optional[Dict]:
        """Get a single recipe with all details"""
        result = self.client.table('recipes').select('''
            id,
            name,
            description,
            image_url,
            prep_time,
            cook_time,
            servings,
            difficulty,
            calories,
            protein,
            carbs,
            fat,
            fiber,
            categories(name, name_de)
        ''').eq('id', recipe_id).execute()

        if not result.data:
            return None

        return result.data[0]

    def get_recipe_ingredients(self, recipe_id: str) -> List[Dict]:
        """Get ingredients for a recipe"""
        result = self.client.table('recipe_ingredients').select(
            'ingredient_name, quantity, unit, is_optional, ingredient_order'
        ).eq('recipe_id', recipe_id).order('ingredient_order').execute()

        return result.data

    def get_recipe_instructions(self, recipe_id: str) -> List[Dict]:
        """Get instructions for a recipe"""
        result = self.client.table('recipe_instructions').select(
            'step_number, instruction'
        ).eq('recipe_id', recipe_id).order('step_number').execute()

        return result.data

    def get_recipe_tags(self, recipe_id: str) -> List[Dict]:
        """Get tags for a recipe"""
        result = self.client.table('recipe_tags').select('''
            tags(name, name_de, type)
        ''').eq('recipe_id', recipe_id).execute()

        # Flatten the nested structure
        tags = []
        for row in result.data:
            if 'tags' in row and row['tags']:
                tags.append(row['tags'])

        return tags

    def create_recipe(self, recipe_data: Dict) -> Dict:
        """Create a new recipe"""
        result = self.client.table('recipes').insert(recipe_data).execute()
        return result.data[0] if result.data else None

    def create_recipe_ingredient(self, ingredient_data: Dict) -> None:
        """Add ingredient to recipe"""
        self.client.table('recipe_ingredients').insert(ingredient_data).execute()

    def create_recipe_instruction(self, instruction_data: Dict) -> None:
        """Add instruction to recipe"""
        self.client.table('recipe_instructions').insert(instruction_data).execute()

    def create_recipe_tag(self, tag_data: Dict) -> None:
        """Link tag to recipe"""
        self.client.table('recipe_tags').insert(tag_data).execute()

    # ========== CATEGORY METHODS ==========

    def get_all_categories(self) -> List[Dict]:
        """Get all recipe categories with recipe counts"""
        result = self.client.table('categories').select(
            'id, name, name_de, description, icon'
        ).execute()

        categories = result.data

        # Add recipe counts
        for category in categories:
            count_result = self.client.table('recipes').select(
                'id', count='exact'
            ).eq('category_id', category['id']).execute()

            category['recipe_count'] = count_result.count or 0

        return categories

    # ========== INGREDIENT KEYWORDS ==========

    def get_ingredient_keywords(self) -> Dict[str, List[tuple]]:
        """
        Get ingredient keywords mapping
        Returns dict: ingredient_name -> [(keyword, priority), ...]
        """
        result = self.client.table('ingredient_keywords').select(
            'ingredient_name, keyword, priority'
        ).order('priority', desc=True).execute()

        # Group by ingredient name
        keywords_map = {}
        for row in result.data:
            ingredient = row['ingredient_name']
            keyword = row['keyword']
            priority = row['priority']

            if ingredient not in keywords_map:
                keywords_map[ingredient] = []
            keywords_map[ingredient].append((keyword, priority))

        return keywords_map

    # ========== DEALS METHODS ==========

    def get_all_deals(self, store_name: Optional[str] = None, category: Optional[str] = None) -> List[Dict]:
        """Get all deals with optional filtering"""
        query = self.client.table('deals').select('*')

        if store_name:
            query = query.eq('store_name', store_name)

        if category:
            query = query.eq('category', category)

        result = query.execute()
        return result.data

    def upsert_deals(self, deals: List[Dict]) -> None:
        """Insert or update deals"""
        if not deals:
            return

        # Supabase upsert (insert or update based on unique constraints)
        self.client.table('deals').upsert(deals).execute()

    def delete_all_deals(self) -> None:
        """Delete all deals"""
        self.client.table('deals').delete().neq('id', '00000000-0000-0000-0000-000000000000').execute()

    # ========== SUPERMARKETS METHODS ==========

    def get_all_supermarkets(self) -> List[Dict]:
        """Get all supermarkets"""
        result = self.client.table('supermarkets').select('*').execute()
        return result.data

    # ========== USER METHODS ==========

    def create_user(self, user_data: Dict) -> Dict:
        """Create a new user"""
        result = self.client.table('users').insert(user_data).execute()
        return result.data[0] if result.data else None

    def get_user_by_id(self, user_id: str) -> Optional[Dict]:
        """Get user by ID"""
        result = self.client.table('users').select('*').eq('id', user_id).execute()
        return result.data[0] if result.data else None

    def get_user_by_email(self, email: str) -> Optional[Dict]:
        """Get user by email"""
        result = self.client.table('users').select('*').eq('email', email).execute()
        return result.data[0] if result.data else None

    def get_user_by_apple_id(self, apple_id: str) -> Optional[Dict]:
        """Get user by Apple ID"""
        result = self.client.table('users').select('*').eq('apple_id', apple_id).execute()
        return result.data[0] if result.data else None

    # ========== MEAL PLAN METHODS ==========

    def create_meal_plan(self, meal_plan_data: Dict) -> Dict:
        """Create a meal plan"""
        result = self.client.table('meal_plans').insert(meal_plan_data).execute()
        return result.data[0] if result.data else None

    def get_meal_plans_by_user(self, user_id: str) -> List[Dict]:
        """Get all meal plans for a user"""
        result = self.client.table('meal_plans').select('*').eq(
            'user_id', user_id
        ).order('week_start', desc=True).execute()

        return result.data

    def get_meal_plan_by_week(self, user_id: str, week_start: str) -> Optional[Dict]:
        """Get meal plan for a specific week"""
        result = self.client.table('meal_plans').select('*').eq(
            'user_id', user_id
        ).eq('week_start', week_start).execute()

        return result.data[0] if result.data else None

    def add_planned_meal(self, planned_meal_data: Dict) -> Dict:
        """Add a planned meal"""
        result = self.client.table('planned_meals').insert(planned_meal_data).execute()
        return result.data[0] if result.data else None

    def get_planned_meals(self, meal_plan_id: str) -> List[Dict]:
        """Get all planned meals for a meal plan"""
        result = self.client.table('planned_meals').select('*').eq(
            'meal_plan_id', meal_plan_id
        ).order('date, meal_type').execute()

        return result.data

    def update_meal_servings(self, planned_meal_id: str, servings: int) -> None:
        """Update servings for a planned meal"""
        self.client.table('planned_meals').update(
            {'servings': servings}
        ).eq('id', planned_meal_id).execute()

    def toggle_meal_cooked(self, planned_meal_id: str) -> None:
        """Toggle cooked status for a planned meal"""
        # First get current status
        result = self.client.table('planned_meals').select('is_cooked').eq(
            'id', planned_meal_id
        ).execute()

        if result.data:
            current_status = result.data[0].get('is_cooked', False)
            self.client.table('planned_meals').update(
                {'is_cooked': not current_status}
            ).eq('id', planned_meal_id).execute()

    def delete_planned_meal(self, planned_meal_id: str) -> None:
        """Delete a planned meal"""
        self.client.table('planned_meals').delete().eq('id', planned_meal_id).execute()

    # ========== CUSTOM RECIPES METHODS ==========

    def create_custom_recipe(self, recipe_data: Dict) -> Dict:
        """Create a custom recipe"""
        result = self.client.table('custom_recipes').insert(recipe_data).execute()
        return result.data[0] if result.data else None

    def create_custom_recipe_ingredient(self, ingredient_data: Dict) -> None:
        """Add ingredient to custom recipe"""
        self.client.table('custom_recipe_ingredients').insert(ingredient_data).execute()

    def create_custom_recipe_instruction(self, instruction_data: Dict) -> None:
        """Add instruction to custom recipe"""
        self.client.table('custom_recipe_instructions').insert(instruction_data).execute()

    def get_custom_recipes_by_user(self, user_id: str) -> List[Dict]:
        """Get all custom recipes for a user"""
        result = self.client.table('custom_recipes').select('*').eq(
            'user_id', user_id
        ).order('created_at', desc=True).execute()

        return result.data

    def get_custom_recipe_ingredients(self, recipe_id: str) -> List[Dict]:
        """Get ingredients for a custom recipe"""
        result = self.client.table('custom_recipe_ingredients').select(
            'ingredient_name, quantity, unit'
        ).eq('recipe_id', recipe_id).order('ingredient_order').execute()

        return result.data

    def get_custom_recipe_instructions(self, recipe_id: str) -> List[str]:
        """Get instructions for a custom recipe"""
        result = self.client.table('custom_recipe_instructions').select(
            'instruction'
        ).eq('recipe_id', recipe_id).order('step_number').execute()

        return [row['instruction'] for row in result.data]

    def delete_custom_recipe(self, recipe_id: str, user_id: str) -> None:
        """Delete a custom recipe (with ownership verification)"""
        # Verify ownership first
        result = self.client.table('custom_recipes').select('id').eq(
            'id', recipe_id
        ).eq('user_id', user_id).execute()

        if not result.data:
            raise ValueError("Recipe not found or not owned by user")

        # Delete recipe (cascade will handle ingredients and instructions)
        self.client.table('custom_recipes').delete().eq('id', recipe_id).execute()


# Global instance
supabase_db = SupabaseClient()
