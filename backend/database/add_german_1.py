#!/usr/bin/env python3
"""
Add popular GERMAN recipes to SmartMeal database - Part 1
Classic German comfort food with detailed instructions
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

# GERMAN CLASSIC RECIPES - Part 1 (5 recipes)
RECIPES = [
    {
        'name': 'Schweinebraten mit Knödeln und Sauerkraut',
        'category': 'german',
        'description': 'Saftiger Schweinebraten mit knuspriger Kruste, serviert mit fluffigen Semmelknödeln und würzigem Sauerkraut. Der bayerische Klassiker schlechthin - perfekt für Sonntage!',
        'image_url': 'https://images.unsplash.com/photo-1544025162-d76694265947?w=800',
        'prep_time': 30,
        'cook_time': 150,
        'servings': 6,
        'difficulty': 'medium',
        'nutrition': {'calories': 720, 'protein': 48, 'carbs': 52, 'fat': 32, 'fiber': 6},
        'tags': ['dinner', 'family-friendly'],
        'ingredients': [
            {'name': 'Schweine-Nackenbraten', 'quantity': '1.5', 'unit': 'kg', 'keywords': ['schwein', 'pork', 'nacken', 'braten'], 'priority': 3},
            {'name': 'Zwiebeln', 'quantity': '3', 'unit': 'Stück', 'keywords': ['zwiebel', 'onion'], 'priority': 2},
            {'name': 'Karotten', 'quantity': '2', 'unit': 'Stück', 'keywords': ['karotte', 'möhre'], 'priority': 1},
            {'name': 'Bier dunkel', 'quantity': '500', 'unit': 'ml', 'keywords': ['bier', 'beer', 'dunkel'], 'priority': 2},
            {'name': 'Sauerkraut', 'quantity': '800', 'unit': 'g', 'keywords': ['sauerkraut', 'kraut'], 'priority': 2},
            {'name': 'Semmelknödel', 'quantity': '12', 'unit': 'Stück', 'keywords': ['knödel', 'semmel'], 'priority': 2},
            {'name': 'Kümmel', 'quantity': '2', 'unit': 'TL', 'keywords': ['kümmel', 'caraway'], 'priority': 1},
        ],
        'instructions': [
            'SCHWARTE EINSCHNEIDEN: Schweinekruste mit einem scharfen Messer rautenförmig einschneiden - ca. 1cm tief, 2cm Abstand. Die Schwarte mit Salz und Kümmel einreiben und fest einmassieren. Das ist der Schlüssel zur knusprigen Kruste!',
            'FLEISCH WÜRZEN: Fleisch rundherum mit Salz, Pfeffer, Paprikapulver und Knoblauchpulver würzen. In einen großen Bräter legen, Schwarte nach oben. 1 Stunde bei Raumtemperatur ruhen lassen - dann gart es gleichmäßiger.',
            'GEMÜSE VORBEREITEN: Zwiebeln und Karotten schälen, in grobe Stücke schneiden. Um den Braten herum im Bräter verteilen. 300ml Wasser angießen. Ofen auf 200°C vorheizen.',
            'ANBRATEN: Bräter ohne Deckel in den Ofen schieben. 30 Minuten bei 200°C anbraten, bis die Schwarte Blasen wirft. Dann Temperatur auf 160°C reduzieren, mit 200ml Bier angießen und Deckel auflegen.',
            'SCHMOREN: 2,5 Stunden schmoren, dabei alle 30 Minuten mit Bratensaft begießen. Bei Bedarf etwas Bier oder Wasser nachgießen. Das Fleisch sollte butterweich werden - fast vom Knochen fallen!',
            'KRUSTE FINALISIEREN: 20 Minuten vor Ende Deckel abnehmen, Temperatur auf 220°C erhöhen. Die Schwarte wird jetzt richtig knusprig! Achtung: Nicht verbrennen lassen.',
            'SAUERKRAUT ZUBEREITEN: Sauerkraut in einem Topf mit 1 Apfel (gewürfelt), 1 Zwiebel (gewürfelt), 1 TL Kümmel, 2 Lorbeerblättern und 100ml Weißwein 30 Minuten köcheln. Mit Zucker und Salz abschmecken.',
            'KNÖDEL KOCHEN: Großen Topf mit Salzwasser zum Kochen bringen. Semmelknödel nach Packungsanweisung in leicht siedendem Wasser 15-20 Minuten garen.',
            'SAUCE MACHEN: Braten herausnehmen, warm stellen. Bratensauce durch ein Sieb gießen, Fett abschöpfen. Bei hoher Hitze auf 400ml einkochen. Mit Salz, Pfeffer abschmecken. Optional mit etwas Speisestärke binden.',
            'SERVIEREN: Braten in dicke Scheiben schneiden. Mit Knödeln, Sauerkraut und Sauce anrichten. Die knusprige Schwarte ist das Highlight - jeder will ein Stück!'
        ]
    },
    {
        'name': 'Schnitzel Wiener Art mit Bratkartoffeln',
        'category': 'german',
        'description': 'Goldbraunes, paniertes Schnitzel mit knusprigen Bratkartoffeln und frischem Salat. Ein Klassiker der deutschen Küche, den jeder liebt!',
        'image_url': 'https://images.unsplash.com/photo-1600891964599-f61ba0e24092?w=800',
        'prep_time': 20,
        'cook_time': 30,
        'servings': 4,
        'difficulty': 'medium',
        'nutrition': {'calories': 650, 'protein': 42, 'carbs': 48, 'fat': 30, 'fiber': 5},
        'tags': ['dinner', 'family-friendly'],
        'ingredients': [
            {'name': 'Schweineschnitzel', 'quantity': '4', 'unit': 'Stück', 'keywords': ['schwein', 'pork', 'schnitzel'], 'priority': 3},
            {'name': 'Kartoffeln festkochend', 'quantity': '1', 'unit': 'kg', 'keywords': ['kartoffel', 'potato', 'festkochend'], 'priority': 3},
            {'name': 'Eier', 'quantity': '3', 'unit': 'Stück', 'keywords': ['ei', 'egg', 'freiland'], 'priority': 2},
            {'name': 'Paniermehl', 'quantity': '150', 'unit': 'g', 'keywords': ['paniermehl', 'semmelbrösel'], 'priority': 2},
            {'name': 'Mehl', 'quantity': '100', 'unit': 'g', 'keywords': ['mehl', 'flour', 'weizenmehl'], 'priority': 1},
            {'name': 'Zitrone', 'quantity': '2', 'unit': 'Stück', 'keywords': ['zitrone', 'lemon'], 'priority': 1},
            {'name': 'Butter', 'quantity': '100', 'unit': 'g', 'keywords': ['butter'], 'priority': 1},
        ],
        'instructions': [
            'KARTOFFELN VORKOCHEN: Kartoffeln waschen, mit Schale in Salzwasser 20 Minuten kochen bis sie fast gar sind. Abgießen, kalt abschrecken, pellen und in 1cm dicke Scheiben schneiden.',
            'SCHNITZEL KLOPFEN: Schnitzel zwischen Frischhaltefolie legen und mit einem Fleischklopfer vorsichtig dünn klopfen - ca. 5mm dick. Zu kräftiges Klopfen zerstört die Fasern!',
            'PANIERSTATION: Drei flache Teller vorbereiten: 1) Mehl mit Salz, Pfeffer  2) Verquirlte Eier  3) Paniermehl. Diese Reihenfolge ist wichtig für perfekte Panade!',
            'SCHNITZEL PANIEREN: Schnitzel erst im Mehl wenden (überschüssiges abklopfen), dann durch Ei ziehen, zuletzt im Paniermehl wälzen und fest andrücken. Die Panade sollte gut haften.',
            'BRATKARTOFFELN BRATEN: Große Pfanne mit 3 EL Öl erhitzen. Kartoffelscheiben portionsweise goldbraun braten - nicht zu oft wenden! Mit Salz, Pfeffer, Paprikapulver würzen. Warm stellen.',
            'SCHNITZEL BRATEN VORBEREITUNG: Große Pfanne mit hohem Rand auf mittlerer bis hoher Hitze erhitzen. Butter und etwas Öl hineingeben - die Mischung verhindert Verbrennen.',
            'SCHNITZEL BRATEN: Panierte Schnitzel vorsichtig in die Pfanne legen. 3-4 Minuten pro Seite goldbraun braten. Das Fett sollte blubbern, aber nicht rauchen! Schnitzel darf den Pfannenboden nicht berühren - es schwimmt im Fett.',
            'SOUFFLIEREN: Während des Bratens die Pfanne leicht schwenken und mit einem Löffel heißes Fett über das Schnitzel gießen. Das macht die Panade luftig und wellig!',
            'ABTROPFEN: Fertige Schnitzel auf Küchenpapier legen, überschüssiges Fett abtropfen lassen. Niemals abdecken - sonst wird die Panade matschig!',
            'SERVIEREN: Schnitzel mit Bratkartoffeln und Zitronenspalten anrichten. Traditionell mit Preiselbeeren oder Kartoffelsalat. Die Zitrone über das Schnitzel träufeln - himmlisch!'
        ]
    },
]

if __name__ == "__main__":
    conn = sqlite3.connect(DB_PATH)

    print(f"📝 Adding {len(RECIPES)} German recipes (Part 1) to database...")

    for recipe in RECIPES:
        recipe_id = add_recipe(conn, recipe)
        print(f"  ✓ Added: {recipe['name']}")

    # Verify
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM recipes")
    total = cursor.fetchone()[0]

    print(f"\n✅ Success! Database now has {total} recipes total")

    conn.close()
