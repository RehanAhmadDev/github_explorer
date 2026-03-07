import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/github_user.dart';

class ApiService {
  // GitHub API ka main link
  static const String baseUrl = 'https://api.github.com/users/';

  // Ye function username le kar server par request bheje ga
  Future<GitHubUser?> fetchUser(String username) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$username'));

      // HTTP Status 200 ka matlab hai request kamyab ho gayi
      if (response.statusCode == 200) {
        // String data ko JSON (Map) mein convert kar rahay hain
        final Map<String, dynamic> data = json.decode(response.body);

        // JSON ko apne Model mein daal kar wapis bhej rahay hain
        return GitHubUser.fromJson(data);
      } else {
        // Agar user na mile (jaise 404 Not Found)
        return null;
      }
    } catch (e) {
      // Agar internet na ho ya koi aur masla aaye
      throw Exception('Failed to connect to API: $e');
    }
  }
}