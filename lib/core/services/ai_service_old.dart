import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:smartmeal/core/models/models.dart';
import 'package:uuid/uuid.dart';

// Provider for AI Service
final aiServiceProvider = Provider<AIService>((ref) => AIService());

class AIService {
  // In production, use your actual API key stored securely
  // This should be fetched from environment variables or secure storage
  static const String _apiKey = 'YOUR_ANTHROPIC_API_KEY';
  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';
  
  final _uuid = const Uuid();

  /// Analyzes an image of a fridge/pantry and extracts ingredients
  Future<List<Ingredient>> analyzeImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-sonnet-4-20250514',
          'max_tokens': 4096,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': 'image/jpeg',
                    'data': base64Image,
                  },
                },
                {
                  'type': 'text',
                  'text': '''Analysiere dieses Bild eines Kühlschranks oder einer Speisekammer und identifiziere alle sichtbaren Lebensmittel.

Antworte NUR mit einem JSON-Array in diesem Format:
[
  {"name": "Zutat", "category": "Kategorie", "quantity": "geschätzte Menge"},
  ...
]

Kategorien: dairy, meat, fish, vegetables, fruits, grains, spices, beverages, frozen, snacks, other

Sei gründlich und liste alle erkennbaren Lebensmittel auf. Wenn du dir bei einer Menge nicht sicher bist, schätze sie.''',
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'] as String;
        
        // Extract JSON from response
        final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(content);
        if (jsonMatch != null) {
          final List<dynamic> ingredientsList = jsonDecode(jsonMatch.group(0)!);
          
          return ingredientsList.map((item) => Ingredient(
            id: _uuid.v4(),
            name: item['name'] as String,
            category: item['category'] as String?,
            quantity: item['quantity'] as String?,
          )).toList();
        }
      }
      
      throw Exception('Failed to analyze image');
    } catch (e) {
      // For demo purposes, return mock data if API fails
      return _getMockIngredients();
    }
  }

  /// Generates recipes based on available ingredients
  Future<List<Recipe>> generateRecipes(List<Ingredient> ingredients) async {
    try {
      final ingredientNames = ingredients.map((i) => i.name).join(', ');
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-sonnet-4-20250514',
          'max_tokens': 8192,
          'messages': [
            {
              'role': 'user',
              'content': '''Du bist ein kreativer Koch-Assistent. Erstelle 5 leckere Rezepte basierend auf diesen verfügbaren Zutaten:

$ingredientNames

Antworte NUR mit einem JSON-Array in diesem exakten Format:
[
  {
    "name": "Rezeptname",
    "description": "Kurze appetitliche Beschreibung",
    "prepTime": 15,
    "cookTime": 30,
    "servings": 4,
    "difficulty": "easy",
    "matchPercentage": 95,
    "ingredients": [
      {"name": "Zutat", "quantity": "200", "unit": "g", "isAvailable": true}
    ],
    "instructions": [
      "Schritt 1...",
      "Schritt 2..."
    ],
    "tags": ["schnell", "gesund"],
    "nutrition": {
      "calories": 450,
      "protein": 25,
      "carbs": 40,
      "fat": 15
    }
  }
]

Regeln:
- Priorisiere Rezepte, die hauptsächlich die verfügbaren Zutaten nutzen
- matchPercentage = Prozentsatz der Zutaten, die verfügbar sind
- isAvailable = true wenn Zutat in der Liste ist
- difficulty: "easy", "medium" oder "hard"
- Zeiten in Minuten
- Klare, nummerierte Anweisungen auf Deutsch''',
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'] as String;
        
        final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(content);
        if (jsonMatch != null) {
          final List<dynamic> recipesList = jsonDecode(jsonMatch.group(0)!);
          
          return recipesList.map((item) => Recipe(
            id: _uuid.v4(),
            name: item['name'] as String,
            description: item['description'] as String,
            prepTime: item['prepTime'] as int,
            cookTime: item['cookTime'] as int,
            servings: item['servings'] as int,
            difficulty: item['difficulty'] as String,
            matchPercentage: (item['matchPercentage'] as num).toDouble(),
            ingredients: (item['ingredients'] as List).map((i) => RecipeIngredient(
              name: i['name'] as String,
              quantity: i['quantity'] as String,
              unit: i['unit'] as String,
              isAvailable: i['isAvailable'] as bool? ?? false,
            )).toList(),
            instructions: List<String>.from(item['instructions'] as List),
            tags: List<String>.from(item['tags'] ?? []),
            nutrition: item['nutrition'] != null ? NutritionInfo(
              calories: item['nutrition']['calories'] as int,
              protein: (item['nutrition']['protein'] as num).toDouble(),
              carbs: (item['nutrition']['carbs'] as num).toDouble(),
              fat: (item['nutrition']['fat'] as num).toDouble(),
            ) : null,
          )).toList();
        }
      }
      
      throw Exception('Failed to generate recipes');
    } catch (e) {
      // Return mock recipes for demo
      return _getMockRecipes(ingredients);
    }
  }

  /// Generates recipes based on current deals
  Future<List<DealRecipe>> generateDealRecipes(List<Deal> deals) async {
    try {
      final dealProducts = deals.map((d) => 
        '${d.productName} (${d.storeName}: ${d.discountPrice.toStringAsFixed(2)}€, spare ${d.savings.toStringAsFixed(2)}€)'
      ).join('\n');
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-sonnet-4-20250514',
          'max_tokens': 8192,
          'messages': [
            {
              'role': 'user',
              'content': '''Du bist ein Spar-Koch-Experte. Erstelle 5 günstige Rezepte basierend auf diesen aktuellen Supermarkt-Angeboten:

$dealProducts

Antworte NUR mit einem JSON-Array. Für jedes Rezept gib an, welche Angebots-Produkte verwendet werden und wie viel man spart:

[
  {
    "recipe": {
      "name": "Rezeptname",
      "description": "Beschreibung",
      "prepTime": 15,
      "cookTime": 30,
      "servings": 4,
      "difficulty": "easy",
      "ingredients": [
        {"name": "Zutat", "quantity": "500", "unit": "g", "isAvailable": true}
      ],
      "instructions": ["Schritt 1", "Schritt 2"],
      "tags": ["günstig", "schnell"]
    },
    "dealIngredients": [
      {"ingredientName": "Zutat", "storeName": "Lidl", "price": 2.99, "savings": 1.50}
    ],
    "totalCost": 8.50,
    "totalSavings": 4.20
  }
]''',
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'] as String;
        
        final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(content);
        if (jsonMatch != null) {
          final List<dynamic> dealRecipesList = jsonDecode(jsonMatch.group(0)!);
          
          return dealRecipesList.map((item) {
            final recipeData = item['recipe'];
            final recipe = Recipe(
              id: _uuid.v4(),
              name: recipeData['name'] as String,
              description: recipeData['description'] as String,
              prepTime: recipeData['prepTime'] as int,
              cookTime: recipeData['cookTime'] as int,
              servings: recipeData['servings'] as int,
              difficulty: recipeData['difficulty'] as String,
              ingredients: (recipeData['ingredients'] as List).map((i) => RecipeIngredient(
                name: i['name'] as String,
                quantity: i['quantity'] as String,
                unit: i['unit'] as String,
                isAvailable: i['isAvailable'] as bool? ?? false,
              )).toList(),
              instructions: List<String>.from(recipeData['instructions'] as List),
              tags: List<String>.from(recipeData['tags'] ?? []),
            );
            
            final dealIngredients = (item['dealIngredients'] as List).map((di) {
              final ingredientName = di['ingredientName'] as String;
              final recipeIngredient = recipe.ingredients.firstWhere(
                (i) => i.name.toLowerCase() == ingredientName.toLowerCase(),
                orElse: () => RecipeIngredient(name: ingredientName, quantity: '', unit: ''),
              );
              
              return DealIngredient(
                ingredient: recipeIngredient,
                storeName: di['storeName'] as String,
                price: (di['price'] as num).toDouble(),
                savings: (di['savings'] as num?)?.toDouble(),
              );
            }).toList();
            
            return DealRecipe(
              recipe: recipe,
              dealIngredients: dealIngredients,
              totalCost: (item['totalCost'] as num).toDouble(),
              totalSavings: (item['totalSavings'] as num).toDouble(),
            );
          }).toList();
        }
      }
      
      throw Exception('Failed to generate deal recipes');
    } catch (e) {
      return _getMockDealRecipes(deals);
    }
  }

  // ==================== MOCK DATA FOR DEMO ====================

  List<Ingredient> _getMockIngredients() {
    return [
      Ingredient(id: _uuid.v4(), name: 'Hähnchenbrust', category: 'meat', quantity: '400g'),
      Ingredient(id: _uuid.v4(), name: 'Brokkoli', category: 'vegetables', quantity: '1 Kopf'),
      Ingredient(id: _uuid.v4(), name: 'Reis', category: 'grains', quantity: '500g'),
      Ingredient(id: _uuid.v4(), name: 'Zwiebeln', category: 'vegetables', quantity: '3 Stück'),
      Ingredient(id: _uuid.v4(), name: 'Knoblauch', category: 'spices', quantity: '1 Knolle'),
      Ingredient(id: _uuid.v4(), name: 'Sahne', category: 'dairy', quantity: '200ml'),
      Ingredient(id: _uuid.v4(), name: 'Parmesan', category: 'dairy', quantity: '100g'),
      Ingredient(id: _uuid.v4(), name: 'Tomaten', category: 'vegetables', quantity: '4 Stück'),
      Ingredient(id: _uuid.v4(), name: 'Paprika', category: 'vegetables', quantity: '2 Stück'),
      Ingredient(id: _uuid.v4(), name: 'Eier', category: 'dairy', quantity: '6 Stück'),
      Ingredient(id: _uuid.v4(), name: 'Butter', category: 'dairy', quantity: '250g'),
      Ingredient(id: _uuid.v4(), name: 'Milch', category: 'dairy', quantity: '1L'),
    ];
  }

  List<Recipe> _getMockRecipes(List<Ingredient> ingredients) {
    return [
      Recipe(
        id: _uuid.v4(),
        name: 'Cremiges Hähnchen mit Brokkoli',
        description: 'Zartes Hähnchen in einer cremigen Sahnesauce mit frischem Brokkoli - perfekt für einen gemütlichen Abend.',
        imageUrl: 'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=800',
        prepTime: 15,
        cookTime: 25,
        servings: 4,
        difficulty: 'easy',
        matchPercentage: 100,
        ingredients: [
          const RecipeIngredient(name: 'Hähnchenbrust', quantity: '400', unit: 'g', isAvailable: true),
          const RecipeIngredient(name: 'Brokkoli', quantity: '1', unit: 'Kopf', isAvailable: true),
          const RecipeIngredient(name: 'Sahne', quantity: '200', unit: 'ml', isAvailable: true),
          const RecipeIngredient(name: 'Knoblauch', quantity: '2', unit: 'Zehen', isAvailable: true),
          const RecipeIngredient(name: 'Parmesan', quantity: '50', unit: 'g', isAvailable: true),
        ],
        instructions: [
          'Hähnchenbrust in Streifen schneiden und mit Salz und Pfeffer würzen.',
          'Brokkoli in Röschen teilen und in Salzwasser 5 Minuten blanchieren.',
          'Hähnchen in einer Pfanne mit etwas Öl goldbraun anbraten.',
          'Knoblauch fein hacken und zum Hähnchen geben.',
          'Sahne hinzufügen und 5 Minuten köcheln lassen.',
          'Brokkoli und geriebenen Parmesan unterheben.',
          'Mit Reis servieren.',
        ],
        tags: ['schnell', 'proteinreich', 'Low Carb möglich'],
        nutrition: const NutritionInfo(calories: 420, protein: 35, carbs: 12, fat: 28),
      ),
      Recipe(
        id: _uuid.v4(),
        name: 'Mediterraner Gemüse-Reis',
        description: 'Buntes Gemüse trifft auf aromatischen Reis - vegetarisch und voller Geschmack.',
        imageUrl: 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=800',
        prepTime: 10,
        cookTime: 30,
        servings: 4,
        difficulty: 'easy',
        matchPercentage: 95,
        ingredients: [
          const RecipeIngredient(name: 'Reis', quantity: '300', unit: 'g', isAvailable: true),
          const RecipeIngredient(name: 'Paprika', quantity: '2', unit: 'Stück', isAvailable: true),
          const RecipeIngredient(name: 'Tomaten', quantity: '3', unit: 'Stück', isAvailable: true),
          const RecipeIngredient(name: 'Zwiebeln', quantity: '1', unit: 'Stück', isAvailable: true),
          const RecipeIngredient(name: 'Knoblauch', quantity: '2', unit: 'Zehen', isAvailable: true),
          const RecipeIngredient(name: 'Olivenöl', quantity: '3', unit: 'EL', isAvailable: false),
        ],
        instructions: [
          'Reis nach Packungsanleitung kochen.',
          'Gemüse waschen und in Würfel schneiden.',
          'Zwiebeln und Knoblauch in Olivenöl anschwitzen.',
          'Paprika hinzufügen und 5 Minuten braten.',
          'Tomaten dazugeben und weitere 3 Minuten garen.',
          'Reis unterheben und mit Salz, Pfeffer und Oregano abschmecken.',
        ],
        tags: ['vegetarisch', 'vegan möglich', 'meal prep'],
        nutrition: const NutritionInfo(calories: 320, protein: 8, carbs: 58, fat: 6),
      ),
      Recipe(
        id: _uuid.v4(),
        name: 'Klassisches Rührei Deluxe',
        description: 'Fluffiges Rührei mit Kräutern und Parmesan - der perfekte Start in den Tag.',
        imageUrl: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=800',
        prepTime: 5,
        cookTime: 10,
        servings: 2,
        difficulty: 'easy',
        matchPercentage: 100,
        ingredients: [
          const RecipeIngredient(name: 'Eier', quantity: '4', unit: 'Stück', isAvailable: true),
          const RecipeIngredient(name: 'Butter', quantity: '20', unit: 'g', isAvailable: true),
          const RecipeIngredient(name: 'Milch', quantity: '50', unit: 'ml', isAvailable: true),
          const RecipeIngredient(name: 'Parmesan', quantity: '30', unit: 'g', isAvailable: true),
          const RecipeIngredient(name: 'Schnittlauch', quantity: '1', unit: 'Bund', isAvailable: false),
        ],
        instructions: [
          'Eier mit Milch verquirlen und mit Salz und Pfeffer würzen.',
          'Butter in einer beschichteten Pfanne bei mittlerer Hitze schmelzen.',
          'Eimasse in die Pfanne geben.',
          'Mit einem Spatel langsam vom Rand zur Mitte schieben.',
          'Wenn das Ei fast gestockt ist, vom Herd nehmen.',
          'Parmesan darüber reiben und mit Schnittlauch servieren.',
        ],
        tags: ['Frühstück', 'schnell', 'vegetarisch'],
        nutrition: const NutritionInfo(calories: 280, protein: 18, carbs: 2, fat: 22),
      ),
      Recipe(
        id: _uuid.v4(),
        name: 'Gebratener Reis mit Hähnchen',
        description: 'Asiatisch inspirierter gebratener Reis mit knusprigem Hähnchen und buntem Gemüse.',
        imageUrl: 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=800',
        prepTime: 15,
        cookTime: 20,
        servings: 4,
        difficulty: 'medium',
        matchPercentage: 90,
        ingredients: [
          const RecipeIngredient(name: 'Reis', quantity: '300', unit: 'g', isAvailable: true),
          const RecipeIngredient(name: 'Hähnchenbrust', quantity: '300', unit: 'g', isAvailable: true),
          const RecipeIngredient(name: 'Eier', quantity: '2', unit: 'Stück', isAvailable: true),
          const RecipeIngredient(name: 'Paprika', quantity: '1', unit: 'Stück', isAvailable: true),
          const RecipeIngredient(name: 'Zwiebeln', quantity: '1', unit: 'Stück', isAvailable: true),
          const RecipeIngredient(name: 'Sojasauce', quantity: '3', unit: 'EL', isAvailable: false),
        ],
        instructions: [
          'Reis kochen und komplett abkühlen lassen (am besten vom Vortag).',
          'Hähnchen in kleine Würfel schneiden.',
          'Gemüse in feine Streifen schneiden.',
          'Hähnchen in heißem Öl scharf anbraten, herausnehmen.',
          'Gemüse im Wok kurz anbraten.',
          'Reis hinzufügen und bei hoher Hitze braten.',
          'Eier am Rand aufschlagen und vermengen.',
          'Hähnchen und Sojasauce hinzufügen.',
        ],
        tags: ['asiatisch', 'meal prep', 'proteinreich'],
        nutrition: const NutritionInfo(calories: 480, protein: 32, carbs: 52, fat: 14),
      ),
      Recipe(
        id: _uuid.v4(),
        name: 'Tomaten-Parmesan Omelette',
        description: 'Luftiges Omelette gefüllt mit sonnengereiften Tomaten und würzigem Parmesan.',
        imageUrl: 'https://images.unsplash.com/photo-1510693206972-df098062cb71?w=800',
        prepTime: 5,
        cookTime: 8,
        servings: 1,
        difficulty: 'easy',
        matchPercentage: 100,
        ingredients: [
          const RecipeIngredient(name: 'Eier', quantity: '3', unit: 'Stück', isAvailable: true),
          const RecipeIngredient(name: 'Tomaten', quantity: '1', unit: 'Stück', isAvailable: true),
          const RecipeIngredient(name: 'Parmesan', quantity: '30', unit: 'g', isAvailable: true),
          const RecipeIngredient(name: 'Butter', quantity: '15', unit: 'g', isAvailable: true),
        ],
        instructions: [
          'Eier verquirlen und mit Salz und Pfeffer würzen.',
          'Tomate in kleine Würfel schneiden.',
          'Butter in einer Pfanne bei mittlerer Hitze schmelzen.',
          'Eier in die Pfanne geben und stocken lassen.',
          'Tomaten und Parmesan auf eine Hälfte geben.',
          'Omelette zusammenklappen und servieren.',
        ],
        tags: ['Frühstück', 'Low Carb', 'vegetarisch'],
        nutrition: const NutritionInfo(calories: 350, protein: 24, carbs: 4, fat: 27),
      ),
    ];
  }

  List<DealRecipe> _getMockDealRecipes(List<Deal> deals) {
    if (deals.isEmpty) {
      return [];
    }

    // ========== HELPER FUNCTIONS ==========

    // Parse quantity from deal description (e.g., "500-g-Packg." => 500g)
    Map<String, dynamic> parseQuantity(String description) {
      // Match patterns like "500-g", "1 kg", "250 ml", etc.
      final regex = RegExp(r'(\d+(?:\.\d+)?)\s*[-\s]*(g|kg|ml|l|stück|stk\.?)', caseSensitive: false);
      final match = regex.firstMatch(description);

      if (match != null) {
        final amount = double.parse(match.group(1)!);
        var unit = match.group(2)!.toLowerCase();

        // Normalize units
        if (unit == 'kg') return {'amount': amount * 1000, 'unit': 'g'};
        if (unit == 'l') return {'amount': amount * 1000, 'unit': 'ml'};
        if (unit.startsWith('stk')) return {'amount': amount, 'unit': 'Stück'};

        return {'amount': amount, 'unit': unit};
      }

      return {'amount': 1.0, 'unit': 'Stück'};
    }

    // Match ingredients to deals intelligently
    Deal? findMatchingDeal(String ingredientName) {
      final searchTerm = ingredientName.toLowerCase();

      // Direct match keywords for common ingredients
      final keywords = <String, List<String>>{
        'hähnchen': ['hähnchen', 'hühnchen', 'geflügel', 'chicken', 'schnitzel'],
        'rind': ['rind', 'beef', 'roastbeef', 'sauerbraten'],
        'hackfleisch': ['hackfleisch', 'hack', 'gehacktes'],
        'lachs': ['lachs', 'salmon', 'lachsforelle'],
        'fisch': ['fisch', 'forelle'],
        'tomaten': ['tomate', 'cherry', 'roma', 'cocktail', 'miniroma'],
        'paprika': ['paprika', 'pepper'],
        'sahne': ['sahne', 'cream', 'schmand'],
        'milch': ['milch', 'milk'],
        'käse': ['käse', 'cheese', 'mozzarella', 'parmesan', 'gouda', 'feta'],
        'eier': ['ei', 'egg'],
        'reis': ['reis', 'rice', 'basmati'],
        'pasta': ['pasta', 'nudel', 'spaghetti', 'penne'],
        'zwiebel': ['zwiebel', 'onion'],
        'kartoffel': ['kartoffel', 'potato', 'erdapfel'],
        'brot': ['brot', 'bread', 'baguette'],
        'wein': ['wein', 'wine'],
        'getränk': ['getränk', 'drink', 'saft'],
        'trauben': ['traube', 'grape'],
      };

      // Try to find matching deal
      for (final deal in deals) {
        final productName = deal.productName.toLowerCase();

        // Direct substring match
        if (productName.contains(searchTerm) || searchTerm.contains(productName.split(' ').first)) {
          return deal;
        }

        // Keyword match
        for (final entry in keywords.entries) {
          if (searchTerm.contains(entry.key)) {
            for (final keyword in entry.value) {
              if (productName.contains(keyword)) {
                return deal;
              }
            }
          }
        }
      }

      return null;
    }

    // Calculate actual savings based on usage - FIXED VERSION
    double calculateActualSavings(Deal deal, double usedAmount, String usedUnit) {
      final dealQty = parseQuantity(deal.description ?? '1 Stück');
      final dealAmount = dealQty['amount'] as double;
      final dealUnit = dealQty['unit'] as String;

      // Normalize to same unit
      double normalizedUsedAmount = usedAmount;
      if (dealUnit == 'g' && usedUnit == 'kg') {
        normalizedUsedAmount = usedAmount * 1000; // convert kg to g
      } else if (dealUnit == 'ml' && usedUnit == 'l') {
        normalizedUsedAmount = usedAmount * 1000; // convert l to ml
      } else if (dealUnit != usedUnit) {
        // Different units, assume 1:1 ratio
        normalizedUsedAmount = usedAmount;
      }

      // Calculate proportional savings: (savings per package) * (amount used / package amount)
      final usageRatio = normalizedUsedAmount / dealAmount;
      return deal.savings * usageRatio;
    }

    // Calculate actual price based on usage - NEW HELPER
    double calculateActualPrice(Deal deal, double usedAmount, String usedUnit) {
      final dealQty = parseQuantity(deal.description ?? '1 Stück');
      final dealAmount = dealQty['amount'] as double;
      final dealUnit = dealQty['unit'] as String;

      // Normalize to same unit
      double normalizedUsedAmount = usedAmount;
      if (dealUnit == 'g' && usedUnit == 'kg') {
        normalizedUsedAmount = usedAmount * 1000;
      } else if (dealUnit == 'ml' && usedUnit == 'l') {
        normalizedUsedAmount = usedAmount * 1000;
      } else if (dealUnit != usedUnit) {
        normalizedUsedAmount = usedAmount;
      }

      // Calculate proportional price
      final usageRatio = normalizedUsedAmount / dealAmount;
      return deal.discountPrice * usageRatio;
    }

    // ========== RECIPE GENERATION ==========

    final dealRecipes = <DealRecipe>[];

    // Group deals by category
    final meatDeals = deals.where((d) => d.category == 'Fleisch & Wurst').toList();
    final veggieDeals = deals.where((d) => d.category == 'Obst & Gemüse').toList();

    // ========== RECIPE 1: Sauerbraten Klassisch ==========
    final sauerbratDeal = findMatchingDeal('sauerbraten');
    final tomatoDeal = findMatchingDeal('tomaten');

    if (sauerbratDeal != null) {
      final servings = 4;

      // Ingredients for 4 servings
      final ingredients = <RecipeIngredient>[
        RecipeIngredient(name: sauerbratDeal.productName, quantity: '800', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Zwiebeln', quantity: '2', unit: 'Stück', isAvailable: true),
        const RecipeIngredient(name: 'Karotten', quantity: '2', unit: 'Stück', isAvailable: true),
        const RecipeIngredient(name: 'Rotwein', quantity: '200', unit: 'ml', isAvailable: true),
        const RecipeIngredient(name: 'Rotkohl', quantity: '500', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Kartoffelklöße', quantity: '8', unit: 'Stück', isAvailable: true),
      ];

      // Calculate costs and savings using CORRECTED HELPERS
      const usedAmount = 800.0; // grams needed for 4 servings

      final meatCost = calculateActualPrice(sauerbratDeal, usedAmount, 'g');
      final meatSavings = calculateActualSavings(sauerbratDeal, usedAmount, 'g');

      final dealIngredients = <DealIngredient>[
        DealIngredient(
          ingredient: ingredients[0],
          deal: sauerbratDeal,
          storeName: sauerbratDeal.storeName,
          price: meatCost,
          savings: meatSavings,
        ),
      ];

      if (tomatoDeal != null) {
        ingredients.insert(1, RecipeIngredient(name: tomatoDeal.productName, quantity: '200', unit: 'g', isAvailable: true));
        final tomatoUsage = 200.0;
        final tomatoQty = parseQuantity(tomatoDeal.description ?? '500 g');
        final tomatoRatio = tomatoUsage / (tomatoQty['amount'] as double);

        dealIngredients.add(DealIngredient(
          ingredient: ingredients[1],
          deal: tomatoDeal,
          storeName: tomatoDeal.storeName,
          price: tomatoDeal.discountPrice * tomatoRatio,
          savings: calculateActualSavings(tomatoDeal, tomatoUsage, 'g'),
        ));
      }

      final totalSavings = dealIngredients.fold<double>(0, (sum, di) => sum + (di.savings ?? 0));
      final totalCost = dealIngredients.fold<double>(0, (sum, di) => sum + di.price) + 4.50; // +other ingredients

      dealRecipes.add(DealRecipe(
        recipe: Recipe(
          id: _uuid.v4(),
          name: 'Klassischer Sauerbraten mit Rotkohl',
          description: 'Traditioneller deutscher Sauerbraten - zartes, mariniertes Rindfleisch in würziger Sauce, serviert mit hausgemachtem Rotkohl und fluffigen Kartoffelklößen. Ein Festmahl für die ganze Familie!',
          imageUrl: 'https://images.unsplash.com/photo-1600891964599-f61ba0e24092?w=800',
          prepTime: 20,
          cookTime: 120,
          servings: servings,
          difficulty: 'medium',
          ingredients: ingredients,
          instructions: [
            '1. VORBEREITUNG: Sauerbraten aus der Verpackung nehmen und mit Küchenpapier gründlich trockentupfen. Bei Raumtemperatur 20 Minuten ruhen lassen, damit er gleichmäßig gart.',
            '2. GEMÜSE VORBEREITEN: Zwiebeln schälen und in feine Ringe schneiden. Karotten schälen und in 1 cm dicke Scheiben schneiden. Falls Tomaten verwendet werden, diese vierteln.',
            '3. FLEISCH ANBRATEN: Eine große Pfanne oder Bräter auf mittlerer bis hoher Hitze erhitzen. 2 EL Öl hinzufügen. Den Sauerbraten von allen Seiten je 3-4 Minuten scharf anbraten, bis er eine goldbraune Kruste hat. Das Fleisch herausnehmen und beiseite stellen.',
            '4. GEMÜSE ANSCHWITZEN: Im gleichen Topf die Zwiebeln und Karotten bei mittlerer Hitze 5 Minuten anschwitzen, dabei den Bratensatz vom Boden lösen.',
            '5. ABLÖSCHEN: Mit Rotwein ablöschen und einmal aufkochen lassen. Dabei mit einem Holzlöffel den Bratensatz komplett vom Boden lösen - hier steckt viel Geschmack drin!',
            '6. SCHMOREN: Das Fleisch zurück in den Topf geben. 400 ml Wasser, 2 Lorbeerblätter, 5 Wacholderbeeren und 2 Nelken hinzufügen. Mit Salz und Pfeffer würzen. Zum Kochen bringen, dann Hitze reduzieren und zugedeckt 90-120 Minuten schmoren lassen. Das Fleisch sollte so zart sein, dass es fast von selbst zerfällt.',
            '7. ROTKOHL ZUBEREITEN: Währenddessen Rotkohl in feine Streifen schneiden. In einem separaten Topf mit etwas Butter andünsten, mit 2 EL Essig, 1 EL Zucker, Salz, Pfeffer und einem Apfel (in Würfel geschnitten) würzen. Bei niedriger Hitze 45 Minuten köcheln lassen.',
            '8. KARTOFFELKLOSSE: 20 Minuten vor Ende der Garzeit die Kartoffelklöße nach Packungsanweisung in gesalzenem, siedendem Wasser garen.',
            '9. SAUCE VOLLENDEN: Das Fleisch aus dem Topf nehmen und warm stellen. Die Sauce durch ein Sieb gießen und in einem kleinen Topf nochmal aufkochen. Mit Salz, Pfeffer und einem Teelöffel Zucker abschmecken. Für eine sämigere Sauce kann man 1 EL Speisestärke mit etwas kaltem Wasser anrühren und einrühren.',
            '10. ANRICHTEN: Den Sauerbraten in dicke Scheiben schneiden und auf vorgewärmten Tellern anrichten. Rotkohl und Klöße dazu servieren. Die Sauce großzügig über das Fleisch geben. Mit frischer Petersilie garnieren und sofort servieren!',
          ],
          tags: ['traditionell', 'festlich', 'kaufland angebote', 'deutsch'],
          nutrition: const NutritionInfo(calories: 680, protein: 52, carbs: 48, fat: 28),
        ),
        dealIngredients: dealIngredients,
        totalCost: totalCost,
        totalSavings: totalSavings,
      ));
    }

    // ========== RECIPE 2: Frischer Tomatensalat mit Trauben ==========
    if (tomatoDeal != null) {
      final grapesDeal = findMatchingDeal('trauben');
      final servings = 4;

      final ingredients = <RecipeIngredient>[
        RecipeIngredient(name: tomatoDeal.productName, quantity: '500', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Rote Zwiebel', quantity: '1', unit: 'Stück', isAvailable: true),
        const RecipeIngredient(name: 'Basilikum', quantity: '1', unit: 'Bund', isAvailable: true),
        const RecipeIngredient(name: 'Olivenöl', quantity: '4', unit: 'EL', isAvailable: true),
        const RecipeIngredient(name: 'Balsamico-Essig', quantity: '2', unit: 'EL', isAvailable: true),
      ];

      final dealIngredients = <DealIngredient>[];

      // Add tomatoes
      final tomatoUsed = 500.0;

      dealIngredients.add(DealIngredient(
        ingredient: ingredients[0],
        deal: tomatoDeal,
        storeName: tomatoDeal.storeName,
        price: calculateActualPrice(tomatoDeal, tomatoUsed, 'g'),
        savings: calculateActualSavings(tomatoDeal, tomatoUsed, 'g'),
      ));

      if (grapesDeal != null) {
        ingredients.insert(2, RecipeIngredient(name: grapesDeal.productName, quantity: '200', unit: 'g', isAvailable: true));
        final grapesUsed = 200.0;

        dealIngredients.add(DealIngredient(
          ingredient: ingredients[2],
          deal: grapesDeal,
          storeName: grapesDeal.storeName,
          price: calculateActualPrice(grapesDeal, grapesUsed, 'g'),
          savings: calculateActualSavings(grapesDeal, grapesUsed, 'g'),
        ));
      }

      final totalSavings = dealIngredients.fold<double>(0, (sum, di) => sum + (di.savings ?? 0));
      final totalCost = dealIngredients.fold<double>(0, (sum, di) => sum + di.price) + 1.50;

      dealRecipes.add(DealRecipe(
        recipe: Recipe(
          id: _uuid.v4(),
          name: 'Mediterraner Tomatensalat mit Trauben',
          description: 'Erfrischender Sommersalat mit saftigen Tomaten und süßen Trauben - eine überraschende Geschmackskombination, die süß und herzhaft perfekt vereint!',
          imageUrl: 'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=800',
          prepTime: 15,
          cookTime: 0,
          servings: servings,
          difficulty: 'easy',
          ingredients: ingredients,
          instructions: [
            '1. TOMATEN VORBEREITEN: Die Tomaten gründlich unter kaltem Wasser waschen und trocken tupfen. Je nach Größe halbieren oder vierteln. Bei größeren Tomaten entfernen Sie den Stielansatz mit einem kleinen Messer.',
            '2. TRAUBEN WASCHEN: Die Trauben vom Stiel lösen, gründlich waschen und ebenfalls halbieren. Wenn Sie keine Kerne mögen, achten Sie beim Kauf auf kernlose Sorten.',
            '3. ZWIEBEL SCHNEIDEN: Die rote Zwiebel schälen und in hauchdünne Ringe oder Halbringe schneiden. PROFI-TIPP: Legen Sie die Zwiebelringe für 5 Minuten in kaltes Wasser - das nimmt die Schärfe und macht sie bekömmlicher!',
            '4. BASILIKUM ZUPFEN: Die Basilikumblätter vom Stiel zupfen. Größere Blätter grob zerreißen, kleine ganz lassen. Nicht schneiden - das würde zu Verfärbungen führen!',
            '5. DRESSING MIXEN: In einer kleinen Schüssel Olivenöl, Balsamico-Essig, 1 TL Honig, Salz und frisch gemahlenen Pfeffer mit einem Schneebesen kräftig verquirlen, bis eine emulgierte Sauce entsteht.',
            '6. SALAT MISCHEN: Tomaten, Trauben und Zwiebelringe in eine große Schüssel geben. Das Dressing darüber träufeln und vorsichtig mit zwei Löffeln vermengen, sodass alles gleichmäßig bedeckt ist.',
            '7. ZIEHEN LASSEN: Den Salat 10 Minuten bei Raumtemperatur ziehen lassen, damit sich die Aromen verbinden können.',
            '8. ANRICHTEN: Auf Teller oder eine schöne Servierplatte anrichten. Mit frischem Basilikum garnieren. Optional können Sie noch geröstete Pinienkerne oder Feta-Käse-Würfel darüber streuen. Sofort servieren!',
          ],
          tags: ['vegetarisch', 'vegan', 'schnell', 'gesund', 'kaufland angebote', 'sommer'],
          nutrition: const NutritionInfo(calories: 140, protein: 2, carbs: 18, fat: 8),
        ),
        dealIngredients: dealIngredients,
        totalCost: totalCost,
        totalSavings: totalSavings,
      ));
    }

    // ========== RECIPE 3: Add more recipes with other available deals ==========
    final otherMeatDeal = meatDeals.isNotEmpty ? meatDeals.first : null;

    if (otherMeatDeal != null) {
      final servings = 4;
      final ingredients = <RecipeIngredient>[
        RecipeIngredient(name: otherMeatDeal.productName, quantity: '600', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Kartoffeln', quantity: '800', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Gemischtes Gemüse', quantity: '400', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Butter', quantity: '50', unit: 'g', isAvailable: true),
      ];

      final meatUsed = 600.0;

      final dealIngredients = <DealIngredient>[
        DealIngredient(
          ingredient: ingredients[0],
          deal: otherMeatDeal,
          storeName: otherMeatDeal.storeName,
          price: calculateActualPrice(otherMeatDeal, meatUsed, 'g'),
          savings: calculateActualSavings(otherMeatDeal, meatUsed, 'g'),
        ),
      ];

      final totalSavings = dealIngredients.fold<double>(0, (sum, di) => sum + (di.savings ?? 0));
      final totalCost = dealIngredients.fold<double>(0, (sum, di) => sum + di.price) + 3.50;

      dealRecipes.add(DealRecipe(
        recipe: Recipe(
          id: _uuid.v4(),
          name: 'Herzhafter Fleisch-Eintopf',
          description: 'Kräftiger Eintopf mit zartem Fleisch, Kartoffeln und Gemüse - perfekt für kalte Tage und die ganze Familie!',
          imageUrl: 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=800',
          prepTime: 20,
          cookTime: 60,
          servings: servings,
          difficulty: 'easy',
          ingredients: ingredients,
          instructions: [
            '1. FLEISCH VORBEREITEN: Das Fleisch in mundgerechte Würfel (ca. 2-3 cm) schneiden. Mit Küchenpapier trocken tupfen - nur trockenes Fleisch brät richtig schön an!',
            '2. GEMÜSE SCHNEIDEN: Kartoffeln schälen und in gleich große Würfel schneiden. Gemüse (Karotten, Sellerie, Lauch) waschen und in grobe Stücke schneiden.',
            '3. FLEISCH ANBRATEN: In einem großen Topf 2 EL Öl erhitzen. Das Fleisch portionsweise (nicht zu viel auf einmal, sonst kocht es statt zu braten!) bei hoher Hitze von allen Seiten scharf anbraten, bis es eine schöne braune Kruste hat. Fleisch herausnehmen.',
            '4. GEMÜSE ANSCHWITZEN: In demselben Topf die Zwiebeln glasig dünsten. Dann Karotten und Sellerie hinzufügen und weitere 5 Minuten anschwitzen.',
            '5. ABLÖSCHEN: Mit 1,5 Liter Brühe (Rind oder Gemüse) ablöschen. Das Fleisch zurück in den Topf geben. Mit Salz, Pfeffer, 2 Lorbeerblättern und etwas Thymian würzen.',
            '6. KÖCHELN: Zum Kochen bringen, dann Hitze reduzieren. 30 Minuten zugedeckt köcheln lassen.',
            '7. KARTOFFELN HINZUFÜGEN: Die Kartoffelwürfel zum Eintopf geben und weitere 20-25 Minuten köcheln lassen, bis Fleisch und Kartoffeln weich sind.',
            '8. ABSCHMECKEN: Mit Salz, Pfeffer und einem Schuss Worcestersauce abschmecken. Wer es sämiger mag, kann 1-2 EL Mehl mit etwas kaltem Wasser verrühren und einrühren.',
            '9. SERVIEREN: In tiefe Teller oder Schüsseln füllen. Mit frischer gehackter Petersilie bestreuen und mit knusprigem Brot servieren. Guten Appetit!',
          ],
          tags: ['herzhaft', 'eintopf', 'familienfreundlich', 'kaufland angebote'],
          nutrition: const NutritionInfo(calories: 520, protein: 42, carbs: 44, fat: 18),
        ),
        dealIngredients: dealIngredients,
        totalCost: totalCost,
        totalSavings: totalSavings,
      ));
    }

    // ========== RECIPE 4: Raclette-Abend ==========
    final racletteDeal = findMatchingDeal('raclette');
    final clementineDeal = findMatchingDeal('clementinen');

    if (racletteDeal != null) {
      const servings = 4;
      final ingredients = <RecipeIngredient>[
        RecipeIngredient(name: racletteDeal.productName, quantity: '400', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Kleine Kartoffeln', quantity: '800', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Cornichons', quantity: '1', unit: 'Glas', isAvailable: true),
        const RecipeIngredient(name: 'Silberzwiebeln', quantity: '1', unit: 'Glas', isAvailable: true),
      ];

      final raclUsed = 400.0;

      final dealIngredients = <DealIngredient>[
        DealIngredient(
          ingredient: ingredients[0],
          deal: racletteDeal,
          storeName: racletteDeal.storeName,
          price: calculateActualPrice(racletteDeal, raclUsed, 'g'),
          savings: calculateActualSavings(racletteDeal, raclUsed, 'g'),
        ),
      ];

      if (clementineDeal != null) {
        ingredients.add(RecipeIngredient(name: clementineDeal.productName, quantity: '4', unit: 'Stück', isAvailable: true));
        final clemUsed = 300.0; // ~4 clementines

        dealIngredients.add(DealIngredient(
          ingredient: ingredients.last,
          deal: clementineDeal,
          storeName: clementineDeal.storeName,
          price: calculateActualPrice(clementineDeal, clemUsed, 'g'),
          savings: calculateActualSavings(clementineDeal, clemUsed, 'g'),
        ));
      }

      final totalSavings = dealIngredients.fold<double>(0, (sum, di) => sum + (di.savings ?? 0));
      final totalCost = dealIngredients.fold<double>(0, (sum, di) => sum + di.price) + 3.00;

      dealRecipes.add(DealRecipe(
        recipe: Recipe(
          id: _uuid.v4(),
          name: 'Gemütlicher Raclette-Abend',
          description: 'Geselliges Raclette mit geschmolzenem Käse, Pellkartoffeln und eingelegten Leckereien - perfekt für einen Abend mit Freunden!',
          imageUrl: 'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?w=800',
          prepTime: 20,
          cookTime: 30,
          servings: servings,
          difficulty: 'easy',
          ingredients: ingredients,
          instructions: [
            '1. KARTOFFELN VORBEREITEN: Die kleinen Kartoffeln gründlich unter fließendem Wasser abbürsten. Größere Kartoffeln halbieren, damit alle gleich groß sind und gleichmäßig garen.',
            '2. KARTOFFELN KOCHEN: Die Kartoffeln in einen großen Topf mit kaltem Salzwasser geben (das Wasser sollte die Kartoffeln vollständig bedecken). Zum Kochen bringen und dann bei mittlerer Hitze 20-25 Minuten kochen, bis sie weich sind. TIPP: Mit einem Messer einstechen - wenn es leicht durchgeht, sind sie fertig!',
            '3. RACLETTE-GERÄT VORHEIZEN: Während die Kartoffeln kochen, das Raclette-Gerät aufstellen und vorheizen. Dies dauert etwa 10-15 Minuten.',
            '4. KÄSE VORBEREITEN: Den Raclette-Käse in dünne Scheiben schneiden (ca. 3-4mm dick). Je dünner die Scheiben, desto schneller und gleichmäßiger schmilzt der Käse. Pro Person rechnet man etwa 200-250g Käse.',
            '5. BEILAGEN ARRANGIEREN: Cornichons und Silberzwiebeln aus den Gläsern nehmen und in kleine Schälchen füllen. Wenn vorhanden: Clementinen schälen und in Spalten teilen - die fruchtige Säure ist ein perfekter Kontrast zum würzigen Käse!',
            '6. KARTOFFELN ABGIESSEN: Wenn die Kartoffeln gar sind, das Wasser abgießen und die Kartoffeln kurz ausdampfen lassen. In einer Schüssel warm halten oder direkt servieren.',
            '7. RACLETTE STARTEN: Jeder Gast bekommt ein Raclette-Pfännchen. Eine Käsescheibe hineinlegen und unter das Raclette-Gerät schieben. Der Käse braucht etwa 3-5 Minuten, bis er goldbraun und blasig geschmolzen ist.',
            '8. SERVIEREN & GENIESSEN: Die Kartoffeln auf den Teller legen und den geschmolzenen Käse darüber gießen. Mit Cornichons, Silberzwiebeln und frischem schwarzen Pfeffer garnieren. Die Clementinen als erfrischenden Abschluss genießen!',
            '9. PROFI-TIPP: Raclette ist ein geselliges Essen - jeder schmilzt seinen Käse selbst! Zwischendurch immer wieder nachfüllen. Der Käse schmeckt am besten, wenn er leicht gebräunt und blasig ist.',
            '10. VARIATION: Für mehr Abwechslung können Sie auch Schinken, Champignons, Paprika oder Zucchini mit in die Pfännchen geben und zusammen mit dem Käse überbacken!',
          ],
          tags: ['gesellig', 'käse', 'vegetarisch', 'kaufland angebote', 'party'],
          nutrition: const NutritionInfo(calories: 580, protein: 24, carbs: 42, fat: 34),
        ),
        dealIngredients: dealIngredients,
        totalCost: totalCost,
        totalSavings: totalSavings,
      ));
    }

    // ========== RECIPE 5: Pizza-Party ==========
    final pizzaDeal = findMatchingDeal('pizza');
    final salamiDeal = findMatchingDeal('salami');

    if (pizzaDeal != null) {
      const servings = 2;
      final ingredients = <RecipeIngredient>[
        RecipeIngredient(name: pizzaDeal.productName, quantity: '1', unit: 'Stück', isAvailable: true),
        const RecipeIngredient(name: 'Frische Rucola', quantity: '50', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Parmesan', quantity: '30', unit: 'g', isAvailable: true),
      ];

      final dealIngredients = <DealIngredient>[
        DealIngredient(
          ingredient: ingredients[0],
          deal: pizzaDeal,
          storeName: pizzaDeal.storeName,
          price: pizzaDeal.discountPrice,
          savings: pizzaDeal.savings,
        ),
      ];

      if (salamiDeal != null) {
        ingredients.insert(1, RecipeIngredient(name: salamiDeal.productName, quantity: '100', unit: 'g', isAvailable: true));
        final salamiUsed = 100.0;

        dealIngredients.add(DealIngredient(
          ingredient: ingredients[1],
          deal: salamiDeal,
          storeName: salamiDeal.storeName,
          price: calculateActualPrice(salamiDeal, salamiUsed, 'g'),
          savings: calculateActualSavings(salamiDeal, salamiUsed, 'g'),
        ));
      }

      final totalSavings = dealIngredients.fold<double>(0, (sum, di) => sum + (di.savings ?? 0));
      final totalCost = dealIngredients.fold<double>(0, (sum, di) => sum + di.price) + 1.50;

      dealRecipes.add(DealRecipe(
        recipe: Recipe(
          id: _uuid.v4(),
          name: 'Gourmet-Pizza Deluxe',
          description: 'Knusprige Ofen-Pizza verfeinert mit zusätzlichem Belag, frischem Rucola und Parmesan - Restaurant-Qualität zu Hause!',
          imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800',
          prepTime: 10,
          cookTime: 12,
          servings: servings,
          difficulty: 'easy',
          ingredients: ingredients,
          instructions: [
            '1. OFEN VORHEIZEN: Den Backofen auf die höchste Temperatur (meist 250°C Ober-/Unterhitze oder 230°C Umluft) vorheizen. WICHTIG: Der Ofen muss richtig heiß sein für eine knusprige Pizza! Mindestens 15 Minuten vorheizen lassen.',
            '2. PIZZA AUSPACKEN: Die Tiefkühl-Pizza aus der Verpackung nehmen. Folie komplett entfernen. Falls vorhanden, einen Pizzastein oder ein Backblech mit in den Ofen geben zum Vorheizen - das macht die Pizza extra knusprig!',
            '3. ZUSÄTZLICHEN BELAG VORBEREITEN (Optional): Wenn Sie Salami hinzufügen möchten, diese in dünne Scheiben schneiden. Andere Extra-Zutaten wie Oliven, Champignons oder Zwiebeln ebenfalls klein schneiden.',
            '4. PIZZA BELEGEN: Die vorbereitete Pizza auf ein Backpapier legen. Wenn gewünscht, jetzt die Salami-Scheiben gleichmäßig auf der Pizza verteilen. Nicht zu viel Belag hinzufügen, sonst wird der Boden nicht knusprig!',
            '5. BACKEN: Die Pizza auf der untersten Schiene in den vorgeheizten Ofen schieben (oder direkt auf den heißen Pizzastein, falls vorhanden). Backzeit laut Packungsanleitung beachten, meist 10-14 Minuten. Die Pizza ist fertig, wenn der Käse goldbraun und blasig ist und der Rand schön knusprig.',
            '6. RUCOLA VORBEREITEN: Während die Pizza backt, den Rucola gründlich waschen und in einer Salatschleuder oder mit Küchenpapier trocknen. In eine Schüssel geben und mit einem Spritzer Olivenöl, etwas Zitronensaft, Salz und Pfeffer würzen.',
            '7. PARMESAN HOBELN: Den Parmesan mit einem Sparschäler in dünne Späne hobeln. Alternativ fein reiben.',
            '8. PIZZA ENTNEHMEN: Wenn die Pizza fertig ist, vorsichtig aus dem Ofen nehmen. ACHTUNG: Sehr heiß! Am besten einen Pizzaheber oder breite Pfannenwender verwenden.',
            '9. FINALES TOPPING: Die Pizza auf ein Schneidebrett legen. Den gewürzten Rucola großzügig auf der heißen Pizza verteilen - er wird durch die Hitze leicht welken. Die Parmesan-Späne darüber streuen.',
            '10. SERVIEREN: Die Pizza mit einem Pizzaschneider oder scharfen Messer in Stücke schneiden. Sofort servieren, solange sie noch heiß und knusprig ist. Optional mit einem guten Olivenöl beträufeln und mit Chili-Flocken würzen!',
          ],
          tags: ['schnell', 'italienisch', 'pizza', 'kaufland angebote'],
          nutrition: const NutritionInfo(calories: 720, protein: 32, carbs: 68, fat: 36),
        ),
        dealIngredients: dealIngredients,
        totalCost: totalCost,
        totalSavings: totalSavings,
      ));
    }

    // ========== RECIPE 6: Himbeer-Dessert ==========
    final raspberryDeal = findMatchingDeal('himbeeren');

    if (raspberryDeal != null) {
      const servings = 4;
      final ingredients = <RecipeIngredient>[
        RecipeIngredient(name: raspberryDeal.productName, quantity: '300', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Mascarpone', quantity: '250', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Sahne', quantity: '200', unit: 'ml', isAvailable: true),
        const RecipeIngredient(name: 'Puderzucker', quantity: '50', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Löffelbiskuits', quantity: '12', unit: 'Stück', isAvailable: true),
      ];

      final raspUsed = 300.0;

      final dealIngredients = <DealIngredient>[
        DealIngredient(
          ingredient: ingredients[0],
          deal: raspberryDeal,
          storeName: raspberryDeal.storeName,
          price: calculateActualPrice(raspberryDeal, raspUsed, 'g'),
          savings: calculateActualSavings(raspberryDeal, raspUsed, 'g'),
        ),
      ];

      final totalSavings = dealIngredients.fold<double>(0, (sum, di) => sum + (di.savings ?? 0));
      final totalCost = dealIngredients.fold<double>(0, (sum, di) => sum + di.price) + 5.50;

      dealRecipes.add(DealRecipe(
        recipe: Recipe(
          id: _uuid.v4(),
          name: 'Himbeer-Mascarpone Traum',
          description: 'Luftig-cremiges Dessert mit frischen Himbeeren und Mascarpone - elegant, lecker und einfach zuzubereiten!',
          imageUrl: 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=800',
          prepTime: 20,
          cookTime: 0,
          servings: servings,
          difficulty: 'easy',
          ingredients: ingredients,
          instructions: [
            '1. HIMBEEREN VORBEREITEN: Die frischen Himbeeren vorsichtig aus der Packung nehmen. Etwa 2/3 der Himbeeren (200g) in eine Schüssel geben. Die restlichen Himbeeren (100g) für die Dekoration beiseite stellen.',
            '2. HIMBEER-KOMPOTT: Die 200g Himbeeren in einem kleinen Topf mit 2 EL Zucker und 2 EL Wasser bei mittlerer Hitze 5 Minuten köcheln lassen, dabei gelegentlich umrühren. Die Himbeeren sollten weich werden und Saft abgeben. Vom Herd nehmen und komplett abkühlen lassen.',
            '3. SAHNE SCHLAGEN: Die kalte Sahne in eine hohe Schüssel geben. WICHTIG: Schüssel und Schneebesen sollten gut gekühlt sein! Die Sahne mit dem Handmixer oder Schneebesen steif schlagen. Sie ist fertig, wenn sie feste Spitzen bildet und nicht mehr aus der Schüssel läuft.',
            '4. MASCARPONE-CREME: In einer separaten Schüssel den Mascarpone mit dem Puderzucker glatt rühren. Mit einem Schneebesen oder Löffel arbeiten, nicht mit dem Mixer - Mascarpone wird sonst flüssig!',
            '5. CREME KOMBINIEREN: Die steif geschlagene Sahne vorsichtig unter die Mascarpone-Masse heben. Mit einem Teigschaber von unten nach oben falten, damit die Luftigkeit erhalten bleibt. Die Creme sollte luftig und locker sein.',
            '6. GLÄSER VORBEREITEN: 4 Dessertgläser oder Schälchen bereitstellen. Löffelbiskuits in kleine Stücke brechen (oder ganz lassen, je nach Glasgröße).',
            '7. SCHICHTEN: In jedes Glas zuerst ein paar Löffelbiskuit-Stücke geben. Dann eine Schicht vom abgekühlten Himbeer-Kompott darauf verteilen. Anschließend eine großzügige Schicht Mascarpone-Creme. Diesen Vorgang wiederholen, bis die Gläser voll sind.',
            '8. FINALE SCHICHT: Die Desserts mit der Mascarpone-Creme abschließen. Die Oberfläche mit einem Löffel glatt streichen.',
            '9. DEKORATION: Die reservierten frischen Himbeeren auf der Mascarpone-Creme verteilen. Optional mit etwas Puderzucker bestäuben und mit Minzblättern garnieren.',
            '10. KÜHLEN & SERVIEREN: Die Desserts mindestens 2 Stunden (besser 4 Stunden oder über Nacht) im Kühlschrank durchziehen lassen. Die Löffelbiskuits saugen sich mit der Feuchtigkeit voll und das Dessert bekommt eine wunderbare Konsistenz. Gut gekühlt servieren!',
          ],
          tags: ['dessert', 'vegetarisch', 'ohne-backen', 'beeren', 'kaufland angebote'],
          nutrition: const NutritionInfo(calories: 420, protein: 6, carbs: 38, fat: 28),
        ),
        dealIngredients: dealIngredients,
        totalCost: totalCost,
        totalSavings: totalSavings,
      ));
    }

    // ========== RECIPE 7: Würstchen-Pfanne ==========
    final sausageDeal = findMatchingDeal('würstchen') ?? findMatchingDeal('hot dog');

    if (sausageDeal != null) {
      const servings = 3;
      final ingredients = <RecipeIngredient>[
        RecipeIngredient(name: sausageDeal.productName, quantity: '6', unit: 'Stück', isAvailable: true),
        const RecipeIngredient(name: 'Kartoffeln', quantity: '600', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Paprika (rot/gelb)', quantity: '2', unit: 'Stück', isAvailable: true),
        const RecipeIngredient(name: 'Zwiebeln', quantity: '2', unit: 'Stück', isAvailable: true),
        const RecipeIngredient(name: 'Ketchup', quantity: '3', unit: 'EL', isAvailable: true),
      ];

      final sausageUsed = 360.0;

      final dealIngredients = <DealIngredient>[
        DealIngredient(
          ingredient: ingredients[0],
          deal: sausageDeal,
          storeName: sausageDeal.storeName,
          price: calculateActualPrice(sausageDeal, sausageUsed, 'g'),
          savings: calculateActualSavings(sausageDeal, sausageUsed, 'g'),
        ),
      ];

      final totalSavings = dealIngredients.fold<double>(0, (sum, di) => sum + (di.savings ?? 0));
      final totalCost = dealIngredients.fold<double>(0, (sum, di) => sum + di.price) + 2.50;

      dealRecipes.add(DealRecipe(
        recipe: Recipe(
          id: _uuid.v4(),
          name: 'Bunte Würstchen-Gemüse-Pfanne',
          description: 'Deftige Würstchen-Pfanne mit knusprigen Bratkartoffeln und buntem Gemüse - ein Familien-Liebling der schnell geht!',
          imageUrl: 'https://images.unsplash.com/photo-1612392062798-2dbae808c0e1?w=800',
          prepTime: 15,
          cookTime: 25,
          servings: servings,
          difficulty: 'easy',
          ingredients: ingredients,
          instructions: [
            '1. KARTOFFELN VORBEREITEN: Die Kartoffeln gründlich waschen (schälen optional - mit Schale sind sie rustikaler). In mundgerechte Würfel schneiden (ca. 1,5 cm). TIPP: Alle Würfel sollten ungefähr gleich groß sein, damit sie gleichmäßig gar werden.',
            '2. KARTOFFELN VORKOCHEN: Die Kartoffelwürfel in einen Topf mit gesalzenem Wasser geben. Zum Kochen bringen und 5-7 Minuten vorkochen, bis sie halb gar sind (sie sollten noch Biss haben). Abgießen und gut abtropfen lassen. WICHTIG: Die Kartoffeln sollten trocken sein fürs Anbraten!',
            '3. GEMÜSE SCHNEIDEN: Während die Kartoffeln kochen, die Paprika waschen, halbieren, Kerne entfernen und in Streifen schneiden. Die Zwiebeln schälen und in grobe Ringe oder Spalten schneiden.',
            '4. WÜRSTCHEN VORBEREITEN: Die Würstchen aus der Packung nehmen. Je nach Vorliebe ganz lassen oder schräg in 2-3 cm dicke Stücke schneiden (geschnitten werden sie besonders knusprig).',
            '5. KARTOFFELN ANBRATEN: In einer großen Pfanne 3 EL Öl erhitzen. Die vorgekochten Kartoffelwürfel hineingeben und bei mittlerer bis hoher Hitze 10-12 Minuten braten. Gelegentlich wenden, damit sie von allen Seiten goldbraun und knusprig werden. Mit Salz, Pfeffer und optional Paprikapulver würzen.',
            '6. GEMÜSE HINZUFÜGEN: Die Zwiebelringe zur Pfanne geben und weitere 3 Minuten mitbraten, bis sie glasig werden. Dann die Paprikastreifen hinzufügen und weitere 3-4 Minuten braten.',
            '7. WÜRSTCHEN BRATEN: Die Würstchen (ganz oder geschnitten) in die Pfanne geben. Alles gut durchmischen und weitere 5-7 Minuten braten, bis die Würstchen heiß und an den Rändern leicht gebräunt sind.',
            '8. WÜRZEN: Mit Salz, Pfeffer und einer Prise geräuchertem Paprikapulver abschmecken. Wer es mag, kann jetzt 2-3 EL Ketchup oder BBQ-Sauce unterrühren - das gibt eine schöne glasierte Note!',
            '9. FINALE WÜRZE (Optional): Für extra Geschmack einen Spritzer Worcestersauce oder einen TL Senf unterrühren. Frische gehackte Petersilie oder Schnittlauch darüber streuen.',
            '10. SERVIEREN: Die dampfende Würstchen-Pfanne direkt aus der Pfanne servieren (spart Abwasch!) oder auf Teller verteilen. Dazu passt Ketchup, Senf oder ein frischer grüner Salat. Guten Appetit!',
          ],
          tags: ['deftig', 'schnell', 'kinderfreundlich', 'pfannengericht', 'kaufland angebote'],
          nutrition: const NutritionInfo(calories: 620, protein: 24, carbs: 52, fat: 34),
        ),
        dealIngredients: dealIngredients,
        totalCost: totalCost,
        totalSavings: totalSavings,
      ));
    }

    // ========== RECIPE 8: Frischer Clementinen-Salat ==========
    if (clementineDeal != null) {
      const servings = 4;
      final ingredients = <RecipeIngredient>[
        RecipeIngredient(name: clementineDeal.productName, quantity: '6', unit: 'Stück', isAvailable: true),
        const RecipeIngredient(name: 'Feta-Käse', quantity: '150', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Rucola oder Babyspinat', quantity: '100', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Walnüsse', quantity: '50', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Olivenöl', quantity: '4', unit: 'EL', isAvailable: true),
        const RecipeIngredient(name: 'Honig', quantity: '1', unit: 'EL', isAvailable: true),
      ];

      final clemUsed = 450.0; // ~6 clementines

      final dealIngredients = <DealIngredient>[
        DealIngredient(
          ingredient: ingredients[0],
          deal: clementineDeal,
          storeName: clementineDeal.storeName,
          price: calculateActualPrice(clementineDeal, clemUsed, 'g'),
          savings: calculateActualSavings(clementineDeal, clemUsed, 'g'),
        ),
      ];

      final totalSavings = dealIngredients.fold<double>(0, (sum, di) => sum + (di.savings ?? 0));
      final totalCost = dealIngredients.fold<double>(0, (sum, di) => sum + di.price) + 4.50;

      dealRecipes.add(DealRecipe(
        recipe: Recipe(
          id: _uuid.v4(),
          name: 'Winterlicher Clementinen-Feta-Salat',
          description: 'Frischer Salat mit süßen Clementinen, cremigem Feta und gerösteten Walnüssen - eine perfekte Kombination aus süß und salzig!',
          imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800',
          prepTime: 15,
          cookTime: 5,
          servings: servings,
          difficulty: 'easy',
          ingredients: ingredients,
          instructions: [
            '1. WALNÜSSE RÖSTEN: Die Walnüsse in einer trockenen Pfanne (ohne Öl!) bei mittlerer Hitze 3-5 Minuten rösten. Dabei häufig schwenken, damit sie nicht verbrennen. Sie sind fertig, wenn sie duften und leicht gebräunt sind. Aus der Pfanne nehmen und abkühlen lassen, dann grob hacken.',
            '2. CLEMENTINEN SCHÄLEN: Die Clementinen vorsichtig schälen. Die weiße Haut so gut wie möglich entfernen, da sie bitter schmecken kann. Die Clementinen in Scheiben schneiden (ca. 5mm dick) oder in einzelne Spalten teilen.',
            '3. SALAT WASCHEN: Den Rucola oder Babyspinat in einer Schüssel mit kaltem Wasser gründlich waschen. In einer Salatschleuder trocknen oder vorsichtig mit Küchenpapier abtupfen. Trockener Salat ist wichtig, damit das Dressing besser haftet!',
            '4. FETA VORBEREITEN: Den Feta-Käse aus der Packung nehmen und in etwa 1,5 cm große Würfel schneiden. Alternativ mit einer Gabel grob zerbröckeln - das sieht rustikaler aus.',
            '5. DRESSING MIXEN: In einem kleinen Glas oder einer Schüssel das Olivenöl, den Honig, 2 EL Zitronensaft (oder weißen Balsamico), eine Prise Salz und frisch gemahlenen Pfeffer mit einer Gabel oder einem Schneebesen kräftig verquirlen, bis alles gut vermischt ist. TIPP: Ein Glas mit Deckel nehmen und kräftig schütteln - so emulgiert das Dressing perfekt!',
            '6. SALAT ANRICHTEN: Den gewaschenen Rucola/Spinat auf einer großen Servierplatte oder vier Tellern verteilen. Die Clementinen-Scheiben darauf arrangieren.',
            '7. TOPPINGS: Die Feta-Würfel über den Salat verteilen. Die gerösteten, gehackten Walnüsse darüber streuen.',
            '8. DRESSING ZUGEBEN: Das Honig-Zitronen-Dressing gleichmäßig über den gesamten Salat träufeln. WICHTIG: Nicht zu früh! Das Dressing erst kurz vor dem Servieren zugeben, damit der Salat nicht zusammenfällt.',
            '9. OPTIONAL VERFEINERN: Für extra Geschmack können Sie noch frische Minzblätter zupfen und darüber streuen. Ein Hauch von Chili-Flocken gibt dem Salat eine pikante Note. Granatapfelkerne passen ebenfalls hervorragend!',
            '10. SERVIEREN: Sofort servieren, solange der Salat noch frisch und knackig ist. Der Salat passt perfekt als leichte Vorspeise, als Beilage zu Fleisch oder als eigenständiges leichtes Mittagessen. Guten Appetit!',
          ],
          tags: ['salat', 'vegetarisch', 'winter', 'gesund', 'schnell', 'kaufland angebote'],
          nutrition: const NutritionInfo(calories: 280, protein: 8, carbs: 22, fat: 18),
        ),
        dealIngredients: dealIngredients,
        totalCost: totalCost,
        totalSavings: totalSavings,
      ));
    }

    // ========== RECIPE 9: Protein-Power Bowl mit Hähnchen ==========
    final chickenDeal = findMatchingDeal('hähnchen');

    if (chickenDeal != null) {
      const servings = 2;
      final ingredients = <RecipeIngredient>[
        RecipeIngredient(name: chickenDeal.productName, quantity: '300', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Quinoa', quantity: '150', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Avocado', quantity: '1', unit: 'Stück', isAvailable: true),
        const RecipeIngredient(name: 'Cherry-Tomaten', quantity: '150', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Spinat', quantity: '100', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Olivenöl', quantity: '2', unit: 'EL', isAvailable: true),
      ];

      final chickenUsed = 300.0;

      final dealIngredients = <DealIngredient>[
        DealIngredient(
          ingredient: ingredients[0],
          deal: chickenDeal,
          storeName: chickenDeal.storeName,
          price: calculateActualPrice(chickenDeal, chickenUsed, 'g'),
          savings: calculateActualSavings(chickenDeal, chickenUsed, 'g'),
        ),
      ];

      if (tomatoDeal != null) {
        ingredients[3] = RecipeIngredient(name: tomatoDeal.productName, quantity: '150', unit: 'g', isAvailable: true);
        final tomatoUsed = 150.0;
        dealIngredients.add(DealIngredient(
          ingredient: ingredients[3],
          deal: tomatoDeal,
          storeName: tomatoDeal.storeName,
          price: calculateActualPrice(tomatoDeal, tomatoUsed, 'g'),
          savings: calculateActualSavings(tomatoDeal, tomatoUsed, 'g'),
        ));
      }

      final totalSavings = dealIngredients.fold<double>(0, (sum, di) => sum + (di.savings ?? 0));
      final totalCost = dealIngredients.fold<double>(0, (sum, di) => sum + di.price) + 4.50;

      dealRecipes.add(DealRecipe(
        recipe: Recipe(
          id: _uuid.v4(),
          name: 'Protein-Power Bowl mit Hähnchen',
          description: 'High-Protein Bowl mit saftigem Hähnchen, Quinoa, Avocado und frischem Gemüse - ideal nach dem Training!',
          imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800',
          prepTime: 15,
          cookTime: 20,
          servings: servings,
          difficulty: 'easy',
          ingredients: ingredients,
          instructions: [
            '1. QUINOA VORBEREITEN: Die Quinoa in einem feinen Sieb unter kaltem Wasser gründlich abspülen, bis das Wasser klar ist. Dies entfernt die bitteren Saponine.',
            '2. QUINOA KOCHEN: Quinoa mit der doppelten Menge Wasser (300ml) in einen Topf geben. Eine Prise Salz hinzufügen, aufkochen und dann bei niedriger Hitze zugedeckt 15 Minuten köcheln lassen. Vom Herd nehmen und 5 Minuten ziehen lassen, dann mit einer Gabel auflockern.',
            '3. HÄHNCHEN WÜRZEN: Die Hähnchenbrust in mundgerechte Würfel schneiden. Mit Salz, Pfeffer, Paprikapulver und etwas Knoblauchpulver würzen. TIPP: Für extra Geschmack kannst du das Hähnchen 10 Minuten marinieren lassen.',
            '4. HÄHNCHEN BRATEN: 1 EL Olivenöl in einer Pfanne erhitzen. Das Hähnchen bei mittlerer bis hoher Hitze 6-8 Minuten von allen Seiten goldbraun anbraten, bis es durchgegart ist. Die Kerntemperatur sollte 74°C betragen.',
            '5. GEMÜSE VORBEREITEN: Während das Hähnchen brät, die Cherry-Tomaten halbieren. Den Spinat waschen und trocken schleudern. Die Avocado halbieren, entkernen und in Scheiben schneiden.',
            '6. SPINAT WILTEN: In der gleichen Pfanne (nach dem Hähnchen) den Spinat mit etwas Knoblauch 1-2 Minuten anbraten, bis er zusammenfällt. Mit Salz und Pfeffer würzen.',
            '7. DRESSING MIXEN: In einer kleinen Schüssel 1 EL Olivenöl, 1 EL Zitronensaft, 1 TL Honig, Salz und Pfeffer vermischen. Optional: 1 TL Dijon-Senf für extra Würze.',
            '8. BOWL ZUSAMMENSTELLEN: Die gekochte Quinoa auf zwei Schüsseln verteilen. Das gebratene Hähnchen darauf arrangieren.',
            '9. TOPPINGS HINZUFÜGEN: Den gebratenen Spinat, die halbierten Cherry-Tomaten und die Avocado-Scheiben auf der Bowl verteilen. Für extra Protein kannst du noch ein gekochtes Ei hinzufügen.',
            '10. FINALE TOUCHES: Das Dressing über die Bowl träufeln. Optional mit gerösteten Kürbiskernen, Sesam oder frischem Koriander garnieren. Sofort genießen! Diese Bowl liefert ca. 45g Protein pro Portion.',
          ],
          tags: ['Fitness', 'High-Protein', 'gesund', 'Bowl', 'kaufland angebote', 'Low-Carb möglich'],
          nutrition: const NutritionInfo(calories: 520, protein: 45, carbs: 38, fat: 22),
        ),
        dealIngredients: dealIngredients,
        totalCost: totalCost,
        totalSavings: totalSavings,
      ));
    }

    // ========== RECIPE 10: Lachs-Avocado Power Salat ==========
    final salmonDeal = findMatchingDeal('lachs');

    if (salmonDeal != null) {
      const servings = 2;
      final ingredients = <RecipeIngredient>[
        RecipeIngredient(name: salmonDeal.productName, quantity: '250', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Avocado', quantity: '1', unit: 'Stück', isAvailable: true),
        const RecipeIngredient(name: 'Rucola', quantity: '100', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Gurke', quantity: '1', unit: 'Stück', isAvailable: true),
        const RecipeIngredient(name: 'Zitrone', quantity: '1', unit: 'Stück', isAvailable: true),
        const RecipeIngredient(name: 'Olivenöl', quantity: '3', unit: 'EL', isAvailable: true),
      ];

      final salmonUsed = 250.0;

      final dealIngredients = <DealIngredient>[
        DealIngredient(
          ingredient: ingredients[0],
          deal: salmonDeal,
          storeName: salmonDeal.storeName,
          price: calculateActualPrice(salmonDeal, salmonUsed, 'g'),
          savings: calculateActualSavings(salmonDeal, salmonUsed, 'g'),
        ),
      ];

      final totalSavings = dealIngredients.fold<double>(0, (sum, di) => sum + (di.savings ?? 0));
      final totalCost = dealIngredients.fold<double>(0, (sum, di) => sum + di.price) + 3.50;

      dealRecipes.add(DealRecipe(
        recipe: Recipe(
          id: _uuid.v4(),
          name: 'Lachs-Avocado Power Salat',
          description: 'Omega-3-reicher Lachs mit cremiger Avocado und frischem Salat - perfekt für Muskelaufbau und gesunde Fette!',
          imageUrl: 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=800',
          prepTime: 10,
          cookTime: 12,
          servings: servings,
          difficulty: 'easy',
          ingredients: ingredients,
          instructions: [
            '1. LACHS VORBEREITEN: Den Lachs unter kaltem Wasser abspülen und mit Küchenpapier trocken tupfen. In zwei gleich große Filets portionieren. Mit Salz, Pfeffer und etwas Zitronensaft würzen.',
            '2. LACHS MARINIEREN: Die Lachsfilets auf beiden Seiten mit etwas Olivenöl bestreichen. Optional: Mit frischem Dill oder Thymian würzen. 5 Minuten ziehen lassen.',
            '3. SALAT WASCHEN: Den Rucola in einer Schüssel mit kaltem Wasser gründlich waschen und in einer Salatschleuder oder mit Küchenpapier trocknen. Trockener Salat ist wichtig für ein gutes Dressing!',
            '4. GEMÜSE SCHNEIDEN: Die Gurke in dünne Scheiben schneiden oder mit einem Sparschäler in lange Streifen hobeln. Die Avocado halbieren, entkernen und in Scheiben oder Würfel schneiden.',
            '5. LACHS BRATEN: Eine beschichtete Pfanne auf mittlerer bis hoher Hitze erhitzen. Den Lachs mit der Hautseite nach unten in die Pfanne legen. 4-5 Minuten braten, bis die Haut knusprig ist.',
            '6. LACHS WENDEN: Den Lachs vorsichtig wenden und weitere 3-4 Minuten braten, bis er durchgegart aber innen noch leicht glasig ist. TIPP: Lachs sollte eine Kerntemperatur von 55-60°C haben für optimale Textur.',
            '7. DRESSING ZUBEREITEN: In einer kleinen Schüssel 2 EL Olivenöl, 2 EL frischen Zitronensaft, 1 TL Honig, 1 TL Dijon-Senf, Salz und Pfeffer verquirlen. Mit einem Schneebesen kräftig rühren, bis das Dressing emulgiert ist.',
            '8. SALAT ANRICHTEN: Den Rucola und die Gurkenscheiben auf zwei Tellern verteilen. Die Avocado-Scheiben darauf arrangieren.',
            '9. LACHS PLATZIEREN: Den gebratenen Lachs vorsichtig auf dem Salat platzieren. Du kannst ihn ganz lassen oder in Stücke teilen.',
            '10. SERVIEREN: Das Dressing über den Salat träufeln. Optional mit gerösteten Pinienkernen, Sesam oder frischem Dill garnieren. Mit Zitronenspalten servieren. Diese Mahlzeit liefert 35g Protein und wertvolle Omega-3-Fettsäuren!',
          ],
          tags: ['Fitness', 'High-Protein', 'Omega-3', 'Low-Carb', 'gesund', 'kaufland angebote'],
          nutrition: const NutritionInfo(calories: 450, protein: 35, carbs: 8, fat: 32),
        ),
        dealIngredients: dealIngredients,
        totalCost: totalCost,
        totalSavings: totalSavings,
      ));
    }

    // ========== RECIPE 11: Roastbeef Power Salat ==========
    final roastbeefDeal = findMatchingDeal('roastbeef');

    if (roastbeefDeal != null) {
      const servings = 2;
      final ingredients = <RecipeIngredient>[
        RecipeIngredient(name: roastbeefDeal.productName, quantity: '200', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Multicolor-Salat', quantity: '200', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Cherry-Tomaten', quantity: '150', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Parmesan', quantity: '40', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Walnüsse', quantity: '30', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Balsamico-Essig', quantity: '2', unit: 'EL', isAvailable: true),
      ];

      final roastbeefUsed = 200.0;

      final dealIngredients = <DealIngredient>[
        DealIngredient(
          ingredient: ingredients[0],
          deal: roastbeefDeal,
          storeName: roastbeefDeal.storeName,
          price: calculateActualPrice(roastbeefDeal, roastbeefUsed, 'g'),
          savings: calculateActualSavings(roastbeefDeal, roastbeefUsed, 'g'),
        ),
      ];

      if (tomatoDeal != null) {
        ingredients[2] = RecipeIngredient(name: tomatoDeal.productName, quantity: '150', unit: 'g', isAvailable: true);
        final tomatoUsed = 150.0;
        dealIngredients.add(DealIngredient(
          ingredient: ingredients[2],
          deal: tomatoDeal,
          storeName: tomatoDeal.storeName,
          price: calculateActualPrice(tomatoDeal, tomatoUsed, 'g'),
          savings: calculateActualSavings(tomatoDeal, tomatoUsed, 'g'),
        ));
      }

      final totalSavings = dealIngredients.fold<double>(0, (sum, di) => sum + (di.savings ?? 0));
      final totalCost = dealIngredients.fold<double>(0, (sum, di) => sum + di.price) + 3.00;

      dealRecipes.add(DealRecipe(
        recipe: Recipe(
          id: _uuid.v4(),
          name: 'Roastbeef Power Salat',
          description: 'Proteinreicher Salat mit zartem Roastbeef, Parmesan und Walnüssen - ein echter Fitness-Klassiker!',
          imageUrl: 'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=800',
          prepTime: 15,
          cookTime: 0,
          servings: servings,
          difficulty: 'easy',
          ingredients: ingredients,
          instructions: [
            '1. WALNÜSSE RÖSTEN: Die Walnüsse in einer trockenen Pfanne ohne Öl bei mittlerer Hitze 3-4 Minuten rösten. Dabei häufig schwenken, damit sie nicht verbrennen. Sie sind fertig, wenn sie duften und leicht gebräunt sind. Abkühlen lassen und grob hacken.',
            '2. SALAT VORBEREITEN: Den Multicolor-Salat gründlich waschen und in einer Salatschleuder trocknen. In eine große Schüssel geben. Falls nicht verfügbar, kannst du eine Mischung aus Rucola, Lollo Rosso und Eisbergsalat verwenden.',
            '3. TOMATEN SCHNEIDEN: Die Cherry-Tomaten waschen und halbieren. Größere Tomaten in Achtel schneiden. Die Tomaten zum Salat geben.',
            '4. ROASTBEEF SCHNEIDEN: Das Roastbeef in dünne Streifen oder mundgerechte Stücke schneiden. TIPP: Für die zarteste Textur schneide gegen die Fleischfaser!',
            '5. PARMESAN HOBELN: Den Parmesan mit einem Sparschäler in dünne Späne hobeln. Dies sieht eleganter aus als geriebener Käse und schmeckt intensiver.',
            '6. DRESSING MIXEN: In einer kleinen Schüssel 3 EL Olivenöl, 2 EL Balsamico-Essig, 1 TL Dijon-Senf, 1 gepresste Knoblauchzehe, Salz und Pfeffer verquirlen. Optional: 1 TL Honig für eine leichte Süße.',
            '7. SALAT MARINIEREN: Das Dressing über den Salat und die Tomaten gießen. Vorsichtig mit den Händen oder zwei Löffeln vermengen, damit alle Blätter gleichmäßig bedeckt sind.',
            '8. SALAT ANRICHTEN: Den marinierten Salat auf zwei Teller oder in zwei Schüsseln verteilen. Als Basis für die weiteren Zutaten.',
            '9. TOPPINGS HINZUFÜGEN: Das Roastbeef auf dem Salat verteilen. Die gerösteten Walnüsse darüber streuen. Die Parmesan-Späne großzügig über den Salat geben.',
            '10. FINALE TOUCHES: Mit frisch gemahlenem schwarzen Pfeffer würzen. Optional mit frischen Kräutern wie Basilikum oder Petersilie garnieren. Sofort servieren! Dieser Salat liefert 32g Protein pro Portion und ist perfekt für die Low-Carb-Ernährung.',
          ],
          tags: ['Fitness', 'High-Protein', 'Low-Carb', 'schnell', 'gesund', 'kaufland angebote'],
          nutrition: const NutritionInfo(calories: 380, protein: 32, carbs: 6, fat: 26),
        ),
        dealIngredients: dealIngredients,
        totalCost: totalCost,
        totalSavings: totalSavings,
      ));
    }

    // ========== RECIPE 12: Beeren-Protein Dessert ==========
    if (raspberryDeal != null) {
      const servings = 2;
      final ingredients = <RecipeIngredient>[
        RecipeIngredient(name: raspberryDeal.productName, quantity: '200', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Griechischer Joghurt', quantity: '300', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Erdnüsse', quantity: '40', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Honig', quantity: '2', unit: 'EL', isAvailable: true),
        const RecipeIngredient(name: 'Chiasamen', quantity: '1', unit: 'EL', isAvailable: true),
      ];

      final raspUsed = 200.0;

      final dealIngredients = <DealIngredient>[
        DealIngredient(
          ingredient: ingredients[0],
          deal: raspberryDeal,
          storeName: raspberryDeal.storeName,
          price: calculateActualPrice(raspberryDeal, raspUsed, 'g'),
          savings: calculateActualSavings(raspberryDeal, raspUsed, 'g'),
        ),
      ];

      final totalSavings = dealIngredients.fold<double>(0, (sum, di) => sum + (di.savings ?? 0));
      final totalCost = dealIngredients.fold<double>(0, (sum, di) => sum + di.price) + 3.50;

      dealRecipes.add(DealRecipe(
        recipe: Recipe(
          id: _uuid.v4(),
          name: 'Beeren-Protein Dessert',
          description: 'High-Protein Dessert mit frischen Himbeeren, griechischem Joghurt und Erdnüssen - lecker und gesund!',
          imageUrl: 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=800',
          prepTime: 10,
          cookTime: 0,
          servings: servings,
          difficulty: 'easy',
          ingredients: ingredients,
          instructions: [
            '1. HIMBEEREN VORBEREITEN: Die frischen Himbeeren vorsichtig aus der Packung nehmen. Etwa die Hälfte (100g) für das Topping beiseite stellen. Die andere Hälfte in eine kleine Schüssel geben.',
            '2. HIMBEER-KOMPOTT: Die 100g Himbeeren mit 1 EL Honig in einer kleinen Schüssel vorsichtig zerdrücken (mit einer Gabel). Das Kompott sollte noch Stückchen enthalten. Optional: 1 TL Zitronensaft hinzufügen für frische Säure.',
            '3. ERDNÜSSE RÖSTEN: Die Erdnüsse in einer trockenen Pfanne ohne Öl 2-3 Minuten rösten, bis sie duften. Abkühlen lassen und grob hacken. TIPP: Geröstete Erdnüsse schmecken intensiver!',
            '4. JOGHURT WÜRZEN: Den griechischen Joghurt in eine Schüssel geben. 1 EL Honig unterrühren. Optional: Eine Prise Vanilleextrakt für extra Geschmack hinzufügen.',
            '5. CHIASAMEN VORBEREITEN: Die Chiasamen in 3 EL Wasser einweichen und 5 Minuten quellen lassen. Dies macht sie bekömmlicher und sie bilden ein Gel.',
            '6. SCHICHTEN BEGINNEN: Zwei Dessertgläser oder Schälchen bereitstellen. Eine Schicht vom Honig-Joghurt als Basis in jedes Glas geben.',
            '7. KOMPOTT SCHICHTEN: Einen Löffel vom Himbeer-Kompott auf die Joghurtschicht geben. Leicht verteilen.',
            '8. WEITERE SCHICHTEN: Abwechselnd Joghurt und Kompott schichten, bis die Gläser fast voll sind. Mit einer Joghurtschicht abschließen.',
            '9. TOPPINGS HINZUFÜGEN: Die frischen Himbeeren auf die Joghurtschicht setzen. Die gerösteten, gehackten Erdnüsse darüber streuen. Die gequollenen Chiasamen darüber verteilen.',
            '10. SERVIEREN: Optional mit einem Minzblatt garnieren. Sofort servieren oder bis zu 2 Stunden im Kühlschrank durchziehen lassen. Dieses Dessert liefert 20g Protein pro Portion - perfekt nach dem Training!',
          ],
          tags: ['Fitness', 'High-Protein', 'dessert', 'gesund', 'ohne-backen', 'kaufland angebote'],
          nutrition: const NutritionInfo(calories: 320, protein: 20, carbs: 28, fat: 14),
        ),
        dealIngredients: dealIngredients,
        totalCost: totalCost,
        totalSavings: totalSavings,
      ));
    }

    // ========== RECIPE 13: Thunfisch-Protein Bowl ==========
    final tunaDeal = findMatchingDeal('thunfisch');

    if (tunaDeal != null) {
      const servings = 2;
      final ingredients = <RecipeIngredient>[
        RecipeIngredient(name: tunaDeal.productName, quantity: '300', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Kichererbsen', quantity: '240', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Paprika (rot)', quantity: '1', unit: 'Stück', isAvailable: true),
        const RecipeIngredient(name: 'Mais', quantity: '150', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Rote Zwiebel', quantity: '1', unit: 'Stück', isAvailable: true),
        const RecipeIngredient(name: 'Zitrone', quantity: '1', unit: 'Stück', isAvailable: true),
      ];

      final tunaUsed = 300.0;

      final dealIngredients = <DealIngredient>[
        DealIngredient(
          ingredient: ingredients[0],
          deal: tunaDeal,
          storeName: tunaDeal.storeName,
          price: calculateActualPrice(tunaDeal, tunaUsed, 'g'),
          savings: calculateActualSavings(tunaDeal, tunaUsed, 'g'),
        ),
      ];

      final totalSavings = dealIngredients.fold<double>(0, (sum, di) => sum + (di.savings ?? 0));
      final totalCost = dealIngredients.fold<double>(0, (sum, di) => sum + di.price) + 2.50;

      dealRecipes.add(DealRecipe(
        recipe: Recipe(
          id: _uuid.v4(),
          name: 'Thunfisch-Protein Bowl',
          description: 'Proteinreiche Bowl mit Thunfisch, Kichererbsen und buntem Gemüse - perfekt für Meal-Prep!',
          imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800',
          prepTime: 15,
          cookTime: 0,
          servings: servings,
          difficulty: 'easy',
          ingredients: ingredients,
          instructions: [
            '1. THUNFISCH VORBEREITEN: Den Thunfisch aus der Dose oder Packung nehmen und gut abtropfen lassen. Falls in Öl eingelegt, das Öl abgießen. Mit einer Gabel in einer Schüssel grob zerteilen.',
            '2. KICHERERBSEN SPÜLEN: Die Kichererbsen (aus der Dose) in einem Sieb unter kaltem Wasser gründlich abspülen. Gut abtropfen lassen. TIPP: Spülen reduziert Natrium und macht sie bekömmlicher.',
            '3. GEMÜSE SCHNEIDEN: Die Paprika waschen, halbieren, Kerne entfernen und in kleine Würfel schneiden. Die rote Zwiebel schälen und in feine Würfel schneiden.',
            '4. MAIS VORBEREITEN: Falls Mais aus der Dose verwendet wird, gut abtropfen lassen. Tiefgekühlten Mais vorher auftauen lassen.',
            '5. ZWIEBEL ENTSCHÄRFEN: Die gewürfelten Zwiebeln für 5 Minuten in kaltes Wasser legen. Das nimmt die Schärfe und macht sie bekömmlicher. Danach gut abtropfen lassen.',
            '6. DRESSING MIXEN: In einer kleinen Schüssel 3 EL Olivenöl, 2 EL frischen Zitronensaft, 1 TL Dijon-Senf, 1 gepresste Knoblauchzehe, Salz, Pfeffer und eine Prise Kreuzkümmel verquirlen.',
            '7. BOWL MISCHEN: In einer großen Schüssel die Kichererbsen, Paprikawürfel, Mais und abgetropften Zwiebelwürfel vermengen. Das Dressing darüber gießen und gut durchmischen.',
            '8. THUNFISCH HINZUFÜGEN: Den zerkleinerten Thunfisch vorsichtig unter die Gemüsemischung heben. Nicht zu stark rühren, damit der Thunfisch nicht zu sehr zerfällt.',
            '9. BOWL ANRICHTEN: Die Mischung auf zwei Schüsseln verteilen. Optional auf einem Bett aus frischem Salat oder Spinat servieren.',
            '10. FINALE TOUCHES: Mit frischer gehackter Petersilie oder Koriander garnieren. Mit Zitronenspalten servieren. Optional mit Avocado-Scheiben toppen für extra gesunde Fette. Diese Bowl liefert 40g Protein pro Portion und eignet sich perfekt für Meal-Prep!',
          ],
          tags: ['Fitness', 'High-Protein', 'schnell', 'Meal-Prep', 'gesund', 'kaufland angebote'],
          nutrition: const NutritionInfo(calories: 420, protein: 40, carbs: 35, fat: 12),
        ),
        dealIngredients: dealIngredients,
        totalCost: totalCost,
        totalSavings: totalSavings,
      ));
    }

    // ========== RECIPE 14: Hähnchen-Gemüse Fitness-Pfanne ==========
    if (chickenDeal != null) {
      const servings = 3;
      final ingredients = <RecipeIngredient>[
        RecipeIngredient(name: chickenDeal.productName, quantity: '500', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Brokkoli', quantity: '300', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Paprika (gemischt)', quantity: '2', unit: 'Stück', isAvailable: true),
        const RecipeIngredient(name: 'Zucchini', quantity: '1', unit: 'Stück', isAvailable: true),
        const RecipeIngredient(name: 'Knoblauch', quantity: '3', unit: 'Zehen', isAvailable: true),
        const RecipeIngredient(name: 'Sojasauce', quantity: '2', unit: 'EL', isAvailable: true),
      ];

      final chickenUsed = 500.0;

      final dealIngredients = <DealIngredient>[
        DealIngredient(
          ingredient: ingredients[0],
          deal: chickenDeal,
          storeName: chickenDeal.storeName,
          price: calculateActualPrice(chickenDeal, chickenUsed, 'g'),
          savings: calculateActualSavings(chickenDeal, chickenUsed, 'g'),
        ),
      ];

      final totalSavings = dealIngredients.fold<double>(0, (sum, di) => sum + (di.savings ?? 0));
      final totalCost = dealIngredients.fold<double>(0, (sum, di) => sum + di.price) + 3.00;

      dealRecipes.add(DealRecipe(
        recipe: Recipe(
          id: _uuid.v4(),
          name: 'Hähnchen-Gemüse Fitness-Pfanne',
          description: 'Schnelle High-Protein Pfanne mit Hähnchen und buntem Gemüse - ideal für Muskelaufbau!',
          imageUrl: 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=800',
          prepTime: 15,
          cookTime: 15,
          servings: servings,
          difficulty: 'easy',
          ingredients: ingredients,
          instructions: [
            '1. HÄHNCHEN VORBEREITEN: Die Hähnchenbrust in ca. 2cm große Würfel schneiden. Mit Salz, Pfeffer und etwas Paprikapulver würzen. Beiseite stellen.',
            '2. GEMÜSE SCHNEIDEN: Den Brokkoli in kleine Röschen teilen. Paprika waschen, entkernen und in Streifen schneiden. Zucchini waschen und in Halbmonde schneiden. Knoblauch fein hacken.',
            '3. BROKKOLI BLANCHIEREN: Einen Topf mit Salzwasser zum Kochen bringen. Die Brokkoli-Röschen 2-3 Minuten blanchieren, dann in Eiswasser abschrecken. Das erhält die grüne Farbe und Bissfestigkeit!',
            '4. HÄHNCHEN ANBRATEN: 1 EL Öl in einer großen Pfanne oder Wok bei hoher Hitze erhitzen. Das Hähnchen portionsweise (nicht zu viel auf einmal!) 4-5 Minuten scharf anbraten, bis es goldbraun ist. Herausnehmen und beiseite stellen.',
            '5. GEMÜSE ANBRATEN: Im gleichen Wok 1 EL Öl erhitzen. Die Paprikastreifen 2 Minuten bei hoher Hitze anbraten. Dann Zucchini und Knoblauch hinzufügen und weitere 2 Minuten braten.',
            '6. BROKKOLI HINZUFÜGEN: Den blanchierten Brokkoli zum Wok geben und 1 Minute mitbraten. Das Gemüse sollte noch Biss haben!',
            '7. SAUCE ZUBEREITEN: In einer kleinen Schüssel 2 EL Sojasauce, 1 EL Sesamöl, 1 TL Honig, etwas frisch geriebenen Ingwer und eine Prise Chili-Flocken vermischen.',
            '8. ALLES KOMBINIEREN: Das gebratene Hähnchen zurück in den Wok geben. Die Sauce darüber gießen und alles 1-2 Minuten bei hoher Hitze schwenken, bis alles gleichmäßig glasiert ist.',
            '9. ABSCHMECKEN: Mit Salz, Pfeffer und optional etwas Zitronensaft abschmecken. Für extra Würze kannst du noch 1 TL Sriracha oder Sambal Oelek hinzufügen.',
            '10. SERVIEREN: Die Pfanne auf Teller verteilen. Mit geröstetem Sesam und frischem Koriander garnieren. Optional mit Basmatireis oder Quinoa servieren. Pur ist es Low-Carb mit 50g Protein pro Portion!',
          ],
          tags: ['Fitness', 'High-Protein', 'Low-Carb', 'schnell', 'asiatisch', 'kaufland angebote'],
          nutrition: const NutritionInfo(calories: 380, protein: 50, carbs: 12, fat: 14),
        ),
        dealIngredients: dealIngredients,
        totalCost: totalCost,
        totalSavings: totalSavings,
      ));
    }

    // ========== RECIPE 15: Protein-Omelette Deluxe ==========
    final eggDeal = findMatchingDeal('eier');

    if (eggDeal != null) {
      const servings = 1;
      final ingredients = <RecipeIngredient>[
        RecipeIngredient(name: eggDeal.productName, quantity: '4', unit: 'Stück', isAvailable: true),
        const RecipeIngredient(name: 'Spinat', quantity: '50', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Cherry-Tomaten', quantity: '80', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Feta-Käse', quantity: '40', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Olivenöl', quantity: '1', unit: 'EL', isAvailable: true),
      ];

      final eggUsed = 240.0; // ~4 eggs at 60g each

      final dealIngredients = <DealIngredient>[
        DealIngredient(
          ingredient: ingredients[0],
          deal: eggDeal,
          storeName: eggDeal.storeName,
          price: calculateActualPrice(eggDeal, eggUsed, 'g'),
          savings: calculateActualSavings(eggDeal, eggUsed, 'g'),
        ),
      ];

      if (tomatoDeal != null) {
        ingredients[2] = RecipeIngredient(name: tomatoDeal.productName, quantity: '80', unit: 'g', isAvailable: true);
        final tomatoUsed = 80.0;
        dealIngredients.add(DealIngredient(
          ingredient: ingredients[2],
          deal: tomatoDeal,
          storeName: tomatoDeal.storeName,
          price: calculateActualPrice(tomatoDeal, tomatoUsed, 'g'),
          savings: calculateActualSavings(tomatoDeal, tomatoUsed, 'g'),
        ));
      }

      final totalSavings = dealIngredients.fold<double>(0, (sum, di) => sum + (di.savings ?? 0));
      final totalCost = dealIngredients.fold<double>(0, (sum, di) => sum + di.price) + 1.50;

      dealRecipes.add(DealRecipe(
        recipe: Recipe(
          id: _uuid.v4(),
          name: 'Protein-Omelette Deluxe',
          description: 'Fluffiges High-Protein Omelette mit Spinat, Tomaten und Feta - der perfekte Fitness-Start in den Tag!',
          imageUrl: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=800',
          prepTime: 5,
          cookTime: 8,
          servings: servings,
          difficulty: 'easy',
          ingredients: ingredients,
          instructions: [
            '1. ZUTATEN VORBEREITEN: Die Eier in eine Schüssel aufschlagen. Den Spinat waschen und grob hacken. Cherry-Tomaten halbieren. Feta-Käse in kleine Würfel schneiden.',
            '2. EIER VERQUIRLEN: Die Eier mit 1 EL Wasser, Salz und frisch gemahlenem schwarzen Pfeffer kräftig mit einer Gabel oder einem Schneebesen verquirlen, bis sie schaumig sind. Das Wasser macht das Omelette besonders fluffig!',
            '3. PFANNE VORHEIZEN: Eine beschichtete Pfanne (ca. 24cm Durchmesser) bei mittlerer Hitze vorheizen. 1 EL Olivenöl hinzufügen und schwenken, damit der Boden gleichmäßig bedeckt ist.',
            '4. SPINAT ANBRATEN: Den gehackten Spinat in die Pfanne geben und 1 Minute anbraten, bis er zusammenfällt. Mit etwas Knoblauchpulver würzen. An den Rand der Pfanne schieben.',
            '5. EIER HINZUFÜGEN: Die verquirlten Eier in die Pfanne gießen. Die Pfanne leicht schwenken, damit die Eimasse gleichmäßig verteilt wird.',
            '6. OMELETTE FORMEN: Mit einem Silikonspatel die Ränder vorsichtig zur Mitte schieben, während die Pfanne leicht gekippt wird. So fließt die flüssige Eimasse nach außen. Dies 2-3 Mal wiederholen.',
            '7. FÜLLUNG HINZUFÜGEN: Wenn die Oberfläche fast gestockt aber noch leicht glänzend ist, die Spinat-Mischung auf eine Hälfte des Omeletts geben. Die halbierten Tomaten und Feta-Würfel darauf verteilen.',
            '8. ZUSAMMENKLAPPEN: Mit dem Spatel die andere Hälfte des Omeletts vorsichtig über die Füllung klappen. Hitze auf niedrig reduzieren und weitere 30 Sekunden garen.',
            '9. RUHEN LASSEN: Die Pfanne vom Herd nehmen und das Omelette 1 Minute in der Pfanne ruhen lassen. So stockt die Füllung nach und das Omelette wird besonders cremig.',
            '10. SERVIEREN: Das Omelette vorsichtig auf einen Teller gleiten lassen. Mit frischen Kräutern wie Schnittlauch oder Petersilie garnieren. Optional mit Avocado-Scheiben servieren. Dieses Omelette liefert 28g Protein - perfekt für Muskelaufbau!',
          ],
          tags: ['Fitness', 'High-Protein', 'Frühstück', 'Low-Carb', 'schnell', 'kaufland angebote'],
          nutrition: const NutritionInfo(calories: 380, protein: 28, carbs: 5, fat: 28),
        ),
        dealIngredients: dealIngredients,
        totalCost: totalCost,
        totalSavings: totalSavings,
      ));
    }

    // ========== RECIPE 16: Putenbrust Asia-Style ==========
    final turkeyDeal = findMatchingDeal('pute');

    if (turkeyDeal != null) {
      const servings = 2;
      final ingredients = <RecipeIngredient>[
        RecipeIngredient(name: turkeyDeal.productName, quantity: '300', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Pak Choi', quantity: '200', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Shiitake-Pilze', quantity: '150', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Ingwer', quantity: '20', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Knoblauch', quantity: '2', unit: 'Zehen', isAvailable: true),
        const RecipeIngredient(name: 'Sojasauce', quantity: '3', unit: 'EL', isAvailable: true),
      ];

      final turkeyUsed = 300.0;

      final dealIngredients = <DealIngredient>[
        DealIngredient(
          ingredient: ingredients[0],
          deal: turkeyDeal,
          storeName: turkeyDeal.storeName,
          price: calculateActualPrice(turkeyDeal, turkeyUsed, 'g'),
          savings: calculateActualSavings(turkeyDeal, turkeyUsed, 'g'),
        ),
      ];

      final totalSavings = dealIngredients.fold<double>(0, (sum, di) => sum + (di.savings ?? 0));
      final totalCost = dealIngredients.fold<double>(0, (sum, di) => sum + di.price) + 3.50;

      dealRecipes.add(DealRecipe(
        recipe: Recipe(
          id: _uuid.v4(),
          name: 'Putenbrust Asia-Style',
          description: 'Magere Putenbrust mit asiatischem Gemüse im Wok - extrem proteinreich und fettarm!',
          imageUrl: 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=800',
          prepTime: 15,
          cookTime: 12,
          servings: servings,
          difficulty: 'medium',
          ingredients: ingredients,
          instructions: [
            '1. PUTE VORBEREITEN: Die Putenbrust in dünne Streifen schneiden (ca. 0,5cm dick). TIPP: Leicht angefrorenes Fleisch lässt sich einfacher schneiden! Mit Salz und weißem Pfeffer würzen.',
            '2. MARINADE ANRÜHREN: In einer Schüssel 1 EL Sojasauce, 1 TL Sesamöl, 1 TL Maisstärke und etwas weißen Pfeffer vermischen. Die Putenstreifen darin 10 Minuten marinieren.',
            '3. GEMÜSE SCHNEIDEN: Pak Choi waschen und in 3cm lange Stücke schneiden (Stiele und Blätter trennen). Shiitake-Pilze putzen und in Scheiben schneiden. Ingwer schälen und fein reiben. Knoblauch hacken.',
            '4. SAUCE VORBEREITEN: In einer kleinen Schüssel 2 EL Sojasauce, 1 EL Austernsauce (optional), 1 TL Sesamöl, 1 TL Honig, 50ml Wasser und 1 TL Maisstärke verquirlen.',
            '5. WOK ERHITZEN: Den Wok bei sehr hoher Hitze erhitzen, bis er raucht. 1 EL neutrales Öl (Erdnuss- oder Rapsöl) hinzufügen und schwenken.',
            '6. PUTE ANBRATEN: Die marinierten Putenstreifen portionsweise (maximal die Hälfte auf einmal!) im Wok 2-3 Minuten scharf anbraten, bis sie goldbraun sind. Herausnehmen und beiseite stellen.',
            '7. AROMATEN ANBRATEN: Etwas mehr Öl in den Wok geben. Ingwer und Knoblauch 30 Sekunden anbraten, bis sie duften. Nicht verbrennen lassen!',
            '8. GEMÜSE GAREN: Zuerst die Pak Choi-Stiele in den Wok geben und 2 Minuten unter ständigem Rühren braten. Dann die Pilze hinzufügen und weitere 2 Minuten braten. Zum Schluss die Pak Choi-Blätter unterheben.',
            '9. FINALISIEREN: Die Pute zurück in den Wok geben. Die vorbereitete Sauce darüber gießen und alles 1-2 Minuten unter ständigem Rühren köcheln lassen, bis die Sauce eindickt und alles glasiert ist.',
            '10. SERVIEREN: Sofort auf vorgewärmten Tellern anrichten. Mit geröstetem Sesam bestreuen und mit frischem Koriander garnieren. Optional mit Chili-Flocken würzen. Pur genießen (Low-Carb) oder mit Jasminreis servieren. 42g Protein pro Portion!',
          ],
          tags: ['Fitness', 'High-Protein', 'Low-Carb', 'asiatisch', 'fettarm', 'kaufland angebote'],
          nutrition: const NutritionInfo(calories: 280, protein: 42, carbs: 8, fat: 8),
        ),
        dealIngredients: dealIngredients,
        totalCost: totalCost,
        totalSavings: totalSavings,
      ));
    }

    // ========== RECIPE 17: Rinder-Steak mit Spargel ==========
    final steakDeal = findMatchingDeal('rind');

    if (steakDeal != null) {
      const servings = 2;
      final ingredients = <RecipeIngredient>[
        RecipeIngredient(name: steakDeal.productName, quantity: '400', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Grüner Spargel', quantity: '300', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Cherry-Tomaten', quantity: '150', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Knoblauch', quantity: '3', unit: 'Zehen', isAvailable: true),
        const RecipeIngredient(name: 'Butter', quantity: '30', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Thymian', quantity: '3', unit: 'Zweige', isAvailable: true),
      ];

      final steakUsed = 400.0;

      final dealIngredients = <DealIngredient>[
        DealIngredient(
          ingredient: ingredients[0],
          deal: steakDeal,
          storeName: steakDeal.storeName,
          price: calculateActualPrice(steakDeal, steakUsed, 'g'),
          savings: calculateActualSavings(steakDeal, steakUsed, 'g'),
        ),
      ];

      if (tomatoDeal != null) {
        ingredients[2] = RecipeIngredient(name: tomatoDeal.productName, quantity: '150', unit: 'g', isAvailable: true);
        final tomatoUsed = 150.0;
        dealIngredients.add(DealIngredient(
          ingredient: ingredients[2],
          deal: tomatoDeal,
          storeName: tomatoDeal.storeName,
          price: calculateActualPrice(tomatoDeal, tomatoUsed, 'g'),
          savings: calculateActualSavings(tomatoDeal, tomatoUsed, 'g'),
        ));
      }

      final totalSavings = dealIngredients.fold<double>(0, (sum, di) => sum + (di.savings ?? 0));
      final totalCost = dealIngredients.fold<double>(0, (sum, di) => sum + di.price) + 3.00;

      dealRecipes.add(DealRecipe(
        recipe: Recipe(
          id: _uuid.v4(),
          name: 'Rinder-Steak mit grünem Spargel',
          description: 'Perfekt gebratenes Rindersteak mit grünem Spargel - proteinreich und Low-Carb für Fitnessziele!',
          imageUrl: 'https://images.unsplash.com/photo-1600891964599-f61ba0e24092?w=800',
          prepTime: 10,
          cookTime: 15,
          servings: servings,
          difficulty: 'medium',
          ingredients: ingredients,
          instructions: [
            '1. STEAK VORBEREITEN: Das Rindersteak mindestens 30 Minuten vor dem Braten aus dem Kühlschrank nehmen - es sollte Raumtemperatur haben. Mit Küchenpapier trocken tupfen. Großzügig mit Salz und frisch gemahlenem Pfeffer würzen.',
            '2. SPARGEL VORBEREITEN: Die holzigen Enden vom grünen Spargel abbrechen (ca. 2-3cm). Die Stangen waschen. Falls die Enden sehr dick sind, die untere Hälfte mit einem Sparschäler schälen.',
            '3. GEMÜSE SCHNEIDEN: Cherry-Tomaten halbieren. Knoblauchzehen in Scheiben schneiden. Thymian-Blätter von den Stielen zupfen.',
            '4. STEAK ANBRATEN: Eine schwere Pfanne (idealerweise Gusseisen) bei sehr hoher Hitze erhitzen, bis sie raucht. 1 EL neutrales Öl mit hohem Rauchpunkt hinzufügen. Das Steak in die Pfanne legen - es sollte laut brutzeln!',
            '5. ERSTE SEITE BRATEN: Das Steak 3-4 Minuten braten, ohne es zu bewegen. Es sollte sich eine schöne dunkle Kruste bilden. WICHTIG: Nicht zu früh wenden!',
            '6. STEAK WENDEN: Das Steak mit einer Zange wenden (niemals mit einer Gabel - das lässt Saft austreten!). Die Butter, Knoblauch und Thymian in die Pfanne geben. Weitere 3-4 Minuten braten für Medium-Rare (Kerntemperatur 52-55°C).',
            '7. STEAK ARROSIEREN: Die Pfanne leicht kippen und mit einem Löffel die geschmolzene Kräuterbutter über das Steak gießen. Dies wiederholt 1 Minute lang tun - das gibt unglaublichen Geschmack!',
            '8. STEAK RUHEN: Das Steak aus der Pfanne nehmen und auf einem Schneidebrett mit Alufolie locker abgedeckt 5-8 Minuten ruhen lassen. Dies ist ESSENTIELL - die Säfte verteilen sich gleichmäßig im Fleisch!',
            '9. SPARGEL BRATEN: In der gleichen Pfanne den Spargel und die Tomaten 5-6 Minuten braten, dabei gelegentlich wenden. Der Spargel sollte leicht gebräunt sein und noch Biss haben. Mit Salz und Pfeffer würzen.',
            '10. SERVIEREN: Das Steak schräg zur Faser in dicke Scheiben schneiden. Mit dem Spargel und Tomaten auf Tellern anrichten. Die Kräuterbutter aus der Pfanne darüber träufeln. Optional mit Meersalzflocken finishen. 52g Protein pro Portion - perfekt für Muskelaufbau!',
          ],
          tags: ['Fitness', 'High-Protein', 'Low-Carb', 'Premium', 'steak', 'kaufland angebote'],
          nutrition: const NutritionInfo(calories: 480, protein: 52, carbs: 6, fat: 28),
        ),
        dealIngredients: dealIngredients,
        totalCost: totalCost,
        totalSavings: totalSavings,
      ));
    }

    // ========== RECIPE 18: Magerquark-Beeren Bowl ==========
    final quarkDeal = findMatchingDeal('quark');

    if (quarkDeal != null) {
      const servings = 1;
      final ingredients = <RecipeIngredient>[
        RecipeIngredient(name: quarkDeal.productName, quantity: '250', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Gemischte Beeren', quantity: '150', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Mandeln', quantity: '30', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Haferflocken', quantity: '40', unit: 'g', isAvailable: true),
        const RecipeIngredient(name: 'Honig', quantity: '1', unit: 'EL', isAvailable: true),
        const RecipeIngredient(name: 'Leinsamen', quantity: '1', unit: 'EL', isAvailable: true),
      ];

      final quarkUsed = 250.0;

      final dealIngredients = <DealIngredient>[
        DealIngredient(
          ingredient: ingredients[0],
          deal: quarkDeal,
          storeName: quarkDeal.storeName,
          price: calculateActualPrice(quarkDeal, quarkUsed, 'g'),
          savings: calculateActualSavings(quarkDeal, quarkUsed, 'g'),
        ),
      ];

      if (raspberryDeal != null) {
        ingredients[1] = RecipeIngredient(name: 'Gemischte Beeren (mit ${raspberryDeal.productName})', quantity: '150', unit: 'g', isAvailable: true);
        final berryUsed = 100.0; // part of the mixed berries
        dealIngredients.add(DealIngredient(
          ingredient: ingredients[1],
          deal: raspberryDeal,
          storeName: raspberryDeal.storeName,
          price: calculateActualPrice(raspberryDeal, berryUsed, 'g'),
          savings: calculateActualSavings(raspberryDeal, berryUsed, 'g'),
        ));
      }

      final totalSavings = dealIngredients.fold<double>(0, (sum, di) => sum + (di.savings ?? 0));
      final totalCost = dealIngredients.fold<double>(0, (sum, di) => sum + di.price) + 2.50;

      dealRecipes.add(DealRecipe(
        recipe: Recipe(
          id: _uuid.v4(),
          name: 'Magerquark-Beeren Protein Bowl',
          description: 'Cremige High-Protein Bowl mit Magerquark, frischen Beeren und Nüssen - perfekt nach dem Training!',
          imageUrl: 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800',
          prepTime: 8,
          cookTime: 0,
          servings: servings,
          difficulty: 'easy',
          ingredients: ingredients,
          instructions: [
            '1. MAGERQUARK VORBEREITEN: Den Magerquark in eine Schüssel geben. Falls er zu fest ist, kannst du 2-3 EL Milch oder Wasser unterrühren, um eine cremigere Konsistenz zu erhalten.',
            '2. QUARK WÜRZEN: 1 EL Honig unter den Quark rühren. Optional: Eine Prise Vanilleextrakt oder Zimt für extra Geschmack hinzufügen. Gut verrühren, bis alles cremig ist.',
            '3. BEEREN VORBEREITEN: Die gemischten Beeren (Himbeeren, Blaubeeren, Erdbeeren) vorsichtig waschen und auf einem Küchentuch trocknen lassen. Größere Erdbeeren in Stücke schneiden.',
            '4. MANDELN RÖSTEN: Die Mandeln in einer trockenen Pfanne ohne Öl 2-3 Minuten bei mittlerer Hitze rösten, bis sie duften und leicht gebräunt sind. Abkühlen lassen und grob hacken.',
            '5. HAFERFLOCKEN TOPPEN: Optional kannst du die Haferflocken ebenfalls kurz in der Pfanne rösten - das gibt ihnen einen nussigen Geschmack. Oder verwende sie roh für mehr Biss.',
            '6. LEINSAMEN VORBEREITEN: Die Leinsamen können ganz verwendet oder kurz gemahlen werden. Gemahlene Leinsamen werden besser vom Körper aufgenommen und liefern mehr Omega-3!',
            '7. BOWL SCHICHTEN: Den vorbereiteten Magerquark in eine schöne Schüssel geben. Die Oberfläche mit einem Löffel glatt streichen.',
            '8. BEEREN HINZUFÜGEN: Die frischen Beeren großzügig auf dem Quark verteilen. Eine bunte Mischung sieht besonders appetitlich aus!',
            '9. TOPPINGS VERTEILEN: Die gerösteten, gehackten Mandeln über die Beeren streuen. Die Haferflocken und Leinsamen darüber verteilen. Für extra Crunch kannst du auch Chiasamen oder Kokosflocken hinzufügen.',
            '10. FINALE TOUCHES: Optional mit einem Hauch Honig beträufeln und mit frischen Minzblättern garnieren. Sofort genießen! Diese Bowl liefert 35g Protein und ist perfekt als Post-Workout Mahlzeit oder proteinreiches Frühstück.',
          ],
          tags: ['Fitness', 'High-Protein', 'Frühstück', 'gesund', 'schnell', 'kaufland angebote'],
          nutrition: const NutritionInfo(calories: 420, protein: 35, carbs: 42, fat: 14),
        ),
        dealIngredients: dealIngredients,
        totalCost: totalCost,
        totalSavings: totalSavings,
      ));
    }

    return dealRecipes;
  }
}
