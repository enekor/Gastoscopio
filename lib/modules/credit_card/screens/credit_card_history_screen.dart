import 'package:cashly/data/models/credit_card_expense.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/credit_card/logic/credit_card_service.dart';
import 'package:cashly/theme/app_glass.dart';
import 'package:cashly/theme/widgets/app_background.dart';
import 'package:cashly/theme/widgets/app_list_row.dart';
import 'package:cashly/theme/widgets/amount_text.dart';
import 'package:cashly/theme/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';

class CreditCardHistoryScreen extends StatefulWidget {
  const CreditCardHistoryScreen({super.key});

  @override
  State<CreditCardHistoryScreen> createState() => _CreditCardHistoryScreenState();
}

class _CreditCardHistoryScreenState extends State<CreditCardHistoryScreen> {
  String _moneda = '€';

  @override
  void initState() {
    super.initState();
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final currency = await SharedPreferencesService().getStringValue(SharedPreferencesKeys.currency);
    if (mounted) {
      setState(() {
        _moneda = currency ?? '€';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = CreditCardService.getInstance();
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Historial de Tarjetas'),
      ),
      body: AppBackground(
        child: SafeArea(
          top: false,
          child: AnimatedBuilder(
            animation: service,
            builder: (context, child) {
              final months = service.allMonths;

              if (months.isEmpty) {
                return Center(
                  child: Text(
                    'No hay historial disponible',
                    style: TextStyle(color: glass.mutedText),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: months.length,
                itemBuilder: (context, index) {
                  final month = months[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      padding: EdgeInsets.zero,
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          shape: const Border(),
                          collapsedShape: const Border(),
                          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          leading: CircleAvatar(
                            backgroundColor: scheme.surfaceContainerHigh,
                            child: Icon(
                              Icons.calendar_month,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          title: Text(
                            '${month.month}/${month.year}',
                            style: TextStyle(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Límite: ${month.limitAmount.toStringAsFixed(2)} $_moneda',
                            style: TextStyle(color: glass.mutedText, fontSize: 12),
                          ),
                          children: [
                            FutureBuilder<List<CreditCardExpense>>(
                              future: SqliteService().db.creditCardExpenseDao.findExpensesByMonthId(month.id!),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      'No hay gastos en este mes',
                                      style: TextStyle(color: glass.mutedText),
                                    ),
                                  );
                                }

                                final expenses = snapshot.data!;
                                final totalSpent = expenses.fold(0.0, (sum, item) => sum + item.amount);
                                final remaining = month.limitAmount - totalSpent;
                                final isOverLimit = remaining < 0;

                                return Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: scheme.surfaceContainerHigh,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Gastado: ${totalSpent.toStringAsFixed(2)} $_moneda',
                                            style: TextStyle(color: scheme.onSurface),
                                          ),
                                          Text(
                                            'Restante: ${remaining.toStringAsFixed(2)} $_moneda',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isOverLimit ? glass.expenseColor : glass.incomeColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ...expenses.map((expense) => Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: AppListRow(
                                            leadingIcon: Icons.payment,
                                            title: expense.description,
                                            subtitle: '${expense.day}/${month.month}/${month.year}',
                                            trailing: AmountText(
                                              amount: expense.amount,
                                              currency: _moneda,
                                              isExpense: true,
                                              signed: true,
                                              fontSize: 15,
                                            ),
                                          ),
                                        )),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
