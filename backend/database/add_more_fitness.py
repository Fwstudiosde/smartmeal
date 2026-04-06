#!/usr/bin/env python3
"""
Add more FITNESS world-class recipes to SmartMeal database
High-Protein, nutrient-dense, detailed instructions
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

# MORE FITNESS RECIPES - World-class quality, High-Protein
RECIPES = [
    {
        'name': 'Protein-Pancakes mit Beeren und griechischem Joghurt',
        'category': 'fitness',
        'description': 'Fluffige, proteinreiche Pancakes mit frischen Beeren - das perfekte Post-Workout-Frühstück! Mit 35g Protein pro Portion und komplexen Kohlenhydraten für optimale Regeneration. Schmeckt wie Dessert, nährt wie ein Champion!',
        'image_url': 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=800',
        'prep_time': 10,
        'cook_time': 15,
        'servings': 2,
        'difficulty': 'easy',
        'nutrition': {'calories': 420, 'protein': 35, 'carbs': 48, 'fat': 10, 'fiber': 8},
        'tags': ['high-protein', 'breakfast', 'meal-prep'],
        'ingredients': [
            {'name': 'Haferflocken', 'quantity': '100', 'unit': 'g', 'keywords': ['hafer', 'oat', 'flocken', 'kernige'], 'priority': 3},
            {'name': 'Protein-Pulver Vanille', 'quantity': '60', 'unit': 'g', 'keywords': ['protein', 'whey', 'pulver', 'eiweiss'], 'priority': 3},
            {'name': 'Eier', 'quantity': '4', 'unit': 'Stück', 'keywords': ['ei', 'egg', 'freiland', 'bio-eier'], 'priority': 3},
            {'name': 'Griechischer Joghurt', 'quantity': '200', 'unit': 'g', 'keywords': ['joghurt', 'greek', 'griechisch', 'skyr'], 'priority': 2},
            {'name': 'Banane', 'quantity': '2', 'unit': 'Stück', 'keywords': ['banane', 'banana'], 'priority': 2},
            {'name': 'Heidelbeeren', 'quantity': '150', 'unit': 'g', 'keywords': ['heidelbeere', 'blueberry', 'beere'], 'priority': 2},
            {'name': 'Himbeeren', 'quantity': '100', 'unit': 'g', 'keywords': ['himbeere', 'raspberry', 'beere'], 'priority': 2},
            {'name': 'Ahornsirup', 'quantity': '2', 'unit': 'EL', 'keywords': ['ahornsirup', 'maple', 'sirup'], 'priority': 1, 'optional': True},
        ],
        'instructions': [
            'TEIG VORBEREITEN: Haferflocken in einen Mixer oder eine Küchenmaschine geben und 30 Sekunden mixen, bis sie zu feinem Mehl werden. Dieser Schritt ist essentiell für die fluffige Textur! Das Hafermehl sollte sich fast wie Weizenmehl anfühlen.',
            'BANANEN ZERDRÜCKEN: Bananen schälen und mit einer Gabel in einer großen Schüssel zu einem glatten Püree zerdrücken. Ein paar kleine Stückchen sind okay, aber je feiner, desto besser wird die Konsistenz. Die Banane dient als natürlicher Süßstoff und Bindemittel.',
            'FEUCHTE ZUTATEN MIXEN: Eier in die Schüssel mit Bananenpüree geben und mit einem Schneebesen gründlich verquirlen, bis die Mischung hellgelb und leicht schaumig ist. 100g griechischen Joghurt hinzufügen und einrühren. Diese Kombination macht die Pancakes super saftig!',
            'TROCKENE ZUTATEN KOMBINIEREN: Das gemahlene Hafermehl und Protein-Pulver in die Ei-Bananen-Mischung sieben oder einrühren. Mit einem Teigschaber vorsichtig unterheben, bis gerade keine Mehlstreifen mehr sichtbar sind. WICHTIG: Nicht zu viel rühren! Ein paar Klümpchen sind perfekt - das hält die Pancakes fluffig.',
            'TEIG RUHEN LASSEN: Teig 5 Minuten bei Raumtemperatur ruhen lassen. In dieser Zeit quellen die Haferflocken auf und der Teig wird dicker. Das ist der Schlüssel zu perfekten, nicht-matschigen Pancakes! Der Teig sollte dickflüssig sein, aber noch vom Löffel tropfen.',
            'PFANNE VORBEREITEN: Große beschichtete Pfanne auf mittlerer Hitze erhitzen (Stufe 5-6 von 9). Mit einem Küchentuch minimal Öl oder Butter verteilen - nur ein Hauch! Zu viel Fett macht die Pancakes ölig. Pfanne ist bereit, wenn ein Wassertropfen tanzt und verdampft.',
            'PANCAKES BRATEN ERSTE SEITE: Mit einer Suppenkelle ca. 1/3 Tasse Teig in die Pfanne geben und leicht kreisförmig verteilen (ca. 10cm Durchmesser). 3-4 Pancakes passen gleichzeitig in die Pfanne. 2-3 Minuten braten, ohne zu bewegen! Warte auf Blasen an der Oberfläche und feste Ränder.',
            'WENDEN UND FERTIG BRATEN: Sobald die Oberfläche viele kleine Blasen zeigt und die Ränder matt aussehen, mit einem breiten Pfannenwender vorsichtig umdrehen. Weitere 1-2 Minuten braten, bis die Unterseite goldbraun ist. Auf einen Teller legen und warm halten. Mit restlichem Teig wiederholen.',
            'BEEREN VORBEREITEN: Während die letzten Pancakes braten, Heidelbeeren und Himbeeren waschen und vorsichtig trocken tupfen. Falls gewünscht, die Hälfte der Beeren mit 1 EL Ahornsirup in einer kleinen Schüssel leicht zerdrücken - das gibt einen köstlichen Beeren-Sirup!',
            'SERVIEREN: Pro Portion 4-5 Pancakes auf einem Teller stapeln. Mit je 50g griechischem Joghurt toppen, dann frische und zerdrückte Beeren darüber verteilen. Optional mit Ahornsirup beträufeln oder mit Nüssen garnieren. Sofort servieren und genießen - 35g Protein für maximalen Muskelaufbau!'
        ]
    },
    {
        'name': 'Thunfisch-Steak mit Sesam-Kruste und Asia-Gemüse',
        'category': 'fitness',
        'description': 'Seltenes Thunfisch-Steak mit knuspriger Sesam-Kruste, serviert auf buntem Wok-Gemüse. Ein Restaurant-würdiges Gericht voller Omega-3-Fettsäuren, hochwertiger Proteine und Vitamine. Innen rosa, außen knusprig - pure Perfektion!',
        'image_url': 'https://images.unsplash.com/photo-1580959375944-0b8b6d6e9c13?w=800',
        'prep_time': 15,
        'cook_time': 10,
        'servings': 2,
        'difficulty': 'medium',
        'nutrition': {'calories': 380, 'protein': 42, 'carbs': 22, 'fat': 14, 'fiber': 6},
        'tags': ['high-protein', 'low-carb', 'dinner', 'omega-3'],
        'ingredients': [
            {'name': 'Thunfisch-Steak', 'quantity': '400', 'unit': 'g', 'keywords': ['thunfisch', 'tuna', 'fisch', 'steak'], 'priority': 3},
            {'name': 'Sesam schwarz', 'quantity': '3', 'unit': 'EL', 'keywords': ['sesam', 'sesame', 'schwarzsesam'], 'priority': 2},
            {'name': 'Sesam weiß', 'quantity': '3', 'unit': 'EL', 'keywords': ['sesam', 'sesame'], 'priority': 2},
            {'name': 'Pak Choi', 'quantity': '300', 'unit': 'g', 'keywords': ['pak choi', 'bok choy', 'chinakohl'], 'priority': 2},
            {'name': 'Paprika gelb', 'quantity': '1', 'unit': 'Stück', 'keywords': ['paprika', 'pepper'], 'priority': 2},
            {'name': 'Zuckerschoten', 'quantity': '150', 'unit': 'g', 'keywords': ['zuckerschote', 'snap pea', 'kefen'], 'priority': 2},
            {'name': 'Ingwer', 'quantity': '30', 'unit': 'g', 'keywords': ['ingwer', 'ginger'], 'priority': 2},
            {'name': 'Sojasauce', 'quantity': '4', 'unit': 'EL', 'keywords': ['soja', 'sauce'], 'priority': 1},
            {'name': 'Sesamöl', 'quantity': '2', 'unit': 'EL', 'keywords': ['sesamöl', 'sesame'], 'priority': 1},
        ],
        'instructions': [
            'THUNFISCH VORBEREITEN: Thunfisch-Steaks aus der Verpackung nehmen und mit Küchenpapier sehr gründlich trocken tupfen - je trockener, desto besser die Kruste! 30 Minuten bei Raumtemperatur ruhen lassen. Mit Meersalz und frisch gemahlenem Pfeffer von allen Seiten würzen.',
            'SESAM-MISCHUNG: Schwarzen und weißen Sesam in einer flachen Schüssel mischen. Optional: Sesam vorher 2 Minuten in einer trockenen Pfanne rösten, bis er duftet - das intensiviert den nussigen Geschmack! Diese bicolor Sesam-Kruste ist nicht nur lecker, sondern auch ein optisches Highlight.',
            'THUNFISCH PANIEREN: Thunfisch-Steaks in die Sesam-Mischung legen und von allen Seiten fest andrücken, sodass eine gleichmäßige, dicke Sesam-Kruste entsteht. Die Sesamkörner sollten gut haften. Tipp: Mit den Händen sanft andrücken für beste Haftung.',
            'GEMÜSE SCHNEIDEN: Pak Choi längs halbieren und gründlich waschen. Paprika entkernen und in dünne Streifen schneiden. Zuckerschoten waschen und Enden abschneiden. Ingwer schälen und in feine Stifte schneiden. Knoblauch (2 Zehen) fein hacken. Alles getrennt bereitstellen - beim Wok-Kochen geht alles schnell!',
            'WOK ERHITZEN: Großen Wok oder große Pfanne auf höchster Stufe 2-3 Minuten vorheizen, bis er wirklich heiß ist! Ein Wassertropfen sollte sofort verdampfen. 1 EL Erdnussöl hinzugeben und schwenken. Die Hitze ist der Schlüssel zu knackigem Gemüse mit Wok-Aroma!',
            'GEMÜSE ANBRATEN: Ingwer und Knoblauch in den Wok geben und 30 Sekunden unter ständigem Rühren braten, bis es duftet. Paprika hinzufügen und 1 Minute braten. Pak Choi und Zuckerschoten dazugeben, 2-3 Minuten unter ständigem Rühren bei höchster Hitze braten. Das Gemüse soll knackig bleiben!',
            'GEMÜSE WÜRZEN: Sojasauce und Sesamöl über das Gemüse gießen, durchschwenken und vom Herd nehmen. Optional: 1 TL Honig und Chiliflocken für Süße und Schärfe. Auf vorgewärmte Teller verteilen und warm halten. Das Gemüse sollte glänzen vom Sesamöl - ein Zeichen für perfektes Wok-Gericht!',
            'THUNFISCH BRATEN: Separate Pfanne auf höchster Stufe erhitzen. 1 EL neutrales Öl (Rapsöl) hinzugeben, bis es gerade anfängt zu rauchen. Thunfisch vorsichtig in die Pfanne legen. 1-1,5 Minuten pro Seite scharf anbraten. WICHTIG: Nicht länger! Der Thunfisch sollte außen eine goldbraune Sesam-Kruste haben, innen noch rosa-rot sein.',
            'RUHEN LASSEN: Thunfisch aus der Pfanne nehmen und 2 Minuten auf einem Schneidebrett ruhen lassen. Mit Alufolie locker abdecken. Das kurze Ruhen lässt die Säfte sich verteilen und die Kruste stabilisiert sich - essentiell für perfekten Anschnitt!',
            'SCHNEIDEN UND SERVIEREN: Thunfisch mit einem sehr scharfen Messer gegen die Faser in 1 cm dicke Scheiben schneiden. Tipp: Ein Sushi-Messer oder sehr scharfes Messer ist wichtig, damit die Sesam-Kruste nicht bröckelt! Scheiben fächerförmig auf dem Gemüse arrangieren. Die rosa Innenseite sollte sichtbar sein. Mit Frühlingszwiebeln, Koriander und Limettenspalten garnieren. Optional: Wasabi-Mayo dazu servieren. 42g Protein, Omega-3 satt!'
        ]
    },
    {
        'name': 'Rindfleisch-Gemüse-Pfanne mit Süßkartoffeln',
        'category': 'fitness',
        'description': 'Saftiges Rindfleisch mit buntem Gemüse und gerösteten Süßkartoffeln - die ultimative One-Pan-Mahlzeit für Muskelaufbau! Reich an Protein, Eisen, komplexen Kohlenhydraten und Vitaminen. Perfekt für Meal-Prep!',
        'image_url': 'https://images.unsplash.com/photo-1544025162-d76694265947?w=800',
        'prep_time': 15,
        'cook_time': 30,
        'servings': 2,
        'difficulty': 'easy',
        'nutrition': {'calories': 520, 'protein': 44, 'carbs': 42, 'fat': 18, 'fiber': 10},
        'tags': ['high-protein', 'dinner', 'meal-prep', 'one-pot'],
        'ingredients': [
            {'name': 'Rinderhüftsteak', 'quantity': '400', 'unit': 'g', 'keywords': ['rind', 'beef', 'hüfte', 'steak', 'rumpsteak'], 'priority': 3},
            {'name': 'Süßkartoffeln', 'quantity': '400', 'unit': 'g', 'keywords': ['süßkartoffel', 'sweet potato', 'batate'], 'priority': 3},
            {'name': 'Brokkoli', 'quantity': '300', 'unit': 'g', 'keywords': ['brokkoli', 'broccoli'], 'priority': 2},
            {'name': 'Paprika rot', 'quantity': '2', 'unit': 'Stück', 'keywords': ['paprika', 'pepper', 'bratpaprika'], 'priority': 2},
            {'name': 'Rote Zwiebeln', 'quantity': '2', 'unit': 'Stück', 'keywords': ['zwiebel', 'onion'], 'priority': 1},
            {'name': 'Knoblauch', 'quantity': '4', 'unit': 'Zehen', 'keywords': ['knoblauch', 'garlic'], 'priority': 1},
            {'name': 'Paprikapulver edelsüß', 'quantity': '2', 'unit': 'TL', 'keywords': ['paprika', 'gewürz'], 'priority': 1},
            {'name': 'Olivenöl', 'quantity': '3', 'unit': 'EL', 'keywords': ['öl', 'olive'], 'priority': 1},
        ],
        'instructions': [
            'OFEN VORHEIZEN: Backofen auf 220°C Ober-/Unterhitze vorheizen. Ein großes Backblech mit Backpapier auslegen. Bei dieser hohen Temperatur werden die Süßkartoffeln außen knusprig und innen cremig - perfekt!',
            'SÜSSKARTOFFELN VORBEREITEN: Süßkartoffeln gründlich waschen (Schale bleibt dran - voller Nährstoffe!). In 2 cm große Würfel schneiden, dabei gleichmäßige Größe anstreben für gleichmäßiges Garen. In eine große Schüssel geben, mit 1,5 EL Olivenöl, 1 TL Paprikapulver, Salz und Pfeffer vermengen.',
            'SÜSSKARTOFFELN RÖSTEN: Gewürzte Süßkartoffelwürfel auf dem Backblech verteilen - wichtig: In einer einzigen Schicht, nicht überlappen! Überlappung macht sie matschig statt knusprig. 25-30 Minuten rösten, nach 15 Minuten einmal wenden. Sie sollten goldbraun und an den Ecken karamellisiert sein.',
            'RINDFLEISCH VORBEREITEN: Während Kartoffeln im Ofen sind: Rinderhüftsteak aus der Verpackung nehmen, trocken tupfen und 10 Minuten bei Raumtemperatur ruhen lassen. In 2 cm große Würfel schneiden - gegen die Faser für maximale Zartheit! Großzügig mit Salz, Pfeffer würzen.',
            'GEMÜSE SCHNEIDEN: Brokkoli in kleine Röschen teilen, Strunk schälen und würfeln (nicht wegwerfen - essbar und lecker!). Paprika entkernen und in mundgerechte Stücke schneiden. Zwiebeln schälen und in Spalten schneiden. Knoblauch fein hacken. Alles bereitstellen - die Pfanne geht schnell!',
            'FLEISCH SCHARF ANBRATEN: Große Pfanne auf höchster Stufe erhitzen. 1 EL Olivenöl hinzugeben und Rindfleischwürfel in die sehr heiße Pfanne geben - nicht zu viele auf einmal, sonst kochen sie statt zu braten! In 2 Portionen arbeiten. Pro Seite 1-2 Minuten braten für schöne Kruste, innen medium. Herausnehmen und beiseite stellen.',
            'GEMÜSE ANBRATEN: In derselben Pfanne (mit den Fleischsäften!) bei mittlerer Hitze 0,5 EL Öl erhitzen. Zwiebeln 3 Minuten glasig dünsten. Knoblauch hinzufügen, 30 Sekunden braten. Paprika dazugeben und 4 Minuten unter Rühren braten, bis sie leicht weich sind.',
            'BROKKOLI GAREN: Brokkoli-Röschen in die Pfanne geben. 100ml Wasser oder Gemüsebrühe hinzugeben, Deckel auflegen und 4-5 Minuten dämpfen, bis der Brokkoli bissfest ist (leuchtend grün, nicht matschig!). Deckel abnehmen und restliche Flüssigkeit verdampfen lassen.',
            'ALLES KOMBINIEREN: Süßkartoffeln sollten jetzt fertig sein - aus dem Ofen nehmen. Gebratenes Rindfleisch zurück in die Pfanne zum Gemüse geben. Geröstete Süßkartoffeln hinzufügen. 1 TL Paprikapulver, Salz, Pfeffer und optional Chiliflocken darüber streuen. Alles vorsichtig vermengen und 1-2 Minuten erwärmen.',
            'FINALISIEREN UND SERVIEREN: Pfanne vom Herd nehmen. Mit frischer Petersilie oder Koriander bestreuen. Optional: Ein Klecks Hummus oder Kräuterquark dazu servieren für extra Cremigkeit. Auf zwei Teller verteilen oder in Meal-Prep-Boxen füllen. Diese Mahlzeit liefert 44g Protein, komplexe Carbs und gesunde Fette - perfekt für Gainz!'
        ]
    },
]

if __name__ == "__main__":
    conn = sqlite3.connect(DB_PATH)

    print(f"📝 Adding {len(RECIPES)} more FITNESS recipes to database...")

    for recipe in RECIPES:
        recipe_id = add_recipe(conn, recipe)
        print(f"  ✓ Added: {recipe['name']}")

    # Verify
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM recipes")
    total = cursor.fetchone()[0]

    print(f"\n✅ Success! Database now has {total} recipes total")

    conn.close()
