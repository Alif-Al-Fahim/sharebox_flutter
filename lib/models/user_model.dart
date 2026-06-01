import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String location;
  final String? profileImage;
  final DateTime createdAt;
  final List<String> favoriteTools;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.location = '',
    this.profileImage,
    required this.createdAt,
    this.favoriteTools = const [],
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      location: map['location'] ?? '',
      profileImage: map['profileImage'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      favoriteTools: List<String>.from(map['favoriteTools'] ?? []),
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'location': location,
      'profileImage': profileImage,
      'createdAt': Timestamp.fromDate(createdAt),
      'favoriteTools': favoriteTools,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? location,
    String? profileImage,
    DateTime? createdAt,
    List<String>? favoriteTools,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      favoriteTools: favoriteTools ?? this.favoriteTools,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email)';
  }
}
