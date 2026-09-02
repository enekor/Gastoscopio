import 'package:cashly/common/month_names.dart';
import 'package:cashly/data/models/month.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/l10n/app_localizations.dart';
import 'package:cashly/theme/app_glass.dart';
import 'package:cashly/theme/widgets/amount_text.dart';
import 'package:cashly/theme/widgets/app_background.dart';
import 'package:cashly/theme/widgets/app_list_row.dart';
import 'package:cashly/theme/widgets/glass_button.dart';
import 'package:cashly/theme/widgets/glass_card.dart';
import 'package:flutter/material.dart';

class ViewMovementsFilteredScreen extends StatefulWidget {
  const ViewMovementsFilteredScreen({super.key});

  @override
  State<ViewMovementsFilteredScreen> createState() =>
      _ViewMovementsFilteredScreenState();
}

class _ViewMovementsFilteredScreenState
    extends State<ViewMovementsFilteredScreen> {
  List<MovementValue> movements = const [];
  List<Month> months = [];
  SqliteService sqliteService = SqliteService();
  DateTimeRange? selectedDateRange;
  bool isExpense = true;
  String _searchQuery = '';
  String _moneda = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = _searchQuery;
    SharedPreferencesService()
        .getStringValue(SharedPreferencesKeys.currency)
        .then(
          (currency) => setState(() {
            _moneda = currency ?? '€';
          }),
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMovements() async {
    movements = [];
    months = [];

    for (
      DateTime date = selectedDateRange!.start;
      date.isBefore(selectedDateRange!.end) ||
          date.isAtSameMomentAs(selectedDateRange!.end);
      date = DateTime(date.year, date.month + 1)
    ) {
      Month? month = await sqliteService.db.monthDao.findMonthByMonthAndYear(
        date.month,
        date.year,
      );
      if (month != null) {
        months.add(month);
        List<MovementValue> _movementsFiltered = await sqliteService
            .db
            .movementValueDao
            .findMovementValuesByMonthId(month.id!);

        movements.addAll(
          _movementsFiltered
              .where((mov) => mov.isExpense == isExpense)
              .toList(),
        );
      }
    }

    setState(() {});
  }

  List<MovementValue> _filterMovements() => movements.where((movement) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final description = movement.description.toLowerCase();
        return description.contains(query);
      }
      return true;
    }).toList();

  /// Whether [monthIndex] (0-based, current year) is inside the selected range.
  bool _isMonthSelected(int monthIndex) {
    if (selectedDateRange == null) return false;
    final year = DateTime.now().year;
    final monthStart = DateTime(year, monthIndex + 1);
    final start = DateTime(
      selectedDateRange!.start.year,
      selectedDateRange!.start.month,
    );
    final end = DateTime(
      selectedDateRange!.end.year,
      selectedDateRange!.end.month,
    );
    return !monthStart.isBefore(start) && !monthStart.isAfter(end);
  }

  /// Toggles a single-month range for the tapped month of the current year and
  /// reloads movements.
  Future<void> _onMonthChipTap(int monthIndex) async {
    final year = DateTime.now().year;
    final monthStart = DateTime(year, monthIndex + 1);
    final monthEnd = DateTime(year, monthIndex + 1);

    setState(() {
      if (_isMonthSelected(monthIndex) &&
          selectedDateRange!.start == monthStart &&
          selectedDateRange!.end == monthEnd) {
        selectedDateRange = null;
      } else {
        selectedDateRange = DateTimeRange(start: monthStart, end: monthEnd);
      }
    });

    if (selectedDateRange != null) {
      await _loadMovements();
    } else {
      setState(() {
        movements = [];
        months = [];
      });
    }
  }

  Future<void> _pickCustomRange() async {
    final localizations = AppLocalizations.of(context)!;
    final DateTimeRange? picked = await showDateRangePicker(
      saveText: localizations.save,
      cancelText: localizations.cancel,
      confirmText: localizations.accept,
      helpText: localizations.selectDateRange,
      barrierColor: Colors.transparent,
      builder: (context, child) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 15),
        child: Card(child: child),
      ),
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: selectedDateRange,
    );
    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
      });
      await _loadMovements();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    final filtered = _filterMovements();
    final total = filtered.fold<double>(0.0, (sum, item) => sum + item.amount);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(localizations.filteredMovements),
      ),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    // Search field
                    _buildSearchField(localizations, scheme, glass),
                    const SizedBox(height: 20),

                    // Date range label + custom range action
                    Row(
                      children: [
                        Text(
                          localizations.dateRange.toUpperCase(),
                          style: TextStyle(
                            color: glass.mutedText,
                            fontSize: 12,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        GlassButton(
                          icon: Icons.calendar_today,
                          label: localizations.customRange,
                          onPressed: _pickCustomRange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildMonthChips(scheme, glass),
                    const SizedBox(height: 24),

                    // Matches label
                    Text(
                      '${localizations.matches} (${filtered.length})'
                          .toUpperCase(),
                      style: TextStyle(
                        color: glass.mutedText,
                        fontSize: 12,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 32),
                        child: Center(
                          child: Text(
                            selectedDateRange == null
                                ? localizations.selectDateRange
                                : localizations.search,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: glass.mutedText),
                          ),
                        ),
                      )
                    else
                      ...filtered.map((movement) {
                        final month = months.firstWhere(
                          (m) => m.id == movement.monthId,
                          orElse: () => Month(0, 0),
                        );
                        return _buildResultRow(movement, month, glass);
                      }),
                  ],
                ),
              ),

              // Sticky total footer
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: GlassCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        localizations.total,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      AmountText(
                        amount: total,
                        currency: _moneda,
                        isExpense: isExpense,
                        signed: true,
                        fontSize: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(
    AppLocalizations localizations,
    ColorScheme scheme,
    AppGlass glass,
  ) {
    return TextField(
      controller: _searchController,
      style: TextStyle(color: scheme.onSurface),
      decoration: InputDecoration(
        hintText: localizations.searchByNameCategory,
        hintStyle: TextStyle(color: glass.mutedText),
        prefixIcon: Icon(Icons.search, color: glass.mutedText),
        filled: true,
        fillColor: glass.glassFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(glass.pillRadius),
          borderSide: BorderSide(color: glass.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(glass.pillRadius),
          borderSide: BorderSide(color: scheme.primary),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(glass.pillRadius),
          borderSide: BorderSide(color: glass.glassBorder),
        ),
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
    );
  }

  Widget _buildMonthChips(ColorScheme scheme, AppGlass glass) {
    final monthLabels = monthShortNames(AppLocalizations.of(context)!);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(monthLabels.length, (index) {
        final selected = _isMonthSelected(index);
        return GestureDetector(
          onTap: () => _onMonthChipTap(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.18)
                  : glass.glassFill,
              borderRadius: BorderRadius.circular(glass.pillRadius),
              border: Border.all(
                color: selected ? scheme.primary : glass.glassBorder,
              ),
            ),
            child: Text(
              monthLabels[index],
              style: TextStyle(
                color: selected ? scheme.primary : scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildResultRow(MovementValue movement, Month month, AppGlass glass) {
    final subtitleParts = <String>[];
    if (movement.category != null && movement.category!.isNotEmpty) {
      subtitleParts.add(movement.category!);
    }
    subtitleParts.add('${movement.day}/${month.month}/${month.year}');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppListRow(
        title: movement.description,
        subtitle: subtitleParts.join(' · '),
        leadingIcon: movement.isExpense
            ? Icons.arrow_downward
            : Icons.arrow_upward,
        trailing: AmountText(
          amount: movement.amount,
          currency: _moneda,
          isExpense: movement.isExpense,
          signed: true,
          fontSize: 16,
        ),
      ),
    );
  }
}
