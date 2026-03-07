class Repository {
  final String name;
  final String description;
  final String language;
  final int stargazersCount;

  Repository({
    required this.name,
    required this.description,
    required this.language,
    required this.stargazersCount,
  });

  factory Repository.fromJson(Map<String, dynamic> json) {
    return Repository(
      name: json['name'] ?? 'Unnamed Repo',
      description: json['description'] ?? 'No description provided',
      language: json['language'] ?? 'Unknown',
      stargazersCount: json['stargazers_count'] ?? 0,
    );
  }
}