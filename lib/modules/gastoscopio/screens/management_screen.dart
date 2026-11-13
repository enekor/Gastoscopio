import 'package:cashly/modules/gastoscopio/screens/fixed_movements_screen.dart';
import 'package:flutter/material.dart';

/// "Gestión" tab: hosts the recurring movements and debts view.
class ManagementScreen extends StatelessWidget {
  const ManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FixedMovementsScreen(embedded: true);
  }
}
