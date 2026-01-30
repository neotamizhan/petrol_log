import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/records_provider.dart';
import '../models/fill_record.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: Consumer<RecordsProvider>(
        builder: (context, provider, child) {
          final stats = provider.getOverallStats();
          final totalRecords = stats['totalRecords'] as int;

          if (totalRecords == 0) {
            return _EmptyState(colorScheme: colorScheme);
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Overview Cards
              _buildOverviewSection(context, stats, colorScheme),
              
              const SizedBox(height: 24),

              // Mileage Section
              _buildMileageSection(context, stats, colorScheme, provider),
              
              const SizedBox(height: 24),

              // Spending Section
              _buildSpendingSection(context, stats, colorScheme),
              
              const SizedBox(height: 24),

              // Fill Pattern Section
              _buildFillPatternSection(context, stats, colorScheme),
              
              const SizedBox(height: 24),

              // Monthly Trend
              _buildMonthlyTrendSection(context, stats, colorScheme),
              
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewSection(BuildContext context, Map<String, dynamic> stats, ColorScheme colorScheme) {
    final theme = Theme.of(context);
    final totalRecords = stats['totalRecords'] as int;
    final totalDistance = stats['totalDistance'] as double;
    final totalFuelLiters = stats['totalFuelLiters'] as double;
    final totalDays = stats['totalDays'] as int;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.analytics_rounded,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Overview',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.local_gas_station_rounded,
                  label: 'Total Fills',
                  value: totalRecords.toString(),
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  icon: Icons.route_rounded,
                  label: 'Distance',
                  value: '${(totalDistance / 1000).toStringAsFixed(1)}k km',
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.water_drop_rounded,
                  label: 'Fuel Used',
                  value: '${totalFuelLiters.toStringAsFixed(0)} L',
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  icon: Icons.calendar_month_rounded,
                  label: 'Duration',
                  value: '$totalDays days',
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMileageSection(BuildContext context, Map<String, dynamic> stats, ColorScheme colorScheme, RecordsProvider provider) {
    final theme = Theme.of(context);
    final averageMileage = stats['averageMileage'] as double;
    final bestMileage = stats['bestMileage'] as double;
    final worstMileage = stats['worstMileage'] as double;
    final bestRecord = stats['bestMileageRecord'] as FillRecord?;
    final worstRecord = stats['worstMileageRecord'] as FillRecord?;
    final dateFormat = DateFormat('dd MMM');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speed_rounded, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Mileage Analysis',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Average Mileage - Featured
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withOpacity(0.1),
                  colorScheme.primary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.trending_up_rounded, color: colorScheme.primary, size: 32),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Average Mileage',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      '${averageMileage.toStringAsFixed(1)} km/L',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Best & Worst
          Row(
            children: [
              Expanded(
                child: _MileageCard(
                  label: 'Best',
                  mileage: bestMileage,
                  date: bestRecord != null ? dateFormat.format(bestRecord.date) : '-',
                  icon: Icons.emoji_events_rounded,
                  iconColor: Colors.amber,
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MileageCard(
                  label: 'Worst',
                  mileage: worstMileage,
                  date: worstRecord != null ? dateFormat.format(worstRecord.date) : '-',
                  icon: Icons.warning_amber_rounded,
                  iconColor: colorScheme.error,
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingSection(BuildContext context, Map<String, dynamic> stats, ColorScheme colorScheme) {
    final theme = Theme.of(context);
    final totalSpent = stats['totalSpent'] as double;
    final averageFillCost = stats['averageFillCost'] as double;
    final provider = context.read<RecordsProvider>();
    final fuelPrice = provider.fuelPricePerLiter;
    final currency = provider.currency;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.currency_rupee_rounded, color: colorScheme.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Spending',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _SpendingTile(
                  label: 'Total Spent',
                  value: '$currency${_formatCurrency(totalSpent)}',
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SpendingTile(
                  label: 'Avg per Fill',
                  value: '$currency${averageFillCost.toStringAsFixed(0)}',
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: colorScheme.onSurface.withOpacity(0.5)),
                const SizedBox(width: 8),
                Text(
                  'Current fuel price: $currency${fuelPrice.toStringAsFixed(2)}/L',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFillPatternSection(BuildContext context, Map<String, dynamic> stats, ColorScheme colorScheme) {
    final theme = Theme.of(context);
    final avgDays = stats['averageDaysBetweenFills'] as double;
    final firstDate = stats['firstFillDate'] as DateTime?;
    final lastDate = stats['lastFillDate'] as DateTime?;
    final dateFormat = DateFormat('dd MMM yyyy');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, color: colorScheme.tertiary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Fill Pattern',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.tertiary.withOpacity(0.1),
                  colorScheme.tertiary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.repeat_rounded, color: colorScheme.tertiary, size: 32),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Average Fill Interval',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      '${avgDays.toStringAsFixed(0)} days',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Icon(Icons.history_rounded, size: 16, color: colorScheme.onSurface.withOpacity(0.5)),
              const SizedBox(width: 8),
              Text(
                firstDate != null && lastDate != null
                    ? 'From ${dateFormat.format(firstDate)} to ${dateFormat.format(lastDate)}'
                    : 'No date range available',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrendSection(BuildContext context, Map<String, dynamic> stats, ColorScheme colorScheme) {
    final theme = Theme.of(context);
    final monthlySpending = stats['monthlySpending'] as Map<String, double>;
    final currency = context.read<RecordsProvider>().currency;
    
    if (monthlySpending.isEmpty) return const SizedBox.shrink();

    final sortedMonths = monthlySpending.keys.toList()..sort();
    final recentMonths = sortedMonths.length > 6 
        ? sortedMonths.sublist(sortedMonths.length - 6) 
        : sortedMonths;
    
    final maxSpending = monthlySpending.values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Monthly Spending',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: recentMonths.map((month) {
                final spending = monthlySpending[month] ?? 0;
                final height = maxSpending > 0 ? (spending / maxSpending) * 80 : 0.0;
                final monthLabel = month.substring(5); // Get MM part
                
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '$currency${(spending / 1000).toStringAsFixed(1)}k',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: height + 8,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                colorScheme.primary,
                                colorScheme.primary.withOpacity(0.6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getMonthName(int.parse(monthLabel)),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}k';
    }
    return amount.toStringAsFixed(0);
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
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
                color: colorScheme.primaryContainer.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.analytics_outlined,
                size: 64,
                color: colorScheme.primary,
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

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onPrimaryContainer.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _MileageCard extends StatelessWidget {
  final String label;
  final double mileage;
  final String date;
  final IconData icon;
  final Color iconColor;
  final ColorScheme colorScheme;

  const _MileageCard({
    required this.label,
    required this.mileage,
    required this.date,
    required this.icon,
    required this.iconColor,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            mileage > 0 ? '${mileage.toStringAsFixed(1)} km/L' : '-',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            date,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpendingTile extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme colorScheme;

  const _SpendingTile({
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
