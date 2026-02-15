import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/records_provider.dart';
import '../services/import_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_utils.dart';
import '../widgets/glass_panel.dart';

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
  ThemeMode _selectedThemeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RecordsProvider>();
      _priceController.text = CurrencyUtils.formatAmount(
        provider.fuelPricePerLiter,
        provider.currency,
      );
      setState(() {
        _selectedCurrency = provider.currency;
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
              title: 'Current Pump Price',
            ),
            GlassPanel(
              color: isDark ? AppColors.settingsCardDark.withOpacity(0.92) : null,
              border: Border.all(
                color: isDark ? AppColors.primary.withOpacity(0.25) : AppColors.outlineLight,
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
                children: [
                  Text(
                    'PRICE PER LITER',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.5),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(CurrencyUtils.getInputPattern(_selectedCurrency)),
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
                      fillColor: isDark ? AppColors.surfaceDarkElevated : AppColors.backgroundLight,
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
                      final price = double.tryParse(value);
                      if (price == null || price <= 0) {
                        return 'Please enter a valid price';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 8,
                        width: 8,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Live update active',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.5),
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
                        value: _currencies.any((c) => c['symbol'] == _selectedCurrency)
                            ? _selectedCurrency
                            : _currencies.first['symbol'],
                        isExpanded: true,
                        icon: Icon(Icons.expand_more_rounded, color: colorScheme.onSurface.withOpacity(0.6)),
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
                              final currentPrice = double.tryParse(_priceController.text);
                              if (currentPrice != null) {
                                _priceController.text = CurrencyUtils.formatAmount(
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
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
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
              color: isDark ? AppColors.settingsCardDark.withOpacity(0.45) : null,
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
                        child: const Icon(Icons.upload_file_rounded, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Import History',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
                      color: isDark ? AppColors.surfaceDarkElevated : AppColors.backgroundLight,
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
                          'Date, Odometer (km), Cost, Notes',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Example: 2026-01-30, 45230, 2500, Full tank',
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
                          label: Text(_isImporting ? 'Importing...' : 'Upload CSV'),
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
              color: isDark ? AppColors.settingsCardDark.withOpacity(0.45) : null,
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
                  Icon(Icons.arrow_forward_rounded, size: 18, color: colorScheme.onSurface.withOpacity(0.4)),
                  const SizedBox(width: 8),
                  _CalcStep(
                    title: 'Step 2',
                    value: 'Fuel Filled',
                    icon: Icons.local_gas_station_rounded,
                    color: AppColors.accentAmber,
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18, color: colorScheme.onSurface.withOpacity(0.4)),
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
    final price = double.parse(_priceController.text);
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
            content: Text('Found ${result.records.length} records to import. Continue?'),
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
            backgroundColor: result.success ? null : Theme.of(context).colorScheme.error,
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
              Icon(icon, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.6)),
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
