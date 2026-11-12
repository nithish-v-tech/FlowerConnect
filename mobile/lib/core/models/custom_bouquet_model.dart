class BouquetBaseOption {
  final String id;
  final String name;
  final double price;
  final String description;
  final String iconEmoji;

  const BouquetBaseOption({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.iconEmoji,
  });
}

class FlowerStemOption {
  final String id;
  final String name;
  final double pricePerStem;
  final String colorHex;
  final String emoji;

  const FlowerStemOption({
    required this.id,
    required this.name,
    required this.pricePerStem,
    required this.colorHex,
    required this.emoji,
  });
}

class RibbonOption {
  final String id;
  final String name;
  final String colorHex;
  final double price;

  const RibbonOption({
    required this.id,
    required this.name,
    required this.colorHex,
    this.price = 40.0,
  });
}

class BouquetAddonOption {
  final String id;
  final String name;
  final double price;
  final String emoji;
  final String description;

  const BouquetAddonOption({
    required this.id,
    required this.name,
    required this.price,
    required this.emoji,
    required this.description,
  });
}

class CustomBouquetConfiguration {
  final BouquetBaseOption base;
  final Map<FlowerStemOption, int> stemCounts;
  final RibbonOption ribbon;
  final List<BouquetAddonOption> selectedAddons;
  final String greetingMessage;

  const CustomBouquetConfiguration({
    required this.base,
    required this.stemCounts,
    required this.ribbon,
    required this.selectedAddons,
    this.greetingMessage = '',
  });

  int get totalStemsCount =>
      stemCounts.values.fold(0, (sum, count) => sum + count);

  double get flowersCost {
    double sum = 0.0;
    stemCounts.forEach((stem, count) {
      sum += stem.pricePerStem * count;
    });
    return sum;
  }

  double get addonsCost =>
      selectedAddons.fold(0.0, (sum, addon) => sum + addon.price);

  double get grandTotal =>
      base.price + ribbon.price + flowersCost + addonsCost;
}

