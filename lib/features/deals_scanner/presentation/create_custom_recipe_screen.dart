import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
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

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte füge mindestens eine Zutat hinzu'),
        ),
      );
      return;
    }

    if (_instructions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte füge mindestens einen Schritt hinzu'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

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
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rezept erfolgreich erstellt!'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Erstellen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Bitte Rezeptname eingeben';
                }
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Bitte Beschreibung eingeben';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Time and Servings Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _prepTimeController,
                    decoration: InputDecoration(
                      labelText: 'Vorbereitung (Min)',
                      prefixIcon: const Icon(Iconsax.clock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Erforderlich';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Zahl eingeben';
                      }
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Erforderlich';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Zahl eingeben';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Servings and Difficulty Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _servingsController,
                    decoration: InputDecoration(
                      labelText: 'Portionen',
                      prefixIcon: const Icon(Iconsax.people),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Erforderlich';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Zahl eingeben';
                      }
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'Einfach', child: Text('Einfach')),
                      DropdownMenuItem(value: 'Mittel', child: Text('Mittel')),
                      DropdownMenuItem(
                          value: 'Schwer', child: Text('Schwer')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _difficulty = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Ingredients Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Zutaten',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Zutat',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                _ingredients[index]['name'] = value;
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Erforderlich';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Menge',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                _ingredients[index]['quantity'] = value;
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Erforderlich';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Einheit',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                _ingredients[index]['unit'] = value;
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Erforderlich';
                                }
                                return null;
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Iconsax.trash, color: Colors.red),
                            onPressed: () => _removeIngredient(index),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),

            if (_ingredients.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Text(
                  'Noch keine Zutaten hinzugefügt',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),

            const SizedBox(height: 24),

            // Instructions Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Zubereitungsschritte',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            hintText: 'Schritt beschreiben...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                          onChanged: (value) {
                            _instructions[index] = value;
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Bitte Schritt beschreiben';
                            }
                            return null;
                          },
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
            }).toList(),

            if (_instructions.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Text(
                  'Noch keine Schritte hinzugefügt',
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Rezept speichern',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
