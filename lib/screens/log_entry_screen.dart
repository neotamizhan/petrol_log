import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/fill_record.dart';
import '../models/maintenance_record.dart';
import '../providers/records_provider.dart';
import '../theme/app_theme.dart';
import '../utils/currency_utils.dart';
import 'add_vehicle_screen.dart';

/// What kind of activity is being logged.
enum LogMode { fuel, service }

/// Service categories (shared with the maintenance views).
const List<Map<String, String>> kMaintenanceCategories = [
  {'id': 'general', 'label': 'General Service'},
  {'id': 'oil_change', 'label': 'Oil Change'},
  {'id': 'tire', 'label': 'Tire / Wheel'},
  {'id': 'brake', 'label': 'Brake Service'},
  {'id': 'battery', 'label': 'Battery'},
  {'id': 'engine', 'label': 'Engine'},
  {'id': 'insurance', 'label': 'Insurance / Registration'},
  {'id': 'other', 'label': 'Other'},
];

/// Starter service types offered as quick-pick chips (plus free text).
const List<String> kServiceTypePresets = [
  'Oil Change',
  'Tire Rotation',
  'Tire Replacement',
  'Brake Service',
  'Battery',
  'Air Filter',
  'Inspection',
  'Insurance',
  'Registration',
  'General Service',
];

/// Unified "Log" screen: records a fuel fill or a service entry, in create or
/// edit mode. Replaces the separate add-fuel, edit-fuel, and add/edit-service
/// screens.
class LogEntryScreen extends StatefulWidget {
  final LogMode initialMode;
  final String? vehicleId;
  final FillRecord? editFillRecord;
  final MaintenanceRecord? editMaintenanceRecord;
  final String? prefillServiceType;

  const LogEntryScreen({
    super.key,
    this.initialMode = LogMode.fuel,
    this.vehicleId,
    this.editFillRecord,
    this.editMaintenanceRecord,
    this.prefillServiceType,
  });

  bool get isEditing =>
      editFillRecord != null || editMaintenanceRecord != null;

  @override
  State<LogEntryScreen> createState() => _LogEntryScreenState();
}

