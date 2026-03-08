import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart'; // ⬅️ Shimmer package zaroori hai
import '../viewmodels/github_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('search_history') ?? [];
    });
    if (_recentSearches.isNotEmpty) {
      _searchController.text = _recentSearches.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<GithubProvider>().fetchUserData(_recentSearches.first);
      });
    }
  }

  void _searchUser(String query) async {
    query = query.trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    context.read<GithubProvider>().fetchUserData(query);
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches.removeWhere((item) => item.toLowerCase() == query.toLowerCase());
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 5) _recentSearches.removeLast();
    });
    await prefs.setStringList('search_history', _recentSearches);
  }

  void _deleteHistoryItem(String name) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches.remove(name);
    });
    await prefs.setStringList('search_history', _recentSearches);
  }

  void _clearAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches.clear();
      _searchController.clear();
      context.read<GithubProvider>().clearData();
    });
    await prefs.remove('search_history');
  }

  // --- NAYA FUNCTION: Language ke hisab se color dene ke liye ---
  Color _getLanguageColor(String? lang) {
    if (lang == null) return Colors.grey;
    switch (lang.toLowerCase()) {
      case 'dart': return Colors.blue;
      case 'java': return Colors.orange;
      case 'python': return Colors.blue.shade900;
      case 'javascript': return Colors.yellow.shade700;
      case 'html': return Colors.redAccent;
      case 'css': return Colors.deepPurpleAccent;
      case 'kotlin': return Colors.purple;
      case 'swift': return Colors.orangeAccent;
      default: return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme colors for Dark/Light mode support
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF161B22) : Colors.white;
    final scaffoldBg = isDark ? const Color(0xFF0D1117) : Colors.grey.shade100;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text('GitHub Explorer', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF010409) : Colors.blueGrey.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SEARCH BAR ---
              Container(
                decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                    ]
                ),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (value) => _searchUser(value),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Enter GitHub Username...',
                    hintStyle: TextStyle(color: isDark ? Colors.grey : Colors.black54),
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.blueAccent),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        context.read<GithubProvider>().clearData();
                      },
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
              ),

              // --- HISTORY CHIPS ---
              if (_recentSearches.isNotEmpty) ...[
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Recent", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    GestureDetector(
                      onTap: _clearAllHistory,
                      child: const Text("Clear All", style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _recentSearches.map((name) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: InputChip(
                        label: Text(name, style: const TextStyle(fontSize: 12)),
                        onPressed: () {
                          _searchController.text = name;
                          _searchUser(name);
                        },
                        onDeleted: () => _deleteHistoryItem(name),
                        backgroundColor: cardColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    )).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 15),

              // Search Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                  ),
                  onPressed: () => _searchUser(_searchController.text),
                  child: const Text("Search Profile", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 25),

              // --- RESULTS SECTION ---
              Expanded(
                child: Consumer<GithubProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return _buildShimmerLoading(isDark); // ⬅️ Naya Shimmer Call
                    }

                    if (provider.errorMessage.isNotEmpty) {
                      return Center(child: Text(provider.errorMessage, style: const TextStyle(color: Colors.grey)));
                    }

                    if (provider.user != null) {
                      final user = provider.user!;
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                children: [
                                  CircleAvatar(radius: 45, backgroundImage: NetworkImage(user.avatarUrl)),
                                  const SizedBox(height: 15),
                                  Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  Text("@${user.login}", style: const TextStyle(color: Colors.blueAccent)),
                                  const SizedBox(height: 10),
                                  Text(user.bio, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildStat("Repos", user.publicRepos),
                                      _buildStat("Followers", user.followers),
                                      _buildStat("Following", user.following),
                                    ],
                                  )
                                ],
                              ),
                            ),

                            const SizedBox(height: 25),
                            const Text("Repositories", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),

                            // Updated Repos List with Language Colors
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: provider.repositories.length,
                              itemBuilder: (context, index) {
                                final repo = provider.repositories[index];
                                return Card(
                                  color: cardColor,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(15),
                                    title: Text(repo.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 5),
                                        Text(repo.description, maxLines: 2),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Container(
                                              width: 10, height: 10,
                                              decoration: BoxDecoration(shape: BoxShape.circle, color: _getLanguageColor(repo.language)),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(repo.language, style: const TextStyle(fontSize: 12)),
                                            const SizedBox(width: 15),
                                            const Icon(Icons.star_border, size: 14, color: Colors.amber),
                                            Text(" ${repo.stargazersCount}", style: const TextStyle(fontSize: 12)),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                          ],
                        ),
                      );
                    }
                    return const Center(child: Text("Search for a developer"));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI WIDGETS ---

  Widget _buildStat(String label, int count) {
    return Column(
      children: [
        Text(count.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  // --- SHIMMER LOADING UI ---
  Widget _buildShimmerLoading(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade900 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(height: 180, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 30),
            ListView.builder(
              shrinkWrap: true,
              itemCount: 4,
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}