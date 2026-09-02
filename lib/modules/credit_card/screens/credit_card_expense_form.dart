import 'package:cashly/data/models/credit_card_expense.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/modules/credit_card/logic/credit_card_service.dart';
import 'package:cashly/theme/app_glass.dart';
import 'package:cashly/theme/widgets/app_background.dart';
import 'package:cashly/theme/widgets/glass_card.dart';
import 'package:cashly/theme/widgets/primary_pill_button.dart';
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
  String _moneda = '€';

  @override
  void initState() {
    super.initState();
    _loadCurrency();
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

  Future<void> _loadCurrency() async {
    final currency = await SharedPreferencesService().getStringValue(SharedPreferencesKeys.currency);
    if (mounted) {
      setState(() {
        _moneda = currency ?? '€';
      });
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

  void _saveExpense() async {
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
        await CreditCardService.getInstance().updateExpense(updatedExpense);
      } else {
        await CreditCardService.getInstance().addExpense(description, amount, _selectedDate);
      }

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text(widget.expenseToEdit != null ? 'Editar Gasto' : 'Nuevo Gasto de Tarjeta'),
      ),
      body: AppBackground(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Description
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Descripción',
                          style: TextStyle(color: glass.mutedText, fontSize: 13),
                        ),
                        TextFormField(
                          controller: _descriptionController,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                          decoration: const InputDecoration(
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                            hintText: 'Ej: Compra online...',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa una descripción';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Amount
                  GlassCard(
                    child: Column(
                      children: [
                        Text(
                          'Cantidad',
                          style: TextStyle(color: glass.mutedText, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              _moneda,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: scheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IntrinsicWidth(
                              child: TextFormField(
                                controller: _amountController,
                                textAlign: TextAlign.center,
                                keyboardType: const TextInputType
                                    .numberWithOptions(decimal: true),
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurface,
                                ),
                                decoration: const InputDecoration(
                                  filled: false,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  hintText: '0.00',
                                  contentPadding: EdgeInsets.zero,
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
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Date
                  GlassCard(
                    onTap: () => _selectDate(context),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fecha',
                              style: TextStyle(color: glass.mutedText, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                              style: TextStyle(
                                color: scheme.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHigh,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.calendar_month, color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  PrimaryPillButton(
                    label: 'Guardar Gasto',
                    icon: Icons.check_circle_outline,
                    onPressed: _saveExpense,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
