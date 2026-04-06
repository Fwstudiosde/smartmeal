# 🔐 Admin Panel - Prospekt Upload System

Du hast jetzt ein **Admin-Panel** mit dem du Prospekte (PDFs oder Screenshots) hochladen kannst. Diese werden automatisch ausgewertet und die Angebote werden für alle App-Nutzer sichtbar gemacht!

---

## ✅ Was wurde implementiert?

### Backend Features:
- ✅ **Admin-Authentifizierung** - Sicherer Login mit JWT Tokens
- ✅ **File Upload** - PDF & Bild-Upload (PNG, JPG, etc.)
- ✅ **OCR Text-Extraktion** - Automatisches Auslesen von Text aus Prospekten
- ✅ **Deal-Extraktion** - Intelligente Erkennung von:
  - Produktnamen
  - Preisen (original & Rabatt)
  - Rabattprozenten
  - Gültigkeitszeiträumen
  - Kategorien
- ✅ **Deal-Management** - Erstellen, Bearbeiten, Löschen von Angeboten
- ✅ **Öffentliche API** - Alle User sehen die hochgeladenen Deals

---

## 🚀 Admin-Login

### 1. Login Credentials (änderbar in `.env`)

```
Username: admin
Password: admin123
```

### 2. Login Request

```bash
curl -X POST http://localhost:8000/api/admin/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "admin123"
  }'
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

Speichere den `access_token` - den brauchst du für alle Admin-Aktionen!

---

## 📤 Prospekt Hochladen

### Upload PDF oder Bild

```bash
curl -X POST http://localhost:8000/api/admin/upload \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -F "file=@prospekt.pdf" \
  -F "store_name=Kaufland"
```

**Unterstützte Formate:**
- PDF (`.pdf`)
- Bilder (`.jpg`, `.jpeg`, `.png`, `.bmp`)

**Response:**
```json
{
  "status": "success",
  "message": "Extracted 12 deals from prospekt.pdf",
  "deals_count": 12,
  "deals": [
    {
      "product_name": "HÄHNCHENBRUST",
      "store_name": "Kaufland",
      "original_price": 8.99,
      "discount_price": 5.99,
      "discount_percentage": 33,
      "valid_from": "2025-12-23T00:00:00",
      "valid_until": "2025-12-30T23:59:59",
      "category": "Fleisch & Wurst"
    }
  ]
}
```

Die Deals sind **sofort für alle App-User sichtbar**!

---

## 📋 Admin API Endpoints

### 1. Alle Deals anzeigen (Admin)

```bash
curl http://localhost:8000/api/admin/deals \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 2. Deal bearbeiten

```bash
curl -X PUT http://localhost:8000/api/admin/deals/0 \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "product_name": "Korrigierter Name",
    "store_name": "Kaufland",
    "original_price": 9.99,
    "discount_price": 6.99,
    "discount_percentage": 30,
    "valid_from": "2025-12-23T00:00:00",
    "valid_until": "2025-12-30T23:59:59",
    "category": "Fleisch & Wurst"
  }'
```

### 3. Deal löschen

```bash
curl -X DELETE http://localhost:8000/api/admin/deals/0 \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 4. Deal manuell erstellen

```bash
curl -X POST http://localhost:8000/api/admin/deals \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "product_name": "Bananen",
    "store_name": "ALDI",
    "original_price": 1.99,
    "discount_price": 0.99,
    "discount_percentage": 50,
    "valid_from": "2025-12-23T00:00:00",
    "valid_until": "2025-12-26T23:59:59",
    "category": "Obst & Gemüse",
    "image_url": ""
  }'
```

### 5. Alle Deals löschen (Vorsicht!)

```bash
curl -X DELETE http://localhost:8000/api/admin/deals \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

## 🎯 Wie funktioniert die OCR-Extraktion?

### 1. **Text-Erkennung (OCR)**
- Verwendet **Tesseract OCR** mit deutscher Sprache
- Konvertiert PDFs zu Bildern
- Liest Text aus Prospekt-Screenshots

### 2. **Deal-Extraktion (Pattern Matching)**
Der Extractor sucht nach:

**Produktnamen:**
- Großgeschriebene Wörter
- Fettgedruckte Überschriften

**Preisen:**
- `4,99€`
- `4.99 EUR`
- `€ 4,99`

**Rabatten:**
- `-30%`
- `30% SPAREN`
- `30 PROZENT`

**Zeiträumen:**
- "gültig vom 23.12. bis 30.12."
- "23.12.2025 - 30.12.2025"

**Kategorien:**
- Automatische Zuordnung anhand Produktname

### 3. **Verbesserungsmöglichkeiten**

Für noch bessere Ergebnisse:

#### Option A: KI-Extraktion mit OpenAI
```python
# In .env:
OPENAI_API_KEY=sk-your-key

# Wird automatisch genutzt wenn verfügbar
```

#### Option B: Prospekt-Screenshots verbessern
- Gute Beleuchtung
- Hohe Auflösung
- Kontrastreiche Farben

---

## 📱 Flutter Admin Screen

Die Flutter-App braucht noch einen Admin-Screen. Hier die nächsten Schritte:

### Features die noch gebaut werden müssen:

1. **Login Screen**
   - Username/Password Eingabe
   - Token speichern (Secure Storage)

2. **Upload Screen**
   - File Picker für PDF/Bilder
   - Store-Name Auswahl
   - Upload Progress
   - Ergebnis-Anzeige

3. **Deal-Management**
   - Liste aller Deals
   - Bearbeiten-Dialog
   - Löschen-Funktion
   - Neue Deals manuell hinzufügen

Soll ich das Flutter Admin-Panel jetzt bauen?

---

## 🔧 Setup

### 1. Tesseract OCR installieren

**macOS:**
```bash
brew install tesseract
brew install tesseract-lang  # Für Deutsch
```

**Ubuntu/Debian:**
```bash
sudo apt-get install tesseract-ocr
sudo apt-get install tesseract-ocr-deu
```

**Windows:**
Download von: https://github.com/UB-Mannheim/tesseract/wiki

### 2. Poppler für PDF-Konvertierung

**macOS:**
```bash
brew install poppler
```

**Ubuntu/Debian:**
```bash
sudo apt-get install poppler-utils
```

### 3. Admin Credentials ändern

In `backend/.env`:
```env
ADMIN_USERNAME=mein-admin
ADMIN_PASSWORD=sicheres-passwort-123
SECRET_KEY=neuer-secret-key  # generiere mit: openssl rand -hex 32
```

---

## 📊 Test-Upload

Probier's aus mit einem Screenshot:

```bash
# 1. Login
TOKEN=$(curl -s -X POST http://localhost:8000/api/admin/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "admin123"}' \
  | jq -r '.access_token')

# 2. Upload (ersetze prospekt.jpg mit deinem File)
curl -X POST http://localhost:8000/api/admin/upload \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@prospekt.jpg" \
  -F "store_name=Kaufland"

# 3. Deals prüfen
curl http://localhost:8000/api/deals
```

---

## 🎉 Vorteile dieses Systems

✅ **Kein Web Scraping nötig** - Keine Bot-Detection, keine Rate Limits
✅ **100% Kontrolle** - Du entscheidest welche Deals gezeigt werden
✅ **Qualität** - Du kannst Deals vor Veröffentlichung prüfen/editieren
✅ **Flexibel** - Funktioniert mit jedem Supermarkt
✅ **Offline-fähig** - PDF-Upload funktioniert immer

**Nächster Schritt:** Flutter Admin UI bauen? 🚀
