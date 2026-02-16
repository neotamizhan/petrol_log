/// Utility class for currency-specific configurations
class CurrencyUtils {
  /// Get the number of decimal places for a given currency symbol
  ///
  /// Most currencies use 2 decimal places, but some currencies like:
  /// - KWD (Kuwaiti Dinar) uses 3 decimal places (fils)
  /// - BHD (Bahraini Dinar) uses 3 decimal places
  /// - OMR (Omani Rial) uses 3 decimal places
  /// - TND (Tunisian Dinar) uses 3 decimal places
  /// - JPY (Japanese Yen) uses 0 decimal places
  /// - BTC (Bitcoin) typically uses up to 8 decimal places, but we'll use 3 for practicality
  static int getDecimalPlaces(String currencySymbol) {
    switch (currencySymbol) {
      case 'KWD':
      case 'BHD':
      case 'OMR':
      case 'TND':
      case '₿': // Bitcoin - using 3 for practical fuel prices
        return 3;
      case '¥': // Japanese Yen
        return 0;
      default:
        return 2; // Default for most currencies
    }
  }

  /// Get a regex pattern for validating currency input based on decimal places
  static String getInputPattern(String currencySymbol) {
    final decimals = getDecimalPlaces(currencySymbol);
    if (decimals == 0) {
      return r'^\d+$';
    }
    return '^\\d+\\.?\\d{0,$decimals}';
  }

  /// Format a number to the appropriate number of decimal places for a currency
  static String formatAmount(double amount, String currencySymbol) {
    final decimals = getDecimalPlaces(currencySymbol);
    return amount.toStringAsFixed(decimals);
  }

  /// Get placeholder text for currency input
  static String getPlaceholder(String currencySymbol) {
    final decimals = getDecimalPlaces(currencySymbol);
    if (decimals == 0) {
      return '0';
    }
    return '0.${'0' * decimals}';
  }
}
