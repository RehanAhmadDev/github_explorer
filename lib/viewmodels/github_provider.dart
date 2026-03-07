import 'package:flutter/material.dart';
import '../models/github_user.dart';
import '../models/repository.dart'; // Naya model import kiya
import '../services/api_service.dart';

class GithubProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  GitHubUser? _user;
  List<Repository> _repositories = []; // ⬅️ Nayi list banayi
  bool _isLoading = false;
  String _errorMessage = '';

  GitHubUser? get user => _user;
  List<Repository> get repositories => _repositories; // ⬅️ UI ke liye Getter
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> fetchUserData(String username) async {
    if (username.trim().isEmpty) return;

    _isLoading = true;
    _errorMessage = '';
    _user = null;
    _repositories = []; // ⬅️ Nayi search par purani list clear karein
    notifyListeners();

    try {
      final fetchedUser = await _apiService.fetchUser(username);

      if (fetchedUser != null) {
        _user = fetchedUser;
        // ⬅️ Jab user mil jaye, to uski repositories bhi fetch kar lo
        _repositories = await _apiService.fetchRepositories(username);
      } else {
        _errorMessage = 'User not found. Please check the username.';
      }
    } catch (e) {
      _errorMessage = 'An error occurred. Check your internet connection.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearData() {
    _user = null;
    _repositories = []; // ⬅️ Clear karte waqt list bhi empty karein
    _errorMessage = '';
    _isLoading = false;
    notifyListeners();
  }
}