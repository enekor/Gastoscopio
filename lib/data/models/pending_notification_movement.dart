import 'package:floor/floor.dart';

@entity
class PendingNotificationMovement {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final String notificationText;
  final String appName;
  final double extractedAmount;
  final String timestamp;

  PendingNotificationMovement(
    this.notificationText,
    this.appName,
    this.extractedAmount,
    this.timestamp, {
    this.id,
  });
}
