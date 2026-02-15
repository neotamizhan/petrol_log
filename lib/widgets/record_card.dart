import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/fill_record.dart';
import '../theme/app_theme.dart';
import '../utils/currency_utils.dart';

class RecordCard extends StatelessWidget {
  final FillRecord record;
  final Map<String, dynamic> stats;
  final String currency;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const RecordCard({
    super.key,
    required this.record,
    required this.stats,
    this.currency = '₹',
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    final isFirstRecord = stats['isFirstRecord'] as bool;
    final distanceKm = stats['distanceKm'] as double;
    final fuelLiters = stats['fuelLiters'] as double;
    final mileage = stats['mileage'] as double;
    final daysSinceLastFill = stats['daysSinceLastFill'] as int;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onEdit,
                  child: Column(
                    children: [
                      Container(
                        height: 4,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.accentAmber],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dateFormat.format(record.date),
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        timeFormat.format(record.date),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurface.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.surfaceDarkElevated
                                        : AppColors.backgroundLight,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.outlineDark.withOpacity(0.6)
                                          : AppColors.outlineLight,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.speed_rounded,
                                        size: 16,
                                        color: colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${record.odometerKm.toStringAsFixed(0)} km',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Efficiency',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurface.withOpacity(0.6),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      isFirstRecord
                                          ? '-- km/L'
                                          : '${mileage.toStringAsFixed(1)} km/L',
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: isFirstRecord
                                            ? colorScheme.onSurface.withOpacity(0.4)
                                            : AppColors.primary,
                                      ),
                                    ),
                                    if (!isFirstRecord)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          'Recorded efficiency',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurface.withOpacity(0.5),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Total Cost',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurface.withOpacity(0.6),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '$currency${CurrencyUtils.formatAmount(record.cost, currency)}',
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.accentAmber : colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.symmetric(
                                  horizontal: BorderSide(
                                    color: colorScheme.onSurface.withOpacity(0.08),
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _MetricChip(
                                    icon: Icons.water_drop_rounded,
                                    label: 'Volume',
                                    value: '${fuelLiters.toStringAsFixed(1)} L',
                                  ),
                                  _MetricDivider(color: colorScheme.onSurface.withOpacity(0.08)),
                                  _MetricChip(
                                    icon: Icons.route_rounded,
                                    label: 'Distance',
                                    value: '${distanceKm.toStringAsFixed(0)} km',
                                  ),
                                  _MetricDivider(color: colorScheme.onSurface.withOpacity(0.08)),
                                  _MetricChip(
                                    icon: Icons.calendar_today_rounded,
                                    label: 'Interval',
                                    value: isFirstRecord ? '--' : '$daysSinceLastFill days',
                                  ),
                                ],
                              ),
                            ),
                            if (record.notes.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.surfaceDarkElevated
                                      : AppColors.backgroundLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.note_rounded,
                                      size: 16,
                                      color: colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        record.notes,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurface.withOpacity(0.7),
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (isFirstRecord) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'First record - stats on next fill',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  onPressed: onEdit,
                                  icon: const Icon(Icons.edit_rounded, size: 20),
                                  color: AppColors.primary,
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppColors.primary.withOpacity(0.12),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => _showDeleteDialog(context),
                                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                                  color: colorScheme.error,
                                  style: IconButton.styleFrom(
                                    backgroundColor: colorScheme.error.withOpacity(0.12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to delete this fill record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onDelete?.call();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MetricDivider extends StatelessWidget {
  final Color color;

  const _MetricDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      width: 1,
      color: color,
    );
  }
}
