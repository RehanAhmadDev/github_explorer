import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    _loadHistory(); // App start hote hi history load karein
  }

  // --- Memory se History Load karne ka function ---
  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('search_history') ?? [];
    });

    // Agar history mein kuch hai to latest search auto-load karein
    if (_recentSearches.isNotEmpty) {
      _searchController.text = _recentSearches.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<GithubProvider>().fetchUserData(_recentSearches.first);
      });
    }
  }

  // --- Search aur History Save karne ka main function ---
  void _searchUser(String query) async {
    query = query.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();

    // 1. API Call
    context.read<GithubProvider>().fetchUserData(query);

    // 2. Local History Update
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches.removeWhere((item) => item.toLowerCase() == query.toLowerCase());
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 5) _recentSearches.removeLast();
    });

    // 3. Save to Disk
    await prefs.setStringList('search_history', _recentSearches);
  }

  // --- Single item delete karne ke liye ---
  void _deleteHistoryItem(String name) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches.remove(name);
    });
    await prefs.setStringList('search_history', _recentSearches);
  }

  // --- Puri history saaf karne ke liye ---
  void _clearAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches.clear();
      _searchController.clear();
      context.read<GithubProvider>().clearData();
    });
    await prefs.remove('search_history');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.blueGrey.shade800;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('GitHub Explorer', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: primaryColor,
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]
                ),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (value) => _searchUser(value),
                  decoration: InputDecoration(
                    hintText: 'Enter GitHub Username...',
                    prefixIcon: Icon(Icons.search_rounded, color: primaryColor),
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

              // --- RECENT SEARCHES (History Chips) ---
              if (_recentSearches.isNotEmpty) ...[
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Recent Searches", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
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
                        avatar: const Icon(Icons.history, size: 14, color: Colors.blueGrey),
                        label: Text(name, style: const TextStyle(fontSize: 12)),
                        onPressed: () {
                          _searchController.text = name;
                          _searchUser(name);
                        },
                        onDeleted: () => _deleteHistoryItem(name),
                        deleteIcon: const Icon(Icons.cancel, size: 14),
                        backgroundColor: Colors.white,
                        elevation: 1,
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
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                  ),
                  onPressed: () => _searchUser(_searchController.text),
                  child: const Text("Search Profile", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 25),

              // --- RESULTS SECTION ---
              Expanded(
                child: Consumer<GithubProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const Center(child: CircularProgressIndicator(color: Colors.blueGrey));
                    }

                    if (provider.errorMessage.isNotEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.info_outline, size: 50, color: Colors.grey),
                            const SizedBox(height: 10),
                            Text(provider.errorMessage),
                          ],
                        ),
                      );
                    }

                    if (provider.user != null) {
                      final user = provider.user!;
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Header Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))]
                              ),
                              child: Column(
                                children: [
                                  CircleAvatar(radius: 45, backgroundImage: NetworkImage(user.avatarUrl)),
                                  const SizedBox(height: 15),
                                  Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  Text("@${user.login}", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 10),
                                  Text(user.bio, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.black54)),
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

                            // Repositories List
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: provider.repositories.length,
                              itemBuilder: (context, index) {
                                final repo = provider.repositories[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    title: Text(repo.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                    subtitle: Text(repo.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.star_border, size: 18, color: Colors.amber),
                                        Text("${repo.stargazersCount}", style: const TextStyle(fontSize: 12)),
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

                    return const Center(child: Text("Search for a GitHub user to see details"));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, int count) {
    return Column(
      children: [
        Text(count.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}