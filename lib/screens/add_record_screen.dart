import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/fill_record.dart';
import '../providers/records_provider.dart';
import '../theme/app_theme.dart';
import '../utils/currency_utils.dart';

class AddRecordScreen extends StatefulWidget {
  const AddRecordScreen({super.key});

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _odometerController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedFuelTypeId = '';
  String _selectedVehicleId = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RecordsProvider>();
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedFuelTypeId = provider.selectedFuelTypeId;
        _selectedVehicleId = provider.selectedVehicleId;
      });
    });
  }

  @override
  void dispose() {
    _odometerController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : null,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Add Fuel Record'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            Consumer<RecordsProvider>(
              builder: (context, provider, child) {
                final selectedFuelTypeId = _selectedFuelTypeId.isNotEmpty
                    ? _selectedFuelTypeId
                    : provider.selectedFuelTypeId;
                final selectedFuelType =
                    provider.getFuelTypeById(selectedFuelTypeId);
                final selectedPrice =
                    provider.getFuelPriceForFuelTypeId(selectedFuelTypeId);
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: isDark
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.addFormSurfaceDark,
                              Color(0xFF17312E)
                            ],
                          )
                        : null,
                    color: isDark ? null : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? AppColors.outlineDark
                          : AppColors.outlineLight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.25 : 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Fuel Price / L',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${provider.currency}${CurrencyUtils.formatAmount(selectedPrice, provider.currency)}',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '/L',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.primary.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (selectedFuelType != null)
                        Text(
                          selectedFuelType.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (selectedFuelType != null) const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceDarkElevated
                              : AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? AppColors.outlineDark.withOpacity(0.7)
                                : AppColors.outlineLight,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              height: 8,
                              width: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.accentAmber,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Live Calculation',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.accentAmber,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Consumer<RecordsProvider>(
              builder: (context, provider, child) {
                final availableFuelTypes = provider.activeFuelTypes;
                if (availableFuelTypes.isEmpty) {
                  return _InputCard(
                    label: 'Fuel Type',
                    icon: Icons.local_fire_department_rounded,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDarkElevated
                            : AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? AppColors.outlineDark
                              : AppColors.outlineLight,
                        ),
                      ),
                      child: const Text(
                          'No active fuel types. Add one in Settings.'),
                    ),
                  );
                }

                final selectedFuelTypeId = _selectedFuelTypeId.isNotEmpty
                    ? _selectedFuelTypeId
                    : provider.selectedFuelTypeId;
                final dropdownValue = availableFuelTypes.any(
                  (fuelType) => fuelType.id == selectedFuelTypeId,
                )
                    ? selectedFuelTypeId
                    : availableFuelTypes.first.id;

                return _InputCard(
                  label: 'Fuel Type',
                  icon: Icons.local_fire_department_rounded,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDarkElevated
                          : AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.outlineDark
                            : AppColors.outlineLight,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: dropdownValue,
                        isExpanded: true,
                        icon: const Icon(Icons.expand_more_rounded),
                        items: availableFuelTypes.map((fuelType) {
                          final priceLabel =
                              '${provider.currency}${CurrencyUtils.formatAmount(fuelType.pricePerLiter, provider.currency)}/L';
                          return DropdownMenuItem<String>(
                            value: fuelType.id,
                            child: Text('${fuelType.name}  •  $priceLabel'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _selectedFuelTypeId = value;
                          });
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Consumer<RecordsProvider>(
              builder: (context, provider, child) {
                final activeVehicles = provider.activeVehicles;
                if (activeVehicles.isEmpty) {
                  return const SizedBox.shrink();
                }

                final selectedVehicleId = _selectedVehicleId.isNotEmpty
                    ? _selectedVehicleId
                    : provider.selectedVehicleId;
                final dropdownValue = activeVehicles.any(
                  (v) => v.id == selectedVehicleId,
                )
                    ? selectedVehicleId
                    : activeVehicles.first.id;

                return _InputCard(
                  label: 'Vehicle',
                  icon: Icons.directions_car_rounded,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDarkElevated
                          : AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.outlineDark
                            : AppColors.outlineLight,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: dropdownValue,
                        isExpanded: true,
                        icon: const Icon(Icons.expand_more_rounded),
                        items: activeVehicles.map((vehicle) {
                          final label = vehicle.plateNumber != null
                              ? '${vehicle.name}  •  ${vehicle.plateNumber}'
                              : vehicle.name;
                          return DropdownMenuItem<String>(
                            value: vehicle.id,
                            child: Text(label),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedVehicleId = value;
                          });
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _TapFieldCard(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: dateFormat.format(_selectedDate),
                    onTap: _selectDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TapFieldCard(
                    icon: Icons.schedule_rounded,
                    label: 'Time',
                    value: _selectedTime.format(context),
                    onTap: _selectTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _InputCard(
              label: 'Odometer',
              icon: Icons.speed_rounded,
              child: _TextFieldShell(
                trailingText: 'km',
                child: TextFormField(
                  controller: _odometerController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  decoration: const InputDecoration(
                    hintText: '0',
                    border: InputBorder.none,
                  ),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.right,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter odometer reading';
                    }
                    final km = double.tryParse(value);
                    if (km == null || km <= 0) {
                      return 'Please enter a valid reading';
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _InputCard(
                    label: 'Total Cost',
                    icon: Icons.attach_money_rounded,
                    child: Consumer<RecordsProvider>(
                      builder: (context, provider, child) {
                        return _TextFieldShell(
                          leadingText: provider.currency,
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
                            decoration: InputDecoration(
                              hintText: CurrencyUtils.getPlaceholder(
                                  provider.currency),
                              border: InputBorder.none,
                            ),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.right,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter cost';
                              }
                              final cost = double.tryParse(value);
                              if (cost == null || cost <= 0) {
                                return 'Please enter a valid amount';
                              }
                              return null;
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InputCard(
                    label: 'Volume',
                    icon: Icons.local_gas_station_rounded,
                    child: Consumer<RecordsProvider>(
                      builder: (context, provider, child) {
                        return ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _costController,
                          builder: (context, value, child) {
                            final cost = double.tryParse(value.text) ?? 0;
                            final selectedFuelTypeId =
                                _selectedFuelTypeId.isNotEmpty
                                    ? _selectedFuelTypeId
                                    : provider.selectedFuelTypeId;
                            final selectedPrice = provider
                                .getFuelPriceForFuelTypeId(selectedFuelTypeId);
                            final volume =
                                selectedPrice > 0 ? cost / selectedPrice : 0.0;
                            return _TextFieldShell(
                              trailingText: 'L',
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  volume > 0 ? volume.toStringAsFixed(1) : '--',
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accentAmber,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _InputCard(
              label: 'Notes',
              icon: Icons.notes_rounded,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.inputSurfaceDark
                      : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isDark ? AppColors.outlineDark : AppColors.outlineLight,
                  ),
                ),
                child: TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText:
                        'Station brand, tire pressure, or trip details...',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                (isDark ? AppColors.backgroundDark : AppColors.backgroundLight)
                    .withOpacity(0),
                isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
              ],
            ),
          ),
          child: FilledButton(
            onPressed: _isSaving ? null : _saveRecord,
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
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save_rounded),
                      SizedBox(width: 8),
                      Text('Save Record'),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final recordDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final provider = context.read<RecordsProvider>();
      final vehicleId = _selectedVehicleId.isNotEmpty
          ? _selectedVehicleId
          : provider.selectedVehicleId;

      final record = FillRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: recordDate,
        odometerKm: double.parse(_odometerController.text),
        cost: double.parse(_costController.text),
        notes: _notesController.text.trim(),
        fuelTypeId: _selectedFuelTypeId.isNotEmpty
            ? _selectedFuelTypeId
            : provider.selectedFuelTypeId,
        vehicleId: vehicleId,
      );

      await provider.addRecord(record);
      await provider.setSelectedFuelType(record.fuelTypeId);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Fill record saved successfully!'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving record: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _TapFieldCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _TapFieldCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.addFormSurfaceDark : Colors.white,
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
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget child;

  const _InputCard({
    required this.label,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _TextFieldShell extends StatelessWidget {
  final Widget child;
  final String? leadingText;
  final String? trailingText;

  const _TextFieldShell({
    required this.child,
    this.leadingText,
    this.trailingText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.inputSurfaceDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
        ),
      ),
      child: Row(
        children: [
          if (leadingText != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                leadingText!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          Expanded(child: child),
          if (trailingText != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                trailingText!,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentAmber,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
