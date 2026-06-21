import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/records_provider.dart';
import '../models/fill_record.dart';
import '../models/fuel_type.dart';
import '../models/vehicle.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_panel.dart';
import '../utils/currency_utils.dart';
import 'settings_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String _selectedFuelTypeFilter = 'all';
  String _selectedVehicleFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.dashboardBackgroundDark : null,
      body: SafeArea(
        child: Consumer<RecordsProvider>(
          builder: (context, provider, child) {
            final filterIsValid = _selectedFuelTypeFilter == 'all' ||
                provider.fuelTypes
                    .any((fuelType) => fuelType.id == _selectedFuelTypeFilter);
            final selectedFilterId =
                filterIsValid ? _selectedFuelTypeFilter : 'all';
            if (!filterIsValid) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) {
                  return;
                }
                setState(() => _selectedFuelTypeFilter = 'all');
              });
            }

            final vehicleFilterIsValid = _selectedVehicleFilter == 'all' ||
                provider.vehicles.any((v) => v.id == _selectedVehicleFilter);
            final selectedVehicleFilterId =
                vehicleFilterIsValid ? _selectedVehicleFilter : 'all';
            if (!vehicleFilterIsValid) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() => _selectedVehicleFilter = 'all');
              });
            }

            final fuelTypeId =
                selectedFilterId == 'all' ? null : selectedFilterId;
            final vehicleId = selectedVehicleFilterId == 'all'
                ? null
                : selectedVehicleFilterId;
            final statsCurrency = fuelTypeId != null
                ? provider.getCurrencyForFuelTypeId(fuelTypeId)
                : provider.currency;
            final stats = provider.getOverallStats(
                fuelTypeId: fuelTypeId, vehicleId: vehicleId);
            final totalRecords = stats['totalRecords'] as int;
            final filterFuelTypes = provider.fuelTypes
                .where(
                  (fuelType) =>
                      fuelType.active ||
                      provider.hasRecordsForFuelType(fuelType.id),
                )
                .toList();

            if (totalRecords == 0) {
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _CircleAction(
                            icon: Icons.arrow_back_rounded,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                          Column(
                            children: [
                              Text(
                                'Vehicle Stats',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.5),
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'Vehicle Logbook',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.expand_more_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          _CircleAction(
                            icon: Icons.settings_rounded,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: _FuelTypeFilterBar(
                        selectedId: selectedFilterId,
                        fuelTypes: filterFuelTypes,
                        onSelected: (value) {
                          setState(() => _selectedFuelTypeFilter = value);
                        },
                      ),
                    ),
                  ),
                  if (provider.activeVehicles.length > 1)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        child: _VehicleFilterBar(
                          selectedId: selectedVehicleFilterId,
                          vehicles: provider.activeVehicles,
                          onSelected: (value) {
                            setState(() => _selectedVehicleFilter = value);
                          },
                        ),
                      ),
                    ),
                  SliverFillRemaining(
                    child: _EmptyState(colorScheme: colorScheme),
                  ),
                ],
              );
            }

            final forecast = provider.getRefillForecast(
                fuelTypeId: fuelTypeId, vehicleId: vehicleId);
            // Maintenance has no fuel type and is tracked in the global
            // currency, so the cost-of-ownership view is only coherent when no
            // fuel-type filter is active.
            final maintenanceOverview = fuelTypeId == null
                ? provider.getMaintenanceOverview(vehicleId: vehicleId)
                : null;
            final hasMaintenance = maintenanceOverview != null &&
                (maintenanceOverview['totalRecords'] as int) > 0;

            final spendByFuelType =
                stats['spendByFuelType'] as Map<String, double>;
            final spendBreakdown = spendByFuelType.entries
                .where((entry) => entry.value > 0)
                .map((entry) => _SpendSlice(
                      label: provider.getFuelTypeName(entry.key),
                      amount: entry.value,
                    ))
                .toList()
              ..sort((a, b) => b.amount.compareTo(a.amount));

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _CircleAction(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        Column(
                          children: [
                            Text(
                              'Vehicle Stats',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.5),
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'Vehicle Logbook',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.expand_more_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                        _CircleAction(
                          icon: Icons.settings_rounded,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: _FuelTypeFilterBar(
                      selectedId: selectedFilterId,
                      fuelTypes: filterFuelTypes,
                      onSelected: (value) {
                        setState(() => _selectedFuelTypeFilter = value);
                      },
                    ),
                  ),
                ),
                if (provider.activeVehicles.length > 1)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: _VehicleFilterBar(
                        selectedId: selectedVehicleFilterId,
                        vehicles: provider.activeVehicles,
                        onSelected: (value) {
                          setState(() => _selectedVehicleFilter = value);
                        },
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: _OverviewGrid(stats: stats, currency: statsCurrency),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _SpendingPanel(stats: stats, currency: statsCurrency),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _EfficiencyPanel(stats: stats),
                  ),
                ),
                if (fuelTypeId == null && spendBreakdown.length > 1)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _SpendBreakdownPanel(
                        breakdown: spendBreakdown,
                        currency: statsCurrency,
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _MonthlySpendPanel(
                      stats: stats,
                      currency: statsCurrency,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _CadencePanel(stats: stats),
                  ),
                ),
                if (forecast != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _ForecastPanel(forecast: forecast),
                    ),
                  ),
                if (hasMaintenance)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: _CostOfOwnershipPanel(
                        fuelSpent: stats['totalSpent'] as double,
                        maintenance: maintenanceOverview,
                        currency: provider.currency,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  final String currency;

  const _OverviewGrid({required this.stats, required this.currency});

  @override
  Widget build(BuildContext context) {
    final totalRecords = stats['totalRecords'] as int;
    final totalSpent = stats['totalSpent'] as double;
    final totalDistance = stats['totalDistance'] as double;
    final totalFuelLiters = stats['totalFuelLiters'] as double;
    final averageMileage = stats['averageMileage'] as double;
    final totalDays = stats['totalDays'] as int;

    final distanceLabel = totalDistance >= 1000
        ? '${(totalDistance / 1000).toStringAsFixed(1)}k'
        : totalDistance.toStringAsFixed(0);

    final spentLabel = _compactCurrency(totalSpent, currency);
    final durationMonths = totalDays > 0 ? (totalDays / 30).ceil() : 0;

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      children: [
        _OverviewCard(
          label: 'Total Fills',
          value: totalRecords.toString(),
          accent: AppColors.primary,
          icon: Icons.local_gas_station_rounded,
        ),
        _OverviewCard(
          label: 'Total Spent',
          value: spentLabel,
          unit: currency,
          accent: const Color(0xFF22C55E),
          icon: Icons.payments_rounded,
        ),
        _OverviewCard(
          label: 'Distance',
          value: distanceLabel,
          unit: 'km',
          accent: AppColors.accentBlue,
          icon: Icons.route_rounded,
        ),
        _OverviewCard(
          label: 'Total Fuel',
          value: totalFuelLiters.toStringAsFixed(0),
          unit: 'L',
          accent: AppColors.accentAmber,
          icon: Icons.water_drop_rounded,
        ),
        _OverviewCard(
          label: 'Avg Mileage',
          value: averageMileage > 0 ? averageMileage.toStringAsFixed(1) : '--',
          unit: 'km/L',
          accent: AppColors.primary,
          icon: Icons.speed_rounded,
        ),
        _OverviewCard(
          label: 'Duration',
          value: durationMonths.toString(),
          unit: 'mo',
          accent: AppColors.accentPurple,
          icon: Icons.schedule_rounded,
        ),
      ],
    );
  }
}

