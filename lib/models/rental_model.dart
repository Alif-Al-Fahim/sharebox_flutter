import 'package:cloud_firestore/cloud_firestore.dart';

enum RentalStatus {
  pending,
  accepted,
  active,
  completed,
  cancelled,
}

extension RentalStatusExtension on RentalStatus {
  String get displayName {
    switch (this) {
      case RentalStatus.pending:
        return 'Pending';
      case RentalStatus.accepted:
        return 'Accepted';
      case RentalStatus.active:
        return 'Active';
      case RentalStatus.completed:
        return 'Completed';
      case RentalStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get emoji {
    switch (this) {
      case RentalStatus.pending:
        return '⏳';
      case RentalStatus.accepted:
        return '✅';
      case RentalStatus.active:
        return '🔄';
      case RentalStatus.completed:
        return '🎉';
      case RentalStatus.cancelled:
        return '❌';
    }
  }
}

class RentalModel {
  final String id;
  final String toolId;
  final String toolName;
  final String? toolImage;
  final String ownerId;
  final String ownerName;
  final String renterId;
  final String renterName;
  final RentalStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final double pricePerDay;
  final String? message;
  final DateTime createdAt;

  const RentalModel({
    required this.id,
    required this.toolId,
    required this.toolName,
    this.toolImage,
    required this.ownerId,
    required this.ownerName,
    required this.renterId,
    required this.renterName,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.pricePerDay,
    this.message,
    required this.createdAt,
  });

  factory RentalModel.fromMap(Map<String, dynamic> map, String id) {
    return RentalModel(
      id: id,
      toolId: map['toolId'] ?? '',
      toolName: map['toolName'] ?? '',
      toolImage: map['toolImage'],
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      renterId: map['renterId'] ?? '',
      renterName: map['renterName'] ?? '',
      status: RentalStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RentalStatus.pending,
      ),
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      pricePerDay: (map['pricePerDay'] ?? 0).toDouble(),
      message: map['message'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory RentalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return RentalModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'toolId': toolId,
      'toolName': toolName,
      'toolImage': toolImage,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'renterId': renterId,
      'renterName': renterName,
      'status': status.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'totalPrice': totalPrice,
      'pricePerDay': pricePerDay,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  RentalModel copyWith({
    String? id,
    String? toolId,
    String? toolName,
    String? toolImage,
    String? ownerId,
    String? ownerName,
    String? renterId,
    String? renterName,
    RentalStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    double? totalPrice,
    double? pricePerDay,
    String? message,
    DateTime? createdAt,
  }) {
    return RentalModel(
      id: id ?? this.id,
      toolId: toolId ?? this.toolId,
      toolName: toolName ?? this.toolName,
      toolImage: toolImage ?? this.toolImage,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      renterId: renterId ?? this.renterId,
      renterName: renterName ?? this.renterName,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalPrice: totalPrice ?? this.totalPrice,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  int get durationDays => endDate.difference(startDate).inDays + 1;

  String get formattedTotalPrice => '৳${totalPrice.toStringAsFixed(0)}';

  @override
  String toString() {
    return 'RentalModel(id: $id, toolId: $toolId, status: $status)';
  }
}
