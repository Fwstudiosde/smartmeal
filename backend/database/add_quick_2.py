#!/usr/bin/env python3
"""
Add quick & easy everyday recipes to SmartMeal database - Part 2
Simple recipes that normal people cook regularly (Recipes 6-10)
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

# QUICK & EASY RECIPES - Part 2 (Recipes 6-10)
RECIPES = [
    {
        'name': 'Tomatensuppe',
        'category': 'quick',
        'description': 'Cremige, aromatische Tomatensuppe. Schnell gemacht und perfekt für kalte Tage - klassisch mit etwas Sahne verfeinert!',
        'image_url': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=800',
        'prep_time': 10,
        'cook_time': 25,
        'servings': 4,
        'difficulty': 'easy',
        'nutrition': {'calories': 180, 'protein': 5, 'carbs': 22, 'fat': 8, 'fiber': 5},
        'tags': ['lunch', 'dinner', 'quick', 'vegetarian'],
        'ingredients': [
            {'name': 'Tomaten passiert', 'quantity': '800', 'unit': 'g', 'keywords': ['tomaten', 'passiert', 'tomato'], 'priority': 3},
            {'name': 'Zwiebeln', 'quantity': '2', 'unit': 'Stück', 'keywords': ['zwiebel', 'onion'], 'priority': 2},
            {'name': 'Knoblauch', 'quantity': '2', 'unit': 'Zehen', 'keywords': ['knoblauch', 'garlic'], 'priority': 1},
            {'name': 'Gemüsebrühe', 'quantity': '500', 'unit': 'ml', 'keywords': ['brühe', 'bouillon', 'gemüsebrühe'], 'priority': 2},
            {'name': 'Sahne', 'quantity': '100', 'unit': 'ml', 'keywords': ['sahne', 'cream'], 'priority': 2},
            {'name': 'Tomatenmark', 'quantity': '2', 'unit': 'EL', 'keywords': ['tomatenmark', 'paste'], 'priority': 2},
            {'name': 'Olivenöl', 'quantity': '2', 'unit': 'EL', 'keywords': ['olivenöl', 'olive oil'], 'priority': 1},
        ],
        'instructions': [
            'Zwiebeln und Knoblauch fein hacken.',
            'Olivenöl in einem großen Topf erhitzen.',
            'Zwiebeln glasig dünsten, dann Knoblauch hinzufügen.',
            'Tomatenmark unterrühren und kurz anrösten.',
            'Passierte Tomaten und Gemüsebrühe hinzufügen.',
            'Mit Salz, Pfeffer, Zucker und Basilikum würzen.',
            'Alles 20 Minuten köcheln lassen.',
            'Mit einem Pürierstab fein pürieren.',
            'Sahne unterrühren und nochmals abschmecken.',
            'Mit frischem Basilikum garnieren und mit Brot servieren.'
        ]
    },
    {
        'name': 'Hühnersuppe',
        'category': 'quick',
        'description': 'Klassische Hühnersuppe mit Gemüse und Nudeln. Wärmt von innen und schmeckt wie bei Oma - perfekt wenn man krank ist!',
        'image_url': 'https://images.unsplash.com/photo-1562158147-f9ec90717dd1?w=800',
        'prep_time': 15,
        'cook_time': 30,
        'servings': 4,
        'difficulty': 'easy',
        'nutrition': {'calories': 220, 'protein': 24, 'carbs': 18, 'fat': 6, 'fiber': 3},
        'tags': ['lunch', 'dinner', 'quick'],
        'ingredients': [
            {'name': 'Hähnchenbrust', 'quantity': '400', 'unit': 'g', 'keywords': ['hähnchen', 'chicken', 'geflügel'], 'priority': 3},
            {'name': 'Hühnerbrühe', 'quantity': '1.5', 'unit': 'Liter', 'keywords': ['brühe', 'bouillon', 'hühnerbrühe'], 'priority': 3},
            {'name': 'Karotten', 'quantity': '3', 'unit': 'Stück', 'keywords': ['karotte', 'möhre', 'carrot'], 'priority': 2},
            {'name': 'Sellerie', 'quantity': '2', 'unit': 'Stangen', 'keywords': ['sellerie', 'celery'], 'priority': 1},
            {'name': 'Zwiebeln', 'quantity': '1', 'unit': 'Stück', 'keywords': ['zwiebel', 'onion'], 'priority': 2},
            {'name': 'Suppennudeln', 'quantity': '100', 'unit': 'g', 'keywords': ['nudeln', 'pasta', 'suppennudeln'], 'priority': 2},
            {'name': 'Petersilie frisch', 'quantity': '1', 'unit': 'Bund', 'keywords': ['petersilie', 'parsley'], 'priority': 1},
        ],
        'instructions': [
            'Hähnchenbrust in mundgerechte Stücke schneiden.',
            'Karotten, Sellerie und Zwiebel in kleine Würfel schneiden.',
            'Hühnerbrühe in einem großen Topf zum Kochen bringen.',
            'Hähnchenfleisch in die kochende Brühe geben und 10 Minuten garen.',
            'Gemüse hinzufügen und weitere 10 Minuten köcheln lassen.',
            'Suppennudeln dazugeben und nach Packungsanweisung garen.',
            'Mit Salz, Pfeffer und Muskatnuss abschmecken.',
            'Petersilie fein hacken.',
            'Suppe in Schüsseln füllen.',
            'Mit frischer Petersilie garnieren und heiß servieren.'
        ]
    },
    {
        'name': 'Eierkuchen / Pfannkuchen',
        'category': 'quick',
        'description': 'Fluffige, goldbraune Pfannkuchen. Süß oder herzhaft - der Klassiker für Frühstück, Mittag oder Abendessen!',
        'image_url': 'https://images.unsplash.com/photo-1567620832903-9fc6debc209f?w=800',
        'prep_time': 5,
        'cook_time': 20,
        'servings': 4,
        'difficulty': 'easy',
        'nutrition': {'calories': 320, 'protein': 12, 'carbs': 45, 'fat': 10, 'fiber': 2},
        'tags': ['breakfast', 'lunch', 'dinner', 'quick'],
        'ingredients': [
            {'name': 'Mehl', 'quantity': '300', 'unit': 'g', 'keywords': ['mehl', 'flour', 'weizenmehl'], 'priority': 2},
            {'name': 'Eier', 'quantity': '3', 'unit': 'Stück', 'keywords': ['ei', 'egg', 'freiland'], 'priority': 2},
            {'name': 'Milch', 'quantity': '500', 'unit': 'ml', 'keywords': ['milch', 'milk', 'vollmilch'], 'priority': 3},
            {'name': 'Zucker', 'quantity': '2', 'unit': 'EL', 'keywords': ['zucker', 'sugar'], 'priority': 1},
            {'name': 'Butter zum Braten', 'quantity': '50', 'unit': 'g', 'keywords': ['butter'], 'priority': 1},
        ],
        'instructions': [
            'Mehl in eine große Schüssel sieben.',
            'Eier, Milch, Zucker und eine Prise Salz hinzufügen.',
            'Alles mit einem Schneebesen glatt rühren bis keine Klumpen mehr da sind.',
            'Teig 10 Minuten quellen lassen.',
            'Eine Pfanne auf mittlerer Hitze erhitzen und etwas Butter hineingeben.',
            'Eine Kelle Teig in die Pfanne geben und gleichmäßig verteilen.',
            'Pfannkuchen von einer Seite goldbraun backen (ca. 2 Minuten).',
            'Mit einem Pfannenwender umdrehen und die andere Seite backen.',
            'Fertige Pfannkuchen warm halten und restlichen Teig verarbeiten.',
            'Mit Apfelmus, Nutella, Marmelade oder Zucker und Zimt servieren.'
        ]
    },
    {
        'name': 'Rührei mit Toast',
        'category': 'quick',
        'description': 'Cremiges Rührei mit knusprigem Toast. Das perfekte Frühstück - in 5 Minuten fertig und super lecker!',
        'image_url': 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=800',
        'prep_time': 2,
        'cook_time': 5,
        'servings': 2,
        'difficulty': 'easy',
        'nutrition': {'calories': 380, 'protein': 18, 'carbs': 28, 'fat': 22, 'fiber': 2},
        'tags': ['breakfast', 'quick'],
        'ingredients': [
            {'name': 'Eier', 'quantity': '4', 'unit': 'Stück', 'keywords': ['ei', 'egg', 'freiland'], 'priority': 3},
            {'name': 'Toastbrot', 'quantity': '4', 'unit': 'Scheiben', 'keywords': ['toast', 'brot', 'bread'], 'priority': 3},
            {'name': 'Butter', 'quantity': '30', 'unit': 'g', 'keywords': ['butter'], 'priority': 2},
            {'name': 'Milch', 'quantity': '3', 'unit': 'EL', 'keywords': ['milch', 'milk', 'vollmilch'], 'priority': 1},
            {'name': 'Schnittlauch', 'quantity': '1', 'unit': 'Bund', 'keywords': ['schnittlauch', 'chives'], 'priority': 1, 'optional': True},
        ],
        'instructions': [
            'Eier in eine Schüssel aufschlagen.',
            'Milch, Salz und Pfeffer hinzufügen und mit einer Gabel verquirlen.',
            'Butter in einer beschichteten Pfanne bei mittlerer Hitze schmelzen.',
            'Eimasse in die Pfanne geben.',
            'Mit einem Pfannenwender ständig rühren bis das Ei stockt.',
            'Wenn das Rührei noch leicht cremig ist vom Herd nehmen.',
            'Toast parallel im Toaster oder in einer Pfanne rösten.',
            'Toast mit Butter bestreichen.',
            'Schnittlauch fein schneiden und über das Rührei streuen.',
            'Rührei auf den Toast geben oder daneben anrichten und servieren.'
        ]
    },
    {
        'name': 'Spiegeleier mit Speck',
        'category': 'quick',
        'description': 'Klassisches Frühstück mit Spiegelei und knusprigem Speck. Einfach, herzhaft und in wenigen Minuten fertig!',
        'image_url': 'https://images.unsplash.com/photo-1608039829572-78524f79c4c7?w=800',
        'prep_time': 2,
        'cook_time': 8,
        'servings': 2,
        'difficulty': 'easy',
        'nutrition': {'calories': 420, 'protein': 26, 'carbs': 24, 'fat': 26, 'fiber': 2},
        'tags': ['breakfast', 'quick'],
        'ingredients': [
            {'name': 'Eier', 'quantity': '4', 'unit': 'Stück', 'keywords': ['ei', 'egg', 'freiland'], 'priority': 3},
            {'name': 'Speck Scheiben', 'quantity': '8', 'unit': 'Scheiben', 'keywords': ['speck', 'bacon', 'frühstücksspeck'], 'priority': 3},
            {'name': 'Brot', 'quantity': '4', 'unit': 'Scheiben', 'keywords': ['brot', 'bread', 'toast'], 'priority': 2},
            {'name': 'Butter', 'quantity': '20', 'unit': 'g', 'keywords': ['butter'], 'priority': 1},
        ],
        'instructions': [
            'Speck in einer großen Pfanne ohne Öl knusprig braten.',
            'Speck herausnehmen und auf Küchenpapier abtropfen lassen.',
            'Im Speckfett die Eier einzeln aufschlagen.',
            'Eier bei mittlerer Hitze braten bis das Eiweiß fest ist.',
            'Mit Salz und Pfeffer würzen.',
            'Für härteres Eigelb Deckel auf die Pfanne legen.',
            'Brot toasten oder in einer separaten Pfanne rösten.',
            'Toast mit Butter bestreichen.',
            'Spiegeleier und Speck auf Tellern anrichten.',
            'Mit Toast servieren, nach Wunsch mit Ketchup.'
        ]
    },
]

if __name__ == "__main__":
    conn = sqlite3.connect(DB_PATH)

    print(f"Adding {len(RECIPES)} quick & easy recipes (Part 2) to database...")

    for recipe in RECIPES:
        recipe_id = add_recipe(conn, recipe)
        print(f"  Added: {recipe['name']}")

    # Verify
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM recipes")
    total = cursor.fetchone()[0]

    print(f"\nSuccess! Database now has {total} recipes total")

    conn.close()
