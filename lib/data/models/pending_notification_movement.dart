import 'package:floor/floor.dart';

@entity
class PendingNotificationMovement {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final String notificationText;
  final String appName;
  final double extractedAmount;
  final String timestamp;
  final bool isCreditCard;

  PendingNotificationMovement(
    this.notificationText,
    this.appName,
    this.extractedAmount,
    this.timestamp, {
    this.isCreditCard = false,
    this.id,
  });
}
