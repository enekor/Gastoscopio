import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';

// Esta función debe ser de nivel superior (top-level)
@pragma('vm:entry-point')
void backgroundNotificationTask() async {
  try {
    // 1. Inicializar la base de datos
    await SqliteService().initializeDatabase();
    final db = SqliteService().db;

    // 2. Obtener el mes y año actuales
    final now = DateTime.now();
    
    // 3. Buscar si hay datos de tarjeta para este mes
    final currentMonth = await db.creditCardMonthDao.findMonth(now.month, now.year);
    
    if (currentMonth != null) {
      // 4. Calcular los gastos
      final expenses = await db.creditCardExpenseDao.findExpensesByMonthId(currentMonth.id!);
      final totalSpent = expenses.fold(0.0, (sum, item) => sum + item.amount);
      final remainingAmount = currentMonth.limitAmount - totalSpent;

      // 5. Obtener la moneda
      final currency = await SharedPreferencesService().getStringValue(SharedPreferencesKeys.currency) ?? '€';

      // 6. Enviar la notificación
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      
      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);

      const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'credit_card_channel',
        'Tarjeta de Crédito',
        channelDescription: 'Notificaciones semanales de la tarjeta de crédito',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );
      
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: DarwinNotificationDetails(),
      );

      await flutterLocalNotificationsPlugin.show(
        0,
        'Resumen de Tarjeta de Crédito',
        'Te quedan ${remainingAmount.toStringAsFixed(2)}$currency de límite.',
        platformChannelSpecifics,
        payload: 'credit_card',
      );
    }
  } catch (e) {
    print("Error en tarea de background: $e");
  }
}

class BackgroundTaskService {
  static final BackgroundTaskService _instance = BackgroundTaskService._internal();
  static const int _alarmId = 1001;

  factory BackgroundTaskService() {
    return _instance;
  }

  BackgroundTaskService._internal();

  Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
  }

  Future<void> scheduleWeeklyCreditCardCheck() async {
    // Calculamos el retraso inicial hasta el próximo domingo al mediodía (aprox)
    final now = DateTime.now();
    int daysUntilSunday = DateTime.sunday - now.weekday;
    if (daysUntilSunday < 0) {
      daysUntilSunday += 7;
    }
    
    // Si es domingo pero ya pasó el mediodía, programamos para el próximo
    if (daysUntilSunday == 0 && now.hour >= 12) {
      daysUntilSunday += 7;
    }

    final targetDate = DateTime(now.year, now.month, now.day, 12, 0).add(Duration(days: daysUntilSunday));

    // Programamos la alarma periódica usando AndroidAlarmManager
    // Al usar wakeup: false, permitimos que el sistema agrupe las alarmas para ahorrar batería
    // No sonará una alarma, simplemente despertará el proceso en segundo plano
    await AndroidAlarmManager.periodic(
      const Duration(days: 7),
      _alarmId,
      backgroundNotificationTask,
      startAt: targetDate,
      exact: false, // Permite al sistema optimizar el momento exacto
      wakeup: false, // No enciende la pantalla ni interrumpe el sueño profundo (Doze)
      rescheduleOnReboot: true,
    );
  }
}
