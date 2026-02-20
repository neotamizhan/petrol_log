import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/vehicle.dart';
import '../providers/records_provider.dart';
import '../theme/app_theme.dart';

class EditVehicleScreen extends StatefulWidget {
  final Vehicle vehicle;

  const EditVehicleScreen({
    super.key,
    required this.vehicle,
  });

  @override
  State<EditVehicleScreen> createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends State<EditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _plateController = TextEditingController();
  final _odometerController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.vehicle.name;
    _makeController.text = widget.vehicle.make;
    _modelController.text = widget.vehicle.model;
    if (widget.vehicle.year != null) {
      _yearController.text = widget.vehicle.year.toString();
    }
    if (widget.vehicle.plateNumber != null) {
      _plateController.text = widget.vehicle.plateNumber!;
    }
    _odometerController.text = widget.vehicle.currentOdometer.toStringAsFixed(0);
  }

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

      // Check if name is unique (excluding current vehicle)
      final existingNames = provider.vehicles
          .where((v) => v.id != widget.vehicle.id)
          .map((v) => v.name.toLowerCase())
          .toList();
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

      final updatedVehicle = widget.vehicle.copyWith(
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
      );

      await provider.updateVehicle(updatedVehicle);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${updatedVehicle.name} updated successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating vehicle: $e'),
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
    final provider = context.read<RecordsProvider>();
    final highestOdometer = provider.getHighestOdometerForVehicle(widget.vehicle.id);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : null,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Edit Vehicle'),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
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
                      if (odometer < highestOdometer) {
                        return 'Odometer cannot be less than the highest recorded value ($highestOdometer km)';
                      }
                      return null;
                    },
                  ),
                  if (highestOdometer > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accentAmber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.accentAmber.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: AppColors.accentAmber,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Highest recorded odometer: ${highestOdometer.toStringAsFixed(0)} km',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.accentAmber,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
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
                : const Text('Save Changes'),
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
