import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/models/Mes.dart';
import 'package:cuentas_android/models/presupuesto.dart';
import 'package:cuentas_android/values.dart';
import 'package:flutter/material.dart';

class SummaryView extends StatelessWidget {
  final List<Presupuesto> budgetItems;

  const SummaryView({super.key, required this.budgetItems});

  @override
  Widget build(BuildContext context) {
    String selectedMonth = Values().nombresMes[DateTime.now().month - 1];
    int selectedYear = DateTime.now().year;
    Mes mes = Values().cuentaRet.value!.Meses.firstWhere(
        (m) => m.NMes.value == selectedMonth && m.Anno.value == selectedYear);
    List<Gasto> expenses =
        mes.Gastos.value.where((v) => v.valor.value > 0).toList() + mes.Extras;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Resumen de gastos"),
      ),
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: [
            // Selector de mes y año
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 15,
              children: [
                Expanded(
                  flex: 5,
                  child: DropdownButton<String>(
                    value: selectedMonth,
                    items: Values()
                        .nombresMes
                        .map((month) => DropdownMenuItem(
                              value: month,
                              child: Text('Mes $month'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        selectedMonth = value;
                      }
                    },
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: DropdownButton<int>(
                    value: selectedYear,
                    items:
                        List.generate(5, (index) => DateTime.now().year - index)
                            .map((year) => DropdownMenuItem(
                                  value: year,
                                  child: Text('Año $year'),
                                ))
                            .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        selectedYear = value;
                      }
                    },
                  ),
                ),
              ],
            ),
            // Resumen de gastos por tags
            Expanded(
              child: ListView.builder(
                itemCount: budgetItems.length,
                itemBuilder: (context, index) {
                  double totalSpent =
                      Values().cuentaRet.value!.CalcularTotalPorTagFecha(
                            budgetItems[index].tags ?? [],
                            selectedMonth,
                            selectedYear,
                          );

                  double budgetAmount = budgetItems[index].amount ?? -1;
                  String statusMessage =
                      getBudgetStatus(totalSpent, budgetAmount);
                  Color statusColor =
                      getBudgetStatusColor(totalSpent, budgetAmount);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      color: statusColor.withAlpha(50),
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(budgetItems[index].description),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Presupuesto: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text('${budgetAmount.toStringAsFixed(2)} ${Values().moneda.value}')
                              ],
                            ),
                            Row(
                              children: [
                                const Text(
                                  'Gastado: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text('${totalSpent.toStringAsFixed(2)} ${Values().moneda.value}')
                              ],
                            ),
                            Text(
                              statusMessage,
                              style: TextStyle(color: statusColor),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String getBudgetStatus(double totalSpent, double budgetAmount) {
  if (totalSpent > budgetAmount) {
    return 'Te has pasado del presupuesto';
  } else if (totalSpent < budgetAmount * 0.5) {
    return 'Lo has hecho muy bien, aún tienes suficiente dinero para gastar';
  } else if (totalSpent < budgetAmount) {
    return 'Vas bien, pero ten cuidado con los gastos';
  } else {
    return 'Presupuesto justo';
  }
}

Color getBudgetStatusColor(double totalSpent, double budgetAmount) {
  if (totalSpent > budgetAmount) {
    return Colors.red;
  } else if (totalSpent < budgetAmount * 0.5) {
    return Colors.green;
  } else if (totalSpent < budgetAmount) {
    return Colors.orange;
  } else {
    return Colors.black;
  }
}
