#!/usr/bin/env python3
"""
Add popular GERMAN recipes to SmartMeal database - Part 3
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

# GERMAN CLASSIC RECIPES - Part 3 (Recipes 10-15)
RECIPES = [
    {
        'name': 'Spätzle mit Geschnetzeltem',
        'category': 'german',
        'description': 'Hausgemachte schwäbische Spätzle mit zartem Schweinegeschnetzeltem in cremiger Champignon-Rahm-Sauce. Ein schwäbischer Klassiker!',
        'image_url': 'https://images.unsplash.com/photo-1612871689287-d5e1db26b39e?w=800',
        'prep_time': 40,
        'cook_time': 25,
        'servings': 4,
        'difficulty': 'medium',
        'nutrition': {'calories': 620, 'protein': 38, 'carbs': 58, 'fat': 26, 'fiber': 4},
        'tags': ['dinner', 'family-friendly'],
        'ingredients': [
            {'name': 'Mehl', 'quantity': '400', 'unit': 'g', 'keywords': ['mehl', 'flour'], 'priority': 1},
            {'name': 'Eier', 'quantity': '4', 'unit': 'Stück', 'keywords': ['ei', 'egg'], 'priority': 2},
            {'name': 'Schweineschnitzel', 'quantity': '600', 'unit': 'g', 'keywords': ['schwein', 'pork', 'schnitzel'], 'priority': 3},
            {'name': 'Champignons', 'quantity': '400', 'unit': 'g', 'keywords': ['champignon', 'mushroom', 'pilz'], 'priority': 2},
            {'name': 'Zwiebeln', 'quantity': '2', 'unit': 'Stück', 'keywords': ['zwiebel', 'onion'], 'priority': 2},
            {'name': 'Sahne', 'quantity': '300', 'unit': 'ml', 'keywords': ['sahne', 'cream', 'schlagsahne'], 'priority': 2},
            {'name': 'Weißwein trocken', 'quantity': '100', 'unit': 'ml', 'keywords': ['weißwein', 'white wine'], 'priority': 2},
            {'name': 'Butter', 'quantity': '60', 'unit': 'g', 'keywords': ['butter'], 'priority': 1},
        ],
        'instructions': [
            'SPÄTZLE-TEIG: 400g Mehl in eine Schüssel geben. 4 Eier, 150ml lauwarmes Wasser, 1 TL Salz zugeben. Mit einem Kochlöffel kräftig schlagen bis Blasen entstehen - ca. 5 Minuten! Der Teig sollte schwer vom Löffel reißen.',
            'TEIG RUHEN: Teig zugedeckt 30 Minuten bei Raumtemperatur ruhen lassen. Das entspannt das Gluten und macht die Spätzle zarter.',
            'WASSER AUFSETZEN: Großen Topf mit Salzwasser zum Kochen bringen. Ein Spätzlebrett oder Spätzlehobel bereitlegen.',
            'SPÄTZLE SCHABEN: Teig portionsweise auf ein angefeuchtetes Spätzlebrett geben. Mit einem Schaber oder Messer dünne Streifen ins kochende Wasser schaben. Wenn sie oben schwimmen, mit einer Schaumkelle herausnehmen. In kaltem Wasser abschrecken, abtropfen.',
            'FLEISCH SCHNEIDEN: Schnitzel in dünne Streifen schneiden - ca. 1cm breit. Mit Salz und Pfeffer würzen. Das Fleisch sollte quer zur Faser geschnitten werden!',
            'CHAMPIGNONS VORBEREITEN: Champignons putzen, in Scheiben schneiden. Zwiebeln fein würfeln.',
            'FLEISCH ANBRATEN: Öl in einer großen Pfanne erhitzen. Fleischstreifen portionsweise scharf anbraten - je Seite 1-2 Minuten. Herausnehmen und warm stellen. Nicht zu lange braten - sonst wird es zäh!',
            'SAUCE ZUBEREITEN: Im gleichen Bratfett Zwiebeln glasig dünsten. Champignons zugeben, 5 Minuten braten bis die Flüssigkeit verdampft ist. Mit Weißwein ablöschen, einkochen lassen. Sahne zugeben, 3 Minuten köcheln.',
            'FERTIGSTELLEN: Fleisch zurück in die Sauce geben, kurz erwärmen. Mit Salz, Pfeffer, Muskatnuss abschmecken. Optional mit Petersilie verfeinern.',
            'SPÄTZLE SCHWENKEN: Butter in einer Pfanne erhitzen, abgetropfte Spätzle darin schwenken bis sie heiß sind. Mit Geschnetzeltem servieren - zusammen auf dem Teller vermischen!'
        ]
    },
    {
        'name': 'Currywurst mit Pommes Frites',
        'category': 'german',
        'description': 'Die Berliner Kult-Mahlzeit! Knackige Bratwurst in würziger Curry-Tomaten-Sauce mit goldenen Pommes. Street Food at its best!',
        'image_url': 'https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?w=800',
        'prep_time': 20,
        'cook_time': 30,
        'servings': 4,
        'difficulty': 'easy',
        'nutrition': {'calories': 740, 'protein': 24, 'carbs': 68, 'fat': 42, 'fiber': 6},
        'tags': ['dinner', 'lunch', 'fast-food'],
        'ingredients': [
            {'name': 'Bratwürste', 'quantity': '8', 'unit': 'Stück', 'keywords': ['bratwurst', 'wurst', 'sausage'], 'priority': 3},
            {'name': 'Pommes Frites', 'quantity': '800', 'unit': 'g', 'keywords': ['pommes', 'frites', 'kartoffel'], 'priority': 3},
            {'name': 'Tomatenmark', 'quantity': '4', 'unit': 'EL', 'keywords': ['tomatenmark', 'tomato paste'], 'priority': 2},
            {'name': 'Zwiebeln', 'quantity': '2', 'unit': 'Stück', 'keywords': ['zwiebel', 'onion'], 'priority': 2},
            {'name': 'Currypulver', 'quantity': '3', 'unit': 'EL', 'keywords': ['curry', 'pulver'], 'priority': 2},
            {'name': 'Paprikapulver edelsüß', 'quantity': '2', 'unit': 'EL', 'keywords': ['paprika', 'pulver'], 'priority': 1},
            {'name': 'Ketchup', 'quantity': '200', 'unit': 'ml', 'keywords': ['ketchup', 'tomato'], 'priority': 2},
            {'name': 'Gemüsebrühe', 'quantity': '200', 'unit': 'ml', 'keywords': ['brühe', 'bouillon'], 'priority': 1},
        ],
        'instructions': [
            'CURRYSAUCE STARTEN: Zwiebeln fein würfeln, in einem Topf mit 2 EL Öl glasig dünsten. Tomatenmark zugeben, kurz anrösten bis es duftet.',
            'GEWÜRZE RÖSTEN: Currypulver und Paprikapulver zugeben, unter Rühren 30 Sekunden rösten. Das entfaltet die Aromen! Nicht anbrennen lassen.',
            'SAUCE AUFBAUEN: Ketchup, Gemüsebrühe, 1 EL Apfelessig, 1 EL Zucker, 1 Prise Salz zugeben. Aufkochen, dann 15 Minuten bei mittlerer Hitze köcheln lassen.',
            'SAUCE VERFEINERN: Mit Pürierstab fein pürieren oder durch ein Sieb streichen. Mit Salz, Pfeffer, Zucker, Essig, eventuell mehr Curry abschmecken. Die Sauce sollte süß-scharf-würzig sein!',
            'WÜRSTE BRATEN: Bratwürste in einer Pfanne mit wenig Öl rundherum goldbraun braten - ca. 10-12 Minuten bei mittlerer Hitze. Sie sollten knackig sein!',
            'POMMES VORBEREITEN: Backofen auf 220°C vorheizen. Pommes auf einem Backblech verteilen, mit etwas Öl beträufeln. 25-30 Minuten backen bis sie goldbraun und knusprig sind. Zwischendurch wenden!',
            'WÜRSTE SCHNEIDEN: Bratwürste in mundgerechte Stücke schneiden - ca. 2cm lang. Manche mögen sie auch ganz!',
            'ANRICHTEN: Pommes auf Teller oder in Schalen geben. Wurststücke darauf verteilen.',
            'SAUCE DRÜBER: Großzügig Currysauce über Wurst und Pommes geben. Mit extra Currypulver bestreuen - das ist das Markenzeichen!',
            'SERVIEREN: Mit Holzgabeln oder Plastikgabeln servieren - original Berliner Art! Wer mag, kann Mayo dazu reichen. Sofort essen, solange es heiß ist!'
        ]
    },
    {
        'name': 'Saftige Frikadellen mit Kartoffelsalat',
        'category': 'german',
        'description': 'Knusprig gebratene Hackfleischbällchen mit deutschem Kartoffelsalat. Der norddeutsche Klassiker - perfekt für Picknicks und Partys!',
        'image_url': 'https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?w=800',
        'prep_time': 30,
        'cook_time': 25,
        'servings': 4,
        'difficulty': 'easy',
        'nutrition': {'calories': 580, 'protein': 34, 'carbs': 42, 'fat': 30, 'fiber': 4},
        'tags': ['dinner', 'lunch', 'family-friendly'],
        'ingredients': [
            {'name': 'Rinderhackfleisch', 'quantity': '500', 'unit': 'g', 'keywords': ['rind', 'hackfleisch', 'ground beef'], 'priority': 3},
            {'name': 'Schweinehackfleisch', 'quantity': '300', 'unit': 'g', 'keywords': ['schwein', 'hackfleisch', 'ground pork'], 'priority': 3},
            {'name': 'Brötchen altbacken', 'quantity': '2', 'unit': 'Stück', 'keywords': ['brötchen', 'semmel', 'roll'], 'priority': 2},
            {'name': 'Kartoffeln festkochend', 'quantity': '1', 'unit': 'kg', 'keywords': ['kartoffel', 'potato', 'festkochend'], 'priority': 3},
            {'name': 'Zwiebeln', 'quantity': '3', 'unit': 'Stück', 'keywords': ['zwiebel', 'onion'], 'priority': 2},
            {'name': 'Eier', 'quantity': '2', 'unit': 'Stück', 'keywords': ['ei', 'egg'], 'priority': 2},
            {'name': 'Gewürzgurken', 'quantity': '6', 'unit': 'Stück', 'keywords': ['gurke', 'pickle'], 'priority': 2},
            {'name': 'Gemüsebrühe', 'quantity': '300', 'unit': 'ml', 'keywords': ['brühe', 'bouillon'], 'priority': 1},
            {'name': 'Senf mittelscharf', 'quantity': '3', 'unit': 'EL', 'keywords': ['senf', 'mustard'], 'priority': 1},
        ],
        'instructions': [
            'BRÖTCHEN EINWEICHEN: Brötchen in Wasser einweichen, 10 Minuten ziehen lassen. Gut ausdrücken bis sie fast trocken sind.',
            'HACKMASSE VORBEREITEN: Beide Hackfleischsorten in eine Schüssel geben. 1 fein gewürfelte Zwiebel, ausgedrückte Brötchen, 1 Ei, 2 EL Senf, Salz, Pfeffer, Paprikapulver zugeben. Mit den Händen 5 Minuten kräftig kneten!',
            'FRIKADELLEN FORMEN: Mit nassen Händen etwa 12 gleichgroße Frikadellen formen - schön flach drücken, ca. 2cm dick. Flache Frikadellen werden schön kross!',
            'KARTOFFELN KOCHEN: Kartoffeln mit Schale in Salzwasser 20-25 Minuten kochen. Abgießen, kurz abkühlen lassen, dann pellen. Noch warm in Scheiben schneiden - so saugen sie das Dressing besser auf!',
            'DRESSING MACHEN: 300ml heiße Gemüsebrühe mit 4 EL Öl, 3 EL Essig, 2 TL Senf, 1 TL Zucker, Salz, Pfeffer verrühren. Über die warmen Kartoffelscheiben gießen, vorsichtig mischen.',
            'SALAT VERFEINERN: 1 fein gewürfelte Zwiebel, gewürfelte Gewürzgurken, 3 EL Gurkenwasser zugeben. Alles vorsichtig vermischen. Mindestens 30 Minuten ziehen lassen - besser noch 2 Stunden!',
            'FRIKADELLEN BRATEN: Öl in einer großen Pfanne erhitzen. Frikadellen hineinlegen, bei mittlerer Hitze je Seite 5-6 Minuten braten bis sie goldbraun und durchgegart sind.',
            'KROSS-TRICK: In den letzten 2 Minuten Hitze etwas erhöhen für extra knusprige Kruste. Mit Deckel bekommen sie keine Kruste!',
            'SALAT ABSCHMECKEN: Kartoffelsalat nochmals mit Salz, Pfeffer, Essig, Senf abschmecken. Er sollte würzig sein! Optional mit gehackter Petersilie oder Schnittlauch garnieren.',
            'SERVIEREN: Frikadellen heiß mit dem Kartoffelsalat servieren. Klassisch kalt oder lauwarm zum Salat. Dazu passen Gewürzgurken und Senf!'
        ]
    },
    {
        'name': 'Maultaschen in Brühe',
        'category': 'german',
        'description': 'Schwäbische Maultaschen gefüllt mit Hackfleisch, Spinat und Brät, serviert in klarer Rinderbrühe. Herrgottsbscheißerle - die schwäbische Leibspeise!',
        'image_url': 'https://images.unsplash.com/photo-1626200419199-391ae4be7a41?w=800',
        'prep_time': 60,
        'cook_time': 20,
        'servings': 4,
        'difficulty': 'hard',
        'nutrition': {'calories': 520, 'protein': 32, 'carbs': 54, 'fat': 20, 'fiber': 5},
        'tags': ['dinner', 'lunch', 'family-friendly'],
        'ingredients': [
            {'name': 'Mehl', 'quantity': '400', 'unit': 'g', 'keywords': ['mehl', 'flour'], 'priority': 1},
            {'name': 'Eier', 'quantity': '4', 'unit': 'Stück', 'keywords': ['ei', 'egg'], 'priority': 2},
            {'name': 'Rinderhackfleisch', 'quantity': '300', 'unit': 'g', 'keywords': ['rind', 'hackfleisch', 'ground beef'], 'priority': 3},
            {'name': 'Spinat tiefgekühlt', 'quantity': '300', 'unit': 'g', 'keywords': ['spinat', 'spinach'], 'priority': 2},
            {'name': 'Brötchen altbacken', 'quantity': '3', 'unit': 'Stück', 'keywords': ['brötchen', 'semmel'], 'priority': 2},
            {'name': 'Zwiebeln', 'quantity': '2', 'unit': 'Stück', 'keywords': ['zwiebel', 'onion'], 'priority': 2},
            {'name': 'Rinderbrühe', 'quantity': '2', 'unit': 'Liter', 'keywords': ['brühe', 'bouillon', 'rind'], 'priority': 2},
            {'name': 'Majoran getrocknet', 'quantity': '1', 'unit': 'TL', 'keywords': ['majoran', 'marjoram'], 'priority': 1},
        ],
        'instructions': [
            'NUDELTEIG: 400g Mehl mit 4 Eiern, 2 EL Öl, 1 Prise Salz und etwas Wasser zu einem glatten Teig verkneten - er sollte geschmeidig aber nicht klebrig sein. In Folie wickeln, 30 Minuten ruhen lassen.',
            'FÜLLUNG VORBEREITEN: Spinat auftauen, gut ausdrücken. Brötchen in Milch einweichen, ausdrücken. Zwiebel fein würfeln, in Butter glasig dünsten, abkühlen lassen.',
            'FÜLLUNG MISCHEN: Hackfleisch, Spinat, Brötchenmasse, Zwiebeln, 1 Ei, Majoran, Salz, Pfeffer, Muskatnuss gründlich vermischen. Die Masse sollte formbar sein - eventuell etwas Semmelbrösel zugeben.',
            'TEIG AUSROLLEN: Teig halbieren. Jede Hälfte auf bemehlter Fläche sehr dünn ausrollen - ca. 2mm dick. So dünn wie möglich, aber ohne Löcher!',
            'FÜLLEN: Füllung in dünnen Streifen auf die untere Hälfte der Teigplatten streichen - ca. 3cm breit. 2cm Abstand zum Rand lassen.',
            'EINSCHLAGEN: Obere Teighälfte über die Füllung klappen. Zwischen den Füllungsstreifen fest andrücken. Mit einem Teigrad in ca. 8x10cm große Rechtecke schneiden. Ränder fest zusammendrücken!',
            'BRÜHE KOCHEN: Rinderbrühe in einem großen Topf zum Kochen bringen. Mit Salz, Pfeffer, Suppenwürze abschmecken. Optional: Mit Gemüse (Karotten, Sellerie, Lauch) anreichern.',
            'MAULTASCHEN GAREN: Hitze reduzieren bis die Brühe nur noch leicht siedet. Maultaschen vorsichtig einlegen. 15-20 Minuten ziehen lassen - NICHT kochen, sonst platzen sie!',
            'PRÜFEN: Maultaschen sind fertig wenn sie an der Oberfläche schwimmen und der Teig glasig aussieht.',
            'SERVIEREN: Maultaschen mit einer Schaumkelle herausheben, in tiefen Tellern anrichten. Mit heißer Brühe übergießen. Mit Schnittlauch garnieren. Dazu passt Kartoffelsalat!'
        ]
    },
    {
        'name': 'Käsespätzle mit Röstzwiebeln',
        'category': 'german',
        'description': 'Schwäbische Spätzle überbacken mit würzigem Bergkäse und knusprigen Röstzwiebeln. Comfort Food vom Feinsten!',
        'image_url': 'https://images.unsplash.com/photo-1612871689287-d5e1db26b39e?w=800',
        'prep_time': 35,
        'cook_time': 30,
        'servings': 4,
        'difficulty': 'medium',
        'nutrition': {'calories': 680, 'protein': 28, 'carbs': 64, 'fat': 34, 'fiber': 4},
        'tags': ['dinner', 'family-friendly', 'vegetarian'],
        'ingredients': [
            {'name': 'Mehl', 'quantity': '500', 'unit': 'g', 'keywords': ['mehl', 'flour'], 'priority': 1},
            {'name': 'Eier', 'quantity': '5', 'unit': 'Stück', 'keywords': ['ei', 'egg'], 'priority': 2},
            {'name': 'Emmentaler gerieben', 'quantity': '300', 'unit': 'g', 'keywords': ['emmentaler', 'käse', 'cheese'], 'priority': 3},
            {'name': 'Bergkäse gerieben', 'quantity': '200', 'unit': 'g', 'keywords': ['bergkäse', 'käse', 'cheese'], 'priority': 2},
            {'name': 'Zwiebeln', 'quantity': '4', 'unit': 'Stück', 'keywords': ['zwiebel', 'onion'], 'priority': 2},
            {'name': 'Butter', 'quantity': '80', 'unit': 'g', 'keywords': ['butter'], 'priority': 1},
            {'name': 'Schnittlauch', 'quantity': '1', 'unit': 'Bund', 'keywords': ['schnittlauch', 'chives'], 'priority': 1},
        ],
        'instructions': [
            'SPÄTZLE-TEIG: 500g Mehl in eine Schüssel geben. 5 Eier, 200ml lauwarmes Wasser, 1,5 TL Salz zugeben. Mit Kochlöffel kräftig 5 Minuten schlagen bis der Teig Blasen wirft. Er sollte schwer vom Löffel reißen.',
            'TEIG RUHEN: Teig zugedeckt 30 Minuten ruhen lassen - das macht die Spätzle zarter.',
            'KÄSE MISCHEN: Emmentaler und Bergkäse mischen. Beiseite stellen. Die Käsemischung gibt den typischen Geschmack!',
            'WASSER AUFSETZEN: Großen Topf mit Salzwasser zum Kochen bringen. Spätzlebrett oder Spätzlehobel bereitlegen.',
            'SPÄTZLE SCHABEN: Teig portionsweise aufs angefeuchtete Brett geben, dünne Streifen ins kochende Wasser schaben. Wenn sie oben schwimmen (ca. 2-3 Min), mit Schaumkelle herausnehmen. Kurz abtropfen lassen - NICHT abschrecken!',
            'SCHICHTEN: Auflaufform buttern. Eine Schicht heiße Spätzle hineinlegen, mit Käse bestreuen, Butterflöckchen darauf. Nächste Lage Spätzle, wieder Käse und Butter. So weitermachen bis alles aufgebraucht ist. Oben sollte viel Käse sein!',
            'ÜBERBACKEN: Im vorgeheizten Backofen bei 180°C ca. 15 Minuten überbacken bis der Käse schmilzt und goldbraun wird.',
            'RÖSTZWIEBELN: Währenddessen Zwiebeln in dünne Ringe schneiden. In einer Pfanne mit reichlich Öl oder Butterschmalz goldbraun und knusprig braten - ca. 10 Minuten bei mittlerer Hitze. Auf Küchenpapier abtropfen.',
            'SERVIEREN: Käsespätzle aus dem Ofen nehmen, mit Röstzwiebeln und frisch geschnittenem Schnittlauch garnieren.',
            'GENUSS: Traditionell mit grünem Salat servieren. Die knusprigen Zwiebeln sind das i-Tüpfelchen! Heiß servieren, damit der Käse noch schön zieht.'
        ]
    },
    {
        'name': 'Elsässer Flammkuchen',
        'category': 'german',
        'description': 'Hauchdünner Teigfladen mit Crème fraîche, Speck und Zwiebeln - knusprig aus dem Ofen. Der Klassiker aus dem Elsass!',
        'image_url': 'https://images.unsplash.com/photo-1571997478779-2adcbbe9ab2f?w=800',
        'prep_time': 30,
        'cook_time': 15,
        'servings': 4,
        'difficulty': 'medium',
        'nutrition': {'calories': 520, 'protein': 18, 'carbs': 48, 'fat': 28, 'fiber': 3},
        'tags': ['dinner', 'lunch', 'party'],
        'ingredients': [
            {'name': 'Mehl', 'quantity': '500', 'unit': 'g', 'keywords': ['mehl', 'flour'], 'priority': 1},
            {'name': 'Crème fraîche', 'quantity': '400', 'unit': 'g', 'keywords': ['crème fraîche', 'creme'], 'priority': 2},
            {'name': 'Bacon-Streifen', 'quantity': '300', 'unit': 'g', 'keywords': ['bacon', 'speck', 'schinken'], 'priority': 3},
            {'name': 'Zwiebeln', 'quantity': '3', 'unit': 'Stück', 'keywords': ['zwiebel', 'onion'], 'priority': 2},
            {'name': 'Hefe frisch', 'quantity': '1', 'unit': 'Würfel', 'keywords': ['hefe', 'yeast'], 'priority': 1},
            {'name': 'Schmand', 'quantity': '200', 'unit': 'g', 'keywords': ['schmand', 'sour cream'], 'priority': 1},
        ],
        'instructions': [
            'HEFETEIG: 500g Mehl in eine Schüssel geben. 1 Würfel frische Hefe in 250ml lauwarmer Milch auflösen. Mit 1 TL Salz, 3 EL Öl zum Mehl geben. Zu einem glatten Teig kneten. Zugedeckt 1 Stunde gehen lassen.',
            'OFEN VORHEIZEN: Backofen auf höchste Stufe vorheizen (250°C) - mit Backblech! Je heißer, desto knuspriger wird der Flammkuchen.',
            'BELAG VORBEREITEN: Zwiebeln in feine Ringe schneiden. Bacon in feine Streifen schneiden (falls noch nicht geschnitten). Crème fraîche und Schmand verrühren, mit Salz, Pfeffer, Muskatnuss würzen.',
            'TEIG TEILEN: Gegangenen Teig in 4 Portionen teilen. Jede Portion sehr dünn ausrollen - ca. 2-3mm! Er sollte fast durchsichtig sein.',
            'BESTREICHEN: Teigfladen mit der Crème-fraîche-Mischung dünn bestreichen - bis ca. 1cm zum Rand.',
            'BELEGEN: Zwiebelringe gleichmäßig verteilen, dann Baconstreifen darauf legen. Nicht zu dick belegen!',
            'BACKEN: Flammkuchen auf das heiße Backblech legen oder direkt auf den Ofenrost (mit Backpapier). 8-10 Minuten backen bis die Ränder knusprig und der Speck kross ist.',
            'BEOBACHTEN: Gut aufpassen - bei der hohen Hitze verbrennt er schnell! Der Rand sollte goldbraun sein.',
            'WÜRZEN: Direkt aus dem Ofen mit frisch gemahlenem Pfeffer würzen.',
            'SERVIEREN: Sofort servieren, solange er knusprig ist! Traditionell wird Flammkuchen mit den Händen gegessen - in Stücke gerissen. Dazu passt Elsässer Riesling oder Bier!'
        ]
    },
]

if __name__ == "__main__":
    conn = sqlite3.connect(DB_PATH)

    print(f"Adding {len(RECIPES)} German recipes (Part 3) to database...")

    for recipe in RECIPES:
        recipe_id = add_recipe(conn, recipe)
        print(f"  Added: {recipe['name']}")

    # Verify
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM recipes")
    total = cursor.fetchone()[0]

    print(f"\nSuccess! Database now has {total} recipes total")

    conn.close()
