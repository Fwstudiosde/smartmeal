# SmartMeal Edge Functions Deployment Guide

## Was wurde erstellt?

Ich habe die gesamte Backend-Logik nach TypeScript Edge Functions portiert. Die Funktionen sind bereit für das Deployment auf Supabase.

### Erstelle Dateien:

1. **`supabase/functions/recipes-with-deals/index.ts`**
   - Hauptfunktion für Recipe Matching
   - Portierte Python-Logik nach TypeScript
   - Enthält die komplette Recipe-Matching-Algorithmus

2. **`supabase/functions/get-categories/index.ts`**
   - Funktion um alle Kategorien abzurufen

3. **`supabase/config.toml`**
   - Supabase-Projektkonfiguration

## Deployment-Anleitung

### Option 1: Manual Deployment über Supabase Dashboard

Da das CLI-Deployment eine Personal Access Token benötigt, ist es einfacher, die Funktionen über das Supabase Dashboard zu deployen:

1. Gehe zu https://supabase.com/dashboard/project/mededsdvznbtunrxyqnn/functions

2. Klicke auf "New Edge Function" für jede Funktion:

#### Für `recipes-with-deals`:
- Function Name: `recipes-with-deals`
- Kopiere den Inhalt aus `supabase/functions/recipes-with-deals/index.ts`
- Deploy

#### Für `get-categories`:
- Function Name: `get-categories`
- Kopiere den Inhalt aus `supabase/functions/get-categories/index.ts`
- Deploy

### Option 2: CLI Deployment

1. Erstelle einen Personal Access Token:
   - Gehe zu https://supabase.com/dashboard/account/tokens
   - Erstelle einen neuen Token
   - Kopiere den Token

2. Deploy mit CLI:
   ```bash
   cd /Users/finnweinnoldt/Downloads/smartmeal

   # Set your access token
   export SUPABASE_ACCESS_TOKEN="your-token-here"

   # Deploy beide Funktionen
   supabase functions deploy recipes-with-deals --project-ref mededsdvznbtunrxyqnn
   supabase functions deploy get-categories --project-ref mededsdvznbtunrxyqnn
   ```

## Nächste Schritte

Nach dem Deployment der Edge Functions:

### 1. Update Flutter App

Die Flutter App muss aktualisiert werden, um die Edge Functions statt des lokalen Backends anzurufen:

In `lib/core/services/recipe_api_client.dart` ändern von:
```dart
static const String baseUrl = 'http://localhost:8000';
```

zu:
```dart
static const String supabaseUrl = 'https://mededsdvznbtunrxyqnn.supabase.co';
```

Und die API-Calls ändern zu:
```dart
Future<MatchedRecipesResponse> getRecipesWithDeals({
  double minCoverage = 0.5,
  int matchThreshold = 70,
  int? limit,
  String? category,
}) async {
  final queryParams = <String, String>{
    'min_coverage': minCoverage.toString(),
    'match_threshold': matchThreshold.toString(),
  };

  if (limit != null) queryParams['limit'] = limit.toString();
  if (category != null) queryParams['category'] = category;

  // Call Edge Function
  final uri = Uri.parse('$supabaseUrl/functions/v1/recipes-with-deals')
      .replace(queryParameters: queryParams);

  final response = await http.get(
    uri,
    headers: {
      'Authorization': 'Bearer ${SupabaseConfig.supabaseAnonKey}',
    },
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to load recipes: ${response.body}');
  }

  final data = json.decode(response.body);
  return MatchedRecipesResponse.fromJson(data);
}
```

### 2. Testen

Nach dem Update der Flutter App:
1. Backend NICHT starten (lsof -ti:8000 | xargs kill -9)
2. Flutter App starten
3. Testen ob alle Funktionen funktionieren

## Edge Function URLs

Nach dem Deployment sind die Funktionen unter folgenden URLs erreichbar:

- **Recipes with Deals**: `https://mededsdvznbtunrxyqnn.supabase.co/functions/v1/recipes-with-deals`
- **Get Categories**: `https://mededsdvznbtunrxyqnn.supabase.co/functions/v1/get-categories`

## Wichtige Hinweise

1. **Service Role Key**: Die Edge Functions verwenden den `SUPABASE_SERVICE_ROLE_KEY` - dieser ist bereits in deinem Supabase-Projekt konfiguriert.

2. **CORS**: Die Funktionen haben bereits CORS-Header konfiguriert für Flutter Web/Mobile Apps.

3. **Kein lokales Backend mehr nötig**: Nach dem Deployment läuft alles auf Supabase-Servern.

4. **Kosten**: Supabase Edge Functions sind im Free Tier inkludiert (bis zu 500K requests/month).

## Fehlerbehebung

Falls die Edge Functions nicht funktionieren:

1. **Logs checken**:
   - Gehe zu https://supabase.com/dashboard/project/mededsdvznbtunrxyqnn/logs
   - Wähle "Edge Functions" aus
   - Siehe die Logs für Fehler

2. **Environment Variables checken**:
   - Stelle sicher dass `SUPABASE_URL` und `SUPABASE_SERVICE_ROLE_KEY` in den Edge Function Settings gesetzt sind
   - Diese sollten automatisch verfügbar sein

3. **Test mit curl**:
   ```bash
   curl -X GET 'https://mededsdvznbtunrxyqnn.supabase.co/functions/v1/recipes-with-deals?min_coverage=0.5' \
     -H 'Authorization: Bearer YOUR_ANON_KEY'
   ```

## Zusammenfassung

✅ Backend-Logik nach TypeScript portiert
✅ Edge Functions erstellt
⏳ Deployment auf Supabase (manuell oder CLI)
⏳ Flutter App Update (API-Calls auf Edge Functions umstellen)
⏳ Testing

Nach diesen Schritten läuft deine komplette App serverless auf Supabase!
