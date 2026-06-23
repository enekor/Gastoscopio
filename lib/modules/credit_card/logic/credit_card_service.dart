import 'package:cashly/data/models/credit_card_expense.dart';
import 'package:cashly/data/models/credit_card_month.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/data/services/background_task_service.dart';
import 'package:flutter/foundation.dart';

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

  Future<void> addExpense(String description, double amount, DateTime date) async {
    if (currentMonth == null) return;
    
    final db = SqliteService().db;
    final expense = CreditCardExpense(
      monthId: currentMonth!.id!,
      description: description,
      amount: amount,
      day: date.day,
      date: date.toIso8601String(),
    );
    
    await db.creditCardExpenseDao.insertExpense(expense);
    currentExpenses = await db.creditCardExpenseDao.findExpensesByMonthId(currentMonth!.id!);
    
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
