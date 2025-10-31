import 'package:cashly/data/models/saves.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/saves/logic/saves_service.dart';
import 'package:cashly/modules/saves/widgets/saves_widgets.dart';
import 'package:flutter/material.dart';

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

  // Removed _buildMetricRow as it's now in SavesWidgets

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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implementar exportación
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Export feature coming soon')),
          );
        },
        child: const Icon(Icons.download),
      ),
      appBar: AppBar(
        toolbarHeight: kToolbarHeight + 32,
        title: Padding(
          padding: const EdgeInsets.only(top: 35.0),
          child: Text(
            'Savings Management',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(top: 35.0),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new),
          ),
        ),
      ),
      body: FutureBuilder(
        future: _initializationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                SavesWidgets.KeyMetricsCard(
                  context: context,
                  metricsFunction: () => Future.wait([
                    widget.savesService.getMonthlyAverage(),
                    widget.savesService.getBestMonth(),
                    widget.savesService.getWorstMonth(),
                  ]),
                ),
                const SizedBox(height: 24),
                SavesWidgets.ViewSelectionCard(
                  context: context,
                  viewByYear: _viewByYear,
                  onViewChanged: (value) {
                    setState(() {
                      _viewByYear = value;
                      widget.searchByWholeYear = value;
                    });
                    _loadData();
                  },
                  currentYear: widget.anno,
                  yearsFunction: () =>
                      SqliteService().db.monthDao.findAllDistinctYears(),
                  onYearChanged: (selectedYear) {
                    setState(() {
                      widget.anno = selectedYear;
                    });
                    _loadData();
                  },
                ),
                const SizedBox(height: 24),
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
                SavesWidgets.OverviewCard(
                  context: context,
                  isLoading: _isLoading,
                  saves: widget.saves,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
