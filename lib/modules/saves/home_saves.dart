import 'package:cashly/data/models/saves.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/saves/logic/saves_service.dart';
import 'package:cashly/modules/saves/widgets/saves_widgets.dart';
import 'package:flutter/material.dart';

//statefull widget that shows a list of saves
class HomeSaves extends StatefulWidget {
  HomeSaves({super.key}) {
    final _db = SqliteService().db;
    savesService = SavesService(_db.savesDao);
  }
  late SavesService savesService;
  List<Saves> saves = [];
  int anno = DateTime.now().year;
  bool searchByWholeYear = false;

  @override
  State<HomeSaves> createState() => _HomeSavesState();
}

class _HomeSavesState extends State<HomeSaves> {
  bool _hasInitialSave = false;

  @override
  void initState() {
    widget.savesService.getSaves(widget.anno, widget.searchByWholeYear).then((
      value,
    ) {
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
    final saves = await widget.savesService.getSaves(
      widget.anno,
      widget.searchByWholeYear,
    );
    setState(() {
      widget.saves = saves;
    });
  }

  void _deleteInitialSave() async {
    await widget.savesService.deleteInitialSave();
    refreshSavesList();
    setState(() {
      _hasInitialSave = false;
    });
  }

  void generateInitialSave() async {
    await widget.savesService.addSave(0.0);
    refreshSavesList();
    setState(() {
      _hasInitialSave = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Savings Management',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
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
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
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
