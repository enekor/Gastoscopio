import 'package:cashly/data/dao/month_dao.dart';
import 'package:cashly/data/dao/movement_value_dao.dart';
import 'package:cashly/data/dao/saves_dao.dart';
import 'package:cashly/data/models/saves.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/saves/logic/saves_service.dart';
import 'package:cashly/modules/saves/widgets/saves_widgets.dart';
import 'package:flutter/material.dart';

//statefull widget that shows a list of saves
class HomeSaves extends StatefulWidget {
  HomeSaves({super.key}) {
    final _db = SqliteService().db;
    savesService = SavesService(
      _db.savesDao,
      _db.monthDao,
      _db.movementValueDao,
    );
  }
  late SavesService savesService;
  List<Saves> saves = [];

  @override
  State<HomeSaves> createState() => _HomeSavesState();
}

class _HomeSavesState extends State<HomeSaves> {
  bool _hasInitialSave = false;

  @override
  void initState() {
    widget.savesService.getSaves().then((value) {
      setState(() {
        widget.saves = value;
      });

      widget.savesService.getSavesByIsInitialValue().then((value) {
        setState(() {
          _hasInitialSave = value.isNotEmpty;
        });
      });
    });

    super.initState();
  }

  void refreshSavesList() async {
    final saves = await widget.savesService.getSaves();
    setState(() {
      widget.saves = saves;
    });
  }

  void _resetAllSaves() async {
    await widget.savesService.resetAllSaves();
    refreshSavesList();
  }

  void _deleteInitialSave() async {
    await widget.savesService.deleteInitialSave();
    refreshSavesList();
    setState(() {
      _hasInitialSave = false;
    });
  }

  void generateSaves() async {
    if (widget.saves.isEmpty) {
      await widget.savesService.generateAllSaves();
      final saves = await widget.savesService.getSaves();
      setState(() {
        widget.saves = saves;
      });
    } else {
      await widget.savesService.generateRemainingSaves();
      final saves = await widget.savesService.getSaves();
      setState(() {
        widget.saves = saves;
      });
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Saves generated successfully')));
  }

  void refreshSaves(DateTime date) async {
    //borra el save de widget.saves que tenga el mismo año y mes que date y ejecuta generateRemainingSaves
    Saves _s = widget.saves.firstWhere(
      (save) => save.date.year == date.year && save.date.month == date.month,
    );
    await widget.savesService.deleteSave(_s);
    widget.saves.remove(_s);
    await widget.savesService.generateRemainingSaves();

    widget.saves = await widget.savesService.getSaves();
    setState(() {});
  }

  void _refreshDatePopUp() async {
    DateTime selectedDate = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      refreshSaves(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Savings Management',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            if (!_hasInitialSave)
              SavesWidgets.AddSaveButton(
                context: context,
                onPressed: (amount) {
                  widget.savesService.addSave(amount);
                  _hasInitialSave = true;
                  refreshSavesList();
                },
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: generateSaves,
              icon: const Icon(Icons.auto_awesome, size: 20),
              label: const Text('Generate remaining saves'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _refreshDatePopUp,
              icon: const Icon(Icons.date_range, size: 20),
              label: const Text('Refresh saves for a month'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _resetAllSaves,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Refresh all saves'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _deleteInitialSave,
              icon: const Icon(Icons.delete_outline, size: 20),
              label: const Text('Delete initial save'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.trending_up,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Savings Overview',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SavesWidgets.LinearChart(widget.saves),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
