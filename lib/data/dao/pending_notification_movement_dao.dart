import 'package:floor/floor.dart';
import '../models/pending_notification_movement.dart';

@dao
abstract class PendingNotificationMovementDao {
  @Query('SELECT * FROM PendingNotificationMovement ORDER BY timestamp DESC')
  Future<List<PendingNotificationMovement>> findAll();

  @Query('SELECT COUNT(*) FROM PendingNotificationMovement')
  Future<int?> countAll();

  @insert
  Future<void> insertPendingMovement(PendingNotificationMovement movement);

  @delete
  Future<void> deletePendingMovement(PendingNotificationMovement movement);

  @Query('DELETE FROM PendingNotificationMovement')
  Future<void> deleteAll();
}
