import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/github_user.dart';
import '../models/repository.dart'; // Naya model import kiya

class ApiService {
  static const String baseUrl = 'https://api.github.com/users/';

  // 1. User detail fetch karne ka purana function
  Future<GitHubUser?> fetchUser(String username) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$username'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return GitHubUser.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Failed to connect to API: $e');
    }
  }

  // 2. Naya function: Repositories fetch karne ke liye
  Future<List<Repository>> fetchRepositories(String username) async {
    try {
      // ?sort=updated is liye lagaya taake latest projects sab se upar aayen
      final response = await http.get(Uri.parse('$baseUrl$username/repos?sort=updated'));

      if (response.statusCode == 200) {
        // API se List of JSON objects aa rahi hai
        List<dynamic> data = json.decode(response.body);

        // Har JSON object ko Repository model mein convert kar ke List bana rahay hain
        return data.map((json) => Repository.fromJson(json)).toList();
      } else {
        return []; // Agar koi repo na mile ya error ho to khali list bhej do
      }
    } catch (e) {
      throw Exception('Failed to fetch repositories: $e');
    }
  }
}