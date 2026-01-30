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
import 'package:cashly/modules/gastoscopio/widgets/tag_list.dart';
import 'package:flutter/material.dart';
import 'package:cashly/l10n/app_localizations.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';

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
  bool _showExpenses = true;
  DateTime? _selectedDate;
  String? _selectedCategory;
  String _searchQuery = '';
  final Map<String, bool> _expandedItems = {};
  late String _moneda;
  late FinanceService _financeService;
  final TextEditingController _searchController = TextEditingController();
  bool _isOpaqueBottomNav = false;

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

    SharedPreferencesService()
        .getBoolValue(SharedPreferencesKeys.isOpaqueBottomNav)
        .then(
          (isOpaque) => setState(() {
            _isOpaqueBottomNav = isOpaque ?? false;
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
      SharedPreferencesService()
          .getBoolValue(SharedPreferencesKeys.isOpaqueBottomNav)
          .then(
            (isOpaque) => setState(() {
              _isOpaqueBottomNav = isOpaque ?? false;
            }),
          );
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

    final themeColor = _showExpenses
        ? Theme.of(context).colorScheme.error
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          sliver: SliverToBoxAdapter(
            child: _buildModernTotalCard(
              totalAmount,
              filteredMovements.length,
              themeColor,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverToBoxAdapter(
            child: _buildModernToolBar(context),
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
                    _showExpenses ? Icons.money_off : Icons.attach_money,
                    size: 64,
                    color: Theme.of(context).disabledColor.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _showExpenses
                        ? AppLocalizations.of(context).noExpenses
                        : AppLocalizations.of(context).noIncomes,
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
                          child: MovementTile(
                            movement: movement,
                            isExpanded: isExpanded,
                            currency: _moneda,
                            onTap: () => _toggleMovementExpansion(movement.id!),
                            expandedContent: _buildExpandedContent(
                              context,
                              movement,
                            ),
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
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<bool>(
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.comfortable,
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          side: MaterialStateProperty.all(
            BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2)),
          ),
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return _showExpenses
                  ? Theme.of(context).colorScheme.errorContainer
                  : Theme.of(context).colorScheme.primaryContainer;
            }
            return Colors.transparent;
          }),
        ),
        segments: [
          ButtonSegment<bool>(
            value: false,
            label: Text(
              AppLocalizations.of(context).incomes,
              style: TextStyle(
                fontWeight: !_showExpenses ? FontWeight.bold : FontWeight.normal,
                color: !_showExpenses
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : null,
              ),
            ),
            icon: const Icon(Icons.arrow_upward, size: 16),
          ),
          ButtonSegment<bool>(
            value: true,
            label: Text(
              AppLocalizations.of(context).expenses,
              style: TextStyle(
                fontWeight: _showExpenses ? FontWeight.bold : FontWeight.normal,
                color: _showExpenses
                    ? Theme.of(context).colorScheme.onErrorContainer
                    : null,
              ),
            ),
            icon: const Icon(Icons.arrow_downward, size: 16),
          ),
        ],
        selected: {_showExpenses},
        onSelectionChanged: (newSelection) {
          setState(() {
            _showExpenses = newSelection.first;
          });
        },
      ),
    );
  }

  Widget _buildModernTotalCard(double total, int count, Color color) {
    return Container(
      width: double.infinity,
      height: 100,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _showExpenses
                    ? AppLocalizations.of(context).expenses
                    : AppLocalizations.of(context).incomes,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count movs.',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          Center(
            child: Text(
              '${total < 0 ? '-' : ''}${total.abs().toStringAsFixed(2)}$_moneda',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernToolBar(BuildContext context) {
    final buttonStyle = ButtonStyle(
      backgroundColor: MaterialStateProperty.all(
        Theme.of(context).colorScheme.surface,
      ),
      elevation: MaterialStateProperty.all(2),
      shadowColor: MaterialStateProperty.all(Colors.black.withOpacity(0.1)),
      padding: MaterialStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
    );

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: buttonStyle.copyWith(
              backgroundColor: MaterialStateProperty.resolveWith(
                (states) => (_expandedItems['filters'] ?? false)
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surface,
              ),
            ),
            onPressed: () {
              setState(() {
                _expandedItems['filters'] =
                    !(_expandedItems['filters'] ?? false);
              });
            },
            icon: Icon(
              Icons.filter_list,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            label: Text(
              "Filtrar",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton.filledTonal(
          style: IconButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(12),
          ),
          onPressed: () => _showSortMenu(context),
          icon: const Icon(Icons.sort),
          tooltip: "Ordenar",
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onLongPress: () {
            _deleteAllTags();
          },
          child: IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: Colors.amber.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(12),
            ),
            onPressed: () async {
              await _autoGenerateTags();
              await _loadMovements();
            },
            icon: Icon(Icons.auto_awesome, color: Colors.amber.shade900),
            tooltip: "Auto-etiquetar",
          ),
        ),
      ],
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
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).search,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
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
      if (movement.isExpense != _showExpenses) return false;
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
    final result = await showModalBottomSheet<bool>(
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
    final result = await showModalBottomSheet<bool>(
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

  Future<void> _showDeleteDialog(MovementValue movement) async {
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
                  return MovementTile(
                    movement: movement,
                    isExpanded: _expandedItems[movement.id.toString()] ?? false,
                    currency: _moneda,
                    onTap: () => _toggleMovementExpansion(movement.id!),
                    expandedContent: _buildExpandedContent(context, movement),
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
