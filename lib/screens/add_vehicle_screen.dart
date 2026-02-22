import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/vehicle.dart';
import '../providers/records_provider.dart';
import '../theme/app_theme.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _plateController = TextEditingController();
  final _odometerController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final provider = context.read<RecordsProvider>();

      // Check if name is unique
      final existingNames = provider.vehicles.map((v) => v.name.toLowerCase()).toList();
      if (existingNames.contains(_nameController.text.trim().toLowerCase())) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A vehicle with this name already exists'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() => _isSaving = false);
        return;
      }

      final vehicleId = 'vehicle_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
      final vehicle = Vehicle(
        id: vehicleId,
        name: _nameController.text.trim(),
        make: _makeController.text.trim(),
        model: _modelController.text.trim(),
        year: _yearController.text.trim().isNotEmpty
            ? int.tryParse(_yearController.text.trim())
            : null,
        plateNumber: _plateController.text.trim().isNotEmpty
            ? _plateController.text.trim()
            : null,
        currentOdometer: double.parse(_odometerController.text),
        active: true,
        createdAt: DateTime.now(),
      );

      await provider.addVehicle(vehicle);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${vehicle.name} added successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding vehicle: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : null,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Add Vehicle'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            _InputCard(
              label: 'Vehicle Name',
              icon: Icons.directions_car_rounded,
              required: true,
              child: TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'e.g., My Honda Civic',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.surfaceDarkElevated
                      : AppColors.backgroundLight,
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a vehicle name';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            _InputCard(
              label: 'Make',
              icon: Icons.factory_rounded,
              child: TextFormField(
                controller: _makeController,
                decoration: InputDecoration(
                  hintText: 'e.g., Honda',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.surfaceDarkElevated
                      : AppColors.backgroundLight,
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ),
            const SizedBox(height: 16),
            _InputCard(
              label: 'Model',
              icon: Icons.info_outline_rounded,
              child: TextFormField(
                controller: _modelController,
                decoration: InputDecoration(
                  hintText: 'e.g., Civic',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.surfaceDarkElevated
                      : AppColors.backgroundLight,
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ),
            const SizedBox(height: 16),
            _InputCard(
              label: 'Year',
              icon: Icons.calendar_today_rounded,
              child: TextFormField(
                controller: _yearController,
                decoration: InputDecoration(
                  hintText: 'e.g., 2020',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.surfaceDarkElevated
                      : AppColors.backgroundLight,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final year = int.tryParse(value);
                    if (year == null || year < 1900 || year > DateTime.now().year + 1) {
                      return 'Please enter a valid year';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            _InputCard(
              label: 'License Plate',
              icon: Icons.badge_rounded,
              child: TextFormField(
                controller: _plateController,
                decoration: InputDecoration(
                  hintText: 'e.g., ABC-1234',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.surfaceDarkElevated
                      : AppColors.backgroundLight,
                ),
                textCapitalization: TextCapitalization.characters,
              ),
            ),
            const SizedBox(height: 16),
            _InputCard(
              label: 'Current Odometer (km)',
              icon: Icons.speed_rounded,
              required: true,
              child: TextFormField(
                controller: _odometerController,
                decoration: InputDecoration(
                  hintText: 'e.g., 45230',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.surfaceDarkElevated
                      : AppColors.backgroundLight,
                  suffixText: 'km',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the current odometer reading';
                  }
                  final odometer = double.tryParse(value);
                  if (odometer == null || odometer < 0) {
                    return 'Please enter a valid odometer reading';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
            ),
          ),
        ),
        child: SafeArea(
          child: FilledButton(
            onPressed: _isSaving ? null : _saveVehicle,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Add Vehicle'),
          ),
        ),
      ),
    ),
  );
  }
}

class _InputCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget child;
  final bool required;

  const _InputCard({
    required this.label,
    required this.icon,
    required this.child,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (required) ...[
                const SizedBox(width: 4),
                Text(
                  '*',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
