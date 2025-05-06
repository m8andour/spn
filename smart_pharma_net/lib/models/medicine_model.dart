class MedicineModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final int quantity;
  final String pharmacyId;
  final String category;
  final String expiryDate;
  final bool canBeSell;
  final int quantityToSell;
  final double priceSell;

  MedicineModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.pharmacyId,
    required this.category,
    required this.expiryDate,
    required this.canBeSell,
    required this.quantityToSell,
    required this.priceSell,
  });

  factory MedicineModel.fromJson(Map<String, dynamic> json) {
    return MedicineModel(
      id: json['id'].toString(),
      name: json['name'] as String,
      description: json['description'] as String,
      price: double.parse(json['price'].toString()),
      quantity: int.parse(json['quantity'].toString()),
      pharmacyId: (json['pharmacy'] ?? json['pharmacy_id']).toString(),
      category: json['category'] as String,
      expiryDate: json['exp_date'] as String,
      canBeSell: json['can_be_sell'] as bool,
      quantityToSell: int.parse(json['quantity_to_sell'].toString()),
      priceSell: double.parse(json['price_sell'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
      'pharmacy': int.parse(pharmacyId),
      'category': category,
      'exp_date': expiryDate,
      'can_be_sell': canBeSell,
      'quantity_to_sell': quantityToSell,
      'price_sell': priceSell,
    };
  }

  MedicineModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    int? quantity,
    String? pharmacyId,
    String? category,
    String? expiryDate,
    bool? canBeSell,
    int? quantityToSell,
    double? priceSell,
  }) {
    return MedicineModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      category: category ?? this.category,
      expiryDate: expiryDate ?? this.expiryDate,
      canBeSell: canBeSell ?? this.canBeSell,
      quantityToSell: quantityToSell ?? this.quantityToSell,
      priceSell: priceSell ?? this.priceSell,
    );
  }
} 