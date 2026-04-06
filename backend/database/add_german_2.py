#!/usr/bin/env python3
"""
Add popular GERMAN recipes to SmartMeal database - Part 2
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

# GERMAN CLASSIC RECIPES - Part 2 (Recipes 4-9)
RECIPES = [
    {
        'name': 'Rinderrouladen mit Rotkohl und Klößen',
        'category': 'german',
        'description': 'Zarte Rinderrouladen gefüllt mit Speck, Zwiebeln und Gurke, geschmort in dunkler Sauce. Serviert mit Rotkohl und Klößen - ein festliches deutsches Traditionsessen!',
        'image_url': 'https://images.unsplash.com/photo-1603360946369-dc9bb6258143?w=800',
        'prep_time': 40,
        'cook_time': 120,
        'servings': 4,
        'difficulty': 'hard',
        'nutrition': {'calories': 680, 'protein': 52, 'carbs': 48, 'fat': 28, 'fiber': 7},
        'tags': ['dinner', 'family-friendly'],
        'ingredients': [
            {'name': 'Rinderrouladen', 'quantity': '8', 'unit': 'Stück', 'keywords': ['rind', 'beef', 'roulade'], 'priority': 3},
            {'name': 'Bacon-Scheiben', 'quantity': '8', 'unit': 'Stück', 'keywords': ['bacon', 'speck', 'schinken'], 'priority': 2},
            {'name': 'Zwiebeln', 'quantity': '2', 'unit': 'Stück', 'keywords': ['zwiebel', 'onion'], 'priority': 2},
            {'name': 'Gewürzgurken', 'quantity': '4', 'unit': 'Stück', 'keywords': ['gurke', 'pickle', 'gewürzgurke'], 'priority': 2},
            {'name': 'Senf mittelscharf', 'quantity': '4', 'unit': 'EL', 'keywords': ['senf', 'mustard'], 'priority': 1},
            {'name': 'Rotwein trocken', 'quantity': '250', 'unit': 'ml', 'keywords': ['rotwein', 'red wine'], 'priority': 2},
            {'name': 'Rotkohl', 'quantity': '700', 'unit': 'g', 'keywords': ['rotkohl', 'blaukraut'], 'priority': 2},
            {'name': 'Äpfel', 'quantity': '2', 'unit': 'Stück', 'keywords': ['apfel', 'apple'], 'priority': 1},
            {'name': 'Kartoffelklöße', 'quantity': '8', 'unit': 'Stück', 'keywords': ['kloß', 'knödel', 'kartoffel'], 'priority': 2},
            {'name': 'Tomatenmark', 'quantity': '2', 'unit': 'EL', 'keywords': ['tomatenmark', 'tomato paste'], 'priority': 1},
        ],
        'instructions': [
            'ROULADEN VORBEREITEN: Rinderrouladen flach auf Arbeitsfläche legen, trocken tupfen. Mit Salz und Pfeffer würzen, dann dünn mit Senf bestreichen. Das gibt den klassischen würzigen Geschmack!',
            'FÜLLUNG AUFLEGEN: Auf jede Roulade 1 Scheibe Bacon legen, dann Zwiebelringe darauf verteilen. Je eine halbe Gewürzgurke längs in die Mitte legen. Die Gurke muss längs sein, damit sie sich gut einrollen lässt!',
            'ROULADEN ROLLEN: Fleisch von der schmalen Seite fest aufrollen, dabei die Füllung gut einschließen. Mit Rouladennadeln oder Küchengarn fest verschließen. Wichtig: Straff rollen, sonst öffnen sie sich beim Braten!',
            'ROULADEN ANBRATEN: Öl in einem großen Schmortopf erhitzen. Rouladen rundherum kräftig anbraten bis sie schön braun sind - das dauert ca. 8-10 Minuten. Die Röststoffe geben später der Sauce Geschmack!',
            'GEMÜSE ANSCHWITZEN: Rouladen herausnehmen. Im gleichen Topf gewürfelte Zwiebeln, Karotten und Sellerie anschwitzen. Tomatenmark zugeben und kurz mitrösten. Das intensiviert den Geschmack!',
            'ABLÖSCHEN & SCHMOREN: Mit Rotwein ablöschen, Fond aufkochen und reduzieren. Rouladen zurück in den Topf geben, mit Rinderbrühe auffüllen bis sie zu 2/3 bedeckt sind. 2 Lorbeerblätter und 3 Wacholderbeeren zugeben. Zugedeckt bei schwacher Hitze 90-120 Minuten schmoren.',
            'ROTKOHL ZUBEREITEN: Rotkohl fein hobeln. In einem Topf mit Butter, Apfelstücken, 2 EL Zucker, 3 EL Essig, Salz, Nelken und Lorbeer 45 Minuten köcheln. Mit Apfelsaft angießen. Zwischendurch umrühren!',
            'KLÖSSE KOCHEN: Großen Topf mit Salzwasser zum Kochen bringen. Kartoffelklöße vorsichtig einlegen, Hitze reduzieren. In leicht siedendem Wasser 15-20 Minuten ziehen lassen - nicht sprudelnd kochen!',
            'SAUCE VERFEINERN: Rouladen aus dem Topf nehmen, warm stellen. Sauce durch ein Sieb passieren, aufkochen und auf gewünschte Konsistenz einreduzieren. Optional mit etwas Speisestärke binden. Mit Salz, Pfeffer, Zucker abschmecken.',
            'SERVIEREN: Rouladennadeln oder Garn entfernen. Rouladen halbieren oder ganz servieren, mit Sauce übergießen. Dazu Rotkohl und Klöße anrichten. Ein Festessen!'
        ]
    },
    {
        'name': 'Königsberger Klopse in Kapernsoße',
        'category': 'german',
        'description': 'Zarte Hackfleischklöße in cremiger weißer Kapernsoße - der ostpreußische Klassiker! Traditionell mit Salzkartoffeln und Rote Bete serviert.',
        'image_url': 'https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?w=800',
        'prep_time': 30,
        'cook_time': 40,
        'servings': 4,
        'difficulty': 'medium',
        'nutrition': {'calories': 520, 'protein': 38, 'carbs': 42, 'fat': 22, 'fiber': 4},
        'tags': ['dinner', 'family-friendly'],
        'ingredients': [
            {'name': 'Rinderhackfleisch', 'quantity': '400', 'unit': 'g', 'keywords': ['rind', 'hackfleisch', 'ground beef'], 'priority': 3},
            {'name': 'Schweinehackfleisch', 'quantity': '200', 'unit': 'g', 'keywords': ['schwein', 'hackfleisch', 'ground pork'], 'priority': 3},
            {'name': 'Altbackene Brötchen', 'quantity': '2', 'unit': 'Stück', 'keywords': ['brötchen', 'semmel', 'roll'], 'priority': 2},
            {'name': 'Zwiebeln', 'quantity': '2', 'unit': 'Stück', 'keywords': ['zwiebel', 'onion'], 'priority': 2},
            {'name': 'Kapern', 'quantity': '80', 'unit': 'g', 'keywords': ['kapern', 'capers'], 'priority': 2},
            {'name': 'Butter', 'quantity': '60', 'unit': 'g', 'keywords': ['butter'], 'priority': 1},
            {'name': 'Mehl', 'quantity': '40', 'unit': 'g', 'keywords': ['mehl', 'flour'], 'priority': 1},
            {'name': 'Sahne', 'quantity': '200', 'unit': 'ml', 'keywords': ['sahne', 'cream', 'schlagsahne'], 'priority': 2},
            {'name': 'Eier', 'quantity': '2', 'unit': 'Stück', 'keywords': ['ei', 'egg'], 'priority': 2},
            {'name': 'Zitrone', 'quantity': '1', 'unit': 'Stück', 'keywords': ['zitrone', 'lemon'], 'priority': 1},
            {'name': 'Kartoffeln', 'quantity': '800', 'unit': 'g', 'keywords': ['kartoffel', 'potato'], 'priority': 3},
        ],
        'instructions': [
            'BRÖTCHEN EINWEICHEN: Brötchen in kleine Stücke reißen, in 150ml lauwarmer Milch einweichen. 10 Minuten ziehen lassen bis sie weich sind. Dann gut ausdrücken.',
            'HACKFLEISCH MISCHEN: Beide Hackfleischsorten in eine Schüssel geben. 1 fein gewürfelte Zwiebel, ausgedrückte Brötchen, 1 Ei, Salz, Pfeffer, 1 Prise Muskatnuss zugeben. Mit den Händen 5 Minuten kräftig durchkneten - das macht die Klopse schön zart!',
            'KLOPSE FORMEN: Mit nassen Händen etwa 12 gleichgroße Klopse formen - ca. tennisballgroß. Die Masse sollte gut zusammenhalten. Tipp: Zwischendurch Hände immer wieder anfeuchten!',
            'SUD VORBEREITEN: 1,5 Liter Wasser in einem großen Topf erhitzen. 1 Zwiebel (halbiert), 1 Lorbeerblatt, 5 Pfefferkörner, 2 Nelken, Salz zugeben. Zum Kochen bringen, dann Hitze reduzieren.',
            'KLOPSE GAREN: Klopse vorsichtig in den leise siedenden Sud geben. Nicht kochen lassen - nur leicht simmern! 20 Minuten ziehen lassen. Klopse vorsichtig wenden nach 10 Minuten.',
            'KARTOFFELN KOCHEN: Kartoffeln schälen, vierteln, in Salzwasser 20 Minuten kochen bis sie gar sind. Abgießen und warm stellen.',
            'MEHLSCHWITZE: Butter in einem Topf zerlassen, Mehl einrühren. Unter ständigem Rühren 2-3 Minuten goldgelb anschwitzen - nicht braun werden lassen! Das ist die Basis der Sauce.',
            'SAUCE HERSTELLEN: 600ml vom Klopse-Sud durch ein Sieb zur Mehlschwitze gießen, dabei kräftig rühren damit keine Klumpen entstehen. Aufkochen, dann 5 Minuten bei mittlerer Hitze köcheln.',
            'SAUCE VERFEINERN: Sahne einrühren. Kapern mit etwas Sud zugeben. Mit Salz, Pfeffer, Zucker und Zitronensaft abschmecken. 1 Eigelb mit 2 EL Sauce verrühren, dann einrühren - macht die Sauce samtig! Nicht mehr kochen!',
            'SERVIEREN: Klopse in die Sauce geben, 2 Minuten ziehen lassen. Mit Salzkartoffeln anrichten. Traditionell mit Rote Bete servieren. Die Kapern geben den typischen Geschmack!'
        ]
    },
    {
        'name': 'Rheinischer Sauerbraten mit Apfelrotkohl',
        'category': 'german',
        'description': 'Butterzarter Rinderbraten nach rheinischer Art, 3 Tage mariniert in süß-saurer Beize mit Rosinen in der Sauce. Der Klassiker vom Niederrhein!',
        'image_url': 'https://images.unsplash.com/photo-1544025162-d76694265947?w=800',
        'prep_time': 40,
        'cook_time': 180,
        'servings': 6,
        'difficulty': 'hard',
        'nutrition': {'calories': 620, 'protein': 54, 'carbs': 38, 'fat': 26, 'fiber': 5},
        'tags': ['dinner', 'family-friendly'],
        'ingredients': [
            {'name': 'Rinder-Schulter', 'quantity': '1.5', 'unit': 'kg', 'keywords': ['rind', 'beef', 'schulter', 'braten'], 'priority': 3},
            {'name': 'Rotweinessig', 'quantity': '500', 'unit': 'ml', 'keywords': ['essig', 'vinegar', 'rotweinessig'], 'priority': 2},
            {'name': 'Rotwein trocken', 'quantity': '500', 'unit': 'ml', 'keywords': ['rotwein', 'red wine'], 'priority': 2},
            {'name': 'Zwiebeln', 'quantity': '3', 'unit': 'Stück', 'keywords': ['zwiebel', 'onion'], 'priority': 2},
            {'name': 'Karotten', 'quantity': '2', 'unit': 'Stück', 'keywords': ['karotte', 'möhre'], 'priority': 1},
            {'name': 'Rosinen', 'quantity': '100', 'unit': 'g', 'keywords': ['rosine', 'raisin'], 'priority': 1},
            {'name': 'Printen oder Lebkuchen', 'quantity': '80', 'unit': 'g', 'keywords': ['printen', 'lebkuchen', 'pfefferkuchen'], 'priority': 1},
            {'name': 'Rübenkraut', 'quantity': '3', 'unit': 'EL', 'keywords': ['rübenkraut', 'zuckerrübensirup'], 'priority': 1},
            {'name': 'Rotkohl', 'quantity': '800', 'unit': 'g', 'keywords': ['rotkohl', 'blaukraut'], 'priority': 2},
            {'name': 'Äpfel', 'quantity': '2', 'unit': 'Stück', 'keywords': ['apfel', 'apple'], 'priority': 1},
        ],
        'instructions': [
            'BEIZE ANSETZEN (3 Tage vorher): Rotwein, Essig, 500ml Wasser in einem Topf erhitzen. 2 Zwiebeln (gevierteilt), Karotten (grob geschnitten), 2 Lorbeerblätter, 8 Wacholderbeeren, 6 Pfefferkörner, 4 Nelken zugeben. Aufkochen, abkühlen lassen.',
            'FLEISCH EINLEGEN: Rinderbraten in einen großen Gefrierbeutel oder Behälter legen, kalte Beize darüber gießen bis das Fleisch komplett bedeckt ist. Verschließen, 3 Tage im Kühlschrank marinieren. Täglich wenden!',
            'FLEISCH VORBEREITEN: Braten aus der Beize nehmen, trocken tupfen. Beize durch ein Sieb abgießen und aufbewahren! Gemüse separat aufbewahren. Fleisch mit Salz und Pfeffer würzen.',
            'ANBRATEN: Öl in einem Bräter erhitzen, Fleisch von allen Seiten kräftig anbraten - ca. 10 Minuten. Das Beizen-Gemüse zugeben, mitbraten. Tomatenmark zugeben und kurz mitrösten.',
            'SCHMOREN: Mit 400ml Beize ablöschen, aufkochen. Zugedeckt bei 160°C im Ofen 2,5-3 Stunden schmoren. Alle 30 Minuten wenden und mit Beize begießen. Bei Bedarf etwas Beize nachgießen.',
            'ROTKOHL ZUBEREITEN: Rotkohl hobeln, in einem Topf mit Butter, Apfelstücken, 2 EL Zucker, 3 EL Essig, Salz anschwitzen. Mit 200ml Apfelsaft aufgießen, 45 Minuten köcheln lassen.',
            'SAUCE VORBEREITEN: Braten herausnehmen, warm stellen. Bratensauce durch ein feines Sieb in einen Topf gießen. Fett abschöpfen. Rosinen zugeben, 10 Minuten köcheln.',
            'SAUCE BINDEN: Printen oder Lebkuchen fein zerbröseln, zur Sauce geben und einrühren - das bindet und süßt! Rübenkraut einrühren. Mit Salz, Pfeffer, eventuell etwas Zucker abschmecken. Die Sauce sollte süß-sauer-würzig sein.',
            'BRATEN AUFSCHNEIDEN: Fleisch gegen die Faser in 1cm dicke Scheiben schneiden. Es sollte butterweich sein!',
            'SERVIEREN: Fleischscheiben auf vorgewärmten Tellern anrichten, mit Sauce übergießen. Dazu Rotkohl und traditionell Kartoffelklöße. Die rheinische Art ist die mit Rosinen und Printen!'
        ]
    },
    {
        'name': 'Kasseler mit Sauerkraut und Kartoffelpüree',
        'category': 'german',
        'description': 'Saftiges, geräuchertes Kasseler-Fleisch auf würzigem Sauerkraut mit cremigem Kartoffelpüree. Deftig, herzhaft und typisch deutsch!',
        'image_url': 'https://images.unsplash.com/photo-1598103442097-8b74394b95c6?w=800',
        'prep_time': 20,
        'cook_time': 60,
        'servings': 4,
        'difficulty': 'easy',
        'nutrition': {'calories': 580, 'protein': 42, 'carbs': 48, 'fat': 24, 'fiber': 6},
        'tags': ['dinner', 'family-friendly'],
        'ingredients': [
            {'name': 'Kasseler-Braten', 'quantity': '800', 'unit': 'g', 'keywords': ['kasseler', 'schwein', 'pork', 'geräuchert'], 'priority': 3},
            {'name': 'Sauerkraut', 'quantity': '1000', 'unit': 'g', 'keywords': ['sauerkraut', 'kraut'], 'priority': 2},
            {'name': 'Kartoffeln mehlig', 'quantity': '1.2', 'unit': 'kg', 'keywords': ['kartoffel', 'potato', 'mehlig'], 'priority': 3},
            {'name': 'Zwiebeln', 'quantity': '2', 'unit': 'Stück', 'keywords': ['zwiebel', 'onion'], 'priority': 2},
            {'name': 'Äpfel', 'quantity': '1', 'unit': 'Stück', 'keywords': ['apfel', 'apple'], 'priority': 1},
            {'name': 'Weißwein trocken', 'quantity': '200', 'unit': 'ml', 'keywords': ['weißwein', 'white wine'], 'priority': 2},
            {'name': 'Butter', 'quantity': '100', 'unit': 'g', 'keywords': ['butter'], 'priority': 1},
            {'name': 'Milch', 'quantity': '200', 'unit': 'ml', 'keywords': ['milch', 'milk'], 'priority': 2},
            {'name': 'Kümmel', 'quantity': '2', 'unit': 'TL', 'keywords': ['kümmel', 'caraway'], 'priority': 1},
        ],
        'instructions': [
            'KASSELER VORBEREITEN: Kasseler kalt abspülen, trocken tupfen. Falls die Schwarte noch dran ist, rautenförmig einschneiden. Das Fleisch ist bereits vorgekocht und geräuchert - es muss nur noch erwärmt werden!',
            'SAUERKRAUT ANSCHWITZEN: Zwiebel fein würfeln, in einem großen Topf mit etwas Öl glasig dünsten. Sauerkraut zugeben (nicht vorher waschen - dann wird es zu mild!), kurz mitbraten.',
            'SAUERKRAUT WÜRZEN: Apfel raspeln und zugeben. Mit Weißwein ablöschen. Kümmel, 1 Lorbeerblatt, 3 Wacholderbeeren, Salz, Pfeffer, 1 TL Zucker zugeben. Mit Wasser auffüllen bis Kraut bedeckt ist.',
            'KASSELER EINLEGEN: Kasseler auf das Sauerkraut legen. Zugedeckt bei mittlerer Hitze 50-60 Minuten schmoren. Das Fleisch saugt die Aromen auf und wird saftig!',
            'KARTOFFELN KOCHEN: Kartoffeln schälen, vierteln, in Salzwasser 20 Minuten kochen bis sie weich sind. Abgießen, kurz ausdampfen lassen.',
            'PÜREE STAMPFEN: Kartoffeln durch eine Kartoffelpresse drücken oder mit einem Stampfer zerdrücken. NICHT im Mixer - sonst wird es klebrig wie Leim!',
            'PÜREE VERFEINERN: Butter und heiße Milch unter das Püree rühren bis es cremig ist. Mit Salz, Pfeffer und Muskatnuss würzen. Optional: 2 EL Crème fraîche für extra Cremigkeit!',
            'KASSELER BRATEN (optional): Wer knusprige Kruste mag: Kasseler aus dem Topf nehmen, in einer Pfanne mit etwas Butter von der Schwartenseite 3-4 Minuten scharf anbraten.',
            'SAUERKRAUT ABSCHMECKEN: Mit Salz, Pfeffer, Zucker abschmecken. Es sollte würzig-säuerlich sein, nicht zu sauer! Optional mit etwas Sahne verfeinern.',
            'SERVIEREN: Kasseler in dicke Scheiben schneiden, auf einem Bett aus Sauerkraut anrichten. Püree daneben servieren. Ein deftiger Genuss!'
        ]
    },
    {
        'name': 'Ungarisches Gulasch mit Nockerln',
        'category': 'german',
        'description': 'Herzhaftes Rindergulasch mit Paprika, Zwiebeln und Tomaten - stundenlang geschmort bis es butterzart ist. Serviert mit fluffigen Nockerln!',
        'image_url': 'https://images.unsplash.com/photo-1610057099443-fde8c4d50f91?w=800',
        'prep_time': 30,
        'cook_time': 150,
        'servings': 6,
        'difficulty': 'medium',
        'nutrition': {'calories': 560, 'protein': 46, 'carbs': 42, 'fat': 22, 'fiber': 5},
        'tags': ['dinner', 'family-friendly'],
        'ingredients': [
            {'name': 'Rindergulasch', 'quantity': '1.2', 'unit': 'kg', 'keywords': ['rind', 'beef', 'gulasch'], 'priority': 3},
            {'name': 'Zwiebeln', 'quantity': '4', 'unit': 'Stück', 'keywords': ['zwiebel', 'onion'], 'priority': 2},
            {'name': 'Paprika rot', 'quantity': '3', 'unit': 'Stück', 'keywords': ['paprika', 'bell pepper'], 'priority': 2},
            {'name': 'Tomaten stückig', 'quantity': '400', 'unit': 'g', 'keywords': ['tomate', 'tomato', 'dose'], 'priority': 2},
            {'name': 'Paprikapulver edelsüß', 'quantity': '4', 'unit': 'EL', 'keywords': ['paprika', 'pulver', 'gewürz'], 'priority': 2},
            {'name': 'Tomatenmark', 'quantity': '3', 'unit': 'EL', 'keywords': ['tomatenmark', 'tomato paste'], 'priority': 1},
            {'name': 'Kümmel', 'quantity': '1', 'unit': 'TL', 'keywords': ['kümmel', 'caraway'], 'priority': 1},
            {'name': 'Mehl', 'quantity': '250', 'unit': 'g', 'keywords': ['mehl', 'flour'], 'priority': 1},
            {'name': 'Eier', 'quantity': '2', 'unit': 'Stück', 'keywords': ['ei', 'egg'], 'priority': 2},
        ],
        'instructions': [
            'FLEISCH VORBEREITEN: Gulaschfleisch in ca. 3x3cm große Würfel schneiden, trocken tupfen. Mit Salz und Pfeffer würzen. Zu kleine Stücke werden trocken, zu große brauchen ewig!',
            'ZWIEBELN ANSCHWITZEN: 4 große Zwiebeln fein würfeln. In einem schweren Topf oder Bräter mit 3 EL Öl bei mittlerer Hitze 15 Minuten glasig dünsten. Sie sollten goldgelb werden, nicht braun! Zwiebeln sind die Basis für echtes Gulasch.',
            'PAPRIKA ZUGEBEN: 1 Knoblauchzehe fein hacken, zu den Zwiebeln geben. 2 EL Paprikapulver einrühren - Vorsicht, nicht anbrennen lassen sonst wird es bitter! 30 Sekunden rösten.',
            'FLEISCH ANBRATEN: Hitze hochdrehen, Fleischwürfel portionsweise kräftig anbraten bis sie Farbe bekommen. Nicht zu viel auf einmal - sonst kocht es statt zu braten! Tomatenmark zugeben und mitrösten.',
            'ABLÖSCHEN: Mit 1 Glas Rotwein oder Rinderbrühe ablöschen, Fond vom Topfboden lösen. Gewürfelte Paprikaschoten, Tomaten aus der Dose, 1 TL Kümmel, 2 Lorbeerblätter, 1 Prise Zucker zugeben.',
            'SCHMOREN: Mit Rinderbrühe auffüllen bis Fleisch knapp bedeckt ist. Zugedeckt bei schwacher Hitze 2-2,5 Stunden schmoren. Gelegentlich umrühren, bei Bedarf Flüssigkeit nachgießen. Das Fleisch muss butterweich werden!',
            'NOCKERLN VORBEREITEN: 250g Mehl, 2 Eier, 1 Prise Salz, 100ml Wasser zu einem zähen Teig verrühren. Er sollte schwer vom Löffel fallen. 10 Minuten ruhen lassen.',
            'NOCKERLN KOCHEN: Großen Topf mit Salzwasser zum Kochen bringen. Mit 2 Teelöffeln kleine Nockerln abstechen und ins siedende Wasser gleiten lassen. 8-10 Minuten ziehen lassen bis sie an die Oberfläche steigen.',
            'GULASCH ABSCHMECKEN: Mit Salz, Pfeffer, Paprikapulver, eventuell etwas Zucker und Essig abschmecken. Die Sauce sollte sämig sein - optional mit etwas Mehlschwitze binden.',
            'SERVIEREN: Gulasch in tiefen Tellern anrichten, Nockerln dazu reichen. Mit frischer Petersilie bestreuen. Dazu passt Brot zum Tunken!'
        ]
    },
    {
        'name': 'Deftiger Linseneintopf mit Würstchen',
        'category': 'german',
        'description': 'Herzhafter Eintopf mit Linsen, Gemüse und Wiener Würstchen - wärmend, sättigend und voller Geschmack. Der perfekte Seelenwärmer!',
        'image_url': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=800',
        'prep_time': 20,
        'cook_time': 50,
        'servings': 6,
        'difficulty': 'easy',
        'nutrition': {'calories': 480, 'protein': 28, 'carbs': 52, 'fat': 18, 'fiber': 12},
        'tags': ['dinner', 'lunch', 'family-friendly'],
        'ingredients': [
            {'name': 'Tellerlinsen', 'quantity': '400', 'unit': 'g', 'keywords': ['linsen', 'lentils', 'teller'], 'priority': 3},
            {'name': 'Wiener Würstchen', 'quantity': '8', 'unit': 'Stück', 'keywords': ['wiener', 'würstchen', 'wurst'], 'priority': 3},
            {'name': 'Zwiebeln', 'quantity': '2', 'unit': 'Stück', 'keywords': ['zwiebel', 'onion'], 'priority': 2},
            {'name': 'Karotten', 'quantity': '3', 'unit': 'Stück', 'keywords': ['karotte', 'möhre'], 'priority': 2},
            {'name': 'Kartoffeln', 'quantity': '400', 'unit': 'g', 'keywords': ['kartoffel', 'potato'], 'priority': 2},
            {'name': 'Sellerie', 'quantity': '1', 'unit': 'Stück', 'keywords': ['sellerie', 'celery'], 'priority': 1},
            {'name': 'Speck durchwachsen', 'quantity': '150', 'unit': 'g', 'keywords': ['speck', 'bacon'], 'priority': 2},
            {'name': 'Lorbeerblätter', 'quantity': '2', 'unit': 'Stück', 'keywords': ['lorbeer', 'bay leaf'], 'priority': 1},
            {'name': 'Essig', 'quantity': '2', 'unit': 'EL', 'keywords': ['essig', 'vinegar'], 'priority': 1},
        ],
        'instructions': [
            'LINSEN VORBEREITEN: Linsen in ein Sieb geben, unter fließendem Wasser abspülen. Tellerlinsen müssen nicht eingeweicht werden - ein Vorteil!',
            'SPECK ANBRATEN: Speck in kleine Würfel schneiden, in einem großen Topf ohne Fett auslassen bis er knusprig ist. Die Fettaromen sind die Basis!',
            'ZWIEBELN ANSCHWITZEN: Zwiebeln fein würfeln, zum Speck geben. Bei mittlerer Hitze glasig dünsten. 2 Knoblauchzehen gehackt zugeben.',
            'GEMÜSE ZUGEBEN: Karotten, Sellerie und Kartoffeln schälen und in 1cm Würfel schneiden. Zum Topf geben, 5 Minuten mitdünsten.',
            'LINSEN GAREN: Linsen zugeben, mit 1,5 Liter Gemüsebrühe aufgießen. 2 Lorbeerblätter, 1 TL Majoran, 2 Nelken zugeben. Zum Kochen bringen, dann Hitze reduzieren. Zugedeckt 40 Minuten köcheln lassen.',
            'UMRÜHREN: Gelegentlich umrühren damit nichts ansetzt. Linsen sollten weich sein, aber noch Biss haben. Bei Bedarf etwas Wasser nachgießen.',
            'WÜRSTCHEN ERWÄRMEN: Würstchen in Scheiben schneiden. 10 Minuten vor Ende zum Eintopf geben und erwärmen. Nicht kochen - sonst platzen sie!',
            'ABSCHMECKEN: Mit Salz, Pfeffer, 2 EL Essig und 1 Prise Zucker abschmecken. Der Essig gibt die typische süß-saure Note! Optional mit Majoran nachwürzen.',
            'KONSISTENZ PRÜFEN: Der Eintopf sollte sämig sein - nicht zu dick, nicht zu dünn. Er wird beim Stehen noch etwas dicker. Eventuell etwas Brühe oder Wasser zugeben.',
            'SERVIEREN: In tiefen Tellern anrichten, mit frischer Petersilie bestreuen. Dazu schmeckt Brot oder Bauernbrot. Am nächsten Tag schmeckt er noch besser!'
        ]
    },
]

if __name__ == "__main__":
    conn = sqlite3.connect(DB_PATH)

    print(f"Adding {len(RECIPES)} German recipes (Part 2) to database...")

    for recipe in RECIPES:
        recipe_id = add_recipe(conn, recipe)
        print(f"  Added: {recipe['name']}")

    # Verify
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM recipes")
    total = cursor.fetchone()[0]

    print(f"\nSuccess! Database now has {total} recipes total")

    conn.close()
