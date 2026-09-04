import 'package:cashly/l10n/app_localizations.dart';
import 'package:cashly/modules/gastoscopio/screens/active_debts_screen.dart';
import 'package:cashly/modules/gastoscopio/screens/fixed_movements_screen.dart';
import 'package:cashly/theme/widgets/app_segmented_control.dart';
import 'package:flutter/material.dart';

/// "Gestión" tab: hosts both the pending debts view and the recurring movements
/// view behind a segmented toggle.
class ManagementScreen extends StatefulWidget {
  const ManagementScreen({super.key});

  @override
  State<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends State<ManagementScreen> {

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      children: [
        Expanded(
          child:  FixedMovementsScreen(embedded: true),
        ),
      ],
    );
  }
}
