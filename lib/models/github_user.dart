class GitHubUser {
  final String login;
  final String avatarUrl;
  final String name;
  final String bio;
  final int publicRepos;
  final int followers;
  final int following;

  GitHubUser({
    required this.login,
    required this.avatarUrl,
    required this.name,
    required this.bio,
    required this.publicRepos,
    required this.followers,
    required this.following,
  });

  // Internet se aane wale JSON data ko Dart object mein convert karne ka function
  factory GitHubUser.fromJson(Map<String, dynamic> json) {
    return GitHubUser(
      // Agar API se koi value null aaye, to hum default value de rahe hain
      login: json['login'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
      name: json['name'] ?? 'Name not provided',
      bio: json['bio'] ?? 'No bio available',
      publicRepos: json['public_repos'] ?? 0,
      followers: json['followers'] ?? 0,
      following: json['following'] ?? 0,
    );
  }
}