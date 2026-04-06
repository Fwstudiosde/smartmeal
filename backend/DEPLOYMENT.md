# Backend Deployment mit Supabase

## Warum nur Supabase?

Supabase ist eine All-in-One-Lösung für deine App:
- ✅ PostgreSQL Datenbank (statt SQLite)
- ✅ User Authentication (Sign in with Apple, Email/Password)
- ✅ Storage für Bilder/PDFs
- ✅ REST API automatisch generiert
- ✅ Realtime Updates
- ✅ Komplett kostenlos bis 500MB + 50k Users
- ✅ Sehr gute Flutter Integration

## Schnellstart (10 Minuten Setup)

### 1. Supabase Account erstellen

1. Gehe zu [supabase.com](https://supabase.com)
2. Klicke **"Start your project"**
3. Melde dich mit GitHub an (kostenlos)

### 2. Neues Projekt erstellen

1. Klicke **"New Project"**
2. **Organization**: Erstelle eine neue (z.B. "SparKoch")
3. **Project Name**: `sparkoch` oder `smartmeal`
4. **Database Password**: Klicke "Generate a password" und **SPEICHERE ES SICHER!**
5. **Region**: Europe West (Frankfurt) - am nächsten zu Deutschland
6. **Pricing Plan**: Free
7. Klicke **"Create new project"**

⏳ Projekt wird erstellt (dauert 2-3 Minuten)

### 3. Datenbank einrichten

Sobald das Projekt bereit ist:

1. Gehe zu **SQL Editor** (linke Sidebar)
2. Klicke **"New query"**
3. Kopiere und führe folgendes SQL aus:

```sql
-- Recipes Tabelle
CREATE TABLE recipes (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  prep_time INTEGER,
  cook_time INTEGER,
  servings INTEGER,
  difficulty TEXT,
  category TEXT,
  calories INTEGER,
  protein REAL,
  carbs REAL,
  fat REAL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Recipe Ingredients
CREATE TABLE recipe_ingredients (
  id SERIAL PRIMARY KEY,
  recipe_id TEXT REFERENCES recipes(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  quantity TEXT NOT NULL,
  unit TEXT NOT NULL
);

-- Recipe Instructions
CREATE TABLE recipe_instructions (
  id SERIAL PRIMARY KEY,
  recipe_id TEXT REFERENCES recipes(id) ON DELETE CASCADE,
  step_number INTEGER NOT NULL,
  instruction TEXT NOT NULL
);

-- Recipe Tags
CREATE TABLE recipe_tags (
  id SERIAL PRIMARY KEY,
  recipe_id TEXT REFERENCES recipes(id) ON DELETE CASCADE,
  tag TEXT NOT NULL
);

-- Deals Tabelle (ersetzt JSON File)
CREATE TABLE deals (
  id SERIAL PRIMARY KEY,
  product_name TEXT NOT NULL,
  store_name TEXT NOT NULL,
  original_price REAL,
  discount_price REAL NOT NULL,
  discount_percentage REAL,
  category TEXT,
  image_url TEXT,
  valid_from DATE,
  valid_until DATE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_instructions ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE deals ENABLE ROW LEVEL SECURITY;

-- Public Read Access (alle können lesen)
CREATE POLICY "Anyone can read recipes" ON recipes FOR SELECT USING (true);
CREATE POLICY "Anyone can read ingredients" ON recipe_ingredients FOR SELECT USING (true);
CREATE POLICY "Anyone can read instructions" ON recipe_instructions FOR SELECT USING (true);
CREATE POLICY "Anyone can read tags" ON recipe_tags FOR SELECT USING (true);
CREATE POLICY "Anyone can read deals" ON deals FOR SELECT USING (true);

-- Admin kann alles (später konfigurieren)
CREATE POLICY "Admins can do everything with deals" ON deals
  USING (auth.uid() IS NOT NULL);
```

4. Klicke **"Run"** (Strg/Cmd + Enter)
5. Du solltest sehen: "Success. No rows returned"

### 4. Authentication einrichten

1. Gehe zu **Authentication** → **Providers**
2. **Email** ist bereits aktiviert ✓
3. Für **Apple Sign-In**:
   - Klicke auf "Apple"
   - Aktiviere "Apple enabled"
   - Folge den Anweisungen (braucht Apple Developer Account)
   - Oder: Lass es erstmal deaktiviert

### 5. API Keys kopieren

Das ist WICHTIG! Du brauchst diese für die Flutter App:

1. Gehe zu **Settings** → **API**
2. Kopiere folgende Werte:

```
Project URL: https://xxxxxxxxxxxxx.supabase.co
anon public key: eyJhbGc...  (sehr langer String)
service_role key: eyJhbGc... (für Backend, GEHEIM!)
```

**Speichere diese sicher!**

---

## Flutter App mit Supabase verbinden

### 1. Supabase Package hinzufügen

Öffne `pubspec.yaml` und füge hinzu:

```yaml
dependencies:
  supabase_flutter: ^2.5.0
```

Dann:
```bash
cd /Users/finnweinnoldt/Downloads/smartmeal
flutter pub get
```

### 2. Supabase initialisieren

Die App muss beim Start Supabase initialisieren. Gib mir deine:
- **Project URL**
- **anon public key**

Dann kann ich die Flutter App entsprechend anpassen.

**Wichtig:** Das Python Backend brauchst du NICHT mehr zu deployen! Supabase ersetzt das komplette Backend:
- ✅ Datenbank → Supabase PostgreSQL
- ✅ User Auth → Supabase Auth
- ✅ API → Supabase REST API
- ✅ Storage → Supabase Storage

---

## Was ist mit dem Python Backend?

Das Python Backend kannst du **OPTIONAL** noch für spezielle Features nutzen:
- Web Scraping (Lidl, Kaufland)
- OCR für Prospekte
- AI-Features mit OpenAI

**Aber für TestFlight brauchst du es NICHT!** Die App funktioniert auch ohne:
- Rezepte kommen aus Supabase
- User Auth durch Supabase
- Deals können manuell über Supabase Dashboard eingegeben werden

---

## Testen

1. Gehe zu **Database** → **Table Editor**
2. Wähle die `recipes` Tabelle
3. Klicke **"Insert"** → **"Insert row"**
4. Füge ein Test-Rezept hinzu

Die Flutter App kann es dann sofort abrufen!

---

## Kosten

**Supabase Free Tier:**
- 500 MB Datenbank
- 1 GB File Storage
- 50,000 monatliche Active Users
- 2 GB Bandwidth
- Unbegrenzte API Requests

**Für deine App: Komplett kostenlos!**

---

## Nächste Schritte

✅ Supabase Projekt erstellt
✅ Datenbank Schema angelegt
✅ API Keys kopiert
⬜ Gib mir deine Supabase URL + API Key
⬜ Ich passe die Flutter App an
⬜ IPA rebuilden
⬜ TestFlight Upload

---

## Troubleshooting

### ❌ SQL Query schlägt fehl

**Lösung:**
- Stelle sicher, du bist im richtigen Projekt
- Führe die Queries einzeln aus (eine Tabelle nach der anderen)

### ❌ Row Level Security

Wenn du Daten nicht lesen kannst:
1. Gehe zu **Authentication** → **Policies**
2. Stelle sicher, die Policies sind aktiviert
3. Oder: Deaktiviere RLS temporär zum Testen (nicht empfohlen für Production)

### ❌ Flutter kann nicht auf Supabase zugreifen

- Prüfe ob `supabase_flutter` installiert ist
- Stelle sicher, die API Keys sind korrekt
- Project URL muss mit `https://` beginnen

Bei Fragen einfach melden!
