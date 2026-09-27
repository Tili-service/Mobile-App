const double defaultTaxRate = 0.2;

double round2(double value) => (value * 100).roundToDouble() / 100;

double parseNum(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;

double parseInput(String text) => double.tryParse(text.trim().replaceAll(',', '.')) ?? double.nan;

// Items are stored HT with `tax` as a decimal rate (0.2); every screen shows TTC.
double itemPriceHT(dynamic item) => parseNum(item['price']);
double itemTaxRate(dynamic item) => parseNum(item['tax']);
double itemPriceTTC(dynamic item) => round2(itemPriceHT(item) * (1 + itemTaxRate(item)));

String formatEuro(double value) => '${value.toStringAsFixed(2).replaceAll('.', ',')} €';
