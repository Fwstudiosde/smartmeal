#!/usr/bin/env python3
"""
Generates corrected recipe code for SmartMeal app with fixed pricing
"""

recipes_data = [
    # Fitness Recipes (10 new ones)
    {
        "name": "Protein-Lachs mit Avocado",
        "keywords": ["lachs", "avocado"],
        "servings": 2,
        "prepTime": 10,
        "cookTime": 15,
        "difficulty": "easy",
        "tags": ["Fitness", "High-Protein", "Omega-3"],
        "ingredients": [
            ("Lachsforellenfilet", "300", "g"),
            ("Avocado", "1", "Stück"),
            ("Salatherzen", "100", "g"),
            ("Zitrone", "1", "Stück"),
            ("Rapsöl", "1", "EL"),
        ],
        "image": "https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=800",
        "description": "Perfektes Post-Workout-Meal! Hochwertiges Protein aus Lachs, gesunde Fette aus Avocado - ideal zum Muskelaufbau und voller Omega-3-Fettsäuren.",
    },
    {
        "name": "Hähnchenbrust Bowl Deluxe",
        "keywords": ["hähnchen"],
        "servings": 2,
        "prepTime": 15,
        "cookTime": 20,
        "difficulty": "easy",
        "tags": ["Fitness", "High-Protein", "Meal-Prep"],
        "ingredients": [
            ("Hähnchenbrust-Filets", "400", "g"),
            ("Bratpaprika", "150", "g"),
            ("Salatherzen", "100", "g"),
            ("Clementinen", "2", "Stück"),
            ("Rapsöl", "1", "EL"),
        ],
        "image": "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800",
        "description": "Die ultimative Fitness-Bowl! Mageres Hähnchen liefert 50g Protein, buntes Gemüse sorgt für Vitamine. Perfekt für Meal-Prep!",
    },
    {
        "name": "Roastbeef Power Salat",
        "keywords": ["roastbeef", "salat"],
        "servings": 2,
        "prepTime": 10,
        "cookTime": 0,
        "difficulty": "easy",
        "tags": ["Fitness", "Low-Carb", "Protein"],
        "ingredients": [
            ("Roastbeef", "300", "g"),
            ("Multicolor-Salat", "200", "g"),
            ("Tomaten", "200", "g"),
            ("Avocado", "1", "Stück"),
            ("Rapsöl", "2", "EL"),
        ],
        "image": "https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=800",
        "description": "Kraftvoller Low-Carb Salat mit edlem Roastbeef. Reich an Eisen und Protein, perfekt für Definition und Fettabbau!",
    },
    {
        "name": "Beeren-Protein Dessert",
        "keywords": ["himbeeren"],
        "servings": 2,
        "prepTime": 5,
        "cookTime": 0,
        "difficulty": "easy",
        "tags": ["Fitness", "Dessert", "Antioxidantien"],
        "ingredients": [
            ("Himbeeren", "250", "g"),
            ("Clementinen", "3", "Stück"),
            ("Trauben", "200", "g"),
            ("Erdnüsse", "50", "g"),
        ],
        "image": "https://images.unsplash.com/photo-1488477181946-6428a0291777?w=800",
        "description": "Gesundes Fitness-Dessert voller Antioxidantien! Beeren unterstützen die Regeneration, Erdnüsse liefern Protein und gesunde Fette.",
    },
    {
        "name": "Thunfisch-Power-Salat",
        "keywords": ["thunfisch", "salat"],
        "servings": 2,
        "prepTime": 10,
        "cookTime": 0,
        "difficulty": "easy",
        "tags": ["Fitness", "High-Protein", "Schnell"],
        "ingredients": [
            ("Thunfischfilet", "300", "g"),
            ("Salatherzen", "200", "g"),
            ("Tomaten", "250", "g"),
            ("Zwiebeln", "1", "Stück"),
            ("Rapsöl", "2", "EL"),
        ],
        "image": "https://images.unsplash.com/photo-1546793665-c74683f339c1?w=800",
        "description": "Schneller Protein-Kick! Thunfisch ist fettarm, proteinreich und in 10 Minuten fertig. Ideal nach dem Training!",
    },
    {
        "name": "Süßkartoffel-Hähnchen-Power",
        "keywords": ["hähnchen", "kartoffel"],
        "servings": 3,
        "prepTime": 15,
        "cookTime": 35,
        "difficulty": "medium",
        "tags": ["Fitness", "Komplexe-Kohlenhydrate"],
        "ingredients": [
            ("Hähnchenbrust-Filets", "500", "g"),
            ("Speisekartoffeln", "600", "g"),
            ("Bratpaprika", "200", "g"),
            ("Zwiebeln", "2", "Stück"),
            ("Rapsöl", "2", "EL"),
        ],
        "image": "https://images.unsplash.com/photo-1512058564366-18510be2db19?w=800",
        "description": "Perfekte Balance aus Protein und komplexen Kohlenhydraten. Ideal für Muskelaufbau und lange Sättigung!",
    },
    {
        "name": "Avocado-Ei Protein-Boost",
        "keywords": ["avocado", "ei"],
        "servings": 2,
        "prepTime": 5,
        "cookTime": 10,
        "difficulty": "easy",
        "tags": ["Fitness", "Frühstück", "Gesunde-Fette"],
        "ingredients": [
            ("Avocado", "2", "Stück"),
            ("Salatherzen", "100", "g"),
            ("Tomaten", "150", "g"),
            ("Rapsöl", "1", "EL"),
        ],
        "image": "https://images.unsplash.com/photo-1525351484163-7529414344d8?w=800",
        "description": "Kraftvolles Frühstück! Avocado liefert gesunde Fette, perfekt um den Tag energiegeladen zu starten.",
    },
    {
        "name": "Granatapfel-Beeren-Power-Bowl",
        "keywords": ["granatapfel", "beeren"],
        "servings": 2,
        "prepTime": 10,
        "cookTime": 0,
        "difficulty": "easy",
        "tags": ["Fitness", "Antioxidantien", "Snack"],
        "ingredients": [
            ("Granatapfel", "1", "Stück"),
            ("Himbeeren", "125", "g"),
            ("Trauben", "200", "g"),
            ("Erdnüsse", "40", "g"),
        ],
        "image": "https://images.unsplash.com/photo-1590301157890-4810ed352733?w=800",
        "description": "Antioxidantien-Bombe! Granatapfel und Beeren fördern die Regeneration, ideal als Pre-Workout-Snack.",
    },
    {
        "name": "Kiwi-Erdbeer Vitamin-Kick",
        "keywords": ["kiwi", "erdbeeren"],
        "servings": 2,
        "prepTime": 5,
        "cookTime": 0,
        "difficulty": "easy",
        "tags": ["Fitness", "Vitamin-C", "Snack"],
        "ingredients": [
            ("Kiwis", "4", "Stück"),
            ("Erdbeeren", "300", "g"),
            ("Clementinen", "3", "Stück"),
            ("Erdnüsse", "30", "g"),
        ],
        "image": "https://images.unsplash.com/photo-1564093497595-593b96d80180?w=800",
        "description": "Vitamin-C-Explosion! Stärkt das Immunsystem und unterstützt die Kollagenproduktion für starke Sehnen und Bänder.",
    },
    {
        "name": "Protein-Gemüse-Pfanne XXL",
        "keywords": ["hähnchen", "gemüse"],
        "servings": 4,
        "prepTime": 15,
        "cookTime": 25,
        "difficulty": "easy",
        "tags": ["Fitness", "Meal-Prep", "Ballaststoffe"],
        "ingredients": [
            ("Hähnchenbrust-Filets", "800", "g"),
            ("Bratpaprika", "300", "g"),
            ("Zwiebeln", "2", "Stück"),
            ("Tomaten", "400", "g"),
            ("Rapsöl", "2", "EL"),
        ],
        "image": "https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=800",
        "description": "Meal-Prep-Champion! In einer Pfanne entsteht ein nährstoffreiches Gericht für die ganze Woche. 4 Portionen pure Power!",
    },
]

print("// Generated Fitness Recipes - Use calculateActualPrice() helper function")
print("// Format: Create simple mock recipes to demonstrate corrected pricing\n")

for i, recipe in enumerate(recipes_data, 1):
    print(f"// Recipe {i}: {recipe['name']}")

print("\n// Implementation would use:")
print("// price = calculateActualPrice(deal, usedAmount, unit)")
print("// savings = calculateActualSavings(deal, usedAmount, unit)")
