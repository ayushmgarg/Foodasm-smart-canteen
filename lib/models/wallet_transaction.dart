import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  credit,
  debit,
}

enum TransactionStatus {
  pending,
  approved,
  rejected,
}

class WalletTransaction {
  final String id;
  final String userId;
  final String userName;
  final double amount;
  final TransactionType type;
  final String description;
  final DateTime timestamp;
  final TransactionStatus status;
  final String? paymentNumber; // UPI/Payment reference
  final String? rejectionReason;

  WalletTransaction({
    required this.id,
    required this.userId,
    required this.userName,
    required this.amount,
    required this.type,
    required this.description,
    DateTime? timestamp,
    this.status = TransactionStatus.pending,
    this.paymentNumber,
    this.rejectionReason,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'amount': amount,
      'type': type.name,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status.name,
      'paymentNumber': paymentNumber,
      'rejectionReason': rejectionReason,
    };
  }

  factory WalletTransaction.fromMap(String id, Map<String, dynamic> map) {
    return WalletTransaction(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.credit,
      ),
      description: map['description'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TransactionStatus.pending,
      ),
      paymentNumber: map['paymentNumber'],
      rejectionReason: map['rejectionReason'],
    );
  }

  WalletTransaction copyWith({
    TransactionStatus? status,
    String? rejectionReason,
  }) {
    return WalletTransaction(
      id: id,
      userId: userId,
      userName: userName,
      amount: amount,
      type: type,
      description: description,
      timestamp: timestamp,
      status: status ?? this.status,
      paymentNumber: paymentNumber,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}