import 'package:cashly/data/models/credit_card_expense.dart';
import 'package:cashly/data/models/credit_card_month.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/data/services/background_task_service.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class CreditCardService extends ChangeNotifier {
  static CreditCardService? _instance;
  
  CreditCardMonth? currentMonth;
  List<CreditCardExpense> currentExpenses = [];
  List<CreditCardMonth> allMonths = [];

  CreditCardService._();

  static CreditCardService getInstance() {
    _instance ??= CreditCardService._();
    return _instance!;
  }

  Future<void> loadMonthData(int month, int year) async {
    final db = SqliteService().db;
    
    currentMonth = await db.creditCardMonthDao.findMonth(month, year);
    
    if (currentMonth != null) {
      currentExpenses = await db.creditCardExpenseDao.findExpensesByMonthId(currentMonth!.id!);
    } else {
      currentExpenses = [];
    }
    
    allMonths = await db.creditCardMonthDao.findAllMonths();
    
    notifyListeners();
  }

  Future<void> _updateNotification() async {
    await BackgroundTaskService().scheduleWeeklyCreditCardCheck();
  }

  Future<void> setMonthLimit(int month, int year, double limit) async {
    final db = SqliteService().db;
    
    if (currentMonth != null && currentMonth!.month == month && currentMonth!.year == year) {
      final updatedMonth = CreditCardMonth(
        id: currentMonth!.id,
        month: month,
        year: year,
        limitAmount: limit,
      );
      await db.creditCardMonthDao.updateMonth(updatedMonth);
      currentMonth = updatedMonth;
    } else {
      final newMonth = CreditCardMonth(
        month: month,
        year: year,
        limitAmount: limit,
      );
      await db.creditCardMonthDao.insertMonth(newMonth);
      currentMonth = await db.creditCardMonthDao.findMonth(month, year);
    }
    
    allMonths = await db.creditCardMonthDao.findAllMonths();
    notifyListeners();
    await _updateNotification();
  }

  Future<DateTime> getTargetMonth(DateTime date) async {
    final prefs = SharedPreferencesService();
    final cycle = await prefs.getStringValue(SharedPreferencesKeys.creditCardBillingCycle) ?? 'monthly';
    final billingDay = (await prefs.getDoubleValue(SharedPreferencesKeys.creditCardBillingDay))?.toInt() ?? 1;

    if (cycle == 'weekly') {
      // Si es semanal, billingDay es el día de la semana (1=Lunes, 7=Domingo)
      // Buscamos el próximo día de cobro.
      DateTime nextBilling = date;
      // Si hoy es el día de cobro, el gasto de hoy ya podría contar para el siguiente ciclo si el cobro es a primera hora, 
      // pero usualmente es al final del día. El usuario dice "martes 30 ... cuente para el siguiente".
      // Si el cobro fue el lunes 29, el martes 30 ya es del siguiente ciclo.
      // Así que si date.weekday >= billingDay, pertenece al ciclo que termina en el próximo billingDay.
      
      // Lógica: Si el día de la semana es MAYOR O IGUAL al billingDay, 
      // avanzamos hasta el próximo billingDay (que será en la semana siguiente).
      // Si ese próximo billingDay cae en otro mes, el gasto es del mes siguiente.
      
      int daysToAdd = (billingDay - date.weekday) % 7;
      if (daysToAdd <= 0) daysToAdd += 7;
      
      DateTime nextBillingDay = date.add(Duration(days: daysToAdd));
      
      if (nextBillingDay.month != date.month) {
        return DateTime(nextBillingDay.year, nextBillingDay.month);
      }
      return DateTime(date.year, date.month);
    } else {
      // Mensual: si el día es >= billingDay, pasa al mes siguiente.
      if (date.day >= billingDay) {
        final nextMonth = DateTime(date.year, date.month + 1);
        return DateTime(nextMonth.year, nextMonth.month);
      }
      return DateTime(date.year, date.month);
    }
  }

  Future<double> getDefaultLimit() async {
    final prefs = SharedPreferencesService();
    return await prefs.getDoubleValue(SharedPreferencesKeys.creditCardDefaultLimit) ?? 1000.0;
  }

  Future<void> addExpense(String description, double amount, DateTime date) async {
    final targetDate = await getTargetMonth(date);
    final db = SqliteService().db;
    
    CreditCardMonth? month = await db.creditCardMonthDao.findMonth(targetDate.month, targetDate.year);
    
    if (month == null) {
      final limit = await getDefaultLimit();
      final newMonth = CreditCardMonth(
        month: targetDate.month,
        year: targetDate.year,
        limitAmount: limit,
      );
      await db.creditCardMonthDao.insertMonth(newMonth);
      month = await db.creditCardMonthDao.findMonth(targetDate.month, targetDate.year);
    }

    if (month == null) return;

    final expense = CreditCardExpense(
      monthId: month.id!,
      description: description,
      amount: amount,
      day: date.day,
      date: date.toIso8601String(),
      uuid: const Uuid().v4(),
      ts: DateTime.now().millisecondsSinceEpoch,
    );
    
    await db.creditCardExpenseDao.insertExpense(expense);
    
    if (currentMonth != null && currentMonth!.id == month.id) {
      currentExpenses = await db.creditCardExpenseDao.findExpensesByMonthId(currentMonth!.id!);
    }
    
    allMonths = await db.creditCardMonthDao.findAllMonths();
    notifyListeners();
    await _updateNotification();
  }

  Future<void> updateExpense(CreditCardExpense expense) async {
    final db = SqliteService().db;
    await db.creditCardExpenseDao.updateExpense(expense);
    
    if (currentMonth != null) {
      currentExpenses = await db.creditCardExpenseDao.findExpensesByMonthId(currentMonth!.id!);
      notifyListeners();
      await _updateNotification();
    }
  }

  Future<void> deleteExpense(CreditCardExpense expense) async {
    final db = SqliteService().db;
    await db.creditCardExpenseDao.deleteExpense(expense);
    
    if (currentMonth != null) {
      currentExpenses = await db.creditCardExpenseDao.findExpensesByMonthId(currentMonth!.id!);
      notifyListeners();
      await _updateNotification();
    }
  }

  double get totalSpent {
    return currentExpenses.fold(0, (sum, item) => sum + item.amount);
  }

  double get remainingAmount {
    if (currentMonth == null) return 0;
    return currentMonth!.limitAmount - totalSpent;
  }
}
