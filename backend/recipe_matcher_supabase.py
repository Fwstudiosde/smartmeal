"""
Recipe Matcher - Supabase Version
Intelligent matching system for recipes and supermarket deals using Supabase
"""
import re
from typing import List, Dict, Tuple, Optional
from supabase_client import supabase_db


class RecipeMatcherSupabase:
    """Matches recipes with current deals using fuzzy string matching and Supabase"""

    def __init__(self):
        """Initialize the matcher with Supabase client"""
        self.db = supabase_db

    def load_recipes(self) -> List[Dict]:
        """Load all recipes from Supabase"""
        recipes = self.db.get_all_recipes()

        # Transform the category format
        for recipe in recipes:
            if 'categories' in recipe and recipe['categories']:
                category = recipe['categories']
                recipe['category'] = category.get('name')
                recipe['category_de'] = category.get('name_de')
                del recipe['categories']

        return recipes

    def load_recipe_ingredients(self, recipe_id: str) -> List[Dict]:
        """Load ingredients for a specific recipe"""
        return self.db.get_recipe_ingredients(recipe_id)

    def load_recipe_instructions(self, recipe_id: str) -> List[Dict]:
        """Load instructions for a specific recipe"""
        return self.db.get_recipe_instructions(recipe_id)

    def load_recipe_tags(self, recipe_id: str) -> List[Dict]:
        """Load tags for a specific recipe"""
        return self.db.get_recipe_tags(recipe_id)

    def load_ingredient_keywords(self) -> Dict[str, List[Tuple[str, int]]]:
        """
        Load ingredient keywords for matching
        Returns a dict mapping ingredient_name -> [(keyword, priority), ...]
        """
        return self.db.get_ingredient_keywords()

    def has_conflicting_terms(self, product_name: str, ingredient_keywords: List[str]) -> bool:
        """
        Check if product has terms that conflict with ingredient

        For example: If looking for chicken (hähnchen), exclude products with
        schwein, rind, pute, lachs, etc.
        """
        product_lower = product_name.lower()

        # Define meat/protein categories with exclusions
        meat_categories = {
            'hähnchen': ['schwein', 'rind', 'kalb', 'lamm', 'pute', 'ente', 'lachs', 'thun', 'garnele'],
            'chicken': ['schwein', 'rind', 'kalb', 'lamm', 'pute', 'ente', 'lachs', 'thun', 'garnele', 'pork', 'beef'],
            'schwein': ['hähnchen', 'rind', 'kalb', 'lamm', 'pute', 'ente', 'lachs', 'thun', 'garnele', 'chicken'],
            'pork': ['hähnchen', 'rind', 'kalb', 'lamm', 'pute', 'ente', 'lachs', 'thun', 'garnele', 'chicken'],
            'rind': ['hähnchen', 'schwein', 'kalb', 'lamm', 'pute', 'ente', 'lachs', 'thun', 'garnele', 'chicken'],
            'beef': ['hähnchen', 'schwein', 'kalb', 'lamm', 'pute', 'ente', 'lachs', 'thun', 'garnele', 'chicken'],
            'pute': ['hähnchen', 'schwein', 'rind', 'kalb', 'lamm', 'ente', 'lachs', 'thun', 'garnele', 'chicken'],
            'turkey': ['hähnchen', 'schwein', 'rind', 'kalb', 'lamm', 'ente', 'lachs', 'thun', 'garnele', 'chicken'],
            'lachs': ['hähnchen', 'schwein', 'rind', 'kalb', 'lamm', 'pute', 'ente', 'thun', 'garnele'],
            'salmon': ['hähnchen', 'schwein', 'rind', 'kalb', 'lamm', 'pute', 'ente', 'thun', 'garnele', 'chicken'],
            'thun': ['hähnchen', 'schwein', 'rind', 'kalb', 'lamm', 'pute', 'ente', 'lachs', 'garnele'],
            'tuna': ['hähnchen', 'schwein', 'rind', 'kalb', 'lamm', 'pute', 'ente', 'lachs', 'garnele', 'chicken'],
        }

        # Check if any ingredient keyword has conflicting terms
        for ing_keyword in ingredient_keywords:
            ing_lower = ing_keyword.lower()
            if ing_lower in meat_categories:
                # Check if product contains any conflicting terms
                exclusions = meat_categories[ing_lower]
                for exclusion in exclusions:
                    if exclusion in product_lower:
                        return True

        return False

    def match_ingredient_to_deals(
        self,
        ingredient_name: str,
        keywords: List[Tuple[str, int]],
        deals: List[Dict],
        threshold: int = 70
    ) -> List[Tuple[Dict, int, int]]:
        """
        Match a single ingredient to available deals

        Args:
            ingredient_name: Name of the ingredient
            keywords: List of (keyword, priority) tuples for this ingredient
            deals: List of available deals
            threshold: Minimum fuzzy match score (0-100)

        Returns:
            List of (deal, match_score, priority) tuples
        """
        matches = []

        # Extract just the keyword strings for conflict checking
        keyword_strings = [kw for kw, _ in keywords]

        for deal in deals:
            product_name = deal.get('product_name', '').lower()
            description = deal.get('description', '').lower()
            combined_text = f"{product_name} {description}"

            # Check for conflicting terms FIRST
            if self.has_conflicting_terms(product_name, keyword_strings):
                continue  # Skip this deal entirely

            # Try matching each keyword
            best_score = 0
            best_priority = 0

            for keyword, priority in keywords:
                keyword_lower = keyword.lower()

                # STRICT: ONLY exact substring matching - NO fuzzy matching!
                # For very short keywords (1-2 chars), require word boundaries
                if len(keyword_lower) <= 2:
                    # Short keywords need word boundaries to avoid false matches
                    # e.g., "ei" should match "ei" or "eier" but not "meica"
                    pattern = r'\b' + re.escape(keyword_lower)
                    if re.search(pattern, product_name):
                        score = 100
                        if score > best_score or (score == best_score and priority > best_priority):
                            best_score = score
                            best_priority = priority
                else:
                    # Longer keywords can use simple substring matching
                    if keyword_lower in product_name:
                        score = 100
                        if score > best_score or (score == best_score and priority > best_priority):
                            best_score = score
                            best_priority = priority

            # Only add if we found an EXACT match (no threshold, must be exact)
            if best_score > 0:
                matches.append((deal, best_score, best_priority))

        # Sort by match score (descending)
        matches.sort(key=lambda x: x[1], reverse=True)

        return matches

    def calculate_recipe_score(
        self,
        recipe_ingredients: List[Dict],
        matched_ingredients: Dict[str, List[Tuple[Dict, int, int]]]
    ) -> Tuple[float, Dict]:
        """
        Calculate overall match score for a recipe

        Args:
            recipe_ingredients: List of ingredients for the recipe
            matched_ingredients: Dict mapping ingredient_name -> [(deal, score, priority), ...]

        Returns:
            Tuple of (overall_score, score_breakdown)
        """
        total_ingredients = len(recipe_ingredients)
        optional_ingredients = sum(1 for ing in recipe_ingredients if ing.get('is_optional'))
        required_ingredients = total_ingredients - optional_ingredients

        matched_count = len(matched_ingredients)

        # Count matched ingredients by priority
        priority_3_matched = 0  # Must have
        priority_2_matched = 0  # Important
        priority_1_matched = 0  # Optional/Nice to have

        total_match_quality = 0

        for ingredient_name, matches in matched_ingredients.items():
            if matches:
                # Take the best match
                best_match = matches[0]
                deal, match_score, priority = best_match

                # Track by priority
                if priority == 3:
                    priority_3_matched += 1
                elif priority == 2:
                    priority_2_matched += 1
                else:
                    priority_1_matched += 1

                # Quality score weighted by priority and match score
                total_match_quality += (priority * match_score)

        # Calculate coverage percentage
        if total_ingredients > 0:
            coverage_percentage = (matched_count / total_ingredients) * 100
        else:
            coverage_percentage = 0

        # Calculate weighted score
        # Formula: (priority_3 * 3 + priority_2 * 2 + priority_1 * 1) + coverage_bonus + quality_bonus
        priority_score = (priority_3_matched * 3) + (priority_2_matched * 2) + (priority_1_matched * 1)
        coverage_bonus = coverage_percentage / 10  # Max 10 points
        quality_bonus = total_match_quality / 1000  # Normalize match quality

        overall_score = priority_score + coverage_bonus + quality_bonus

        score_breakdown = {
            "total_ingredients": total_ingredients,
            "required_ingredients": required_ingredients,
            "optional_ingredients": optional_ingredients,
            "matched_count": matched_count,
            "coverage_percentage": round(coverage_percentage, 1),
            "priority_3_matched": priority_3_matched,
            "priority_2_matched": priority_2_matched,
            "priority_1_matched": priority_1_matched,
            "priority_score": priority_score,
            "coverage_bonus": round(coverage_bonus, 1),
            "quality_bonus": round(quality_bonus, 1),
            "overall_score": round(overall_score, 2)
        }

        return overall_score, score_breakdown

    def match_recipes_with_deals(
        self,
        deals: List[Dict],
        min_coverage_percentage: float = 50.0,
        match_threshold: int = 70
    ) -> List[Dict]:
        """
        Match all recipes with current deals

        Args:
            deals: List of available deals
            min_coverage_percentage: Minimum percentage of ingredients that must have deals
            match_threshold: Minimum fuzzy match score (0-100)

        Returns:
            List of recipes with their matched deals, sorted by match score
        """
        # Load data
        recipes = self.load_recipes()
        keywords_map = self.load_ingredient_keywords()

        matched_recipes = []

        for recipe in recipes:
            recipe_id = recipe['id']

            # Load recipe details
            ingredients = self.load_recipe_ingredients(recipe_id)

            if not ingredients:
                continue

            # Match each ingredient to deals
            matched_ingredients = {}

            for ingredient in ingredients:
                ingredient_name = ingredient['ingredient_name']

                # Get keywords for this ingredient
                keywords = keywords_map.get(ingredient_name, [(ingredient_name, 1)])

                # Find matching deals
                matches = self.match_ingredient_to_deals(
                    ingredient_name,
                    keywords,
                    deals,
                    threshold=match_threshold
                )

                if matches:
                    matched_ingredients[ingredient_name] = matches

            # Calculate score
            overall_score, score_breakdown = self.calculate_recipe_score(
                ingredients,
                matched_ingredients
            )

            # Filter by minimum coverage
            if score_breakdown['coverage_percentage'] >= min_coverage_percentage:
                # Build matched deals list (take top match for each ingredient)
                matched_deals = []
                for ingredient_name, matches in matched_ingredients.items():
                    if matches:
                        deal, match_score, priority = matches[0]
                        matched_deals.append({
                            "ingredient_name": ingredient_name,
                            "priority": priority,
                            "match_score": match_score,
                            "deal": deal
                        })

                # Sort matched deals by priority (descending)
                matched_deals.sort(key=lambda x: (x['priority'], x['match_score']), reverse=True)

                # Add full recipe details including instructions
                recipe['ingredients'] = ingredients
                recipe['instructions'] = self.load_recipe_instructions(recipe_id)
                recipe['matched_deals'] = matched_deals
                recipe['match_score'] = overall_score
                recipe['score_breakdown'] = score_breakdown

                matched_recipes.append(recipe)

        # Sort by overall score (descending)
        matched_recipes.sort(key=lambda x: x['match_score'], reverse=True)

        return matched_recipes

    def get_recipe_by_id(self, recipe_id: str) -> Optional[Dict]:
        """Get a single recipe with all its details"""
        recipe = self.db.get_recipe_by_id(recipe_id)

        if not recipe:
            return None

        # Transform category format
        if 'categories' in recipe and recipe['categories']:
            category = recipe['categories']
            recipe['category'] = category.get('name')
            recipe['category_de'] = category.get('name_de')
            del recipe['categories']

        # Add related data
        recipe['ingredients'] = self.load_recipe_ingredients(recipe_id)
        recipe['instructions'] = self.load_recipe_instructions(recipe_id)
        recipe['tags'] = self.load_recipe_tags(recipe_id)

        return recipe

    def get_all_categories(self) -> List[Dict]:
        """Get all recipe categories"""
        return self.db.get_all_categories()

    def get_all_recipes(
        self,
        category: Optional[str] = None,
        limit: Optional[int] = None
    ) -> List[Dict]:
        """
        Get all recipes with their full details (ingredients, instructions)

        Args:
            category: Filter by category name (optional)
            limit: Limit number of results (optional)

        Returns:
            List of recipes with all details
        """
        recipes = self.db.get_all_recipes(category=category, limit=limit)

        # Transform and add details for each recipe
        for recipe in recipes:
            # Transform category format
            if 'categories' in recipe and recipe['categories']:
                category_data = recipe['categories']
                recipe['category'] = category_data.get('name')
                recipe['category_de'] = category_data.get('name_de')
                del recipe['categories']

            recipe_id = recipe['id']
            recipe['ingredients'] = self.load_recipe_ingredients(recipe_id)
            recipe['instructions'] = self.load_recipe_instructions(recipe_id)

        return recipes

    def match_single_recipe_with_deals(
        self,
        recipe: Dict,
        deals: List[Dict],
        min_coverage_percentage: float = 50.0,
        match_threshold: int = 70
    ) -> Optional[Dict]:
        """
        Match a single recipe with current deals

        Args:
            recipe: Recipe dict with id, name, description, ingredients, etc.
            deals: List of available deals
            min_coverage_percentage: Minimum percentage of ingredients that must have deals
            match_threshold: Minimum fuzzy match score (0-100)

        Returns:
            Recipe with matched deals if coverage meets threshold, None otherwise
        """
        ingredients = recipe.get('ingredients', [])

        if not ingredients:
            return None

        keywords_map = self.load_ingredient_keywords()

        # Match each ingredient to deals
        matched_ingredients = {}

        for ingredient in ingredients:
            # Handle both dict format (from custom recipes) and the standard format
            if isinstance(ingredient, dict):
                ingredient_name = ingredient.get('ingredient_name') or ingredient.get('name')
            else:
                ingredient_name = str(ingredient)

            if not ingredient_name:
                continue

            # Get keywords for this ingredient
            keywords = keywords_map.get(ingredient_name, [(ingredient_name, 1)])

            # Find matching deals
            matches = self.match_ingredient_to_deals(
                ingredient_name,
                keywords,
                deals,
                threshold=match_threshold
            )

            if matches:
                matched_ingredients[ingredient_name] = matches

        # Calculate score
        overall_score, score_breakdown = self.calculate_recipe_score(
            ingredients,
            matched_ingredients
        )

        # Filter by minimum coverage
        if score_breakdown['coverage_percentage'] < min_coverage_percentage:
            return None

        # Build matched deals list (take top match for each ingredient)
        matched_deals = []
        total_savings = 0.0

        for ingredient_name, matches in matched_ingredients.items():
            if matches:
                deal, match_score, priority = matches[0]

                # Calculate savings if deal has price info
                savings = 0.0
                if 'discount_percentage' in deal and 'price' in deal:
                    original_price = deal['price'] / (1 - deal['discount_percentage'] / 100)
                    savings = original_price - deal['price']

                total_savings += savings

                matched_deals.append({
                    "ingredient_name": ingredient_name,
                    "priority": priority,
                    "match_score": match_score,
                    "deal": deal,
                    "savings": round(savings, 2)
                })

        # Sort matched deals by priority (descending)
        matched_deals.sort(key=lambda x: (x['priority'], x['match_score']), reverse=True)

        # Return recipe with match info
        result = recipe.copy()
        result['matched_deals'] = matched_deals
        result['match_score'] = overall_score
        result['score_breakdown'] = score_breakdown
        result['total_savings'] = round(total_savings, 2)

        return result
