import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vehicle.dart';
import '../providers/records_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_panel.dart';
import 'add_vehicle_screen.dart';
import 'edit_vehicle_screen.dart';

class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : null,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('My Vehicles'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddVehicleScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Vehicle'),
      ),
      body: Consumer<RecordsProvider>(
        builder: (context, provider, child) {
          final vehicles = provider.vehicles;

          if (vehicles.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicles[index];
              final fillRecordCount =
                  provider.getRecordsForVehicle(vehicle.id).length;
              final maintenanceRecordCount =
                  provider.getMaintenanceRecordsForVehicle(vehicle.id).length;
              final hasRecords = provider.hasRecordsForVehicle(vehicle.id);
              final isSelected = vehicle.id == provider.selectedVehicleId;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _VehicleCard(
                  vehicle: vehicle,
                  fillRecordCount: fillRecordCount,
                  maintenanceRecordCount: maintenanceRecordCount,
                  hasRecords: hasRecords,
                  isSelected: isSelected,
                  isDark: isDark,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.directions_car_rounded,
                size: 60,
                color: AppColors.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Vehicles Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add your first vehicle to start tracking fuel records',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddVehicleScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Your First Vehicle'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final int fillRecordCount;
  final int maintenanceRecordCount;
  final bool hasRecords;
  final bool isSelected;
  final bool isDark;

  const _VehicleCard({
    required this.vehicle,
    required this.fillRecordCount,
    required this.maintenanceRecordCount,
    required this.hasRecords,
    required this.isSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.read<RecordsProvider>();

    final displayName = vehicle.name;
    final makeModel =
        [vehicle.make, vehicle.model].where((s) => s.isNotEmpty).join(' • ');
    final hasDetails = makeModel.isNotEmpty || vehicle.plateNumber != null;

    return GlassPanel(
      color: isSelected
          ? (isDark
              ? AppColors.primary.withOpacity(0.15)
              : AppColors.primary.withOpacity(0.08))
          : (isDark ? AppColors.settingsCardDark.withOpacity(0.92) : null),
      border: Border.all(
        color: isSelected
            ? AppColors.primary.withOpacity(0.5)
            : (isDark
                ? AppColors.primary.withOpacity(0.25)
                : AppColors.outlineLight),
        width: isSelected ? 2 : 1,
      ),
      boxShadow: isDark
          ? [
              BoxShadow(
                color: AppColors.primary.withOpacity(isSelected ? 0.25 : 0.15),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ]
          : null,
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: (vehicle.active
                          ? AppColors.primary
                          : colorScheme.onSurface)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.directions_car_rounded,
                  color: vehicle.active
                      ? AppColors.primary
                      : colorScheme.onSurface.withOpacity(0.5),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (vehicle.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'DEFAULT',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                        if (!vehicle.active) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.onSurface.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'INACTIVE',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.5),
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (hasDetails) ...[
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (makeModel.isNotEmpty) makeModel,
                          if (vehicle.plateNumber != null) vehicle.plateNumber,
                        ].join(' • '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceDarkElevated.withOpacity(0.5)
                  : AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoItem(
                  icon: Icons.speed_rounded,
                  label: 'Odometer',
                  value: '${vehicle.currentOdometer.toStringAsFixed(0)} km',
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: colorScheme.onSurface.withOpacity(0.1),
                ),
                _InfoItem(
                  icon: Icons.local_gas_station_rounded,
                  label: 'Fill Records',
                  value: fillRecordCount.toString(),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: colorScheme.onSurface.withOpacity(0.1),
                ),
                _InfoItem(
                  icon: Icons.build_rounded,
                  label: 'Services',
                  value: maintenanceRecordCount.toString(),
                ),
              ],
            ),
          ),
          if (vehicle.active) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (!isSelected)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        provider.setSelectedVehicle(vehicle.id);
                      },
                      icon: const Icon(Icons.check_circle_outline_rounded,
                          size: 18),
                      label: const Text('Select'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                if (!isSelected) const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditVehicleScreen(vehicle: vehicle),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _confirmDelete(context, vehicle, hasRecords),
                    icon: const Icon(Icons.delete_rounded, size: 18),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Vehicle vehicle, bool hasRecords) {
    final theme = Theme.of(context);
    final provider = context.read<RecordsProvider>();
    final fillRecords = provider.getRecordsForVehicle(vehicle.id).length;
    final maintenanceRecords =
        provider.getMaintenanceRecordsForVehicle(vehicle.id).length;
    final totalRecords = fillRecords + maintenanceRecords;
    final historyDescription = [
      if (fillRecords > 0) '$fillRecords fuel',
      if (maintenanceRecords > 0) '$maintenanceRecords maintenance',
    ].join(' + ');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${vehicle.name}?'),
        content: Text(
          hasRecords
              ? 'This vehicle has $totalRecords log entries ($historyDescription). It will be marked as inactive instead of being permanently deleted.'
              : 'This vehicle has no associated records and will be permanently deleted. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              provider.deleteVehicle(vehicle.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    hasRecords
                        ? '${vehicle.name} marked as inactive'
                        : '${vehicle.name} deleted',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primary,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
