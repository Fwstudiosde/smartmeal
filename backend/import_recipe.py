#!/usr/bin/env python3
"""
Chefkoch Recipe Importer
========================
Einfaches Tool zum Importieren von Chefkoch.de Rezepten

Usage:
    python import_recipe.py
"""

import json
import os
from pathlib import Path
from datetime import datetime
from chefkoch_scraper import ChefkochScraper
from supabase_client import supabase_db


def save_recipe_to_json(recipe_data, output_dir='imported_recipes'):
    """Save recipe to JSON file"""
    # Create output directory if it doesn't exist
    Path(output_dir).mkdir(exist_ok=True)

    # Generate filename from recipe name
    filename = recipe_data['name'].lower()
    filename = filename.replace(' ', '_').replace('-', '_')
    filename = ''.join(c for c in filename if c.isalnum() or c == '_')
    filename = f"{filename}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"

    filepath = Path(output_dir) / filename

    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(recipe_data, f, indent=2, ensure_ascii=False)

    return filepath


def save_to_supabase(recipe_data):
    """Save recipe to Supabase database"""
    try:
        # Prepare recipe data for database
        recipe_db_data = {
            'name': recipe_data['name'],
            'description': recipe_data['description'],
            'image_url': recipe_data['image_url'],
            'prep_time': recipe_data['prep_time'],
            'cook_time': recipe_data['cook_time'],
            'servings': recipe_data['servings'],
            'difficulty': recipe_data['difficulty'],
            'category_id': None,  # Can be set manually later
        }

        # Add nutrition data if available
        if recipe_data.get('nutrition'):
            nutrition = recipe_data['nutrition']
            recipe_db_data.update({
                'calories': nutrition.get('calories'),
                'protein': nutrition.get('protein'),
                'carbs': nutrition.get('carbs'),
                'fat': nutrition.get('fat'),
                'fiber': nutrition.get('fiber'),
            })

        # Create recipe in database
        print("   📤 Speichere in Supabase...")
        created_recipe = supabase_db.create_recipe(recipe_db_data)

        if not created_recipe:
            raise Exception("Failed to create recipe in database")

        recipe_id = created_recipe['id']
        print(f"   ✅ Rezept gespeichert (ID: {recipe_id})")

        # Add ingredients
        for i, ingredient in enumerate(recipe_data['ingredients']):
            ingredient_db_data = {
                'recipe_id': recipe_id,
                'ingredient_name': ingredient['name'],
                'quantity': ingredient['quantity'],
                'unit': ingredient['unit'],
                'is_optional': False,
                'ingredient_order': i + 1,
            }
            supabase_db.create_recipe_ingredient(ingredient_db_data)

        print(f"   ✅ {len(recipe_data['ingredients'])} Zutaten gespeichert")

        # Add instructions
        for i, instruction in enumerate(recipe_data['instructions']):
            instruction_db_data = {
                'recipe_id': recipe_id,
                'step_number': i + 1,
                'instruction': instruction,
            }
            supabase_db.create_recipe_instruction(instruction_db_data)

        print(f"   ✅ {len(recipe_data['instructions'])} Schritte gespeichert")

        return True, recipe_id

    except Exception as e:
        print(f"   ⚠️  Fehler beim Speichern in Supabase: {e}")
        return False, None


def print_recipe_summary(recipe_data):
    """Print a nice summary of the scraped recipe"""
    print("\n" + "=" * 70)
    print(f"📖 {recipe_data['name']}")
    print("=" * 70)
    print(f"\n📝 Beschreibung: {recipe_data['description'][:100]}...")
    print(f"\n⏱️  Zeiten:")
    print(f"   • Vorbereitung: {recipe_data['prep_time']} Min")
    print(f"   • Kochen: {recipe_data['cook_time']} Min")
    print(f"   • Portionen: {recipe_data['servings']}")
    print(f"   • Schwierigkeit: {recipe_data['difficulty']}")

    print(f"\n🥗 Zutaten ({len(recipe_data['ingredients'])}):")
    for ing in recipe_data['ingredients'][:5]:
        print(f"   • {ing['quantity']} {ing['unit']} {ing['name']}")
    if len(recipe_data['ingredients']) > 5:
        print(f"   ... und {len(recipe_data['ingredients']) - 5} weitere")

    print(f"\n📋 Zubereitung ({len(recipe_data['instructions'])} Schritte)")
    for i, step in enumerate(recipe_data['instructions'][:2], 1):
        print(f"   {i}. {step[:80]}...")
    if len(recipe_data['instructions']) > 2:
        print(f"   ... und {len(recipe_data['instructions']) - 2} weitere Schritte")

    if recipe_data.get('nutrition'):
        nut = recipe_data['nutrition']
        print(f"\n💪 Nährwerte:")
        if nut.get('calories'):
            print(f"   • Kalorien: {nut['calories']} kcal")
        if nut.get('protein'):
            print(f"   • Protein: {nut['protein']}g")
        if nut.get('carbs'):
            print(f"   • Kohlenhydrate: {nut['carbs']}g")
        if nut.get('fat'):
            print(f"   • Fett: {nut['fat']}g")

    print("\n" + "=" * 70)


def main():
    """Main function"""
    print("╔═══════════════════════════════════════════════════════════════╗")
    print("║         🍳 Chefkoch.de Rezept Importer 🍳                    ║")
    print("╚═══════════════════════════════════════════════════════════════╝")
    print()

    scraper = ChefkochScraper()

    while True:
        print("\n" + "-" * 70)
        url = input("\n📎 Chefkoch.de URL eingeben (oder 'q' zum Beenden): ").strip()

        if url.lower() in ['q', 'quit', 'exit']:
            print("\n👋 Auf Wiedersehen!")
            break

        if not url or 'chefkoch.de' not in url.lower():
            print("❌ Ungültige URL! Bitte gib eine Chefkoch.de URL ein.")
            continue

        try:
            # Scrape recipe
            print("\n🔍 Scraping Rezept...")
            recipe_data = scraper.scrape_recipe(url)

            # Show summary
            print_recipe_summary(recipe_data)

            # Save to JSON
            print("\n💾 Speichere Rezept...")
            json_path = save_recipe_to_json(recipe_data)
            print(f"   ✅ JSON gespeichert: {json_path}")

            # Try to save to Supabase
            print("\n🌐 Versuche in Supabase zu speichern...")
            success, recipe_id = save_to_supabase(recipe_data)

            if success:
                print(f"\n🎉 Rezept erfolgreich importiert!")
                print(f"   📁 JSON: {json_path}")
                print(f"   🔗 Supabase ID: {recipe_id}")
            else:
                print(f"\n✅ Rezept in JSON gespeichert: {json_path}")
                print("   ℹ️  Supabase-Speicherung fehlgeschlagen (keine Verbindung?)")
                print("   💡 Du kannst das JSON später mit sync_to_supabase.py hochladen")

        except KeyboardInterrupt:
            print("\n\n⚠️  Abgebrochen durch Benutzer")
            break
        except Exception as e:
            print(f"\n❌ Fehler: {e}")
            import traceback
            traceback.print_exc()
            print("\n💡 Tipp: Stelle sicher, dass die URL korrekt ist und die Seite erreichbar ist.")


if __name__ == '__main__':
    main()
