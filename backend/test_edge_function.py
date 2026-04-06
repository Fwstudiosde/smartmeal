#!/usr/bin/env python3
"""
Test Supabase Edge Function
"""
import requests
import os
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
# Use anon key from Flutter app (from supabase_config.dart)
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1lZGVkc2R2em5idHVucnh5cW5uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjcwMTU4MjYsImV4cCI6MjA4MjU5MTgyNn0.QOS6NJLZOke7HdOIidH3vCZGDNOVa8OdgTrWEk9gjs8"

print("🔍 Teste Supabase Edge Function...\n")
print(f"URL: {SUPABASE_URL}/functions/v1/recipes-with-deals")

try:
    response = requests.get(
        f"{SUPABASE_URL}/functions/v1/recipes-with-deals",
        params={"min_coverage": 0.5, "limit": 50},
        headers={"Authorization": f"Bearer {SUPABASE_ANON_KEY}"},
        timeout=30
    )

    print(f"\nStatus Code: {response.status_code}")

    if response.status_code == 200:
        data = response.json()
        recipes = data.get('recipes', [])
        print(f"✅ Edge Function funktioniert!")
        print(f"   {len(recipes)} Rezepte mit Deals gefunden\n")

        if recipes:
            print("Erste 3 Rezepte:")
            for i, recipe in enumerate(recipes[:3], 1):
                print(f"{i}. {recipe['name']}")
                print(f"   Matched Deals: {len(recipe.get('matched_deals', []))}")
                coverage = recipe.get('score_breakdown', {}).get('coverage_percentage', 0)
                print(f"   Coverage: {coverage:.1f}%")
                print()
        else:
            print("❌ Keine Rezepte mit Deals gefunden!")
            print("Das ist der Grund, warum die App leer ist.")
    else:
        print(f"❌ Fehler: HTTP {response.status_code}")
        print(f"Response: {response.text}")

except Exception as e:
    print(f"❌ Fehler beim Aufrufen der Edge Function: {e}")
    import traceback
    traceback.print_exc()
