import 'package:cashly/data/services/export_service.dart';
import 'package:cashly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ExportCsvWidget extends StatefulWidget {
  const ExportCsvWidget({super.key});

  @override
  State<ExportCsvWidget> createState() => _ExportCsvWidgetState();
}

class _ExportCsvWidgetState extends State<ExportCsvWidget> {
  bool _isExporting = false;

  Future<void> _exportCsv() async {
    if (_isExporting) return;
    final localizations = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isExporting = true);
    final result = await ExportService().exportMovementsToCSV();
    if (!mounted) return;
    setState(() => _isExporting = false);

    if (result.wasCancelled) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(result.success
            ? localizations.exportCsvSuccess
            : localizations.exportCsvError),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    return Card(
      color: theme.colorScheme.tertiary.withAlpha(25),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outline.withAlpha(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.file_download_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  localizations.exportCsvTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              localizations.exportCsvDescription,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : _exportCsv,
                icon: _isExporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                label: Text(
                  _isExporting
                      ? localizations.exportingCsv
                      : localizations.exportCsvMovements,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: theme.colorScheme.onSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
