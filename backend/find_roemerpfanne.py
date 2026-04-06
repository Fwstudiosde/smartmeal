#!/usr/bin/env python3
"""
Check if Römerpfanne is in recipes with deals
"""
import requests
import os
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1lZGVkc2R2em5idHVucnh5cW5uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjcwMTU4MjYsImV4cCI6MjA4MjU5MTgyNn0.QOS6NJLZOke7HdOIidH3vCZGDNOVa8OdgTrWEk9gjs8"

print("🔍 Suche Römerpfanne in Rezepten mit Deals...\n")

try:
    response = requests.get(
        f"{SUPABASE_URL}/functions/v1/recipes-with-deals",
        params={"min_coverage": 0.1, "limit": 100},  # Lower threshold, more recipes
        headers={"Authorization": f"Bearer {SUPABASE_ANON_KEY}"},
        timeout=30
    )

    if response.status_code == 200:
        data = response.json()
        recipes = data.get('recipes', [])

        print(f"Total Rezepte mit Deals: {len(recipes)}")

        # Check if Römerpfanne is in the list
        roemerpfanne = [r for r in recipes if 'römerpfanne' in r['name'].lower()]

        if roemerpfanne:
            print(f"✅ Römerpfanne gefunden!")
            recipe = roemerpfanne[0]
            print(f"   Name: {recipe['name']}")
            print(f"   Matched Deals: {len(recipe.get('matched_deals', []))}")
            coverage = recipe.get('score_breakdown', {}).get('coverage_percentage', 0)
            print(f"   Coverage: {coverage:.1f}%")

            print("\n   Matched Ingredients:")
            for deal in recipe.get('matched_deals', [])[:5]:
                print(f"   - {deal['ingredient_name']}: {deal['deal']['product_name']}")
        else:
            print("❌ Römerpfanne NICHT in den Rezepten mit Deals!")
            print("\nDas bedeutet: Keine der Zutaten hat passende Angebote.")
            print("\nZutaten der Römerpfanne:")
            print("- Hackfleisch")
            print("- Zucchini")
            print("- Kidneybohnen")
            print("- Salatgurke")
            print("- Mais")
            print("- Rucola")
            print("- Macadamiaöl")
            print("- Salz und Pfeffer")
            print("- Currypulver")
            print("- Petersilie")

            print("\nAlle verfügbaren Rezepte:")
            for i, recipe in enumerate(recipes[:10], 1):
                print(f"{i}. {recipe['name']} ({len(recipe.get('matched_deals', []))} deals)")

    else:
        print(f"❌ Fehler: HTTP {response.status_code}")

except Exception as e:
    print(f"❌ Fehler: {e}")
    import traceback
    traceback.print_exc()
