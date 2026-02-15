import 'package:flutter_test/flutter_test.dart';
import 'package:petrol_log/utils/currency_utils.dart';

void main() {
  group('CurrencyUtils', () {
    group('getDecimalPlaces', () {
      test('returns 3 for KWD', () {
        expect(CurrencyUtils.getDecimalPlaces('KWD'), 3);
      });

      test('returns 3 for BHD', () {
        expect(CurrencyUtils.getDecimalPlaces('BHD'), 3);
      });

      test('returns 3 for OMR', () {
        expect(CurrencyUtils.getDecimalPlaces('OMR'), 3);
      });

      test('returns 3 for TND', () {
        expect(CurrencyUtils.getDecimalPlaces('TND'), 3);
      });

      test('returns 3 for Bitcoin', () {
        expect(CurrencyUtils.getDecimalPlaces('₿'), 3);
      });

      test('returns 0 for Japanese Yen', () {
        expect(CurrencyUtils.getDecimalPlaces('¥'), 0);
      });

      test('returns 2 for USD', () {
        expect(CurrencyUtils.getDecimalPlaces('\$'), 2);
      });

      test('returns 2 for EUR', () {
        expect(CurrencyUtils.getDecimalPlaces('€'), 2);
      });

      test('returns 2 for INR', () {
        expect(CurrencyUtils.getDecimalPlaces('₹'), 2);
      });

      test('returns 2 for unknown currency (default)', () {
        expect(CurrencyUtils.getDecimalPlaces('XYZ'), 2);
      });
    });

    group('getInputPattern', () {
      test('returns pattern allowing 3 decimals for KWD', () {
        final pattern = CurrencyUtils.getInputPattern('KWD');
        expect(RegExp(pattern).hasMatch('1.234'), true);
        expect(RegExp(pattern).hasMatch('1.2345'), false);
      });

      test('returns pattern allowing 0 decimals for JPY', () {
        final pattern = CurrencyUtils.getInputPattern('¥');
        expect(RegExp(pattern).hasMatch('100'), true);
        expect(RegExp(pattern).hasMatch('100.5'), false);
      });

      test('returns pattern allowing 2 decimals for USD', () {
        final pattern = CurrencyUtils.getInputPattern('\$');
        expect(RegExp(pattern).hasMatch('1.23'), true);
        expect(RegExp(pattern).hasMatch('1.234'), false);
      });
    });

    group('formatAmount', () {
      test('formats amount with 3 decimals for KWD', () {
        expect(CurrencyUtils.formatAmount(1.2345, 'KWD'), '1.235');
      });

      test('formats amount with 0 decimals for JPY', () {
        expect(CurrencyUtils.formatAmount(100.5, '¥'), '100');
        expect(CurrencyUtils.formatAmount(100.6, '¥'), '101');
      });

      test('formats amount with 2 decimals for USD', () {
        expect(CurrencyUtils.formatAmount(1.234, '\$'), '1.23');
      });

      test('formats amount with 2 decimals for default currency', () {
        expect(CurrencyUtils.formatAmount(1.234, 'UNKNOWN'), '1.23');
      });
    });

    group('getPlaceholder', () {
      test('returns placeholder with 3 decimals for KWD', () {
        expect(CurrencyUtils.getPlaceholder('KWD'), '0.000');
      });

      test('returns placeholder with 0 decimals for JPY', () {
        expect(CurrencyUtils.getPlaceholder('¥'), '0');
      });

      test('returns placeholder with 2 decimals for USD', () {
        expect(CurrencyUtils.getPlaceholder('\$'), '0.00');
      });
    });
  });
}
