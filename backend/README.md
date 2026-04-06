# SmartMeal Backend - Web Scraper

Dieses Backend scraped wöchentliche Angebote von deutschen Supermärkten.

## ⚠️ Rechtlicher Hinweis

**WICHTIG:** Web Scraping kann gegen die AGB der Websites verstoßen. Dieses Tool ist nur für:
- Bildungszwecke
- Private, nicht-kommerzielle Nutzung
- Prototyping und Entwicklung

Für kommerzielle Nutzung solltest du offizielle APIs oder Partnerschaften mit den Supermärkten nutzen.

## Installation

```bash
# Virtuelle Umgebung erstellen
python -m venv venv

# Aktivieren (macOS/Linux)
source venv/bin/activate

# Aktivieren (Windows)
venv\Scripts\activate

# Dependencies installieren
pip install -r requirements.txt

# Playwright Browser installieren
playwright install chromium
```

## Starten

```bash
# API Server starten
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

API ist dann verfügbar unter: `http://localhost:8000`
API Docs: `http://localhost:8000/docs`

## API Endpoints

- `GET /` - Health check
- `GET /api/deals` - Alle Angebote abrufen
- `GET /api/deals/{store}` - Angebote für einen bestimmten Supermarkt
- `GET /api/stores` - Liste der verfügbaren Supermärkte
- `POST /api/scrape` - Scraping manuell starten
- `GET /api/scrape/status` - Scraping Status

## Unterstützte Supermärkte

- Lidl (lidl.de)
- ALDI Süd (aldi-sued.de)
- REWE (rewe.de)
- EDEKA (edeka.de)
- Kaufland (kaufland.de)
- Penny (penny.de)

## Konfiguration

Erstelle eine `.env` Datei:

```
API_PORT=8000
SCRAPING_INTERVAL=86400  # 24 Stunden in Sekunden
CACHE_TTL=3600          # 1 Stunde
DEBUG=True
```

## Flutter Integration

```dart
// In Flutter app
final response = await dio.get('http://localhost:8000/api/deals');
final deals = (response.data as List).map((d) => Deal.fromJson(d)).toList();
```
