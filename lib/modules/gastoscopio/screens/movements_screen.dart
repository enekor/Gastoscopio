import 'package:cashly/data/services/gemini_service.dart';
import 'package:cashly/data/services/groq_serice.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/data/services/log_file_service.dart';
import 'package:cashly/modules/gastoscopio/screens/movement_form_screen.dart';
import 'package:cashly/modules/gastoscopio/widgets/loading.dart';
import 'package:cashly/modules/gastoscopio/widgets/main_screen_widgets.dart';
import 'package:cashly/modules/gastoscopio/widgets/movement_tile.dart';
import 'package:cashly/common/tag_list.dart' show getTagList;
import 'package:cashly/common/month_names.dart';
import 'package:cashly/modules/gastoscopio/widgets/tag_list.dart';
import 'package:flutter/material.dart';
import 'package:cashly/l10n/app_localizations.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:cashly/theme/app_glass.dart';
import 'package:cashly/theme/widgets/glass_card.dart';
import 'package:cashly/theme/widgets/app_segmented_control.dart';
import 'package:cashly/theme/widgets/amount_text.dart';

class MovementsScreen extends StatefulWidget {
  final int year;
  final int month;

  const MovementsScreen({Key? key, required this.year, required this.month})
    : super(key: key);

  @override
  State<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen>
    with TickerProviderStateMixin {
  // 0 = Todos, 1 = Ingresos, 2 = Gastos
  int _filterMode = 0;
  DateTime? _selectedDate;
  String? _selectedCategory;
  String _searchQuery = '';
  final Map<String, bool> _expandedItems = {};
  late String _moneda;
  late FinanceService _financeService;
  final TextEditingController _searchController = TextEditingController();

  String? _currentSortType;
  bool _isAscending = true;

  List<MovementValue> _cachedMovements = [];
  bool _isLoading = true;

  late AnimationController _listAnimationController;
  late AnimationController _toggleAnimationController;
  late Animation<double> _listFadeAnimation;
  late Animation<double> _toggleAnimation;

  @override
  void initState() {
    super.initState();

    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _toggleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _listFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _listAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _toggleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _toggleAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _financeService = FinanceService.getInstance(
      SqliteService().db.monthDao,
      SqliteService().db.movementValueDao,
      SqliteService().db.fixedMovementDao,
    );

    _financeService.addListener(_onFinanceServiceChanged);

    SharedPreferencesService()
        .getStringValue(SharedPreferencesKeys.currency)
        .then(
          (currency) => setState(() {
            _moneda = currency ?? '€';
          }),
        );

    _searchController.text = _searchQuery;
    _loadMovements();

    _listAnimationController.forward();
    _toggleAnimationController.forward();
  }

  void _onFinanceServiceChanged() {
    _loadMovements();
  }

  Future<void> _loadMovements() async {
    try {
      var movements = await _financeService.getCurrentMonthMovements();

      if (_cachedMovements.isNotEmpty) {
        await _listAnimationController.reverse();
      }

      movements.sort((a, b) => a.day.compareTo(b.day));
      movements = movements.reversed.toList();

      if (mounted) {
        setState(() {
          _cachedMovements = movements;
          _isLoading = false;
          _applySorting();
        });
        await _listAnimationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      LogFileService().appendLog('Error loading movements: $e');
    }
  }

  Future<void> _deleteAllTags() async {
    bool delete =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context).confrmTagDelete),
            content: Text(AppLocalizations.of(context).confirmDeleteAllTags),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(AppLocalizations.of(context).cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(AppLocalizations.of(context).ok),
              ),
            ],
          ),
        ) ??
        false;
    
    if (!delete) return;

    List<MovementValue> movements = await _financeService
        .getCurrentMonthMovements();
    movements = movements
        .where((m) => m.category != null && m.category!.isNotEmpty)
        .toList();

    if (movements.isEmpty) return;

    for (final movement in movements) {
      final updatedMovement = movement.copyWith(category: null);
      await _financeService.updateMovement(updatedMovement);
      await SharedPreferencesService().haveToUpload();
    }

    await _loadMovements();
  }

  Future<void> _autoGenerateTags() async {
    List<MovementValue> movements = await _financeService
        .getCurrentMonthMovements();
    movements = movements
        .where((m) => m.category == null || m.category!.isEmpty)
        .toList();

    if (movements.isEmpty) return;
    List<String> tags = await GroqService().generateTags(
      movements
          .map((m) => '${m.description} (${m.isExpense ? "gasto" : "ingreso"})')
          .join(','),
      context,
    );
    if (tags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.noTagsGenerated,
            style: TextStyle(color: Theme.of(context).colorScheme.onError),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    for (int i = 0; i < movements.length; i++) {
      final movement = movements[i];
      final tag = tags[i % tags.length];
      final updatedMovement = movement.copyWith(category: tag);
      await _financeService.updateMovement(updatedMovement);
      await SharedPreferencesService().haveToUpload();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _financeService.removeListener(_onFinanceServiceChanged);
    _listAnimationController.dispose();
    _toggleAnimationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MovementsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.year != widget.year || oldWidget.month != widget.month) {
      _loadMovements();
    }
  }

  @override
  Widget build(BuildContext context) {
    bool _showFutureMovements = _financeService.currentMonth!.month ==
        DateTime.now().month &&
        _financeService.currentMonth!.year == DateTime.now().year;

    if (_isLoading) {
      return Center(child: Loading(context));
    }

    final filteredMovements = _filterMovements(_cachedMovements);
    final totalAmount = filteredMovements.fold<double>(
      0,
      (sum, movement) =>
          sum + (movement.isExpense ? -movement.amount : movement.amount),
    );

    final glass = Theme.of(context).extension<AppGlass>()!;
    final themeColor = _filterMode == 2
        ? glass.expenseColor
        : _filterMode == 1
            ? glass.incomeColor
            : Theme.of(context).colorScheme.primary;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          sliver: SliverToBoxAdapter(
            child: _buildTypeSelector(),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          sliver: SliverToBoxAdapter(
            child: _buildSearchToolBar(context),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          sliver: SliverToBoxAdapter(
            child: _buildModernTotalCard(
              totalAmount,
              filteredMovements.length,
              themeColor,
            ),
          ),
        ),
        if (_expandedItems['filters'] ?? false)
          SliverToBoxAdapter(child: _buildFilters()),
        
        if (_showFutureMovements)
          SliverToBoxAdapter(
            child: _buildFutureMovementsCard(
              filteredMovements
                  .where((mov) => mov.day > DateTime.now().day)
                  .toList(),
            ),
          ),

        if (_cachedMovements.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _filterMode == 1 ? Icons.attach_money : Icons.money_off,
                    size: 64,
                    color: Theme.of(context).disabledColor.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _filterMode == 1
                        ? AppLocalizations.of(context).noIncomes
                        : AppLocalizations.of(context).noExpenses,
                    style: TextStyle(
                      color: Theme.of(context).disabledColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: AnimatedBuilder(
              animation: _listFadeAnimation,
              builder: (context, child) {
                List<MovementValue> _showingValues = !_showFutureMovements 
                  ? filteredMovements 
                  : filteredMovements.where((mov) => mov.day <= DateTime.now().day).toList();

                return SliverOpacity(
                  opacity: _listFadeAnimation.value,
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final movement = _showingValues[index];
                        final isExpanded = _expandedItems[movement.id.toString()] ?? false;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildSwipeableMovementTile(
                            movement: movement,
                            isExpanded: isExpanded,
                          ),
                        );
                      },
                      childCount: _showingValues.length,
                    ),
                  ),
                );
              },
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return AppSegmentedControl<int>(
      selected: _filterMode,
      segments: [
        (value: 0, label: AppLocalizations.of(context)!.all, icon: null),
        (
          value: 1,
          label: AppLocalizations.of(context)!.incomes,
          icon: Icons.arrow_upward,
        ),
        (
          value: 2,
          label: AppLocalizations.of(context)!.expenses,
          icon: Icons.arrow_downward,
        ),
      ],
      onChanged: (value) {
        setState(() {
          _filterMode = value;
        });
      },
    );
  }

  Widget _buildModernTotalCard(double total, int count, Color color) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    final monthName = monthFullNames(
      AppLocalizations.of(context)!,
    )[_financeService.currentMonth!.month - 1];
    final year = _financeService.currentMonth!.year;

    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$monthName $year',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count ${AppLocalizations.of(context).movements}',
                  style: TextStyle(color: glass.mutedText, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppLocalizations.of(context)!.balance.toUpperCase(),
                style: TextStyle(
                  color: glass.mutedText,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              AmountText(
                amount: total.abs(),
                currency: _moneda,
                isExpense: total < 0,
                signed: true,
                fontSize: 24,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchToolBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    final bool filtersOpen = _expandedItems['filters'] ?? false;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            style: TextStyle(color: scheme.onSurface),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.searchByName,
              hintStyle: TextStyle(color: glass.mutedText),
              prefixIcon: Icon(Icons.search, color: glass.mutedText),
              filled: true,
              fillColor: scheme.surfaceContainerLow,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(glass.pillRadius),
                borderSide: BorderSide(color: glass.glassBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(glass.pillRadius),
                borderSide: BorderSide(color: glass.glassBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(glass.pillRadius),
                borderSide: BorderSide(color: scheme.primary),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: glass.mutedText),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        _buildToolbarIconButton(
          icon: Icons.sort,
          tooltip: 'Ordenar',
          active: _currentSortType != null,
          onPressed: () => _showSortMenu(context),
        ),
        const SizedBox(width: 8),
        _buildToolbarIconButton(
          icon: Icons.filter_list,
          tooltip: 'Filtrar',
          active: filtersOpen,
          onPressed: () {
            setState(() {
              _expandedItems['filters'] = !filtersOpen;
            });
          },
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onLongPress: _deleteAllTags,
          child: _buildToolbarIconButton(
            icon: Icons.auto_awesome,
            tooltip: 'Auto-etiquetar',
            active: false,
            onPressed: () async {
              await _autoGenerateTags();
              await _loadMovements();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToolbarIconButton({
    required IconData icon,
    required String tooltip,
    required bool active,
    required VoidCallback onPressed,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: active ? scheme.primary : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(glass.pillRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(glass.pillRadius),
          onTap: onPressed,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(glass.pillRadius),
              border: Border.all(color: glass.glassBorder),
            ),
            child: Icon(
              icon,
              size: 20,
              color: active ? scheme.onPrimary : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final bool isFiltersExpanded = _expandedItems['filters'] ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () => _selectDate(context),
                      style: FilledButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.date_range, color: Theme.of(context).colorScheme.primary, size: 20),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _selectedDate != null
                                  ? _selectedDate!.day.toString()
                                  : AppLocalizations.of(context).all,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_selectedDate != null) ...[
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDate = null;
                                });
                              },
                              child: Icon(Icons.clear, size: 16, color: Theme.of(context).colorScheme.error),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FutureBuilder<List<MovementValue>>(
                      future: _financeService.getCurrentMonthMovements(),
                      builder: (context, snapshot) {
                        final categories = _getAvailableCategories(snapshot.data ?? []);
                        return FilledButton.tonal(
                          onPressed: () => _selectCategory(context, categories),
                          style: FilledButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.category, size: 20, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _selectedCategory ?? AppLocalizations.of(context).all,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              if (_selectedCategory != null) ...[
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedCategory = null;
                                    });
                                  },
                                  child: Icon(Icons.clear, size: 16, color: Theme.of(context).colorScheme.error),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context, MovementValue movement) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ElevatedButton.icon(
                  onPressed: () => _showDatePicker(context, movement),
                  label: Text(
                    '${movement.day}/${widget.month}/${widget.year}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  icon: const Icon(Icons.calendar_month),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditDialog(movement),
              ),
            ),
            Expanded(
              flex: 2,
              child: IconButton(
                icon: const Icon(Icons.category),
                tooltip: 'Cambiar categoría',
                onPressed: () => _showCategoryChangeDialog(context, movement),
              ),
            ),
            Expanded(
              flex: 2,
              child: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _showDeleteDialog(movement),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _toggleMovementExpansion(int movementId) {
    final key = movementId.toString();
    setState(() {
      _expandedItems[key] = !(_expandedItems[key] ?? false);
    });
  }

  void _showSortMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(AppLocalizations.of(context).byDate),
                trailing: _currentSortType == 'fecha'
                    ? Icon(
                        _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    if (_currentSortType == 'fecha') {
                      _isAscending = !_isAscending;
                    } else {
                      _currentSortType = 'fecha';
                      _isAscending = true;
                    }
                    _applySorting();
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sort_by_alpha),
                title: Text(AppLocalizations.of(context).alphabetical),
                trailing: _currentSortType == 'alfabetico'
                    ? Icon(
                        _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    if (_currentSortType == 'alfabetico') {
                      _isAscending = !_isAscending;
                    } else {
                      _currentSortType = 'alfabetico';
                      _isAscending = true;
                    }
                    _applySorting();
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.euro),
                title: Text(AppLocalizations.of(context).byValue),
                trailing: _currentSortType == 'valor'
                    ? Icon(
                        _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    if (_currentSortType == 'valor') {
                      _isAscending = !_isAscending;
                    } else {
                      _currentSortType = 'valor';
                      _isAscending = true;
                    }
                    _applySorting();
                  });
                  Navigator.pop(context);
                },
              ),
              if (_currentSortType != null)
                ListTile(
                  leading: const Icon(Icons.clear),
                  title: Text(AppLocalizations.of(context).clearSort),
                  onTap: () {
                    setState(() {
                      _currentSortType = null;
                      _isAscending = true;
                      _loadMovements();
                    });
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _applySorting() {
    if (_currentSortType == null) {
      _cachedMovements.sort((a, b) => b.day.compareTo(a.day));
      return;
    }

    _cachedMovements.sort((a, b) {
      int comparison;
      switch (_currentSortType) {
        case 'fecha':
          comparison = a.day.compareTo(b.day);
          break;
        case 'alfabetico':
          comparison = a.description.toLowerCase().compareTo(b.description.toLowerCase());
          break;
        case 'valor':
          comparison = a.amount.compareTo(b.amount);
          break;
        default:
          comparison = b.day.compareTo(a.day);
      }
      return _isAscending ? comparison : -comparison;
    });
  }

  List<MovementValue> _filterMovements(List<MovementValue> movements) {
    return movements.where((movement) {
      // _filterMode: 0 = Todos, 1 = Ingresos, 2 = Gastos
      if (_filterMode == 1 && movement.isExpense) return false;
      if (_filterMode == 2 && !movement.isExpense) return false;
      if (_selectedDate != null && movement.day != _selectedDate!.day) return false;
      if (_selectedCategory != null && movement.category != _selectedCategory) return false;

      DateTime _date = DateTime(_financeService.currentMonth!.year, _financeService.currentMonth!.month, 1);
      if(_date.isAfter(DateTime.now())){
        DateTime _movDate = DateTime(_date.year, _date.month, movement.day);
        if(_movDate.isAfter(DateTime.now())){
          return false;
        }
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final description = movement.description.toLowerCase();
        final category = (movement.category ?? '').toLowerCase();
        return description.contains(query) || category.contains(query);
      }
      return true;
    }).toList();
  }

  Set<String> _getAvailableCategories(List<MovementValue> movements) {
    return movements
        .where((m) => m.category != null)
        .map((m) => m.category!)
        .toSet();
  }

  Future<void> _selectDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(widget.year, widget.month, 1),
      firstDate: DateTime(widget.year, widget.month, 1),
      lastDate: DateTime(widget.year, widget.month + 1, 0),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  void _selectCategory(BuildContext context, Set<String> existingCategories) {
    final locale = AppLocalizations.of(context).localeName;
    final localizedTags = getTagList(locale);
    final allCategories = {...existingCategories, ...localizedTags}.toList()
      ..sort((a, b) => a.compareTo(b));

    showModalBottomSheet(
      showDragHandle: true,
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return TagList(
              tags: allCategories,
              context: context,
              scrollController: scrollController,
              onTagSelected: (tag) {
                setState(() {
                  _selectedCategory = tag;
                });
                Navigator.pop(context);
              },
              selectedCategory: _selectedCategory,
            );
          },
        );
      },
    );
  }

  Future<void> _createNewMovement() async {
    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (BuildContext context) => MovementFormScreen(),
    );
    if (result == true) {
      await _loadMovements();
    }
  }

  Future<void> _showEditDialog(MovementValue movement) async {
    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (BuildContext context) => MovementFormScreen(movement: movement),
    );
    if (result == true) {
      await _loadMovements();
    }
  }

  Future<bool> _showDeleteDialog(MovementValue movement) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteMovement),
        content: Text(
          AppLocalizations.of(context)!.confirmDeleteMovement(movement.description),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
    if (shouldDelete == true) {
      await _financeService.deleteMovement(context, movement);
      if (mounted) {
        setState(() {
          _expandedItems.remove(movement.id.toString());
        });
      }
      return true;
    }
    return false;
  }

  Widget _buildSwipeableMovementTile({
    required MovementValue movement,
    required bool isExpanded,
  }) {
    return Dismissible(
      key: Key('movement_swipe_${movement.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      secondaryBackground: _buildSwipeBackground(
        color: Theme.of(context).colorScheme.primary,
        icon: Icons.more_horiz,
        label: AppLocalizations.of(context)!.edit,
        alignLeft: false,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          await _showSwipeActionsMenu(movement);
        }
        return false;
      },
      child: MovementTile(
        movement: movement,
        isExpanded: isExpanded,
        currency: _moneda,
        onTap: () => _toggleMovementExpansion(movement.id!),
        expandedContent: _buildExpandedContent(context, movement),
      ),
    );
  }

  Future<void> _showSwipeActionsMenu(MovementValue movement) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _showEditDialog(movement);
                  },
                  icon: const Icon(Icons.edit),
                  label: Text(AppLocalizations.of(context)!.edit),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    await _showDeleteDialog(movement);
                  },
                  icon: const Icon(Icons.delete),
                  label: Text(AppLocalizations.of(context)!.delete),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground({
    required Color color,
    required IconData icon,
    required String label,
    required bool alignLeft,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
      padding: EdgeInsets.only(
        left: alignLeft ? 20 : 0,
        right: alignLeft ? 0 : 20,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: alignLeft
            ? [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(color: Colors.white)),
              ]
            : [
                Text(label, style: const TextStyle(color: Colors.white)),
                const SizedBox(width: 8),
                Icon(icon, color: Colors.white),
              ],
      ),
    );
  }

  Future<bool> _convertMovementToMonthlyDebtFromSwipe(
    MovementValue movement,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.convertToMonthlyDebt),
        content: Text(
          AppLocalizations.of(
            context,
          )!.convertToMonthlyDebtConfirm(movement.description),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.create),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;

    try {
      await _financeService.convertMovementToMonthlyDebt(movement);
      if (!mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.movementConvertedToMonthlyDebt,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadMovements();
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.convertToDebtError('$e')),
          behavior: SnackBarBehavior.floating,
        ),
      );
      LogFileService().appendLog('Error converting movement by swipe: $e');
      return false;
    }
  }

  Widget _buildFutureMovementsCard(List<MovementValue> values) {
    if (values.isEmpty) return const SizedBox.shrink();
    final bool isExpanded = _expandedItems['future_movements'] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              title: Row(
                children: [
                  Icon(Icons.upcoming, color: Theme.of(context).colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.futureMovements,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      values.length.toString(),
                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer, fontSize: 12),
                    ),
                  ),
                ],
              ),
              trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Theme.of(context).colorScheme.primary),
              onTap: () => setState(() => _expandedItems['future_movements'] = !isExpanded),
            ),
            if (isExpanded)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: values.length,
                itemBuilder: (context, index) {
                  final movement = values[index];
                  return _buildSwipeableMovementTile(
                    movement: movement,
                    isExpanded: _expandedItems[movement.id.toString()] ?? false,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCategoryChangeDialog(BuildContext context, MovementValue movement) async {
    final movements = await _financeService.getCurrentMonthMovements();
    final existingCategories = _getAvailableCategories(movements);
    final locale = AppLocalizations.of(context).localeName;
    final localizedTags = getTagList(locale);
    final allCategories = {...existingCategories, ...localizedTags}.toList()
      ..sort((a, b) => a.compareTo(b));

    await showModalBottomSheet(
      showDragHandle: true,
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return TagList(
              scrollController: scrollController,
              tags: allCategories,
              context: context,
              onTagSelected: (tag) async {
                final updated = movement.copyWith(category: tag);
                showDialog(context: context, barrierDismissible: false, builder: (context) => Center(child: Loading(context)));
                await _financeService.updateMovement(updated);
                Navigator.pop(context);
                Navigator.pop(context);
              },
              selectedCategory: movement.category,
            );
          },
        );
      },
    );
  }

  Future<void> _showDatePicker(BuildContext context, MovementValue movement) async {
    final DateTime initialDate = DateTime(widget.year, widget.month, movement.day);
    final DateTime firstDate = DateTime(widget.year, widget.month, 1);
    final DateTime lastDate = DateTime(widget.year, widget.month + 1, 0);

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: AppLocalizations.of(context)!.selectDate,
    );

    if (selectedDate != null && selectedDate.day != movement.day) {
      await _updateMovementDate(movement, selectedDate.day);
    }
  }

  Future<void> _updateMovementDate(MovementValue movement, int newDay) async {
    try {
      final updatedMovement = movement.copyWith(day: newDay);
      await SqliteService().database.movementValueDao.updateMovementValue(updatedMovement);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.dateUpdatedToDay(newDay)), behavior: SnackBarBehavior.floating));
      }
      await _loadMovements();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.errorUpdatingDate(e.toString())), behavior: SnackBarBehavior.floating, backgroundColor: Theme.of(context).colorScheme.error));
      }
      LogFileService().appendLog('Error updating movement date: $e');
    }
  }
}
