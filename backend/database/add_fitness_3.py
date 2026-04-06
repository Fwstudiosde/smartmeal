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
        'name': 'Gebackener Kabeljau mit Kräuterkruste und grünen Bohnen',
        'category': 'fitness',
        'description': 'Saftiger Kabeljau mit knuspriger Kräuter-Parmesan-Kruste und knackigen grünen Bohnen mit Mandeln. Reich an Protein (40g!), arm an Kalorien, perfekt für Definition. Ein leichtes, aber sättigendes Abendessen!',
        'image_url': 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=800',
        'prep_time': 15,
        'cook_time': 20,
        'servings': 2,
        'difficulty': 'easy',
        'nutrition': {'calories': 340, 'protein': 40, 'carbs': 18, 'fat': 12, 'fiber': 7},
        'tags': ['high-protein', 'low-carb', 'low-fat', 'dinner'],
        'ingredients': [
            {'name': 'Kabeljau-Filet', 'quantity': '500', 'unit': 'g', 'keywords': ['kabeljau', 'cod', 'fisch', 'dorsch'], 'priority': 3},
            {'name': 'Grüne Bohnen', 'quantity': '400', 'unit': 'g', 'keywords': ['bohne', 'grüne bohnen', 'prinzess'], 'priority': 2},
            {'name': 'Mandeln gehobelt', 'quantity': '30', 'unit': 'g', 'keywords': ['mandel', 'almond', 'gehobelt'], 'priority': 2},
            {'name': 'Paniermehl', 'quantity': '50', 'unit': 'g', 'keywords': ['paniermehl', 'semmelbrösel'], 'priority': 1},
            {'name': 'Parmesan', 'quantity': '30', 'unit': 'g', 'keywords': ['parmesan', 'käse', 'parmigiano'], 'priority': 2},
            {'name': 'Zitrone', 'quantity': '2', 'unit': 'Stück', 'keywords': ['zitrone', 'lemon'], 'priority': 1},
            {'name': 'Petersilie frisch', 'quantity': '1', 'unit': 'Bund', 'keywords': ['petersilie', 'parsley', 'kräuter'], 'priority': 1},
            {'name': 'Knoblauch', 'quantity': '3', 'unit': 'Zehen', 'keywords': ['knoblauch', 'garlic'], 'priority': 1},
            {'name': 'Olivenöl', 'quantity': '2', 'unit': 'EL', 'keywords': ['öl', 'olive'], 'priority': 1},
        ],
        'instructions': [
            'OFEN VORHEIZEN: Backofen auf 200°C Ober-/Unterhitze vorheizen. Ein Backblech mit Backpapier auslegen. Diese Temperatur sorgt dafür, dass der Fisch gart während die Kruste knusprig wird - perfektes Timing!',
            'KABELJAU VORBEREITEN: Kabeljau-Filets unter kaltem Wasser abspülen und mit Küchenpapier sehr gründlich trocken tupfen. Auf einem Schneidebrett prüfen, ob noch Gräten vorhanden sind (mit Fingern fühlen) und diese mit einer Pinzette entfernen. Mit Salz und Pfeffer würzen.',
            'KRÄUTERKRUSTE MIXEN: Petersilie waschen, trocken schütteln und fein hacken (ca. 3 EL). Knoblauch schälen und sehr fein hacken. Parmesan fein reiben. In einer Schüssel Paniermehl, geriebenen Parmesan, gehackte Petersilie, Knoblauch, Zest von 1 Zitrone, 1 Prise Salz und 1 EL Olivenöl vermischen. Die Mischung sollte leicht feucht und krümelig sein.',
            'FISCH MIT KRUSTE BEDECKEN: Kabeljau-Filets auf das vorbereitete Backblech legen. Die Kräuter-Parmesan-Mischung gleichmäßig auf die Oberseite der Filets drücken und fest andrücken, sodass eine ca. 5mm dicke Kruste entsteht. Mit den Händen sanft festdrücken - die Kruste sollte gut haften.',
            'KABELJAU BACKEN: Backblech in den vorgeheizten Ofen schieben und 15-18 Minuten backen, bis der Fisch gerade durchgegart ist (das Fleisch sollte undurchsichtig weiß sein und sich leicht mit einer Gabel teilen lassen) und die Kruste goldbraun ist. NICHT überbacken - Kabeljau wird sonst trocken!',
            'BOHNEN VORBEREITEN: Während der Fisch backt: Grüne Bohnen waschen und Enden abschneiden. Großen Topf mit Salzwasser zum Kochen bringen. Eine Schüssel mit Eiswasser bereitstellen - das stoppt den Garprozess und erhält die leuchtend grüne Farbe!',
            'BOHNEN BLANCHIEREN: Grüne Bohnen ins kochende Salzwasser geben und 4-5 Minuten kochen, bis sie bissfest sind (sie sollten noch Biss haben, aber nicht roh schmecken). Mit einem Sieb abgießen und sofort ins Eiswasser geben. Nach 2 Minuten herausnehmen und gut abtropfen lassen.',
            'MANDELN RÖSTEN: Während die Bohnen abkühlen, eine Pfanne auf mittlerer Hitze erwärmen. Gehobelte Mandeln ohne Fett 3-4 Minuten rösten, dabei ständig rühren, bis sie goldbraun sind und nussig duften. Vorsicht - sie verbrennen schnell! Aus der Pfanne nehmen.',
            'BOHNEN FINALISIEREN: In derselben Pfanne 1 EL Olivenöl erhitzen. Abgetropfte grüne Bohnen hinzugeben und 2-3 Minuten schwenken, bis sie heiß sind. Mit Salz, Pfeffer und Saft von 1/2 Zitrone würzen. Geröstete Mandeln darüber streuen und durchmischen. Die Kombination ist himmlisch!',
            'SERVIEREN: Kabeljau sollte jetzt fertig sein - aus dem Ofen nehmen. Auf vorgewärmte Teller legen, grüne Bohnen daneben arrangieren. Mit frischen Zitronenspalten garnieren und optional mit Petersilie bestreuen. Sofort servieren! Der Fisch ist saftig, die Kruste knusprig, die Bohnen knackig - Restaurant-Qualität mit 40g Protein und nur 340 Kalorien!'
        ]
    },
    {
        'name': 'Türkisches Hähnchen-Spieß mit Joghurt-Dip und Bulgur',
        'category': 'fitness',
        'description': 'Saftige Hähnchen-Spieße mit orientalischen Gewürzen, cremigem Tzatziki und protein-reichem Bulgur. Ein Geschmacksexplosion aus dem Nahen Osten - 45g Protein pro Portion! Perfekt zum Grillen oder aus dem Ofen.',
        'image_url': 'https://images.unsplash.com/photo-1603360946369-dc9bb6258143?w=800',
        'prep_time': 20,
        'cook_time': 15,
        'servings': 2,
        'difficulty': 'easy',
        'nutrition': {'calories': 480, 'protein': 45, 'carbs': 38, 'fat': 16, 'fiber': 8},
        'tags': ['high-protein', 'dinner', 'grilled', 'meal-prep'],
        'ingredients': [
            {'name': 'Hähnchenbrust-Filets', 'quantity': '500', 'unit': 'g', 'keywords': ['hähnchen', 'chicken', 'geflügel', 'brust', 'filet'], 'priority': 3},
            {'name': 'Bulgur', 'quantity': '150', 'unit': 'g', 'keywords': ['bulgur', 'bulgour'], 'priority': 2},
            {'name': 'Griechischer Joghurt', 'quantity': '300', 'unit': 'g', 'keywords': ['joghurt', 'greek', 'griechisch', 'skyr'], 'priority': 2},
            {'name': 'Gurke', 'quantity': '1', 'unit': 'Stück', 'keywords': ['gurke', 'salatgurke', 'cucumber'], 'priority': 2},
            {'name': 'Paprika rot', 'quantity': '1', 'unit': 'Stück', 'keywords': ['paprika', 'pepper', 'bratpaprika'], 'priority': 2},
            {'name': 'Rote Zwiebeln', 'quantity': '2', 'unit': 'Stück', 'keywords': ['zwiebel', 'onion'], 'priority': 1},
            {'name': 'Zitrone', 'quantity': '2', 'unit': 'Stück', 'keywords': ['zitrone', 'lemon'], 'priority': 1},
            {'name': 'Kreuzkümmel gemahlen', 'quantity': '2', 'unit': 'TL', 'keywords': ['kreuzkümmel', 'cumin'], 'priority': 1},
            {'name': 'Paprikapulver edelsüß', 'quantity': '2', 'unit': 'TL', 'keywords': ['paprika', 'gewürz'], 'priority': 1},
            {'name': 'Olivenöl', 'quantity': '3', 'unit': 'EL', 'keywords': ['öl', 'olive'], 'priority': 1},
        ],
        'instructions': [
            'MARINADE VORBEREITEN: In einer großen Schüssel 2 EL Olivenöl, Saft von 1 Zitrone, 2 TL Kreuzkümmel, 2 TL Paprikapulver, 1 TL Knoblauchpulver, 1 TL getrockneten Oregano, 1 Prise Zimt, Salz und frisch gemahlenen schwarzen Pfeffer vermischen. Diese Gewürzmischung ist authentisch türkisch und gibt unglaubliche Aromen!',
            'HÄHNCHEN MARINIEREN: Hähnchenbrust in 3-4 cm große Würfel schneiden - wichtig ist gleichmäßige Größe für gleichmäßiges Garen! Die Fleischwürfel in die Marinade geben und mit den Händen gut einmassieren, sodass jedes Stück bedeckt ist. Mindestens 15 Minuten marinieren, idealerweise 2 Stunden im Kühlschrank. Je länger, desto intensiver der Geschmack!',
            'SPIESZE VORBEREITEN: Falls Holzspieße verwendet werden, diese 30 Minuten in Wasser einweichen - verhindert Verbrennen! Paprika entkernen und in 3 cm große Stücke schneiden. 1 Zwiebel schälen und in Achtel teilen, Schichten trennen. Grill oder Backofen auf 220°C vorheizen.',
            'SPIESZE AUFSTECKEN: Hähnchenwürfel abwechselnd mit Paprika und Zwiebelstücken auf die Spieße stecken. Pro-Tipp: Mit Hähnchen beginnen und enden, Gemüse dazwischen. Nicht zu eng packen - Luft muss zirkulieren können für gleichmäßiges Garen. Ca. 4-5 Fleischstücke pro Spieß.',
            'BULGUR KOCHEN: 300ml Wasser oder Gemüsebrühe in einem Topf zum Kochen bringen. Bulgur hinzugeben, umrühren, Hitze auf niedrig stellen und zugedeckt 12-15 Minuten quellen lassen, bis die Flüssigkeit aufgesogen ist. Vom Herd nehmen und 5 Minuten zugedeckt ruhen lassen. Mit einer Gabel auflockern.',
            'TZATZIKI ZUBEREITEN: Während Bulgur kocht: Gurke halbieren, mit einem Löffel Kerne herauskratzen und grob raspeln. Geraspelte Gurke in ein sauberes Geschirrtuch geben und sehr fest auspressen - so viel Wasser wie möglich entfernen! 2 Knoblauchzehen fein pressen. In einer Schüssel griechischen Joghurt, ausgepresste Gurke, Knoblauch, 1 EL Olivenöl, Saft von 1/2 Zitrone, 1 TL getrocknete Minze, Salz und Pfeffer vermischen. Kalt stellen.',
            'SPIESZE GRILLEN METHODE 1 (GRILL): Spieße auf den vorgeheizten Grill legen und 12-15 Minuten grillen, dabei alle 3-4 Minuten wenden, bis das Hähnchen überall goldbraun ist und schöne Grillstreifen hat. Kerntemperatur sollte 74°C erreichen. Das Gemüse sollte leicht verkohlt und karamellisiert sein.',
            'SPIESZE BACKEN METHODE 2 (OFEN): Spieße auf ein mit Backpapier ausgelegtes Backblech legen oder auf einen Rost über ein Blech. Im vorgeheizten Ofen bei 220°C 15-18 Minuten backen, nach 8 Minuten einmal wenden. Die Spieße sollten an den Rändern leicht gebräunt sein.',
            'BULGUR VERFEINERN: Bulgur in eine Schüssel geben. 1 gewürfelte Zwiebel, 1 EL Olivenöl, Saft von 1/2 Zitrone, frisch gehackte Petersilie, Salz und Pfeffer unterrühren. Optional: Granatapfelkerne, gehackte Minze oder geröstete Pinienkerne für extra Geschmack und Textur hinzufügen.',
            'SERVIEREN: Bulgur auf Teller verteilen, Hähnchen-Spieße darauf oder daneben legen. Großzügig Tzatziki darüber geben oder separat servieren. Mit Zitronenspalten, frischer Petersilie und optional Sumach garnieren. Warm servieren! Diese Mahlzeit schmeckt wie im türkischen Restaurant - 45g Protein, authentische Gewürze, einfach köstlich!'
        ]
    },
    {
        'name': 'Overnight Protein-Oats mit Chia und Beeren',
        'category': 'fitness',
        'description': 'Cremige Overnight Oats mit Protein-Boost, Chia-Samen und frischen Beeren - das perfekte Fitness-Frühstück zum Vorbereiten! Einfach am Vorabend mixen, morgens genießen. 30g Protein, sättigt für Stunden!',
        'image_url': 'https://images.unsplash.com/photo-1590301157890-4810ed352733?w=800',
        'prep_time': 10,
        'cook_time': 0,
        'servings': 2,
        'difficulty': 'easy',
        'nutrition': {'calories': 380, 'protein': 30, 'carbs': 45, 'fat': 10, 'fiber': 12},
        'tags': ['high-protein', 'breakfast', 'meal-prep', 'no-cook'],
        'ingredients': [
            {'name': 'Haferflocken', 'quantity': '100', 'unit': 'g', 'keywords': ['hafer', 'oat', 'flocken', 'kernige'], 'priority': 3},
            {'name': 'Protein-Pulver Vanille', 'quantity': '60', 'unit': 'g', 'keywords': ['protein', 'whey', 'pulver', 'eiweiss'], 'priority': 3},
            {'name': 'Chia-Samen', 'quantity': '4', 'unit': 'EL', 'keywords': ['chia', 'samen', 'seed'], 'priority': 2},
            {'name': 'Mandelmilch ungesüßt', 'quantity': '400', 'unit': 'ml', 'keywords': ['mandelmilch', 'almond', 'pflanzenmilch'], 'priority': 2},
            {'name': 'Griechischer Joghurt', 'quantity': '200', 'unit': 'g', 'keywords': ['joghurt', 'greek', 'griechisch', 'skyr'], 'priority': 2},
            {'name': 'Banane', 'quantity': '1', 'unit': 'Stück', 'keywords': ['banane', 'banana'], 'priority': 2},
            {'name': 'Heidelbeeren', 'quantity': '150', 'unit': 'g', 'keywords': ['heidelbeere', 'blueberry', 'beere'], 'priority': 2},
            {'name': 'Himbeeren', 'quantity': '100', 'unit': 'g', 'keywords': ['himbeere', 'raspberry', 'beere'], 'priority': 2},
            {'name': 'Honig', 'quantity': '2', 'unit': 'EL', 'keywords': ['honig', 'honey'], 'priority': 1},
            {'name': 'Zimt gemahlen', 'quantity': '1', 'unit': 'TL', 'keywords': ['zimt', 'cinnamon'], 'priority': 1},
        ],
        'instructions': [
            'BASIS MIXEN: In einer großen Schüssel Haferflocken, Protein-Pulver, Chia-Samen und Zimt vermischen. Diese trockenen Zutaten zuerst zu kombinieren verhindert Klumpenbildung beim Hinzufügen der Flüssigkeit. Pro-Tipp: Chia-Samen sind wahre Nährstoff-Bomben mit Omega-3 und Ballaststoffen!',
            'FLÜSSIGKEIT HINZUFÜGEN: Mandelmilch langsam unter ständigem Rühren zur trockenen Mischung gießen. Gründlich verrühren, bis keine Klumpen mehr sichtbar sind. Das Protein-Pulver braucht etwas Zeit zum Auflösen - 1-2 Minuten gut rühren! Die Mischung wird dünnflüssig sein, aber über Nacht quellen die Haferflocken und Chia-Samen auf.',
            'JOGHURT EINRÜHREN: Griechischen Joghurt zur Hafer-Protein-Mischung geben und mit einem Löffel gut unterrühren, bis die Konsistenz cremig und gleichmäßig ist. Der Joghurt gibt extra Protein (ca. 10g!) und macht die Oats super cremig. Optional: 1-2 EL Honig für natürliche Süße einrühren.',
            'BANANE PÜRIEREN: Banane schälen und mit einer Gabel in einer separaten kleinen Schüssel zu einem glatten Püree zerdrücken. Bananenpüree zu der Oats-Mischung geben und unterrühren. Die Banane dient als natürlicher Süßstoff und gibt eine wunderbare cremige Konsistenz. Für Bananenbrot-Vibes!',
            'IN GLÄSER FÜLLEN: Die Overnight-Oats-Mischung gleichmäßig auf 2 verschließbare Gläser oder Schüsseln verteilen (je ca. 300ml pro Portion). Mit einem Deckel oder Frischhaltefolie fest verschließen. Die luftdichte Versiegelung ist wichtig, damit die Oats nicht austrocknen.',
            'ÜBER NACHT KÜHLEN: Gläser in den Kühlschrank stellen und mindestens 6 Stunden, idealerweise über Nacht (8-12 Stunden) quellen lassen. In dieser Zeit nehmen die Haferflocken die Flüssigkeit auf, werden weich und cremig, und die Chia-Samen bilden eine puddingartige Konsistenz. Die Geduld lohnt sich!',
            'BEEREN VORBEREITEN: Am nächsten Morgen: Heidelbeeren und Himbeeren waschen und trocken tupfen. Falls gewünscht, die Hälfte der Beeren leicht mit einer Gabel zerdrücken und mit 1 TL Honig vermischen - das gibt einen fruchtigen Beeren-Sirup!',
            'TOPPINGS HINZUFÜGEN: Overnight Oats aus dem Kühlschrank nehmen und umrühren - sie sollten jetzt dick und cremig sein, fast wie Pudding. Falls zu dick, 1-2 EL Mandelmilch unterrühren. Auf die Oberfläche frische und zerdrückte Beeren verteilen.',
            'OPTIONALE EXTRAS: Für zusätzliche Textur und Nährstoffe kannst du folgende Toppings hinzufügen: gehackte Mandeln, Walnüsse oder Pekannüsse (gesunde Fette), Kokosflocken (Geschmack), Kakao-Nibs (Antioxidantien), Leinsamen (Omega-3), Nussbutter (Cremigkeit) oder frische Minze (Frische).',
            'SERVIEREN: Sofort kalt genießen! Die Overnight Oats können auch mitgenommen werden - einfach im verschlossenen Glas transportieren. Haltbar im Kühlschrank bis zu 3 Tage, daher perfekt für Meal-Prep. Mit 30g Protein, 12g Ballaststoffen und komplexen Carbs bist du für Stunden satt und voller Energie!'
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
