import 'package:flutter/material.dart';
import '../models/github_user.dart';
import '../services/api_service.dart';

class GithubProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // State variables
  GitHubUser? _user;
  bool _isLoading = false;
  String _errorMessage = '';

  // Getters for the UI to access the state
  GitHubUser? get user => _user;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Function called from the UI when user taps "Search"
  Future<void> fetchUserData(String username) async {
    if (username.trim().isEmpty) return;

    // Set loading state and clear previous errors/data
    _isLoading = true;
    _errorMessage = '';
    _user = null;
    notifyListeners(); // Update the UI to show a loading spinner

    try {
      final fetchedUser = await _apiService.fetchUser(username);

      if (fetchedUser != null) {
        _user = fetchedUser; // Data successfully fetched
      } else {
        _errorMessage = 'User not found. Please check the username.';
      }
    } catch (e) {
      _errorMessage = 'An error occurred. Check your internet connection.';
    } finally {
      // Whether success or error, stop the loading spinner
      _isLoading = false;
      notifyListeners();
    }
  }

  // Optional: Function to clear the screen
  void clearData() {
    _user = null;
    _errorMessage = '';
    _isLoading = false;
    notifyListeners();
  }
}