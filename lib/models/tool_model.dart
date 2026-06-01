import 'package:cloud_firestore/cloud_firestore.dart';

enum ToolCategory {
  powerTools,
  handTools,
  gardenTools,
  constructionTools,
  automotiveTools,
  cleaningTools,
  electricalTools,
  plumbingTools,
  other,
}

extension ToolCategoryExtension on ToolCategory {
  String get displayName {
    switch (this) {
      case ToolCategory.powerTools:
        return 'Power Tools';
      case ToolCategory.handTools:
        return 'Hand Tools';
      case ToolCategory.gardenTools:
        return 'Garden Tools';
      case ToolCategory.constructionTools:
        return 'Construction';
      case ToolCategory.automotiveTools:
        return 'Automotive';
      case ToolCategory.cleaningTools:
        return 'Cleaning';
      case ToolCategory.electricalTools:
        return 'Electrical';
      case ToolCategory.plumbingTools:
        return 'Plumbing';
      case ToolCategory.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case ToolCategory.powerTools:
        return '⚡';
      case ToolCategory.handTools:
        return '🔨';
      case ToolCategory.gardenTools:
        return '🌿';
      case ToolCategory.constructionTools:
        return '🏗️';
      case ToolCategory.automotiveTools:
        return '🔧';
      case ToolCategory.cleaningTools:
        return '🧹';
      case ToolCategory.electricalTools:
        return '💡';
      case ToolCategory.plumbingTools:
        return '🔩';
      case ToolCategory.other:
        return '🛠️';
    }
  }
}

class ToolModel {
  final String id;
  final String name;
  final ToolCategory category;
  final double pricePerDay;
  final String description;
  final List<String> images;
  final String ownerId;
  final String ownerName;
  final String? ownerImage;
  final String location;
  final bool isAvailable;
  final DateTime createdAt;
  final double? rating;
  final int reviewCount;
  final int totalRentals;

  const ToolModel({
    required this.id,
    required this.name,
    required this.category,
    required this.pricePerDay,
    required this.description,
    required this.images,
    required this.ownerId,
    required this.ownerName,
    this.ownerImage,
    required this.location,
    this.isAvailable = true,
    required this.createdAt,
    this.rating,
    this.reviewCount = 0,
    this.totalRentals = 0,
  });

  factory ToolModel.fromMap(Map<String, dynamic> map, String id) {
    return ToolModel(
      id: id,
      name: map['name'] ?? '',
      category: ToolCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ToolCategory.other,
      ),
      pricePerDay: (map['pricePerDay'] ?? 0).toDouble(),
      description: map['description'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      ownerImage: map['ownerImage'],
      location: map['location'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rating: map['rating']?.toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      totalRentals: map['totalRentals'] ?? 0,
    );
  }

  factory ToolModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ToolModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category.name,
      'pricePerDay': pricePerDay,
      'description': description,
      'images': images,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerImage': ownerImage,
      'location': location,
      'isAvailable': isAvailable,
      'createdAt': Timestamp.fromDate(createdAt),
      'rating': rating,
      'reviewCount': reviewCount,
      'totalRentals': totalRentals,
    };
  }

  ToolModel copyWith({
    String? id,
    String? name,
    ToolCategory? category,
    double? pricePerDay,
    String? description,
    List<String>? images,
    String? ownerId,
    String? ownerName,
    String? ownerImage,
    String? location,
    bool? isAvailable,
    DateTime? createdAt,
    double? rating,
    int? reviewCount,
    int? totalRentals,
  }) {
    return ToolModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      description: description ?? this.description,
      images: images ?? this.images,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerImage: ownerImage ?? this.ownerImage,
      location: location ?? this.location,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      totalRentals: totalRentals ?? this.totalRentals,
    );
  }

  String get formattedPrice => '৳${pricePerDay.toStringAsFixed(0)}/day';

  @override
  String toString() {
    return 'ToolModel(id: $id, name: $name, price: $pricePerDay)';
  }
}
