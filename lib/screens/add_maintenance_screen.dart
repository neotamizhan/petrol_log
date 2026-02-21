import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/maintenance_record.dart';
import '../providers/records_provider.dart';
import '../theme/app_theme.dart';
import '../utils/currency_utils.dart';

const List<Map<String, String>> _maintenanceCategories = [
  {'id': 'general', 'label': 'General Service'},
  {'id': 'oil_change', 'label': 'Oil Change'},
  {'id': 'tire', 'label': 'Tire / Wheel'},
  {'id': 'brake', 'label': 'Brake Service'},
  {'id': 'battery', 'label': 'Battery'},
  {'id': 'engine', 'label': 'Engine'},
  {'id': 'insurance', 'label': 'Insurance / Registration'},
  {'id': 'other', 'label': 'Other'},
];

class AddMaintenanceScreen extends StatefulWidget {
  final MaintenanceRecord? record;

  const AddMaintenanceScreen({super.key, this.record});

  bool get isEditing => record != null;

  @override
  State<AddMaintenanceScreen> createState() => _AddMaintenanceScreenState();
}

class _AddMaintenanceScreenState extends State<AddMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serviceTypeController = TextEditingController();
  final _odometerController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();
  final _nextDueOdometerController = TextEditingController();

  DateTime _serviceDate = DateTime.now();
  DateTime? _nextDueDate;
  String _selectedVehicleId = '';
  String _selectedCategory = _maintenanceCategories.first['id']!;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.record;
    if (existing != null) {
      _serviceTypeController.text = existing.serviceType;
      _odometerController.text = existing.odometerKm.toStringAsFixed(0);
      _costController.text = existing.cost > 0 ? existing.cost.toString() : '';
      _notesController.text = existing.notes;
      _serviceDate = existing.serviceDate;
      _nextDueDate = existing.nextDueDate;
      _selectedVehicleId = existing.vehicleId;
      _selectedCategory = existing.category;
      if (existing.nextDueOdometerKm != null) {
        _nextDueOdometerController.text =
            existing.nextDueOdometerKm!.toStringAsFixed(0);
      }
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        final provider = context.read<RecordsProvider>();
        setState(() {
          _selectedVehicleId = provider.selectedVehicleId;
        });
      });
    }
  }

  @override
  void dispose() {
    _serviceTypeController.dispose();
    _odometerController.dispose();
    _costController.dispose();
    _notesController.dispose();
    _nextDueOdometerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : null,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.isEditing ? 'Edit Service' : 'Add Service'),
      ),
      body: Consumer<RecordsProvider>(
        builder: (context, provider, child) {
          final vehicles = provider.activeVehicles;
          final selectedVehicleId = _selectedVehicleId.isNotEmpty
              ? _selectedVehicleId
              : provider.selectedVehicleId;
          final canSelectVehicle =
              vehicles.any((vehicle) => vehicle.id == selectedVehicleId);
          final dropdownValue = canSelectVehicle && vehicles.isNotEmpty
              ? selectedVehicleId
              : (vehicles.isNotEmpty ? vehicles.first.id : '');
          final selectedCategory = _maintenanceCategories.any(
            (category) => category['id'] == _selectedCategory,
          )
              ? _selectedCategory
              : _maintenanceCategories.first['id']!;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: [
                _Panel(
                  title: 'Service Details',
                  icon: Icons.build_circle_rounded,
                  child: Column(
                    children: [
                      if (vehicles.isNotEmpty) ...[
                        _LabeledField(
                          label: 'Vehicle',
                          child: DropdownButtonFormField<String>(
                            initialValue: dropdownValue,
                            decoration: _inputDecoration(
                              theme,
                              isDark,
                              hintText: 'Select vehicle',
                            ),
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
                              if (value == null) {
                                return;
                              }
                              setState(() => _selectedVehicleId = value);
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      _LabeledField(
                        label: 'Service Type',
                        child: TextFormField(
                          controller: _serviceTypeController,
                          decoration: _inputDecoration(
                            theme,
                            isDark,
                            hintText: 'Oil Change',
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter a service type';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      _LabeledField(
                        label: 'Category',
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedCategory,
                          decoration: _inputDecoration(
                            theme,
                            isDark,
                            hintText: 'Select category',
                          ),
                          items: _maintenanceCategories.map((category) {
                            return DropdownMenuItem<String>(
                              value: category['id'],
                              child: Text(category['label']!),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() => _selectedCategory = value);
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      _TapField(
                        icon: Icons.calendar_month_rounded,
                        label: 'Service Date',
                        value: dateFormat.format(_serviceDate),
                        onTap: _pickServiceDate,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _Panel(
                  title: 'Odometer & Cost',
                  icon: Icons.speed_rounded,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _LabeledField(
                              label: 'Odometer',
                              child: TextFormField(
                                controller: _odometerController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d*')),
                                ],
                                decoration: _inputDecoration(
                                  theme,
                                  isDark,
                                  hintText: '0',
                                  suffixText: 'km',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Enter odometer';
                                  }
                                  final odometer = double.tryParse(value);
                                  if (odometer == null || odometer < 0) {
                                    return 'Enter valid odometer';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _LabeledField(
                              label: 'Cost (Optional)',
                              child: TextFormField(
                                controller: _costController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(CurrencyUtils.getInputPattern(
                                        provider.currency)),
                                  ),
                                ],
                                decoration: _inputDecoration(
                                  theme,
                                  isDark,
                                  hintText: CurrencyUtils.getPlaceholder(
                                      provider.currency),
                                  prefixText: '${provider.currency} ',
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return null;
                                  }
                                  final parsed = double.tryParse(
                                    value.replaceAll(',', '').trim(),
                                  );
                                  if (parsed == null || parsed < 0) {
                                    return 'Enter valid cost';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _Panel(
                  title: 'Next Due (Optional)',
                  icon: Icons.schedule_rounded,
                  child: Column(
                    children: [
                      _LabeledField(
                        label: 'Due Odometer',
                        child: TextFormField(
                          controller: _nextDueOdometerController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*')),
                          ],
                          decoration: _inputDecoration(
                            theme,
                            isDark,
                            hintText: 'e.g. 5000 km after service',
                            suffixText: 'km',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return null;
                            }
                            final dueOdometer = double.tryParse(value.trim());
                            if (dueOdometer == null || dueOdometer <= 0) {
                              return 'Enter valid due odometer';
                            }
                            final serviceOdometer =
                                double.tryParse(_odometerController.text);
                            if (serviceOdometer != null &&
                                dueOdometer <= serviceOdometer) {
                              return 'Must be greater than service odometer';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      _TapField(
                        icon: Icons.event_repeat_rounded,
                        label: 'Due Date',
                        value: _nextDueDate == null
                            ? 'Not set'
                            : dateFormat.format(_nextDueDate!),
                        onTap: _pickDueDate,
                        trailing: _nextDueDate == null
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () {
                                  setState(() => _nextDueDate = null);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _Panel(
                  title: 'Notes',
                  icon: Icons.note_alt_rounded,
                  child: TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _inputDecoration(
                      theme,
                      isDark,
                      hintText: 'Parts replaced, workshop, remarks...',
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
              ),
            ),
          ),
          child: FilledButton(
            onPressed: _isSaving ? null : _save,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.isEditing ? 'Save Changes' : 'Add Service'),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    ThemeData theme,
    bool isDark, {
    String? hintText,
    String? prefixText,
    String? suffixText,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixText: prefixText,
      suffixText: suffixText,
      filled: true,
      fillColor:
          isDark ? AppColors.surfaceDarkElevated : AppColors.backgroundLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.6,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.colorScheme.error,
          width: 1.6,
        ),
      ),
    );
  }

  Future<void> _pickServiceDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _serviceDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _serviceDate = picked;
        if (_nextDueDate != null && !_nextDueDate!.isAfter(_serviceDate)) {
          _nextDueDate = null;
        }
      });
    }
  }

  Future<void> _pickDueDate() async {
    final initial = _nextDueDate ?? _serviceDate.add(const Duration(days: 90));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(DateTime.now()) ? initial : DateTime.now(),
      firstDate: _serviceDate.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _nextDueDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final dueDate = _nextDueDate;
    if (dueDate != null && !dueDate.isAfter(_serviceDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Due date must be after service date'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final provider = context.read<RecordsProvider>();
      final vehicleId = _selectedVehicleId.isNotEmpty
          ? _selectedVehicleId
          : provider.selectedVehicleId;
      final now = DateTime.now();
      final maintenanceId = widget.record?.id ??
          'maint_${now.microsecondsSinceEpoch}_${Random().nextInt(9999)}';
      final serviceDate = DateTime(
        _serviceDate.year,
        _serviceDate.month,
        _serviceDate.day,
        now.hour,
        now.minute,
      );
      final dueOdometerText = _nextDueOdometerController.text.trim();
      final nextDueOdometer = dueOdometerText.isEmpty
          ? null
          : double.parse(dueOdometerText.replaceAll(',', ''));
      final costText = _costController.text.trim();
      final parsedCost =
          costText.isEmpty ? 0.0 : double.parse(costText.replaceAll(',', ''));

      final base = widget.record;
      final maintenanceRecord = base == null
          ? MaintenanceRecord(
              id: maintenanceId,
              vehicleId: vehicleId,
              serviceType: _serviceTypeController.text.trim(),
              category: _selectedCategory,
              serviceDate: serviceDate,
              odometerKm: double.parse(_odometerController.text.trim()),
              cost: parsedCost,
              notes: _notesController.text.trim(),
              nextDueOdometerKm: nextDueOdometer,
              nextDueDate: dueDate == null
                  ? null
                  : DateTime(dueDate.year, dueDate.month, dueDate.day),
              createdAt: now,
            )
          : base.copyWith(
              vehicleId: vehicleId,
              serviceType: _serviceTypeController.text.trim(),
              category: _selectedCategory,
              serviceDate: serviceDate,
              odometerKm: double.parse(_odometerController.text.trim()),
              cost: parsedCost,
              notes: _notesController.text.trim(),
              nextDueOdometerKm: nextDueOdometer,
              nextDueDate: dueDate == null
                  ? null
                  : DateTime(dueDate.year, dueDate.month, dueDate.day),
              clearNextDueOdometerKm: nextDueOdometer == null,
              clearNextDueDate: dueDate == null,
            );

      if (widget.isEditing) {
        await provider.updateMaintenanceRecord(maintenanceRecord);
      } else {
        await provider.addMaintenanceRecord(maintenanceRecord);
      }
      await provider.setSelectedVehicle(vehicleId);

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEditing
              ? 'Service entry updated'
              : 'Service entry added'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save service: $error'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Panel({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _TapField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final Widget? trailing;

  const _TapField({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceDarkElevated
                  : AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
