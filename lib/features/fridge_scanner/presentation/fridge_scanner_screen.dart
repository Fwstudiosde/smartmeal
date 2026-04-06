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

class FridgeScannerScreen extends ConsumerStatefulWidget {
  const FridgeScannerScreen({super.key});

  @override
  ConsumerState<FridgeScannerScreen> createState() => _FridgeScannerScreenState();
}

class _FridgeScannerScreenState extends ConsumerState<FridgeScannerScreen> {
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
        
        // Analyze the image
        final aiService = ref.read(aiServiceProvider);
        final ingredients = await aiService.analyzeImage(_selectedImage!);
        
        // Update the provider
        ref.read(ingredientsProvider.notifier).setIngredients(ingredients);
        
        setState(() => _isAnalyzing = false);
        
        if (mounted) {
          context.push('/ingredients');
        }
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Laden des Bildes: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(context),
                const SizedBox(height: 32),
                
                // Scan Options
                _buildScanOptions(context),
                const SizedBox(height: 32),
                
                // Manual Input Section
                _buildManualInputSection(context),
                const SizedBox(height: 24),
                
                // Recent Scans
                _buildRecentScans(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kühlschrank',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: AppColors.textPrimary,
          ),
        ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
        Text(
          'Scanner',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: -0.1),
        const SizedBox(height: 12),
        Text(
          'Fotografiere deinen Kühlschrank und wir finden die perfekten Rezepte für dich.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
      ],
    );
  }

  Widget _buildScanOptions(BuildContext context) {
    if (_isAnalyzing) {
      return _buildAnalyzingState();
    }
    
    return Column(
      children: [
        // Camera Option
        _ScanOptionCard(
          icon: Iconsax.camera,
          title: 'Foto aufnehmen',
          subtitle: 'Fotografiere deinen Kühlschrank direkt',
          gradient: AppColors.primaryGradient,
          onTap: () => _pickImage(ImageSource.camera),
        ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.1),
        
        const SizedBox(height: 16),
        
        // Gallery Option
        _ScanOptionCard(
          icon: Iconsax.gallery,
          title: 'Aus Galerie wählen',
          subtitle: 'Wähle ein bestehendes Foto aus',
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
          onTap: () => _pickImage(ImageSource.gallery),
        ).animate().fadeIn(duration: 400.ms, delay: 400.ms).slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildAnalyzingState() {
    return Container(
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
              child: Image.file(
                _selectedImage!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),
          ],
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primary,
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat())
            .shimmer(duration: 1500.ms, color: AppColors.primary.withOpacity(0.3)),
          const SizedBox(height: 24),
          Text(
            'KI analysiert dein Bild...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Zutaten werden erkannt',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildManualInputSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 1,
              color: AppColors.surfaceVariant,
            ),
            const SizedBox(width: 16),
            Text(
              'oder',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                height: 1,
                color: AppColors.surfaceVariant,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () {
            // Set empty ingredients and go to manual input
            ref.read(ingredientsProvider.notifier).setIngredients([]);
            context.push('/ingredients');
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surfaceVariant),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Iconsax.edit_2,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manuell eingeben',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Füge Zutaten per Hand hinzu',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Iconsax.arrow_right_3,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 600.ms).slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildRecentScans(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'So funktioniert\'s',
          style: Theme.of(context).textTheme.headlineSmall,
        ).animate().fadeIn(duration: 400.ms, delay: 700.ms),
        const SizedBox(height: 16),
        _StepCard(
          number: '1',
          title: 'Fotografieren',
          description: 'Mache ein Foto von deinem Kühlschrank oder deinen Vorräten.',
        ).animate().fadeIn(duration: 400.ms, delay: 800.ms).slideX(begin: 0.1),
        const SizedBox(height: 12),
        _StepCard(
          number: '2',
          title: 'KI-Analyse',
          description: 'Unsere KI erkennt automatisch alle Zutaten im Bild.',
        ).animate().fadeIn(duration: 400.ms, delay: 900.ms).slideX(begin: 0.1),
        const SizedBox(height: 12),
        _StepCard(
          number: '3',
          title: 'Rezepte erhalten',
          description: 'Erhalte passende Rezepte basierend auf deinen Zutaten.',
        ).animate().fadeIn(duration: 400.ms, delay: 1000.ms).slideX(begin: 0.1),
      ],
    );
  }
}

class _ScanOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  const _ScanOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Iconsax.arrow_right_3,
              color: Colors.white.withOpacity(0.8),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _StepCard({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
