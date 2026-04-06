#!/usr/bin/env python3
"""
Quick test to verify recipes can be fetched from Supabase
"""
from supabase_client import supabase_db

print("🔍 Teste Rezept-Anzeige aus Supabase...\n")

# Get all recipes
try:
    recipes = supabase_db.get_all_recipes(limit=5)

    print(f"✅ {len(recipes)} Rezepte gefunden (zeige erste 5):\n")

    for i, recipe in enumerate(recipes, 1):
        print(f"{i}. {recipe['name']}")
        print(f"   ID: {recipe['id']}")
        print(f"   Bild: {recipe.get('image_url', 'Kein Bild')[:60]}...")
        print(f"   Portionen: {recipe['servings']}, Schwierigkeit: {recipe['difficulty']}")

        # Get ingredients
        ingredients = supabase_db.get_recipe_ingredients(recipe['id'])
        print(f"   Zutaten: {len(ingredients)}")

        # Get instructions
        instructions = supabase_db.get_recipe_instructions(recipe['id'])
        print(f"   Schritte: {len(instructions)}")
        print()

    # Specifically check for our Römerpfanne recipe
    print("\n🔍 Suche speziell nach 'Römerpfanne'...")
    all_recipes = supabase_db.get_all_recipes()
    roemerpfanne = [r for r in all_recipes if 'römerpfanne' in r['name'].lower()]

    if roemerpfanne:
        print(f"✅ Römerpfanne gefunden!")
        recipe = roemerpfanne[0]
        print(f"   Name: {recipe['name']}")
        print(f"   ID: {recipe['id']}")

        ingredients = supabase_db.get_recipe_ingredients(recipe['id'])
        instructions = supabase_db.get_recipe_instructions(recipe['id'])

        print(f"   {len(ingredients)} Zutaten")
        print(f"   {len(instructions)} Zubereitungsschritte")

        print("\n📝 Zubereitungsschritte:")
        for step in instructions:
            print(f"   {step['step_number']}. {step['instruction'][:80]}...")
    else:
        print("❌ Römerpfanne nicht gefunden!")

except Exception as e:
    print(f"❌ Fehler: {e}")
    import traceback
    traceback.print_exc()