/// Compact money label for tight tiles: 12.3k / 1.2M, full amount otherwise.
String _compactCurrency(double amount, String currency) {
  if (amount >= 1000000) {
    return '${(amount / 1000000).toStringAsFixed(1)}M';
  }
  if (amount >= 10000) {
    return '${(amount / 1000).toStringAsFixed(1)}k';
  }
  return CurrencyUtils.formatAmount(amount, currency);
}

class _FuelTypeFilterBar extends StatelessWidget {
  final String selectedId;
  final List<FuelType> fuelTypes;
  final ValueChanged<String> onSelected;

  const _FuelTypeFilterBar({
    required this.selectedId,
    required this.fuelTypes,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = <Map<String, String>>[
      const {'id': 'all', 'label': 'All'},
      ...fuelTypes.map((fuelType) => {
            'id': fuelType.id,
            'label': fuelType.name,
          }),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          final optionId = option['id']!;
          final selected = selectedId == optionId;
          return ChoiceChip(
            label: Text(option['label']!),
            selected: selected,
            onSelected: (_) => onSelected(optionId),
            labelStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: selected
                  ? Colors.white
                  : theme.colorScheme.onSurface.withOpacity(0.75),
            ),
            selectedColor: AppColors.primary,
            backgroundColor: theme.brightness == Brightness.dark
                ? AppColors.surfaceDarkElevated
                : Colors.white,
            side: BorderSide(
              color: selected
                  ? AppColors.primary
                  : theme.brightness == Brightness.dark
                      ? AppColors.outlineDark.withOpacity(0.6)
                      : AppColors.outlineLight,
            ),
          );
        },
      ),
    );
  }
}

