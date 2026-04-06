#!/usr/bin/env python3
"""
Add quick & easy everyday recipes to SmartMeal database - Part 1
Simple recipes that normal people cook regularly (Recipes 1-5)
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

# QUICK & EASY RECIPES - Part 1 (Recipes 1-5)
RECIPES = [
    {
        'name': 'Spaghetti Bolognese',
        'category': 'quick',
        'description': 'Klassische Spaghetti mit herzhafter Hackfleischsauce. Der italienische Klassiker, den jeder liebt - einfach und schnell zubereitet!',
        'image_url': 'https://images.unsplash.com/photo-1598866594230-a7c12756260f?w=800',
        'prep_time': 10,
        'cook_time': 25,
        'servings': 4,
        'difficulty': 'easy',
        'nutrition': {'calories': 580, 'protein': 28, 'carbs': 72, 'fat': 18, 'fiber': 5},
        'tags': ['dinner', 'lunch', 'family-friendly'],
        'ingredients': [
            {'name': 'Spaghetti', 'quantity': '500', 'unit': 'g', 'keywords': ['spaghetti', 'pasta', 'nudeln'], 'priority': 3},
            {'name': 'Rinderhackfleisch', 'quantity': '500', 'unit': 'g', 'keywords': ['hackfleisch', 'rind', 'ground beef'], 'priority': 3},
            {'name': 'Zwiebeln', 'quantity': '2', 'unit': 'Stück', 'keywords': ['zwiebel', 'onion'], 'priority': 2},
            {'name': 'Knoblauch', 'quantity': '2', 'unit': 'Zehen', 'keywords': ['knoblauch', 'garlic'], 'priority': 1},
            {'name': 'Tomaten passiert', 'quantity': '400', 'unit': 'g', 'keywords': ['tomaten', 'passiert', 'tomato'], 'priority': 3},
            {'name': 'Tomatenmark', 'quantity': '2', 'unit': 'EL', 'keywords': ['tomatenmark', 'paste'], 'priority': 2},
            {'name': 'Parmesan', 'quantity': '100', 'unit': 'g', 'keywords': ['parmesan', 'käse', 'cheese'], 'priority': 2},
            {'name': 'Olivenöl', 'quantity': '2', 'unit': 'EL', 'keywords': ['olivenöl', 'olive oil'], 'priority': 1},
        ],
        'instructions': [
            'Einen großen Topf mit Salzwasser zum Kochen bringen.',
            'Zwiebeln und Knoblauch fein hacken.',
            'Olivenöl in einer großen Pfanne erhitzen und Zwiebeln glasig dünsten.',
            'Hackfleisch hinzufügen und krümelig anbraten bis es braun ist.',
            'Knoblauch und Tomatenmark kurz mitbraten.',
            'Passierte Tomaten hinzufügen, mit Salz, Pfeffer und Oregano würzen.',
            'Sauce 15-20 Minuten köcheln lassen.',
            'Spaghetti nach Packungsanweisung kochen (ca. 8-10 Minuten).',
            'Nudeln abgießen und mit der Sauce vermischen.',
            'Mit geriebenem Parmesan servieren.'
        ]
    },
    {
        'name': 'Spaghetti Carbonara',
        'category': 'quick',
        'description': 'Cremige Pasta mit Speck, Ei und Parmesan. Echter italienischer Klassiker - cremig ohne Sahne, nur mit Ei und Käse!',
        'image_url': 'https://images.unsplash.com/photo-1612874742237-6526221588e3?w=800',
        'prep_time': 5,
        'cook_time': 15,
        'servings': 4,
        'difficulty': 'easy',
        'nutrition': {'calories': 620, 'protein': 26, 'carbs': 68, 'fat': 26, 'fiber': 3},
        'tags': ['dinner', 'lunch', 'quick'],
        'ingredients': [
            {'name': 'Spaghetti', 'quantity': '500', 'unit': 'g', 'keywords': ['spaghetti', 'pasta', 'nudeln'], 'priority': 3},
            {'name': 'Speck gewürfelt', 'quantity': '200', 'unit': 'g', 'keywords': ['speck', 'bacon', 'schinken'], 'priority': 3},
            {'name': 'Eier', 'quantity': '4', 'unit': 'Stück', 'keywords': ['ei', 'egg', 'freiland'], 'priority': 2},
            {'name': 'Parmesan', 'quantity': '150', 'unit': 'g', 'keywords': ['parmesan', 'käse', 'cheese'], 'priority': 3},
            {'name': 'Knoblauch', 'quantity': '2', 'unit': 'Zehen', 'keywords': ['knoblauch', 'garlic'], 'priority': 1},
            {'name': 'Olivenöl', 'quantity': '1', 'unit': 'EL', 'keywords': ['olivenöl', 'olive oil'], 'priority': 1},
        ],
        'instructions': [
            'Einen großen Topf mit Salzwasser zum Kochen bringen.',
            'Spaghetti nach Packungsanweisung kochen (ca. 8-10 Minuten).',
            'Eier mit geriebenem Parmesan in einer Schüssel verquirlen, mit Pfeffer würzen.',
            'Speck in einer Pfanne ohne Öl knusprig ausbraten.',
            'Knoblauch fein hacken und kurz zum Speck geben.',
            'Nudeln abgießen, dabei 1 Tasse Nudelwasser aufheben.',
            'Heiße Nudeln sofort zum Speck in die Pfanne geben.',
            'Pfanne vom Herd nehmen und Ei-Käse-Mischung unterrühren.',
            'Mit Nudelwasser die gewünschte Cremigkeit einstellen.',
            'Sofort servieren mit extra Parmesan und frisch gemahlenem Pfeffer.'
        ]
    },
    {
        'name': 'Nudeln mit Tomatensoße',
        'category': 'quick',
        'description': 'Einfache Pasta mit klassischer Tomatensoße. Schnell, günstig und schmeckt jedem - der perfekte Klassiker für jeden Tag!',
        'image_url': 'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=800',
        'prep_time': 5,
        'cook_time': 20,
        'servings': 4,
        'difficulty': 'easy',
        'nutrition': {'calories': 420, 'protein': 14, 'carbs': 78, 'fat': 8, 'fiber': 6},
        'tags': ['dinner', 'lunch', 'quick', 'vegetarian'],
        'ingredients': [
            {'name': 'Nudeln', 'quantity': '500', 'unit': 'g', 'keywords': ['nudeln', 'pasta', 'penne', 'fusilli'], 'priority': 3},
            {'name': 'Tomaten passiert', 'quantity': '500', 'unit': 'g', 'keywords': ['tomaten', 'passiert', 'tomato'], 'priority': 3},
            {'name': 'Zwiebeln', 'quantity': '1', 'unit': 'Stück', 'keywords': ['zwiebel', 'onion'], 'priority': 2},
            {'name': 'Knoblauch', 'quantity': '2', 'unit': 'Zehen', 'keywords': ['knoblauch', 'garlic'], 'priority': 1},
            {'name': 'Tomatenmark', 'quantity': '2', 'unit': 'EL', 'keywords': ['tomatenmark', 'paste'], 'priority': 2},
            {'name': 'Olivenöl', 'quantity': '2', 'unit': 'EL', 'keywords': ['olivenöl', 'olive oil'], 'priority': 1},
            {'name': 'Basilikum frisch', 'quantity': '1', 'unit': 'Bund', 'keywords': ['basilikum', 'basil'], 'priority': 1, 'optional': True},
        ],
        'instructions': [
            'Einen großen Topf mit Salzwasser zum Kochen bringen.',
            'Zwiebel und Knoblauch fein hacken.',
            'Olivenöl in einer Pfanne erhitzen und Zwiebeln glasig dünsten.',
            'Knoblauch hinzufügen und kurz mitdünsten.',
            'Tomatenmark unterrühren und 1 Minute anrösten.',
            'Passierte Tomaten hinzufügen und gut verrühren.',
            'Mit Salz, Pfeffer, Zucker und italienischen Kräutern würzen.',
            'Sauce 15 Minuten köcheln lassen, Nudeln währenddessen kochen.',
            'Nudeln abgießen und mit der Sauce vermischen.',
            'Mit frischem Basilikum garnieren und servieren.'
        ]
    },
    {
        'name': 'Gebratene Nudeln mit Gemüse',
        'category': 'quick',
        'description': 'Asiatisch inspirierte gebratene Nudeln mit knackigem Gemüse. Schnell, gesund und lecker - perfekt für die ganze Familie!',
        'image_url': 'https://images.unsplash.com/photo-1585032226651-759b368d7246?w=800',
        'prep_time': 10,
        'cook_time': 15,
        'servings': 4,
        'difficulty': 'easy',
        'nutrition': {'calories': 480, 'protein': 16, 'carbs': 72, 'fat': 14, 'fiber': 7},
        'tags': ['dinner', 'lunch', 'quick', 'vegetarian'],
        'ingredients': [
            {'name': 'Nudeln', 'quantity': '400', 'unit': 'g', 'keywords': ['nudeln', 'pasta', 'spaghetti'], 'priority': 3},
            {'name': 'Paprika gemischt', 'quantity': '2', 'unit': 'Stück', 'keywords': ['paprika', 'bell pepper'], 'priority': 2},
            {'name': 'Karotten', 'quantity': '2', 'unit': 'Stück', 'keywords': ['karotte', 'möhre', 'carrot'], 'priority': 2},
            {'name': 'Zucchini', 'quantity': '1', 'unit': 'Stück', 'keywords': ['zucchini', 'courgette'], 'priority': 2},
            {'name': 'Zwiebeln', 'quantity': '1', 'unit': 'Stück', 'keywords': ['zwiebel', 'onion'], 'priority': 2},
            {'name': 'Knoblauch', 'quantity': '2', 'unit': 'Zehen', 'keywords': ['knoblauch', 'garlic'], 'priority': 1},
            {'name': 'Sojasauce', 'quantity': '4', 'unit': 'EL', 'keywords': ['sojasauce', 'soy sauce'], 'priority': 2},
            {'name': 'Sesamöl', 'quantity': '2', 'unit': 'EL', 'keywords': ['sesamöl', 'sesame oil'], 'priority': 1},
        ],
        'instructions': [
            'Nudeln nach Packungsanweisung kochen, abgießen und beiseite stellen.',
            'Gemüse waschen und in dünne Streifen schneiden.',
            'Zwiebel und Knoblauch fein hacken.',
            'Wok oder große Pfanne stark erhitzen, Öl hineingeben.',
            'Zwiebeln und Knoblauch kurz anbraten.',
            'Karotten hinzufügen und 2 Minuten braten.',
            'Paprika und Zucchini dazugeben, weitere 3 Minuten braten.',
            'Gekochte Nudeln hinzufügen und alles gut vermischen.',
            'Sojasauce und Sesamöl unterrühren, kurz durchschwenken.',
            'Mit Salz und Pfeffer abschmecken, heiß servieren.'
        ]
    },
    {
        'name': 'Pizza Margherita',
        'category': 'quick',
        'description': 'Klassische Pizza mit Tomatensoße, Mozzarella und Basilikum. Der italienische Klassiker - einfach, aber unglaublich lecker!',
        'image_url': 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=800',
        'prep_time': 15,
        'cook_time': 15,
        'servings': 4,
        'difficulty': 'easy',
        'nutrition': {'calories': 520, 'protein': 22, 'carbs': 68, 'fat': 18, 'fiber': 4},
        'tags': ['dinner', 'lunch', 'family-friendly'],
        'ingredients': [
            {'name': 'Pizzateig fertig', 'quantity': '2', 'unit': 'Stück', 'keywords': ['pizzateig', 'pizza dough', 'teig'], 'priority': 3},
            {'name': 'Tomaten passiert', 'quantity': '400', 'unit': 'g', 'keywords': ['tomaten', 'passiert', 'tomato'], 'priority': 3},
            {'name': 'Mozzarella', 'quantity': '400', 'unit': 'g', 'keywords': ['mozzarella', 'käse', 'cheese'], 'priority': 3},
            {'name': 'Tomatenmark', 'quantity': '2', 'unit': 'EL', 'keywords': ['tomatenmark', 'paste'], 'priority': 2},
            {'name': 'Basilikum frisch', 'quantity': '1', 'unit': 'Bund', 'keywords': ['basilikum', 'basil'], 'priority': 1},
            {'name': 'Knoblauch', 'quantity': '2', 'unit': 'Zehen', 'keywords': ['knoblauch', 'garlic'], 'priority': 1},
            {'name': 'Olivenöl', 'quantity': '2', 'unit': 'EL', 'keywords': ['olivenöl', 'olive oil'], 'priority': 1},
        ],
        'instructions': [
            'Backofen auf 250 Grad Celsius vorheizen (Ober-/Unterhitze).',
            'Knoblauch fein hacken und mit passierten Tomaten und Tomatenmark vermischen.',
            'Die Tomatensoße mit Salz, Pfeffer und Oregano würzen.',
            'Pizzateig auf einem bemehlten Backblech ausrollen.',
            'Tomatensoße gleichmäßig auf dem Teig verteilen.',
            'Mozzarella abtropfen lassen und in Scheiben schneiden.',
            'Mozzarella-Scheiben auf der Pizza verteilen.',
            'Pizza mit etwas Olivenöl beträufeln.',
            'Pizza im heißen Ofen 12-15 Minuten backen bis der Käse goldbraun ist.',
            'Mit frischem Basilikum garnieren und sofort servieren.'
        ]
    },
]

if __name__ == "__main__":
    conn = sqlite3.connect(DB_PATH)

    print(f"Adding {len(RECIPES)} quick & easy recipes (Part 1) to database...")

    for recipe in RECIPES:
        recipe_id = add_recipe(conn, recipe)
        print(f"  Added: {recipe['name']}")

    # Verify
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM recipes")
    total = cursor.fetchone()[0]

    print(f"\nSuccess! Database now has {total} recipes total")

    conn.close()
