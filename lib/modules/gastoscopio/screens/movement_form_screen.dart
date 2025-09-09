import 'package:cashly/data/services/gemini_service.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:flutter/material.dart';
import 'package:cashly/l10n/app_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MovementFormScreen extends StatefulWidget {
  final MovementValue? movement;
  bool isExpense = true;

  MovementFormScreen({super.key, this.movement, this.isExpense = true});

  @override
  State<MovementFormScreen> createState() => _MovementFormScreenState();
}

class _MovementFormScreenState extends State<MovementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false; // Agregar indicador de carga
  late final _descriptionController = TextEditingController();
  late final _amountController = TextEditingController();
  late DateTime _selectedDate = DateTime.now();
  late String _moneda = '';
  String? _category;
  final _descriptionFocus = FocusNode();
  final _amountFocus = FocusNode();
  bool _isKeyboardVisible = false;

  void _onFocusChange() {
    setState(() {
      _isKeyboardVisible = _descriptionFocus.hasFocus || _amountFocus.hasFocus;
    });
  }

  @override
  void initState() {
    super.initState();
    _descriptionFocus.addListener(_onFocusChange);
    _amountFocus.addListener(_onFocusChange);
    if (widget.movement != null) {
      _descriptionController.text = widget.movement!.description;
      _amountController.text = widget.movement!.amount.toStringAsFixed(2);
      widget.isExpense = widget.movement!.isExpense;
      _selectedDate = DateTime.now().copyWith(day: widget.movement!.day);
      _category = widget.movement!.category;
    }
    SharedPreferencesService()
        .getStringValue(SharedPreferencesKeys.currency)
        .then(
          (currency) => setState(() {
            _moneda = currency ?? '€'; // Valor por defecto si no se encuentra
          }),
        );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _descriptionFocus.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveMovement(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    // Prevenir múltiples guardados
    if (_isLoading) return;

    // Cerrar el teclado para mejorar la experiencia del usuario
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });
    try {
      // Parseo más robusto del monto
      String amountText = _amountController.text.trim();
      // Reemplazar comas por puntos para formato decimal
      amountText = amountText.replaceAll(',', '.');
      // Eliminar espacios
      amountText = amountText.replaceAll(' ', '');
      final amount = double.tryParse(amountText);
      if (amount == null || amount <= 0) {
        if (mounted) {
          // Toast inmediato
          Fluttertoast.showToast(
            msg: "❌ Monto inválido",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.TOP,
            timeInSecForIosWeb: 2,
            backgroundColor: Colors.orange,
            textColor: Colors.white,
            fontSize: 16.0,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(
                        context,
                      )!.pleaseEnterValidAmountGreaterThanZero,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange.shade700,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      final db = SqliteService().db;
      final financeService = FinanceService.getInstance(
        db.monthDao,
        db.movementValueDao,
        db.fixedMovementDao,
      );

      int monthId = widget.movement?.monthId ?? await db.monthDao.findMonthByMonthAndYear(
        _selectedDate.month,
        _selectedDate.year,
      );

      //aqui
      final monthId = await financeService.getMonthId(
        _selectedDate,
      ); // Generate category if needed and not already set
      if (_category == null) {
        try {
          // Agregar timeout para evitar que se quede colgado
          final generatedCategory = await GeminiService()
              .generateCategory(
                _descriptionController.text,
                widget.isExpense,
                context,
              )
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  return ''; // Retornar categoría vacía si hay timeout
                },
              );

          if (generatedCategory.isEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!.categoryNotGenerated,
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }

          _category = generatedCategory.isEmpty ? '' : generatedCategory;
        } catch (e) {
          // Si falla la generación de categoría, usar categoría vacía
          _category = '';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.errorGeneratingCategory,
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }

      final MovementValue movement;
      if (widget.movement != null) {
        // Update existing movement
        movement = MovementValue(
          widget.movement!.id,
          monthId,
          _descriptionController.text,
          amount,
          widget.isExpense,
          _selectedDate.day,
          _category,
        );
        await db.movementValueDao.updateMovementValue(movement);
      } else {
        // Create new movement
        movement = MovementValue(
          DateTime.now().millisecondsSinceEpoch, // Unique ID based on timestamp
          monthId,
          _descriptionController.text,
          amount,
          widget.isExpense,
          _selectedDate.day,
          _category?.trim(),
        );
        await db.movementValueDao.insertMovementValue(movement);
      }

      // Call haveToUpload() after any movement creation or update
      await SharedPreferencesService().haveToUpload();

      // Update FinanceService singleton
      if (mounted) {
        await financeService.updateSelectedDate(
          _selectedDate.month,
          _selectedDate.year,
        );
        // Mostrar toast de éxito
        Fluttertoast.showToast(
          msg: widget.movement != null
              ? AppLocalizations.of(context)!.movementUpdated
              : AppLocalizations.of(context)!.movementSaved,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 2,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.movement != null
                      ? AppLocalizations.of(
                          context,
                        )!.movementUpdatedSuccessfully
                      : AppLocalizations.of(context)!.movementSavedSuccessfully,
                ),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );

        Navigator.pop(context, true); // Devolver true para indicar éxito
      }
    } catch (e) {
      // Manejo de errores específicos con mensajes informativos
      String errorMessage = AppLocalizations.of(context)!.unknownError;
      String errorType = AppLocalizations.of(context)!.generalError;

      if (e.toString().contains('database')) {
        errorType = AppLocalizations.of(context)!.databaseError;
        errorMessage = AppLocalizations.of(context)!.databaseErrorMessage;
      } else if (e.toString().contains('parse') ||
          e.toString().contains('format')) {
        errorType = AppLocalizations.of(context)!.formatError;
        errorMessage = AppLocalizations.of(context)!.formatErrorMessage;
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorType = AppLocalizations.of(context)!.connectionError;
        errorMessage = AppLocalizations.of(context)!.connectionErrorMessage;
      } else if (e.toString().contains('permission')) {
        errorType = AppLocalizations.of(context)!.permissionError;
        errorMessage = AppLocalizations.of(context)!.permissionErrorMessage;
      } else if (e.toString().contains('space') ||
          e.toString().contains('storage')) {
        errorType = 'Error de almacenamiento';
        errorMessage =
            'No hay suficiente espacio de almacenamiento en el dispositivo.';
      } else {
        errorType = 'Error inesperado';
        errorMessage = 'Ocurrió un error inesperado: ${e.toString()}';
      }

      if (mounted) {
        // Mostrar toast para feedback inmediato
        Fluttertoast.showToast(
          msg: "❌ $errorType",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 3,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        // Mostrar SnackBar con información detallada
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      errorType,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(errorMessage, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      },
                      child: Text(
                        AppLocalizations.of(context)!.ok,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 8),
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Material(
      child: Padding(
        padding: EdgeInsets.only(bottom: _isKeyboardVisible ? 250 : 0),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.isExpense
                            ? localizations.newExpense
                            : localizations.newIncome,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Selector de tipo de movimiento
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment<bool>(
                        value: true,
                        label: Text(localizations.expense),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      ButtonSegment<bool>(
                        value: false,
                        label: Text(localizations.income),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                    selected: {widget.isExpense},
                    onSelectionChanged: (Set<bool> selection) {
                      setState(() {
                        widget.isExpense = selection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo de descripción
                  TextFormField(
                    controller: _descriptionController,
                    focusNode: _descriptionFocus,
                    decoration: InputDecoration(
                      labelText: localizations.description,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations.pleaseEnterDescription;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo de monto
                  TextFormField(
                    controller: _amountController,
                    focusNode: _amountFocus,
                    decoration: InputDecoration(
                      labelText: localizations.amount,
                      border: const OutlineInputBorder(),
                      suffixText: _moneda,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations.pleaseEnterAmount;
                      }
                      if (double.tryParse(value.replaceAll(',', '.')) == null) {
                        return localizations.pleaseEnterValidAmount;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Selector de fecha
                  OutlinedButton.icon(
                    onPressed: () => _selectDate(context),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      '${localizations.date}: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    ),
                  ),
                  const SizedBox(height: 16), // Botón de guardar
                  FilledButton(
                    onPressed: _isLoading ? null : () => _saveMovement(context),
                    child: _isLoading
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(localizations.saving),
                            ],
                          )
                        : Text(localizations.save),
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
