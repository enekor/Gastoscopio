import 'package:cashly/data/models/movement_value.dart';
import 'package:flutter/material.dart';

Widget NotificationWidget(String text, double value, BuildContext context, int monthId, Function(MovementValue onSave) onSave) {
  final theme = Theme.of(context);
  bool _isExpense = true;

  void onDirectlySave(){
    final movementValue = MovementValue(
      null,
      monthId,
      text,
      value,
      _isExpense,
      DateTime.now().day,
      null
    );

    onSave(movementValue);
  }

  void onEdit() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController(text: text);
        final valueController = TextEditingController(text: value.toString());
        return AlertDialog(
          title: const Text('Editar movimiento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: valueController,
                decoration: const InputDecoration(labelText: 'Valor'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final editedName = nameController.text;
                final editedValue = double.tryParse(valueController.text) ?? value;
                final movementValue = MovementValue(
                  null,
                  monthId,
                  editedName,
                  editedValue,
                  _isExpense,
                  DateTime.now().day,
                  null,
                );
                Navigator.of(context).pop();
                onSave(movementValue);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  return Card(
    color: theme.colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: theme.colorScheme.primary.withAlpha(90),
      ),
    ),
    child: Column(
      children: [
        ListTile(
          title: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
          ),
          trailing: Text(
            value.toStringAsFixed(2),
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
          ),
        ),
        const SizedBox(
          height: 8,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(onPressed: onDirectlySave, label: Text("Guardar"), icon: const Icon(Icons.save)),
            ElevatedButton.icon(onPressed: onEdit, label: Text("Editar"), icon: const Icon(Icons.edit))
          ],
        )
      ],
    ),
  );
}