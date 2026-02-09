import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/records_provider.dart';
import '../models/fill_record.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_panel.dart';
import 'settings_screen.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Consumer<RecordsProvider>(
          builder: (context, provider, child) {
            final stats = provider.getOverallStats();
            final totalRecords = stats['totalRecords'] as int;

            if (totalRecords == 0) {
              return _EmptyState(colorScheme: colorScheme);
            }

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
                                  'Petrol Log',
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
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: _OverviewGrid(stats: stats),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _EfficiencyPanel(stats: stats),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: _MonthlySpendPanel(stats: stats, currency: provider.currency),
                  ),
                ),
                if (!isDark)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: _InsightStrip(stats: stats),
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

  const _OverviewGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final totalRecords = stats['totalRecords'] as int;
    final totalDistance = stats['totalDistance'] as double;
    final totalFuelLiters = stats['totalFuelLiters'] as double;
    final totalDays = stats['totalDays'] as int;

    final distanceLabel = totalDistance >= 1000
        ? '${(totalDistance / 1000).toStringAsFixed(1)}k'
        : totalDistance.toStringAsFixed(0);

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
    final averageMileage = stats['averageMileage'] as double;
    final bestMileage = stats['bestMileage'] as double;
    final worstMileage = stats['worstMileage'] as double;
    final bestRecord = stats['bestMileageRecord'] as FillRecord?;
    final worstRecord = stats['worstMileageRecord'] as FillRecord?;
    final dateFormat = DateFormat('dd MMM');

    final maxMileage = averageMileage > 0 ? math.max(averageMileage * 1.4, 15) : 15.0;
    final value = (averageMileage / maxMileage).clamp(0.0, 1.0);

    return GlassPanel(
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
                    backgroundColor: theme.colorScheme.onSurface.withOpacity(0.08),
                    foregroundColor: AppColors.primary,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      averageMileage > 0 ? averageMileage.toStringAsFixed(1) : '--',
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
                  value: bestMileage > 0 ? bestMileage.toStringAsFixed(1) : '--',
                  hint: bestRecord != null ? dateFormat.format(bestRecord.date) : 'Highway',
                  valueColor: const Color(0xFF22C55E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniCard(
                  label: 'Worst Trip',
                  value: worstMileage > 0 ? worstMileage.toStringAsFixed(1) : '--',
                  hint: worstRecord != null ? dateFormat.format(worstRecord.date) : 'City',
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthlySpending = stats['monthlySpending'] as Map<String, double>;

    if (monthlySpending.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedMonths = monthlySpending.keys.toList()..sort();
    final recentMonths = sortedMonths.length > 5
        ? sortedMonths.sublist(sortedMonths.length - 5)
        : sortedMonths;

    final maxSpending = monthlySpending.values.reduce(math.max);

    return GlassPanel(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Spend',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Text(
                      'This Year',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: recentMonths.map((monthKey) {
                final spending = monthlySpending[monthKey] ?? 0;
                final height = maxSpending > 0 ? (spending / maxSpending) * 120 : 0.0;
                final isPeak = spending == maxSpending;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: height + 8,
                          decoration: BoxDecoration(
                            color: isPeak ? AppColors.primary : AppColors.primary.withOpacity(0.4),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                            boxShadow: isPeak
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 16,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _monthName(monthKey),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isPeak
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface.withOpacity(0.6),
                            fontWeight: isPeak ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Peak month: $currency${maxSpending.toStringAsFixed(0)}',
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
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

class _InsightStrip extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _InsightStrip({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final averageFillCost = stats['averageFillCost'] as double;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.primary.withOpacity(0.08),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.trending_up_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Average fill cost is ${averageFillCost.toStringAsFixed(0)}. Track trends to optimize your spend.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
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
            color: isDark ? AppColors.outlineDark.withOpacity(0.6) : AppColors.outlineLight,
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
    canvas.drawArc(rect, startAngle, sweepAngle * value, false, foregroundPaint);
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
              'Add some fill records to see your statistics',
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
