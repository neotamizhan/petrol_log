import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/maintenance_record.dart';
import '../providers/records_provider.dart';
import '../widgets/record_card.dart';
import 'add_record_screen.dart';
import 'edit_record_screen.dart';
import 'maintenance_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import 'vehicles_screen.dart';
import '../theme/app_theme.dart';
import '../utils/currency_utils.dart';
import '../widgets/glass_panel.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : null,
      body: SafeArea(
        child: Consumer<RecordsProvider>(
          builder: (context, provider, child) {
            final selectedVehicleId = provider.selectedVehicleId;
            final stats =
                provider.getOverallStats(vehicleId: selectedVehicleId);
            final sorted = provider.records
                .where((record) => record.vehicleId == selectedVehicleId)
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));
            final latest = sorted.isNotEmpty ? sorted.first : null;
            final lastRefuelDays = latest == null
                ? null
                : DateTime.now().difference(latest.date).inDays;
            final forecast =
                provider.getRefillForecast(vehicleId: selectedVehicleId);
            final maintenanceOverview =
                provider.getMaintenanceOverview(vehicleId: selectedVehicleId);

            return Stack(
              children: [
                if (isDark)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _DotPatternPainter(
                          dotColor:
                              AppColors.surfaceDarkElevated.withOpacity(0.58),
                          spacing: 20,
                        ),
                      ),
                    ),
                  ),
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.backgroundDark.withOpacity(0.78)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: isDark
                                ? Border.all(
                                    color:
                                        AppColors.outlineDark.withOpacity(0.5))
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    height: 40,
                                    width: 40,
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.primary.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.local_gas_station_rounded,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Petrol Log',
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        'Recent Records',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurface
                                              .withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  _IconBubble(
                                    icon: Icons.bar_chart_rounded,
                                    onTap: () => _navigateToStats(context),
                                  ),
                                  const SizedBox(width: 8),
                                  _IconBubble(
                                    icon: Icons.build_rounded,
                                    onTap: () =>
                                        _navigateToMaintenance(context),
                                  ),
                                  const SizedBox(width: 8),
                                  _IconBubble(
                                    icon: Icons.settings_rounded,
                                    onTap: () => _navigateToSettings(context),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: _VehicleSelector(
                          provider: provider,
                          isDark: isDark,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                        child: _SummaryCard(
                          currency: provider.currency,
                          currentOdometer: latest?.odometerKm ?? 0,
                          averageMileage:
                              (stats['averageMileage'] as double?) ?? 0,
                          lastRefuelDays: lastRefuelDays,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                        child: _RefillRadarCard(
                          forecast: forecast,
                          currency: provider.currency,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                        child: _MaintenanceDigestCard(
                          overview: maintenanceOverview,
                          onTapManage: () => _navigateToMaintenance(context),
                        ),
                      ),
                    ),
                    if (provider.isLoading)
                      const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (sorted.isEmpty)
                      SliverFillRemaining(
                        child: _EmptyState(colorScheme: colorScheme),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.only(bottom: 110),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final record = sorted[index];
                              final recordStats =
                                  provider.getRecordStats(record);

                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration:
                                    Duration(milliseconds: 300 + (index * 50)),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Transform.translate(
                                    offset: Offset(0, 16 * (1 - value)),
                                    child: Opacity(
                                      opacity: value,
                                      child: child,
                                    ),
                                  );
                                },
                                child: RecordCard(
                                  record: record,
                                  stats: recordStats,
                                  currency: provider.currency,
                                  onDelete: () =>
                                      provider.deleteRecord(record.id),
                                  onEdit: () =>
                                      _navigateToEditRecord(context, record),
                                ),
                              );
                            },
                            childCount: sorted.length,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddRecord(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Fill'),
        elevation: 6,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _navigateToAddRecord(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddRecordScreen(),
      ),
    );
  }

  void _navigateToEditRecord(BuildContext context, record) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditRecordScreen(record: record),
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

  void _navigateToMaintenance(BuildContext context) {
    final provider = context.read<RecordsProvider>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MaintenanceScreen(
          initialVehicleId: provider.selectedVehicleId,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ColorScheme colorScheme;

  const _EmptyState({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_gas_station_rounded,
                size: 54,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Fill Records Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to log your first petrol fill',
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

class _IconBubble extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBubble({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDarkElevated : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? AppColors.outlineDark.withOpacity(0.7)
                : AppColors.outlineLight,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String currency;
  final double currentOdometer;
  final double averageMileage;
  final int? lastRefuelDays;

  const _SummaryCard({
    required this.currency,
    required this.currentOdometer,
    required this.averageMileage,
    required this.lastRefuelDays,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lastRefuelText = lastRefuelDays == null
        ? 'No data'
        : lastRefuelDays == 0
            ? 'Today'
            : '$lastRefuelDays days ago';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Odometer',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${currentOdometer.toStringAsFixed(0)} km',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.speed_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: 'Avg. Mileage',
                  value: averageMileage > 0
                      ? '${averageMileage.toStringAsFixed(1)} km/L'
                      : '--',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryMetric(
                  label: 'Last Refuel',
                  value: lastRefuelText,
                ),
              ),
            ],
          ),
          if (!isDark) const SizedBox(height: 4),
          if (!isDark)
            Text(
              'Currency: $currency',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _RefillRadarCard extends StatelessWidget {
  final Map<String, dynamic>? forecast;
  final String currency;

  const _RefillRadarCard({
    required this.forecast,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (forecast == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child:
                  const Icon(Icons.radar_rounded, color: AppColors.accentBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Refuel Radar unlocks after your next fill. Add more records for AI-style predictions.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final status = forecast!['status'] as String;
    final daysUntilRefill = forecast!['daysUntilRefill'] as int;
    final nextRefillDate = forecast!['nextRefillDate'] as DateTime;
    final projectedOdometerKm =
        (forecast!['projectedOdometerKm'] as num).toDouble();
    final expectedCost = (forecast!['expectedCost'] as num).toDouble();
    final confidence = (forecast!['confidence'] as num).toDouble();
    final forecastDays = forecast!['forecastDays'] as int;
    final intervalCount = forecast!['intervalCount'] as int;
    final progress =
        ((forecast!['progress'] as num).toDouble()).clamp(0.0, 1.0);
    final dateFormat = DateFormat('EEE, dd MMM');

    final statusText = daysUntilRefill < 0
        ? '${daysUntilRefill.abs()} days overdue'
        : daysUntilRefill == 0
            ? 'Refuel due today'
            : 'Refuel in $daysUntilRefill day${daysUntilRefill == 1 ? '' : 's'}';

    final statusColor = _statusColor(status);
    final confidenceLabel = _confidenceLabel(confidence);
    final confidenceColor = _confidenceColor(confidence);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradientForStatus(status),
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.radar_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Refuel Radar',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.17),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$confidenceLabel confidence',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            statusText,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Expected around ${dateFormat.format(nextRefillDate)} based on your last $intervalCount fills.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.86),
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.22),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ForecastMetric(
                  label: 'Expected Cost',
                  value:
                      '$currency${CurrencyUtils.formatAmount(expectedCost, currency)}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ForecastMetric(
                  label: 'Target Odo',
                  value: '${projectedOdometerKm.toStringAsFixed(0)} km',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ForecastMetric(
                  label: 'Cycle',
                  value: '$forecastDays days',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Model stability: $confidenceLabel',
            style: theme.textTheme.labelSmall?.copyWith(
              color: confidenceColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _gradientForStatus(String status) {
    switch (status) {
      case 'overdue':
        return const [Color(0xFFEF4444), Color(0xFFB91C1C)];
      case 'soon':
        return const [Color(0xFFF59E0B), Color(0xFFD97706)];
      default:
        return const [AppColors.accentBlue, AppColors.primaryDark];
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'overdue':
        return const Color(0xFFEF4444);
      case 'soon':
        return const Color(0xFFF59E0B);
      default:
        return AppColors.accentBlue;
    }
  }

  String _confidenceLabel(double confidence) {
    if (confidence >= 0.75) {
      return 'High';
    }
    if (confidence >= 0.5) {
      return 'Medium';
    }
    return 'Low';
  }

  Color _confidenceColor(double confidence) {
    if (confidence >= 0.75) {
      return const Color(0xFFD6F6E7);
    }
    if (confidence >= 0.5) {
      return const Color(0xFFFFF2CC);
    }
    return const Color(0xFFFEE2E2);
  }
}

class _MaintenanceDigestCard extends StatelessWidget {
  final Map<String, dynamic> overview;
  final VoidCallback onTapManage;

  const _MaintenanceDigestCard({
    required this.overview,
    required this.onTapManage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final totalRecords = overview['totalRecords'] as int;
    final overdueCount = overview['overdueCount'] as int;
    final dueSoonCount = overview['dueSoonCount'] as int;
    final scheduledItems = overview['scheduledItems'] as int;
    final dueItems =
        (overview['dueItems'] as List<dynamic>).cast<Map<String, dynamic>>();
    final needsAttention = overdueCount > 0 || dueSoonCount > 0;

    final title = totalRecords == 0
        ? 'Maintenance'
        : needsAttention
            ? 'Maintenance Alert'
            : 'Maintenance On Track';
    final subtitle = totalRecords == 0
        ? 'Track services like oil change, brake jobs, and inspections.'
        : needsAttention
            ? _attentionText(dueItems)
            : 'No urgent service tasks for now.';

    return InkWell(
      onTap: onTapManage,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: needsAttention
                ? (overdueCount > 0
                    ? const Color(0xFFEF4444).withOpacity(0.45)
                    : AppColors.accentAmber.withOpacity(0.45))
                : (isDark ? AppColors.outlineDark : AppColors.outlineLight),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: (needsAttention
                            ? (overdueCount > 0
                                ? const Color(0xFFEF4444)
                                : AppColors.accentAmber)
                            : AppColors.primary)
                        .withOpacity(0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.build_rounded,
                    color: needsAttention
                        ? (overdueCount > 0
                            ? const Color(0xFFEF4444)
                            : AppColors.accentAmber)
                        : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MaintenanceChip(
                  label: 'Records',
                  value: totalRecords.toString(),
                ),
                _MaintenanceChip(
                  label: 'Scheduled',
                  value: scheduledItems.toString(),
                ),
                _MaintenanceChip(
                  label: 'Overdue',
                  value: overdueCount.toString(),
                ),
                _MaintenanceChip(
                  label: 'Due Soon',
                  value: dueSoonCount.toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _attentionText(List<Map<String, dynamic>> dueItems) {
    if (dueItems.isEmpty) {
      return 'Upcoming services detected.';
    }
    final first = dueItems.first['record'] as MaintenanceRecord;
    final remaining = dueItems.length - 1;
    if (remaining <= 0) {
      return '${first.serviceType} needs attention.';
    }
    return '${first.serviceType} and $remaining more need attention.';
  }
}

class _MaintenanceChip extends StatelessWidget {
  final String label;
  final String value;

  const _MaintenanceChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _ForecastMetric extends StatelessWidget {
  final String label;
  final String value;

  const _ForecastMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _VehicleSelector extends StatelessWidget {
  final RecordsProvider provider;
  final bool isDark;

  const _VehicleSelector({
    required this.provider,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final seenVehicleIds = <String>{};
    final activeVehicles = provider.activeVehicles
        .where((vehicle) => seenVehicleIds.add(vehicle.id))
        .toList();

    if (activeVehicles.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedVehicleId = provider.selectedVehicleId;
    final selectedIsValid =
        activeVehicles.any((vehicle) => vehicle.id == selectedVehicleId);
    final dropdownValue =
        selectedIsValid ? selectedVehicleId : activeVehicles.first.id;

    if (!selectedIsValid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (provider.selectedVehicleId != dropdownValue) {
          provider.setSelectedVehicle(dropdownValue);
        }
      });
    }

    return GlassPanel(
      color: isDark
          ? AppColors.surfaceDark.withOpacity(0.7)
          : Colors.white.withOpacity(0.95),
      border: Border.all(
        color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButton<String>(
              value: dropdownValue,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: activeVehicles.map((vehicle) {
                final displayName = vehicle.plateNumber != null
                    ? '${vehicle.name} • ${vehicle.plateNumber}'
                    : vehicle.name;
                return DropdownMenuItem(
                  value: vehicle.id,
                  child: Text(
                    displayName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (vehicleId) {
                if (vehicleId != null) {
                  provider.setSelectedVehicle(vehicleId);
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.settings_rounded,
              color: colorScheme.onSurface.withOpacity(0.6),
              size: 20,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VehiclesScreen(),
                ),
              );
            },
            tooltip: 'Manage Vehicles',
          ),
        ],
      ),
    );
  }
}

class _DotPatternPainter extends CustomPainter {
  final Color dotColor;
  final double spacing;

  const _DotPatternPainter({
    required this.dotColor,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotPatternPainter oldDelegate) {
    return oldDelegate.dotColor != dotColor || oldDelegate.spacing != spacing;
  }
}