class _LogEntryScreenState extends State<LogEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _odometerController = TextEditingController();
  final _costController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  final _serviceTypeController = TextEditingController();
  final _nextDueOdometerController = TextEditingController();

  late LogMode _mode;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime? _nextDueDate;
  String _selectedFuelTypeId = '';
  String _selectedVehicleId = '';
  String _selectedCategory = kMaintenanceCategories.first['id']!;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Mode is fixed by the record being edited; otherwise the requested mode.
    _mode = widget.editMaintenanceRecord != null
        ? LogMode.service
        : widget.editFillRecord != null
            ? LogMode.fuel
            : widget.initialMode;

    final fill = widget.editFillRecord;
    final service = widget.editMaintenanceRecord;

    if (fill != null) {
      _odometerController.text = fill.odometerKm.toStringAsFixed(0);
      _notesController.text = fill.notes;
      _selectedDate = fill.date;
      _selectedTime = TimeOfDay.fromDateTime(fill.date);
      _selectedFuelTypeId = fill.fuelTypeId;
      _selectedVehicleId = fill.vehicleId;
    } else if (service != null) {
      _serviceTypeController.text = service.serviceType;
      _odometerController.text = service.odometerKm.toStringAsFixed(0);
      _costController.text = service.cost > 0 ? service.cost.toString() : '';
      _notesController.text = service.notes;
      _selectedDate = service.serviceDate;
      _nextDueDate = service.nextDueDate;
      _selectedVehicleId = service.vehicleId;
      _selectedCategory = service.category;
      if (service.nextDueOdometerKm != null) {
        _nextDueOdometerController.text =
            service.nextDueOdometerKm!.toStringAsFixed(0);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final provider = context.read<RecordsProvider>();
      setState(() {
        if (_selectedVehicleId.isEmpty) {
          _selectedVehicleId = widget.vehicleId ?? provider.selectedVehicleId;
        }
        if (_selectedFuelTypeId.isEmpty) {
          _selectedFuelTypeId =
              provider.lastFuelTypeIdForVehicle(_selectedVehicleId) ??
                  provider.selectedFuelTypeId;
        }
        if (widget.editFillRecord == null &&
            widget.editMaintenanceRecord == null &&
            widget.prefillServiceType != null) {
          _serviceTypeController.text = widget.prefillServiceType!;
        }
      });
      // Edit-mode cost must be formatted in the record's own currency.
      final fill = widget.editFillRecord;
      if (fill != null) {
        final currency = provider.getCurrencyForFuelTypeId(fill.fuelTypeId);
        _costController.text =
            CurrencyUtils.formatAmount(fill.cost, currency);
        final price = fill.pricePerLiter ??
            provider.getFuelPriceForFuelTypeId(fill.fuelTypeId);
        _priceController.text = CurrencyUtils.formatAmount(price, currency);
      } else if (_mode == LogMode.fuel) {
        // New fill: default the price to the last fill's price for this
        // vehicle + fuel type (the recurring "no Settings trip" win).
        final currency = provider.getCurrencyForFuelTypeId(_selectedFuelTypeId);
        final price = provider.lastFuelPriceForVehicleFuelType(
            _selectedVehicleId, _selectedFuelTypeId);
        _priceController.text = CurrencyUtils.formatAmount(price, currency);
      }
    });
  }

  @override
  void dispose() {
    _odometerController.dispose();
    _costController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    _serviceTypeController.dispose();
    _nextDueOdometerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          title: Text(widget.isEditing ? 'Edit' : 'Log'),
          actions: [
            if (widget.isEditing)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: _isSaving ? null : _confirmDelete,
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            children: [
              _buildModeSelector(theme, isDark),
              const SizedBox(height: 16),
              _buildVehicleField(theme, isDark),
              const SizedBox(height: 16),
              if (_mode == LogMode.fuel)
                ..._buildFuelFields(theme, isDark)
              else
                ..._buildServiceFields(theme, isDark),
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
                    hintText: _mode == LogMode.fuel
                        ? 'Station brand, trip details...'
                        : 'Parts replaced, workshop, remarks...',
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildSaveBar(isDark),
      ),
    );
  }

  Widget _buildModeSelector(ThemeData theme, bool isDark) {
    if (widget.isEditing) {
      // Type is locked once saved — show it, don't let it change.
      final label = _mode == LogMode.fuel ? 'Fuel' : 'Service';
      final icon = _mode == LogMode.fuel
          ? Icons.local_gas_station_rounded
          : Icons.build_circle_rounded;
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SegmentedButton<LogMode>(
      segments: const [
        ButtonSegment(
          value: LogMode.fuel,
          label: Text('Fuel'),
          icon: Icon(Icons.local_gas_station_rounded),
        ),
        ButtonSegment(
          value: LogMode.service,
          label: Text('Service'),
          icon: Icon(Icons.build_circle_rounded),
        ),
      ],
      selected: {_mode},
      onSelectionChanged: (selection) {
        setState(() => _mode = selection.first);
      },
    );
  }

  Widget _buildVehicleField(ThemeData theme, bool isDark) {
    return Consumer<RecordsProvider>(
      builder: (context, provider, child) {
        final vehicles = provider.activeVehicles;
        if (vehicles.isEmpty) {
          return _Panel(
            title: 'Vehicle',
            icon: Icons.directions_car_rounded,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(child: Text('No active vehicles.')),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AddVehicleScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Vehicle'),
                ),
              ],
            ),
          );
        }

        final selectedId = _selectedVehicleId.isNotEmpty
            ? _selectedVehicleId
            : provider.selectedVehicleId;
        final value = vehicles.any((v) => v.id == selectedId)
            ? selectedId
            : vehicles.first.id;

        return _Panel(
          title: 'Vehicle',
          icon: Icons.directions_car_rounded,
          child: DropdownButtonFormField<String>(
            initialValue: value,
            decoration: _inputDecoration(theme, isDark),
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
              if (value == null) return;
              setState(() => _selectedVehicleId = value);
            },
          ),
        );
      },
    );
  }

  List<Widget> _buildFuelFields(ThemeData theme, bool isDark) {
    return [
      Consumer<RecordsProvider>(
        builder: (context, provider, child) {
          final fuelTypes = provider.activeFuelTypes;
          if (fuelTypes.isEmpty) {
            return _Panel(
              title: 'Fuel Type',
              icon: Icons.local_fire_department_rounded,
              child: const Text('No active fuel types. Add one in Settings.'),
            );
          }
          final selectedId = _selectedFuelTypeId.isNotEmpty
              ? _selectedFuelTypeId
              : provider.selectedFuelTypeId;
          final value = fuelTypes.any((f) => f.id == selectedId)
              ? selectedId
              : fuelTypes.first.id;

          return _Panel(
            title: 'Fuel Type',
            icon: Icons.local_fire_department_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: value,
                  decoration: _inputDecoration(theme, isDark),
                  items: fuelTypes.map((fuelType) {
                    final ftCurrency =
                        provider.getCurrencyForFuelTypeId(fuelType.id);
                    final priceLabel =
                        '$ftCurrency${CurrencyUtils.formatAmount(fuelType.pricePerLiter, ftCurrency)}/L';
                    return DropdownMenuItem<String>(
                      value: fuelType.id,
                      child: Text('${fuelType.name}  •  $priceLabel'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedFuelTypeId = value;
                      final newCurrency =
                          provider.getCurrencyForFuelTypeId(value);
                      final currentCost =
                          double.tryParse(_costController.text);
                      if (currentCost != null) {
                        _costController.text =
                            CurrencyUtils.formatAmount(currentCost, newCurrency);
                      }
                      // Re-seed the price from this type's last/known price.
                      _priceController.text = CurrencyUtils.formatAmount(
                        provider.lastFuelPriceForVehicleFuelType(
                            _selectedVehicleId, value),
                        newCurrency,
                      );
                    });
                  },
                ),
              ],
            ),
          );
        },
      ),
      const SizedBox(height: 16),
      _buildDateOdometerPanel(theme, isDark, withTime: true),
      const SizedBox(height: 16),
      Consumer<RecordsProvider>(
        builder: (context, provider, child) {
          final selectedId = _selectedFuelTypeId.isNotEmpty
              ? _selectedFuelTypeId
              : provider.selectedFuelTypeId;
          final currency = provider.getCurrencyForFuelTypeId(selectedId);
          return _Panel(
            title: 'Price, Cost & Volume',
            icon: Icons.payments_rounded,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _LabeledField(
                        label: 'Price / litre',
                        child: TextFormField(
                          key: const Key('log-price'),
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(CurrencyUtils.getInputPattern(currency)),
                            ),
                          ],
                          decoration: _inputDecoration(
                            theme,
                            isDark,
                            hintText: CurrencyUtils.getPlaceholder(currency),
                            prefixText: '$currency ',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter price';
                            }
                            final price = double.tryParse(value);
                            if (price == null || price <= 0) {
                              return 'Enter a valid price';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _LabeledField(
                        label: 'Total Cost',
                        child: TextFormField(
                          key: const Key('log-cost'),
                          controller: _costController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(CurrencyUtils.getInputPattern(currency)),
                            ),
                          ],
                          decoration: _inputDecoration(
                            theme,
                            isDark,
                            hintText: CurrencyUtils.getPlaceholder(currency),
                            prefixText: '$currency ',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter cost';
                            }
                            final cost = double.tryParse(value);
                            if (cost == null || cost <= 0) {
                              return 'Enter a valid amount';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AnimatedBuilder(
                  animation:
                      Listenable.merge([_costController, _priceController]),
                  builder: (context, child) {
                    final cost = double.tryParse(_costController.text) ?? 0;
                    final price = double.tryParse(_priceController.text) ?? 0;
                    final volume = price > 0 ? cost / price : 0.0;
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDarkElevated
                            : AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? AppColors.outlineDark
                              : AppColors.outlineLight,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Volume',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            volume > 0
                                ? '${volume.toStringAsFixed(1)} L'
                                : '-- L',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentAmber,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    ];
  }

  List<Widget> _buildServiceFields(ThemeData theme, bool isDark) {
    return [
      _Panel(
        title: 'Service Details',
        icon: Icons.build_circle_rounded,
        child: Column(
          children: [
            _LabeledField(
              label: 'Service Type',
              child: TextFormField(
                key: const Key('log-service-type'),
                controller: _serviceTypeController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration(theme, isDark, hintText: 'Oil Change'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a service type';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 10),
            // Quick-pick presets (last-used first).
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _orderedPresets().map((preset) {
                  return ActionChip(
                    label: Text(preset),
                    onPressed: () {
                      setState(() => _serviceTypeController.text = preset);
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
            _LabeledField(
              label: 'Category',
              child: DropdownButtonFormField<String>(
                initialValue: kMaintenanceCategories
                        .any((c) => c['id'] == _selectedCategory)
                    ? _selectedCategory
                    : kMaintenanceCategories.first['id'],
                decoration: _inputDecoration(theme, isDark),
                items: kMaintenanceCategories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category['id'],
                    child: Text(category['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedCategory = value);
                },
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _buildDateOdometerPanel(theme, isDark, withTime: false, costOptional: true),
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
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
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
                    return 'Must exceed service odometer';
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
                  : DateFormat('MMM dd, yyyy').format(_nextDueDate!),
              onTap: _pickDueDate,
              trailing: _nextDueDate == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => setState(() => _nextDueDate = null),
                    ),
            ),
          ],
        ),
      ),
    ];
  }

  /// Shared Date (+ Time for fuel) and Odometer + Cost panel.
  Widget _buildDateOdometerPanel(
    ThemeData theme,
    bool isDark, {
    required bool withTime,
    bool costOptional = false,
  }) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return Consumer<RecordsProvider>(
      builder: (context, provider, child) {
        final lastKnown =
            provider.getVehicleById(_selectedVehicleId)?.currentOdometer;
        return _Panel(
          title: withTime ? 'When & Odometer' : 'Date & Odometer',
          icon: Icons.speed_rounded,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _TapField(
                      icon: Icons.calendar_today_rounded,
                      label: 'Date',
                      value: dateFormat.format(_selectedDate),
                      onTap: _pickDate,
                    ),
                  ),
                  if (withTime) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TapField(
                        icon: Icons.schedule_rounded,
                        label: 'Time',
                        value: _selectedTime.format(context),
                        onTap: _pickTime,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _LabeledField(
                      label: 'Odometer',
                      child: TextFormField(
                        key: const Key('log-odometer'),
                        controller: _odometerController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*')),
                        ],
                        decoration: _inputDecoration(
                          theme,
                          isDark,
                          hintText: lastKnown != null
                              ? lastKnown.toStringAsFixed(0)
                              : '0',
                          suffixText: 'km',
                          helperText: lastKnown != null
                              ? 'Last: ${lastKnown.toStringAsFixed(0)} km'
                              : null,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter odometer';
                          }
                          final odometer = double.tryParse(value);
                          if (odometer == null || odometer <= 0) {
                            return 'Enter valid odometer';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  if (costOptional) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _LabeledField(
                        label: 'Cost (Optional)',
                        child: TextFormField(
                          controller: _costController,
                          keyboardType: const TextInputType.numberWithOptions(
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
                            hintText:
                                CurrencyUtils.getPlaceholder(provider.currency),
                            prefixText: '${provider.currency} ',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return null;
                            }
                            final parsed = double.tryParse(
                                value.replaceAll(',', '').trim());
                            if (parsed == null || parsed < 0) {
                              return 'Enter valid cost';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSaveBar(bool isDark) {
    return SafeArea(
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.isEditing ? 'Save Changes' : 'Save'),
        ),
      ),
    );
  }

  List<String> _orderedPresets() {
    final current = _serviceTypeController.text.trim();
    if (current.isEmpty) {
      return kServiceTypePresets;
    }
    // Float a matching preset to the front for quick re-selection.
    final ordered = List<String>.from(kServiceTypePresets);
    ordered.removeWhere((p) => p.toLowerCase() == current.toLowerCase());
    return ordered;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        if (_nextDueDate != null && !_nextDueDate!.isAfter(_selectedDate)) {
          _nextDueDate = null;
        }
      });
    }
  }

  Future<void> _pickTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _pickDueDate() async {
    final initial = _nextDueDate ?? _selectedDate.add(const Duration(days: 90));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(DateTime.now()) ? initial : DateTime.now(),
      firstDate: _selectedDate.add(const Duration(days: 1)),
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
    setState(() => _isSaving = true);
    try {
      final provider = context.read<RecordsProvider>();
      final vehicleId = _selectedVehicleId.isNotEmpty
          ? _selectedVehicleId
          : provider.selectedVehicleId;

      if (_mode == LogMode.fuel) {
        await _saveFuel(provider, vehicleId);
      } else {
        await _saveService(provider, vehicleId);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_mode == LogMode.fuel
              ? (widget.isEditing ? 'Fuel log updated' : 'Fuel log saved')
              : (widget.isEditing ? 'Service updated' : 'Service saved')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _saveFuel(RecordsProvider provider, String vehicleId) async {
    final date = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    final fuelTypeId = _selectedFuelTypeId.isNotEmpty
        ? _selectedFuelTypeId
        : provider.selectedFuelTypeId;
    final price = double.tryParse(_priceController.text.trim());
    final record = FillRecord(
      id: widget.editFillRecord?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      date: date,
      odometerKm: double.parse(_odometerController.text),
      cost: double.parse(_costController.text),
      notes: _notesController.text.trim(),
      fuelTypeId: fuelTypeId,
      vehicleId: vehicleId,
      pricePerLiter: (price != null && price > 0) ? price : null,
    );
    if (widget.editFillRecord != null) {
      await provider.updateRecord(record);
    } else {
      await provider.addRecord(record);
    }
    await provider.setSelectedFuelType(fuelTypeId);
  }

  Future<void> _saveService(RecordsProvider provider, String vehicleId) async {
    final dueDate = _nextDueDate;
    final now = DateTime.now();
    final serviceDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
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

    final base = widget.editMaintenanceRecord;
    final record = base == null
        ? MaintenanceRecord(
            id: 'maint_${now.microsecondsSinceEpoch}_${Random().nextInt(9999)}',
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

    if (widget.editMaintenanceRecord != null) {
      await provider.updateMaintenanceRecord(record);
    } else {
      await provider.addMaintenanceRecord(record);
    }
    await provider.setSelectedVehicle(vehicleId);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry'),
        content: const Text(
            'Are you sure you want to delete this entry? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final provider = context.read<RecordsProvider>();
    if (widget.editFillRecord != null) {
      await provider.deleteRecord(widget.editFillRecord!.id);
    } else if (widget.editMaintenanceRecord != null) {
      await provider.deleteMaintenanceRecord(widget.editMaintenanceRecord!.id);
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Entry deleted'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

InputDecoration _inputDecoration(
  ThemeData theme,
  bool isDark, {
  String? hintText,
  String? prefixText,
  String? suffixText,
  String? helperText,
}) {
  return InputDecoration(
    hintText: hintText,
    prefixText: prefixText,
    suffixText: suffixText,
    helperText: helperText,
    filled: true,
    fillColor:
        isDark ? AppColors.surfaceDarkElevated : AppColors.backgroundLight,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.colorScheme.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.colorScheme.error, width: 1.6),
    ),
  );
}

class _Panel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Panel({required this.title, required this.icon, required this.child});

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

  const _LabeledField({required this.label, required this.child});

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