class _VehicleFilterBar extends StatelessWidget {
  final String selectedId;
  final List<Vehicle> vehicles;
  final ValueChanged<String> onSelected;

  const _VehicleFilterBar({
    required this.selectedId,
    required this.vehicles,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = <Map<String, String>>[
      const {'id': 'all', 'label': 'All Vehicles'},
      ...vehicles.map((vehicle) => {
            'id': vehicle.id,
            'label': vehicle.name,
          }),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          final optionId = option['id']!;
          final selected = selectedId == optionId;
          return ChoiceChip(
            label: Text(option['label']!),
            selected: selected,
            onSelected: (_) => onSelected(optionId),
            avatar: selected && optionId != 'all'
                ? const Icon(Icons.directions_car_rounded,
                    size: 16, color: Colors.white)
                : null,
            labelStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: selected
                  ? Colors.white
                  : theme.colorScheme.onSurface.withOpacity(0.75),
            ),
            selectedColor: AppColors.accentBlue,
            backgroundColor: theme.brightness == Brightness.dark
                ? AppColors.surfaceDarkElevated
                : Colors.white,
            side: BorderSide(
              color: selected
                  ? AppColors.accentBlue
                  : theme.brightness == Brightness.dark
                      ? AppColors.outlineDark.withOpacity(0.6)
                      : AppColors.outlineLight,
            ),
          );
        },
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final Color accent;
  final IconData icon;

  const _OverviewCard({
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassPanel(
      color: isDark ? const Color(0xB2161B22) : null,
      enableBlur: false,
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, size: 20, color: accent),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 6),
                Text(
                  unit!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _EfficiencyPanel extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _EfficiencyPanel({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final averageMileage = stats['averageMileage'] as double;
    final bestMileage = stats['bestMileage'] as double;
    final worstMileage = stats['worstMileage'] as double;
    final bestRecord = stats['bestMileageRecord'] as FillRecord?;
    final worstRecord = stats['worstMileageRecord'] as FillRecord?;
    final dateFormat = DateFormat('dd MMM');

    final maxMileage =
        averageMileage > 0 ? math.max(averageMileage * 1.4, 15) : 15.0;
    final value = (averageMileage / maxMileage).clamp(0.0, 1.0);

    return GlassPanel(
      color: isDark ? const Color(0xB2161B22) : null,
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        children: [
          Text(
            'Efficiency Analysis',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                CustomPaint(
                  size: const Size(240, 120),
                  painter: _GaugePainter(
                    value: value,
                    backgroundColor:
                        theme.colorScheme.onSurface.withOpacity(0.08),
                    foregroundColor: AppColors.primary,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      averageMileage > 0
                          ? averageMileage.toStringAsFixed(1)
                          : '--',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'km/L',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniCard(
                  label: 'Best Trip',
                  value:
                      bestMileage > 0 ? bestMileage.toStringAsFixed(1) : '--',
                  hint: bestRecord != null
                      ? dateFormat.format(bestRecord.date)
                      : 'Highway',
                  valueColor: const Color(0xFF22C55E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniCard(
                  label: 'Worst Trip',
                  value:
                      worstMileage > 0 ? worstMileage.toStringAsFixed(1) : '--',
                  hint: worstRecord != null
                      ? dateFormat.format(worstRecord.date)
                      : 'City',
                  valueColor: AppColors.accentAmber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String label;
  final String value;
  final String hint;
  final Color valueColor;

  const _MiniCard({
    required this.label,
    required this.value,
    required this.hint,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? AppColors.surfaceDarkElevated
            : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? AppColors.outlineDark.withOpacity(0.6)
              : AppColors.outlineLight,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            hint,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlySpendPanel extends StatelessWidget {
  final Map<String, dynamic> stats;
  final String currency;

  const _MonthlySpendPanel({required this.stats, required this.currency});

  static const _monthLabels = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final monthlySpending = stats['monthlySpending'] as Map<String, double>;

    if (monthlySpending.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedMonths = monthlySpending.keys.toList()..sort();
    final recentMonths = sortedMonths.length > 6
        ? sortedMonths.sublist(sortedMonths.length - 6)
        : sortedMonths;

    final maxSpending = monthlySpending.values.reduce(math.max);

    final barGroups = <BarChartGroupData>[];
    for (var i = 0; i < recentMonths.length; i++) {
      final spending = monthlySpending[recentMonths[i]] ?? 0;
      final isPeak = spending == maxSpending;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: spending,
              width: 18,
              color: isPeak
                  ? AppColors.primary
                  : AppColors.primary.withOpacity(0.35),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ],
        ),
      );
    }

    return GlassPanel(
      color: isDark ? const Color(0xB2161B22) : null,
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Spend',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 170,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxSpending > 0 ? maxSpending * 1.2 : 1,
                barGroups: barGroups,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= recentMonths.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _monthName(recentMonths[index]),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => isDark
                        ? AppColors.surfaceDarkElevated
                        : Colors.white,
                    tooltipBorder: BorderSide(
                      color: AppColors.primary.withOpacity(0.4),
                    ),
                    getTooltipItem: (group, _, rod, __) {
                      return BarTooltipItem(
                        '$currency${CurrencyUtils.formatAmount(rod.toY, currency)}',
                        theme.textTheme.labelMedium!.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Peak month: $currency${CurrencyUtils.formatAmount(maxSpending, currency)}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(String monthKey) {
    final parts = monthKey.split('-');
    if (parts.length < 2) return monthKey;
    final month = int.tryParse(parts[1]) ?? 1;
    return _monthLabels[(month - 1).clamp(0, 11)];
  }
}

/// A single fuel type's share of total spend, for the breakdown donut.
class _SpendSlice {
  final String label;
  final double amount;

  const _SpendSlice({required this.label, required this.amount});
}

class _SpendingPanel extends StatelessWidget {
  final Map<String, dynamic> stats;
  final String currency;

  const _SpendingPanel({required this.stats, required this.currency});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final costPerKm = stats['costPerKm'] as double;
    final costPerLiter = stats['costPerLiter'] as double;
    final averageFillCost = stats['averageFillCost'] as double;
    final maxFillCost = stats['maxFillCost'] as double;
    final minFillCost = stats['minFillCost'] as double;
    final maxRecord = stats['maxFillRecord'] as FillRecord?;
    final minRecord = stats['minFillRecord'] as FillRecord?;
    final dateFormat = DateFormat('dd MMM');

    String money(double value) =>
        '$currency${CurrencyUtils.formatAmount(value, currency)}';

    return GlassPanel(
      color: isDark ? const Color(0xB2161B22) : null,
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatLine(
                  label: 'Cost / km',
                  value: costPerKm > 0 ? money(costPerKm) : '--',
                  accent: AppColors.accentBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatLine(
                  label: 'Cost / litre',
                  value: costPerLiter > 0 ? money(costPerLiter) : '--',
                  accent: AppColors.accentAmber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatLine(
                  label: 'Avg fill',
                  value: averageFillCost > 0 ? money(averageFillCost) : '--',
                  accent: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniCard(
                  label: 'Priciest Fill',
                  value: maxFillCost > 0 ? money(maxFillCost) : '--',
                  hint: maxRecord != null
                      ? dateFormat.format(maxRecord.date)
                      : '--',
                  valueColor: AppColors.accentAmber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniCard(
                  label: 'Cheapest Fill',
                  value: minFillCost > 0 ? money(minFillCost) : '--',
                  hint: minRecord != null
                      ? dateFormat.format(minRecord.date)
                      : '--',
                  valueColor: const Color(0xFF22C55E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _StatLine({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: accent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SpendBreakdownPanel extends StatelessWidget {
  final List<_SpendSlice> breakdown;
  final String currency;

  const _SpendBreakdownPanel({required this.breakdown, required this.currency});

  static const _palette = [
    AppColors.primary,
    AppColors.accentBlue,
    AppColors.accentAmber,
    AppColors.accentPurple,
    Color(0xFF22C55E),
    Color(0xFFEF4444),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final total = breakdown.fold<double>(0, (sum, slice) => sum + slice.amount);
    if (total <= 0) {
      return const SizedBox.shrink();
    }

    final sections = <PieChartSectionData>[];
    for (var i = 0; i < breakdown.length; i++) {
      final slice = breakdown[i];
      sections.add(
        PieChartSectionData(
          value: slice.amount,
          color: _palette[i % _palette.length],
          radius: 26,
          showTitle: false,
        ),
      );
    }

    return GlassPanel(
      color: isDark ? const Color(0xB2161B22) : null,
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spend by Fuel Type',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                height: 120,
                width: 120,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 32,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < breakdown.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _LegendRow(
                          color: _palette[i % _palette.length],
                          label: breakdown[i].label,
                          amount:
                              '$currency${CurrencyUtils.formatAmount(breakdown[i].amount, currency)}',
                          percent:
                              '${(breakdown[i].amount / total * 100).toStringAsFixed(0)}%',
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String amount;
  final String percent;

  const _LegendRow({
    required this.color,
    required this.label,
    required this.amount,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          height: 12,
          width: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          '$amount  ',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        Text(
          percent,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CadencePanel extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _CadencePanel({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final avgDays = stats['averageDaysBetweenFills'] as double;
    final fillsPerMonth = stats['fillsPerMonth'] as double;
    final firstFillDate = stats['firstFillDate'] as DateTime?;
    final totalDays = stats['totalDays'] as int;
    final spanMonths = totalDays > 0 ? (totalDays / 30).ceil() : 0;
    final dateFormat = DateFormat('MMM yyyy');

    return GlassPanel(
      color: isDark ? const Color(0xB2161B22) : null,
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fill Cadence',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatLine(
                  label: 'Avg gap',
                  value: avgDays > 0
                      ? '${avgDays.toStringAsFixed(0)} d'
                      : '--',
                  accent: AppColors.accentBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatLine(
                  label: 'Fills / month',
                  value: fillsPerMonth > 0
                      ? fillsPerMonth.toStringAsFixed(1)
                      : '--',
                  accent: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatLine(
                  label: 'Active since',
                  value: firstFillDate != null
                      ? dateFormat.format(firstFillDate)
                      : '--',
                  accent: AppColors.accentPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            spanMonths > 0
                ? 'Tracking $spanMonths month${spanMonths == 1 ? '' : 's'} of activity'
                : 'Tracking your first month of activity',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _ForecastPanel extends StatelessWidget {
  final Map<String, dynamic> forecast;

  const _ForecastPanel({required this.forecast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final nextRefillDate = forecast['nextRefillDate'] as DateTime;
    final daysUntilRefill = forecast['daysUntilRefill'] as int;
    final expectedCost = forecast['expectedCost'] as double;
    final expectedCurrency = forecast['expectedCurrency'] as String;
    final confidence = forecast['confidence'] as double;
    final status = forecast['status'] as String;
    final dateFormat = DateFormat('EEE, dd MMM');

    final statusColor = status == 'overdue'
        ? const Color(0xFFEF4444)
        : status == 'soon'
            ? AppColors.accentAmber
            : const Color(0xFF22C55E);
    final whenLabel = daysUntilRefill < 0
        ? '${daysUntilRefill.abs()} day${daysUntilRefill.abs() == 1 ? '' : 's'} overdue'
        : daysUntilRefill == 0
            ? 'Due today'
            : 'in $daysUntilRefill day${daysUntilRefill == 1 ? '' : 's'}';

    return GlassPanel(
      color: isDark ? const Color(0xB2161B22) : null,
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, size: 20, color: statusColor),
              const SizedBox(width: 8),
              Text(
                'Next Refill Forecast',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                dateFormat.format(nextRefillDate),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  whenLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Expected cost ~ $expectedCurrency${CurrencyUtils.formatAmount(expectedCost, expectedCurrency)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Confidence',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: confidence.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor:
                        theme.colorScheme.onSurface.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation(statusColor),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(confidence * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CostOfOwnershipPanel extends StatelessWidget {
  final double fuelSpent;
  final Map<String, dynamic> maintenance;
  final String currency;

  const _CostOfOwnershipPanel({
    required this.fuelSpent,
    required this.maintenance,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final maintenanceCost = maintenance['totalCost'] as double;
    final overdueCount = maintenance['overdueCount'] as int;
    final dueSoonCount = maintenance['dueSoonCount'] as int;
    final total = fuelSpent + maintenanceCost;
    final fuelFraction = total > 0 ? fuelSpent / total : 0.0;

    String money(double value) =>
        '$currency${CurrencyUtils.formatAmount(value, currency)}';

    return GlassPanel(
      color: isDark ? const Color(0xB2161B22) : null,
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cost of Ownership',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                money(total),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Expanded(
                  flex: ((fuelFraction * 1000).round()).clamp(1, 1000),
                  child: Container(height: 12, color: AppColors.primary),
                ),
                Expanded(
                  flex: (((1 - fuelFraction) * 1000).round()).clamp(1, 1000),
                  child: Container(height: 12, color: AppColors.accentPurple),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _LegendRow(
                  color: AppColors.primary,
                  label: 'Fuel',
                  amount: money(fuelSpent),
                  percent: '${(fuelFraction * 100).toStringAsFixed(0)}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _LegendRow(
                  color: AppColors.accentPurple,
                  label: 'Maintenance',
                  amount: money(maintenanceCost),
                  percent:
                      '${((1 - fuelFraction) * 100).toStringAsFixed(0)}%',
                ),
              ),
            ],
          ),
          if (overdueCount > 0 || dueSoonCount > 0) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              children: [
                if (overdueCount > 0)
                  _StatusPill(
                    label: '$overdueCount overdue',
                    color: const Color(0xFFEF4444),
                  ),
                if (dueSoonCount > 0)
                  _StatusPill(
                    label: '$dueSoonCount due soon',
                    color: AppColors.accentAmber,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDarkElevated : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? AppColors.outlineDark.withOpacity(0.6)
                : AppColors.outlineLight,
          ),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color backgroundColor;
  final Color foregroundColor;

  _GaugePainter({
    required this.value,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2.2;
    const strokeWidth = 12.0;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final foregroundPaint = Paint()
      ..color = foregroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = math.pi;
    const sweepAngle = math.pi;

    canvas.drawArc(rect, startAngle, sweepAngle, false, backgroundPaint);
    canvas.drawArc(
        rect, startAngle, sweepAngle * value, false, foregroundPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.foregroundColor != foregroundColor;
  }
}

class _EmptyState extends StatelessWidget {
  final ColorScheme colorScheme;

  const _EmptyState({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.analytics_outlined,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Data Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add vehicle activity to see your statistics',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
