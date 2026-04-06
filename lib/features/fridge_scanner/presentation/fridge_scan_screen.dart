import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smartmeal/core/theme/app_theme.dart';
import 'package:smartmeal/core/models/models.dart';
import 'package:smartmeal/core/services/ai_service.dart';
import 'package:smartmeal/features/fridge_scanner/providers/fridge_providers.dart';

class FridgeScanScreen extends ConsumerStatefulWidget {
  const FridgeScanScreen({super.key});

  @override
  ConsumerState<FridgeScanScreen> createState() => _FridgeScanScreenState();
}

class _FridgeScanScreenState extends ConsumerState<FridgeScanScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;
  File? _selectedImage;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _isAnalyzing = true;
        });
        final aiService = ref.read(aiServiceProvider);
        final ingredients = await aiService.analyzeImage(_selectedImage!);
        ref.read(ingredientsProvider.notifier).setIngredients(ingredients);
        setState(() => _isAnalyzing = false);
        if (mounted) context.push('/ingredients');
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button + title
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.surfaceVariant),
                      ),
                      child: const Icon(Iconsax.arrow_left, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kühlschrank Scanner',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'KI erkennt deine Zutaten',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),

              const Spacer(),

              // Analyzing state
              if (_isAnalyzing) ...[
                _buildAnalyzingState(),
              ] else ...[
                // Main scan area
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: const Icon(Iconsax.camera, size: 64, color: AppColors.primary),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Fotografiere deinen Kühlschrank',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Unsere KI erkennt automatisch alle\nZutaten und findet passende Rezepte.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
              ],

              const Spacer(),

              // Buttons
              if (!_isAnalyzing) ...[
                GestureDetector(
                  onTap: () => _pickImage(ImageSource.camera),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.camera, color: Colors.white, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Foto aufnehmen',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickImage(ImageSource.gallery),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.surfaceVariant),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Iconsax.gallery, size: 18, color: Color(0xFF6366F1)),
                              SizedBox(width: 8),
                              Text('Galerie', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          ref.read(ingredientsProvider.notifier).setIngredients([]);
                          context.push('/ingredients');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.surfaceVariant),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Iconsax.edit_2, size: 18, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text('Manuell', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyzingState() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.surfaceVariant),
        ),
        child: Column(
          children: [
            if (_selectedImage != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(_selectedImage!, height: 180, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 24),
            ],
            const SizedBox(
              width: 48, height: 48,
              child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'KI analysiert dein Bild...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Zutaten werden erkannt',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
