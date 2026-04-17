from fastapi import FastAPI, HTTPException, BackgroundTasks, UploadFile, File, Depends, Form
from fastapi.middleware.cors import CORSMiddleware
from typing import List, Dict, Optional
from datetime import datetime, timedelta
from pydantic import BaseModel
import json
import os
from pathlib import Path
import tempfile
import shutil
import uuid

# Import scrapers
from scrapers.lidl_scraper import LidlScraper
from scrapers.kaufland_scraper import KauflandScraper
from scrapers.aldi_scraper import AldiScraper
from scrapers.rewe_scraper import ReweScraper
from scrapers.edeka_scraper import EdekaScraper
from scrapers.penny_scraper import PennyScraper
from scrapers.netto_scraper import NettoScraper

# Import Chefkoch scraper
from chefkoch_scraper import ChefkochScraper

# Import notification service
from notification_service import send_deal_alerts, send_to_topic, send_to_tokens, send_to_all_users

# Import admin functionality
from auth import (
    authenticate_admin,
    create_access_token,
    require_admin,
    LoginRequest,
    Token,
    ACCESS_TOKEN_EXPIRE_MINUTES,
    get_password_hash,
    verify_password,
    get_current_user_id
)
from ocr_service import DealExtractor

# Import recipe matcher (Supabase version)
from recipe_matcher_supabase import RecipeMatcherSupabase

# Import user service (Supabase version)
from user_service_supabase import UserServiceSupabase, UserCreate

app = FastAPI(
    title="SmartMeal Deals API",
    description="API for scraping supermarket deals",
    version="1.0.0"
)

# CORS middleware for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your Flutter app's origin
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Data storage (in production, use a database)
DEALS_FILE = Path("deals_cache.json")
SCRAPING_STATUS = {
    "is_running": False,
    "last_run": None,
    "last_success": None,
    "error": None
}

# Initialize scrapers
SCRAPERS = {
    "lidl": LidlScraper(),
    "kaufland": KauflandScraper(),
    "aldi": AldiScraper(),
    "rewe": ReweScraper(),
    "edeka": EdekaScraper(),
    "penny": PennyScraper(),
    "netto": NettoScraper(),
}

# Initialize Chefkoch scraper
chefkoch_scraper = ChefkochScraper()

# Initialize recipe matcher (Supabase version)
recipe_matcher = RecipeMatcherSupabase()

# Initialize user service (Supabase version)
user_service = UserServiceSupabase()


def load_deals() -> List[Dict]:
    """Load deals from cache file (includes expired — admin use only)"""
    if DEALS_FILE.exists():
        try:
            with open(DEALS_FILE, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            print(f"Error loading deals: {e}")
    return []


def is_deal_active(deal: Dict, today: Optional[str] = None) -> bool:
    """A deal is active if its valid_until is today or later.
    Deals without valid_until are treated as active (legacy data)."""
    valid_until = deal.get('valid_until')
    if not valid_until:
        return True
    today = today or datetime.utcnow().date().isoformat()
    return str(valid_until)[:10] >= today


def load_active_deals() -> List[Dict]:
    """Load only deals whose valid_until is today or later.
    This is what all user-facing endpoints and recipe matching should use."""
    today = datetime.utcnow().date().isoformat()
    return [d for d in load_deals() if is_deal_active(d, today)]


def remove_duplicate_deals(deals: List[Dict]) -> List[Dict]:
    """
    Remove duplicate deals based on product name, store, and discount price.
    Keeps the first occurrence of each unique deal.
    """
    seen = set()
    unique_deals = []

    for deal in deals:
        # Create a unique key from product name, store, and discount price
        # This handles cases where the same product is uploaded multiple times
        key = (
            deal.get('product_name', '').lower().strip(),
            deal.get('store_name', '').lower().strip(),
            deal.get('discount_price', 0)
        )

        if key not in seen and deal.get('product_name'):  # Only add if has product name
            seen.add(key)
            unique_deals.append(deal)

    removed_count = len(deals) - len(unique_deals)
    if removed_count > 0:
        print(f"Removed {removed_count} duplicate deals")

    return unique_deals


def save_deals(deals: List[Dict]):
    """Save deals to cache file and Supabase after removing duplicates"""
    try:
        # Remove duplicates before saving
        unique_deals = remove_duplicate_deals(deals)

        # Save to local cache file
        with open(DEALS_FILE, 'w', encoding='utf-8') as f:
            json.dump(unique_deals, f, ensure_ascii=False, indent=2)

        print(f"Saved {len(unique_deals)} unique deals to cache")

        # Also persist to Supabase
        _sync_deals_to_supabase(unique_deals)
    except Exception as e:
        print(f"Error saving deals: {e}")


def _sync_deals_to_supabase(deals: List[Dict]):
    """Sync deals to Supabase database"""
    try:
        from supabase_client import SupabaseClient
        db = SupabaseClient()

        # Convert deals to Supabase format
        supabase_deals = []
        for deal in deals:
            supabase_deal = {
                'product_name': deal.get('product_name', ''),
                'store_name': deal.get('store_name', ''),
                'original_price': deal.get('original_price'),
                'discount_price': deal.get('discount_price'),
                'discount_percentage': deal.get('discount_percentage'),
                'valid_from': deal.get('valid_from', datetime.now().isoformat()),
                'valid_until': deal.get('valid_until', (datetime.now() + timedelta(days=7)).isoformat()),
                'category': deal.get('category'),
                'description': deal.get('description'),
                'image_url': deal.get('image_url', ''),
            }
            # Only add deals with valid product names
            if supabase_deal['product_name']:
                supabase_deals.append(supabase_deal)

        if supabase_deals:
            db.upsert_deals(supabase_deals)
            print(f"Synced {len(supabase_deals)} deals to Supabase")
    except Exception as e:
        print(f"Warning: Could not sync deals to Supabase: {e}")
        # Non-fatal - deals are still in local cache


async def scrape_all_stores():
    """Scrape deals from all stores"""
    global SCRAPING_STATUS

    SCRAPING_STATUS["is_running"] = True
    SCRAPING_STATUS["last_run"] = datetime.now().isoformat()
    SCRAPING_STATUS["error"] = None

    all_deals = []

    try:
        for store_name, scraper in SCRAPERS.items():
            print(f"Scraping {store_name}...")
            try:
                deals = await scraper.scrape_deals()
                all_deals.extend(deals)
                print(f"Found {len(deals)} deals from {store_name}")
            except Exception as e:
                print(f"Error scraping {store_name}: {e}")
                SCRAPING_STATUS["error"] = f"{store_name}: {str(e)}"

        # Save to cache
        save_deals(all_deals)

        # Send push notifications for new deals
        if all_deals:
            try:
                sent = await send_deal_alerts(all_deals, supabase_client=None)
                print(f"Sent {sent} deal alert notifications")
            except Exception as e:
                print(f"Error sending deal alerts: {e}")

        SCRAPING_STATUS["last_success"] = datetime.now().isoformat()
        print(f"Scraping completed. Total deals: {len(all_deals)}")

    except Exception as e:
        SCRAPING_STATUS["error"] = str(e)
        print(f"Scraping error: {e}")

    finally:
        SCRAPING_STATUS["is_running"] = False


@app.on_event("startup")
async def startup_event():
    """Run initial scrape on startup"""
    print("Starting SmartMeal Deals API...")

    # Load existing deals
    deals = load_deals()
    print(f"Loaded {len(deals)} deals from cache")

    # Run initial scrape if no cache exists
    if not deals:
        print("No cached deals found. Running initial scrape...")
        await scrape_all_stores()


@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "status": "ok",
        "service": "SmartMeal Deals API",
        "version": "1.0.0",
        "timestamp": datetime.now().isoformat()
    }


