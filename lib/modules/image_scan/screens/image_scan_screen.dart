import 'dart:convert';
import 'dart:io';

import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/data/services/groq_serice.dart';
import 'package:cashly/data/services/log_file_service.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:cashly/modules/gastoscopio/widgets/loading.dart';
import 'package:cashly/modules/image_scan/widgets/scanned_movement_card.dart';
import 'package:cashly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ImageScanScreen extends StatefulWidget {
  final String imagePath;

  const ImageScanScreen({super.key, required this.imagePath});

  @override
  State<ImageScanScreen> createState() => _ImageScanScreenState();
}

class _ImageScanScreenState extends State<ImageScanScreen> {
  final _formKey = GlobalKey<FormState>();
  List<ScannedMovement> _movements = [];
  bool _isAnalyzing = true;
  bool _isSaving = false;
  int _savingCurrent = 0;
  int _savingTotal = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _analyzeImage();
  }

  @override
  void dispose() {
    for (final m in _movements) {
      m.dispose();
    }
    super.dispose();
  }

  String _getMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  Future<void> _analyzeImage() async {
    try {
      final file = File(widget.imagePath);
      final bytes = await file.readAsBytes();

      if (bytes.length > 4 * 1024 * 1024) {
        if (mounted) {
          setState(() {
            _isAnalyzing = false;
            _errorMessage = AppLocalizations.of(context)!.imageTooLarge;
          });
        }
        return;
      }

      final base64Image = base64Encode(bytes);
      final mimeType = _getMimeType(widget.imagePath);

      if (!mounted) return;

      final results = await GroqService().parseImageMovements(
        base64Image,
        mimeType,
        context,
      );

      if (!mounted) return;

      if (results == null) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = AppLocalizations.of(context)!.scanError;
        });
        return;
      }

      setState(() {
        _movements = results
            .map(
              (r) => ScannedMovement(
                descriptionController: TextEditingController(
                  text: r['title'] as String,
                ),
                amountController: TextEditingController(
                  text: (r['amount'] as double).toStringAsFixed(2),
                ),
                isExpense: r['isExpense'] as bool,
                category: r['category'] as String?,
              ),
            )
            .toList();
        _isAnalyzing = false;
      });
    } catch (e) {
      LogFileService().appendLog('ImageScanScreen: error analyzing image: $e');
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = AppLocalizations.of(context)!.scanError;
        });
      }
    }
  }

  void _removeMovement(int index) {
    setState(() {
      _movements[index].dispose();
      _movements.removeAt(index);
    });
  }

  Future<void> _saveAll() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
      _savingTotal = _movements.length;
      _savingCurrent = 0;
    });

    final db = SqliteService().db;
    final financeService = FinanceService.getInstance(
      db.monthDao,
      db.movementValueDao,
      db.fixedMovementDao,
    );

    try {
      final now = DateTime.now();

      for (int i = 0; i < _movements.length; i++) {
        setState(() => _savingCurrent = i + 1);

        final m = _movements[i];
        final amount = double.parse(
          m.amountController.text.replaceAll(',', '.'),
        );

        final monthId = await financeService.findMonthByMonthAndYear(
          now.month,
          now.year,
        );

        final movement = MovementValue(
          null,
          monthId,
          m.descriptionController.text,
          amount,
          m.isExpense,
          now.day,
          m.category?.trim(),
        );
        await db.movementValueDao.insertMovementValue(movement);
        await SharedPreferencesService().haveToUpload();
      }

      await financeService.updateSelectedDate(now.month, now.year);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.pendingNotificationsSaved,
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      LogFileService().appendLog('ImageScanScreen: error saving movements: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.generalError),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_isAnalyzing) {
      return Scaffold(
        appBar: AppBar(title: Text(localizations.scanFromImage)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Loading(context),
              const SizedBox(height: 16),
              Text(
                localizations.analyzingImage,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: Text(localizations.scanFromImage)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _isAnalyzing = true;
                      _errorMessage = null;
                    });
                    _analyzeImage();
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(localizations.tryAgain),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_movements.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(localizations.scanFromImage)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.search_off,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.noMovementsFoundInImage,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text(localizations.scanFromImage),
              floating: true,
            ),
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                color: theme.colorScheme.primaryContainer.withAlpha(80),
                child: Row(
                  children: [
                    Icon(
                      Icons.document_scanner_outlined,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        localizations.movementsExtracted,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Image preview
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: Image.file(
                      File(widget.imagePath),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ScannedMovementCard(
                      movement: _movements[index],
                      onDelete: () => _removeMovement(index),
                      onExpenseChanged: (isExpense) {
                        setState(() {
                          _movements[index].isExpense = isExpense;
                        });
                      },
                    ),
                  );
                }, childCount: _movements.length),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _saveAll,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check),
              label: Text(
                _isSaving
                    ? localizations.savingProgress(_savingCurrent, _savingTotal)
                    : localizations.saveAll,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
