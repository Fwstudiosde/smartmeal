#!/usr/bin/env python3
"""
Add quick & easy everyday recipes to SmartMeal database - Part 3
Simple recipes that normal people cook regularly (Recipes 11-15)
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

# QUICK & EASY RECIPES - Part 3 (Recipes 11-15)
RECIPES = [
    {
        'name': 'Nudelsalat',
        'category': 'quick',
        'description': 'Klassischer Nudelsalat mit Gemüse und Mayonnaise. Perfekt für Grillpartys, Picknicks oder als Beilage!',
        'image_url': 'https://images.unsplash.com/photo-1621510456681-2330135e5871?w=800',
        'prep_time': 15,
        'cook_time': 15,
        'servings': 6,
        'difficulty': 'easy',
        'nutrition': {'calories': 380, 'protein': 10, 'carbs': 48, 'fat': 16, 'fiber': 4},
        'tags': ['lunch', 'dinner', 'side-dish', 'quick'],
        'ingredients': [
            {'name': 'Nudeln kurz', 'quantity': '500', 'unit': 'g', 'keywords': ['nudeln', 'pasta', 'fusilli', 'penne'], 'priority': 3},
            {'name': 'Mayonnaise', 'quantity': '200', 'unit': 'g', 'keywords': ['mayonnaise', 'mayo'], 'priority': 3},
            {'name': 'Saure Sahne', 'quantity': '150', 'unit': 'g', 'keywords': ['saure sahne', 'sour cream'], 'priority': 2},
            {'name': 'Paprika gemischt', 'quantity': '2', 'unit': 'Stück', 'keywords': ['paprika', 'bell pepper'], 'priority': 2},
            {'name': 'Gurke', 'quantity': '1', 'unit': 'Stück', 'keywords': ['gurke', 'salatgurke', 'cucumber'], 'priority': 2},
            {'name': 'Erbsen tiefgekühlt', 'quantity': '200', 'unit': 'g', 'keywords': ['erbsen', 'peas'], 'priority': 1},
            {'name': 'Zwiebeln', 'quantity': '1', 'unit': 'Stück', 'keywords': ['zwiebel', 'onion'], 'priority': 1},
        ],
        'instructions': [
            'Nudeln in Salzwasser nach Packungsanweisung kochen.',
            'Nudeln abgießen, kalt abschrecken und abtropfen lassen.',
            'Paprika waschen und in kleine Würfel schneiden.',
            'Gurke waschen und ebenfalls würfeln.',
            'Zwiebel fein hacken.',
            'Erbsen kurz in kochendem Wasser blanchieren und abgießen.',
            'Mayonnaise mit saurer Sahne, Salz, Pfeffer und etwas Zucker verrühren.',
            'Nudeln mit Gemüse in einer großen Schüssel mischen.',
            'Dressing unterrühren bis alles gut vermischt ist.',
            'Mindestens 30 Minuten im Kühlschrank ziehen lassen und kalt servieren.'
        ]
    },
    {
        'name': 'Griechischer Salat',
        'category': 'quick',
        'description': 'Frischer Salat mit Tomaten, Gurken, Oliven und Feta. Mediterran, leicht und super lecker - fertig in 10 Minuten!',
        'image_url': 'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=800',
        'prep_time': 10,
        'cook_time': 0,
        'servings': 4,
        'difficulty': 'easy',
        'nutrition': {'calories': 280, 'protein': 12, 'carbs': 14, 'fat': 20, 'fiber': 4},
        'tags': ['lunch', 'dinner', 'side-dish', 'quick', 'vegetarian'],
        'ingredients': [
            {'name': 'Tomaten', 'quantity': '4', 'unit': 'Stück', 'keywords': ['tomate', 'tomato'], 'priority': 3},
            {'name': 'Gurke', 'quantity': '1', 'unit': 'Stück', 'keywords': ['gurke', 'salatgurke', 'cucumber'], 'priority': 3},
            {'name': 'Feta-Käse', 'quantity': '200', 'unit': 'g', 'keywords': ['feta', 'käse', 'schafskäse'], 'priority': 3},
            {'name': 'Zwiebeln rot', 'quantity': '1', 'unit': 'Stück', 'keywords': ['zwiebel', 'onion', 'rot'], 'priority': 2},
            {'name': 'Oliven schwarz', 'quantity': '100', 'unit': 'g', 'keywords': ['olive', 'oliven', 'schwarz'], 'priority': 2},
            {'name': 'Olivenöl', 'quantity': '4', 'unit': 'EL', 'keywords': ['olivenöl', 'olive oil'], 'priority': 2},
            {'name': 'Oregano getrocknet', 'quantity': '1', 'unit': 'TL', 'keywords': ['oregano'], 'priority': 1},
        ],
        'instructions': [
            'Tomaten waschen und in Spalten schneiden.',
            'Gurke waschen und in dicke Scheiben schneiden.',
            'Rote Zwiebel schälen und in dünne Ringe schneiden.',
            'Feta-Käse in grobe Würfel schneiden.',
            'Alle Zutaten in eine große Salatschüssel geben.',
            'Oliven hinzufügen.',
            'Olivenöl darüber träufeln.',
            'Mit Salz, Pfeffer und Oregano würzen.',
            'Vorsichtig vermischen.',
            'Sofort servieren oder kurz ziehen lassen.'
        ]
    },
    {
        'name': 'Caprese Salat',
        'category': 'quick',
        'description': 'Italienischer Klassiker mit Tomate, Mozzarella und Basilikum. Einfach, frisch und unglaublich lecker!',
        'image_url': 'https://images.unsplash.com/photo-1608897013039-887f21d8c804?w=800',
        'prep_time': 10,
        'cook_time': 0,
        'servings': 4,
        'difficulty': 'easy',
        'nutrition': {'calories': 260, 'protein': 14, 'carbs': 8, 'fat': 20, 'fiber': 2},
        'tags': ['lunch', 'dinner', 'side-dish', 'quick', 'vegetarian'],
        'ingredients': [
            {'name': 'Tomaten groß', 'quantity': '4', 'unit': 'Stück', 'keywords': ['tomate', 'tomato', 'fleischtomate'], 'priority': 3},
            {'name': 'Mozzarella', 'quantity': '2', 'unit': 'Kugeln', 'keywords': ['mozzarella', 'käse'], 'priority': 3},
            {'name': 'Basilikum frisch', 'quantity': '1', 'unit': 'Bund', 'keywords': ['basilikum', 'basil'], 'priority': 2},
            {'name': 'Olivenöl nativ extra', 'quantity': '4', 'unit': 'EL', 'keywords': ['olivenöl', 'olive oil'], 'priority': 2},
            {'name': 'Balsamico', 'quantity': '2', 'unit': 'EL', 'keywords': ['balsamico', 'essig', 'vinegar'], 'priority': 1},
        ],
        'instructions': [
            'Tomaten waschen und in dicke Scheiben schneiden.',
            'Mozzarella abtropfen lassen und in Scheiben schneiden.',
            'Basilikumblätter von den Stielen zupfen und waschen.',
            'Tomaten und Mozzarella abwechselnd auf einem Teller anrichten.',
            'Basilikumblätter zwischen die Scheiben legen.',
            'Mit Meersalz und frisch gemahlenem Pfeffer würzen.',
            'Olivenöl großzügig darüber träufeln.',
            'Balsamico-Essig darüber sprenkeln.',
            'Kurz ziehen lassen.',
            'Als Vorspeise oder Beilage servieren.'
        ]
    },
    {
        'name': 'Gemischter Salat',
        'category': 'quick',
        'description': 'Frischer bunter Salat mit Vinaigrette. Die perfekte Beilage - gesund, knackig und in 5 Minuten fertig!',
        'image_url': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800',
        'prep_time': 10,
        'cook_time': 0,
        'servings': 4,
        'difficulty': 'easy',
        'nutrition': {'calories': 140, 'protein': 3, 'carbs': 12, 'fat': 10, 'fiber': 4},
        'tags': ['lunch', 'dinner', 'side-dish', 'quick', 'vegetarian'],
        'ingredients': [
            {'name': 'Eisbergsalat', 'quantity': '1', 'unit': 'Kopf', 'keywords': ['eisberg', 'salat', 'lettuce'], 'priority': 2},
            {'name': 'Tomaten', 'quantity': '2', 'unit': 'Stück', 'keywords': ['tomate', 'tomato'], 'priority': 2},
            {'name': 'Gurke', 'quantity': '1', 'unit': 'Stück', 'keywords': ['gurke', 'salatgurke', 'cucumber'], 'priority': 2},
            {'name': 'Paprika', 'quantity': '1', 'unit': 'Stück', 'keywords': ['paprika', 'bell pepper'], 'priority': 1},
            {'name': 'Karotten', 'quantity': '2', 'unit': 'Stück', 'keywords': ['karotte', 'möhre', 'carrot'], 'priority': 1},
            {'name': 'Olivenöl', 'quantity': '3', 'unit': 'EL', 'keywords': ['olivenöl', 'olive oil'], 'priority': 1},
            {'name': 'Essig', 'quantity': '2', 'unit': 'EL', 'keywords': ['essig', 'vinegar'], 'priority': 1},
        ],
        'instructions': [
            'Eisbergsalat waschen, trockenschleudern und in Stücke zupfen.',
            'Tomaten waschen und in Spalten schneiden.',
            'Gurke waschen und in Scheiben schneiden.',
            'Paprika waschen, entkernen und in Streifen schneiden.',
            'Karotten schälen und raspeln.',
            'Alle Zutaten in eine große Salatschüssel geben.',
            'Olivenöl und Essig in einer kleinen Schüssel verrühren.',
            'Mit Salz, Pfeffer und etwas Zucker würzen.',
            'Dressing über den Salat geben.',
            'Gut durchmischen und sofort servieren.'
        ]
    },
    {
        'name': 'Gegrillte Bratwurst mit Brot',
        'category': 'quick',
        'description': 'Saftige Bratwurst vom Grill mit knusprigem Brot. Der deutsche Klassiker - einfach, lecker und immer gut!',
        'image_url': 'https://images.unsplash.com/photo-1612392062798-2dbaa2c752b4?w=800',
        'prep_time': 5,
        'cook_time': 15,
        'servings': 4,
        'difficulty': 'easy',
        'nutrition': {'calories': 520, 'protein': 22, 'carbs': 38, 'fat': 30, 'fiber': 3},
        'tags': ['lunch', 'dinner', 'quick'],
        'ingredients': [
            {'name': 'Bratwurst', 'quantity': '8', 'unit': 'Stück', 'keywords': ['bratwurst', 'wurst', 'sausage'], 'priority': 3},
            {'name': 'Baguette', 'quantity': '2', 'unit': 'Stück', 'keywords': ['brot', 'bread', 'baguette'], 'priority': 3},
            {'name': 'Senf', 'quantity': '4', 'unit': 'EL', 'keywords': ['senf', 'mustard'], 'priority': 2},
            {'name': 'Zwiebeln', 'quantity': '2', 'unit': 'Stück', 'keywords': ['zwiebel', 'onion'], 'priority': 1},
            {'name': 'Ketchup', 'quantity': '4', 'unit': 'EL', 'keywords': ['ketchup'], 'priority': 1, 'optional': True},
        ],
        'instructions': [
            'Grill oder Grillpfanne auf mittlere Hitze vorheizen.',
            'Bratwürste auf den Grill legen.',
            'Von allen Seiten gleichmäßig grillen, ca. 12-15 Minuten.',
            'Dabei regelmäßig wenden damit sie nicht verbrennen.',
            'Zwiebeln in Ringe schneiden.',
            'Zwiebelringe optional kurz auf dem Grill rösten.',
            'Baguette aufschneiden oder in Stücke teilen.',
            'Brot optional kurz auf dem Grill rösten.',
            'Bratwurst in das Brot legen oder daneben servieren.',
            'Mit Senf, Ketchup und Zwiebeln servieren.'
        ]
    },
]

if __name__ == "__main__":
    conn = sqlite3.connect(DB_PATH)

    print(f"Adding {len(RECIPES)} quick & easy recipes (Part 3) to database...")

    for recipe in RECIPES:
        recipe_id = add_recipe(conn, recipe)
        print(f"  Added: {recipe['name']}")

    # Verify
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM recipes")
    total = cursor.fetchone()[0]

    print(f"\nSuccess! Database now has {total} recipes total")

    conn.close()
