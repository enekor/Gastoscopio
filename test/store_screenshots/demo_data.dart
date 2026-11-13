import 'package:cashly/common/tag_list.dart';
import 'package:cashly/data/models/credit_card_expense.dart';
import 'package:cashly/data/models/credit_card_month.dart';
import 'package:cashly/data/models/fixed_movement.dart';
import 'package:cashly/data/models/month.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';

/// Demo data used only for the Play Store screenshots.
///
/// Descriptions are deliberately generic (no real brand names) so the store
/// listing does not show third-party trademarks.
class DemoLocale {
  final String code;
  final String currency;
  final String cardHolder;
  final Map<String, String> text;
  const DemoLocale(this.code, this.currency, this.cardHolder, this.text);

  String t(String key) => text[key] ?? key;

  /// Category name as stored by the app for this language, looked up by its
  /// icon file so it does not depend on the order of tagDataList.
  String cat(String icon) {
    final tag = tagDataList.firstWhere(
      (t) => t.iconPath == 'assets/icons/$icon.svg',
    );
    return code == 'es' ? tag.tagEs : tag.tagEn;
  }
}

// Category icons (assets/icons/*.svg), used to look up the category names.
const _housing = 'housing';
const _grocery = 'grocery';
const _leisure = 'entertainment';
const _restaurants = 'restaurant_bar';
const _utilities = 'home_utilities';
const _transport = 'transportation';
const _health = 'health';
const _education = 'education';
const _clothing = 'clothing';
const _travel = 'travel';
const _gifts = 'gifts';
const _electronics = 'electronics';
const _insurance = 'insurance';
const _sports = 'sports';
const _subscriptions = 'subscriptions';
const _salary = 'salary';
const _otherIncome = 'other_income';

const demoEs = DemoLocale('es', '€', 'Alex Martín', {
  'salary': 'Nómina',
  'rent': 'Alquiler del piso',
  'supermarket': 'Compra semanal',
  'supermarket2': 'Supermercado',
  'power': 'Factura de la luz',
  'internet': 'Fibra y móvil',
  'fuel': 'Gasolina',
  'streaming': 'Plataforma de streaming',
  'music': 'Música en streaming',
  'dinner': 'Cena con amigos',
  'coffee': 'Café y desayuno',
  'pharmacy': 'Farmacia',
  'clothes': 'Zapatillas nuevas',
  'cinema': 'Entradas de cine',
  'sold': 'Venta de segunda mano',
  'trip': 'Escapada de fin de semana',
  'gift': 'Regalo de cumpleaños',
  'headphones': 'Auriculares',
  'books': 'Libros de la universidad',
  'gym': 'Cuota del gimnasio',
  'carInsurance': 'Seguro del coche',
  'course': 'Curso de inglés',
  'friendOwes': 'Me debe Carlos (cena)',
  'cardOnline': 'Compra online',
  'cardSport': 'Tienda de deporte',
  'cardFuel': 'Gasolinera',
  'cardRestaurant': 'Restaurante',
  'cardDept': 'Grandes almacenes',
});

// Euro in both languages: the statistics screen always shows '€'.
const demoEn = DemoLocale('en', '€', 'Alex Morgan', {
  'salary': 'Paycheck',
  'rent': 'Apartment rent',
  'supermarket': 'Weekly groceries',
  'supermarket2': 'Supermarket',
  'power': 'Electricity bill',
  'internet': 'Internet & phone',
  'fuel': 'Gas',
  'streaming': 'Streaming service',
  'music': 'Music streaming',
  'dinner': 'Dinner with friends',
  'coffee': 'Coffee & breakfast',
  'pharmacy': 'Pharmacy',
  'clothes': 'New sneakers',
  'cinema': 'Movie tickets',
  'sold': 'Second-hand sale',
  'trip': 'Weekend getaway',
  'gift': 'Birthday present',
  'headphones': 'Headphones',
  'books': 'College books',
  'gym': 'Gym membership',
  'carInsurance': 'Car insurance',
  'course': 'English course',
  'friendOwes': 'Carlos owes me (dinner)',
  'cardOnline': 'Online order',
  'cardSport': 'Sports store',
  'cardFuel': 'Gas station',
  'cardRestaurant': 'Restaurant',
  'cardDept': 'Department store',
});

class _Mov {
  final String key;
  final double amount;
  final bool isExpense;
  final int day;
  final String category;
  const _Mov(
    this.key,
    this.amount,
    this.day,
    this.category, {
    this.isExpense = true,
  });
}

