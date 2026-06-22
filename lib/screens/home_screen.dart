import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/fill_record.dart';
import '../models/fuel_type.dart';
import '../models/maintenance_record.dart';
import '../models/vehicle.dart';
import '../providers/records_provider.dart';
import '../theme/app_theme.dart';
import '../utils/currency_utils.dart';
import 'add_vehicle_screen.dart';
import 'log_entry_screen.dart';
import 'maintenance_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import 'vehicles_screen.dart';

enum _LogEntryType { maintenance, fuel }

class _LogEntry {
  final _LogEntryType type;
  final FillRecord? fuelRecord;
  final MaintenanceRecord? maintenanceRecord;

  const _LogEntry.fuel(this.fuelRecord)
      : type = _LogEntryType.fuel,
        maintenanceRecord = null;

  const _LogEntry.maintenance(this.maintenanceRecord)
      : type = _LogEntryType.maintenance,
        fuelRecord = null;

  DateTime get date {
    switch (type) {
      case _LogEntryType.fuel:
        return fuelRecord!.date;
      case _LogEntryType.maintenance:
        return maintenanceRecord!.serviceDate;
    }
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : null,
      body: SafeArea(
        child: Consumer<RecordsProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final vehicles = provider.activeVehicles;
            if (vehicles.isEmpty) {
              return _NoVehicleHome(
                onAddVehicle: () => _navigateToAddVehicle(context),
                onSettings: () => _navigateToSettings(context),
              );
            }

            final selectedVehicleId = provider.selectedVehicleId;
            final selectedVehicle = provider.selectedVehicle;
            final fuelRecords = provider.getRecordsForVehicle(selectedVehicleId)
              ..sort((a, b) => b.date.compareTo(a.date));
            final maintenanceRecords =
                provider.getMaintenanceRecordsForVehicle(selectedVehicleId);
            final timeline = <_LogEntry>[
              ...maintenanceRecords.map(_LogEntry.maintenance),
              ...fuelRecords.map(_LogEntry.fuel),
            ]..sort((a, b) => b.date.compareTo(a.date));

            final stats =
                provider.getOverallStats(vehicleId: selectedVehicleId);
            final maintenanceOverview =
                provider.getMaintenanceOverview(vehicleId: selectedVehicleId);
            final forecast =
                provider.getRefillForecast(vehicleId: selectedVehicleId);
            final monthlySpending =
                stats['monthlySpending'] as Map<String, double>;
            final now = DateTime.now();
            final thisMonthKey =
                '${now.year}-${now.month.toString().padLeft(2, '0')}';
            final thisMonthSpend = monthlySpending[thisMonthKey] ?? 0.0;
            final highestLoggedOdometer =
                provider.getHighestOdometerForVehicle(selectedVehicleId);
            final vehicleOdometer = selectedVehicle?.currentOdometer ?? 0;
            final currentOdometer = highestLoggedOdometer > vehicleOdometer
                ? highestLoggedOdometer
                : vehicleOdometer;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _HomeHeader(
                    vehicle: selectedVehicle,
                    onOpenStats: () => _navigateToStats(context),
                    onOpenSettings: () => _navigateToSettings(context),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: _VehicleSwitcher(
                      vehicles: vehicles,
                      selectedVehicleId: selectedVehicleId,
                      onSelected: provider.setSelectedVehicle,
                      onManage: () => _navigateToVehicles(context),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                    child: _CareStatusPanel(
                      overview: maintenanceOverview,
                      currentOdometer: currentOdometer,
                      thisMonthSpend: thisMonthSpend,
                      currency: provider.currency,
                      averageMileage: (stats['averageMileage'] as double?) ?? 0,
                      onLogService: () => _navigateToAddMaintenance(context),
                      onLogFuel: () => _navigateToAddFuel(context),
                      onOpenMaintenance: () =>
                          _navigateToMaintenance(context, selectedVehicleId),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: _NextStepsRow(
                      overview: maintenanceOverview,
                      forecast: forecast,
                      onOpenMaintenance: () =>
                          _navigateToMaintenance(context, selectedVehicleId),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                    child: _SectionTitle(
                      title: 'Activity',
                      actionLabel: 'View services',
                      onAction: () =>
                          _navigateToMaintenance(context, selectedVehicleId),
                    ),
                  ),
                ),
                if (timeline.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyTimeline(
                      onLogService: () => _navigateToAddMaintenance(context),
                      onLogFuel: () => _navigateToAddFuel(context),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                    sliver: SliverList.separated(
                      itemCount: timeline.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final entry = timeline[index];
                        return _TimelineCard(
                          entry: entry,
                          provider: provider,
                          onEditFuel: (record) =>
                              _navigateToEditFuel(context, record),
                          onEditMaintenance: (record) =>
                              _navigateToEditMaintenance(context, record),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddFuel(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log Activity'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _navigateToAddFuel(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LogEntryScreen(initialMode: LogMode.fuel),
      ),
    );
  }

  void _navigateToEditFuel(BuildContext context, FillRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LogEntryScreen(editFillRecord: record),
      ),
    );
  }

  void _navigateToAddMaintenance(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            const LogEntryScreen(initialMode: LogMode.service),
      ),
    );
  }

  void _navigateToEditMaintenance(
    BuildContext context,
    MaintenanceRecord record,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LogEntryScreen(editMaintenanceRecord: record),
      ),
    );
  }