@app.get("/api/deals", response_model=List[Dict])
async def get_all_deals(
    store: Optional[str] = None,
    category: Optional[str] = None,
    limit: Optional[int] = None
):
    """
    Get active deals, optionally filtered by store and/or category

    - **store**: Filter by store name (e.g., 'Lidl', 'ALDI')
    - **category**: Filter by category (e.g., 'Fleisch', 'Gemüse')
    - **limit**: Limit number of results
    """
    # Only active deals (valid_until >= today)
    deals = load_active_deals()

    # Apply filters
    if store:
        deals = [d for d in deals if d['store_name'].lower() == store.lower()]

    if category:
        deals = [d for d in deals if d.get('category', '').lower() == category.lower()]

    # Apply limit
    if limit:
        deals = deals[:limit]

    return deals


@app.get("/api/deals/{store_name}", response_model=List[Dict])
async def get_deals_by_store(store_name: str):
    """Get active deals for a specific store"""
    deals = load_active_deals()
    store_deals = [
        d for d in deals
        if d['store_name'].lower() == store_name.lower()
    ]

    if not store_deals:
        raise HTTPException(status_code=404, detail=f"No deals found for {store_name}")

    return store_deals


@app.get("/api/stores")
async def get_stores():
    """Get list of available stores with active deal counts"""
    deals = load_active_deals()

    stores = {}
    for deal in deals:
        store_name = deal['store_name']
        if store_name not in stores:
            stores[store_name] = {
                "name": store_name,
                "deal_count": 0
            }
        stores[store_name]["deal_count"] += 1

    return list(stores.values())


@app.get("/api/categories")
async def get_categories():
    """Get list of product categories with active deal counts"""
    deals = load_active_deals()

    categories = {}
    for deal in deals:
        category = deal.get('category', 'Sonstiges')
        if category not in categories:
            categories[category] = 0
        categories[category] += 1

    return [
        {"name": cat, "deal_count": count}
        for cat, count in categories.items()
    ]


@app.post("/api/scrape")
async def trigger_scrape(background_tasks: BackgroundTasks):
    """Manually trigger scraping process"""
    if SCRAPING_STATUS["is_running"]:
        raise HTTPException(status_code=409, detail="Scraping already in progress")

    background_tasks.add_task(scrape_all_stores)

    return {
        "status": "started",
        "message": "Scraping process started in background"
    }


@app.get("/api/scrape/status")
async def get_scrape_status():
    """Get current scraping status"""
    return SCRAPING_STATUS


@app.get("/api/stats")
async def get_stats():
    """Get statistics about available (active) deals"""
    deals = load_active_deals()

    stats = {
        "total_deals": len(deals),
        "stores": len(set(d['store_name'] for d in deals)),
        "categories": len(set(d.get('category', 'Sonstiges') for d in deals)),
        "average_discount": round(
            sum(d['discount_percentage'] for d in deals) / len(deals) if deals else 0,
            1
        ),
        "last_updated": SCRAPING_STATUS.get("last_success"),
    }

    return stats


# ========================================
# RECIPE ENDPOINTS
# ========================================

@app.get("/api/recipes")
async def get_all_recipes(
    category: Optional[str] = None,
    limit: Optional[int] = None
):
    """
    Get all recipes without requiring deals

    - **category**: Filter by category (optional)
    - **limit**: Limit number of results (optional)

    Returns all recipes from the database
    """
    try:
        recipes = recipe_matcher.get_all_recipes(category=category, limit=limit)

        return {
            "total_recipes": len(recipes),
            "recipes": recipes
        }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving recipes: {str(e)}"
        )


