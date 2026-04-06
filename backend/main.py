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

# Import Chefkoch scraper
from chefkoch_scraper import ChefkochScraper

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
    # Add more scrapers here
    # "aldi": AldiScraper(),
    # "rewe": ReweScraper(),
}

# Initialize Chefkoch scraper
chefkoch_scraper = ChefkochScraper()

# Initialize recipe matcher (Supabase version)
recipe_matcher = RecipeMatcherSupabase()

# Initialize user service (Supabase version)
user_service = UserServiceSupabase()


def load_deals() -> List[Dict]:
    """Load deals from cache file"""
    if DEALS_FILE.exists():
        try:
            with open(DEALS_FILE, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            print(f"Error loading deals: {e}")
    return []


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
    """Save deals to cache file after removing duplicates"""
    try:
        # Remove duplicates before saving
        unique_deals = remove_duplicate_deals(deals)

        with open(DEALS_FILE, 'w', encoding='utf-8') as f:
            json.dump(unique_deals, f, ensure_ascii=False, indent=2)

        print(f"Saved {len(unique_deals)} unique deals")
    except Exception as e:
        print(f"Error saving deals: {e}")


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
    Get all deals, optionally filtered by store and/or category

    - **store**: Filter by store name (e.g., 'Lidl', 'ALDI')
    - **category**: Filter by category (e.g., 'Fleisch', 'Gemüse')
    - **limit**: Limit number of results
    """
    # Always reload deals from file to get latest updates
    deals = load_deals()

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
    """Get deals for a specific store"""
    deals = load_deals()
    store_deals = [
        d for d in deals
        if d['store_name'].lower() == store_name.lower()
    ]

    if not store_deals:
        raise HTTPException(status_code=404, detail=f"No deals found for {store_name}")

    return store_deals


@app.get("/api/stores")
async def get_stores():
    """Get list of available stores with deal counts"""
    deals = load_deals()

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
    """Get list of product categories with deal counts"""
    deals = load_deals()

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
    """Get statistics about available deals"""
    deals = load_deals()

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
        # Load current deals
        deals = load_deals()

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
    """Get custom recipes matched with current deals"""
    try:
        # Load current deals
        deals = load_deals()

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


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
