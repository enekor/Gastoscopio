import 'package:floor/floor.dart';
import 'package:cashly/data/models/debt_definition.dart';
import 'package:cashly/data/models/month.dart';

const String debtStatusPending = 'pending';
const String debtStatusCompleted = 'completed';

@Entity(
  tableName: 'DebtOccurrence',
  foreignKeys: [
    ForeignKey(
      childColumns: ['debtDefinitionId'],
      parentColumns: ['id'],
      entity: DebtDefinition,
      onDelete: ForeignKeyAction.cascade,
    ),
    ForeignKey(
      childColumns: ['monthId'],
      parentColumns: ['id'],
      entity: Month,
      onDelete: ForeignKeyAction.cascade,
    ),
  ],
  indices: [
    Index(value: ['debtDefinitionId', 'monthId'], unique: true),
  ],
)
class DebtOccurrence {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final int debtDefinitionId;
  final int monthId;
  final int dueDay;
  final int originMonth;
  final int originYear;
  final String status;
  final String? completedAt;

  DebtOccurrence(
    this.id,
    this.debtDefinitionId,
    this.monthId,
    this.dueDay,
    this.originMonth,
    this.originYear,
    this.status,
    this.completedAt,
  );

  DebtOccurrence copyWith({
    int? id,
    int? debtDefinitionId,
    int? monthId,
    int? dueDay,
    int? originMonth,
    int? originYear,
    String? status,
    String? completedAt,
  }) {
    return DebtOccurrence(
      id ?? this.id,
      debtDefinitionId ?? this.debtDefinitionId,
      monthId ?? this.monthId,
      dueDay ?? this.dueDay,
      originMonth ?? this.originMonth,
      originYear ?? this.originYear,
      status ?? this.status,
      completedAt ?? this.completedAt,
    );
  }
}