@app.get("/api/recipes/categories")
async def get_recipe_categories():
    """
    Get all recipe categories with recipe counts

    Returns list of categories with their names, descriptions, and number of recipes
    """
    try:
        categories = recipe_matcher.get_all_categories()
        return {
            "total_categories": len(categories),
            "categories": categories
        }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving categories: {str(e)}"
        )


@app.get("/api/recipes/with-deals")
async def get_recipes_with_deals(
    min_coverage: Optional[float] = 50.0,
    match_threshold: Optional[int] = 70,
    limit: Optional[int] = None
):
    """
    Get recipes that have active deals

    - **min_coverage**: Minimum percentage of ingredients that must have deals (default: 50%)
    - **match_threshold**: Minimum fuzzy match score 0-100 (default: 70)
    - **limit**: Limit number of results

    Returns recipes sorted by match score (best matches first)
    """
    try:
        # Only active deals (expired weeks excluded)
        deals = load_active_deals()

        if not deals:
            return {
                "message": "No deals available",
                "recipes": []
            }

        # Match recipes with deals
        matched_recipes = recipe_matcher.match_recipes_with_deals(
            deals=deals,
            min_coverage_percentage=min_coverage,
            match_threshold=match_threshold
        )

        # Apply limit if specified
        if limit:
            matched_recipes = matched_recipes[:limit]

        return {
            "total_matches": len(matched_recipes),
            "total_deals_available": len(deals),
            "filters": {
                "min_coverage_percentage": min_coverage,
                "match_threshold": match_threshold
            },
            "recipes": matched_recipes
        }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error matching recipes with deals: {str(e)}"
        )


@app.get("/api/recipes/{recipe_id}")
async def get_recipe_by_id(recipe_id: str):
    """
    Get a single recipe by ID with full details

    Returns recipe with ingredients, instructions, and tags
    """
    try:
        recipe = recipe_matcher.get_recipe_by_id(recipe_id)

        if not recipe:
            raise HTTPException(
                status_code=404,
                detail=f"Recipe with ID '{recipe_id}' not found"
            )

        return recipe

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving recipe: {str(e)}"
        )


# ========================================
# USER AUTHENTICATION ENDPOINTS
# ========================================

class UserLoginRequest(BaseModel):
    email: str
    password: str


class AppleAuthRequest(BaseModel):
    apple_id: str
    email: Optional[str] = None
    name: Optional[str] = None


@app.post("/api/auth/register", response_model=Token)
async def register(user: UserCreate):
    """Register a new user with email and password"""
    try:
        created_user = user_service.create_user(user)

        # Create access token
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"user_id": created_user["id"]},
            expires_delta=access_token_expires
        )

        return {"access_token": access_token, "token_type": "bearer"}

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Registration failed: {str(e)}")


@app.post("/api/auth/login", response_model=Token)
async def login(credentials: UserLoginRequest):
    """Login with email and password"""
    user = user_service.authenticate_user(credentials.email, credentials.password)

    if not user:
        raise HTTPException(
            status_code=401,
            detail="Incorrect email or password"
        )

    # Create access token
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"user_id": user["id"]},
        expires_delta=access_token_expires
    )

    return {"access_token": access_token, "token_type": "bearer"}


@app.post("/api/auth/apple", response_model=Token)
async def apple_auth(auth: AppleAuthRequest):
    """Authenticate or register with Apple ID"""
    try:
        user = user_service.create_or_get_apple_user(
            apple_id=auth.apple_id,
            email=auth.email,
            name=auth.name
        )

        # Create access token
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"user_id": user["id"]},
            expires_delta=access_token_expires
        )

        return {"access_token": access_token, "token_type": "bearer"}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Apple authentication failed: {str(e)}")


@app.get("/api/auth/me")
async def get_current_user(user_id: str = Depends(get_current_user_id)):
    """Get current user info"""
    user = user_service.get_user_by_id(user_id)

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    return user


# ========================================
# MEAL PLANS ENDPOINTS (USER-SPECIFIC)
# ========================================

class CreateMealPlanRequest(BaseModel):
    week_start: str  # ISO format date


class AddPlannedMealRequest(BaseModel):
    recipe_id: str
    date: str  # ISO format date
    meal_type: str  # breakfast, lunch, dinner, snack
    servings: int = 2


class CustomRecipeIngredient(BaseModel):
    name: str
    quantity: str
    unit: str


class CreateCustomRecipeRequest(BaseModel):
    name: str
    description: str
    prep_time: int
    cook_time: int
    servings: int
    difficulty: str
    ingredients: List[CustomRecipeIngredient]
    instructions: List[str]
    image_url: Optional[str] = None
    calories: Optional[int] = None
    protein: Optional[float] = None
    carbs: Optional[float] = None
    fat: Optional[float] = None


@app.post("/api/meal-plans")
async def create_meal_plan(
    request: CreateMealPlanRequest,
    user_id: str = Depends(get_current_user_id)
):
    """Create a meal plan for the current user"""
    try:
        meal_plan_id = user_service.create_meal_plan(user_id, request.week_start)
        return {"meal_plan_id": meal_plan_id, "week_start": request.week_start}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create meal plan: {str(e)}")


@app.get("/api/meal-plans")
async def get_meal_plans(user_id: str = Depends(get_current_user_id)):
    """Get all meal plans for the current user"""
    try:
        plans = user_service.get_meal_plans_for_user(user_id)
        return {"meal_plans": plans}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get meal plans: {str(e)}")


