#!/usr/bin/env python3
"""
Add quick & easy everyday recipes to SmartMeal database - Part 4
Simple recipes that normal people cook regularly (Recipes 16-20)
"""

import sqlite3
import uuid
from pathlib import Path

DB_PATH = Path(__file__).parent / "recipes.db"

def add_recipe(conn, recipe_data):
    """Add a complete recipe to the database"""
    cursor = conn.cursor()

    # Get category ID
    cursor.execute("SELECT id FROM categories WHERE name = ?", (recipe_data['category'],))
    category_id = cursor.fetchone()[0]

    # Insert recipe
    recipe_id = str(uuid.uuid4())
    cursor.execute("""
        INSERT INTO recipes (id, name, description, image_url, prep_time, cook_time,
                           servings, difficulty, category_id, calories, protein, carbs, fat, fiber)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (recipe_id, recipe_data['name'], recipe_data['description'], recipe_data['image_url'],
          recipe_data['prep_time'], recipe_data['cook_time'], recipe_data['servings'],
          recipe_data['difficulty'], category_id, recipe_data['nutrition']['calories'],
          recipe_data['nutrition']['protein'], recipe_data['nutrition']['carbs'],
          recipe_data['nutrition']['fat'], recipe_data['nutrition'].get('fiber')))

    # Insert ingredients
    for i, ing in enumerate(recipe_data['ingredients'], 1):
        cursor.execute("""
            INSERT INTO recipe_ingredients (recipe_id, ingredient_name, quantity, unit, is_optional, ingredient_order)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (recipe_id, ing['name'], ing['quantity'], ing['unit'], ing.get('optional', False), i))

    # Insert instructions
    for i, step in enumerate(recipe_data['instructions'], 1):
        cursor.execute("""
            INSERT INTO recipe_instructions (recipe_id, step_number, instruction)
            VALUES (?, ?, ?)
        """, (recipe_id, i, step))

    # Insert tags
    for tag_name in recipe_data.get('tags', []):
        cursor.execute("SELECT id FROM tags WHERE name = ?", (tag_name,))
        tag_result = cursor.fetchone()
        if tag_result:
            cursor.execute("""
                INSERT OR IGNORE INTO recipe_tags (recipe_id, tag_id)
                VALUES (?, ?)
            """, (recipe_id, tag_result[0]))

    # Insert ingredient keywords for matching
    for ing in recipe_data['ingredients']:
        for keyword in ing.get('keywords', []):
            cursor.execute("""
                INSERT OR IGNORE INTO ingredient_keywords (ingredient_name, keyword, priority)
                VALUES (?, ?, ?)
            """, (ing['name'], keyword.lower(), ing.get('priority', 1)))

    conn.commit()
    return recipe_id

