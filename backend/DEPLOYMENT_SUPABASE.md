# Backend Deployment mit Supabase + Railway

## Option 1: Supabase + Railway (Empfohlen)

Diese Lösung kombiniert das Beste aus beiden Welten:
- **Supabase**: PostgreSQL Datenbank + User Authentication (kostenlos)
- **Railway**: Python Backend für Scraper + API (kostenlos)

### Schritt 1: Supabase Setup

#### 1.1 Account erstellen
1. Gehe zu [supabase.com](https://supabase.com)
2. Klicke "Start your project"
3. Melde dich mit GitHub an (kostenlos)

#### 1.2 Neues Projekt erstellen
1. "New Project"
2. Projektname: `smartmeal` oder `sparkoch`
3. Database Password: Generiere ein sicheres Passwort (speichere es!)
4. Region: Frankfurt (näher zu Deutschland)
5. Pricing Plan: Free
6. "Create new project" (dauert 2-3 Minuten)

#### 1.3 Datenbank Schema erstellen

Gehe zu SQL Editor und führe folgende Queries aus:

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

-- Enable Row Level Security (RLS)
ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_instructions ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_tags ENABLE ROW LEVEL SECURITY;

-- Policies (alle können lesen)
CREATE POLICY "Anyone can read recipes" ON recipes FOR SELECT USING (true);
CREATE POLICY "Anyone can read ingredients" ON recipe_ingredients FOR SELECT USING (true);
CREATE POLICY "Anyone can read instructions" ON recipe_instructions FOR SELECT USING (true);
CREATE POLICY "Anyone can read tags" ON recipe_tags FOR SELECT USING (true);
```

#### 1.4 Authentication einrichten

1. Gehe zu Authentication → Providers
2. Email Provider ist bereits aktiviert
3. Für Apple Sign-In:
   - Aktiviere "Apple" Provider
   - Folge den Anweisungen für Apple Developer Setup

#### 1.5 API Keys kopieren

1. Gehe zu Settings → API
2. Kopiere:
   - `Project URL` (z.B. https://xxxxx.supabase.co)
   - `anon public` API Key
   - `service_role secret` Key (für Backend)

### Schritt 2: Railway Setup (für Python Backend)

#### 2.1 Account erstellen
1. Gehe zu [railway.app](https://railway.app)
2. Melde dich mit GitHub an

#### 2.2 Projekt deployen
1. "New Project"
2. "Deploy from GitHub repo"
3. Wähle `smartmeal` Repository
4. Root Directory: `backend`

#### 2.3 Environment Variables setzen

In Railway → Variables:

```
PORT=8000
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_KEY=dein-service-role-key
SECRET_KEY=ein-sicherer-random-string
OPENAI_API_KEY=optional-dein-openai-key
```

#### 2.4 Railway URL kopieren

Nach dem Deployment erhältst du eine URL wie:
```
https://your-app.up.railway.app
```

Kopiere diese URL - du brauchst sie für die Flutter App!

---

## Option 2: Nur Railway (Einfacher, aber weniger Features)

Falls du Supabase nicht nutzen möchtest, kannst du auch nur Railway verwenden:

1. Folge den Anweisungen in `DEPLOYMENT.md`
2. Deine SQLite Datenbanken werden automatisch mitdeployt
3. User Auth funktioniert wie gewohnt mit JWT

**Nachteile:**
- SQLite ist nicht optimal für Production (Concurrency-Probleme)
- Keine automatischen Backups
- Keine Realtime-Features

---

## Schritt 3: Flutter App konfigurieren

### 3.1 Supabase Package hinzufügen

Füge in `pubspec.yaml` hinzu:

```yaml
dependencies:
  supabase_flutter: ^2.5.0
```

### 3.2 API URLs konfigurieren

Erstelle eine Config-Datei oder nutze Environment Variables für:

**Wenn Supabase + Railway:**
- Supabase URL: `https://xxxxx.supabase.co` (für Auth + Rezepte)
- Railway URL: `https://your-app.up.railway.app` (für Deals + Scraper)

**Wenn nur Railway:**
- Backend URL: `https://your-app.up.railway.app`

Die API-Client-Dateien müssen aktualisiert werden:
- `lib/core/services/api/deals_api_client.dart`
- `lib/core/services/api/admin_api_client.dart`
- `lib/core/services/recipe_api_client.dart`
- `lib/core/services/api/scraper_api_client.dart`

---

## Kosten

### Supabase Free Tier:
- 500 MB Datenbank
- 1 GB File Storage
- 50,000 monatliche Active Users
- Unbegrenzte API Requests

### Railway Free Tier:
- $5 Guthaben/Monat (ca. 500 Stunden)
- Automatischer Sleep nach Inaktivität

**Zusammen: Komplett kostenlos für kleine bis mittlere Apps!**

---

## Vorteile Supabase

✅ PostgreSQL statt SQLite (besser für Production)
✅ Automatische Backups
✅ Eingebaute User Authentication
✅ Realtime Subscriptions (Live-Updates)
✅ File Storage für Bilder
✅ Sehr gute Flutter-Integration
✅ Dashboard für Datenverwaltung
✅ Automatische API-Generierung

---

## Nächste Schritte

1. Entscheide dich: Supabase + Railway ODER nur Railway
2. Erstelle die Accounts und deploye
3. Kopiere die URLs
4. Teile mir die URLs mit, damit ich die Flutter App konfiguriere
5. Rebuild IPA
6. Upload zu TestFlight

Bei Fragen einfach melden!
