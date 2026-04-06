import sqlite3
import uuid
from datetime import datetime
from typing import Optional, Dict, List
from pathlib import Path
from pydantic import BaseModel, EmailStr
from auth import get_password_hash, verify_password

# Database path
DB_PATH = Path("database/users.db")


class UserCreate(BaseModel):
    email: EmailStr
    password: str
    name: Optional[str] = None


class UserResponse(BaseModel):
    id: str
    email: str
    name: Optional[str]
    created_at: str


class UserService:
    def __init__(self, db_path: Path = DB_PATH):
        self.db_path = db_path

    def _get_connection(self):
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        return conn

    def create_user(self, user_data: UserCreate) -> Dict:
        """Create a new user"""
        conn = self._get_connection()
        cursor = conn.cursor()

        try:
            # Check if user already exists
            cursor.execute("SELECT id FROM users WHERE email = ?", (user_data.email,))
            if cursor.fetchone():
                raise ValueError("User with this email already exists")

            # Create new user
            user_id = str(uuid.uuid4())
            password_hash = get_password_hash(user_data.password)

            cursor.execute(
                """
                INSERT INTO users (id, email, password_hash, name, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                (
                    user_id,
                    user_data.email,
                    password_hash,
                    user_data.name,
                    datetime.now().isoformat(),
                    datetime.now().isoformat(),
                ),
            )

            conn.commit()

            return {
                "id": user_id,
                "email": user_data.email,
                "name": user_data.name,
                "created_at": datetime.now().isoformat(),
            }

        finally:
            conn.close()

    def create_or_get_apple_user(self, apple_id: str, email: Optional[str], name: Optional[str]) -> Dict:
        """Create or get user by Apple ID"""
        conn = self._get_connection()
        cursor = conn.cursor()

        try:
            # Check if user with apple_id exists
            cursor.execute(
                "SELECT id, email, name, created_at FROM users WHERE apple_id = ?",
                (apple_id,),
            )
            user = cursor.fetchone()

            if user:
                return {
                    "id": user["id"],
                    "email": user["email"],
                    "name": user["name"],
                    "created_at": user["created_at"],
                }

            # Create new user with Apple ID
            user_id = str(uuid.uuid4())

            cursor.execute(
                """
                INSERT INTO users (id, email, password_hash, name, apple_id, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    user_id,
                    email or f"{apple_id}@apple.privaterelay.com",
                    "",  # No password for Apple users
                    name,
                    apple_id,
                    datetime.now().isoformat(),
                    datetime.now().isoformat(),
                ),
            )

            conn.commit()

            return {
                "id": user_id,
                "email": email or f"{apple_id}@apple.privaterelay.com",
                "name": name,
                "created_at": datetime.now().isoformat(),
            }

        finally:
            conn.close()

    def authenticate_user(self, email: str, password: str) -> Optional[Dict]:
        """Authenticate user with email and password"""
        conn = self._get_connection()
        cursor = conn.cursor()

        try:
            cursor.execute(
                "SELECT id, email, password_hash, name, created_at FROM users WHERE email = ?",
                (email,),
            )
            user = cursor.fetchone()

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

        finally:
            conn.close()

    def get_user_by_id(self, user_id: str) -> Optional[Dict]:
        """Get user by ID"""
        conn = self._get_connection()
        cursor = conn.cursor()

        try:
            cursor.execute(
                "SELECT id, email, name, created_at FROM users WHERE id = ?",
                (user_id,),
            )
            user = cursor.fetchone()

            if not user:
                return None

            return {
                "id": user["id"],
                "email": user["email"],
                "name": user["name"],
                "created_at": user["created_at"],
            }

        finally:
            conn.close()

    def get_user_by_email(self, email: str) -> Optional[Dict]:
        """Get user by email"""
        conn = self._get_connection()
        cursor = conn.cursor()

        try:
            cursor.execute(
                "SELECT id, email, name, created_at FROM users WHERE email = ?",
                (email,),
            )
            user = cursor.fetchone()

            if not user:
                return None

            return {
                "id": user["id"],
                "email": user["email"],
                "name": user["name"],
                "created_at": user["created_at"],
            }

        finally:
            conn.close()

    # ==== MEAL PLAN METHODS ====

    def create_meal_plan(self, user_id: str, week_start: str) -> str:
        """Create a meal plan for a user"""
        conn = self._get_connection()
        cursor = conn.cursor()

        try:
            meal_plan_id = str(uuid.uuid4())

            cursor.execute(
                """
                INSERT INTO meal_plans (id, user_id, week_start, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?)
                """,
                (
                    meal_plan_id,
                    user_id,
                    week_start,
                    datetime.now().isoformat(),
                    datetime.now().isoformat(),
                ),
            )

            conn.commit()
            return meal_plan_id

        finally:
            conn.close()

    def get_meal_plans_for_user(self, user_id: str) -> List[Dict]:
        """Get all meal plans for a user"""
        conn = self._get_connection()
        cursor = conn.cursor()

        try:
            cursor.execute(
                "SELECT * FROM meal_plans WHERE user_id = ? ORDER BY week_start DESC",
                (user_id,),
            )
            plans = cursor.fetchall()

            return [dict(plan) for plan in plans]

        finally:
            conn.close()

    def get_meal_plan_by_week(self, user_id: str, week_start: str) -> Optional[Dict]:
        """Get meal plan for a specific week"""
        conn = self._get_connection()
        cursor = conn.cursor()

        try:
            cursor.execute(
                "SELECT * FROM meal_plans WHERE user_id = ? AND week_start = ?",
                (user_id, week_start),
            )
            plan = cursor.fetchone()

            if not plan:
                return None

            return dict(plan)

        finally:
            conn.close()

    def add_planned_meal(
        self,
        meal_plan_id: str,
        recipe_id: str,
        date: str,
        meal_type: str,
        servings: int = 2,
    ) -> str:
        """Add a planned meal to a meal plan"""
        conn = self._get_connection()
        cursor = conn.cursor()

        try:
            planned_meal_id = str(uuid.uuid4())

            cursor.execute(
                """
                INSERT INTO planned_meals (id, meal_plan_id, recipe_id, date, meal_type, servings, is_cooked, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    planned_meal_id,
                    meal_plan_id,
                    recipe_id,
                    date,
                    meal_type,
                    servings,
                    False,
                    datetime.now().isoformat(),
                ),
            )

            conn.commit()
            return planned_meal_id

        finally:
            conn.close()

    def get_planned_meals(self, meal_plan_id: str) -> List[Dict]:
        """Get all planned meals for a meal plan"""
        conn = self._get_connection()
        cursor = conn.cursor()

        try:
            cursor.execute(
                "SELECT * FROM planned_meals WHERE meal_plan_id = ? ORDER BY date, meal_type",
                (meal_plan_id,),
            )
            meals = cursor.fetchall()

            return [dict(meal) for meal in meals]

        finally:
            conn.close()

    def update_meal_servings(self, planned_meal_id: str, servings: int):
        """Update servings for a planned meal"""
        conn = self._get_connection()
        cursor = conn.cursor()

        try:
            cursor.execute(
                "UPDATE planned_meals SET servings = ? WHERE id = ?",
                (servings, planned_meal_id),
            )
            conn.commit()

        finally:
            conn.close()

    def toggle_meal_cooked(self, planned_meal_id: str):
        """Toggle is_cooked status for a planned meal"""
        conn = self._get_connection()
        cursor = conn.cursor()

        try:
            cursor.execute(
                "UPDATE planned_meals SET is_cooked = NOT is_cooked WHERE id = ?",
                (planned_meal_id,),
            )
            conn.commit()

        finally:
            conn.close()

    def delete_planned_meal(self, planned_meal_id: str):
        """Delete a planned meal"""
        conn = self._get_connection()
        cursor = conn.cursor()

        try:
            cursor.execute("DELETE FROM planned_meals WHERE id = ?", (planned_meal_id,))
            conn.commit()

        finally:
            conn.close()

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
        fat: Optional[float] = None
    ) -> str:
        """Create a custom recipe for a user"""
        conn = self._get_connection()
        cursor = conn.cursor()

        try:
            recipe_id = str(uuid.uuid4())

            # Insert main recipe
            cursor.execute(
                """
                INSERT INTO custom_recipes (
                    id, user_id, name, description, prep_time, cook_time,
                    servings, difficulty, image_url, calories, protein, carbs, fat, created_at
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    recipe_id,
                    user_id,
                    name,
                    description,
                    prep_time,
                    cook_time,
                    servings,
                    difficulty,
                    image_url,
                    calories,
                    protein,
                    carbs,
                    fat,
                    datetime.now().isoformat()
                )
            )

            # Insert ingredients
            for idx, (ing_name, quantity, unit) in enumerate(ingredients):
                cursor.execute(
                    """
                    INSERT INTO custom_recipe_ingredients (
                        recipe_id, ingredient_name, quantity, unit, ingredient_order
                    )
                    VALUES (?, ?, ?, ?, ?)
                    """,
                    (recipe_id, ing_name, quantity, unit, idx + 1)
                )

            # Insert instructions
            for step_num, instruction in enumerate(instructions):
                cursor.execute(
                    """
                    INSERT INTO custom_recipe_instructions (
                        recipe_id, step_number, instruction
                    )
                    VALUES (?, ?, ?)
                    """,
                    (recipe_id, step_num + 1, instruction)
                )

            conn.commit()
            return recipe_id

        finally:
            conn.close()

    def get_custom_recipes(self, user_id: str) -> List[Dict]:
        """Get all custom recipes for a user with ingredients and instructions"""
        conn = self._get_connection()
        cursor = conn.cursor()

        try:
            # Get all custom recipes for the user
            cursor.execute(
                """
                SELECT id, name, description, prep_time, cook_time, servings,
                       difficulty, image_url, calories, protein, carbs, fat, created_at
                FROM custom_recipes
                WHERE user_id = ?
                ORDER BY created_at DESC
                """,
                (user_id,)
            )

            recipes = []
            for row in cursor.fetchall():
                recipe = dict(row)
                recipe_id = recipe['id']

                # Get ingredients
                cursor.execute(
                    """
                    SELECT ingredient_name, quantity, unit
                    FROM custom_recipe_ingredients
                    WHERE recipe_id = ?
                    ORDER BY ingredient_order
                    """,
                    (recipe_id,)
                )
                recipe['ingredients'] = [dict(ing) for ing in cursor.fetchall()]

                # Get instructions
                cursor.execute(
                    """
                    SELECT instruction
                    FROM custom_recipe_instructions
                    WHERE recipe_id = ?
                    ORDER BY step_number
                    """,
                    (recipe_id,)
                )
                recipe['instructions'] = [row['instruction'] for row in cursor.fetchall()]

                recipes.append(recipe)

            return recipes

        finally:
            conn.close()

    def delete_custom_recipe(self, recipe_id: str, user_id: str):
        """Delete a custom recipe (only if owned by user)"""
        conn = self._get_connection()
        cursor = conn.cursor()

        try:
            # Verify ownership
            cursor.execute(
                "SELECT id FROM custom_recipes WHERE id = ? AND user_id = ?",
                (recipe_id, user_id)
            )

            if not cursor.fetchone():
                raise ValueError("Recipe not found or not owned by user")

            # Delete instructions
            cursor.execute(
                "DELETE FROM custom_recipe_instructions WHERE recipe_id = ?",
                (recipe_id,)
            )

            # Delete ingredients
            cursor.execute(
                "DELETE FROM custom_recipe_ingredients WHERE recipe_id = ?",
                (recipe_id,)
            )

            # Delete recipe
            cursor.execute("DELETE FROM custom_recipes WHERE id = ?", (recipe_id,))

            conn.commit()

        finally:
            conn.close()
