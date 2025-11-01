import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/wallet_transaction.dart';

class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Student: Request to add money
  Future<bool> requestAddMoney({
    required String userId,
    required String userName,
    required double amount,
    required String paymentNumber,
  }) async {
    try {
      // Create transaction request
      WalletTransaction transaction = WalletTransaction(
        id: _uuid.v4(),
        userId: userId,
        userName: userName,
        amount: amount,
        type: TransactionType.credit,
        description: 'Add money request',
        status: TransactionStatus.pending,
        paymentNumber: paymentNumber,
      );

      await _firestore
          .collection('wallet_requests')
          .doc(transaction.id)
          .set(transaction.toMap());

      return true;
    } catch (e) {
      print('Request add money error: $e');
      rethrow;
    }
  }

  // Admin: Get all pending requests
  Stream<List<WalletTransaction>> getPendingRequests() {
    return _firestore
        .collection('wallet_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => WalletTransaction.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // Admin: Approve request
  Future<void> approveRequest(WalletTransaction transaction) async {
    try {
      // Update user wallet
      final userDoc = await _firestore.collection('users').doc(transaction.userId).get();
      final userData = UserModel.fromMap(userDoc.data()!);
      
      final newBalance = userData.walletBalance + transaction.amount;
      
      await _firestore.collection('users').doc(transaction.userId).update({
        'walletBalance': newBalance,
      });

      // Update request status
      await _firestore
          .collection('wallet_requests')
          .doc(transaction.id)
          .update({
        'status': TransactionStatus.approved.name,
      });

      // Create transaction record
      await _firestore
          .collection('transactions')
          .doc(transaction.id)
          .set(transaction.copyWith(status: TransactionStatus.approved).toMap());
    } catch (e) {
      print('Approve request error: $e');
      rethrow;
    }
  }

  // Admin: Reject request
  Future<void> rejectRequest(WalletTransaction transaction, String reason) async {
    try {
      await _firestore
          .collection('wallet_requests')
          .doc(transaction.id)
          .update({
        'status': TransactionStatus.rejected.name,
        'rejectionReason': reason,
      });
    } catch (e) {
      print('Reject request error: $e');
      rethrow;
    }
  }

  // Deduct Money from Wallet (for orders)
  Future<void> deductMoney({
    required String userId,
    required String userName,
    required double amount,
    required String description,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = UserModel.fromMap(userDoc.data()!);

      if (userData.walletBalance < amount) {
        throw Exception('Insufficient balance');
      }

      final newBalance = userData.walletBalance - amount;
      await _firestore.collection('users').doc(userId).update({
        'walletBalance': newBalance,
      });

      // Create transaction record
      WalletTransaction transaction = WalletTransaction(
        id: _uuid.v4(),
        userId: userId,
        userName: userName,
        amount: amount,
        type: TransactionType.debit,
        description: description,
        status: TransactionStatus.approved,
      );

      await _firestore
          .collection('transactions')
          .doc(transaction.id)
          .set(transaction.toMap());
    } catch (e) {
      print('Deduct money error: $e');
      rethrow;
    }
  }

  // Get Transaction History
  Stream<List<WalletTransaction>> getTransactions(String userId) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final transactions = snapshot.docs
          .map((doc) => WalletTransaction.fromMap(doc.id, doc.data()))
          .toList();
      
      transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return transactions;
    });
  }

  // Get user's pending requests
  Stream<List<WalletTransaction>> getUserRequests(String userId) {
    return _firestore
        .collection('wallet_requests')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final requests = snapshot.docs
          .map((doc) => WalletTransaction.fromMap(doc.id, doc.data()))
          .toList();
      
      requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return requests;
    });
  }
}