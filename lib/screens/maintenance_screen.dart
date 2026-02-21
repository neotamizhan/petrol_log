import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/maintenance_record.dart';
import '../models/vehicle.dart';
import '../providers/records_provider.dart';
import '../theme/app_theme.dart';
import '../utils/currency_utils.dart';
import 'add_maintenance_screen.dart';
import 'add_vehicle_screen.dart';

class MaintenanceScreen extends StatefulWidget {
  final String? initialVehicleId;

  const MaintenanceScreen({super.key, this.initialVehicleId});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  String _selectedVehicleId = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final provider = context.read<RecordsProvider>();
      setState(() {
        _selectedVehicleId =
            widget.initialVehicleId ?? provider.selectedVehicleId;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasVehicles = context.select<RecordsProvider, bool>(
      (provider) => provider.activeVehicles.isNotEmpty,
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : null,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Service & Maintenance'),
      ),
      body: Consumer<RecordsProvider>(
        builder: (context, provider, child) {
          final vehicles = provider.activeVehicles;
          if (vehicles.isEmpty) {
            return _NoVehicleState(
              onAddVehicle: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddVehicleScreen(),
                  ),
                );
              },
            );
          }

          final resolvedVehicleId = vehicles.any(
            (vehicle) => vehicle.id == _selectedVehicleId,
          )
              ? _selectedVehicleId
              : vehicles.first.id;
          if (resolvedVehicleId != _selectedVehicleId) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) {
                return;
              }
              setState(() => _selectedVehicleId = resolvedVehicleId);
            });
          }

          final records =
              provider.getMaintenanceRecordsForVehicle(resolvedVehicleId);
          final overview =
              provider.getMaintenanceOverview(vehicleId: resolvedVehicleId);
          final dueItems = (overview['dueItems'] as List<dynamic>)
              .cast<Map<String, dynamic>>();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              _VehicleFilter(
                selectedVehicleId: resolvedVehicleId,
                vehicles: vehicles,
                onChanged: (value) {
                  setState(() => _selectedVehicleId = value);
                },
              ),
              const SizedBox(height: 12),
              _MaintenanceSummaryCard(
                overview: overview,
                dueItems: dueItems,
              ),
              const SizedBox(height: 16),
              if (records.isEmpty)
                const _EmptyState()
              else
                ...records.map((record) {
                  final dueStatus = provider.getMaintenanceDueStatus(record);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MaintenanceCard(
                      record: record,
                      dueStatus: dueStatus,
                      currency: provider.currency,
                      onEdit: () => _openEditor(context, record: record),
                      onDelete: () => _confirmDelete(context, record),
                    ),
                  );
                }),
            ],
          );
        },
      ),
      floatingActionButton: hasVehicles
          ? FloatingActionButton.extended(
              onPressed: () => _openEditor(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Service'),
            )
          : null,
    );
  }

  Future<void> _openEditor(
    BuildContext context, {
    MaintenanceRecord? record,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddMaintenanceScreen(record: record),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    MaintenanceRecord record,
  ) async {
    final provider = context.read<RecordsProvider>();
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service Entry?'),
        content:
            Text('Delete "${record.serviceType}" from maintenance history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    await provider.deleteMaintenanceRecord(record.id);

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(this.context).showSnackBar(
      const SnackBar(
        content: Text('Service entry deleted'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _VehicleFilter extends StatelessWidget {
  final String selectedVehicleId;
  final List<Vehicle> vehicles;
  final ValueChanged<String> onChanged;

  const _VehicleFilter({
    required this.selectedVehicleId,
    required this.vehicles,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_car_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedVehicleId,
                isExpanded: true,
                items: vehicles.map((vehicle) {
                  final label = vehicle.plateNumber != null
                      ? '${vehicle.name} • ${vehicle.plateNumber}'
                      : vehicle.name;
                  return DropdownMenuItem<String>(
                    value: vehicle.id,
                    child: Text(label),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    onChanged(value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceSummaryCard extends StatelessWidget {
  final Map<String, dynamic> overview;
  final List<Map<String, dynamic>> dueItems;

  const _MaintenanceSummaryCard({
    required this.overview,
    required this.dueItems,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overdueCount = overview['overdueCount'] as int;
    final dueSoonCount = overview['dueSoonCount'] as int;
    final onTrackCount = overview['onTrackCount'] as int;
    final scheduledItems = overview['scheduledItems'] as int;
    final statusLabel = overdueCount > 0
        ? 'Needs Attention'
        : dueSoonCount > 0
            ? 'Upcoming Services'
            : 'All Clear';
    final statusColor = overdueCount > 0
        ? const Color(0xFFEF4444)
        : dueSoonCount > 0
            ? AppColors.accentAmber
            : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(0.22),
            statusColor.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.build_rounded,
                  color: statusColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                statusLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryChip(
                label: 'Scheduled',
                value: scheduledItems.toString(),
              ),
              _SummaryChip(
                label: 'Overdue',
                value: overdueCount.toString(),
              ),
              _SummaryChip(
                label: 'Due Soon',
                value: dueSoonCount.toString(),
              ),
              _SummaryChip(
                label: 'On Track',
                value: onTrackCount.toString(),
              ),
            ],
          ),
          if (dueItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _dueMessage(dueItems),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.75),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _dueMessage(List<Map<String, dynamic>> dueItems) {
    final first = dueItems.first;
    final record = first['record'] as MaintenanceRecord;
    final dueStatus = first['dueStatus'] as Map<String, dynamic>;
    final status = dueStatus['status'] as String;
    final suffix =
        dueItems.length > 1 ? ' and ${dueItems.length - 1} more' : '';
    if (status == 'overdue') {
      return '${record.serviceType} is overdue$suffix.';
    }
    return '${record.serviceType} is due soon$suffix.';
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryChip({
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

class _MaintenanceCard extends StatelessWidget {
  final MaintenanceRecord record;
  final Map<String, dynamic> dueStatus;
  final String currency;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MaintenanceCard({
    required this.record,
    required this.dueStatus,
    required this.currency,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateFormat = DateFormat('MMM dd, yyyy');

    final status = dueStatus['status'] as String;
    final color = _statusColor(status);
    final label = _statusLabel(status);
    final nextDueDate = record.nextDueDate;
    final nextDueOdometer = record.nextDueOdometerKm;
    final daysRemaining = dueStatus['daysRemaining'] as int?;
    final kmRemaining = dueStatus['kmRemaining'] as double?;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                        record.serviceType,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(record.serviceDate),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetaLine(
                    icon: Icons.speed_rounded,
                    text: '${record.odometerKm.toStringAsFixed(0)} km',
                  ),
                ),
                Expanded(
                  child: _MetaLine(
                    icon: Icons.payments_rounded,
                    text: record.cost > 0
                        ? '$currency${CurrencyUtils.formatAmount(record.cost, currency)}'
                        : '--',
                  ),
                ),
              ],
            ),
            if (nextDueDate != null || nextDueOdometer != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDarkElevated
                      : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (nextDueDate != null)
                      Text(
                        'Due date: ${dateFormat.format(nextDueDate)}'
                        '${daysRemaining == null ? '' : ' (${_daysText(daysRemaining)})'}',
                        style: theme.textTheme.bodySmall,
                      ),
                    if (nextDueOdometer != null)
                      Text(
                        'Due odometer: ${nextDueOdometer.toStringAsFixed(0)} km'
                        '${kmRemaining == null ? '' : ' (${_kmText(kmRemaining)})'}',
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
            if (record.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                record.notes,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.75),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'overdue':
        return 'Overdue';
      case 'due_soon':
        return 'Due Soon';
      case 'on_track':
        return 'On Track';
      default:
        return 'Completed';
    }
  }

  Color _statusColor(String status) {
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

  String _daysText(int daysRemaining) {
    if (daysRemaining < 0) {
      return '${daysRemaining.abs()}d overdue';
    }
    if (daysRemaining == 0) {
      return 'due today';
    }
    return '$daysRemaining d left';
  }

  String _kmText(double kmRemaining) {
    if (kmRemaining < 0) {
      return '${kmRemaining.abs().toStringAsFixed(0)} km overdue';
    }
    if (kmRemaining == 0) {
      return 'due now';
    }
    return '${kmRemaining.toStringAsFixed(0)} km left';
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaLine({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _NoVehicleState extends StatelessWidget {
  final VoidCallback onAddVehicle;

  const _NoVehicleState({required this.onAddVehicle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 88,
              width: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.directions_car_rounded,
                color: AppColors.primary,
                size: 44,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add a vehicle first',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Maintenance entries are linked to a specific vehicle.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.65),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAddVehicle,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Vehicle'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? AppColors.surfaceDark
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? AppColors.outlineDark
              : AppColors.outlineLight,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.build_circle_outlined,
            color: AppColors.primary.withOpacity(0.6),
            size: 44,
          ),
          const SizedBox(height: 10),
          Text(
            'No maintenance records yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "Add Service" to log your first maintenance activity.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }
}