/// Movements repeated every month (amounts vary slightly by month offset).
List<_Mov> _baseMonth(int offset) {
  final v = [1.0, 1.08, 0.94, 1.12, 0.97, 1.05][offset % 6];
  return [
    const _Mov('salary', 2150, 1, _salary, isExpense: false),
    const _Mov('rent', 750, 1, _housing),
    _Mov(
      'supermarket',
      double.parse((86.40 * v).toStringAsFixed(2)),
      3,
      _grocery,
    ),
    _Mov('power', double.parse((54.20 * v).toStringAsFixed(2)), 5, _utilities),
    const _Mov('internet', 45.90, 5, _utilities),
    _Mov('fuel', double.parse((60.00 * v).toStringAsFixed(2)), 6, _transport),
    const _Mov('streaming', 12.99, 7, _subscriptions),
    _Mov(
      'dinner',
      double.parse((38.50 * v).toStringAsFixed(2)),
      8,
      _restaurants,
    ),
    const _Mov('pharmacy', 14.30, 10, _health),
    _Mov(
      'supermarket2',
      double.parse((42.75 * v).toStringAsFixed(2)),
      11,
      _grocery,
    ),
    const _Mov('coffee', 3.20, 12, _restaurants),
    const _Mov('music', 10.99, 14, _subscriptions),
    _Mov(
      'supermarket',
      double.parse((91.10 * v).toStringAsFixed(2)),
      17,
      _grocery,
    ),
    _Mov('fuel', double.parse((55.00 * v).toStringAsFixed(2)), 20, _transport),
    _Mov(
      'dinner',
      double.parse((26.40 * v).toStringAsFixed(2)),
      22,
      _restaurants,
    ),
    _Mov(
      'supermarket2',
      double.parse((64.30 * v).toStringAsFixed(2)),
      25,
      _grocery,
    ),
  ];
}

/// One distinctive extra per month so the history charts are not flat.
const _extras = <int, List<_Mov>>{
  0: [
    _Mov('clothes', 49.95, 11, _clothing),
    _Mov('sold', 45.00, 9, _otherIncome, isExpense: false),
  ],
  1: [_Mov('trip', 236.00, 18, _travel)],
  2: [_Mov('gift', 65.00, 15, _gifts), _Mov('cinema', 18.00, 21, _leisure)],
  3: [_Mov('headphones', 129.00, 12, _electronics)],
  4: [_Mov('books', 84.50, 9, _education), _Mov('cinema', 16.00, 23, _leisure)],
  5: [_Mov('sold', 120.00, 16, _otherIncome, isExpense: false)],
};

/// Inserts six months of demo data, fixed movements, debts and a credit card
/// month. Must run in a real async zone (tester.runAsync).
Future<void> seedDemoData(DemoLocale demo, DateTime now) async {
  final db = SqliteService().db;

  for (var offset = 5; offset >= 0; offset--) {
    final date = DateTime(now.year, now.month - offset);
    await db.monthDao.insertMonth(Month(date.month, date.year));
    final month = await db.monthDao.findMonthByMonthAndYear(
      date.month,
      date.year,
    );
    final movements = [..._baseMonth(offset), ...?_extras[offset]];
    for (final m in movements) {
      // The current month only has what already happened up to today.
      if (offset == 0 && m.day > now.day) continue;
      await db.movementValueDao.insertMovementValue(
        MovementValue(
          null,
          month!.id!,
          demo.t(m.key),
          m.amount,
          m.isExpense,
          m.day,
          demo.cat(m.category),
        ),
      );
    }
  }

  for (final f in [
    const _Mov('salary', 2150, 1, _salary, isExpense: false),
    const _Mov('rent', 750, 1, _housing),
    const _Mov('internet', 45.90, 5, _utilities),
    const _Mov('streaming', 12.99, 7, _subscriptions),
    const _Mov('music', 10.99, 14, _subscriptions),
  ]) {
    await db.fixedMovementDao.insertFixedMovement(
      FixedMovement(
        null,
        demo.t(f.key),
        f.amount,
        f.isExpense,
        f.day,
        demo.cat(f.category),
      ),
    );
  }

  final finance = FinanceService.getInstance(
    db.monthDao,
    db.movementValueDao,
    db.fixedMovementDao,
  );
  await finance.setCurrentMonth(now.month, now.year);
  await finance.createMonthlyDebtDefinition(
    description: demo.t('gym'),
    amount: 39.90,
    isExpense: true,
    day: 15,
    category: demo.cat(_sports),
  );
  await finance.createMonthlyDebtDefinition(
    description: demo.t('carInsurance'),
    amount: 48.50,
    isExpense: true,
    day: 20,
    category: demo.cat(_insurance),
  );
  await finance.createOneTimeDebt(
    description: demo.t('course'),
    amount: 180,
    isExpense: true,
    date: DateTime(now.year, now.month, 28),
    category: demo.cat(_education),
  );
  await finance.createOneTimeDebt(
    description: demo.t('friendOwes'),
    amount: 22.50,
    isExpense: false,
    date: DateTime(now.year, now.month, 18),
    category: demo.cat(_otherIncome),
  );

  final cardMonthId = await db.creditCardMonthDao.insertMonth(
    CreditCardMonth(month: now.month, year: now.year, limitAmount: 1200),
  );
  final cardExpenses = <(String, double, int)>[
    ('cardOnline', 34.99, 2),
    ('cardSport', 59.90, 4),
    ('cardFuel', 45.00, 7),
    ('cardRestaurant', 27.80, 9),
    ('cardDept', 89.00, 11),
  ];
  for (final (key, amount, day) in cardExpenses) {
    final date = DateTime(now.year, now.month, day, 18, 30);
    await db.creditCardExpenseDao.insertExpense(
      CreditCardExpense(
        monthId: cardMonthId,
        description: demo.t(key),
        amount: amount,
        day: day,
        date: date.toIso8601String(),
        uuid: 'demo-$key',
        ts: date.millisecondsSinceEpoch,
      ),
    );
  }
}
