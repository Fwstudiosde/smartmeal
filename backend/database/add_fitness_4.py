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
        'name': 'Garnelen-Zucchini-Nudeln mit Knoblauch-Zitronen-Sauce',
        'category': 'fitness',
        'description': 'Saftige Garnelen auf low-carb Zucchini-Nudeln mit aromatischer Knoblauch-Zitronen-Sauce. Ein leichtes, proteinreiches Gericht (38g Protein!), das in 15 Minuten fertig ist. Perfekt für schnelle Fitness-Mahlzeiten!',
        'image_url': 'https://images.unsplash.com/photo-1633321702181-b1e7f1f6b5b5?w=800',
        'prep_time': 10,
        'cook_time': 10,
        'servings': 2,
        'difficulty': 'easy',
        'nutrition': {'calories': 280, 'protein': 38, 'carbs': 12, 'fat': 10, 'fiber': 4},
        'tags': ['high-protein', 'low-carb', 'quick', 'dinner'],
        'ingredients': [
            {'name': 'Garnelen roh geschält', 'quantity': '500', 'unit': 'g', 'keywords': ['garnele', 'shrimp', 'prawn', 'krabbe'], 'priority': 3},
            {'name': 'Zucchini', 'quantity': '4', 'unit': 'Stück', 'keywords': ['zucchini'], 'priority': 2},
            {'name': 'Knoblauch', 'quantity': '5', 'unit': 'Zehen', 'keywords': ['knoblauch', 'garlic'], 'priority': 1},
            {'name': 'Zitrone', 'quantity': '2', 'unit': 'Stück', 'keywords': ['zitrone', 'lemon'], 'priority': 1},
            {'name': 'Petersilie frisch', 'quantity': '1', 'unit': 'Bund', 'keywords': ['petersilie', 'parsley', 'kräuter'], 'priority': 1},
            {'name': 'Olivenöl', 'quantity': '2', 'unit': 'EL', 'keywords': ['öl', 'olive'], 'priority': 1},
            {'name': 'Chiliflocken', 'quantity': '1', 'unit': 'TL', 'keywords': ['chili', 'flocken'], 'priority': 1, 'optional': True},
        ],
        'instructions': [
            'ZUCCHINI-NUDELN VORBEREITEN: Zucchini waschen und die Enden abschneiden. Mit einem Spiralschneider zu langen, dünnen Nudeln verarbeiten. Falls kein Spiralschneider vorhanden: Mit einem Gemüseschäler lange, dünne Streifen schneiden. Tipp: Die Zucchini-Nudeln (Zoodles) sollten nicht zu dünn sein, sonst werden sie matschig!',
            'ZOODLES ENTWÄSSERN: Die Zucchini-Nudeln in eine Schüssel geben, mit 1 TL Salz bestreuen und gut durchmischen. 10 Minuten stehen lassen - das Salz zieht überschüssiges Wasser heraus. Dann in ein sauberes Geschirrtuch geben und sehr fest auspressen. Dieser Schritt ist essentiell, um wässrige Nudeln zu vermeiden!',
            'GARNELEN VORBEREITEN: Falls die Garnelen gefroren sind, unter kaltem Wasser auftauen und gründlich trocken tupfen. Garnelen sollten komplett trocken sein für bestes Anbraten! Mit Salz, Pfeffer und einer Prise Paprikapulver würzen. Pro-Tipp: Trockene Garnelen = knusprige Oberfläche!',
            'KNOBLAUCH UND KRÄUTER SCHNEIDEN: Knoblauch schälen und in sehr dünne Scheiben schneiden (nicht pressen - das gibt zu viel Schärfe!). Petersilie waschen, trocken schütteln und grob hacken. Zitrone halbieren - eine zum Auspressen bereitstellen, die andere in Spalten schneiden für die Garnitur.',
            'GARNELEN SCHARF ANBRATEN: Große Pfanne auf hoher Hitze 2 Minuten erhitzen, bis sie sehr heiß ist. 1 EL Olivenöl hinzugeben und sofort die Garnelen in einer einzigen Schicht verteilen - nicht überlappen! 90 Sekunden pro Seite braten, ohne zu bewegen. Sie sollten rosa werden und eine leichte Kruste haben. Aus der Pfanne nehmen und beiseite stellen.',
            'KNOBLAUCH-ZITRONEN-SAUCE: Hitze auf mittel reduzieren. 1 EL Olivenöl in die gleiche Pfanne geben, Knoblauchscheiben hinzufügen und 1 Minute goldgelb braten - nicht braun werden lassen! Saft von 1,5 Zitronen, Chiliflocken (nach Geschmack) und 3 EL Wasser hinzugeben. 30 Sekunden köcheln lassen.',
            'ZOODLES GAREN: Ausgedrückte Zucchini-Nudeln in die Pfanne zur Knoblauch-Zitronen-Sauce geben. Mit Zange oder Gabeln durchmischen und 2-3 Minuten schwenken, bis die Zoodles al dente sind - sie sollten noch etwas Biss haben! WICHTIG: Nicht länger als 3 Minuten, sonst werden sie matschig.',
            'GARNELEN ZURÜCKGEBEN: Gebratene Garnelen zurück in die Pfanne geben und 1 Minute durchschwenken, bis alles heiß ist und die Garnelen mit Sauce überzogen sind. Die Restwärme erwärmt die Garnelen perfekt, ohne sie zu überkochen - überbackene Garnelen werden gummiartig!',
            'PETERSILIE EINRÜHREN: Gehackte Petersilie zur Pfanne geben und durchmischen. Mit Salz und frisch gemahlenem schwarzem Pfeffer abschmecken. Optional: Eine Prise Muskatnuss für extra Tiefe hinzufügen. Die frischen Kräuter sollten gerade welken und ihren Duft freisetzen.',
            'SERVIEREN: Zucchini-Nudeln mit Garnelen auf vorgewärmte Teller verteilen. Mit frischen Zitronenspalten, extra Petersilie und optional Parmesan garnieren. Sofort servieren, solange die Zoodles noch bissfest sind! Mit 38g Protein, nur 280 Kalorien und 12g Carbs ist dieses Gericht perfekt für Definition - und es schmeckt wie im 5-Sterne-Restaurant!'
        ]
    },
    {
        'name': 'Rindersteak mit Süßkartoffel-Pommes und Rucola-Salat',
        'category': 'fitness',
        'description': 'Perfekt gegrilltes Rindersteak (medium-rare) mit knusprigen Süßkartoffel-Pommes aus dem Ofen und frischem Rucola-Salat. Hochwertige Proteine (48g!), komplexe Kohlenhydrate und gesunde Fette - das ultimative Post-Workout-Dinner!',
        'image_url': 'https://images.unsplash.com/photo-1600891964599-f61ba0e24092?w=800',
        'prep_time': 15,
        'cook_time': 30,
        'servings': 2,
        'difficulty': 'medium',
        'nutrition': {'calories': 620, 'protein': 48, 'carbs': 45, 'fat': 26, 'fiber': 8},
        'tags': ['high-protein', 'dinner', 'meal-prep'],
        'ingredients': [
            {'name': 'Rumpsteak', 'quantity': '500', 'unit': 'g', 'keywords': ['rind', 'beef', 'steak', 'rumpsteak', 'hüftsteak'], 'priority': 3},
            {'name': 'Süßkartoffeln', 'quantity': '500', 'unit': 'g', 'keywords': ['süßkartoffel', 'sweet potato', 'batate'], 'priority': 3},
            {'name': 'Rucola', 'quantity': '100', 'unit': 'g', 'keywords': ['rucola', 'arugula', 'rauke', 'salat'], 'priority': 2},
            {'name': 'Parmesan', 'quantity': '40', 'unit': 'g', 'keywords': ['parmesan', 'käse', 'parmigiano'], 'priority': 2},
            {'name': 'Tomaten Cherry', 'quantity': '150', 'unit': 'g', 'keywords': ['tomate', 'cherry', 'miniroma'], 'priority': 2},
            {'name': 'Knoblauch', 'quantity': '3', 'unit': 'Zehen', 'keywords': ['knoblauch', 'garlic'], 'priority': 1},
            {'name': 'Rosmarin frisch', 'quantity': '3', 'unit': 'Zweige', 'keywords': ['rosmarin', 'rosemary', 'kräuter'], 'priority': 1},
            {'name': 'Olivenöl', 'quantity': '4', 'unit': 'EL', 'keywords': ['öl', 'olive'], 'priority': 1},
            {'name': 'Balsamico-Essig', 'quantity': '2', 'unit': 'EL', 'keywords': ['balsamico', 'essig', 'vinegar'], 'priority': 1},
        ],
        'instructions': [
            'OFEN VORHEIZEN: Backofen auf 220°C Ober-/Unterhitze vorheizen. Ein großes Backblech mit Backpapier auslegen. Diese hohe Temperatur sorgt für knusprige Pommes mit weichem Kern - wie aus der Friteuse, aber gesünder!',
            'SÜSSKARTOFFEL-POMMES SCHNEIDEN: Süßkartoffeln gründlich waschen (Schale bleibt dran - voller Nährstoffe und Ballaststoffe!). In gleichmäßig dicke Pommes schneiden - ca. 1cm dick. Pro-Tipp: Gleichmäßige Dicke ist entscheidend, damit alle Pommes zur gleichen Zeit fertig werden. Zu dünne Pommes verbrennen, zu dicke bleiben roh innen.',
            'POMMES WÜRZEN: Süßkartoffel-Pommes in eine große Schüssel geben. Mit 2 EL Olivenöl, 1 TL Paprikapulver, 1 TL Knoblauchpulver, 1/2 TL Kreuzkümmel, Salz und Pfeffer würzen. Mit den Händen gut durchmischen, bis jede Pommes gleichmäßig mit Öl und Gewürzen überzogen ist.',
            'POMMES BACKEN: Gewürzte Pommes auf dem Backblech in einer einzigen Schicht verteilen - sehr wichtig: nicht überlappen, sonst dämpfen sie statt zu backen! Im vorgeheizten Ofen 25-30 Minuten backen, nach 15 Minuten einmal wenden. Sie sollten außen knusprig und goldbraun, innen weich sein.',
            'STEAK VORBEREITEN: Rumpsteak aus dem Kühlschrank nehmen und 30 Minuten bei Raumtemperatur ruhen lassen - essentiell für gleichmäßiges Garen! Mit Küchenpapier sehr gründlich trocken tupfen. Großzügig mit Meersalz und frisch gemahlenem schwarzem Pfeffer von allen Seiten würzen. Raumtemperatur = gleichmäßige Kruste = perfektes Steak!',
            'PFANNE VORBEREITEN: 10 Minuten bevor die Pommes fertig sind: Schwere Pfanne (am besten Gusseisen) auf höchster Stufe 3-4 Minuten vorheizen, bis sie raucht. 1 EL neutrales Öl mit hohem Rauchpunkt (Rapsöl oder Erdnussöl) hinzugeben. Das Öl sollte gerade anfangen zu schimmern.',
            'STEAK BRATEN: Steak vorsichtig in die sehr heiße Pfanne legen - es sollte sofort laut zischen! 2-3 Minuten pro Seite braten für medium-rare (Kerntemperatur 52-55°C), ohne zu bewegen. In der letzten Minute 1 EL Butter, zerdrückte Knoblauchzehen und Rosmarinzweige zur Pfanne geben. Steak mit der aromatischen Butter begießen.',
            'STEAK RUHEN LASSEN: Steak aus der Pfanne nehmen, auf ein Schneidebrett legen und mit Alufolie locker abdecken. 8-10 Minuten ruhen lassen - dies ist NICHT optional! In dieser Zeit verteilen sich die Säfte gleichmäßig im Fleisch. Zu frühes Schneiden = ausgelaufene Säfte = trockenes Steak. Geduld wird mit Saftigkeit belohnt!',
            'SALAT VORBEREITEN: Während das Steak ruht: Rucola waschen und trocken schleudern. Cherry-Tomaten halbieren. Parmesan in dünne Späne hobeln. In einer großen Schüssel 2 EL Olivenöl, 2 EL Balsamico-Essig, 1 TL Honig, Salz und Pfeffer zu einem Dressing verquirlen. Rucola und Tomaten hinzugeben und vorsichtig durchmischen.',
            'SERVIEREN: Steak gegen die Faser in 1cm dicke Scheiben schneiden - gegen die Faser macht es zarter! Auf vorgewärmte Teller legen. Süßkartoffel-Pommes (sollten jetzt fertig sein) daneben arrangieren. Rucola-Salat auf der Seite platzieren und mit Parmesan-Spänen toppen. Optional: Steaksauce oder Kräuterbutter dazu servieren. Mit 48g Protein, komplexen Carbs und gesunden Fetten - das perfekte Bodybuilder-Dinner!'
        ]
    },
    {
        'name': 'Mexikanische Hähnchen-Burrito-Bowl mit schwarzen Bohnen',
        'category': 'fitness',
        'description': 'Würzige Hähnchen-Burrito-Bowl mit Reis, schwarzen Bohnen, Mais und frischen Toppings. Eine explosion mexikanischer Aromen mit 42g Protein! Perfekt für Meal-Prep - schmeckt auch am nächsten Tag fantastisch.',
        'image_url': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800',
        'prep_time': 20,
        'cook_time': 25,
        'servings': 2,
        'difficulty': 'easy',
        'nutrition': {'calories': 550, 'protein': 42, 'carbs': 58, 'fat': 16, 'fiber': 14},
        'tags': ['high-protein', 'lunch', 'dinner', 'meal-prep'],
        'ingredients': [
            {'name': 'Hähnchenbrust-Filets', 'quantity': '400', 'unit': 'g', 'keywords': ['hähnchen', 'chicken', 'geflügel', 'brust', 'filet'], 'priority': 3},
            {'name': 'Basmati-Reis', 'quantity': '150', 'unit': 'g', 'keywords': ['reis', 'rice', 'basmati'], 'priority': 2},
            {'name': 'Schwarze Bohnen Dose', 'quantity': '400', 'unit': 'g', 'keywords': ['bohne', 'black bean', 'kidneybohne'], 'priority': 2},
            {'name': 'Mais Dose', 'quantity': '200', 'unit': 'g', 'keywords': ['mais', 'corn', 'zuckermais'], 'priority': 2},
            {'name': 'Paprika rot', 'quantity': '1', 'unit': 'Stück', 'keywords': ['paprika', 'pepper', 'bratpaprika'], 'priority': 2},
            {'name': 'Avocado', 'quantity': '1', 'unit': 'Stück', 'keywords': ['avocado'], 'priority': 2},
            {'name': 'Salatherzen', 'quantity': '100', 'unit': 'g', 'keywords': ['salat', 'salatherz', 'eisberg'], 'priority': 2},
            {'name': 'Tomaten', 'quantity': '2', 'unit': 'Stück', 'keywords': ['tomate', 'tomato'], 'priority': 2},
            {'name': 'Limette', 'quantity': '2', 'unit': 'Stück', 'keywords': ['limette', 'lime'], 'priority': 1},
            {'name': 'Kreuzkümmel gemahlen', 'quantity': '2', 'unit': 'TL', 'keywords': ['kreuzkümmel', 'cumin'], 'priority': 1},
            {'name': 'Paprikapulver edelsüß', 'quantity': '2', 'unit': 'TL', 'keywords': ['paprika', 'gewürz'], 'priority': 1},
            {'name': 'Koriander frisch', 'quantity': '1', 'unit': 'Bund', 'keywords': ['koriander', 'cilantro', 'kräuter'], 'priority': 1, 'optional': True},
        ],
        'instructions': [
            'REIS KOCHEN: Basmati-Reis in einem feinen Sieb unter fließendem Wasser gründlich waschen, bis das Wasser klar ist - dies entfernt überschüssige Stärke und macht den Reis fluffiger! 300ml Wasser in einem Topf zum Kochen bringen, Reis hinzufügen, umrühren, Hitze auf niedrig reduzieren und zugedeckt 12-15 Minuten köcheln lassen.',
            'HÄHNCHEN-GEWÜRZMISCHUNG: In einer kleinen Schüssel 2 TL Kreuzkümmel, 2 TL Paprikapulver, 1 TL Knoblauchpulver, 1 TL Zwiebelpulver, 1/2 TL Chilipulver, 1 Prise Zimt, Salz und Pfeffer vermischen. Diese Mischung ist authentisch mexikanisch - der Zimt ist das Geheimnis für Tiefe!',
            'HÄHNCHEN WÜRZEN UND SCHNEIDEN: Hähnchenbrust in 2cm große Würfel schneiden. In eine Schüssel geben, mit der Gewürzmischung bestreuen und mit den Händen gut einmassieren, sodass jedes Stück gleichmäßig überzogen ist. Saft von 1/2 Limette darüber träufeln und 10 Minuten marinieren.',
            'BOHNEN UND MAIS VORBEREITEN: Schwarze Bohnen in ein Sieb geben, unter fließendem Wasser abspülen und gut abtropfen lassen. Mais ebenfalls abgießen und abtropfen lassen. In einen kleinen Topf geben, 1 TL Kreuzkümmel, Salz und Pfeffer hinzufügen. Bei niedriger Hitze 5 Minuten erwärmen und durchmischen.',
            'HÄHNCHEN BRATEN: Große Pfanne auf mittlerer bis hoher Hitze erhitzen. 1 EL Olivenöl hinzugeben und marinierte Hähnchenwürfel in die Pfanne geben - nicht überfüllen, lieber in 2 Portionen arbeiten! 6-8 Minuten braten, dabei regelmäßig wenden, bis das Hähnchen goldbraun und durchgegart ist (Kerntemperatur 74°C).',
            'PAPRIKA ANBRATEN: Paprika entkernen und in 1cm große Würfel schneiden. In derselben Pfanne (nach dem Hähnchen) 2-3 Minuten bei mittlerer Hitze anbraten, bis sie weich aber noch etwas bissfest ist. Die Paprika sollte leicht karamellisiert sein und die Gewürze vom Hähnchen aufnehmen.',
            'REIS FINALISIEREN: Reis sollte jetzt fertig sein - vom Herd nehmen und 5 Minuten zugedeckt ruhen lassen. Mit einer Gabel auflockern, Saft von 1/2 Limette und optional gehackten Koriander unterrühren. Der Limettensaft gibt Frische und hebt den Reis auf ein neues Level!',
            'FRISCHE TOPPINGS VORBEREITEN: Salat waschen und in feine Streifen schneiden. Tomaten würfeln. Avocado halbieren, Kern entfernen, schälen und in Scheiben oder Würfel schneiden, sofort mit Limettensaft beträufeln. Koriander waschen und grob hacken. Alles bereitstellen - jetzt kommt der Spaß: die Bowl zusammenstellen!',
            'PICO DE GALLO MACHEN (OPTIONAL): Für extra Frische: Gewürfelte Tomaten mit 1/4 fein gewürfelter roter Zwiebel, gehacktem Koriander, Saft von 1/2 Limette, Salz und Pfeffer vermischen. 5 Minuten ziehen lassen. Diese frische Salsa macht die Bowl authentisch mexikanisch!',
            'BOWL ZUSAMMENSTELLEN: In zwei große Schüsseln je eine Portion Limetten-Koriander-Reis als Base geben. Darauf in Sektionen arrangieren: gebratenes Hähnchen, schwarze Bohnen-Mais-Mischung, gebratene Paprika, Salat, Tomatenwürfel und Avocado. Mit Pico de Gallo, Limettenspalten und frischem Koriander garnieren. Optional: Einen Klecks griechischen Joghurt oder Salsa dazu. Mit 42g Protein, 14g Ballaststoffen - sättigt für Stunden!'
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
