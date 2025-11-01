import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAdmin => _user?.isAdmin ?? false;

  Future<void> loadUser() async {
    _isLoading = true;
    notifyListeners();

    _user = await AuthService().getUserData();

    _isLoading = false;
    notifyListeners();
  }

  void setUser(UserModel? user) {
    _user = user;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }

  // Listen to user changes
  void listenToUserChanges(String userId) {
    DatabaseService().getUserStream(userId).listen((user) {
      _user = user;
      notifyListeners();
    });
  }
}