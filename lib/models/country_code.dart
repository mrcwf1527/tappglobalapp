// lib/models/country_code.dart
class CountryCode {
  final String name;
  final String code;
  final String dialCode;
  final String flag;

  const CountryCode({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
  });
}

class CountryCodes {
  static final List<CountryCode> codes = [
    CountryCode(
      name: 'United States',
      code: 'US',
      dialCode: '+1',
      flag: '🇺🇸',
    ),
    CountryCode(
      name: 'United Kingdom',
      code: 'GB',
      dialCode: '+44',
      flag: '🇬🇧',
    ),
    CountryCode(
      name: 'India',
      code: 'IN',
      dialCode: '+91',
      flag: '🇮🇳',
    ),
    CountryCode(
      name: 'United Arab Emirates',
      code: 'AE',
      dialCode: '+971',
      flag: '🇦🇪',
    ),
    CountryCode(
      name: 'Saudi Arabia',
      code: 'SA',
      dialCode: '+966',
      flag: '🇸🇦',
    ),
    CountryCode(
      name: 'Malaysia',
      code: 'MY',
      dialCode: '+60',
      flag: '🇲🇾',
    ),
    // Add more countries as needed
  ];

  static CountryCode getDefault() {
    return codes.firstWhere((code) => code.code == 'AE');
  }

  static CountryCode? findByCode(String code) {
    try {
      return codes.firstWhere((country) => country.code == code.toUpperCase());
    } catch (_) {
      return null;
    }
  }
}