  void _navigateToMaintenance(BuildContext context, String vehicleId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MaintenanceScreen(initialVehicleId: vehicleId),
      ),
    );
  }

  void _navigateToVehicles(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const VehiclesScreen(),
      ),
    );
  }

  void _navigateToAddVehicle(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddVehicleScreen(),
      ),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  void _navigateToStats(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const StatsScreen(),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final Vehicle? vehicle;
  final VoidCallback onOpenStats;
  final VoidCallback onOpenSettings;

  const _HomeHeader({
    required this.vehicle,
    required this.onOpenStats,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final vehicleName = vehicle?.name ?? 'Vehicle';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.directions_car_filled_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vehicle Logbook',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  vehicleName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.62),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _HeaderAction(
            icon: Icons.insights_rounded,
            onTap: onOpenStats,
          ),
          const SizedBox(width: 8),
          _HeaderAction(
            icon: Icons.settings_rounded,
            onTap: onOpenSettings,
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderAction({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: isDark ? AppColors.surfaceDarkElevated : Colors.white,
        foregroundColor: theme.colorScheme.onSurface,
        side: BorderSide(
          color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

class _VehicleSwitcher extends StatelessWidget {
  final List<Vehicle> vehicles;
  final String selectedVehicleId;
  final ValueChanged<String> onSelected;
  final VoidCallback onManage;

  const _VehicleSwitcher({
    required this.vehicles,
    required this.selectedVehicleId,
    required this.onSelected,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: vehicles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                final isSelected = vehicle.id == selectedVehicleId;
                final label = vehicle.plateNumber == null
                    ? vehicle.name
                    : '${vehicle.name}  ${vehicle.plateNumber}';
                return ChoiceChip(
                  selected: isSelected,
                  showCheckmark: false,
                  avatar: Icon(
                    Icons.directions_car_rounded,
                    size: 18,
                    color: isSelected ? Colors.white : AppColors.primary,
                  ),
                  label: Text(label),
                  onSelected: (_) => onSelected(vehicle.id),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onManage,
            icon: const Icon(Icons.tune_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.surfaceDarkElevated
                  : Colors.white,
              side: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.outlineDark
                    : AppColors.outlineLight,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CareStatusPanel extends StatelessWidget {
  final Map<String, dynamic> overview;
  final double currentOdometer;
  final double thisMonthSpend;
  final String currency;
  final double averageMileage;
  final VoidCallback onLogService;
  final VoidCallback onLogFuel;
  final VoidCallback onOpenMaintenance;

  const _CareStatusPanel({
    required this.overview,
    required this.currentOdometer,
    required this.thisMonthSpend,
    required this.currency,
    required this.averageMileage,
    required this.onLogService,
    required this.onLogFuel,
    required this.onOpenMaintenance,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overdueCount = overview['overdueCount'] as int;
    final dueSoonCount = overview['dueSoonCount'] as int;
    final latestServiceDate = overview['latestServiceDate'] as DateTime?;
    final attentionCount = overdueCount + dueSoonCount;
    final statusColor = overdueCount > 0
        ? const Color(0xFFEF4444)
        : dueSoonCount > 0
            ? AppColors.accentAmber
            : AppColors.primary;
    final statusTitle = overdueCount > 0
        ? 'Needs attention'
        : dueSoonCount > 0
            ? 'Service coming up'
            : 'Ready to drive';
    final statusDetail = overdueCount > 0
        ? '$overdueCount overdue item${overdueCount == 1 ? '' : 's'}'
        : dueSoonCount > 0
            ? '$dueSoonCount item${dueSoonCount == 1 ? '' : 's'} due soon'
            : latestServiceDate == null
                ? 'No service history yet'
                : 'Last service ${DateFormat('MMM d').format(latestServiceDate)}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? AppColors.surfaceDark
            : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? AppColors.outlineDark
              : AppColors.outlineLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.28 : 0.07,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.verified_rounded,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusDetail,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.64),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onOpenMaintenance,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _CareMetric(
                  label: 'Odometer',
                  value: '${currentOdometer.toStringAsFixed(0)} km',
                ),
              ),
              Expanded(
                child: _CareMetric(
                  label: 'Open items',
                  value: attentionCount.toString(),
                ),
              ),
              Expanded(
                child: _CareMetric(
                  label: 'This month',
                  value:
                      '$currency${CurrencyUtils.formatAmount(thisMonthSpend, currency)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            averageMileage > 0
                ? 'Fuel average: ${averageMileage.toStringAsFixed(1)} km/L'
                : 'Fuel average appears after two fuel logs',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onLogService,
                  icon: const Icon(Icons.build_rounded, size: 18),
                  label: const Text('Service'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onLogFuel,
                  icon: const Icon(Icons.local_gas_station_rounded, size: 18),
                  label: const Text('Fuel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CareMetric extends StatelessWidget {
  final String label;
  final String value;

  const _CareMetric({
    required this.label,
    required this.value,
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
            color: theme.colorScheme.onSurface.withValues(alpha: 0.54),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _NextStepsRow extends StatelessWidget {
  final Map<String, dynamic> overview;
  final Map<String, dynamic>? forecast;
  final VoidCallback onOpenMaintenance;

  const _NextStepsRow({
    required this.overview,
    required this.forecast,
    required this.onOpenMaintenance,
  });

  @override
  Widget build(BuildContext context) {
    final dueItems =
        (overview['dueItems'] as List<dynamic>).cast<Map<String, dynamic>>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 620;
        final maintenanceCard = _MaintenanceNextCard(
          dueItems: dueItems,
          onTap: onOpenMaintenance,
        );
        final fuelCard = _FuelNextCard(
          forecast: forecast,
        );

        if (narrow) {
          return Column(
            children: [
              maintenanceCard,
              const SizedBox(height: 10),
              fuelCard,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: maintenanceCard),
            const SizedBox(width: 10),
            Expanded(child: fuelCard),
          ],
        );
      },
    );
  }
}

class _MaintenanceNextCard extends StatelessWidget {
  final List<Map<String, dynamic>> dueItems;
  final VoidCallback onTap;

  const _MaintenanceNextCard({
    required this.dueItems,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasDueItem = dueItems.isNotEmpty;
    final record =
        hasDueItem ? dueItems.first['record'] as MaintenanceRecord : null;
    final status = hasDueItem
        ? (dueItems.first['dueStatus'] as Map<String, dynamic>)['status']
            as String
        : 'on_track';
    final color = status == 'overdue'
        ? const Color(0xFFEF4444)
        : status == 'due_soon'
            ? AppColors.accentAmber
            : AppColors.primary;

    return _SignalCard(
      icon: Icons.build_rounded,
      color: color,
      title: hasDueItem ? record!.serviceType : 'Maintenance',
      value: hasDueItem
          ? status == 'overdue'
              ? 'Overdue'
              : 'Due soon'
          : 'No open items',
      detail: hasDueItem
          ? dueItems.length == 1
              ? 'Check service plan'
              : '${dueItems.length} service items need review'
          : 'Service history is clear',
      onTap: onTap,
    );
  }
}

class _FuelNextCard extends StatelessWidget {
  final Map<String, dynamic>? forecast;

  const _FuelNextCard({
    required this.forecast,
  });

  @override
  Widget build(BuildContext context) {
    final nextForecast = forecast;
    if (nextForecast == null) {
      return const _SignalCard(
        icon: Icons.local_gas_station_rounded,
        color: AppColors.accentBlue,
        title: 'Fuel',
        value: 'Learning pattern',
        detail: 'Add another fuel log for refill timing',
      );
    }

    final daysUntilRefill = nextForecast['daysUntilRefill'] as int;
    final expectedCost = (nextForecast['expectedCost'] as num).toDouble();
    final expectedCurrency =
        nextForecast['expectedCurrency'] as String? ?? FuelType.defaultCurrency;
    final status = nextForecast['status'] as String;
    final color = status == 'overdue'
        ? const Color(0xFFEF4444)
        : status == 'soon'
            ? AppColors.accentAmber
            : AppColors.accentBlue;
    final value = daysUntilRefill < 0
        ? '${daysUntilRefill.abs()}d overdue'
        : daysUntilRefill == 0
            ? 'Due today'
            : 'In $daysUntilRefill d';

    return _SignalCard(
      icon: Icons.local_gas_station_rounded,
      color: color,
      title: 'Fuel',
      value: value,
      detail:
          'Expected $expectedCurrency${CurrencyUtils.formatAmount(expectedCost, expectedCurrency)}',
    );
  }
}

class _SignalCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String detail;
  final VoidCallback? onTap;

  const _SignalCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.detail,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.56),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.58),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  const _SectionTitle({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final _LogEntry entry;
  final RecordsProvider provider;
  final ValueChanged<FillRecord> onEditFuel;
  final ValueChanged<MaintenanceRecord> onEditMaintenance;

  const _TimelineCard({
    required this.entry,
    required this.provider,
    required this.onEditFuel,
    required this.onEditMaintenance,
  });

  @override
  Widget build(BuildContext context) {
    switch (entry.type) {
      case _LogEntryType.maintenance:
        return _MaintenanceTimelineCard(
          record: entry.maintenanceRecord!,
          provider: provider,
          onTap: () => onEditMaintenance(entry.maintenanceRecord!),
        );
      case _LogEntryType.fuel:
        return _FuelTimelineCard(
          record: entry.fuelRecord!,
          provider: provider,
          onTap: () => onEditFuel(entry.fuelRecord!),
        );
    }
  }
}

class _MaintenanceTimelineCard extends StatelessWidget {
  final MaintenanceRecord record;
  final RecordsProvider provider;
  final VoidCallback onTap;

  const _MaintenanceTimelineCard({
    required this.record,
    required this.provider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueStatus = provider.getMaintenanceDueStatus(record);
    final status = dueStatus['status'] as String;
    final color = _maintenanceColor(status);
    final statusLabel = _maintenanceLabel(status);

    return _ActivityShell(
      accent: color,
      icon: Icons.build_circle_rounded,
      onTap: onTap,
      header: _formatDate(record.serviceDate),
      title: record.serviceType,
      badge: statusLabel,
      badgeColor: color,
      children: [
        Text(
          '${_categoryLabel(record.category)} at ${record.odometerKm.toStringAsFixed(0)} km',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
          ),
        ),
        if (record.cost > 0) ...[
          const SizedBox(height: 8),
          _InlineMeta(
            icon: Icons.payments_rounded,
            text:
                '${provider.currency}${CurrencyUtils.formatAmount(record.cost, provider.currency)}',
          ),
        ],
        if (record.nextDueDate != null || record.nextDueOdometerKm != null) ...[
          const SizedBox(height: 8),
          _InlineMeta(
            icon: Icons.event_repeat_rounded,
            text: _nextDueText(record),
          ),
        ],
        if (record.notes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            record.notes,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Color _maintenanceColor(String status) {
    switch (status) {
      case 'overdue':
        return const Color(0xFFEF4444);
      case 'due_soon':
        return AppColors.accentAmber;
      case 'on_track':
        return AppColors.primary;
      default:
        return AppColors.accentBlue;
    }
  }

  String _maintenanceLabel(String status) {
    switch (status) {
      case 'overdue':
        return 'Overdue';
      case 'due_soon':
        return 'Due soon';
      case 'on_track':
        return 'Scheduled';
      default:
        return 'Done';
    }
  }
}

class _FuelTimelineCard extends StatelessWidget {
  final FillRecord record;
  final RecordsProvider provider;
  final VoidCallback onTap;

  const _FuelTimelineCard({
    required this.record,
    required this.provider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = provider.getRecordStats(record);
    final isFirstRecord = stats['isFirstRecord'] as bool;
    final mileage = stats['mileage'] as double;
    final fuelLiters = stats['fuelLiters'] as double;
    final fuelTypeName = stats['fuelTypeName'] as String? ?? 'Fuel';
    final efficiency = isFirstRecord
        ? 'Baseline reading'
        : '${mileage.toStringAsFixed(1)} km/L';

    return _ActivityShell(
      accent: AppColors.accentBlue,
      icon: Icons.local_gas_station_rounded,
      onTap: onTap,
      header: _formatDate(record.date),
      title: 'Fuel',
      badge: fuelTypeName,
      badgeColor: AppColors.accentBlue,
      children: [
        Text(
          '${record.odometerKm.toStringAsFixed(0)} km',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: [
            _InlineMeta(
              icon: Icons.payments_rounded,
              text:
                  '${provider.getCurrencyForRecord(record)}${CurrencyUtils.formatAmount(record.cost, provider.getCurrencyForRecord(record))}',
            ),
            _InlineMeta(
              icon: Icons.water_drop_rounded,
              text: '${fuelLiters.toStringAsFixed(1)} L',
            ),
            _InlineMeta(
              icon: Icons.speed_rounded,
              text: efficiency,
            ),
          ],
        ),
        if (record.notes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            record.notes,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

class _ActivityShell extends StatelessWidget {
  final Color accent;
  final IconData icon;
  final VoidCallback onTap;
  final String header;
  final String title;
  final String badge;
  final Color badgeColor;
  final List<Widget> children;

  const _ActivityShell({
    required this.accent,
    required this.icon,
    required this.onTap,
    required this.header,
    required this.title,
    required this.badge,
    required this.badgeColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(18),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 38,
                          width: 38,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: accent, size: 21),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          header,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.52),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          title,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: badgeColor.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      badge,
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: badgeColor,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...children,
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineMeta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InlineMeta({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 5),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _EmptyTimeline extends StatelessWidget {
  final VoidCallback onLogService;
  final VoidCallback onLogFuel;

  const _EmptyTimeline({
    required this.onLogService,
    required this.onLogFuel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 76,
            width: 76,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.fact_check_rounded,
              color: AppColors.primary,
              size: 38,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Start the vehicle logbook',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Capture maintenance first, then add fuel whenever it matters.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: onLogService,
                icon: const Icon(Icons.build_rounded),
                label: const Text('Service'),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: onLogFuel,
                icon: const Icon(Icons.local_gas_station_rounded),
                label: const Text('Fuel'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoVehicleHome extends StatelessWidget {
  final VoidCallback onAddVehicle;
  final VoidCallback onSettings;

  const _NoVehicleHome({
    required this.onAddVehicle,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Vehicle Logbook',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: onSettings,
                icon: const Icon(Icons.settings_rounded),
              ),
            ],
          ),
          const Spacer(),
          Center(
            child: Column(
              children: [
                Container(
                  height: 88,
                  width: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(
                    Icons.directions_car_rounded,
                    color: AppColors.primary,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Add a vehicle first',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Every service, repair, reminder, and fuel log belongs to a vehicle.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onAddVehicle,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Vehicle'),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final value = DateTime(date.year, date.month, date.day);
  final dayDifference = today.difference(value).inDays;
  if (dayDifference == 0) {
    return 'Today';
  }
  if (dayDifference == 1) {
    return 'Yesterday';
  }
  return DateFormat('MMM d, yyyy').format(date);
}

String _categoryLabel(String category) {
  switch (category) {
    case 'oil_change':
      return 'Oil change';
    case 'tire':
      return 'Tire / wheel';
    case 'brake':
      return 'Brake service';
    case 'battery':
      return 'Battery';
    case 'engine':
      return 'Engine';
    case 'insurance':
      return 'Insurance / registration';
    case 'other':
      return 'Other';
    default:
      return 'General service';
  }
}

String _nextDueText(MaintenanceRecord record) {
  final parts = <String>[];
  if (record.nextDueDate != null) {
    parts.add('Due ${DateFormat('MMM d, yyyy').format(record.nextDueDate!)}');
  }
  if (record.nextDueOdometerKm != null) {
    parts.add('${record.nextDueOdometerKm!.toStringAsFixed(0)} km');
  }
  return parts.join(' / ');
}
