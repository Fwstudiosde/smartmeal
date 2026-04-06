#!/bin/bash

# SparKoch - App Store Build Script
# Dieses Script erstellt einen Release Build für den Apple App Store

set -e  # Exit on error

echo "========================================="
echo "SparKoch - App Store Build"
echo "========================================="
echo ""

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funktion für Success Messages
success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Funktion für Error Messages
error() {
    echo -e "${RED}✗${NC} $1"
}

# Funktion für Info Messages
info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# 1. Prüfe ob Flutter installiert ist
info "Prüfe Flutter Installation..."
if ! command -v flutter &> /dev/null; then
    error "Flutter ist nicht installiert oder nicht im PATH"
    exit 1
fi
success "Flutter gefunden: $(flutter --version | head -n 1)"
echo ""

# 2. Prüfe aktuelle Version
info "Lese aktuelle Version aus pubspec.yaml..."
VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')
if [ -z "$VERSION" ]; then
    error "Konnte Version nicht aus pubspec.yaml lesen"
    exit 1
fi
success "Aktuelle Version: $VERSION"
echo ""

# 3. Frage ob Version erhöht werden soll
echo "Möchtest du die Build-Nummer erhöhen?"
echo "Aktuelle Version: $VERSION"
read -p "Neue Build-Nummer eingeben (oder Enter für aktuell): " NEW_BUILD

if [ ! -z "$NEW_BUILD" ]; then
    BASE_VERSION=$(echo $VERSION | cut -d'+' -f1)
    NEW_VERSION="${BASE_VERSION}+${NEW_BUILD}"

    # Update pubspec.yaml
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/^version:.*/version: $NEW_VERSION/" pubspec.yaml
    else
        # Linux
        sed -i "s/^version:.*/version: $NEW_VERSION/" pubspec.yaml
    fi

    success "Version aktualisiert: $VERSION → $NEW_VERSION"
    VERSION=$NEW_VERSION
fi
echo ""

# 4. Flutter Clean
info "Führe Flutter Clean aus..."
flutter clean
success "Clean abgeschlossen"
echo ""

# 5. Get Dependencies
info "Hole Flutter Dependencies..."
flutter pub get
success "Dependencies geholt"
echo ""

# 6. Code Generation (falls riverpod_generator verwendet wird)
if grep -q "riverpod_generator" pubspec.yaml; then
    info "Führe Code Generation aus..."
    flutter pub run build_runner build --delete-conflicting-outputs
    success "Code Generation abgeschlossen"
    echo ""
fi

# 7. iOS Pods installieren
info "Installiere iOS CocoaPods..."
cd ios
pod install
cd ..
success "Pods installiert"
echo ""

# 8. Prüfe Xcode Signing
info "Prüfe Xcode Signing Konfiguration..."
echo ""
echo "WICHTIG: Stelle sicher, dass in Xcode konfiguriert ist:"
echo "  - Team: Dein Apple Developer Team"
echo "  - Bundle Identifier: de.sparkoch.app"
echo "  - Signing: Automatic oder Manual mit korrektem Provisioning Profile"
echo ""
read -p "Ist Xcode Signing korrekt konfiguriert? (y/n): " SIGNING_OK

if [ "$SIGNING_OK" != "y" ]; then
    error "Bitte konfiguriere Signing in Xcode:"
    echo "  1. open ios/Runner.xcworkspace"
    echo "  2. Wähle 'Runner' Target"
    echo "  3. Gehe zu 'Signing & Capabilities'"
    echo "  4. Wähle dein Team und stelle Signing ein"
    exit 1
fi
echo ""

# 9. Build IPA
info "Erstelle Release IPA für App Store..."
echo ""
flutter build ipa --release

if [ $? -eq 0 ]; then
    success "Build erfolgreich erstellt!"
    echo ""
    echo "========================================="
    echo "BUILD ERFOLGREICH!"
    echo "========================================="
    echo ""
    echo "IPA Datei: build/ios/ipa/smartmeal.ipa"
    echo "Version: $VERSION"
    echo ""
    echo "NÄCHSTE SCHRITTE:"
    echo "1. Öffne Transporter App oder Xcode"
    echo "2. Upload die IPA zu App Store Connect"
    echo "3. Warte bis Build in App Store Connect erscheint (5-15 Min)"
    echo "4. Füge Build zur App-Version hinzu"
    echo "5. Reiche App zur Review ein"
    echo ""
    echo "Weitere Infos in APP_STORE_README.md"
    echo ""

    # Option: IPA direkt in Downloads kopieren
    read -p "IPA in Downloads kopieren? (y/n): " COPY_IPA
    if [ "$COPY_IPA" == "y" ]; then
        cp build/ios/ipa/smartmeal.ipa ~/Downloads/SparKoch_v${VERSION}.ipa
        success "IPA kopiert nach: ~/Downloads/SparKoch_v${VERSION}.ipa"
    fi

    # Option: Xcode Organizer öffnen
    read -p "Xcode Organizer öffnen? (y/n): " OPEN_XCODE
    if [ "$OPEN_XCODE" == "y" ]; then
        open ~/Library/Developer/Xcode/Archives
    fi

else
    error "Build fehlgeschlagen!"
    echo ""
    echo "Mögliche Lösungen:"
    echo "1. Prüfe Signing in Xcode: open ios/Runner.xcworkspace"
    echo "2. Lösche Pods: cd ios && rm -rf Pods Podfile.lock && pod install"
    echo "3. Lösche Flutter Cache: flutter clean && flutter pub get"
    exit 1
fi
