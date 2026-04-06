#!/usr/bin/env python3
"""
Add world-class recipes to SmartMeal database
Run this script multiple times to add more recipes
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

# German Classic Recipes - World-class quality
RECIPES = [
    {
        'name': 'Klassischer Rinderbraten nach Omas Art',
        'category': 'german',
        'description': 'Zartes Rindfleisch in aromatischer Rotwein-Sauce, serviert mit cremigen Kartoffelklößen und glasiertem Rotkohl. Ein Festmahl, das Generationen verbindet - perfekt für Sonntage und besondere Anlässe.',
        'image_url': 'https://images.unsplash.com/photo-1600891964599-f61ba0e24092?w=800',
        'prep_time': 30,
        'cook_time': 150,
        'servings': 6,
        'difficulty': 'medium',
        'nutrition': {'calories': 680, 'protein': 52, 'carbs': 45, 'fat': 28, 'fiber': 6},
        'tags': ['dinner', 'family-friendly'],
        'ingredients': [
            {'name': 'Rinderbraten', 'quantity': '1.5', 'unit': 'kg', 'keywords': ['rind', 'beef', 'braten', 'roastbeef', 'jungbullen'], 'priority': 3},
            {'name': 'Rote Zwiebeln', 'quantity': '3', 'unit': 'Stück', 'keywords': ['zwiebel', 'onion'], 'priority': 2},
            {'name': 'Karotten', 'quantity': '3', 'unit': 'Stück', 'keywords': ['karotte', 'möhre'], 'priority': 1},
            {'name': 'Sellerie', 'quantity': '2', 'unit': 'Stangen', 'keywords': ['sellerie'], 'priority': 1},
            {'name': 'Rotwein', 'quantity': '400', 'unit': 'ml', 'keywords': ['rotwein', 'wein', 'dornfelder', 'spätburgunder'], 'priority': 2},
            {'name': 'Rinderbrühe', 'quantity': '500', 'unit': 'ml', 'keywords': ['brühe'], 'priority': 1},
            {'name': 'Tomatenmark', 'quantity': '3', 'unit': 'EL', 'keywords': ['tomate', 'mark'], 'priority': 1},
            {'name': 'Kartoffelklöße', 'quantity': '12', 'unit': 'Stück', 'keywords': ['kartoffel', 'kloß'], 'priority': 2},
            {'name': 'Rotkohl', 'quantity': '1', 'unit': 'kg', 'keywords': ['rotkohl', 'blaukraut'], 'priority': 2},
        ],
        'instructions': [
            'FLEISCH VORBEREITEN: Rinderbraten aus dem Kühlschrank nehmen und 30 Minuten bei Raumtemperatur ruhen lassen. Mit Küchenpapier trocken tupfen und großzügig mit Salz und Pfeffer würzen. Tipp: Raumtemperatur sorgt für gleichmäßiges Garen!',
            'ANBRATEN: Große Bratpfanne oder Bräter auf hoher Stufe erhitzen. 2 EL Öl hinzugeben und das Fleisch von allen Seiten jeweils 3-4 Minuten kräftig anbraten, bis eine goldbraune Kruste entsteht. Fleisch herausnehmen und beiseite stellen.',
            'GEMÜSE VORBEREITEN: Zwiebeln schälen und in grobe Würfel schneiden. Karotten schälen und in 2 cm dicke Scheiben schneiden. Sellerie waschen und in Stücke schneiden. Das Gemüse bildet die aromatische Basis!',
            'GEMÜSE ANSCHWITZEN: Im gleichen Bräter das Gemüse bei mittlerer Hitze 8-10 Minuten anbraten, dabei regelmäßig umrühren. Tomatenmark hinzugeben und 2 Minuten mitrösten - das gibt intensive Röstaromen.',
            'ABLÖSCHEN: Mit Rotwein ablöschen und den Bratensatz vom Boden lösen. Wein bei hoher Hitze 5 Minuten einkochen lassen, bis er um die Hälfte reduziert ist. Rinderbrühe hinzufügen.',
            'SCHMOREN: Rinderbraten zurück in den Bräter legen. Deckel auflegen und bei 160°C im Ofen 2,5 Stunden schmoren. Alle 30 Minuten wenden und mit Bratensaft begießen. Das Fleisch sollte butterweich werden!',
            'ROTKOHL ZUBEREITEN: Rotkohl fein hobeln. In großem Topf mit 2 EL Butter, 1 gewürfeltem Apfel, 2 EL Zucker, 3 EL Essig, Lorbeerblatt und Gewürznelken 45 Minuten köcheln lassen. Regelmäßig umrühren.',
            'KLÖSSE KOCHEN: 20 Minuten vor dem Servieren Salzwasser zum Kochen bringen. Kartoffelklöße nach Packungsanweisung in leicht siedendem (nicht kochendem!) Wasser garen. Tipp: Klöße müssen an die Oberfläche steigen.',
            'SAUCE FINALISIEREN: Fleisch herausnehmen und warm stellen. Bratensauce durch ein Sieb gießen, Gemüse ausdrücken. Sauce bei hoher Hitze auf 300ml einkochen, bis sie sämig wird. Mit Salz, Pfeffer und etwas Sahne abschmecken.',
            'ANRICHTEN: Rinderbraten in dicke Scheiben schneiden. Auf vorgewärmten Tellern mit Klößen und Rotkohl anrichten. Sauce darüber gießen. Mit frischer Petersilie garnieren. Pro-Tipp: Fleisch gegen die Faser schneiden für maximale Zartheit!'
        ]
    },
]

if __name__ == "__main__":
    conn = sqlite3.connect(DB_PATH)

    print(f"📝 Adding {len(RECIPES)} world-class recipes to database...")

    for recipe in RECIPES:
        recipe_id = add_recipe(conn, recipe)
        print(f"  ✓ Added: {recipe['name']}")

    # Verify
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM recipes")
    total = cursor.fetchone()[0]

    print(f"\n✅ Success! Database now has {total} recipes")

    conn.close()
