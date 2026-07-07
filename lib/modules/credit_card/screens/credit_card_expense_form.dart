import 'package:cashly/data/models/credit_card_expense.dart';
import 'package:cashly/modules/credit_card/logic/credit_card_service.dart';
import 'package:flutter/material.dart';

class CreditCardExpenseForm extends StatefulWidget {
  final int month;
  final int year;
  final CreditCardExpense? expenseToEdit;

  const CreditCardExpenseForm({
    super.key,
    required this.month,
    required this.year,
    this.expenseToEdit,
  });

  @override
  State<CreditCardExpenseForm> createState() => _CreditCardExpenseFormState();
}

class _CreditCardExpenseFormState extends State<CreditCardExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.expenseToEdit != null) {
      _descriptionController.text = widget.expenseToEdit!.description;
      _amountController.text = widget.expenseToEdit!.amount.toStringAsFixed(2);
      _selectedDate = DateTime.parse(widget.expenseToEdit!.date);
    } else {
      final now = DateTime.now();
      if (now.month == widget.month && now.year == widget.year) {
        _selectedDate = now;
      } else {
        _selectedDate = DateTime(widget.year, widget.month, 1);
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(widget.year, widget.month, 1),
      lastDate: DateTime(widget.year, widget.month + 1, 0),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveExpense() {
    if (_formKey.currentState!.validate()) {
      final description = _descriptionController.text;
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));

      if (widget.expenseToEdit != null) {
        final updatedExpense = CreditCardExpense(
          id: widget.expenseToEdit!.id,
          monthId: widget.expenseToEdit!.monthId,
          description: description,
          amount: amount,
          day: _selectedDate.day,
          date: _selectedDate.toIso8601String(),
          uuid: widget.expenseToEdit!.uuid,
          ts: DateTime.now().millisecondsSinceEpoch,
        );
        CreditCardService.getInstance().updateExpense(updatedExpense);
      } else {
        CreditCardService.getInstance().addExpense(description, amount, _selectedDate);
      }
      
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expenseToEdit != null ? 'Editar Gasto' : 'Nuevo Gasto de Tarjeta'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa una descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Cantidad',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa una cantidad';
                  }
                  if (double.tryParse(value.replaceAll(',', '.')) == null) {
                    return 'Por favor ingresa un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Fecha'),
                subtitle: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                trailing: const Icon(Icons.calendar_today),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                onTap: () => _selectDate(context),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _saveExpense,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Guardar Gasto', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
