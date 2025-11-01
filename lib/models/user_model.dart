import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String rollNumber;
  final double walletBalance;
  final bool isAdmin;
  final List<String> preferences;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.rollNumber,
    this.walletBalance = 0.0,
    this.isAdmin = false,
    this.preferences = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'rollNumber': rollNumber,
      'walletBalance': walletBalance,
      'isAdmin': isAdmin,
      'preferences': preferences,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      rollNumber: map['rollNumber'] ?? '',
      walletBalance: (map['walletBalance'] ?? 0).toDouble(),
      isAdmin: map['isAdmin'] ?? false,
      preferences: List<String>.from(map['preferences'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? rollNumber,
    double? walletBalance,
    bool? isAdmin,
    List<String>? preferences,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      rollNumber: rollNumber ?? this.rollNumber,
      walletBalance: walletBalance ?? this.walletBalance,
      isAdmin: isAdmin ?? this.isAdmin,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt,
    );
  }
}