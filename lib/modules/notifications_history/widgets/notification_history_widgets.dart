import 'package:flutter/material.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/l10n/app_localizations.dart';

class NotificationWidget extends StatefulWidget {
  final String title;
  final double value;
  final BuildContext parentContext;
  final int monthId;
  final Function(MovementValue) onSave;

  const NotificationWidget(
    this.title,
    this.value,
    this.parentContext,
    this.monthId,
    this.onSave, {
    Key? key,
  }) : super(key: key);

  @override
  State<NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<NotificationWidget> {
  bool _isExpense = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          title: Text(
            widget.title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.value.abs().toStringAsFixed(2),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      widget.value < 0
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context).isExpense,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Switch(
                    value: _isExpense,
                    onChanged: (value) {
                      setState(() {
                        _isExpense = value;
                      });
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.add_circle_outline),
            color: Theme.of(context).colorScheme.primary,
            onPressed:
                widget.monthId == -1
                    ? null
                    : () async {
                      final movement = MovementValue(
                        -1,
                        widget.monthId,
                        widget.title,
                        widget.value.abs(),
                        _isExpense,
                        DateTime.now().day,
                        null,
                      );

                      await widget.onSave(movement);

                      if (widget.parentContext.mounted) {
                        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(
                                widget.parentContext,
                              ).movementAdded,
                            ),
                            backgroundColor:
                                Theme.of(
                                  widget.parentContext,
                                ).colorScheme.primary,
                          ),
                        );
                      }
                    },
            tooltip:
                widget.monthId == -1
                    ? AppLocalizations.of(context).noActiveMonth
                    : AppLocalizations.of(context).addMovement,
          ),
        ),
      ],
    );
  }
}
