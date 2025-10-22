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
  int anno = DateTime.now().year;
  bool searchByWholeYear = false;

  @override
  State<HomeSaves> createState() => _HomeSavesState();
}

class _HomeSavesState extends State<HomeSaves> {
  bool _hasInitialSave = false;
  bool _isLoading = true;
  bool _viewByYear = false;
  late final Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initialize();
  }

  Future<void> _initialize() async {
    bool needToGenerate = await widget.savesService.needToGenerate();
    if (needToGenerate) {
      await widget.savesService.generateAllSaves();
    }
    await _loadData();
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

  void generateInitialSave() async {
    await widget.savesService.addSave(0.0);
    refreshSavesList();
    setState(() {
      _hasInitialSave = true;
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Cargar los datos de ahorros
      final saves = await widget.savesService.getSaves(
        widget.anno,
        _viewByYear,
      );

      // Verificar si existe un ahorro inicial
      final initialSaves = await widget.savesService.getSavesByIsInitialValue();

      if (initialSaves.isNotEmpty && !widget.searchByWholeYear) {
        saves.addAll(initialSaves);
      }

      setState(() {
        widget.saves = saves;
        _hasInitialSave = initialSaves.isNotEmpty;
      });
    } finally {
      setState(() => _isLoading = false);
    }
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
      body: FutureBuilder(
        future: _initializationFuture,
        builder: (context, asyncSnapshot) {
          if (asyncSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (asyncSnapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${asyncSnapshot.error}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }

          if (!asyncSnapshot.hasData) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Vista por año/mes switch
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                _viewByYear
                                    ? Icons.calendar_today
                                    : Icons.calendar_month,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _viewByYear ? 'Yearly View' : 'Monthly View',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              Switch(
                                value: _viewByYear,
                                onChanged: (value) {
                                  setState(() {
                                    _viewByYear = value;
                                    widget.searchByWholeYear = value;
                                  });
                                  _loadData();
                                },
                              ),
                            ],
                          ),
                          if (_viewByYear) ...[
                            const SizedBox(height: 16),
                            DropdownButton<int>(
                              value: widget.anno,
                              isExpanded: true,
                              items: List.generate(
                                5,
                                (index) => DropdownMenuItem(
                                  value: DateTime.now().year - index,
                                  child: Text('${DateTime.now().year - index}'),
                                ),
                              ),
                              onChanged: (selectedYear) {
                                if (selectedYear != null) {
                                  setState(() {
                                    widget.anno = selectedYear;
                                  });
                                  _loadData();
                                }
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botón condicional (Añadir/Eliminar ahorro inicial)
                  if (!_hasInitialSave)
                    SavesWidgets.AddSaveButton(
                      context: context,
                      onPressed: (amount) async {
                        await widget.savesService.addSave(amount);
                        _loadData();
                      },
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () async {
                        await widget.savesService.deleteInitialSave();
                        _loadData();
                      },
                      icon: const Icon(Icons.delete_outline, size: 20),
                      label: const Text('Delete Initial Save'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        foregroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: _isLoading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.trending_up,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Savings Overview',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
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
            );
          }

          return Center(
            child: Text(
              'No savings data available.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        },
      ),
    );
  }
}
