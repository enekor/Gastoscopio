import 'package:cuentas_android/dao/cuentaDao.dart';
import 'package:cuentas_android/models/presupuesto.dart';
import 'package:cuentas_android/pantallas/presupuestos/budgetSummary.dart';
import 'package:cuentas_android/utils/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/charts.dart';
import 'package:cuentas_android/widgets/widgetsBasicos.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final _formKey = GlobalKey<FormState>();
  double totalBudget = Values().cuentaRet.value!.GetLastIngreso();
  List<Presupuesto> budgetItems = Values().cuentaRet.value!.presupuestos.value;
  final List<String> _tags =
      Values().cuentaRet.value?.tags.value ?? ["No se ha iniciado el usuario"];

  void _almacenarDatos() {
    cuentaDao().almacenarDatos(Values().cuentaRet.value!, kIsWeb);
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Recalculate budget items based on the new total budget
      setState(() {
        for (var item in budgetItems) {
          item.amount = (item.percentage / 100) * totalBudget;
        }
      });

      _almacenarDatos();
    }
  }

  void _addItem() {
    setState(() {
      budgetItems.add(Presupuesto(
          description: 'New Item',
          percentage: 10, // Default percentage
          amount: (10 / 100) *
              totalBudget, // Calculate amount based on totalBudget and percentage
          tags: []));
    });

    _almacenarDatos();
  }

  void _removeItem(int index) {
    setState(() {
      budgetItems.removeAt(index);
    });

    _almacenarDatos();
  }

  void _updateItem(
      int index, String description, double percentage, List<String> tags) {
    setState(() {
      budgetItems[index].description = description;
      budgetItems[index].percentage = percentage;
      budgetItems[index].tags = tags;
    });
    _almacenarDatos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(
            top: kToolbarHeight, left: 16.0, right: 16, bottom: 16),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              HeadBox(),
              TextFormField(
                initialValue: totalBudget.toStringAsFixed(2),
                decoration: const InputDecoration(
                  labelText: 'Total Budget',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a total budget';
                  }
                  final parsedValue = double.tryParse(value);
                  if (parsedValue == null || parsedValue <= 0) {
                    return 'Please enter a valid positive number';
                  }
                  return null;
                },
                onSaved: (newValue) {
                  setState(() {
                    totalBudget = double.parse(newValue!);
                  });
                },
              ),
              const SizedBox(height: 50),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: List.generate(budgetItems.length, (index) {
                          return SizedBox(
                            width: 150,
                            child: CardButton(
                              onPressed: () => showEditDelete(context, index),
                              context: context,
                              margin: 2,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    budgetItems[index].description,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  Row(
                                    children: [
                                      const Expanded(
                                          flex: 6,
                                          child: Text(
                                            'Deseado:',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          )),
                                      Expanded(
                                          flex: 4,
                                          child: Text(
                                              '${budgetItems[index].percentage}%')),
                                    ],
                                  ),
                                  if (budgetItems[index].amount != null)
                                    Row(
                                      children: [
                                        const Expanded(
                                            flex: 5,
                                            child: Text('Total',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        Expanded(
                                            flex: 5,
                                            child: Text(
                                                '${budgetItems[index].amount!.toStringAsFixed(2)}${Values().moneda.value}')),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 50),
                      SizedBox(
                          height: 200,
                          width: 200,
                          child: BudgetPieChart(budgetItems: budgetItems)),
                    ],
                  ),
                ),
              ),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ActionChipButton(
                    selected: true,
                    onPressed: _submitForm,
                    text: 'Calcular',
                  ),
                  if (budgetItems.last.amount != null)
                    ActionChipButton(
                      selected: true,
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SummaryView(budgetItems: budgetItems),
                          )),
                      text: 'Analisis mensual',
                    ),
                  ActionChipButton(
                      selected: true,
                      onPressed: _addItem,
                      text: 'Agregar',
                      icon: const Icon(Icons.add))
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<dynamic> showEditDelete(BuildContext context, int index) {
    return showDialog(
      context: context,
      builder: (context) {
        RxString description = budgetItems[index].description.obs;
        RxDouble percentage = budgetItems[index].percentage.obs;
        RxList<String> selectedTags =
            RxList.from(budgetItems[index].tags ?? []);

        return AlertDialog(
          title: const Text('Update Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(
                () => TextFormField(
                  initialValue: description.value,
                  decoration: const InputDecoration(labelText: 'Description'),
                  onChanged: (value) {
                    description.value = value;
                  },
                ),
              ),
              Obx(
                () => TextFormField(
                  initialValue: percentage.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Percentage'),
                  onChanged: (value) {
                    percentage.value =
                        double.tryParse(value) ?? percentage.value;
                  },
                ),
              ),
              Obx(() => MultiSelectDialogField(
                    items: _tags
                        .map((tag) => MultiSelectItem<String>(tag, tag))
                        .toList(),
                    title: const Text('Tags'),
                    initialValue:
                        selectedTags.value.where((tag) => tag != "").toList(),
                    onConfirm: (values) {
                      selectedTags.value =
                          values.map((v) => v.toString()).toList();
                    },
                    chipDisplay: MultiSelectChipDisplay(
                      onTap: (value) {
                        selectedTags.value.remove(value.toString());
                      },
                    ),
                    itemsTextStyle: const TextStyle(),
                    selectedItemsTextStyle: const TextStyle(),
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _updateItem(index, description.value, percentage.value,
                    selectedTags.value);
                Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  budgetItems.removeAt(index);
                });
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
