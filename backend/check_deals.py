#!/usr/bin/env python3
"""
Check deals in database
"""
from supabase_client import supabase_db

print("🔍 Prüfe Deals in der Datenbank...\n")

try:
    deals = supabase_db.get_all_deals()
    print(f"✅ {len(deals)} Deals gefunden\n")

    if deals:
        print("Erste 5 Deals:")
        for i, deal in enumerate(deals[:5], 1):
            print(f"{i}. {deal['product_name']} - {deal['store_name']}")
            print(f"   Preis: {deal.get('discount_price', 0)}€ (war {deal.get('original_price', 0)}€)")
            print()
    else:
        print("❌ Keine Deals in der Datenbank!")
        print("\nDie App zeigt nur Rezepte an, für die es passende Angebote gibt.")
        print("Deswegen wird dein Römerpfanne-Rezept nicht angezeigt.\n")

except Exception as e:
    print(f"❌ Fehler: {e}")
    import traceback
    traceback.print_exc()
