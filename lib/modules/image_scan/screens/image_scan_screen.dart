import 'dart:convert';
import 'dart:io';

import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/data/services/groq_serice.dart';
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

  Future<void> _analyzeImage() async {
    try {
      final file = File(widget.imagePath);
      final bytes = await file.readAsBytes();

      if (bytes.length > 20 * 1024 * 1024) {
        if (mounted) {
          setState(() {
            _isAnalyzing = false;
            _errorMessage = AppLocalizations.of(context)!.imageTooLarge;
          });
        }
        return;
      }

      final base64 = base64Encode(bytes);
      final ext = widget.imagePath.split('.').last.toLowerCase();
      final mimeType = ext == 'png' ? 'image/png' : ext == 'webp' ? 'image/webp' : 'image/jpeg';

      if (!mounted) return;
      final results = await GroqService().parseImageMovements(base64, mimeType, context);

      if (!mounted) return;

      if (results == null || results.isEmpty) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = AppLocalizations.of(context)!.noMovementsFoundInImage;
        });
        return;
      }

      setState(() {
        _movements = results.map((r) => ScannedMovement(
          title: r['title'] as String,
          amount: r['amount'] as double,
          isExpense: r['isExpense'] as bool,
          category: r['category'] as String?,
        )).toList();
        _isAnalyzing = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = AppLocalizations.of(context)!.scanError;
        });
      }
    }
  }

  Future<void> _saveAll() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
      _savingCurrent = 0;
    });

    final db = SqliteService().db;
    final financeService = FinanceService.getInstance(
      db.monthDao,
      db.movementValueDao,
      db.fixedMovementDao,
    );
    final now = DateTime.now();

    try {
      final monthId = await financeService.findMonthByMonthAndYear(now.month, now.year);

      for (int i = 0; i < _movements.length; i++) {
        setState(() => _savingCurrent = i + 1);
        final m = _movements[i];
        final amount = double.parse(m.amountController.text.replaceAll(',', '.'));

        final movement = MovementValue(
          DateTime.now().millisecondsSinceEpoch,
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
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.movementsExtracted(_movements.length)),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.scanError),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _removeMovement(int index) {
    setState(() {
      _movements[index].dispose();
      _movements.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.scanFromImage),
      ),
      body: _isAnalyzing
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Loading(context),
                  const SizedBox(height: 16),
                  Text(localizations.analyzingImage),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline, size: 48, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _movements.length,
                    itemBuilder: (context, index) {
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
                    },
                  ),
                ),
      bottomNavigationBar: (!_isAnalyzing && _errorMessage == null && _movements.isNotEmpty)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveAll,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    _isSaving
                        ? localizations.savingProgress(_savingCurrent, _movements.length)
                        : localizations.saveAll,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
