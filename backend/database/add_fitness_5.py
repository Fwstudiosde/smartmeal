#!/usr/bin/env python3
"""
Add 10 more unique FITNESS recipes to SmartMeal database
Including breakfast options and diverse protein sources
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

# 10 NEW FITNESS RECIPES - World-class quality, High-Protein, diverse
RECIPES = [
    {
        'name': 'Protein-Waffeln mit Erdnussbutter und Banane',
        'category': 'fitness',
        'description': 'Knusprige, proteinreiche Waffeln mit cremiger Erdnussbutter und frischer Banane. Mit 32g Protein das perfekte Power-Frühstück! Schmeckt wie Dessert, liefert Energie für den ganzen Tag.',
        'image_url': 'https://images.unsplash.com/photo-1562376552-0d160a2f238d?w=800',
        'prep_time': 10,
        'cook_time': 15,
        'servings': 2,
        'difficulty': 'easy',
        'nutrition': {'calories': 450, 'protein': 32, 'carbs': 42, 'fat': 16, 'fiber': 6},
        'tags': ['high-protein', 'breakfast'],
        'ingredients': [
            {'name': 'Haferflocken', 'quantity': '120', 'unit': 'g', 'keywords': ['hafer', 'oat', 'flocken', 'kernige'], 'priority': 3},
            {'name': 'Protein-Pulver Vanille', 'quantity': '60', 'unit': 'g', 'keywords': ['protein', 'whey', 'pulver', 'eiweiss'], 'priority': 3},
            {'name': 'Eier', 'quantity': '3', 'unit': 'Stück', 'keywords': ['ei', 'egg', 'freiland', 'bio-eier'], 'priority': 3},
            {'name': 'Banane', 'quantity': '2', 'unit': 'Stück', 'keywords': ['banane', 'banana'], 'priority': 2},
            {'name': 'Erdnussbutter', 'quantity': '60', 'unit': 'g', 'keywords': ['erdnussbutter', 'peanut butter', 'nussbutter'], 'priority': 2},
            {'name': 'Milch', 'quantity': '150', 'unit': 'ml', 'keywords': ['milch', 'milk', 'vollmilch'], 'priority': 2},
            {'name': 'Backpulver', 'quantity': '1', 'unit': 'TL', 'keywords': ['backpulver', 'baking powder'], 'priority': 1},
            {'name': 'Zimt gemahlen', 'quantity': '1', 'unit': 'TL', 'keywords': ['zimt', 'cinnamon'], 'priority': 1},
        ],
        'instructions': [
            'HAFERFLOCKEN MAHLEN: Haferflocken in einen Mixer oder eine Küchenmaschine geben und 30-40 Sekunden mixen, bis sie zu einem feinen Mehl werden. Das Hafermehl sollte sich fast wie normales Mehl anfühlen - das ist der Schlüssel zu fluffigen Waffeln statt krümeliger!',
            'BANANE ZERDRÜCKEN: 1 Banane schälen und mit einer Gabel in einer großen Schüssel zu einem glatten Püree zerdrücken. Je feiner das Püree, desto gleichmäßiger wird der Teig. Die zweite Banane für später zum Garnieren aufbewahren.',
            'TEIG MIXEN: Eier, Milch und Bananenpüree in die Schüssel geben und mit einem Schneebesen gut verquirlen, bis die Mischung homogen ist. Gemahlene Haferflocken, Protein-Pulver, Backpulver und Zimt hinzufügen. Alles zu einem glatten Teig verrühren - aber nicht zu lange, sonst werden die Waffeln zäh!',
            'TEIG RUHEN LASSEN: Den Teig 5 Minuten bei Raumtemperatur ruhen lassen. In dieser Zeit quillt das Hafermehl auf und der Teig wird dicker. Das ist wichtig für perfekte Waffeln! Der Teig sollte dickflüssig sein, aber noch vom Löffel tropfen.',
            'WAFFELEISEN VORHEIZEN: Waffeleisen auf mittlere bis hohe Stufe vorheizen und leicht mit Öl oder Butter einfetten. Das Eisen ist bereit, wenn ein Wassertropfen darauf sofort verdampft. Pro-Tipp: Nicht zu viel Fett verwenden, sonst werden die Waffeln ölig!',
            'WAFFELN BACKEN: Eine Suppenkelle Teig in die Mitte des Waffeleisens gießen und gleichmäßig verteilen, sodass die gesamte Fläche bedeckt ist. Deckel schließen und 3-4 Minuten backen, bis die Waffeln goldbraun und knusprig sind. WICHTIG: Deckel nicht zu früh öffnen, sonst reißen die Waffeln!',
            'WAFFELN WARM HALTEN: Fertige Waffeln aus dem Eisen nehmen und auf einem Kuchengitter (nicht auf einem Teller!) warm halten. Das Gitter verhindert, dass die Unterseite durch Dampf matschig wird. Bei Bedarf im Ofen bei 100°C warm halten. Mit dem restlichen Teig weitere Waffeln backen.',
            'BANANE SCHNEIDEN: Die zweite Banane schälen und in dünne Scheiben schneiden. Optional: Bananenscheiben in einer Pfanne mit etwas Butter und Zimt 2 Minuten karamellisieren - das gibt extra Süße und eine tolle Optik!',
            'ERDNUSSBUTTER ERWÄRMEN: Erdnussbutter in einem kleinen Topf oder in der Mikrowave (20 Sekunden) leicht erwärmen, bis sie flüssiger wird und sich gut verteilen lässt. Bei Bedarf 1-2 TL Wasser unterrühren für bessere Konsistenz.',
            'SERVIEREN: Waffeln auf Teller stapeln (2-3 pro Portion), großzügig mit warmer Erdnussbutter beträufeln und mit Bananenscheiben belegen. Optional: Mit Ahornsirup, Honig, gehackten Nüssen oder Schokodrops garnieren. Sofort servieren und genießen - 32g Protein für maximale Energie!'
        ]
    },
    {
        'name': 'Shakshuka mit Feta und frischem Brot',
        'category': 'fitness',
        'description': 'Nordafrikanisches Eier-Gericht in würziger Tomaten-Paprika-Sauce mit cremigem Feta. Reich an Protein (28g!), voller Aromen und perfekt zum Dippen mit frischem Brot. Ein herzhaftes Frühstück der Extraklasse!',
        'image_url': 'https://images.unsplash.com/photo-1587486937773-f025c89e2915?w=800',
        'prep_time': 10,
        'cook_time': 25,
        'servings': 2,
        'difficulty': 'easy',
        'nutrition': {'calories': 420, 'protein': 28, 'carbs': 35, 'fat': 20, 'fiber': 8},
        'tags': ['high-protein', 'breakfast', 'lunch'],
        'ingredients': [
            {'name': 'Eier', 'quantity': '6', 'unit': 'Stück', 'keywords': ['ei', 'egg', 'freiland', 'bio-eier'], 'priority': 3},
            {'name': 'Tomaten gehackt Dose', 'quantity': '400', 'unit': 'g', 'keywords': ['tomate', 'tomaten', 'dose', 'gehackt'], 'priority': 2},
            {'name': 'Paprika rot', 'quantity': '2', 'unit': 'Stück', 'keywords': ['paprika', 'pepper', 'bratpaprika'], 'priority': 2},
            {'name': 'Feta', 'quantity': '100', 'unit': 'g', 'keywords': ['feta', 'käse', 'schafskäse'], 'priority': 2},
            {'name': 'Zwiebeln', 'quantity': '1', 'unit': 'Stück', 'keywords': ['zwiebel', 'onion'], 'priority': 1},
            {'name': 'Knoblauch', 'quantity': '4', 'unit': 'Zehen', 'keywords': ['knoblauch', 'garlic'], 'priority': 1},
            {'name': 'Kreuzkümmel gemahlen', 'quantity': '1', 'unit': 'TL', 'keywords': ['kreuzkümmel', 'cumin'], 'priority': 1},
            {'name': 'Paprikapulver edelsüß', 'quantity': '2', 'unit': 'TL', 'keywords': ['paprika', 'gewürz'], 'priority': 1},
            {'name': 'Olivenöl', 'quantity': '2', 'unit': 'EL', 'keywords': ['öl', 'olive'], 'priority': 1},
            {'name': 'Petersilie frisch', 'quantity': '1', 'unit': 'Bund', 'keywords': ['petersilie', 'parsley', 'kräuter'], 'priority': 1},
        ],
        'instructions': [
            'GEMÜSE VORBEREITEN: Zwiebel schälen und fein würfeln. Knoblauch schälen und fein hacken. Paprika entkernen und in 1,5cm große Würfel schneiden. Petersilie waschen, trocken schütteln und grob hacken. Alles getrennt bereitstellen - bei diesem Gericht muss es schnell gehen!',
            'ZWIEBEL UND PAPRIKA ANBRATEN: Große ofenfeste Pfanne (am besten Gusseisen) auf mittlerer Hitze erhitzen. Olivenöl hinzugeben, Zwiebel dazugeben und 3-4 Minuten glasig dünsten. Paprikawürfel hinzufügen und weitere 5 Minuten braten, bis sie weich sind und leicht karamellisieren.',
            'GEWÜRZE ANRÖSTEN: Knoblauch, Kreuzkümmel, Paprikapulver, 1/2 TL Cayennepfeffer (nach Geschmack), Salz und Pfeffer zur Pfanne geben. 1 Minute unter Rühren anrösten, bis die Gewürze duften - das entfaltet ihre vollen Aromen! Vorsicht, der Knoblauch sollte nicht verbrennen.',
            'TOMATEN HINZUFÜGEN: Gehackte Tomaten (mit Saft!) in die Pfanne gießen. Umrühren und zum Köcheln bringen. Hitze reduzieren und 10 Minuten köcheln lassen, dabei gelegentlich umrühren, bis die Sauce eingedickt ist. Die Sauce sollte sämig sein, nicht wässrig - bei Bedarf länger einkochen.',
            'SAUCE WÜRZEN: Sauce mit Salz, Pfeffer und optional 1 Prise Zucker abschmecken. Der Zucker balanciert die Säure der Tomaten aus - ein Profi-Trick! Optional: 1 EL Tomatenmark einrühren für intensiveren Geschmack.',
            'MULDEN FÜR EIER FORMEN: Mit einem Löffel 6 kleine Mulden in die Tomatensauce drücken - gleichmäßig verteilt. Diese Mulden werden die Eier aufnehmen. Pro-Tipp: Die Mulden sollten nicht zu tief sein, sonst sinken die Eier ein und werden vom Eigelb getrennt.',
            'EIER HINZUFÜGEN: Vorsichtig ein Ei nach dem anderen in jede Mulde aufschlagen. Am besten jedes Ei vorher einzeln in eine kleine Schüssel schlagen, dann vorsichtig in die Mulde gleiten lassen - so vermeidet man zerbrochene Eigelbe! Mit Salz und Pfeffer würzen.',
            'EIER GAREN: Pfanne mit einem Deckel abdecken und bei niedriger Hitze 8-10 Minuten garen, bis das Eiweiß fest ist, aber das Eigelb noch flüssig - perfekt zum Dippen! Für komplett durchgegarte Eier 12-14 Minuten garen. Nicht zu lange, sonst werden die Eier hart!',
            'FETA UND KRÄUTER: Feta in grobe Stücke zerbröseln und über die Shakshuka streuen. Die Hälfte der gehackten Petersilie darüber verteilen. Optional: Pfanne für 2 Minuten in den vorgeheizten Ofen bei 200°C schieben, damit der Feta leicht schmilzt.',
            'SERVIEREN: Shakshuka direkt aus der Pfanne servieren - das ist traditionell und sieht beeindruckend aus! Mit restlicher Petersilie garnieren. Dazu frisches Brot, Pita oder Fladenbrot zum Dippen reichen. Jeder bekommt 3 Eier mit reichlich Sauce. Mit 28g Protein, würzigen Aromen und flüssigem Eigelb zum Dippen - ein Frühstück wie im Urlaub!'
        ]
    },
    {
        'name': 'Quinoa-Frühstücks-Bowl mit Beeren und Mandeln',
        'category': 'fitness',
        'description': 'Warme Quinoa-Bowl mit Zimt, frischen Beeren, gerösteten Mandeln und Honig. Ein proteinreiches, glutenfreies Frühstück (18g Protein!) voller komplexer Kohlenhydrate. Perfekte Alternative zu Haferflocken!',
        'image_url': 'https://images.unsplash.com/photo-1511690743698-d9d85f2fbf38?w=800',
        'prep_time': 5,
        'cook_time': 20,
        'servings': 2,
        'difficulty': 'easy',
        'nutrition': {'calories': 420, 'protein': 18, 'carbs': 58, 'fat': 14, 'fiber': 10},
        'tags': ['high-protein', 'breakfast', 'gluten-free'],
        'ingredients': [
            {'name': 'Quinoa', 'quantity': '150', 'unit': 'g', 'keywords': ['quinoa'], 'priority': 3},
            {'name': 'Mandelmilch ungesüßt', 'quantity': '400', 'unit': 'ml', 'keywords': ['mandelmilch', 'almond', 'pflanzenmilch'], 'priority': 2},
            {'name': 'Heidelbeeren', 'quantity': '150', 'unit': 'g', 'keywords': ['heidelbeere', 'blueberry', 'beere'], 'priority': 2},
            {'name': 'Himbeeren', 'quantity': '100', 'unit': 'g', 'keywords': ['himbeere', 'raspberry', 'beere'], 'priority': 2},
            {'name': 'Mandeln gehobelt', 'quantity': '40', 'unit': 'g', 'keywords': ['mandel', 'almond', 'gehobelt'], 'priority': 2},
            {'name': 'Honig', 'quantity': '3', 'unit': 'EL', 'keywords': ['honig', 'honey'], 'priority': 1},
            {'name': 'Zimt gemahlen', 'quantity': '1', 'unit': 'TL', 'keywords': ['zimt', 'cinnamon'], 'priority': 1},
            {'name': 'Vanille-Extrakt', 'quantity': '1', 'unit': 'TL', 'keywords': ['vanille', 'vanilla', 'extrakt'], 'priority': 1},
        ],
        'instructions': [
            'QUINOA WASCHEN: Quinoa in einem feinen Sieb unter fließendem kaltem Wasser sehr gründlich waschen - mindestens 2 Minuten, bis das Wasser komplett klar ist! Dieser Schritt ist essentiell: Er entfernt die natürlichen Saponine, die Quinoa bitter machen. Gut abtropfen lassen.',
            'QUINOA MIT MILCH KOCHEN: Gewaschene Quinoa in einen mittelgroßen Topf geben. Mandelmilch, Zimt, Vanille-Extrakt und 1 Prise Salz hinzufügen. Zum Kochen bringen, dann Hitze auf niedrig reduzieren und zugedeckt 15-18 Minuten köcheln lassen, bis die Flüssigkeit aufgesogen ist.',
            'QUINOA RUHEN LASSEN: Topf vom Herd nehmen und 5 Minuten zugedeckt ruhen lassen. Dieser Schritt ist wichtig - die Quinoa dampft nach und wird fluffig! Danach mit einer Gabel auflockern. Jedes Quinoa-Korn sollte einen kleinen "Schwanz" haben - das Zeichen für perfekt gegartes Quinoa.',
            'MANDELN RÖSTEN: Während die Quinoa kocht: Gehobelte Mandeln in einer trockenen Pfanne bei mittlerer Hitze 3-4 Minuten rösten, dabei ständig rühren oder die Pfanne schwenken. Sie sollten goldbraun sein und nussig duften. Vorsicht - sie verbrennen schnell! Aus der Pfanne nehmen und abkühlen lassen.',
            'BEEREN VORBEREITEN: Heidelbeeren und Himbeeren waschen und vorsichtig trocken tupfen. Optional: Die Hälfte der Beeren in einer kleinen Schüssel mit 1 TL Honig und einem Spritzer Zitronensaft leicht zerdrücken - das gibt einen fruchtigen Beeren-Kompott!',
            'HONIG-ZIMT-MISCHUNG: In einer kleinen Schüssel 2 EL Honig mit 1/2 TL Zimt vermischen. Bei Bedarf 1 EL warmes Wasser hinzufügen, damit der Honig flüssiger wird und sich besser verteilen lässt. Diese Honig-Zimt-Mischung gibt der Bowl süße Würze!',
            'QUINOA SÜSSEN: Die warme, aufgelockerte Quinoa mit 1 EL Honig vermischen. Abschmecken - bei Bedarf mehr Honig oder eine Prise Salz hinzufügen. Die Balance zwischen süß und salzig ist wichtig für ein rundes Geschmackserlebnis.',
            'BOWL ZUSAMMENSTELLEN BASIS: Warme Quinoa gleichmäßig auf zwei Schüsseln verteilen. Die Quinoa sollte als fluffige Base dienen - wie ein warmes Porridge, aber mit mehr Textur und Nussigkeit.',
            'TOPPINGS ARRANGIEREN: Auf die Quinoa in jeder Bowl die Beeren (sowohl frische als auch zerdrückte) verteilen. Geröstete Mandeln darüber streuen. Mit der Honig-Zimt-Mischung beträufeln. Optional: Kokosraspeln, Chia-Samen, Leinsamen oder Nussbutter hinzufügen.',
            'SERVIEREN: Sofort warm servieren! Optional: Mit frischer Minze, Bananenscheiben oder einem Klecks griechischem Joghurt garnieren. Die Kombination aus warmer, nussiger Quinoa, kühlen Beeren und knusprigen Mandeln ist einfach perfekt! Mit 18g Protein, 10g Ballaststoffen - sättigt bis zum Mittag!'
        ]
    },
    {
        'name': 'Protein-Smoothie-Bowl mit Granola und Früchten',
        'category': 'fitness',
        'description': 'Dicke, cremige Smoothie-Bowl mit Beeren, Banane und Protein-Pulver, getoppt mit knusprigem Granola und frischen Früchten. Schnelles Fitness-Frühstück (25g Protein!) das wie Eiscreme schmeckt!',
        'image_url': 'https://images.unsplash.com/photo-1590301157890-4810ed352733?w=800',
        'prep_time': 10,
        'cook_time': 0,
        'servings': 2,
        'difficulty': 'easy',
        'nutrition': {'calories': 380, 'protein': 25, 'carbs': 52, 'fat': 10, 'fiber': 9},
        'tags': ['high-protein', 'breakfast', 'no-cook'],
        'ingredients': [
            {'name': 'Banane gefroren', 'quantity': '2', 'unit': 'Stück', 'keywords': ['banane', 'banana', 'gefroren'], 'priority': 2},
            {'name': 'Heidelbeeren gefroren', 'quantity': '200', 'unit': 'g', 'keywords': ['heidelbeere', 'blueberry', 'beere', 'gefroren'], 'priority': 2},
            {'name': 'Protein-Pulver Vanille', 'quantity': '60', 'unit': 'g', 'keywords': ['protein', 'whey', 'pulver', 'eiweiss'], 'priority': 3},
            {'name': 'Griechischer Joghurt', 'quantity': '200', 'unit': 'g', 'keywords': ['joghurt', 'greek', 'griechisch', 'skyr'], 'priority': 2},
            {'name': 'Haferflocken', 'quantity': '60', 'unit': 'g', 'keywords': ['hafer', 'oat', 'flocken', 'kernige'], 'priority': 2},
            {'name': 'Mandelmilch ungesüßt', 'quantity': '100', 'unit': 'ml', 'keywords': ['mandelmilch', 'almond', 'pflanzenmilch'], 'priority': 1},
            {'name': 'Erdbeeren frisch', 'quantity': '100', 'unit': 'g', 'keywords': ['erdbeere', 'strawberry', 'beere'], 'priority': 2},
            {'name': 'Honig', 'quantity': '2', 'unit': 'EL', 'keywords': ['honig', 'honey'], 'priority': 1},
        ],
        'instructions': [
            'FRÜCHTE VORBEREITEN: Falls Bananen nicht bereits gefroren sind: Bananen schälen, in Scheiben schneiden und mindestens 2 Stunden einfrieren. Gefrorene Früchte sind das Geheimnis für eine dicke, cremige Bowl - wie Eiscreme! Je gefrorener, desto besser die Konsistenz.',
            'MIXER VORBEREITEN: Einen leistungsstarken Mixer verwenden (mindestens 600 Watt). Die Reihenfolge ist wichtig: Zuerst die Flüssigkeit (Mandelmilch und Joghurt) in den Mixer geben - das verhindert, dass der Motor blockiert. Dann Protein-Pulver und Honig hinzufügen.',
            'GEFRORENE FRÜCHTE HINZUFÜGEN: Gefrorene Bananen und gefrorene Heidelbeeren auf die Joghurt-Mischung geben. WICHTIG: Die Früchte sollten sehr gefroren sein, aber nicht steinhart - 2 Minuten antauen lassen, falls nötig, damit der Mixer sie verarbeiten kann.',
            'MIXEN TECHNIK: Mixer auf niedrigster Stufe starten und langsam hochdrehen. Mit einem Stößel die Masse nach unten drücken, damit alles gleichmäßig gemixt wird. Mehrmals stoppen und durchrühren. Nur so viel mixen wie nötig - zu langes Mixen erwärmt die Masse! Konsistenz sollte sehr dick sein, wie weiches Eis.',
            'KONSISTENZ ANPASSEN: Die Bowl sollte so dick sein, dass ein Löffel darin stehen bleibt! Wenn zu dünn: 2-3 Eiswürfel hinzufügen und kurz nachmixen. Wenn zu dick: 1-2 EL Mandelmilch hinzufügen. Die perfekte Konsistenz ist entscheidend - dick genug für Toppings, aber noch cremig!',
            'FRISCHE FRÜCHTE SCHNEIDEN: Erdbeeren waschen, Grün entfernen und in dünne Scheiben schneiden. Weitere Banane (falls gewünscht) schälen und in Scheiben schneiden. Alle frischen Früchte zum Toppen bereitstellen - die Farbkontraste machen die Bowl Instagram-würdig!',
            'GRANOLA VORBEREITEN: Haferflocken in einer Pfanne ohne Fett bei mittlerer Hitze 3-4 Minuten rösten, bis sie goldbraun sind und nussig duften. Optional: Mit 1 TL Honig und einer Prise Zimt karamellisieren. Abkühlen lassen - das gibt Crunch!',
            'BOWLS FÜLLEN: Die dicke Smoothie-Masse gleichmäßig auf zwei Schüsseln verteilen. Mit einem Löffel glatt streichen - die Oberfläche sollte eben sein, damit die Toppings schön liegen. Die Bowl ist jetzt die Canvas für ein Kunstwerk!',
            'TOPPINGS KREATIV ANORDNEN: Geröstete Haferflocken in einer Linie über die Mitte streuen. Links und rechts davon Erdbeerscheiben, Heidelbeeren und Bananenscheiben in Reihen oder Mustern arrangieren. Optional: Kokosflocken, Chia-Samen, Kakao-Nibs, Nussbutter oder Minze hinzufügen.',
            'SOFORT SERVIEREN: Die Bowl muss sofort serviert werden, solange sie noch dick und eiskalt ist! Mit einem Löffel essen und alle Schichten zusammen genießen. Die Kombination aus cremiger, eiskalter Base und knusprigen Toppings ist unschlagbar! Mit 25g Protein - perfekt für Power am Morgen!'
        ]
    },
    {
        'name': 'Puten-Chili mit Kidney-Bohnen und Reis',
        'category': 'fitness',
        'description': 'Würziges, proteinreiches Chili mit magerem Putenfleisch, Kidney-Bohnen und Tomaten. Mit 46g Protein pro Portion! Perfekt für Meal-Prep - schmeckt am nächsten Tag noch besser. Ein echter Klassiker!',
        'image_url': 'https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?w=800',
        'prep_time': 15,
        'cook_time': 40,
        'servings': 2,
        'difficulty': 'easy',
        'nutrition': {'calories': 580, 'protein': 46, 'carbs': 62, 'fat': 14, 'fiber': 16},
        'tags': ['high-protein', 'lunch', 'dinner', 'meal-prep', 'one-pot'],
        'ingredients': [
            {'name': 'Putenhackfleisch', 'quantity': '500', 'unit': 'g', 'keywords': ['pute', 'turkey', 'hack', 'hackfleisch', 'gehacktes'], 'priority': 3},
            {'name': 'Kidney-Bohnen Dose', 'quantity': '400', 'unit': 'g', 'keywords': ['bohne', 'kidney', 'rote bohne'], 'priority': 2},
            {'name': 'Tomaten gehackt Dose', 'quantity': '400', 'unit': 'g', 'keywords': ['tomate', 'tomaten', 'dose', 'gehackt'], 'priority': 2},
            {'name': 'Mais Dose', 'quantity': '200', 'unit': 'g', 'keywords': ['mais', 'corn', 'zuckermais'], 'priority': 2},
            {'name': 'Basmati-Reis', 'quantity': '150', 'unit': 'g', 'keywords': ['reis', 'rice', 'basmati'], 'priority': 2},
            {'name': 'Paprika rot', 'quantity': '2', 'unit': 'Stück', 'keywords': ['paprika', 'pepper', 'bratpaprika'], 'priority': 2},
            {'name': 'Zwiebeln', 'quantity': '2', 'unit': 'Stück', 'keywords': ['zwiebel', 'onion'], 'priority': 1},
            {'name': 'Knoblauch', 'quantity': '4', 'unit': 'Zehen', 'keywords': ['knoblauch', 'garlic'], 'priority': 1},
            {'name': 'Kreuzkümmel gemahlen', 'quantity': '2', 'unit': 'TL', 'keywords': ['kreuzkümmel', 'cumin'], 'priority': 1},
            {'name': 'Chilipulver', 'quantity': '2', 'unit': 'TL', 'keywords': ['chili', 'pulver'], 'priority': 1},
            {'name': 'Paprikapulver edelsüß', 'quantity': '2', 'unit': 'TL', 'keywords': ['paprika', 'gewürz'], 'priority': 1},
        ],
        'instructions': [
            'REIS KOCHEN: Basmati-Reis in einem Sieb unter fließendem Wasser gründlich waschen, bis das Wasser klar ist. 300ml Wasser in einem Topf zum Kochen bringen, Reis und eine Prise Salz hinzufügen, umrühren, zudecken und bei niedriger Hitze 12-15 Minuten köcheln lassen. Vom Herd nehmen und 5 Minuten ruhen lassen.',
            'GEMÜSE VORBEREITEN: Zwiebeln schälen und fein würfeln. Knoblauch schälen und fein hacken. Paprika entkernen und in 1,5cm große Würfel schneiden. Alles getrennt bereitstellen. Bei einem One-Pot-Gericht wie Chili ist eine gute Mise en Place entscheidend!',
            'PUTENHACK ANBRATEN: Großen Topf oder Dutch Oven auf hoher Hitze erhitzen. 1 EL Öl hinzugeben und Putenhackfleisch in den Topf geben. Mit Salz und Pfeffer würzen. 5-7 Minuten kräftig anbraten, dabei mit einem Holzlöffel zerteilen, bis es braun und krümelig ist. Das Fleisch sollte Röstaromen entwickeln!',
            'ZWIEBEL UND PAPRIKA HINZUFÜGEN: Hitze auf mittel reduzieren. Zwiebeln und Paprikawürfel zum gebratenen Putenhack geben. 5 Minuten unter gelegentlichem Rühren braten, bis Zwiebeln glasig und Paprika weich sind. Das Gemüse nimmt die Fleischsäfte auf und karamellisiert leicht.',
            'GEWÜRZE ANRÖSTEN: Knoblauch, Kreuzkümmel, Chilipulver, Paprikapulver, 1 TL Oregano und 1/2 TL Cayennepfeffer (nach Schärfevorliebe) hinzufügen. 1-2 Minuten unter ständigem Rühren anrösten, bis die Gewürze intensiv duften. Das Rösten aktiviert die ätherischen Öle - der Schlüssel zu authentischem Chili!',
            'TOMATEN UND BOHNEN HINZUFÜGEN: Gehackte Tomaten (mit Saft!), abgetropfte Kidney-Bohnen und abgetropften Mais in den Topf geben. 200ml Wasser oder Brühe hinzufügen. Alles gut umrühren und zum Köcheln bringen. Mit Salz, Pfeffer und optional 1 Prise Zucker abschmecken.',
            'CHILI KÖCHELN LASSEN: Hitze auf niedrig reduzieren und Chili zugedeckt 25-30 Minuten köcheln lassen. Gelegentlich umrühren, damit nichts ansetzt. Das Chili sollte langsam blubbern und eindicken. Je länger es köchelt, desto besser verschmelzen die Aromen! Falls zu dick, etwas Wasser hinzufügen.',
            'KONSISTENZ ANPASSEN: Nach 30 Minuten sollte das Chili sämig sein - nicht zu flüssig, nicht zu trocken. Falls zu wässrig: Deckel abnehmen und weitere 5-10 Minuten einkochen lassen. Falls zu dick: 50-100ml Wasser unterrühren. Die perfekte Konsistenz ist wie eine dicke Bolognese.',
            'ABSCHMECKEN UND VERFEINERN: Chili vom Herd nehmen und final abschmecken. Mit Salz, Pfeffer, Chilipulver, Kreuzkümmel oder einem Spritzer Limettensaft nachwürzen. Optional: 1 Stück dunkle Schokolade (70% Kakao) einrühren - gibt Tiefe und Süße! Profi-Geheimnis!',
            'SERVIEREN: Reis mit einer Gabel auflockern und auf Teller oder in Bowls verteilen. Chili großzügig darüber geben. Mit frischem Koriander, Frühlingszwiebeln, einem Klecks Joghurt oder Sauerrahm, geriebenem Käse und Limettenspalten garnieren. Mit 46g Protein, 16g Ballaststoffen - das ultimative Comfort Food für Fitness-Fans!'
        ]
    },
    {
        'name': 'Gebackener Tofu mit Brokkoli und Erdnuss-Sauce',
        'category': 'fitness',
        'description': 'Knuspriger gebackener Tofu mit gedämpftem Brokkoli und cremiger Erdnuss-Sauce. Pflanzliches Protein-Power (28g!) mit asiatischen Aromen. Perfekt für Veganer und alle, die Abwechslung suchen!',
        'image_url': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800',
        'prep_time': 20,
        'cook_time': 30,
        'servings': 2,
        'difficulty': 'medium',
        'nutrition': {'calories': 480, 'protein': 28, 'carbs': 38, 'fat': 24, 'fiber': 10},
        'tags': ['high-protein', 'dinner', 'baked'],
        'ingredients': [
            {'name': 'Tofu fest', 'quantity': '400', 'unit': 'g', 'keywords': ['tofu', 'soja', 'seidentofu'], 'priority': 3},
            {'name': 'Brokkoli', 'quantity': '400', 'unit': 'g', 'keywords': ['brokkoli', 'broccoli'], 'priority': 2},
            {'name': 'Basmati-Reis', 'quantity': '150', 'unit': 'g', 'keywords': ['reis', 'rice', 'basmati'], 'priority': 2},
            {'name': 'Erdnussbutter', 'quantity': '80', 'unit': 'g', 'keywords': ['erdnussbutter', 'peanut butter', 'nussbutter'], 'priority': 2},
            {'name': 'Sojasauce', 'quantity': '4', 'unit': 'EL', 'keywords': ['soja', 'sauce'], 'priority': 1},
            {'name': 'Sesamöl', 'quantity': '2', 'unit': 'EL', 'keywords': ['sesamöl', 'sesame'], 'priority': 1},
            {'name': 'Ingwer', 'quantity': '20', 'unit': 'g', 'keywords': ['ingwer', 'ginger'], 'priority': 1},
            {'name': 'Knoblauch', 'quantity': '3', 'unit': 'Zehen', 'keywords': ['knoblauch', 'garlic'], 'priority': 1},
            {'name': 'Sesam', 'quantity': '2', 'unit': 'EL', 'keywords': ['sesam'], 'priority': 1},
        ],
        'instructions': [
            'TOFU PRESSEN: Tofu aus der Verpackung nehmen, Flüssigkeit abgießen. Tofu zwischen mehreren Lagen Küchenpapier oder sauberen Geschirrtüchern legen. Mit einem schweren Brett oder Topf beschweren und 15-20 Minuten pressen. Dieser Schritt ist ESSENTIELL - er entfernt überschüssiges Wasser, sodass der Tofu knusprig werden kann!',
            'OFEN VORHEIZEN: Backofen auf 200°C Ober-/Unterhitze vorheizen. Ein Backblech mit Backpapier auslegen. Die hohe Hitze ist wichtig, damit der Tofu außen knusprig wird, während er innen weich bleibt.',
            'TOFU SCHNEIDEN UND MARINIEREN: Gepressten Tofu in 2cm große Würfel schneiden. In eine Schüssel geben. 2 EL Sojasauce, 1 EL Sesamöl, 1 TL Knoblauchpulver und 1 TL Ingwerpulver hinzufügen. Vorsichtig durchmischen (Tofu bricht leicht!), 10 Minuten marinieren.',
            'TOFU BACKEN: Marinierte Tofu-Würfel auf dem vorbereiteten Backblech in einer einzigen Schicht verteilen - nicht überlappen! Im Ofen 25-30 Minuten backen, nach 15 Minuten einmal vorsichtig wenden. Der Tofu sollte goldbraun und an den Ecken knusprig sein.',
            'REIS KOCHEN: Währenddessen Basmati-Reis waschen und wie gewohnt kochen (siehe vorherige Rezepte). 300ml Wasser, Reis, Salz - 12-15 Minuten köcheln, 5 Minuten ruhen. Mit Gabel auflockern.',
            'ERDNUSS-SAUCE VORBEREITEN: Ingwer schälen und fein reiben. Knoblauch schälen und fein hacken. In einer Schüssel Erdnussbutter, 2 EL Sojasauce, 1 EL Reisessig, 1 EL Honig, geriebenen Ingwer, gehackten Knoblauch, 1 TL Sesamöl und 4-5 EL warmes Wasser verrühren, bis eine glatte, cremige Sauce entsteht.',
            'BROKKOLI VORBEREITEN: Brokkoli in kleine Röschen teilen. Strunk schälen und würfeln (nicht wegwerfen!). Großen Topf mit Wasser zum Kochen bringen, salzen. Einen Dämpfeinsatz einsetzen oder ein Sieb über das kochende Wasser hängen.',
            'BROKKOLI DÄMPFEN: Brokkoli-Röschen in den Dämpfeinsatz geben, Deckel auflegen und 4-6 Minuten dämpfen, bis der Brokkoli bissfest ist und leuchtend grün. NICHT zu lange dämpfen - er sollte noch Crunch haben! Sofort aus dem Dampf nehmen.',
            'SESAM RÖSTEN: Sesam in einer trockenen Pfanne bei mittlerer Hitze 2-3 Minuten rösten, dabei ständig schwenken, bis er goldbraun ist und nussig duftet. Aus der Pfanne nehmen - er brennt schnell!',
            'SERVIEREN: Reis auf Teller oder in Bowls verteilen. Darauf gedämpften Brokkoli und knusprige Tofu-Würfel arrangieren. Erdnuss-Sauce großzügig darüber träufeln oder separat servieren. Mit geröstetem Sesam, Frühlingszwiebeln und optional Chiliflocken garnieren. Mit 28g pflanzlichem Protein, cremiger Sauce und knusprigem Tofu - vegan war nie so lecker!'
        ]
    },
]

if __name__ == "__main__":
    conn = sqlite3.connect(DB_PATH)

    print(f"📝 Adding {len(RECIPES)} new unique FITNESS recipes to database...")

    for recipe in RECIPES:
        recipe_id = add_recipe(conn, recipe)
        print(f"  ✓ Added: {recipe['name']}")

    # Verify
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM recipes")
    total = cursor.fetchone()[0]

    print(f"\n✅ Success! Database now has {total} recipes total")

    conn.close()
