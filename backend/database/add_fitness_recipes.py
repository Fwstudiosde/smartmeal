#!/usr/bin/env python3
"""
Add FITNESS world-class recipes to SmartMeal database
High-Protein, Low-Carb, detailed instructions
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

# FITNESS RECIPES - World-class quality, High-Protein
RECIPES = [
    {
        'name': 'Perfekt gegrillte Hähnchenbrust mit Gemüse-Medley',
        'category': 'fitness',
        'description': 'Saftige, perfekt gewürzte Hähnchenbrust mit buntem Ofengemüse - das ultimative Fitness-Gericht. Reich an Protein (48g!), arm an Kohlenhydraten, perfekt für Muskelaufbau und Definition. Ein Gericht, das Bodybuilder lieben!',
        'image_url': 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=800',
        'prep_time': 15,
        'cook_time': 25,
        'servings': 2,
        'difficulty': 'easy',
        'nutrition': {'calories': 420, 'protein': 48, 'carbs': 18, 'fat': 16, 'fiber': 6},
        'tags': ['high-protein', 'low-carb', 'dinner', 'meal-prep'],
        'ingredients': [
            {'name': 'Hähnchenbrust-Filets', 'quantity': '500', 'unit': 'g', 'keywords': ['hähnchen', 'chicken', 'geflügel', 'brust', 'filet'], 'priority': 3},
            {'name': 'Paprika rot', 'quantity': '2', 'unit': 'Stück', 'keywords': ['paprika', 'pepper', 'bratpaprika'], 'priority': 2},
            {'name': 'Zucchini', 'quantity': '1', 'unit': 'Stück', 'keywords': ['zucchini'], 'priority': 2},
            {'name': 'Tomaten', 'quantity': '250', 'unit': 'g', 'keywords': ['tomate', 'cherry', 'roma', 'miniroma'], 'priority': 2},
            {'name': 'Olivenöl', 'quantity': '2', 'unit': 'EL', 'keywords': ['öl', 'olive'], 'priority': 1},
            {'name': 'Knoblauch', 'quantity': '3', 'unit': 'Zehen', 'keywords': ['knoblauch', 'garlic'], 'priority': 1},
            {'name': 'Zitrone', 'quantity': '1', 'unit': 'Stück', 'keywords': ['zitrone', 'lemon'], 'priority': 1},
        ],
        'instructions': [
            'VORBEREITUNG: Hähnchenbrust-Filets aus der Verpackung nehmen, mit Küchenpapier trocken tupfen und 10 Minuten bei Raumtemperatur ruhen lassen. Ofen auf 200°C Ober-/Unterhitze vorheizen. Pro-Tipp: Trockenes Fleisch bräunt besser und wird saftiger!',
            'FLEISCH WÜRZEN: Hähnchenbrust mit Salz, frisch gemahlenem schwarzem Pfeffer, 1 TL Paprikapulver und 1 TL Knoblauchpulver von beiden Seiten großzügig würzen. Sanft in die Oberfläche einmassieren. Die Gewürze bilden eine aromatische Kruste beim Braten.',
            'GEMÜSE SCHNEIDEN: Paprika entkernen und in 2 cm große Würfel schneiden. Zucchini in 1 cm dicke Scheiben schneiden. Tomaten halbieren. Knoblauch fein hacken. Alles in eine große Schüssel geben und mit 1 EL Olivenöl, Salz, Pfeffer und italienischen Kräutern vermengen.',
            'FLEISCH ANBRATEN: Große ofenfeste Pfanne auf mittlerer bis hoher Stufe erhitzen. 1 EL Olivenöl hinzugeben und die Hähnchenbrust vorsichtig in die Pfanne legen. 3-4 Minuten pro Seite anbraten, bis eine goldbraune Kruste entsteht. Nicht zu oft wenden! Geduld zahlt sich aus.',
            'GEMÜSE HINZUFÜGEN: Gewürztes Gemüse um das Hähnchen herum in die Pfanne geben. Mit einem Holzlöffel verteilen, sodass es gleichmäßig liegt. Das Gemüse nimmt die Aromen vom Fleisch auf und wird herrlich karamellisiert.',
            'IM OFEN GAREN: Pfanne in den vorgeheizten Ofen stellen und 15-18 Minuten garen, bis das Hähnchen eine Kerntemperatur von 74°C erreicht. Mit einem Fleischthermometer prüfen. Bei dieser Temperatur ist das Fleisch perfekt saftig und durchgegart.',
            'RUHEN LASSEN: Pfanne aus dem Ofen nehmen (Vorsicht, Griff ist heiß!). Hähnchenbrust auf ein Schneidebrett legen und mit Alufolie locker abdecken. 5 Minuten ruhen lassen. In dieser Zeit verteilen sich die Säfte gleichmäßig im Fleisch - essentiell für maximale Saftigkeit!',
            'ZITRONENSAFT: Während das Fleisch ruht, Zitrone halbieren und den Saft über das Gemüse in der Pfanne träufeln. Kurz durchmischen. Der Zitronensaft gibt Frische und hebt alle Aromen hervor.',
            'SCHNEIDEN: Hähnchenbrust gegen die Faser in 1 cm dicke Scheiben schneiden. Das Schneiden gegen die Faser macht das Fleisch noch zarter und leichter zu kauen. Ein echter Profi-Trick!',
            'SERVIEREN: Geschnittenes Hähnchen auf Teller legen, Gemüse daneben arrangieren. Mit frischen Kräutern (Petersilie oder Basilikum) garnieren. Optional: Ein Klecks griechischer Joghurt (10g zusätzliches Protein!) und eine Zitronenspalte dazu. Perfekt für Muskelaufbau - 48g Protein pro Portion!'
        ]
    },
    {
        'name': 'Lachs-Power-Bowl mit Avocado und Quinoa',
        'category': 'fitness',
        'description': 'Omega-3-reicher Lachs trifft auf cremige Avocado und protein-reiches Quinoa. Diese Bowl ist ein Nährstoff-Kraftpaket: hochwertige Proteine, gesunde Fette und komplexe Kohlenhydrate. Perfekt nach intensivem Training!',
        'image_url': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800',
        'prep_time': 15,
        'cook_time': 20,
        'servings': 2,
        'difficulty': 'easy',
        'nutrition': {'calories': 580, 'protein': 38, 'carbs': 35, 'fat': 32, 'fiber': 12},
        'tags': ['high-protein', 'omega-3', 'lunch', 'dinner'],
        'ingredients': [
            {'name': 'Lachsfilet', 'quantity': '400', 'unit': 'g', 'keywords': ['lachs', 'salmon', 'lachsforelle', 'fisch'], 'priority': 3},
            {'name': 'Quinoa', 'quantity': '150', 'unit': 'g', 'keywords': ['quinoa'], 'priority': 2},
            {'name': 'Avocado', 'quantity': '2', 'unit': 'Stück', 'keywords': ['avocado'], 'priority': 3},
            {'name': 'Salatherzen', 'quantity': '200', 'unit': 'g', 'keywords': ['salat', 'salatherz', 'multicolor'], 'priority': 2},
            {'name': 'Edamame', 'quantity': '100', 'unit': 'g', 'keywords': ['edamame', 'sojabohne'], 'priority': 2},
            {'name': 'Sesam', 'quantity': '2', 'unit': 'EL', 'keywords': ['sesam'], 'priority': 1},
            {'name': 'Sojasauce', 'quantity': '3', 'unit': 'EL', 'keywords': ['soja', 'sauce'], 'priority': 1},
        ],
        'instructions': [
            'QUINOA VORBEREITEN: Quinoa in einem feinen Sieb unter fließendem Wasser gründlich abspülen, bis das Wasser klar ist. Dieser Schritt entfernt die bitteren Saponine. 300ml Wasser in einem Topf zum Kochen bringen, Quinoa hinzufügen, Hitze reduzieren und zugedeckt 15 Minuten köcheln lassen.',
            'LACHS VORBEREITEN: Lachsfilet mit Küchenpapier trocken tupfen. Mit Salz und Pfeffer würzen. Die Haut (falls vorhanden) kann dran bleiben - sie wird schön knusprig! Ofen auf 180°C vorheizen oder Pfanne bereitstellen.',
            'LACHS BRATEN METHODE 1 (PFANNE): Pfanne auf mittlerer Hitze erhitzen, 1 EL Öl hinzugeben. Lachs mit der Hautseite nach unten in die Pfanne legen. 4-5 Minuten braten ohne zu bewegen, bis die Haut knusprig ist. Wenden und weitere 3-4 Minuten braten. Lachs sollte innen noch leicht glasig sein.',
            'LACHS BRATEN METHODE 2 (OFEN): Lachsfilet auf ein mit Backpapier ausgelegtes Blech legen, mit etwas Olivenöl beträufeln. 12-15 Minuten im Ofen garen. Bei dieser Methode bleibt der Lachs besonders saftig und gleichmäßig gegart.',
            'AVOCADO VORBEREITEN: Avocados längs halbieren, Kern entfernen. Mit einem Löffel das Fruchtfleisch herauslösen und in dünne Scheiben schneiden. Alternativ: In Würfel schneiden. Sofort mit etwas Zitronensaft beträufeln, damit sie nicht braun wird.',
            'QUINOA FINALISIEREN: Sobald Quinoa fertig ist (das Wasser sollte vollständig aufgesogen sein), Topf vom Herd nehmen und 5 Minuten zugedeckt ruhen lassen. Dann mit einer Gabel auflockern. Pro-Tipp: Jedes Korn sollte sich einzeln anfühlen und einen kleinen "Schwanz" haben.',
            'GEMÜSE VORBEREITEN: Salat waschen und in mundgerechte Stücke zupfen. Edamame kurz in heißem Wasser blanchieren (2-3 Minuten) oder aufgetaute TK-Ware verwenden. Sesam in einer trockenen Pfanne 2-3 Minuten rösten, bis er duftet - dadurch wird er nussiger.',
            'DRESSING MIXEN: 3 EL Sojasauce mit 1 EL Sesamöl, 1 TL Honig, 1 TL Ingwer (gerieben) und 1 TL Reisessig in einer kleinen Schüssel verquirlen. Abschmecken und nach Bedarf mehr Säure oder Süße hinzufügen. Dies ist die "Umami-Bombe" der Bowl!',
            'BOWL ZUSAMMENSTELLEN: In zwei große Schüsseln je eine Portion Quinoa als Base geben. Darauf Salat, Avocadoscheiben, Edamame und Lachs (in Stücke gebrochen oder als ganzes Filet) arrangieren. Bowl-Tipp: Optik ist wichtig - jede Zutat sollte sichtbar sein!',
            'FINALISIEREN UND SERVIEREN: Dressing über die Bowl träufeln (oder separat servieren). Mit geröstetem Sesam, Frühlingszwiebeln und optional Nori-Algen garnieren. Diese Mahlzeit liefert 38g Protein, gesunde Omega-3-Fette und komplexe Carbs - perfekt für 2 Stunden vor oder nach dem Training!'
        ]
    },
]

if __name__ == "__main__":
    conn = sqlite3.connect(DB_PATH)

    print(f"📝 Adding {len(RECIPES)} FITNESS recipes to database...")

    for recipe in RECIPES:
        recipe_id = add_recipe(conn, recipe)
        print(f"  ✓ Added: {recipe['name']}")

    # Verify
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM recipes")
    total = cursor.fetchone()[0]

    print(f"\n✅ Success! Database now has {total} recipes total")

    conn.close()
