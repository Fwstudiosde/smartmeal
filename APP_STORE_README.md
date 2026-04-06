# SparKoch - Apple App Store Upload Anleitung

## App-Informationen

**App Name:** SparKoch
**Bundle ID:** de.sparkoch.app
**Version:** 1.0.0
**Build Number:** 3
**Kategorie:** Food & Drink / Lifestyle
**Sprache:** Deutsch

## 1. Build erstellen

### iOS Build mit Flutter
```bash
cd /Users/finnweinnoldt/Downloads/smartmeal

# Release Build erstellen
flutter build ipa --release

# Das IPA wird hier erstellt:
# build/ios/ipa/smartmeal.ipa
```

## 2. Xcode vorbereiten

### Signing & Capabilities in Xcode konfigurieren

1. Öffne das Projekt in Xcode:
```bash
open ios/Runner.xcworkspace
```

2. Wähle das "Runner" Target
3. Gehe zu "Signing & Capabilities"
4. Stelle sicher, dass folgendes konfiguriert ist:
   - **Team:** Dein Apple Developer Team
   - **Bundle Identifier:** de.sparkoch.app
   - **Signing Certificate:** Apple Distribution
   - **Provisioning Profile:** App Store Distribution Profile

### Build Nummer erhöhen
Die aktuelle Build Number ist **3**. Für jeden neuen Upload musst du diese erhöhen:
- In `pubspec.yaml`: Ändere `version: 1.0.0+3` zu `version: 1.0.0+4` (oder höher)

## 3. App Store Connect vorbereiten

### In App Store Connect (appstoreconnect.apple.com):

1. **App erstellen:**
   - Gehe zu "Meine Apps"
   - Klicke auf "+ App"
   - Wähle iOS
   - App-Name: **SparKoch**
   - Primäre Sprache: **Deutsch**
   - Bundle ID: **de.sparkoch.app**
   - SKU: **sparkoch-ios-001**

2. **App-Informationen ausfüllen:**
   - Name: SparKoch
   - Untertitel: Smarte Rezepte & Angebote
   - Kategorie: Food & Drink
   - Altersfreigabe: 4+

## 4. Upload via Xcode

### Option A: Direkter Upload aus Xcode

1. Öffne das Projekt in Xcode:
```bash
open ios/Runner.xcworkspace
```

2. Wähle "Any iOS Device (arm64)" als Target
3. Product → Archive
4. Warte bis das Archiv erstellt wurde
5. Im Organizer: "Distribute App"
6. Wähle "App Store Connect"
7. Wähle "Upload"
8. Folge den Anweisungen

### Option B: Upload via Transporter App

1. Build erstellen:
```bash
flutter build ipa --release
```

2. Transporter App öffnen (aus dem Mac App Store)
3. IPA-Datei hineinziehen: `build/ios/ipa/smartmeal.ipa`
4. "Deliver" klicken

## 5. Screenshots & Assets benötigt

### iPhone Screenshots (erforderlich)
- 6.7" Display (iPhone 15 Pro Max): 1290 x 2796 px
- 6.5" Display (iPhone 11 Pro Max): 1242 x 2688 px

Erstelle mindestens 3-5 Screenshots von:
1. Home Screen mit Rezeptvorschlägen
2. Kühlschrank-Scanner in Aktion
3. Rezept-Details Ansicht
4. Angebote-Finder
5. Benutzerprofil

### App Icon
- Bereits konfiguriert in `assets/SparKoch_Appicon2.0.png`
- Größe: 1024 x 1024 px
- Kein Alpha-Kanal (transparent)

### Optional: iPad Screenshots
- 12.9" iPad Pro (3. Gen): 2048 x 2732 px

## 6. App-Beschreibungen für App Store

### Deutscher Beschreibungstext (siehe APP_STORE_TEXTS.md)

Die Texte findest du in der separaten Datei `APP_STORE_TEXTS.md`

## 7. Privacy & Berechtigungen

Die App verwendet folgende Berechtigungen (bereits in Info.plist konfiguriert):

- **Kamera:** Zum Scannen von Lebensmitteln und Angeboten
- **Fotomediathek:** Zum Auswählen von Fotos

### Privacy Policy
Du benötigst eine Datenschutzerklärung. Diese sollte folgende Punkte abdecken:
- Datenerhebung (E-Mail, Benutzerdaten)
- Kamera-Nutzung
- OpenAI API Nutzung
- Supabase Backend
- Keine Weitergabe an Dritte (außer OpenAI für Bildanalyse)

Beispiel-URL für Privacy Policy: `https://sparkoch.de/privacy`

## 8. Checkliste vor dem Upload

- [ ] Build Number erhöht
- [ ] Signing Certificates konfiguriert
- [ ] App in App Store Connect erstellt
- [ ] Screenshots vorbereitet (min. 3-5)
- [ ] App Icon korrekt (1024x1024, kein Alpha)
- [ ] Beschreibungstexte vorbereitet
- [ ] Privacy Policy URL bereit
- [ ] Support URL bereit
- [ ] Marketing URL (optional)
- [ ] Testflight Beta-Tester (optional, empfohlen)

## 9. Nach dem Upload

1. Warte 5-15 Minuten bis der Build in App Store Connect erscheint
2. Gehe zu "App Store" Tab in App Store Connect
3. Füge den Build zur Version hinzu
4. Fülle alle erforderlichen Felder aus
5. Klicke "Zur Überprüfung einreichen"

### Review-Prozess
- Durchschnittliche Review-Zeit: 1-3 Tage
- Apple testet alle Funktionen der App
- Bei Ablehnung: Behebe die Probleme und reiche erneut ein

## 10. Häufige Probleme

### Build wird nicht akzeptiert
- Stelle sicher, dass die Build Number höher ist als alle vorherigen
- Prüfe ob Signing Certificate gültig ist

### App wird abgelehnt
Häufige Gründe:
- Fehlende Privacy Policy
- Funktionen funktionieren nicht wie beschrieben
- Fehlende Berechtigungs-Begründungen
- Login-Probleme (stelle Test-Account bereit)

### Fehlende Screenshots
- Mindestens 3 Screenshots für 6.7" und 6.5" Displays erforderlich
- Nutze den iOS Simulator für Screenshots

## Nützliche Commands

```bash
# Build für App Store
flutter build ipa --release

# Build mit bestimmter Version
flutter build ipa --release --build-number=4

# Archive in Xcode öffnen
open ~/Library/Developer/Xcode/Archives

# Provisioning Profiles aktualisieren
cd ios && pod install && cd ..

# Xcode Cache löschen
rm -rf ~/Library/Developer/Xcode/DerivedData/*
flutter clean
flutter pub get
```

## Support & Hilfe

- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [App Store Connect Hilfe](https://developer.apple.com/app-store-connect/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