@app.get("/api/meal-plans/week/{week_start}")
async def get_meal_plan_by_week(
    week_start: str,
    user_id: str = Depends(get_current_user_id)
):
    """Get meal plan for a specific week"""
    try:
        plan = user_service.get_meal_plan_by_week(user_id, week_start)
        if not plan:
            raise HTTPException(status_code=404, detail="Meal plan not found")
        return plan
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get meal plan: {str(e)}")


@app.post("/api/meal-plans/{meal_plan_id}/meals")
async def add_planned_meal(
    meal_plan_id: str,
    request: AddPlannedMealRequest,
    user_id: str = Depends(get_current_user_id)
):
    """Add a meal to a meal plan"""
    try:
        planned_meal_id = user_service.add_planned_meal(
            meal_plan_id=meal_plan_id,
            recipe_id=request.recipe_id,
            date=request.date,
            meal_type=request.meal_type,
            servings=request.servings
        )
        return {"planned_meal_id": planned_meal_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to add planned meal: {str(e)}")


@app.get("/api/meal-plans/{meal_plan_id}/meals")
async def get_planned_meals(
    meal_plan_id: str,
    user_id: str = Depends(get_current_user_id)
):
    """Get all meals for a meal plan"""
    try:
        meals = user_service.get_planned_meals(meal_plan_id)
        return {"meals": meals}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get planned meals: {str(e)}")


@app.put("/api/meal-plans/meals/{planned_meal_id}/servings")
async def update_meal_servings(
    planned_meal_id: str,
    servings: int,
    user_id: str = Depends(get_current_user_id)
):
    """Update servings for a planned meal"""
    try:
        user_service.update_meal_servings(planned_meal_id, servings)
        return {"status": "success"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update servings: {str(e)}")


@app.put("/api/meal-plans/meals/{planned_meal_id}/toggle-cooked")
async def toggle_meal_cooked(
    planned_meal_id: str,
    user_id: str = Depends(get_current_user_id)
):
    """Toggle cooked status for a planned meal"""
    try:
        user_service.toggle_meal_cooked(planned_meal_id)
        return {"status": "success"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to toggle cooked status: {str(e)}")


@app.delete("/api/meal-plans/meals/{planned_meal_id}")
async def delete_planned_meal(
    planned_meal_id: str,
    user_id: str = Depends(get_current_user_id)
):
    """Delete a planned meal"""
    try:
        user_service.delete_planned_meal(planned_meal_id)
        return {"status": "success"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete planned meal: {str(e)}")


# ========================================
# CUSTOM RECIPES ENDPOINTS
# ========================================

@app.post("/api/custom-recipes")
async def create_custom_recipe(
    request: CreateCustomRecipeRequest,
    user_id: str = Depends(get_current_user_id)
):
    """Create a custom recipe for the current user"""
    try:
        recipe_id = user_service.create_custom_recipe(
            user_id=user_id,
            name=request.name,
            description=request.description,
            prep_time=request.prep_time,
            cook_time=request.cook_time,
            servings=request.servings,
            difficulty=request.difficulty,
            ingredients=[(i.name, i.quantity, i.unit) for i in request.ingredients],
            instructions=request.instructions,
            image_url=request.image_url,
            calories=request.calories,
            protein=request.protein,
            carbs=request.carbs,
            fat=request.fat
        )
        return {"recipe_id": recipe_id, "status": "success"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create custom recipe: {str(e)}")


@app.get("/api/custom-recipes")
async def get_custom_recipes(user_id: str = Depends(get_current_user_id)):
    """Get all custom recipes for the current user"""
    try:
        recipes = user_service.get_custom_recipes(user_id)
        return {"recipes": recipes}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get custom recipes: {str(e)}")


@app.get("/api/custom-recipes/with-deals")
async def get_custom_recipes_with_deals(
    user_id: str = Depends(get_current_user_id),
    min_coverage: Optional[float] = 50.0,
    match_threshold: Optional[int] = 70
):
    """Get custom recipes matched with current active deals"""
    try:
        # Only active deals (expired weeks excluded)
        deals = load_active_deals()

        if not deals:
            return {
                "message": "No deals available",
                "recipes": []
            }

        # Get custom recipes
        custom_recipes = user_service.get_custom_recipes(user_id)

        # Match each custom recipe with deals
        matched_recipes = []
        for recipe in custom_recipes:
            # Convert to format expected by recipe matcher
            recipe_for_matching = {
                "id": recipe["id"],
                "name": recipe["name"],
                "description": recipe["description"],
                "image_url": recipe.get("image_url"),
                "prep_time": recipe["prep_time"],
                "cook_time": recipe["cook_time"],
                "servings": recipe["servings"],
                "difficulty": recipe["difficulty"],
                "ingredients": recipe["ingredients"]
            }

            # Match with deals
            matches = recipe_matcher.match_single_recipe_with_deals(
                recipe_for_matching,
                deals,
                min_coverage_percentage=min_coverage,
                match_threshold=match_threshold
            )

            if matches:
                matched_recipes.append(matches)

        # Sort by total savings (highest first)
        matched_recipes.sort(key=lambda x: x.get("total_savings", 0), reverse=True)

        return {
            "total_matches": len(matched_recipes),
            "recipes": matched_recipes
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to match custom recipes with deals: {str(e)}")


@app.delete("/api/custom-recipes/{recipe_id}")
async def delete_custom_recipe(
    recipe_id: str,
    user_id: str = Depends(get_current_user_id)
):
    """Delete a custom recipe"""
    try:
        user_service.delete_custom_recipe(recipe_id, user_id)
        return {"status": "success"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete custom recipe: {str(e)}")


# ========================================
# ADMIN ENDPOINTS
# ========================================

# Initialize deal extractor
deal_extractor = DealExtractor()

# Upload directory
UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)


@app.post("/api/admin/login", response_model=Token)
async def admin_login(login: LoginRequest):
    """Admin login endpoint"""
    if not authenticate_admin(login.username, login.password):
        raise HTTPException(
            status_code=401,
            detail="Incorrect username or password"
        )

    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": login.username},
        expires_delta=access_token_expires
    )

    return {"access_token": access_token, "token_type": "bearer"}


async def process_prospekt_background(file_path: Path, store_name: str):
    """
    Background task to process prospekt and save deals
    This continues even if the client disconnects
    Saves deals after each page is processed
    """
    import logging
    logger = logging.getLogger(__name__)

    def save_page_deals(page_deals: List[Dict]):
        """Callback to save deals after each page"""
        try:
            existing_deals = load_deals()
            existing_deals.extend(page_deals)
            save_deals(existing_deals)
            logger.info(f"Saved {len(page_deals)} deals from current page. Total: {len(existing_deals)}")
        except Exception as e:
            logger.error(f"Error saving page deals: {e}")

    try:
        logger.info(f"Starting background processing of {file_path.name}")

        # Extract deals from file with page-by-page saving
        deals = await deal_extractor.extract_deals_from_file(
            str(file_path),
            store_name=store_name,
            on_page_complete=save_page_deals
        )

        logger.info(f"Successfully processed {file_path.name}: {len(deals)} deals total")

    except Exception as e:
        logger.error(f"Error in background processing: {e}", exc_info=True)

    finally:
        # Clean up uploaded file (optional - keep for debugging)
        # if file_path.exists():
        #     file_path.unlink()
        pass


@app.post("/api/admin/upload")
async def upload_prospekt(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    store_name: str = Form(...),
    admin: str = Depends(require_admin)
):
    """
    Upload prospekt (PDF or image) and extract deals automatically

    Processing happens in the background, so the request returns immediately.
    Deals are saved even if the client disconnects or times out.

    Requires admin authentication.
    """
    # Validate file type
    allowed_extensions = {'.pdf', '.jpg', '.jpeg', '.png', '.bmp'}
    file_ext = Path(file.filename).suffix.lower()

    if file_ext not in allowed_extensions:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid file type. Allowed: {', '.join(allowed_extensions)}"
        )

    # Save uploaded file
    file_id = str(uuid.uuid4())
    file_path = UPLOAD_DIR / f"{file_id}{file_ext}"

    try:
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        # Start background processing
        background_tasks.add_task(process_prospekt_background, file_path, store_name)

        return {
            "status": "processing",
            "message": f"File {file.filename} uploaded successfully. Processing in background...",
            "file_id": file_id,
            "note": "Check /api/admin/deals to see extracted deals (processing may take several minutes)"
        }

    except Exception as e:
        # Clean up on error
        if file_path.exists():
            file_path.unlink()

        raise HTTPException(
            status_code=500,
            detail=f"Error uploading file: {str(e)}"
        )


@app.get("/api/admin/deals")
async def get_all_deals_admin(admin: str = Depends(require_admin)):
    """Get all deals (admin view with full details)"""
    deals = load_deals()
    return {
        "total": len(deals),
        "deals": deals
    }


@app.put("/api/admin/deals/{deal_index}")
async def update_deal(
    deal_index: int,
    updated_deal: Dict,
    admin: str = Depends(require_admin)
):
    """Update a specific deal"""
    deals = load_deals()

    if deal_index < 0 or deal_index >= len(deals):
        raise HTTPException(status_code=404, detail="Deal not found")

    # Update deal
    deals[deal_index] = updated_deal
    save_deals(deals)

    return {
        "status": "success",
        "message": "Deal updated",
        "deal": updated_deal
    }


@app.delete("/api/admin/deals/{deal_index}")
async def delete_deal(
    deal_index: int,
    admin: str = Depends(require_admin)
):
    """Delete a specific deal"""
    deals = load_deals()

    if deal_index < 0 or deal_index >= len(deals):
        raise HTTPException(status_code=404, detail="Deal not found")

    deleted_deal = deals.pop(deal_index)
    save_deals(deals)

    return {
        "status": "success",
        "message": "Deal deleted",
        "deleted_deal": deleted_deal
    }


@app.post("/api/admin/deals")
async def create_deal(
    deal: Dict,
    admin: str = Depends(require_admin)
):
    """Manually create a new deal"""
    deals = load_deals()
    deals.append(deal)
    save_deals(deals)

    return {
        "status": "success",
        "message": "Deal created",
        "deal": deal
    }


@app.delete("/api/admin/deals")
async def clear_all_deals(admin: str = Depends(require_admin)):
    """Clear all deals (use with caution!)"""
    save_deals([])

    return {
        "status": "success",
        "message": "All deals cleared"
    }


# ========================================
# PUSH NOTIFICATION ENDPOINTS (ADMIN)
# ========================================

class SendNotificationRequest(BaseModel):
    title: str
    body: str
    topic: Optional[str] = None
    data: Optional[Dict[str, str]] = None


class SendToAllRequest(BaseModel):
    title: str
    body: str
    data: Optional[Dict[str, str]] = None


@app.post("/api/admin/notifications/send")
async def send_notification(
    request: SendNotificationRequest,
    admin: str = Depends(require_admin)
):
    """
    Send a push notification to a specific topic or all users.
    If topic is provided, sends to that topic. Otherwise sends to all registered devices.
    """
    try:
        if request.topic:
            response = await send_to_topic(
                topic=request.topic,
                title=request.title,
                body=request.body,
                data=request.data,
            )
            return {
                "status": "success",
                "message": f"Notification sent to topic '{request.topic}'",
                "fcm_response": response,
            }
        else:
            result = await send_to_all_users(
                title=request.title,
                body=request.body,
                data=request.data,
            )
            return {
                "status": "success",
                "message": "Notification sent to all users",
                **result,
            }
    except RuntimeError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to send notification: {str(e)}")


@app.post("/api/admin/notifications/send-all")
async def send_notification_all(
    request: SendToAllRequest,
    admin: str = Depends(require_admin)
):
    """Send a push notification to ALL registered devices via FCM tokens"""
    try:
        result = await send_to_all_users(
            title=request.title,
            body=request.body,
            data=request.data,
        )
        return {
            "status": "success",
            **result,
        }
    except RuntimeError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to send notification: {str(e)}")


@app.post("/api/admin/notifications/test")
async def send_test_notification(admin: str = Depends(require_admin)):
    """Send a test notification to the 'test' topic"""
    try:
        response = await send_to_topic(
            topic="test",
            title="SparKoch Test",
            body="Push Notifications funktionieren!",
            data={"type": "test"},
        )
        return {
            "status": "success",
            "message": "Test notification sent to topic 'test'",
            "fcm_response": response,
        }
    except RuntimeError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to send test notification: {str(e)}")


# ==================== CHEFKOCH RECIPE IMPORT ====================

class RecipeImportRequest(BaseModel):
    """Request model for recipe import"""
    url: str
    category_id: Optional[int] = None


@app.post("/api/recipes/import/chefkoch")
async def import_chefkoch_recipe(request: RecipeImportRequest):
    """
    Import a recipe from Chefkoch.de URL

    This endpoint scrapes a Chefkoch.de recipe and saves it to the database.
    """
    try:
        # Validate URL
        if not request.url or 'chefkoch.de' not in request.url.lower():
            raise HTTPException(
                status_code=400,
                detail="Invalid URL. Please provide a valid Chefkoch.de recipe URL"
            )

        # Scrape recipe data
        print(f"Scraping recipe from: {request.url}")
        recipe_data = chefkoch_scraper.scrape_recipe(request.url)

        # Prepare recipe data for database
        from supabase_client import supabase_db

        recipe_db_data = {
            'name': recipe_data['name'],
            'description': recipe_data['description'],
            'image_url': recipe_data['image_url'],
            'prep_time': recipe_data['prep_time'],
            'cook_time': recipe_data['cook_time'],
            'servings': recipe_data['servings'],
            'difficulty': recipe_data['difficulty'],
            'category_id': request.category_id,
        }

        # Add nutrition data if available
        if recipe_data.get('nutrition'):
            nutrition = recipe_data['nutrition']
            recipe_db_data.update({
                'calories': nutrition.get('calories'),
                'protein': nutrition.get('protein'),
                'carbs': nutrition.get('carbs'),
                'fat': nutrition.get('fat'),
                'fiber': nutrition.get('fiber'),
            })

        # Create recipe in database
        print(f"Creating recipe in database: {recipe_data['name']}")
        created_recipe = supabase_db.create_recipe(recipe_db_data)

        if not created_recipe:
            raise Exception("Failed to create recipe in database")

        recipe_id = created_recipe['id']
        print(f"Recipe created with ID: {recipe_id}")

        # Add ingredients
        for i, ingredient in enumerate(recipe_data['ingredients']):
            ingredient_db_data = {
                'recipe_id': recipe_id,
                'ingredient_name': ingredient['name'],
                'quantity': ingredient['quantity'],
                'unit': ingredient['unit'],
                'is_optional': False,
                'ingredient_order': i + 1,
            }
            supabase_db.create_recipe_ingredient(ingredient_db_data)

        print(f"Added {len(recipe_data['ingredients'])} ingredients")

        # Add instructions
        for i, instruction in enumerate(recipe_data['instructions']):
            instruction_db_data = {
                'recipe_id': recipe_id,
                'step_number': i + 1,
                'instruction': instruction,
            }
            supabase_db.create_recipe_instruction(instruction_db_data)

        print(f"Added {len(recipe_data['instructions'])} instructions")

        # Return success response
        return {
            "status": "success",
            "message": f"Recipe '{recipe_data['name']}' imported successfully",
            "recipe": {
                "id": recipe_id,
                "name": recipe_data['name'],
                "description": recipe_data['description'],
                "image_url": recipe_data['image_url'],
                "prep_time": recipe_data['prep_time'],
                "cook_time": recipe_data['cook_time'],
                "servings": recipe_data['servings'],
                "difficulty": recipe_data['difficulty'],
                "ingredients_count": len(recipe_data['ingredients']),
                "instructions_count": len(recipe_data['instructions']),
                "source_url": recipe_data['source_url'],
            }
        }

    except HTTPException:
        raise
    except Exception as e:
        import traceback
        print(f"Error importing recipe: {str(e)}")
        print(traceback.format_exc())

        raise HTTPException(
            status_code=500,
            detail=f"Failed to import recipe: {str(e)}"
        )


# ====================================================================
# ADMIN DASHBOARD ENDPOINTS
# ====================================================================

def _iso_now():
    return datetime.utcnow().isoformat()


def _count(table: str, **filters) -> int:
    try:
        from supabase_client import supabase_db
        q = supabase_db.client.table(table).select('*', count='exact', head=True)
        for key, val in filters.items():
            if isinstance(val, tuple):
                op, v = val
                if op == 'gte':
                    q = q.gte(key, v)
                elif op == 'lte':
                    q = q.lte(key, v)
            else:
                q = q.eq(key, val)
        result = q.execute()
        return result.count or 0
    except Exception as e:
        print(f"_count error on {table}: {e}")
        return 0


@app.get("/api/admin/stats/overview")
async def admin_stats_overview(admin: str = Depends(require_admin)):
    """KPI cards: users, recipes, deals, engagement"""
    from supabase_client import supabase_db

    now = datetime.utcnow()
    today = now.replace(hour=0, minute=0, second=0, microsecond=0).isoformat()
    week_ago = (now - timedelta(days=7)).isoformat()

    # Users — auth.users via admin API
    total_users = 0
    new_users_today = 0
    new_users_week = 0
    try:
        users_page = supabase_db.client.auth.admin.list_users()
        total_users = len(users_page)
        for u in users_page:
            created = getattr(u, 'created_at', None)
            if created:
                created_str = str(created)
                if created_str >= today:
                    new_users_today += 1
                if created_str >= week_ago:
                    new_users_week += 1
    except Exception as e:
        print(f"auth.users error: {e}")
        total_users = _count('user_profiles')
        new_users_today = _count('user_profiles', created_at=('gte', today))
        new_users_week = _count('user_profiles', created_at=('gte', week_ago))

    # Recipes (community)
    total_community = _count('custom_recipes')
    new_recipes_today = _count('custom_recipes', created_at=('gte', today))
    new_recipes_week = _count('custom_recipes', created_at=('gte', week_ago))

    # Deals
    total_deals = _count('deals')
    today_date = now.date().isoformat()
    active_deals = _count('deals', valid_until=('gte', today_date))

    # Deals per store
    deals_by_store = {}
    try:
        deals_result = supabase_db.client.table('deals').select(
            'store_name'
        ).gte('valid_until', today_date).execute()
        for row in deals_result.data:
            store = row.get('store_name', 'Unbekannt')
            deals_by_store[store] = deals_by_store.get(store, 0) + 1
    except Exception as e:
        print(f"deals_by_store error: {e}")

    # Engagement (last 7 days)
    likes_week = _count('recipe_likes', created_at=('gte', week_ago))
    follows_week = _count('follows', created_at=('gte', week_ago))
    bookmarks_week = _count('saved_recipes', created_at=('gte', week_ago))

    return {
        "users": {
            "total": total_users,
            "new_today": new_users_today,
            "new_week": new_users_week,
        },
        "recipes": {
            "total_community": total_community,
            "new_today": new_recipes_today,
            "new_week": new_recipes_week,
        },
        "deals": {
            "total": total_deals,
            "active": active_deals,
            "by_store": deals_by_store,
        },
        "engagement": {
            "likes_week": likes_week,
            "follows_week": follows_week,
            "bookmarks_week": bookmarks_week,
        },
        "generated_at": _iso_now(),
    }


@app.get("/api/admin/stats/timeseries")
async def admin_stats_timeseries(
    days: int = 30,
    admin: str = Depends(require_admin)
):
    """Daily counts for signups + recipes over the last N days"""
    from supabase_client import supabase_db

    now = datetime.utcnow()
    start = (now - timedelta(days=days)).isoformat()

    # Prepare date buckets
    signups_by_day = {}
    recipes_by_day = {}
    for i in range(days):
        day = (now - timedelta(days=days - 1 - i)).date().isoformat()
        signups_by_day[day] = 0
        recipes_by_day[day] = 0

    # Signups (from auth.users if possible, else user_profiles)
    try:
        users_page = supabase_db.client.auth.admin.list_users()
        for u in users_page:
            created = str(getattr(u, 'created_at', ''))[:10]
            if created in signups_by_day:
                signups_by_day[created] += 1
    except Exception:
        try:
            res = supabase_db.client.table('user_profiles').select(
                'created_at'
            ).gte('created_at', start).execute()
            for row in res.data:
                day = str(row.get('created_at', ''))[:10]
                if day in signups_by_day:
                    signups_by_day[day] += 1
        except Exception as e:
            print(f"user_profiles timeseries error: {e}")

    # Community recipes
    try:
        res = supabase_db.client.table('custom_recipes').select(
            'created_at'
        ).gte('created_at', start).execute()
        for row in res.data:
            day = str(row.get('created_at', ''))[:10]
            if day in recipes_by_day:
                recipes_by_day[day] += 1
    except Exception as e:
        print(f"custom_recipes timeseries error: {e}")

    return {
        "signups": [{"date": d, "count": c} for d, c in signups_by_day.items()],
        "recipes": [{"date": d, "count": c} for d, c in recipes_by_day.items()],
    }


@app.get("/api/admin/stats/top")
async def admin_stats_top(admin: str = Depends(require_admin)):
    """Top recipes by likes + top authors by followers (last 7d)"""
    from supabase_client import supabase_db

    week_ago = (datetime.utcnow() - timedelta(days=7)).isoformat()

    # Top recipes: count likes per recipe_id (last 7d), then fetch recipe details
    top_recipes = []
    try:
        likes_res = supabase_db.client.table('recipe_likes').select(
            'recipe_id'
        ).gte('created_at', week_ago).execute()

        counts = {}
        for row in likes_res.data:
            rid = row.get('recipe_id')
            if rid:
                counts[rid] = counts.get(rid, 0) + 1

        top_ids = sorted(counts.items(), key=lambda x: x[1], reverse=True)[:5]
        for rid, cnt in top_ids:
            try:
                res = supabase_db.client.table('custom_recipes').select(
                    'id, name, author_name, image_url, user_id'
                ).eq('id', rid).execute()
                if res.data:
                    r = res.data[0]
                    r['likes_week'] = cnt
                    top_recipes.append(r)
            except Exception:
                pass
    except Exception as e:
        print(f"top_recipes error: {e}")

    # Top authors: count followers per following_id
    top_authors = []
    try:
        follows_res = supabase_db.client.table('follows').select(
            'following_id'
        ).execute()
        counts = {}
        for row in follows_res.data:
            uid = row.get('following_id')
            if uid:
                counts[uid] = counts.get(uid, 0) + 1
        top_ids = sorted(counts.items(), key=lambda x: x[1], reverse=True)[:5]
        for uid, cnt in top_ids:
            try:
                prof = supabase_db.client.table('user_profiles').select(
                    'id, display_name, community_name'
                ).eq('id', uid).execute()
                if prof.data:
                    p = prof.data[0]
                    p['followers'] = cnt
                    top_authors.append(p)
            except Exception:
                pass
    except Exception as e:
        print(f"top_authors error: {e}")

    return {
        "top_recipes": top_recipes,
        "top_authors": top_authors,
    }


@app.get("/api/admin/moderation/queue")
async def admin_moderation_queue(
    limit: int = 20,
    admin: str = Depends(require_admin)
):
    """Newest community recipes for moderation"""
    from supabase_client import supabase_db
    try:
        res = supabase_db.client.table('custom_recipes').select(
            'id, name, description, author_name, user_id, image_url, is_public, created_at'
        ).order('created_at', desc=True).limit(limit).execute()
        return {"recipes": res.data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/admin/users")
async def admin_users_list(
    page: int = 1,
    limit: int = 20,
    search: Optional[str] = None,
    admin: str = Depends(require_admin)
):
    """Paginated user list with recipe + follower counts"""
    from supabase_client import supabase_db

    try:
        users = supabase_db.client.auth.admin.list_users()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Could not list users: {e}")

    # Filter by search
    if search:
        s = search.lower()
        users = [
            u for u in users
            if s in str(getattr(u, 'email', '') or '').lower()
        ]

    total = len(users)
    start = (page - 1) * limit
    page_users = users[start:start + limit]

    # Enrich with recipe + follower counts
    enriched = []
    for u in page_users:
        uid = str(u.id)
        email = getattr(u, 'email', None)
        created = str(getattr(u, 'created_at', ''))

        # Profile
        profile = None
        try:
            prof = supabase_db.client.table('user_profiles').select(
                'display_name, community_name'
            ).eq('id', uid).execute()
            if prof.data:
                profile = prof.data[0]
        except Exception:
            pass

        recipes = _count('custom_recipes', user_id=uid)
        followers = _count('follows', following_id=uid)
        following = _count('follows', follower_id=uid)

        enriched.append({
            "id": uid,
            "email": email,
            "created_at": created,
            "display_name": (profile or {}).get('display_name') if profile else None,
            "community_name": (profile or {}).get('community_name') if profile else None,
            "recipes": recipes,
            "followers": followers,
            "following": following,
        })

    return {
        "total": total,
        "page": page,
        "limit": limit,
        "users": enriched,
    }


@app.get("/api/admin/recipes/community")
async def admin_community_recipes(
    page: int = 1,
    limit: int = 20,
    search: Optional[str] = None,
    sort: str = "newest",
    admin: str = Depends(require_admin)
):
    """Paginated community recipes for moderation"""
    from supabase_client import supabase_db

    try:
        q = supabase_db.client.table('custom_recipes').select(
            'id, name, description, author_name, user_id, image_url, is_public, created_at',
            count='exact'
        )
        if search:
            q = q.ilike('name', f'%{search}%')
        if sort == "newest":
            q = q.order('created_at', desc=True)
        else:
            q = q.order('name')

        start = (page - 1) * limit
        q = q.range(start, start + limit - 1)
        res = q.execute()

        return {
            "total": res.count or 0,
            "page": page,
            "limit": limit,
            "recipes": res.data,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.delete("/api/admin/recipes/{recipe_id}")
async def admin_delete_community_recipe(
    recipe_id: str,
    admin: str = Depends(require_admin)
):
    """Delete a community recipe"""
    from supabase_client import supabase_db
    try:
        supabase_db.client.table('custom_recipes').delete().eq('id', recipe_id).execute()
        return {"status": "success", "message": "Recipe deleted"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.delete("/api/admin/users/{user_id}")
async def admin_delete_user(
    user_id: str,
    admin: str = Depends(require_admin)
):
    """Delete a user via auth.admin (cascades to profile/recipes/likes)"""
    from supabase_client import supabase_db
    try:
        supabase_db.client.auth.admin.delete_user(user_id)
        return {"status": "success", "message": "User deleted"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/admin/health")
async def admin_health(admin: str = Depends(require_admin)):
    """Backend + Supabase health check with latency"""
    from supabase_client import supabase_db
    import time

    supabase_ok = False
    supabase_latency_ms = None
    try:
        t0 = time.time()
        supabase_db.client.table('user_profiles').select(
            'id', count='exact', head=True
        ).limit(1).execute()
        supabase_latency_ms = int((time.time() - t0) * 1000)
        supabase_ok = True
    except Exception as e:
        print(f"health check error: {e}")

    return {
        "backend": "ok",
        "supabase": "ok" if supabase_ok else "error",
        "supabase_latency_ms": supabase_latency_ms,
        "timestamp": _iso_now(),
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
