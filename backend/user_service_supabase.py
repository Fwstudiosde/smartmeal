import uuid
from datetime import datetime
from typing import Optional, Dict, List
from pydantic import BaseModel, EmailStr
from auth import get_password_hash, verify_password
from supabase_client import supabase_db


class UserCreate(BaseModel):
    email: EmailStr
    password: str
    name: Optional[str] = None


class UserResponse(BaseModel):
    id: str
    email: str
    name: Optional[str]
    created_at: str


class UserServiceSupabase:
    def __init__(self):
        self.db = supabase_db

    def create_user(self, user_data: UserCreate) -> Dict:
        """Create a new user"""
        # Check if user already exists
        existing_user = self.db.get_user_by_email(user_data.email)
        if existing_user:
            raise ValueError("User with this email already exists")

        # Create new user
        user_id = str(uuid.uuid4())
        password_hash = get_password_hash(user_data.password)
        now = datetime.now().isoformat()

        user_dict = {
            "id": user_id,
            "email": user_data.email,
            "password_hash": password_hash,
            "name": user_data.name,
            "created_at": now,
            "updated_at": now,
        }

        created_user = self.db.create_user(user_dict)

        return {
            "id": user_id,
            "email": user_data.email,
            "name": user_data.name,
            "created_at": now,
        }

    def create_or_get_apple_user(
        self, apple_id: str, email: Optional[str], name: Optional[str]
    ) -> Dict:
        """Create or get user by Apple ID"""
        # Check if user with apple_id exists
        user = self.db.get_user_by_apple_id(apple_id)

        if user:
            return {
                "id": user["id"],
                "email": user["email"],
                "name": user["name"],
                "created_at": user["created_at"],
            }

        # Create new user with Apple ID
        user_id = str(uuid.uuid4())
        now = datetime.now().isoformat()

        user_dict = {
            "id": user_id,
            "email": email or f"{apple_id}@apple.privaterelay.com",
            "password_hash": "",  # No password for Apple users
            "name": name,
            "apple_id": apple_id,
            "created_at": now,
            "updated_at": now,
        }

        self.db.create_user(user_dict)

        return {
            "id": user_id,
            "email": email or f"{apple_id}@apple.privaterelay.com",
            "name": name,
            "created_at": now,
        }

    def authenticate_user(self, email: str, password: str) -> Optional[Dict]:
        """Authenticate user with email and password"""
        user = self.db.get_user_by_email(email)

        if not user:
            return None

        # Verify password
        if not verify_password(password, user["password_hash"]):
            return None

        return {
            "id": user["id"],
            "email": user["email"],
            "name": user["name"],
            "created_at": user["created_at"],
        }

    def get_user_by_id(self, user_id: str) -> Optional[Dict]:
        """Get user by ID"""
        user = self.db.get_user_by_id(user_id)

        if not user:
            return None

        return {
            "id": user["id"],
            "email": user["email"],
            "name": user["name"],
            "created_at": user["created_at"],
        }

    def get_user_by_email(self, email: str) -> Optional[Dict]:
        """Get user by email"""
        user = self.db.get_user_by_email(email)

        if not user:
            return None

        return {
            "id": user["id"],
            "email": user["email"],
            "name": user["name"],
            "created_at": user["created_at"],
        }

    # ==== MEAL PLAN METHODS ====

    def create_meal_plan(self, user_id: str, week_start: str) -> str:
        """Create a meal plan for a user"""
        meal_plan_id = str(uuid.uuid4())
        now = datetime.now().isoformat()

        meal_plan_data = {
            "id": meal_plan_id,
            "user_id": user_id,
            "week_start": week_start,
            "created_at": now,
            "updated_at": now,
        }

        self.db.create_meal_plan(meal_plan_data)
        return meal_plan_id

    def get_meal_plans_for_user(self, user_id: str) -> List[Dict]:
        """Get all meal plans for a user"""
        return self.db.get_meal_plans_by_user(user_id)

    def get_meal_plan_by_week(self, user_id: str, week_start: str) -> Optional[Dict]:
        """Get meal plan for a specific week"""
        return self.db.get_meal_plan_by_week(user_id, week_start)

    def add_planned_meal(
        self,
        meal_plan_id: str,
        recipe_id: str,
        date: str,
        meal_type: str,
        servings: int = 2,
    ) -> str:
        """Add a planned meal to a meal plan"""
        planned_meal_id = str(uuid.uuid4())
        now = datetime.now().isoformat()

        planned_meal_data = {
            "id": planned_meal_id,
            "meal_plan_id": meal_plan_id,
            "recipe_id": recipe_id,
            "date": date,
            "meal_type": meal_type,
            "servings": servings,
            "is_cooked": False,
            "created_at": now,
        }

        self.db.add_planned_meal(planned_meal_data)
        return planned_meal_id

    def get_planned_meals(self, meal_plan_id: str) -> List[Dict]:
        """Get all planned meals for a meal plan"""
        return self.db.get_planned_meals(meal_plan_id)

    def update_meal_servings(self, planned_meal_id: str, servings: int):
        """Update servings for a planned meal"""
        self.db.update_meal_servings(planned_meal_id, servings)

    def toggle_meal_cooked(self, planned_meal_id: str):
        """Toggle is_cooked status for a planned meal"""
        self.db.toggle_meal_cooked(planned_meal_id)

    def delete_planned_meal(self, planned_meal_id: str):
        """Delete a planned meal"""
        self.db.delete_planned_meal(planned_meal_id)

    # ==== CUSTOM RECIPES METHODS ====

    def create_custom_recipe(
        self,
        user_id: str,
        name: str,
        description: str,
        prep_time: int,
        cook_time: int,
        servings: int,
        difficulty: str,
        ingredients: List[tuple],  # [(name, quantity, unit), ...]
        instructions: List[str],
        image_url: Optional[str] = None,
        calories: Optional[int] = None,
        protein: Optional[float] = None,
        carbs: Optional[float] = None,
        fat: Optional[float] = None,
    ) -> str:
        """Create a custom recipe for a user"""
        recipe_id = str(uuid.uuid4())
        now = datetime.now().isoformat()

        # Insert main recipe
        recipe_data = {
            "id": recipe_id,
            "user_id": user_id,
            "name": name,
            "description": description,
            "prep_time": prep_time,
            "cook_time": cook_time,
            "servings": servings,
            "difficulty": difficulty,
            "image_url": image_url,
            "calories": calories,
            "protein": protein,
            "carbs": carbs,
            "fat": fat,
            "created_at": now,
        }

        self.db.create_custom_recipe(recipe_data)

        # Insert ingredients
        for idx, (ing_name, quantity, unit) in enumerate(ingredients):
            ingredient_data = {
                "recipe_id": recipe_id,
                "ingredient_name": ing_name,
                "quantity": quantity,
                "unit": unit,
                "ingredient_order": idx + 1,
            }
            self.db.create_custom_recipe_ingredient(ingredient_data)

        # Insert instructions
        for step_num, instruction in enumerate(instructions):
            instruction_data = {
                "recipe_id": recipe_id,
                "step_number": step_num + 1,
                "instruction": instruction,
            }
            self.db.create_custom_recipe_instruction(instruction_data)

        return recipe_id

    def get_custom_recipes(self, user_id: str) -> List[Dict]:
        """Get all custom recipes for a user with ingredients and instructions"""
        recipes = self.db.get_custom_recipes_by_user(user_id)

        for recipe in recipes:
            recipe_id = recipe["id"]

            # Get ingredients
            ingredients = self.db.get_custom_recipe_ingredients(recipe_id)
            recipe["ingredients"] = ingredients

            # Get instructions
            instructions = self.db.get_custom_recipe_instructions(recipe_id)
            recipe["instructions"] = instructions

        return recipes

    def delete_custom_recipe(self, recipe_id: str, user_id: str):
        """Delete a custom recipe (only if owned by user)"""
        self.db.delete_custom_recipe(recipe_id, user_id)
