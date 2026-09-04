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
  int _tab = 0; // 0 = Deudas, 1 = Recurrentes

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: AppSegmentedControl<int>(
            segments: [
              (value: 0, label: l.navDebts, icon: Icons.credit_score_outlined),
              (value: 1, label: l.recurrents, icon: Icons.repeat_rounded),
            ],
            selected: _tab,
            onChanged: (v) => setState(() => _tab = v),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _tab,
            children: const [
              ActiveDebtsScreen(embedded: true),
              FixedMovementsScreen(embedded: true),
            ],
          ),
        ),
      ],
    );
  }
}
