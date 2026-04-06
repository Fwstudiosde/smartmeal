#!/usr/bin/env python3
"""
Add 4 more unique FITNESS recipes to SmartMeal database
Completing the set of 10 new recipes
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
                VALUES (?, ?)\n            """, (recipe_id, tag_result[0]))

    # Insert ingredient keywords for matching
    for ing in recipe_data['ingredients']:
        for keyword in ing.get('keywords', []):
            cursor.execute("""
                INSERT OR IGNORE INTO ingredient_keywords (ingredient_name, keyword, priority)
                VALUES (?, ?, ?)
            """, (ing['name'], keyword.lower(), ing.get('priority', 1)))

    conn.commit()
    return recipe_id

# 4 MORE FITNESS RECIPES - completing the set of 10
RECIPES = [
    {
        'name': 'Cottage Cheese Protein-Bowls mit Früchten',
        'category': 'fitness',
        'description': 'Cremiger Hüttenkäse mit frischen Früchten, Nüssen und Honig. Ein proteinreiches Frühstück (30g!) das in 5 Minuten fertig ist. Perfekt wenn es schnell gehen muss!',
        'image_url': 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=800',
        'prep_time': 5,
        'cook_time': 0,
        'servings': 2,
        'difficulty': 'easy',
        'nutrition': {'calories': 320, 'protein': 30, 'carbs': 32, 'fat': 10, 'fiber': 6},
        'tags': ['high-protein', 'breakfast', 'no-cook', 'quick'],
        'ingredients': [
            {'name': 'Hüttenkäse', 'quantity': '400', 'unit': 'g', 'keywords': ['hüttenkäse', 'cottage', 'käse', 'quark'], 'priority': 3},
            {'name': 'Heidelbeeren', 'quantity': '150', 'unit': 'g', 'keywords': ['heidelbeere', 'blueberry', 'beere'], 'priority': 2},
            {'name': 'Erdbeeren', 'quantity': '150', 'unit': 'g', 'keywords': ['erdbeere', 'strawberry', 'beere'], 'priority': 2},
            {'name': 'Walnüsse', 'quantity': '40', 'unit': 'g', 'keywords': ['walnuss', 'walnut', 'nuss'], 'priority': 2},
            {'name': 'Honig', 'quantity': '2', 'unit': 'EL', 'keywords': ['honig', 'honey'], 'priority': 1},
            {'name': 'Zimt gemahlen', 'quantity': '1', 'unit': 'TL', 'keywords': ['zimt', 'cinnamon'], 'priority': 1},
        ],
        'instructions': [
            'HÜTTENKÄSE VORBEREITEN: Hüttenkäse aus dem Kühlschrank nehmen. Falls zu fest, kurz bei Raumtemperatur stehen lassen für cremigere Konsistenz. In eine Schüssel geben und mit 1 EL Honig und 1/2 TL Zimt vermischen. Gut durchrühren bis gleichmäßig.',
            'ERDBEEREN SCHNEIDEN: Erdbeeren waschen, Grün entfernen und in Viertel oder dünne Scheiben schneiden. Die geschnittenen Erdbeeren in eine kleine Schüssel geben und mit 1 TL Honig vermischen - lässt sie etwas Saft ziehen.',
            'HEIDELBEEREN WASCHEN: Heidelbeeren in einem Sieb unter kaltem Wasser waschen und gut abtropfen lassen. Auf Küchenpapier verteilen und trocken tupfen. Frische Heidelbeeren sollten prall und fest sein.',
            'WALNÜSSE HACKEN: Walnüsse grob hacken - nicht zu fein! Einige größere Stücke geben Crunch. Optional: In einer Pfanne ohne Fett 2-3 Minuten rösten für intensiveren nussigen Geschmack, dann abkühlen lassen.',
            'HONIG-ZIMT-DRIZZLE: Restlichen Honig (1 EL) mit 1/2 TL Zimt in einer kleinen Schüssel vermischen. Bei Bedarf 1 TL warmes Wasser hinzufügen für bessere Verteilbarkeit. Diese Mischung zum Beträufeln bereitstellen.',
            'BOWLS SCHICHTEN: Gewürzten Hüttenkäse gleichmäßig auf zwei Schüsseln verteilen. Mit einem Löffel glatt streichen als Base. Der Hüttenkäse sollte die gesamte Unterseite bedecken.',
            'FRÜCHTE ARRANGIEREN: Erdbeeren und Heidelbeeren dekorativ auf dem Hüttenkäse verteilen. Man kann sie in Sektionen arrangieren oder kreisförmig - wie es gefällt! Die Farben sollten sich schön abheben.',
            'NÜSSE UND HONIG: Gehackte Walnüsse über die Früchte streuen. Mit der Honig-Zimt-Mischung beträufeln. Optional: Mit Minzblättchen, Kokosraspeln oder Kakao-Nibs garnieren.',
            'OPTIONAL PROTEIN-BOOST: Für extra Protein: 1 EL Protein-Pulver unter den Hüttenkäse rühren oder 1 EL Chia-Samen darüber streuen. Leinsamen funktionieren auch!',
            'SOFORT SERVIEREN: Diese Bowl schmeckt am besten frisch und kalt! Der cremige Hüttenkäse, saftige Früchte und knackige Nüsse sind eine perfekte Kombination. Mit 30g Protein in 5 Minuten - ideal für hektische Morgen!'
        ]
    },
    {
        'name': 'Vollkorn-Wraps mit Hähnchen und Hummus',
        'category': 'fitness',
        'description': 'Frische Vollkorn-Wraps gefüllt mit saftigem Hähnchen, cremigem Hummus und knackigem Gemüse. High-Protein (38g!), perfekt für unterwegs. Das ultimative Fitness-Lunch!',
        'image_url': 'https://images.unsplash.com/photo-1626700051175-6818013e1d4f?w=800',
        'prep_time': 15,
        'cook_time': 15,
        'servings': 2,
        'difficulty': 'easy',
        'nutrition': {'calories': 520, 'protein': 38, 'carbs': 52, 'fat': 18, 'fiber': 10},
        'tags': ['high-protein', 'lunch', 'quick'],
        'ingredients': [
            {'name': 'Hähnchenbrust-Filets', 'quantity': '300', 'unit': 'g', 'keywords': ['hähnchen', 'chicken', 'geflügel', 'brust', 'filet'], 'priority': 3},
            {'name': 'Vollkorn-Wraps', 'quantity': '4', 'unit': 'Stück', 'keywords': ['wrap', 'tortilla', 'vollkorn'], 'priority': 2},
            {'name': 'Hummus', 'quantity': '150', 'unit': 'g', 'keywords': ['hummus', 'kichererbse'], 'priority': 2},
            {'name': 'Salat-Mix', 'quantity': '100', 'unit': 'g', 'keywords': ['salat', 'mix', 'multicolor'], 'priority': 2},
            {'name': 'Tomaten', 'quantity': '2', 'unit': 'Stück', 'keywords': ['tomate', 'tomato'], 'priority': 2},
            {'name': 'Gurke', 'quantity': '1', 'unit': 'Stück', 'keywords': ['gurke', 'salatgurke', 'cucumber'], 'priority': 2},
            {'name': 'Feta', 'quantity': '60', 'unit': 'g', 'keywords': ['feta', 'käse', 'schafskäse'], 'priority': 2},
            {'name': 'Paprikapulver edelsüß', 'quantity': '1', 'unit': 'TL', 'keywords': ['paprika', 'gewürz'], 'priority': 1},
            {'name': 'Olivenöl', 'quantity': '1', 'unit': 'EL', 'keywords': ['öl', 'olive'], 'priority': 1},
        ],
        'instructions': [
            'HÄHNCHEN WÜRZEN: Hähnchenbrust mit Küchenpapier trocken tupfen. Mit Salz, Pfeffer, Paprikapulver, 1 TL Knoblauchpulver und 1 TL Oregano von beiden Seiten würzen. Mit den Händen in die Oberfläche einmassieren.',
            'HÄHNCHEN BRATEN: Pfanne auf mittlerer bis hoher Hitze erhitzen. Olivenöl hinzugeben und Hähnchenbrust 6-7 Minuten pro Seite braten, bis sie durchgegart ist (Kerntemperatur 74°C). Die Oberfläche sollte goldbraun sein.',
            'HÄHNCHEN RUHEN: Gebratenes Hähnchen auf ein Schneidebrett legen und mit Alufolie abdecken. 5 Minuten ruhen lassen - die Säfte verteilen sich. Dann gegen die Faser in dünne Streifen schneiden.',
            'GEMÜSE VORBEREITEN: Während das Hähnchen ruht: Salat waschen und trocken schleudern. Tomaten in dünne Scheiben schneiden. Gurke längs halbieren, Kerne mit einem Löffel herauskratzen und in dünne Halbmonde schneiden. Feta in kleine Würfel schneiden.',
            'WRAPS ERWÄRMEN: Vollkorn-Wraps einzeln in einer trockenen Pfanne bei mittlerer Hitze je 30 Sekunden pro Seite erwärmen, bis sie weich und biegsam sind. Alternativ: 10 Sekunden in der Mikrowelle. Warme Wraps lassen sich besser rollen!',
            'HUMMUS VERTEILEN: Jeden Wrap auf eine flache Arbeitsfläche legen. 2-3 EL Hummus in der Mitte verteilen und mit einem Löffel dünn ausstreichen - etwa 2cm vom Rand entfernt lassen. Der Hummus ist Basis und Kleber zugleich.',
            'FÜLLUNG SCHICHTEN: Auf das Hummus eine Handvoll Salat legen. Darauf Hähnchen-Streifen, Tomatenscheiben, Gurkenscheiben und Feta-Würfel verteilen. Nicht zu viel füllen - sonst lässt sich der Wrap nicht rollen!',
            'WRAPS ROLLEN: Untere Seite des Wraps über die Füllung klappen. Linke und rechte Seite nach innen falten. Dann straff von unten nach oben aufrollen, dabei die Füllung fest andrücken. Der Wrap sollte fest gerollt sein.',
            'WRAPS FIXIEREN: Mit einem Zahnstocher fixieren oder fest in Backpapier einwickeln. Optional: Die Wraps in einer Pfanne mit etwas Butter von allen Seiten kurz anbraten für knusprige Oberfläche - wie ein Burrito!',
            'SERVIEREN: Wraps diagonal halbieren für schöne Optik - man sieht alle Schichten! Sofort servieren oder in Backpapier/Alufolie einwickeln für unterwegs. Mit 38g Protein, frischem Gemüse und cremigem Hummus - das perfekte Lunch to go!'
        ]
    },
    {
        'name': 'Rührei mit Lachs und Avocado auf Vollkornbrot',
        'category': 'fitness',
        'description': 'Cremiges Rührei mit geräuchertem Lachs, cremiger Avocado auf geröstetem Vollkornbrot. Luxuriöses Fitness-Frühstück mit 34g Protein und Omega-3-Fettsäuren. Wie im 5-Sterne-Hotel!',
        'image_url': 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=800',
        'prep_time': 10,
        'cook_time': 10,
        'servings': 2,
        'difficulty': 'easy',
        'nutrition': {'calories': 480, 'protein': 34, 'carbs': 32, 'fat': 24, 'fiber': 8},
        'tags': ['high-protein', 'breakfast', 'omega-3'],
        'ingredients': [
            {'name': 'Eier', 'quantity': '6', 'unit': 'Stück', 'keywords': ['ei', 'egg', 'freiland', 'bio-eier'], 'priority': 3},
            {'name': 'Räucherlachs', 'quantity': '120', 'unit': 'g', 'keywords': ['lachs', 'räucherlachs', 'salmon', 'smoked'], 'priority': 3},
            {'name': 'Avocado', 'quantity': '1', 'unit': 'Stück', 'keywords': ['avocado'], 'priority': 2},
            {'name': 'Vollkornbrot', 'quantity': '4', 'unit': 'Scheiben', 'keywords': ['brot', 'vollkorn', 'bread'], 'priority': 2},
            {'name': 'Butter', 'quantity': '20', 'unit': 'g', 'keywords': ['butter'], 'priority': 1},
            {'name': 'Milch', 'quantity': '50', 'unit': 'ml', 'keywords': ['milch', 'milk', 'vollmilch'], 'priority': 1},
            {'name': 'Schnittlauch frisch', 'quantity': '1', 'unit': 'Bund', 'keywords': ['schnittlauch', 'chives', 'kräuter'], 'priority': 1},
            {'name': 'Zitrone', 'quantity': '1', 'unit': 'Stück', 'keywords': ['zitrone', 'lemon'], 'priority': 1},
        ],
        'instructions': [
            'EIER VORBEREITEN: Eier in eine Schüssel aufschlagen. Milch, eine Prise Salz und frisch gemahlenen Pfeffer hinzufügen. Mit einer Gabel oder Schneebesen verquirlen, bis die Mischung homogen und leicht schaumig ist - aber nicht zu viel, sonst werden die Eier zäh!',
            'SCHNITTLAUCH SCHNEIDEN: Schnittlauch waschen, trocken tupfen und in feine Röllchen schneiden. Die Hälfte zur Eiermischung geben, die andere Hälfte zum Garnieren aufbewahren. Frische Kräuter machen den Unterschied!',
            'AVOCADO VORBEREITEN: Avocado halbieren, Kern entfernen, schälen. Eine Hälfte in dünne Scheiben schneiden, die andere Hälfte mit einer Gabel zerdrücken, mit Saft von 1/2 Zitrone, Salz und Pfeffer würzen - selbstgemachte Guacamole!',
            'BROT TOASTEN: Vollkornbrot-Scheiben im Toaster oder in einer Pfanne goldbraun rösten. Die Scheiben sollten außen knusprig sein, aber innen noch etwas Biss haben. Warm halten.',
            'RÜHREI PFANNE VORBEREITEN: Beschichtete Pfanne auf niedriger bis mittlerer Hitze erwärmen - NICHT zu heiß! Die Temperatur ist der Schlüssel zu cremigem Rührei. 15g Butter in der Pfanne schmelzen lassen, bis sie schäumt.',
            'RÜHREI LANGSAM GAREN: Eiermischung in die Pfanne gießen. 30 Sekunden stehen lassen, dann mit einem Silikonspatel vorsichtig vom Rand zur Mitte schieben. Immer wieder vom Rand zur Mitte, sodass große, cremige Flocken entstehen. LANGSAM arbeiten - das dauert 3-4 Minuten!',
            'RÜHREI FINAL: Wenn die Eier noch leicht feucht aber nicht mehr flüssig sind, Pfanne vom Herd nehmen - sie garen in der Restwärme nach! Restliche Butter (5g) unterrühren für extra Cremigkeit. Bei zu langer Garzeit werden sie trocken!',
            'TOAST BELEGEN BASIS: Getoastete Brotscheiben auf Teller legen. Zwei Scheiben mit zerdrückter Avocado bestreichen, die anderen zwei mit einem dünnen Film Butter (optional). Das Fett verhindert, dass das Brot matschig wird.',
            'RÜHREI UND LACHS ARRANGIEREN: Cremiges Rührei gleichmäßig auf alle 4 Brotscheiben verteilen. Räucherlachs in Streifen zupfen oder rollen und auf das Rührei legen. Avocadoscheiben daneben oder darauf arrangieren.',
            'GARNIEREN UND SERVIEREN: Mit restlichem Schnittlauch bestreuen. Mit frisch gemahlenem schwarzem Pfeffer, Zitronenzesten und optional Kapern garnieren. Zitronenspalten dazu servieren. Sofort genießen - cremiges Rührei, salziger Lachs, buttrige Avocado auf knusprigem Toast. 34g Protein, Omega-3 satt - Luxus-Frühstück!'
        ]
    },
    {
        'name': 'Fitness-Meatballs mit Vollkorn-Spaghetti und Tomatensauce',
        'category': 'fitness',
        'description': 'Saftige, selbstgemachte Fleischbällchen aus Rinderhack mit Vollkorn-Spaghetti in würziger Tomatensauce. Mit 44g Protein! Ein Klassiker neu interpretiert - weniger Fett, mehr Protein, voller Geschmack!',
        'image_url': 'https://images.unsplash.com/photo-1622973536968-3ead9e780960?w=800',
        'prep_time': 20,
        'cook_time': 30,
        'servings': 2,
        'difficulty': 'medium',
        'nutrition': {'calories': 620, 'protein': 44, 'carbs': 68, 'fat': 18, 'fiber': 12},
        'tags': ['high-protein', 'dinner', 'family-friendly'],
        'ingredients': [
            {'name': 'Rinderhackfleisch mager', 'quantity': '400', 'unit': 'g', 'keywords': ['rind', 'hack', 'hackfleisch', 'gehacktes', 'beef'], 'priority': 3},
            {'name': 'Vollkorn-Spaghetti', 'quantity': '200', 'unit': 'g', 'keywords': ['pasta', 'spaghetti', 'vollkorn', 'nudeln'], 'priority': 2},
            {'name': 'Tomaten gehackt Dose', 'quantity': '400', 'unit': 'g', 'keywords': ['tomate', 'tomaten', 'dose', 'gehackt'], 'priority': 2},
            {'name': 'Tomatenmark', 'quantity': '2', 'unit': 'EL', 'keywords': ['tomate', 'mark'], 'priority': 1},
            {'name': 'Paniermehl', 'quantity': '40', 'unit': 'g', 'keywords': ['paniermehl', 'semmelbrösel'], 'priority': 1},
            {'name': 'Eier', 'quantity': '1', 'unit': 'Stück', 'keywords': ['ei', 'egg', 'freiland', 'bio-eier'], 'priority': 2},
            {'name': 'Parmesan', 'quantity': '40', 'unit': 'g', 'keywords': ['parmesan', 'käse', 'parmigiano'], 'priority': 2},
            {'name': 'Zwiebeln', 'quantity': '1', 'unit': 'Stück', 'keywords': ['zwiebel', 'onion'], 'priority': 1},
            {'name': 'Knoblauch', 'quantity': '4', 'unit': 'Zehen', 'keywords': ['knoblauch', 'garlic'], 'priority': 1},
            {'name': 'Basilikum frisch', 'quantity': '1', 'unit': 'Bund', 'keywords': ['basilikum', 'basil', 'kräuter'], 'priority': 1},
            {'name': 'Olivenöl', 'quantity': '2', 'unit': 'EL', 'keywords': ['öl', 'olive'], 'priority': 1},
        ],
        'instructions': [
            'MEATBALLS VORBEREITEN: In einer großen Schüssel Rinderhackfleisch, 1 Ei, Paniermehl, 20g geriebenen Parmesan, 2 gehackte Knoblauchzehen, 1 TL Oregano, Salz und Pfeffer vermischen. Mit Händen gut durchkneten, bis die Masse bindet - nicht zu lange, sonst wird sie zäh!',
            'MEATBALLS FORMEN: Hände leicht anfeuchten. Aus der Hackfleischmasse gleichgroße Kugeln formen - etwa walnussgroß (ca. 12 Stück). Auf einem Teller ablegen. Gleichmäßige Größe ist wichtig, damit alle zur gleichen Zeit fertig sind!',
            'OFEN VORHEIZEN: Backofen auf 200°C vorheizen. Ein Backblech mit Backpapier auslegen und leicht mit Öl bepinseln. Diese Methode ist gesünder als Braten in der Pfanne - weniger Fett, gleichmäßigeres Garen!',
            'MEATBALLS BACKEN: Fleischbällchen auf dem Backblech verteilen - nicht zu eng. Im Ofen 20-25 Minuten backen, nach 12 Minuten einmal vorsichtig wenden. Sie sollten außen gebräunt und durchgegart sein (Kerntemperatur 70°C).',
            'TOMATENSAUCE STARTEN: Während Meatballs backen: Zwiebel fein würfeln, restlichen Knoblauch hacken. In einem großen Topf 1 EL Olivenöl erhitzen, Zwiebel 4 Minuten glasig dünsten. Knoblauch hinzufügen, 1 Minute mitdünsten.',
            'TOMATENSAUCE KOCHEN: Tomatenmark einrühren und 2 Minuten anrösten - das entfaltet die Aromen! Gehackte Tomaten hinzugeben, mit 100ml Wasser ablöschen. Salz, Pfeffer, 1 Prise Zucker, 1 TL Oregano und 5-6 zerrissene Basilikumblätter hinzufügen. 15 Minuten köcheln lassen.',
            'SPAGHETTI KOCHEN: Großen Topf mit reichlich Salzwasser zum Kochen bringen. Vollkorn-Spaghetti nach Packungsanweisung kochen (meist 10-12 Minuten) - al dente! 1 Tasse Nudelwasser aufbewahren, dann abgießen.',
            'MEATBALLS ZUR SAUCE: Fertig gebackene Meatballs vorsichtig in die köchelnde Tomatensauce geben. 5 Minuten in der Sauce ziehen lassen, damit sie die Aromen aufnehmen. Bei Bedarf etwas Nudelwasser hinzufügen für gewünschte Konsistenz.',
            'SPAGHETTI MIT SAUCE: Abgegossene Spaghetti entweder direkt zur Sauce geben und durchmischen, oder separat auf Teller verteilen. Falls direkt in die Sauce: etwas Nudelwasser und 1 EL Olivenöl hinzufügen, durchschwenken.',
            'SERVIEREN: Spaghetti auf Teller verteilen, Meatballs darauf arrangieren, Sauce darüber geben. Mit geriebenem Parmesan bestreuen und frischen Basilikumblättern garnieren. Optional: Ein Klecks Ricotta für extra Cremigkeit. Mit 44g Protein, Vollkorn-Carbs - Italienische Küche trifft Fitness!'
        ]
    },
]

if __name__ == "__main__":
    conn = sqlite3.connect(DB_PATH)

    print(f"📝 Adding {len(RECIPES)} more unique FITNESS recipes to database...")

    for recipe in RECIPES:
        recipe_id = add_recipe(conn, recipe)
        print(f"  ✓ Added: {recipe['name']}")

    # Verify
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM recipes")
    total = cursor.fetchone()[0]

    print(f"\n✅ Success! Database now has {total} recipes total")

    conn.close()
