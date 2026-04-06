import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:smartmeal/core/auth/providers/community_profile_provider.dart';
import '../providers/custom_recipes_provider.dart';

class CreateCustomRecipeScreen extends ConsumerStatefulWidget {
  const CreateCustomRecipeScreen({super.key});

  @override
  ConsumerState<CreateCustomRecipeScreen> createState() =>
      _CreateCustomRecipeScreenState();
}

class _CreateCustomRecipeScreenState
    extends ConsumerState<CreateCustomRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _cookTimeController = TextEditingController();
  final _servingsController = TextEditingController(text: '2');

  String _difficulty = 'Einfach';
  final List<Map<String, String>> _ingredients = [];
  final List<String> _instructions = [];
  bool _isPublic = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _servingsController.dispose();
    super.dispose();
  }

  void _addIngredient() {
    setState(() {
      _ingredients.add({'name': '', 'quantity': '', 'unit': ''});
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  void _addInstruction() {
    setState(() {
      _instructions.add('');
    });
  }

  void _removeInstruction(int index) {
    setState(() {
      _instructions.removeAt(index);
    });
  }

  Future<String?> _promptDisplayName() async {
    final controller = TextEditingController();
    final existingName = ref.read(displayNameProvider);
    if (existingName != null) controller.text = existingName;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Anzeigename waehlen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dein Name wird bei Community-Rezepten angezeigt.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'z.B. KochProfi92',
                prefixIcon: const Icon(Iconsax.user),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx, name);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Bestaetigen'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte fuege mindestens eine Zutat hinzu')),
      );
      return;
    }

    if (_instructions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte fuege mindestens einen Schritt hinzu')),
      );
      return;
    }

    // If public and no display name yet, prompt for one
    if (_isPublic && !ref.read(hasDisplayNameProvider)) {
      final name = await _promptDisplayName();
      if (name == null) return; // User cancelled
      ref.read(displayNameProvider.notifier).setName(name);
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(customRecipesProvider.notifier).createRecipe(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            prepTime: int.parse(_prepTimeController.text),
            cookTime: int.parse(_cookTimeController.text),
            servings: int.parse(_servingsController.text),
            difficulty: _difficulty,
            ingredients: _ingredients,
            instructions: _instructions,
            isPublic: _isPublic,
            authorName: _isPublic ? ref.read(displayNameProvider) : null,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isPublic
                ? 'Community-Rezept veroeffentlicht!'
                : 'Rezept erfolgreich erstellt!'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Erstellen: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eigenes Rezept erstellen'),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Rezeptname',
                prefixIcon: const Icon(Iconsax.receipt_item),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Bitte Rezeptname eingeben';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Beschreibung',
                prefixIcon: const Icon(Iconsax.note_text),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Bitte Beschreibung eingeben';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Time and Servings
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _prepTimeController,
                    decoration: InputDecoration(
                      labelText: 'Vorbereitung (Min)',
                      prefixIcon: const Icon(Iconsax.clock),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Erforderlich';
                      if (int.tryParse(value) == null) return 'Zahl eingeben';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _cookTimeController,
                    decoration: InputDecoration(
                      labelText: 'Kochzeit (Min)',
                      prefixIcon: const Icon(Iconsax.timer_1),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Erforderlich';
                      if (int.tryParse(value) == null) return 'Zahl eingeben';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Servings and Difficulty
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _servingsController,
                    decoration: InputDecoration(
                      labelText: 'Portionen',
                      prefixIcon: const Icon(Iconsax.people),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Erforderlich';
                      if (int.tryParse(value) == null) return 'Zahl eingeben';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _difficulty,
                    decoration: InputDecoration(
                      labelText: 'Schwierigkeit',
                      prefixIcon: const Icon(Iconsax.star),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Einfach', child: Text('Einfach')),
                      DropdownMenuItem(value: 'Mittel', child: Text('Mittel')),
                      DropdownMenuItem(value: 'Schwer', child: Text('Schwer')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _difficulty = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // === Public Toggle ===
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isPublic ? const Color(0xFF2E7D32).withOpacity(0.06) : Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isPublic ? const Color(0xFF2E7D32).withOpacity(0.3) : Colors.grey[300]!,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isPublic ? const Color(0xFF2E7D32).withOpacity(0.1) : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isPublic ? Iconsax.global : Iconsax.lock,
                      color: _isPublic ? const Color(0xFF2E7D32) : Colors.grey,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isPublic ? 'Community-Rezept' : 'Privates Rezept',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isPublic
                              ? 'Sichtbar fuer alle Nutzer'
                              : 'Nur fuer dich sichtbar',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isPublic,
                    onChanged: (val) => setState(() => _isPublic = val),
                    activeColor: const Color(0xFF2E7D32),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Ingredients Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Zutaten', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Iconsax.add_circle),
                  onPressed: _addIngredient,
                  color: const Color(0xFF2E7D32),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ..._ingredients.asMap().entries.map((entry) {
              final index = entry.key;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 6, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with number and delete
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Zutat ${index + 1}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Iconsax.trash, color: Colors.red, size: 20),
                            onPressed: () => _removeIngredient(index),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Zutat name - full width
                      const Text('Zutat *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                      const SizedBox(height: 4),
                      TextFormField(
                        decoration: InputDecoration(
                          hintText: 'z.B. Kartoffeln, Mehl, Butter...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        onChanged: (value) => _ingredients[index]['name'] = value,
                        validator: (value) => (value == null || value.isEmpty) ? 'Bitte Zutat eingeben' : null,
                      ),
                      const SizedBox(height: 12),
                      // Menge + Einheit nebeneinander
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Menge *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                                const SizedBox(height: 4),
                                TextFormField(
                                  decoration: InputDecoration(
                                    hintText: 'z.B. 250',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                  keyboardType: TextInputType.text,
                                  onChanged: (value) => _ingredients[index]['quantity'] = value,
                                  validator: (value) => (value == null || value.isEmpty) ? 'Erforderlich' : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Einheit *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                  isExpanded: true,
                                  hint: const Text('Waehlen'),
                                  items: const [
                                    DropdownMenuItem(value: 'g', child: Text('Gramm (g)')),
                                    DropdownMenuItem(value: 'kg', child: Text('Kilogramm (kg)')),
                                    DropdownMenuItem(value: 'ml', child: Text('Milliliter (ml)')),
                                    DropdownMenuItem(value: 'l', child: Text('Liter (l)')),
                                    DropdownMenuItem(value: 'Stueck', child: Text('Stueck')),
                                    DropdownMenuItem(value: 'EL', child: Text('Essloeffel (EL)')),
                                    DropdownMenuItem(value: 'TL', child: Text('Teeloeffel (TL)')),
                                    DropdownMenuItem(value: 'Prise', child: Text('Prise')),
                                    DropdownMenuItem(value: 'Bund', child: Text('Bund')),
                                    DropdownMenuItem(value: 'Zehe', child: Text('Zehe(n)')),
                                    DropdownMenuItem(value: 'Scheibe', child: Text('Scheibe(n)')),
                                    DropdownMenuItem(value: 'Tasse', child: Text('Tasse(n)')),
                                    DropdownMenuItem(value: 'Becher', child: Text('Becher')),
                                    DropdownMenuItem(value: 'Packung', child: Text('Packung')),
                                    DropdownMenuItem(value: 'Dose', child: Text('Dose(n)')),
                                    DropdownMenuItem(value: 'Flasche', child: Text('Flasche(n)')),
                                    DropdownMenuItem(value: 'Handvoll', child: Text('Handvoll')),
                                    DropdownMenuItem(value: 'Blatt', child: Text('Blatt/Blaetter')),
                                    DropdownMenuItem(value: 'Stange', child: Text('Stange(n)')),
                                    DropdownMenuItem(value: 'nach Geschmack', child: Text('nach Geschmack')),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) _ingredients[index]['unit'] = value;
                                  },
                                  validator: (value) => (value == null || value.isEmpty) ? 'Waehlen' : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),

            if (_ingredients.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Text(
                  'Noch keine Zutaten hinzugefuegt',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),

            const SizedBox(height: 24),

            // Instructions Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Zubereitungsschritte', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Iconsax.add_circle),
                  onPressed: _addInstruction,
                  color: const Color(0xFF2E7D32),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ..._instructions.asMap().entries.map((entry) {
              final index = entry.key;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: const BoxDecoration(color: Color(0xFF2E7D32), shape: BoxShape.circle),
                        child: Center(
                          child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(hintText: 'Schritt beschreiben...', border: OutlineInputBorder()),
                          maxLines: 2,
                          onChanged: (value) => _instructions[index] = value,
                          validator: (value) => (value == null || value.isEmpty) ? 'Bitte Schritt beschreiben' : null,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Iconsax.trash, color: Colors.red),
                        onPressed: () => _removeInstruction(index),
                      ),
                    ],
                  ),
                ),
              );
            }),

            if (_instructions.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Text(
                  'Noch keine Schritte hinzugefuegt',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),

            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveRecipe,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : Text(
                      _isPublic ? 'Community-Rezept veroeffentlichen' : 'Rezept speichern',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
