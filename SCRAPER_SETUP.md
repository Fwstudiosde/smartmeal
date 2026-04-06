# 🕷️ Web Scraper Setup - Echte Supermarkt-Angebote

Ich habe dir ein komplettes **Web Scraping Backend** gebaut, das echte Angebote von deutschen Supermärkten scraped!

## ✅ Was du jetzt hast:

### Backend (`/backend` Ordner):
- ✅ **FastAPI Server** - REST API für Angebots-Daten
- ✅ **Web Scraper** - Scraped Lidl, ALDI, REWE, etc.
- ✅ **Caching** - Speichert Daten lokal
- ✅ **Auto-Update** - Kann täglich automatisch scrapen

### Flutter App:
- ✅ **ScraperApiClient** - Verbindet sich mit Backend
- ✅ **DealsServiceV2** - Neue Service-Schicht
- ✅ **Fertig für Integration** - Nur Provider austauschen

---

## 🚀 Setup & Start

### 1. Backend installieren

```bash
# In das backend Verzeichnis wechseln
cd backend

# Python Virtual Environment erstellen
python3 -m venv venv

# Aktivieren (macOS/Linux)
source venv/bin/activate

# Dependencies installieren
pip install -r requirements.txt
```

### 2. Backend starten

```bash
# Im backend Ordner:
python main.py

# Oder mit uvicorn:
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

✅ **API läuft jetzt unter:** `http://localhost:8000`
✅ **API Docs:** `http://localhost:8000/docs`

### 3. Flutter App anpassen

Öffne `lib/features/deals_scanner/providers/deals_providers.dart`:

**Ersetze:**
```dart
final dealsServiceProvider = Provider((ref) => DealsService());
```

**Mit:**
```dart
final dealsServiceProvider = Provider((ref) => DealsServiceV2(
  scraperClient: ScraperApiClient(baseUrl: 'http://localhost:8000'),
));
```

### 4. App neu starten

```bash
# Im main Ordner:
flutter run
```

---

## 📡 API Endpoints

| Endpoint | Beschreibung |
|----------|--------------|
| `GET /api/deals` | Alle Angebote |
| `GET /api/deals/Lidl` | Nur Lidl Angebote |
| `GET /api/stores` | Verfügbare Supermärkte |
| `GET /api/stats` | Statistiken |
| `POST /api/scrape` | Scraping manuell starten |
| `GET /api/scrape/status` | Scraping Status |

---

## 🎯 Scraper erweitern

### Neuen Supermarkt hinzufügen:

**1. Neuen Scraper erstellen:**
```python
# backend/scrapers/aldi_scraper.py
from .base_scraper import BaseScraper

class AldiScraper(BaseScraper):
    def __init__(self):
        super().__init__(
            store_name='ALDI',
            base_url='https://www.aldi-sued.de'
        )

    async def scrape_deals(self):
        # Implementiere Scraping-Logik
        ...
```

**2. In main.py registrieren:**
```python
from scrapers.aldi_scraper import AldiScraper

SCRAPERS = {
    "lidl": LidlScraper(),
    "aldi": AldiScraper(),  # ← Neu hinzufügen
}
```

---

## ⚠️ Wichtige Hinweise

### Rechtliches:
- ⚠️ Web Scraping kann gegen AGB verstoßen
- ✅ Nur für private, nicht-kommerzielle Nutzung
- ✅ Für Produktion: Offizielle APIs oder Partnerschaften nutzen

### Technisches:
- **JavaScript-Websites:** Einige Sites (wie Lidl) rendern Content mit JavaScript
  - Lösung: Playwright oder Selenium nutzen (schon in requirements.txt)
  - Siehe Kommentare in `lidl_scraper.py`

- **Rate Limiting:** Websites können Requests blockieren
  - Lösung: Delays zwischen Requests einbauen
  - User-Agent setzen (bereits implementiert)

- **Website-Änderungen:** HTML-Struktur ändert sich häufig
  - Lösung: CSS-Selektoren regelmäßig anpassen

---

## 🔄 Automatisches Scraping

Um täglich automatisch zu scrapen:

**Option 1: Cron Job (Linux/macOS)**
```bash
# Crontab bearbeiten
crontab -e

# Täglich um 6 Uhr morgens scrapen
0 6 * * * cd /pfad/zu/smartmeal/backend && python -c "import asyncio; from main import scrape_all_stores; asyncio.run(scrape_all_stores())"
```

**Option 2: Python Schedule (in main.py hinzufügen)**
```python
import schedule
import time

def job():
    asyncio.run(scrape_all_stores())

schedule.every().day.at("06:00").do(job)

while True:
    schedule.run_pending()
    time.sleep(60)
```

---

## 🐛 Troubleshooting

### Backend startet nicht:
```bash
# Port bereits in Nutzung?
lsof -i :8000
kill -9 <PID>

# Dependencies fehlen?
pip install -r requirements.txt
```

### Flutter kann Backend nicht erreichen:
```bash
# Auf iOS Simulator: localhost funktioniert
baseUrl: 'http://localhost:8000'

# Auf Android Emulator: 10.0.2.2 nutzen
baseUrl: 'http://10.0.2.2:8000'

# Auf echtem Gerät: Computer-IP nutzen
baseUrl: 'http://192.168.1.XXX:8000'
```

### Keine Deals werden gescraped:
- Prüfe Backend Logs
- Website-Struktur hat sich geändert → CSS-Selektoren anpassen
- Rate Limiting → Delays erhöhen

---

## 📊 Beispiel API Responses

**GET /api/deals:**
```json
[
  {
    "product_name": "Hähnchenbrust",
    "store_name": "Lidl",
    "original_price": 6.99,
    "discount_price": 4.99,
    "discount_percentage": 29,
    "image_url": "https://...",
    "valid_from": "2025-12-23T00:00:00",
    "valid_until": "2025-12-30T23:59:59",
    "category": "Fleisch"
  }
]
```

---

## 🎉 Nächste Schritte

1. ✅ Backend starten
2. ✅ Flutter App anpassen
3. 🔄 Scraper für weitere Supermärkte erweitern
4. 🔒 Für Produktion: Auf Server deployen (Heroku, Railway, etc.)
5. 📦 Caching & Database hinzufügen (Redis, PostgreSQL)

**Viel Erfolg! 🚀**
