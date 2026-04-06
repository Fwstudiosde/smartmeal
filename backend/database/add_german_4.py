#!/usr/bin/env python3
"""
Add popular GERMAN recipes to SmartMeal database - Part 4
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

# GERMAN CLASSIC RECIPES - Part 4 (Recipes 16-21)
RECIPES = [
    {
        'name': 'Zwiebelkuchen mit Federweißer',
        'category': 'german',
        'description': 'Herzhafter Hefekuchen mit Zwiebeln, Speck und Schmand - der Herbstklassiker! Traditionell mit Federweißer serviert.',
        'image_url': 'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?w=800',
        'prep_time': 40,
        'cook_time': 45,
        'servings': 8,
        'difficulty': 'medium',
        'nutrition': {'calories': 420, 'protein': 14, 'carbs': 38, 'fat': 24, 'fiber': 3},
        'tags': ['dinner', 'party', 'autumn'],
        'ingredients': [
            {'name': 'Mehl', 'quantity': '500', 'unit': 'g', 'keywords': ['mehl', 'flour'], 'priority': 1},
            {'name': 'Hefe frisch', 'quantity': '1', 'unit': 'Würfel', 'keywords': ['hefe', 'yeast'], 'priority': 1},
            {'name': 'Zwiebeln', 'quantity': '1.5', 'unit': 'kg', 'keywords': ['zwiebel', 'onion'], 'priority': 3},
            {'name': 'Speck durchwachsen', 'quantity': '250', 'unit': 'g', 'keywords': ['speck', 'bacon'], 'priority': 2},
            {'name': 'Schmand', 'quantity': '400', 'unit': 'g', 'keywords': ['schmand', 'sour cream'], 'priority': 2},
            {'name': 'Eier', 'quantity': '3', 'unit': 'Stück', 'keywords': ['ei', 'egg'], 'priority': 2},
            {'name': 'Kümmel', 'quantity': '2', 'unit': 'TL', 'keywords': ['kümmel', 'caraway'], 'priority': 1},
            {'name': 'Butter', 'quantity': '60', 'unit': 'g', 'keywords': ['butter'], 'priority': 1},
        ],
        'instructions': [
            'HEFETEIG: 500g Mehl in eine Schüssel geben. 1 Würfel Hefe in 250ml lauwarmer Milch auflösen, mit 1 TL Salz, 1 TL Zucker, 60g zerlassener Butter zum Mehl geben. Zu einem glatten Teig kneten. Zugedeckt 1 Stunde gehen lassen.',
            'ZWIEBELN SCHNEIDEN: Zwiebeln schälen und in feine Ringe schneiden - das ist Arbeit, aber es lohnt sich! Je feiner, desto besser.',
            'SPECK AUSLASSEN: Speck in kleine Würfel schneiden, in einer großen Pfanne ohne Fett auslassen bis er knusprig ist. Herausnehmen, Fett aufbewahren.',
            'ZWIEBELN DÜNSTEN: Zwiebelringe im Speckfett bei mittlerer Hitze 20-25 Minuten goldgelb dünsten. Ständig rühren! Sie sollten weich und leicht karamellisiert sein. Mit Salz, Pfeffer, Kümmel würzen. Abkühlen lassen.',
            'GUSS VORBEREITEN: Schmand, 3 Eier, 2 EL Mehl mit Schneebesen glattrühren. Mit Salz, Pfeffer, Muskatnuss würzen.',
            'TEIG AUSROLLEN: Gegangenen Teig auf einem gefetteten Backblech (40x30cm) ausrollen. Einen 2cm hohen Rand hochziehen - der Guss darf nicht auslaufen!',
            'BELEGEN: Abgekühlte Zwiebeln gleichmäßig auf dem Teig verteilen. Speckwürfel darüber streuen.',
            'GUSS DARÜBER: Schmand-Ei-Mischung gleichmäßig über Zwiebeln und Speck gießen. Mit einer Gabel kurz verteilen.',
            'BACKEN: Im vorgeheizten Ofen bei 200°C (Ober-/Unterhitze) 35-45 Minuten backen bis der Guss gestockt und der Rand goldbraun ist. Der Guss sollte noch leicht wackeln.',
            'SERVIEREN: Lauwarm oder kalt in Stücke schneiden. Traditionell mit Federweißem (junger Wein) servieren - im Herbst ein Muss! Schmeckt am nächsten Tag noch besser!'
        ]
    },
    {
        'name': 'Reibekuchen mit Apfelmus',
        'category': 'german',
        'description': 'Knusprig gebratene Kartoffelpuffer mit selbstgemachtem Apfelmus - der rheinische Klassiker! Auch bekannt als Kartoffelpuffer oder Reiberdatschi.',
        'image_url': 'https://images.unsplash.com/photo-1568158879083-c42860933ed7?w=800',
        'prep_time': 30,
        'cook_time': 40,
        'servings': 4,
        'difficulty': 'medium',
        'nutrition': {'calories': 480, 'protein': 12, 'carbs': 68, 'fat': 18, 'fiber': 8},
        'tags': ['lunch', 'dinner', 'snack'],
        'ingredients': [
            {'name': 'Kartoffeln mehlig', 'quantity': '1.5', 'unit': 'kg', 'keywords': ['kartoffel', 'potato', 'mehlig'], 'priority': 3},
            {'name': 'Zwiebeln', 'quantity': '2', 'unit': 'Stück', 'keywords': ['zwiebel', 'onion'], 'priority': 2},
            {'name': 'Eier', 'quantity': '2', 'unit': 'Stück', 'keywords': ['ei', 'egg'], 'priority': 2},
            {'name': 'Mehl', 'quantity': '4', 'unit': 'EL', 'keywords': ['mehl', 'flour'], 'priority': 1},
            {'name': 'Äpfel säuerlich', 'quantity': '1', 'unit': 'kg', 'keywords': ['apfel', 'apple'], 'priority': 3},
            {'name': 'Zitrone', 'quantity': '1', 'unit': 'Stück', 'keywords': ['zitrone', 'lemon'], 'priority': 1},
        ],
        'instructions': [
            'APFELMUS KOCHEN: Äpfel schälen, entkernen, vierteln. Mit 100ml Wasser, 3 EL Zucker, Saft einer halben Zitrone, 1 Zimtstange in einen Topf geben. Zugedeckt 20 Minuten köcheln bis die Äpfel zerfallen. Mit Kartoffelstampfer zerdrücken oder glatt pürieren.',
            'KARTOFFELN REIBEN: Kartoffeln schälen, sofort in eine Schüssel mit kaltem Wasser reiben (grobe Reibe). Das verhindert das Braunwerden! Auch Zwiebeln grob reiben.',
            'MASSE AUSDRÜCKEN: Kartoffel-Zwiebel-Masse portionsweise in ein sauberes Küchentuch geben und kräftig ausdrücken. Die Stärkeflüssigkeit in einer Schüssel auffangen und 5 Minuten stehen lassen.',
            'STÄRKE ZURÜCKGEBEN: Die Flüssigkeit vorsichtig abgießen - die weiße Stärke am Boden bleibt zurück! Diese Stärke zurück zur ausgedrückten Kartoffelmasse geben - das bindet!',
            'TEIG MACHEN: Ausgedrückte Kartoffel-Zwiebel-Masse, Kartoffelstärke, 2 Eier, 4 EL Mehl, 1,5 TL Salz, Pfeffer gründlich vermischen. Der Teig sollte zusammenhalten.',
            'FETT ERHITZEN: Große Pfanne mit reichlich Öl (ca. 1cm hoch) auf mittlerer bis hoher Hitze erhitzen. Das Öl muss richtig heiß sein!',
            'REIBEKUCHEN BRATEN: Mit einem Esslöffel Teig in die Pfanne geben, flach drücken - ca. 1cm dick. Nicht zu viele auf einmal! Je Seite 4-5 Minuten goldbraun und knusprig braten.',
            'ABTROPFEN: Fertige Reibekuchen auf Küchenpapier legen, Fett abtropfen lassen. Im Ofen bei 100°C warm halten bis alle fertig sind.',
            'WÜRZEN: Direkt nach dem Braten mit etwas Salz bestreuen - das gibt extra Würze!',
            'SERVIEREN: Heiß mit warmem oder kaltem Apfelmus servieren. Traditionell auch mit Rübenkraut oder Schmand. Die Reibekuchen müssen außen kross und innen saftig sein!'
        ]
    },
    {
        'name': 'Himmel und Erde mit Blutwurst',
        'category': 'german',
        'description': 'Rheinisches Traditionsessen: Kartoffelpüree (Erde) mit Apfelmus (Himmel), gebratener Blutwurst und Röstzwiebeln. Deftig und heimelig!',
        'image_url': 'https://images.unsplash.com/photo-1585325701165-9d63cf2c5ff4?w=800',
        'prep_time': 25,
        'cook_time': 35,
        'servings': 4,
        'difficulty': 'easy',
        'nutrition': {'calories': 620, 'protein': 24, 'carbs': 72, 'fat': 26, 'fiber': 8},
        'tags': ['dinner', 'family-friendly'],
        'ingredients': [
            {'name': 'Kartoffeln mehlig', 'quantity': '1', 'unit': 'kg', 'keywords': ['kartoffel', 'potato', 'mehlig'], 'priority': 3},
            {'name': 'Äpfel säuerlich', 'quantity': '800', 'unit': 'g', 'keywords': ['apfel', 'apple'], 'priority': 3},
            {'name': 'Blutwurst', 'quantity': '4', 'unit': 'Stück', 'keywords': ['blutwurst', 'wurst', 'blood sausage'], 'priority': 3},
            {'name': 'Zwiebeln', 'quantity': '3', 'unit': 'Stück', 'keywords': ['zwiebel', 'onion'], 'priority': 2},
            {'name': 'Milch', 'quantity': '200', 'unit': 'ml', 'keywords': ['milch', 'milk'], 'priority': 2},
            {'name': 'Butter', 'quantity': '100', 'unit': 'g', 'keywords': ['butter'], 'priority': 1},
        ],
        'instructions': [
            'KARTOFFELN KOCHEN: Kartoffeln schälen, vierteln, in Salzwasser 20 Minuten kochen bis sie weich sind. Abgießen, ausdampfen lassen.',
            'APFELMUS: Äpfel schälen, entkernen, würfeln. Mit 50ml Wasser, 2 EL Zucker, 1 Prise Zimt in einem Topf weich kochen - ca. 15 Minuten. Grob stampfen oder als Stücke lassen.',
            'PÜREE STAMPFEN: Kartoffeln durch eine Kartoffelpresse drücken oder stampfen. 50g Butter und heiße Milch unterrühren bis es cremig ist. Mit Salz, Pfeffer, Muskatnuss würzen.',
            'RÖSTZWIEBELN: Zwiebeln in feine Ringe schneiden. In einer Pfanne mit reichlich Öl oder Butterschmalz goldbraun und knusprig braten - ca. 10 Minuten. Auf Küchenpapier abtropfen.',
            'BLUTWURST VORBEREITEN: Blutwurst in 2cm dicke Scheiben schneiden. Haut kann dran bleiben oder entfernt werden.',
            'BLUTWURST BRATEN: In einer beschichteten Pfanne mit wenig Fett bei mittlerer Hitze je Seite 3-4 Minuten braten bis sie knusprig ist. Vorsichtig wenden - sie zerfällt leicht!',
            'WARMHALTEN: Kartoffelpüree und Apfelmus bei niedriger Temperatur warm halten.',
            'ANRICHTEN: Auf jedem Teller eine Portion Kartoffelpüree und eine Portion Apfelmus nebeneinander geben - Himmel und Erde!',
            'BLUTWURST AUFLEGEN: Blutwurstscheiben auf dem Püree anrichten.',
            'TOPPING: Großzügig knusprige Röstzwiebeln über alles streuen. Optional mit gebratenen Apfelringen garnieren. Sofort servieren - ein Gedicht!'
        ]
    },
    {
        'name': 'Eisbein mit Sauerkraut und Erbspüree',
        'category': 'german',
        'description': 'Zartes, gepökeltes Schweinshaxe mit knuspriger Kruste, würzigem Sauerkraut und cremigem Erbspüree. Berliner Traditionsessen!',
        'image_url': 'https://images.unsplash.com/photo-1598103442097-8b74394b95c6?w=800',
        'prep_time': 30,
        'cook_time': 180,
        'servings': 4,
        'difficulty': 'medium',
        'nutrition': {'calories': 780, 'protein': 56, 'carbs': 48, 'fat': 38, 'fiber': 12},
        'tags': ['dinner', 'family-friendly'],
        'ingredients': [
            {'name': 'Eisbein gepökelt', 'quantity': '2', 'unit': 'Stück', 'keywords': ['eisbein', 'schwein', 'haxe', 'schweinshaxe'], 'priority': 3},
            {'name': 'Sauerkraut', 'quantity': '1000', 'unit': 'g', 'keywords': ['sauerkraut', 'kraut'], 'priority': 2},
            {'name': 'Erbsen gelb getrocknet', 'quantity': '400', 'unit': 'g', 'keywords': ['erbsen', 'peas', 'gelb'], 'priority': 3},
            {'name': 'Zwiebeln', 'quantity': '3', 'unit': 'Stück', 'keywords': ['zwiebel', 'onion'], 'priority': 2},
            {'name': 'Karotten', 'quantity': '2', 'unit': 'Stück', 'keywords': ['karotte', 'möhre'], 'priority': 1},
            {'name': 'Sellerie', 'quantity': '1', 'unit': 'Stück', 'keywords': ['sellerie', 'celery'], 'priority': 1},
            {'name': 'Lorbeerblätter', 'quantity': '3', 'unit': 'Stück', 'keywords': ['lorbeer', 'bay leaf'], 'priority': 1},
            {'name': 'Kümmel', 'quantity': '2', 'unit': 'TL', 'keywords': ['kümmel', 'caraway'], 'priority': 1},
        ],
        'instructions': [
            'ERBSEN EINWEICHEN: Gelbe Erbsen über Nacht in reichlich kaltem Wasser einweichen. Am nächsten Tag abgießen und abspülen.',
            'EISBEIN VORBEREITEN: Eisbein kalt abspülen. Falls die Schwarte noch rau ist, mit einem scharfen Messer abschaben. Dann rautenförmig einschneiden - ca. 1cm tief.',
            'EISBEIN KOCHEN: Eisbein in einen großen Topf legen. Mit Wasser bedecken. 1 Zwiebel (geviertelt), 1 Karotte, Sellerie (grob), 2 Lorbeerblätter, 10 Pfefferkörner, 1 TL Kümmel zugeben. Aufkochen, Schaum abschöpfen. Bei schwacher Hitze 2,5-3 Stunden köcheln.',
            'ERBSPÜREE KOCHEN: Eingeweichte Erbsen mit frischem Wasser bedecken. 1 Zwiebel (gewürfelt), 1 Karotte (gewürfelt) zugeben. 60-90 Minuten köcheln bis die Erbsen zerfallen. Gelegentlich umrühren!',
            'ERBSPÜREE VERFEINERN: Gemüsestücke entfernen. Erbsen mit Kartoffelstampfer zerdrücken. Mit Salz, Pfeffer, 1 Prise Zucker würzen. Optional etwas Butter einrühren für Cremigkeit.',
            'SAUERKRAUT ZUBEREITEN: Sauerkraut in einem Topf mit 1 gewürfelten Zwiebel, 1 geriebenem Apfel, Kümmel, 1 Lorbeerblatt, 100ml Weißwein 30 Minuten köcheln. Mit Salz, Pfeffer, Zucker abschmecken.',
            'EISBEIN KROSS MACHEN: Eisbein aus dem Sud nehmen, trocken tupfen. Schwarte mit Honig oder Bier bestreichen. In einer Pfanne oder im Ofen bei 220°C die Schwarte 15-20 Minuten knusprig braten.',
            'SUD REDUZIEREN: Kochsud durch ein Sieb gießen. Optional auf 300ml einkochen und als leichte Sauce servieren.',
            'SCHNEIDEN: Eisbein vorsichtig vom Knochen lösen oder mit Knochen servieren. Das Fleisch sollte so zart sein, dass es fast von selbst abfällt!',
            'SERVIEREN: Eisbein mit Sauerkraut und Erbspüree anrichten. Dazu Senf und frisches Bauernbrot. Mit einem kalten Bier genießen!'
        ]
    },
    {
        'name': 'Norddeutscher Labskaus',
        'category': 'german',
        'description': 'Hamburger Seemannsgericht aus Pökelfleisch, Kartoffeln und Roter Bete - gekrönt mit Spiegelei und Rollmops. Ein Kultgericht!',
        'image_url': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800',
        'prep_time': 25,
        'cook_time': 40,
        'servings': 4,
        'difficulty': 'medium',
        'nutrition': {'calories': 540, 'protein': 32, 'carbs': 46, 'fat': 26, 'fiber': 5},
        'tags': ['lunch', 'dinner'],
        'ingredients': [
            {'name': 'Corned Beef', 'quantity': '400', 'unit': 'g', 'keywords': ['corned beef', 'pökelfleisch', 'rind'], 'priority': 3},
            {'name': 'Kartoffeln mehlig', 'quantity': '800', 'unit': 'g', 'keywords': ['kartoffel', 'potato', 'mehlig'], 'priority': 3},
            {'name': 'Rote Bete gekocht', 'quantity': '400', 'unit': 'g', 'keywords': ['rote bete', 'beetroot'], 'priority': 3},
            {'name': 'Zwiebeln', 'quantity': '2', 'unit': 'Stück', 'keywords': ['zwiebel', 'onion'], 'priority': 2},
            {'name': 'Gewürzgurken', 'quantity': '4', 'unit': 'Stück', 'keywords': ['gurke', 'pickle'], 'priority': 2},
            {'name': 'Rollmops', 'quantity': '4', 'unit': 'Stück', 'keywords': ['rollmops', 'hering', 'herring'], 'priority': 2},
            {'name': 'Eier', 'quantity': '4', 'unit': 'Stück', 'keywords': ['ei', 'egg'], 'priority': 2},
            {'name': 'Butter', 'quantity': '60', 'unit': 'g', 'keywords': ['butter'], 'priority': 1},
        ],
        'instructions': [
            'KARTOFFELN KOCHEN: Kartoffeln schälen, in Stücke schneiden, in Salzwasser 20 Minuten weich kochen. Abgießen, zurück in den Topf geben.',
            'ROTE BETE VORBEREITEN: Rote Bete (vorgekocht, vakuumiert oder Glas) in kleine Würfel schneiden. Saft auffangen - der kommt auch in den Labskaus!',
            'FLEISCH KOCHEN: Corned Beef (oder gepökeltes Rindfleisch) in Würfel schneiden. In einem Topf mit Wasser bedecken, 30 Minuten köcheln bis es zart ist. Abgießen, Sud aufbewahren.',
            'ZWIEBELN ANSCHWITZEN: Zwiebeln fein würfeln, in einer Pfanne mit Butter goldgelb anschwitzen.',
            'ALLES STAMPFEN: Kartoffeln, Fleisch, Rote Bete, Zwiebeln in eine Schüssel geben. Mit einem Kartoffelstampfer grob zerstampfen - nicht zu fein! Es sollte noch stückig sein.',
            'WÜRZEN & BINDEN: Mit Salz, Pfeffer, Muskatnuss, etwas Rote-Bete-Saft würzen. Optional etwas Butter und Kochsud vom Fleisch zugeben bis die Konsistenz sämig ist. Die Farbe sollte schön rosa-rot sein!',
            'ERWÄRMEN: Labskaus in einem Topf oder Pfanne unter Rühren erwärmen. Nicht zu heiß - sonst trocknet es aus!',
            'SPIEGELEIER: 4 Spiegeleier in Butter braten - das Eigelb sollte noch flüssig sein!',
            'ANRICHTEN: Labskaus zu einem Häufchen auf Tellern anrichten. Spiegelei oben drauf setzen.',
            'GARNITUR: Mit Rollmops, Gewürzgurkenfächer und eingelegten Rote-Bete-Scheiben garnieren. Dazu passt Schwarzbrot. Beim Essen alles vermischen!'
        ]
    },
    {
        'name': 'Deutscher Kartoffelsalat mit Würstchen',
        'category': 'german',
        'description': 'Klassischer süddeutscher Kartoffelsalat mit Brühe und Essig - ohne Mayo! Mit knackigen Wiener Würstchen serviert.',
        'image_url': 'https://images.unsplash.com/photo-1562843142-c4e7ffe0a208?w=800',
        'prep_time': 30,
        'cook_time': 25,
        'servings': 4,
        'difficulty': 'easy',
        'nutrition': {'calories': 480, 'protein': 18, 'carbs': 58, 'fat': 20, 'fiber': 5},
        'tags': ['lunch', 'dinner', 'family-friendly', 'bbq'],
        'ingredients': [
            {'name': 'Kartoffeln festkochend', 'quantity': '1.2', 'unit': 'kg', 'keywords': ['kartoffel', 'potato', 'festkochend'], 'priority': 3},
            {'name': 'Wiener Würstchen', 'quantity': '8', 'unit': 'Stück', 'keywords': ['wiener', 'würstchen', 'wurst'], 'priority': 3},
            {'name': 'Zwiebeln', 'quantity': '2', 'unit': 'Stück', 'keywords': ['zwiebel', 'onion'], 'priority': 2},
            {'name': 'Gemüsebrühe', 'quantity': '400', 'unit': 'ml', 'keywords': ['brühe', 'bouillon'], 'priority': 2},
            {'name': 'Weißweinessig', 'quantity': '80', 'unit': 'ml', 'keywords': ['essig', 'vinegar', 'weißwein'], 'priority': 2},
            {'name': 'Senf mittelscharf', 'quantity': '2', 'unit': 'EL', 'keywords': ['senf', 'mustard'], 'priority': 1},
            {'name': 'Rapsöl', 'quantity': '100', 'unit': 'ml', 'keywords': ['öl', 'oil', 'raps'], 'priority': 1},
            {'name': 'Schnittlauch', 'quantity': '1', 'unit': 'Bund', 'keywords': ['schnittlauch', 'chives'], 'priority': 1},
        ],
        'instructions': [
            'KARTOFFELN KOCHEN: Kartoffeln mit Schale in Salzwasser 20-25 Minuten kochen bis sie gar, aber noch fest sind. Nicht zu weich - sonst zerfallen sie im Salat!',
            'PELLEN & SCHNEIDEN: Kartoffeln abgießen, kurz abkühlen lassen, dann pellen. NOCH WARM in dünne Scheiben schneiden - ca. 5mm. Warme Kartoffeln nehmen das Dressing besser auf!',
            'DRESSING MACHEN: 400ml heiße Gemüsebrühe mit 80ml Essig, 100ml Öl, 2 EL Senf, 2 TL Zucker, Salz, Pfeffer in einer Schüssel verrühren.',
            'ZWIEBELN VORBEREITEN: 1 Zwiebel sehr fein würfeln, zum Dressing geben. Die andere Zwiebel in feine Ringe schneiden.',
            'MARINIEREN: Warme Kartoffelscheiben in eine große Schüssel geben. Heißes Dressing darüber gießen, vorsichtig unterheben. Die Kartoffeln sollen das Dressing aufsaugen!',
            'ZIEHEN LASSEN: Zwiebelringe unterheben. Salat zugedeckt mindestens 1 Stunde ziehen lassen - am besten 2-3 Stunden oder über Nacht. Zwischendurch vorsichtig durchmischen.',
            'WÜRSTCHEN ERWÄRMEN: Wiener Würstchen in heißem (nicht kochendem!) Wasser 10 Minuten erwärmen. Oder in der Pfanne kurz anbraten.',
            'ABSCHMECKEN: Kartoffelsalat nochmals mit Salz, Pfeffer, Essig, Zucker abschmecken. Er sollte würzig und leicht säuerlich sein. Bei Bedarf etwas Brühe oder Öl nachgeben.',
            'GARNIEREN: Frisch geschnittenen Schnittlauch untermengen oder darüber streuen.',
            'SERVIEREN: Kartoffelsalat auf Tellern anrichten, Würstchen dazu legen. Optional mit Senf servieren. Schmeckt lauwarm am besten!'
        ]
    },
]

if __name__ == "__main__":
    conn = sqlite3.connect(DB_PATH)

    print(f"Adding {len(RECIPES)} German recipes (Part 4) to database...")

    for recipe in RECIPES:
        recipe_id = add_recipe(conn, recipe)
        print(f"  Added: {recipe['name']}")

    # Verify
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM recipes")
    total = cursor.fetchone()[0]

    print(f"\nSuccess! Database now has {total} recipes total")

    conn.close()
