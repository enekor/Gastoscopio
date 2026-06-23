import 'package:cashly/data/models/credit_card_expense.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/credit_card/logic/credit_card_service.dart';
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
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Tarjetas'),
      ),
      body: AnimatedBuilder(
        animation: service,
        builder: (context, child) {
          final months = service.allMonths;
          
          if (months.isEmpty) {
            return const Center(
              child: Text('No hay historial disponible'),
            );
          }
          
          return ListView.builder(
            itemCount: months.length,
            itemBuilder: (context, index) {
              final month = months[index];
              return ExpansionTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.calendar_month),
                ),
                title: Text('${month.month}/${month.year}'),
                subtitle: Text('Límite: ${month.limitAmount.toStringAsFixed(2)} $_moneda'),
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
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No hay gastos en este mes'),
                        );
                      }

                      final expenses = snapshot.data!;
                      final totalSpent = expenses.fold(0.0, (sum, item) => sum + item.amount);
                      final remaining = month.limitAmount - totalSpent;
                      final isOverLimit = remaining < 0;

                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            color: isOverLimit ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Gastado: ${totalSpent.toStringAsFixed(2)} $_moneda'),
                                Text(
                                  'Restante: ${remaining.toStringAsFixed(2)} $_moneda',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isOverLimit ? Colors.red : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...expenses.map((expense) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.payment, size: 20),
                            title: Text(expense.description),
                            subtitle: Text('${expense.day}/${month.month}/${month.year}'),
                            trailing: Text(
                              '-${expense.amount.toStringAsFixed(2)} $_moneda',
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          )).toList(),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
