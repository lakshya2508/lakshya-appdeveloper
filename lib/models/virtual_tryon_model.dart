enum TryOnCategory {
  all,
  eyewear,
  headwear,
  footwear,
  tops,
  custom;

  String get label {
    switch (this) {
      case TryOnCategory.all:
        return 'All Items';
      case TryOnCategory.eyewear:
        return 'Eyewear';
      case TryOnCategory.headwear:
        return 'Headwear';
      case TryOnCategory.footwear:
        return 'Footwear';
      case TryOnCategory.tops:
        return 'Apparel & Tops';
      case TryOnCategory.custom:
        return 'Custom';
    }
  }

  static TryOnCategory fromString(String val) {
    return TryOnCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => TryOnCategory.all,
    );
  }
}

class TryOnItem {
  const TryOnItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.image,
    this.glbAsset,
    this.arAsset,
    this.isCustom = false,
  });

  final String id;
  final String name;
  final TryOnCategory category;
  final double price;
  final String description;
  final String image;
  final String? glbAsset;
  final String? arAsset;
  final bool isCustom;

  factory TryOnItem.fromJson(Map<String, dynamic> json) => TryOnItem(
        id: json['id'] as String,
        name: json['name'] as String,
        category: TryOnCategory.fromString(json['category'] as String? ?? 'all'),
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        description: json['description'] as String? ?? '',
        image: json['image'] as String,
        glbAsset: json['glbAsset'] as String?,
        arAsset: json['arAsset'] as String?,
        isCustom: json['isCustom'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.name,
        'price': price,
        'description': description,
        'image': image,
        if (glbAsset != null) 'glbAsset': glbAsset,
        if (arAsset != null) 'arAsset': arAsset,
        'isCustom': isCustom,
      };

  static const List<TryOnItem> catalog = [
    TryOnItem(
      id: 'sunglass',
      name: 'Aviator Sunglasses',
      category: TryOnCategory.eyewear,
      price: 120.0,
      description: 'Classic polarized UV-protected sunglasses with titanium framing.',
      image: 'assets/sunglasses.png',
      glbAsset: 'assets/rayban_sunglasses.glb',
      arAsset: 'assets/Sunglass.deepar',
    ),
    TryOnItem(
      id: 'helmet',
      name: 'Viking Horned Helmet',
      category: TryOnCategory.headwear,
      price: 65.0,
      description: 'Ornate legendary Viking helmet with engraved horns and metallic finish.',
      image: 'assets/helmet.png',
      glbAsset: 'assets/helmet.glb',
      arAsset: 'assets/helmet.deepar',
    ),
    TryOnItem(
      id: 'shoe',
      name: 'Speedster Running Sneakers',
      category: TryOnCategory.footwear,
      price: 145.0,
      description: 'Aerodynamic breathable knit performance running shoes with responsive foam.',
      image: 'assets/shoes.png',
      glbAsset: 'assets/shoe.glb',
      arAsset: 'assets/shoe.deepar',
    ),
    TryOnItem(
      id: 'hoodie',
      name: 'Minimalist Studio Hoodie',
      category: TryOnCategory.tops,
      price: 88.0,
      description: 'Organic heavy-cotton oversized hoodie with drop shoulders and hidden seams.',
      image: 'assets/sunglasses.png',
      glbAsset: null,
      arAsset: null,
    ),
  ];

  static const List<TryOnItem> curatedResources = [
    TryOnItem(
      id: 'curated_cyber_visor',
      name: 'Cyberpunk Neon Visor',
      category: TryOnCategory.eyewear,
      price: 159.0,
      description: 'Futuristic polarized HUD eyewear with chromatic tint and titanium arms.',
      image: 'assets/sunglasses.png',
      glbAsset: 'assets/rayban_sunglasses.glb',
      isCustom: true,
    ),
    TryOnItem(
      id: 'curated_viking_crown',
      name: 'Nordic Chieftain Crown',
      category: TryOnCategory.headwear,
      price: 110.0,
      description: 'Hand-hammered brass ceremonial horned crown with embossed knotwork.',
      image: 'assets/helmet.png',
      glbAsset: 'assets/helmet.glb',
      isCustom: true,
    ),
    TryOnItem(
      id: 'curated_retro_runner',
      name: 'Retro High-Top Trail Shoe',
      category: TryOnCategory.footwear,
      price: 135.0,
      description: 'Rugged all-weather high-top sneaker with reinforced toe box and tread.',
      image: 'assets/shoes.png',
      glbAsset: 'assets/shoe.glb',
      isCustom: true,
    ),
    TryOnItem(
      id: 'curated_bomber_jacket',
      name: 'Leather Bomber Flight Jacket',
      category: TryOnCategory.tops,
      price: 220.0,
      description: 'Authentic distressed cowhide flight jacket with ribbed wool trim.',
      image: 'assets/sunglasses.png',
      glbAsset: null,
      isCustom: true,
    ),
    TryOnItem(
      id: 'curated_gold_aviator',
      name: '24K Gold Rim Aviators',
      category: TryOnCategory.eyewear,
      price: 195.0,
      description: 'Limited edition ultra-light gold alloy aviators with gradient amber lenses.',
      image: 'assets/sunglasses.png',
      glbAsset: 'assets/rayban_sunglasses.glb',
      isCustom: true,
    ),
    TryOnItem(
      id: 'curated_tactical_cap',
      name: 'Tactical Streetwear Cap',
      category: TryOnCategory.headwear,
      price: 52.0,
      description: 'Water-repellent ripstop unstructured 6-panel cap with magnetic buckle.',
      image: 'assets/helmet.png',
      glbAsset: 'assets/helmet.glb',
      isCustom: true,
    ),
  ];
}

class TryOnSession {
  const TryOnSession({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.category,
    required this.originalImage,
    required this.resultImage,
    required this.timestamp,
    required this.engineUsed,
    required this.status,
    this.durationMs = 0,
  });

  final String id;
  final String itemId;
  final String itemName;
  final TryOnCategory category;
  final String originalImage;
  final String resultImage;
  final DateTime timestamp;
  final String engineUsed;
  final String status;
  final int durationMs;

  factory TryOnSession.fromJson(Map<String, dynamic> json) => TryOnSession(
        id: json['id'] as String,
        itemId: json['itemId'] as String,
        itemName: json['itemName'] as String,
        category: TryOnCategory.fromString(json['category'] as String? ?? 'all'),
        originalImage: json['originalImage'] as String,
        resultImage: json['resultImage'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        engineUsed: json['engineUsed'] as String? ?? 'Local Compositor',
        status: json['status'] as String? ?? 'completed',
        durationMs: json['durationMs'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'itemId': itemId,
        'itemName': itemName,
        'category': category.name,
        'originalImage': originalImage,
        'resultImage': resultImage,
        'timestamp': timestamp.toUtc().toIso8601String(),
        'engineUsed': engineUsed,
        'status': status,
        'durationMs': durationMs,
      };
}
