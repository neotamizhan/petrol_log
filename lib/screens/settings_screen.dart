import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/fuel_type.dart';
import '../providers/records_provider.dart';
import '../services/import_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_utils.dart';
import '../widgets/glass_panel.dart';
import 'vehicles_screen.dart';

const List<Map<String, String>> _currencies = [
  {'symbol': '₹', 'name': 'Indian Rupee (INR)'},
  {'symbol': '\$', 'name': 'US Dollar (USD)'},
  {'symbol': '€', 'name': 'Euro (EUR)'},
  {'symbol': '£', 'name': 'British Pound (GBP)'},
  {'symbol': '¥', 'name': 'Japanese Yen (JPY)'},
  {'symbol': '₽', 'name': 'Russian Ruble (RUB)'},
  {'symbol': 'د.إ', 'name': 'UAE Dirham (AED)'},
  {'symbol': '₿', 'name': 'Bitcoin (BTC)'},
  {'symbol': 'A\$', 'name': 'Australian Dollar (AUD)'},
  {'symbol': 'C\$', 'name': 'Canadian Dollar (CAD)'},
  {'symbol': 'KWD', 'name': 'Kuwaiti Dinar (KWD)'},
];

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _importService = ImportService();
  bool _hasChanges = false;
  bool _isImporting = false;
  String _selectedCurrency = 'KWD';
  String _selectedFuelTypeId = '';
  ThemeMode _selectedThemeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RecordsProvider>();
      final selectedFuelTypeId = provider.selectedFuelTypeId;
      _priceController.text = CurrencyUtils.formatAmount(
        provider.getFuelPriceForFuelTypeId(selectedFuelTypeId),
        provider.currency,
      );
      setState(() {
        _selectedCurrency = provider.currency;
        _selectedFuelTypeId = selectedFuelTypeId;
        _selectedThemeMode = provider.themeMode;
      });
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : null,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: _hasChanges
                ? _saveSettings
                : () {
                    Navigator.of(context).pop();
                  },
            child: Text(
              _hasChanges ? 'Save' : 'Done',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _SectionHeader(
              icon: Icons.local_gas_station_rounded,
              title: 'Fuel Types & Pricing',
            ),
            Consumer<RecordsProvider>(
              builder: (context, provider, child) {
                final fuelTypes = provider.fuelTypes;
                final selectableFuelTypes = fuelTypes
                    .where((fuelType) =>
                        fuelType.active ||
                        fuelType.id == provider.selectedFuelTypeId ||
                        fuelType.id == _selectedFuelTypeId)
                    .toList();
                if (selectableFuelTypes.isEmpty) {
                  return const SizedBox.shrink();
                }
                final preferredId = _selectedFuelTypeId.isNotEmpty
                    ? _selectedFuelTypeId
                    : provider.selectedFuelTypeId;
                final selectedId = selectableFuelTypes.any(
                  (fuelType) => fuelType.id == preferredId,
                )
                    ? preferredId
                    : selectableFuelTypes.first.id;
                final selectedFuelType = provider.getFuelTypeById(selectedId);

                return GlassPanel(
                  color: isDark
                      ? AppColors.settingsCardDark.withOpacity(0.92)
                      : null,
                  border: Border.all(
                    color: isDark
                        ? AppColors.primary.withOpacity(0.25)
                        : AppColors.outlineLight,
                  ),
                  boxShadow: isDark
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : null,
                  padding: const EdgeInsets.all(20),
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FUEL TYPE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.5),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
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
                            value: selectedId,
                            isExpanded: true,
                            icon: const Icon(Icons.expand_more_rounded),
                            items: selectableFuelTypes.map((fuelType) {
                              final archivedSuffix =
                                  fuelType.active ? '' : ' (Archived)';
                              return DropdownMenuItem<String>(
                                value: fuelType.id,
                                child: Text('${fuelType.name}$archivedSuffix'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() {
                                _selectedFuelTypeId = value;
                                _priceController.text =
                                    CurrencyUtils.formatAmount(
                                  provider.getFuelPriceForFuelTypeId(value),
                                  _selectedCurrency,
                                );
                                _hasChanges = true;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'PRICE PER LITER',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.5),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(CurrencyUtils.getInputPattern(
                                _selectedCurrency)),
                          ),
                        ],
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                        decoration: InputDecoration(
                          prefixText: '$_selectedCurrency ',
                          prefixStyle: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                          suffixText: '/L',
                          filled: true,
                          fillColor: isDark
                              ? AppColors.surfaceDarkElevated
                              : AppColors.backgroundLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (_) => setState(() => _hasChanges = true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter fuel price';
                          }
                          final price =
                              double.tryParse(value.replaceAll(',', '').trim());
                          if (price == null || price <= 0) {
                            return 'Please enter a valid price';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showAddFuelTypeDialog(provider),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Add Type'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: selectedFuelType == null
                                  ? null
                                  : () => _showEditFuelTypeDialog(
                                      provider, selectedFuelType),
                              icon: const Icon(Icons.edit_rounded, size: 18),
                              label: const Text('Edit Type'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: selectedFuelType == null ||
                                      fuelTypes.length <= 1
                                  ? null
                                  : () => _confirmDeleteFuelType(
                                      provider, selectedFuelType),
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 18),
                              label: const Text('Delete'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: fuelTypes.map((fuelType) {
                          final isSelected = fuelType.id == selectedId;
                          final badgeText =
                              '${fuelType.name} • ${_selectedCurrency}${CurrencyUtils.formatAmount(fuelType.pricePerLiter, _selectedCurrency)}';
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withOpacity(0.14)
                                  : (isDark
                                      ? AppColors.surfaceDarkElevated
                                      : AppColors.backgroundLight),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary.withOpacity(0.5)
                                    : (isDark
                                        ? AppColors.outlineDark
                                        : AppColors.outlineLight),
                              ),
                            ),
                            child: Text(
                              fuelType.active
                                  ? badgeText
                                  : '$badgeText (Archived)',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: fuelType.active
                                    ? colorScheme.onSurface
                                    : colorScheme.onSurface.withOpacity(0.55),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              icon: Icons.tune_rounded,
              title: 'Regional Preferences',
            ),
            Row(
              children: [
                Expanded(
                  child: _PreferenceCard(
                    title: 'Currency',
                    icon: Icons.payments_rounded,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _currencies
                                .any((c) => c['symbol'] == _selectedCurrency)
                            ? _selectedCurrency
                            : _currencies.first['symbol'],
                        isExpanded: true,
                        icon: Icon(Icons.expand_more_rounded,
                            color: colorScheme.onSurface.withOpacity(0.6)),
                        items: _currencies.map((currency) {
                          return DropdownMenuItem<String>(
                            value: currency['symbol'],
                            child: Text(
                              '${currency['symbol']}  ${currency['name']}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCurrency = value;
                              _hasChanges = true;
                              // Update price controller text to match new currency's decimal places
                              final currentPrice =
                                  double.tryParse(_priceController.text);
                              if (currentPrice != null) {
                                _priceController.text =
                                    CurrencyUtils.formatAmount(
                                  currentPrice,
                                  value,
                                );
                              }
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PreferenceCard(
                    title: 'Unit System',
                    icon: Icons.straighten_rounded,
                    child: Text(
                      'Liters',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              icon: Icons.directions_car_rounded,
              title: 'Vehicles',
            ),
            Consumer<RecordsProvider>(
              builder: (context, provider, child) {
                final vehicleCount = provider.vehicles.length;
                return GlassPanel(
                  color: isDark
                      ? AppColors.settingsCardDark.withOpacity(0.45)
                      : null,
                  padding: const EdgeInsets.all(18),
                  borderRadius: BorderRadius.circular(20),
                  child: Row(
                    children: [
                      Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.directions_car_rounded,
                            color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vehicle Management',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '$vehicleCount vehicle${vehicleCount == 1 ? '' : 's'} configured',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const VehiclesScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.tune_rounded, size: 18),
                        label: const Text('Manage'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              icon: Icons.palette_rounded,
              title: 'Appearance',
            ),
            GlassPanel(
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme Mode',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_rounded),
                        label: Text('Light'),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_rounded),
                        label: Text('Dark'),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.system,
                        icon: Icon(Icons.phone_iphone_rounded),
                        label: Text('System'),
                      ),
                    ],
                    selected: {_selectedThemeMode},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) {
                      setState(() {
                        _selectedThemeMode = selection.first;
                        _hasChanges = true;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              icon: Icons.table_view_rounded,
              title: 'Data Management',
            ),
            GlassPanel(
              color:
                  isDark ? AppColors.settingsCardDark.withOpacity(0.45) : null,
              padding: const EdgeInsets.all(18),
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.upload_file_rounded,
                            color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Import History',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              'Migrate data from CSV exports.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDarkElevated
                          : AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CSV Format',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Date, Odometer (km), Cost, Notes, Fuel Type',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Example: 2026-01-30, 45230, 2500, Full tank, Premium 95',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isImporting ? null : _importFromCsv,
                          icon: _isImporting
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.onPrimary,
                                  ),
                                )
                              : const Icon(Icons.upload_file_rounded),
                          label: Text(
                              _isImporting ? 'Importing...' : 'Upload CSV'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.help_outline_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark
                              ? AppColors.surfaceDarkElevated
                              : AppColors.backgroundLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              icon: Icons.analytics_rounded,
              title: 'How We Calculate',
            ),
            GlassPanel(
              color:
                  isDark ? AppColors.settingsCardDark.withOpacity(0.45) : null,
              padding: const EdgeInsets.all(18),
              borderRadius: BorderRadius.circular(20),
              child: Row(
                children: [
                  _CalcStep(
                    title: 'Step 1',
                    value: 'Odometer',
                    icon: Icons.speed_rounded,
                    color: AppColors.accentBlue,
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded,
                      size: 18, color: colorScheme.onSurface.withOpacity(0.4)),
                  const SizedBox(width: 8),
                  _CalcStep(
                    title: 'Step 2',
                    value: 'Fuel Filled',
                    icon: Icons.local_gas_station_rounded,
                    color: AppColors.accentAmber,
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded,
                      size: 18, color: colorScheme.onSurface.withOpacity(0.4)),
                  const SizedBox(width: 8),
                  _CalcStep(
                    title: 'Result',
                    value: 'Efficiency',
                    icon: Icons.analytics_rounded,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Petrol Log v1.0.0',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<RecordsProvider>();
    final selectedFuelTypeId = _selectedFuelTypeId.isNotEmpty
        ? _selectedFuelTypeId
        : provider.selectedFuelTypeId;
    final price = _parseAmount(_priceController.text);
    await provider.setSelectedFuelType(selectedFuelTypeId);
    await provider.setFuelPrice(price);
    await provider.setCurrency(_selectedCurrency);
    await provider.setThemeMode(_selectedThemeMode);

    setState(() => _hasChanges = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Settings saved!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _showAddFuelTypeDialog(RecordsProvider provider) async {
    String fuelTypeName = '';
    String fuelTypePriceText = CurrencyUtils.formatAmount(
      provider.fuelPricePerLiter,
      _selectedCurrency,
    );
    final formKey = GlobalKey<FormState>();

    final draft = await showDialog<_FuelTypeDraft>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Fuel Type'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: fuelTypeName,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Fuel type name',
                  hintText: 'Premium 95',
                ),
                onChanged: (value) => fuelTypeName = value,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a fuel type name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: fuelTypePriceText,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(CurrencyUtils.getInputPattern(_selectedCurrency)),
                  ),
                ],
                onChanged: (value) => fuelTypePriceText = value,
                decoration: InputDecoration(
                  labelText: 'Price per liter',
                  prefixText: '$_selectedCurrency ',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter price';
                  }
                  final price =
                      double.tryParse(value.replaceAll(',', '').trim());
                  if (price == null || price <= 0) {
                    return 'Enter a valid price';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) {
                return;
              }
              Navigator.of(ctx).pop(
                _FuelTypeDraft(
                  name: fuelTypeName.trim(),
                  pricePerLiter: _parseAmount(fuelTypePriceText),
                ),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (draft == null) {
      return;
    }

    await Future<void>.delayed(Duration.zero);

    final beforeIds = provider.fuelTypes.map((fuelType) => fuelType.id).toSet();
    await provider.addFuelType(
      name: draft.name,
      pricePerLiter: draft.pricePerLiter,
    );

    final createdFuelType = provider.fuelTypes.firstWhere(
      (fuelType) => !beforeIds.contains(fuelType.id),
      orElse: () => provider.selectedFuelType ?? provider.fuelTypes.first,
    );
    await provider.setSelectedFuelType(createdFuelType.id);

    if (!mounted) {
      return;
    }
    setState(() {
      _selectedFuelTypeId = createdFuelType.id;
      _priceController.text = CurrencyUtils.formatAmount(
        createdFuelType.pricePerLiter,
        _selectedCurrency,
      );
      _hasChanges = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Fuel type added'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _showEditFuelTypeDialog(
    RecordsProvider provider,
    FuelType fuelType,
  ) async {
    String fuelTypeName = fuelType.name;
    String fuelTypePriceText = CurrencyUtils.formatAmount(
      fuelType.pricePerLiter,
      _selectedCurrency,
    );
    final formKey = GlobalKey<FormState>();

    final draft = await showDialog<_FuelTypeDraft>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Fuel Type'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: fuelTypeName,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Fuel type name'),
                onChanged: (value) => fuelTypeName = value,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a fuel type name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: fuelTypePriceText,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(CurrencyUtils.getInputPattern(_selectedCurrency)),
                  ),
                ],
                onChanged: (value) => fuelTypePriceText = value,
                decoration: InputDecoration(
                  labelText: 'Price per liter',
                  prefixText: '$_selectedCurrency ',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter price';
                  }
                  final price =
                      double.tryParse(value.replaceAll(',', '').trim());
                  if (price == null || price <= 0) {
                    return 'Enter a valid price';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) {
                return;
              }
              Navigator.of(ctx).pop(
                _FuelTypeDraft(
                  name: fuelTypeName.trim(),
                  pricePerLiter: _parseAmount(fuelTypePriceText),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (draft == null) {
      return;
    }

    await Future<void>.delayed(Duration.zero);

    final updatedFuelType = fuelType.copyWith(
      name: draft.name,
      pricePerLiter: draft.pricePerLiter,
    );
    await provider.updateFuelType(updatedFuelType);

    if (!mounted) {
      return;
    }
    if (_selectedFuelTypeId == updatedFuelType.id) {
      setState(() {
        _priceController.text = CurrencyUtils.formatAmount(
          updatedFuelType.pricePerLiter,
          _selectedCurrency,
        );
        _hasChanges = false;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Fuel type updated'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteFuelType(
    RecordsProvider provider,
    FuelType fuelType,
  ) async {
    if (provider.fuelTypes.length <= 1) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('At least one fuel type is required'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    final hasRecords = provider.hasRecordsForFuelType(fuelType.id);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Fuel Type'),
        content: Text(
          hasRecords
              ? 'This fuel type is used in existing records. It will be archived instead of removed. Continue?'
              : 'Remove "${fuelType.name}" permanently?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(hasRecords ? 'Archive' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await provider.deleteFuelType(fuelType.id);
    final nextSelected = provider.selectedFuelTypeId;

    if (!mounted) {
      return;
    }
    setState(() {
      _selectedFuelTypeId = nextSelected;
      _priceController.text = CurrencyUtils.formatAmount(
        provider.getFuelPriceForFuelTypeId(nextSelected),
        _selectedCurrency,
      );
      _hasChanges = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(hasRecords ? 'Fuel type archived' : 'Fuel type deleted'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _importFromCsv() async {
    setState(() => _isImporting = true);

    try {
      final result = await _importService.importFromCsv();

      if (!mounted) return;

      if (result.success && result.records.isNotEmpty) {
        final shouldImport = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Import Records'),
            content: Text(
                'Found ${result.records.length} records to import. Continue?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Import'),
              ),
            ],
          ),
        );

        if (shouldImport == true && mounted) {
          final provider = context.read<RecordsProvider>();
          for (final record in result.records) {
            await provider.addRecord(record);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            behavior: SnackBarBehavior.floating,
            backgroundColor:
                result.success ? null : Theme.of(context).colorScheme.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  double _parseAmount(String text) {
    return double.parse(text.replaceAll(',', '').trim());
  }
}

class _FuelTypeDraft {
  final String name;
  final double pricePerLiter;

  const _FuelTypeDraft({
    required this.name,
    required this.pricePerLiter,
  });
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              letterSpacing: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _PreferenceCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GlassPanel(
      color: isDark ? AppColors.settingsCardDark.withOpacity(0.45) : null,
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: 18,
                  color: theme.colorScheme.onSurface.withOpacity(0.6)),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _CalcStep extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _CalcStep({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
