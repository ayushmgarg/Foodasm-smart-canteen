import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

 // Sign Up - FIXED TO ENSURE WALLET BALANCE
Future<UserModel?> signUp({
  required String email,
  required String password,
  required String name,
  required String rollNumber,
}) async {
  try {
    print('🔵 Starting signup for: $email');
    
    UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    User? user = result.user;
    if (user != null) {
      print('✅ Firebase Auth user created: ${user.uid}');
      
      UserModel newUser = UserModel(
        uid: user.uid,
        email: email,
        name: name,
        rollNumber: rollNumber,
        walletBalance: 100.0, // ← ENSURE THIS IS SET!
        isAdmin: false,
      );

      print('📝 Creating Firestore document with ₹100 balance...');
      
      // Create user document
      await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
      
      print('✅ Firestore document created successfully');
      
      // CRITICAL: Verify it was created with correct balance
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        print('✅ Verified: Document exists in Firestore');
        print('💰 Wallet Balance: ${data?['walletBalance']}');
        
        if (data?['walletBalance'] == 100.0) {
          print('✅ Wallet balance confirmed: ₹100');
        } else {
          print('⚠️ WARNING: Wallet balance not set correctly!');
        }
        
        return newUser;
      } else {
        print('❌ ERROR: Document not found after creation!');
        throw Exception('Failed to create user document');
      }
    }
  } catch (e) {
    print('❌ Sign up error: $e');
    rethrow;
  }
  return null;
}

// Sign In
Future<UserModel?> signIn({
  required String email,
  required String password,
}) async {
  try {
    print('🔵 Starting signin for: $email');
    
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    print('✅ Firebase Auth signin successful');
    
    // Force load user data
    final user = await getUserData();
    
    if (user == null) {
      print('❌ ERROR: User data not found in Firestore!');
      throw Exception('User data not found. Please contact support.');
    }
    
    print('✅ User data loaded: ${user.name}');
    print('💰 Wallet Balance: ₹${user.walletBalance}');
    return user;
  } catch (e) {
    print('❌ Sign in error: $e');
    rethrow;
  }
}

  // Get User Data
  Future<UserModel?> getUserData() async {
  try {
    User? user = currentUser;
    if (user != null) {
      print('📄 Getting user data for UID: ${user.uid}');
      
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      
      print('📄 Document exists: ${doc.exists}');
      
      if (doc.exists && doc.data() != null) {
        final userData = doc.data() as Map<String, dynamic>;
        print('✅ User data loaded: ${userData['name']}');
        print('💰 Wallet Balance: ₹${userData['walletBalance']}');
        
        return UserModel.fromMap(userData);
      } else {
        print('❌ No user document found, creating one...');
        
        // Create user document if it doesn't exist
        final newUser = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? 'User',
          rollNumber: 'NEW${DateTime.now().millisecondsSinceEpoch}',
          walletBalance: 100.0,
        );
        
        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        print('✅ Created new user document with ₹100 balance');
        
        return newUser;
      }
    }
  } catch (e) {
    print('❌ Get user data error: $e');
  }
  return null;
}

  // Update User
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update(user.toMap());
      print('✅ User updated successfully');
    } catch (e) {
      print('❌ Update user error: $e');
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
    print('👋 User signed out');
  }

  // Create Admin (Run this once to create an admin account)
  Future<void> createAdminAccount() async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: 'admin@canteen.com',
        password: 'Admin@123',
      );

      User? user = result.user;
      if (user != null) {
        UserModel admin = UserModel(
          uid: user.uid,
          email: 'admin@canteen.com',
          name: 'Admin',
          rollNumber: 'ADMIN001',
          walletBalance: 0,
          isAdmin: true,
        );

        await _firestore.collection('users').doc(user.uid).set(admin.toMap());
        print('✅ Admin account created');
      }
    } catch (e) {
      print('❌ Create admin error: $e');
    }
  }
}