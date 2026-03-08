class Repository {
  final String name;
  final String description;
  final String language;
  final int stargazersCount;
  final String htmlUrl; // ⬅️ Ye nayi line add karni hai

  Repository({
    required this.name,
    required this.description,
    required this.language,
    required this.stargazersCount,
    required this.htmlUrl, // ⬅️ Constructor mein bhi add karein
  });

  // API se data map karne wala function
  factory Repository.fromJson(Map<String, dynamic> json) {
    return Repository(
      name: json['name'] ?? 'No Name',
      description: json['description'] ?? 'No description provided',
      language: json['language'] ?? 'Unknown',
      stargazersCount: json['stargazers_count'] ?? 0,
      htmlUrl: json['html_url'] ?? '', // ⬅️ GitHub ki API mein 'html_url' hota hai
    );
  }
}