# QUICK & EASY RECIPES - Part 4 (Recipes 16-20)
RECIPES = [
    {
        'name': 'Hotdog',
        'category': 'quick',
        'description': 'Klassischer Hotdog mit Würstchen im Brötchen. Schnell gemacht, super lecker - der amerikanische Klassiker!',
        'image_url': 'https://images.unsplash.com/photo-1612392062422-ef19b42f74df?w=800',
        'prep_time': 5,
        'cook_time': 10,
        'servings': 4,
        'difficulty': 'easy',
        'nutrition': {'calories': 450, 'protein': 18, 'carbs': 42, 'fat': 22, 'fiber': 3},
        'tags': ['lunch', 'dinner', 'quick'],
        'ingredients': [
            {'name': 'Wiener Würstchen', 'quantity': '8', 'unit': 'Stück', 'keywords': ['wiener', 'würstchen', 'hot dog'], 'priority': 3},
            {'name': 'Hotdog-Brötchen', 'quantity': '8', 'unit': 'Stück', 'keywords': ['hotdog', 'brötchen', 'bun'], 'priority': 3},
            {'name': 'Senf', 'quantity': '4', 'unit': 'EL', 'keywords': ['senf', 'mustard'], 'priority': 2},
            {'name': 'Ketchup', 'quantity': '4', 'unit': 'EL', 'keywords': ['ketchup'], 'priority': 2},
            {'name': 'Zwiebeln', 'quantity': '1', 'unit': 'Stück', 'keywords': ['zwiebel', 'onion'], 'priority': 1, 'optional': True},
            {'name': 'Gewürzgurken', 'quantity': '8', 'unit': 'Stück', 'keywords': ['gurke', 'pickle', 'gewürzgurke'], 'priority': 1, 'optional': True},
        ],
        'instructions': [
            'Einen großen Topf mit Wasser zum Kochen bringen.',
            'Wiener Würstchen in das kochende Wasser geben.',
            'Hitze reduzieren und Würstchen 5-7 Minuten heiß werden lassen.',
            'Hotdog-Brötchen längs aufschneiden, aber nicht ganz durchschneiden.',
            'Brötchen optional kurz toasten oder im Backofen aufbacken.',
            'Zwiebeln fein würfeln (falls verwendet).',
            'Würstchen aus dem Wasser nehmen und abtropfen lassen.',
            'Jedes Würstchen in ein Brötchen legen.',
            'Mit Senf und Ketchup garnieren.',
            'Nach Wunsch mit Zwiebeln und Gewürzgurken belegen und servieren.'
        ]
    },
    {
        'name': 'Burger selbstgemacht',
        'category': 'quick',
        'description': 'Saftiger Hamburger mit frischen Zutaten. Besser als Fast Food - selbstgemacht schmeckt es einfach am besten!',
        'image_url': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800',
        'prep_time': 15,
        'cook_time': 15,
        'servings': 4,
        'difficulty': 'easy',
        'nutrition': {'calories': 650, 'protein': 32, 'carbs': 48, 'fat': 35, 'fiber': 4},
        'tags': ['lunch', 'dinner', 'quick'],
        'ingredients': [
            {'name': 'Rinderhackfleisch', 'quantity': '600', 'unit': 'g', 'keywords': ['hackfleisch', 'rind', 'ground beef'], 'priority': 3},
            {'name': 'Burger-Brötchen', 'quantity': '4', 'unit': 'Stück', 'keywords': ['burger', 'brötchen', 'bun'], 'priority': 3},
            {'name': 'Cheddar-Käse', 'quantity': '4', 'unit': 'Scheiben', 'keywords': ['käse', 'cheddar', 'cheese'], 'priority': 2},
            {'name': 'Tomaten', 'quantity': '2', 'unit': 'Stück', 'keywords': ['tomate', 'tomato'], 'priority': 2},
            {'name': 'Eisbergsalat', 'quantity': '1', 'unit': 'Stück', 'keywords': ['eisberg', 'salat', 'lettuce'], 'priority': 2},
            {'name': 'Zwiebeln', 'quantity': '1', 'unit': 'Stück', 'keywords': ['zwiebel', 'onion'], 'priority': 1},
            {'name': 'Gewürzgurken', 'quantity': '8', 'unit': 'Scheiben', 'keywords': ['gurke', 'pickle', 'gewürzgurke'], 'priority': 1},
            {'name': 'Ketchup', 'quantity': '4', 'unit': 'EL', 'keywords': ['ketchup'], 'priority': 1},
            {'name': 'Mayonnaise', 'quantity': '4', 'unit': 'EL', 'keywords': ['mayonnaise', 'mayo'], 'priority': 1},
        ],
        'instructions': [
            'Hackfleisch in 4 gleich große Portionen teilen und zu Patties formen.',
            'Patties mit Salz und Pfeffer würzen.',
            'Eine große Pfanne oder Grillpfanne stark erhitzen.',
            'Burger-Patties 4-5 Minuten pro Seite braten.',
            'Käsescheiben in der letzten Minute auf die Patties legen.',
            'Brötchen halbieren und optional kurz anrösten.',
            'Tomaten in Scheiben schneiden, Salat waschen.',
            'Zwiebel in Ringe schneiden.',
            'Brötchen mit Mayo und Ketchup bestreichen.',
            'Salat, Patty mit Käse, Tomate, Zwiebel und Gurke schichten und servieren.'
        ]
    },
    {
        'name': 'Belegtes Brot / Sandwich',
        'category': 'quick',
        'description': 'Frisches belegtes Brot mit Aufschnitt und Gemüse. Der Klassiker für zwischendurch - schnell und lecker!',
        'image_url': 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=800',
        'prep_time': 5,
        'cook_time': 0,
        'servings': 2,
        'difficulty': 'easy',
        'nutrition': {'calories': 380, 'protein': 20, 'carbs': 42, 'fat': 14, 'fiber': 5},
        'tags': ['breakfast', 'lunch', 'quick'],
        'ingredients': [
            {'name': 'Brot oder Toast', 'quantity': '4', 'unit': 'Scheiben', 'keywords': ['brot', 'bread', 'toast', 'vollkorn'], 'priority': 3},
            {'name': 'Butter', 'quantity': '20', 'unit': 'g', 'keywords': ['butter'], 'priority': 2},
            {'name': 'Aufschnitt gemischt', 'quantity': '200', 'unit': 'g', 'keywords': ['aufschnitt', 'schinken', 'wurst', 'salami'], 'priority': 3},
            {'name': 'Käse Scheiben', 'quantity': '4', 'unit': 'Scheiben', 'keywords': ['käse', 'cheese', 'gouda'], 'priority': 2},
            {'name': 'Tomaten', 'quantity': '1', 'unit': 'Stück', 'keywords': ['tomate', 'tomato'], 'priority': 1},
            {'name': 'Gurke', 'quantity': '1/2', 'unit': 'Stück', 'keywords': ['gurke', 'salatgurke', 'cucumber'], 'priority': 1},
            {'name': 'Eisbergsalat', 'quantity': '4', 'unit': 'Blätter', 'keywords': ['eisberg', 'salat', 'lettuce'], 'priority': 1},
        ],
        'instructions': [
            'Brotscheiben mit Butter bestreichen.',
            'Salatblätter waschen und trocken tupfen.',
            'Tomate und Gurke waschen und in Scheiben schneiden.',
            'Salatblätter auf die Brotscheiben legen.',
            'Aufschnitt darauf verteilen.',
            'Käsescheiben darauf legen.',
            'Tomaten- und Gurkenscheiben darauf verteilen.',
            'Mit Salz und Pfeffer würzen.',
            'Optional mit einer zweiten Brotscheibe belegen.',
            'In der Mitte durchschneiden und servieren.'
        ]
    },
    {
        'name': 'Toast Hawaii',
        'category': 'quick',
        'description': 'Überbackener Toast mit Schinken, Ananas und Käse. Der Retro-Klassiker aus den 70ern - kitschig aber lecker!',
        'image_url': 'https://images.unsplash.com/photo-1619095751153-3b0c33f933b7?w=800',
        'prep_time': 5,
        'cook_time': 10,
        'servings': 2,
        'difficulty': 'easy',
        'nutrition': {'calories': 420, 'protein': 24, 'carbs': 38, 'fat': 18, 'fiber': 2},
        'tags': ['breakfast', 'lunch', 'dinner', 'quick'],
        'ingredients': [
            {'name': 'Toastbrot', 'quantity': '4', 'unit': 'Scheiben', 'keywords': ['toast', 'brot', 'bread'], 'priority': 3},
            {'name': 'Kochschinken', 'quantity': '4', 'unit': 'Scheiben', 'keywords': ['schinken', 'ham', 'kochschinken'], 'priority': 3},
            {'name': 'Ananas Scheiben', 'quantity': '4', 'unit': 'Scheiben', 'keywords': ['ananas', 'pineapple'], 'priority': 3},
            {'name': 'Käse Scheiben', 'quantity': '4', 'unit': 'Scheiben', 'keywords': ['käse', 'cheese', 'gouda'], 'priority': 3},
            {'name': 'Butter', 'quantity': '20', 'unit': 'g', 'keywords': ['butter'], 'priority': 1},
        ],
        'instructions': [
            'Backofen auf 200 Grad Celsius vorheizen (Oberhitze mit Grill).',
            'Toastscheiben auf ein Backblech legen.',
            'Jede Toastscheibe dünn mit Butter bestreichen.',
            'Eine Scheibe Schinken auf jede Toastscheibe legen.',
            'Ananasscheiben abtropfen lassen.',
            'Je eine Ananasscheibe auf den Schinken legen.',
            'Mit einer Scheibe Käse bedecken.',
            'Im Backofen 8-10 Minuten überbacken bis der Käse schmilzt.',
            'Kurz unter den Grill schieben bis der Käse goldbraun ist.',
            'Heiß servieren, optional mit einem Salatblatt garnieren.'
        ]
    },
    {
        'name': 'Käsebrot überbacken',
        'category': 'quick',
        'description': 'Knuspriges überbackenes Käsebrot. Einfacher geht es nicht - perfekt für den schnellen Hunger!',
        'image_url': 'https://images.unsplash.com/photo-1619740455993-9e90966c36f5?w=800',
        'prep_time': 5,
        'cook_time': 8,
        'servings': 2,
        'difficulty': 'easy',
        'nutrition': {'calories': 380, 'protein': 18, 'carbs': 35, 'fat': 18, 'fiber': 3},
        'tags': ['breakfast', 'lunch', 'dinner', 'quick', 'vegetarian'],
        'ingredients': [
            {'name': 'Brot', 'quantity': '4', 'unit': 'Scheiben', 'keywords': ['brot', 'bread', 'vollkorn'], 'priority': 3},
            {'name': 'Käse gerieben', 'quantity': '200', 'unit': 'g', 'keywords': ['käse', 'cheese', 'gouda', 'gerieben'], 'priority': 3},
            {'name': 'Butter', 'quantity': '20', 'unit': 'g', 'keywords': ['butter'], 'priority': 2},
            {'name': 'Tomaten', 'quantity': '1', 'unit': 'Stück', 'keywords': ['tomate', 'tomato'], 'priority': 1, 'optional': True},
            {'name': 'Zwiebeln', 'quantity': '1', 'unit': 'Stück', 'keywords': ['zwiebel', 'onion'], 'priority': 1, 'optional': True},
        ],
        'instructions': [
            'Backofen auf 200 Grad Celsius vorheizen (Oberhitze mit Grill).',
            'Brotscheiben auf ein Backblech legen.',
            'Jede Brotscheibe dünn mit Butter bestreichen.',
            'Optional Tomaten in dünne Scheiben schneiden und auf das Brot legen.',
            'Optional Zwiebeln fein würfeln und auf das Brot streuen.',
            'Großzügig geriebenen Käse auf jede Scheibe verteilen.',
            'Mit Salz, Pfeffer und Paprikapulver würzen.',
            'Im Backofen 6-8 Minuten überbacken bis der Käse schmilzt.',
            'Kurz unter den Grill schieben bis der Käse goldbraun und knusprig ist.',
            'Heiß servieren, nach Wunsch mit frischem Schnittlauch garnieren.'
        ]
    },
]

if __name__ == "__main__":
    conn = sqlite3.connect(DB_PATH)

    print(f"Adding {len(RECIPES)} quick & easy recipes (Part 4) to database...")

    for recipe in RECIPES:
        recipe_id = add_recipe(conn, recipe)
        print(f"  Added: {recipe['name']}")

    # Verify
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM recipes")
    total = cursor.fetchone()[0]

    print(f"\nSuccess! Database now has {total} recipes total")

    conn.close()
