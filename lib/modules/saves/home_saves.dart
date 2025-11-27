import 'package:cashly/data/models/saves.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/saves/logic/saves_service.dart';
import 'package:cashly/modules/saves/widgets/saves_widgets.dart';
import 'package:cashly/l10n/app_localizations.dart';
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
  double _savingGoal = 0.0;
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

    final goalValue = await SharedPreferencesService().getDoubleValue(
      SharedPreferencesKeys.savingGoal,
    );
    setState(() {
      _savingGoal = goalValue ?? 0.0;
    });

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

  void _showEditGoalDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _goalController = TextEditingController(
      text: _savingGoal > 0 ? _savingGoal.toString() : '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.flag,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(AppLocalizations.of(context).setSavingsGoal),
            ],
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context).enterTargetSavings,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _goalController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).goalAmount,
                    hintText: AppLocalizations.of(context).enterAmountHint,
                    prefixIcon: const Icon(Icons.euro),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context).pleaseEnterAmount;
                    }
                    if (double.tryParse(value) == null) {
                      return AppLocalizations.of(context).pleaseEnterValidNumber;
                    }
                    if (double.parse(value) <= 0) {
                      return AppLocalizations.of(context).pleaseEnterValidAmountGreaterThanZero;
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context).cancel),
            ),
            FilledButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final newGoal = double.parse(_goalController.text);
                  await SharedPreferencesService().setDoubleValue(
                    SharedPreferencesKeys.savingGoal,
                    newGoal,
                  );
                  setState(() {
                    _savingGoal = newGoal;
                  });
                  Navigator.of(context).pop();
                }
              },
              child: Text(AppLocalizations.of(context).saveGoal),
            ),
          ],
        );
      },
    );
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
            SnackBar(content: Text(AppLocalizations.of(context).exportComingSoon)),
          );
        },
        child: const Icon(Icons.download),
      ),
      appBar: AppBar(
        toolbarHeight: kToolbarHeight + 32,
        title: Padding(
          padding: const EdgeInsets.only(top: 35.0),
          child: Text(
            AppLocalizations.of(context).savingsManagement,
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
                  SavesWidgets.DeleteInitialSaveButton(
                    context: context,
                    onPressed: () async {
                      await widget.savesService.deleteInitialSave();
                      _loadData();
                    },
                  ),
                const SizedBox(height: 24),
                SavesWidgets.OverviewCard(
                  context: context,
                  isLoading: _isLoading,
                  saves: widget.saves,
                ),
                const SizedBox(height: 24),
                SavesWidgets.KeyMetricsCard(
                  context: context,
                  metricsFunction: () => Future.wait([
                    widget.savesService.getMonthlyAverage(),
                    widget.savesService.getBestMonth(),
                    widget.savesService.getWorstMonth(),
                  ]),
                ),
                const SizedBox(height: 24),
                FutureBuilder<double>(
                  future: widget.savesService.getTotalSavings(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return SavesWidgets.GoalProgressCard(
                      context: context,
                      currentAmount: snapshot.data ?? 0.0,
                      goalAmount: _savingGoal,
                      onEditGoal: () => _showEditGoalDialog(context),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
