enum CurrencyCode {
  ngn('NGN', '₦'),
  ghs('GHS', 'GH₵'),
  kes('KES', 'KSh'),
  zar('ZAR', 'R'),
  usd('USD', r'$'),
  gbp('GBP', '£'),
  eur('EUR', '€');

  const CurrencyCode(this.code, this.symbol);

  final String code;
  final String symbol;

  static CurrencyCode? tryParse(String? input) {
    if (input == null) return null;
    final upper = input.trim().toUpperCase();
    for (final value in CurrencyCode.values) {
      if (value.code == upper) return value;
    }
    return null;
  }

  static CurrencyCode parse(String input) {
    final parsed = tryParse(input);
    if (parsed == null) {
      throw ArgumentError.value(input, 'input', 'Unsupported currency code');
    }
    return parsed;
  }

  static CurrencyCode fromCountryCode(String? countryCode) {
    if (countryCode == null) return CurrencyCode.usd;
    final upper = countryCode.trim().toUpperCase();
    switch (upper) {
      case 'NG':
        return CurrencyCode.ngn;
      case 'GH':
        return CurrencyCode.ghs;
      case 'KE':
        return CurrencyCode.kes;
      case 'ZA':
        return CurrencyCode.zar;
      case 'US':
        return CurrencyCode.usd;
      case 'GB':
        return CurrencyCode.gbp;
      case 'AT':
      case 'BE':
      case 'CY':
      case 'EE':
      case 'FI':
      case 'FR':
      case 'DE':
      case 'GR':
      case 'IE':
      case 'IT':
      case 'LV':
      case 'LT':
      case 'LU':
      case 'MT':
      case 'NL':
      case 'PT':
      case 'SK':
      case 'SI':
      case 'ES':
      case 'HR':
        return CurrencyCode.eur;
      default:
        return CurrencyCode.usd;
    }
  }
}
