#!/usr/bin/env python3
"""
Initialize SmartMeal Recipe Database
Creates database structure and populates with world-class recipes
"""

import sqlite3
import os
import json
from pathlib import Path

DB_PATH = Path(__file__).parent / "recipes.db"
SCHEMA_PATH = Path(__file__).parent / "schema.sql"

def init_database():
    """Initialize database with schema"""
    print("🔨 Initializing database...")

    # Remove old database if exists
    if DB_PATH.exists():
        DB_PATH.unlink()
        print("  ✓ Removed old database")

    # Create new database
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    # Execute schema
    with open(SCHEMA_PATH, 'r', encoding='utf-8') as f:
        schema_sql = f.read()
        cursor.executescript(schema_sql)

    conn.commit()
    print(f"  ✓ Database created at {DB_PATH}")

    return conn

def get_category_id(cursor, name):
    """Get category ID by name"""
    cursor.execute("SELECT id FROM categories WHERE name = ?", (name,))
    result = cursor.fetchone()
    return result[0] if result else None

def get_tag_id(cursor, name):
    """Get tag ID by name"""
    cursor.execute("SELECT id FROM tags WHERE name = ?", (name,))
    result = cursor.fetchone()
    return result[0] if result else None

if __name__ == "__main__":
    conn = init_database()

    # Verify categories and tags were created
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM categories")
    cat_count = cursor.fetchone()[0]
    cursor.execute("SELECT COUNT(*) FROM tags")
    tag_count = cursor.fetchone()[0]

    print(f"\n✅ Database initialized successfully!")
    print(f"  - {cat_count} categories")
    print(f"  - {tag_count} tags")
    print(f"\nReady to generate recipes!")

    conn.close()
