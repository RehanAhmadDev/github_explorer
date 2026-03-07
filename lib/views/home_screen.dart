import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/github_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  void _searchUser() {
    // Hide keyboard after searching
    FocusScope.of(context).unfocus();

    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      context.read<GithubProvider>().fetchUserData(query);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // theme for a professional GitHub-like look
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
            children: [
              // --- SEARCH BAR ---
              Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
                    ]
                ),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _searchUser(), // Enter dabane par bhi search hoga
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
              const SizedBox(height: 20),

              // Search Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                  ),
                  onPressed: _searchUser,
                  child: const Text("Search Profile", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 30),

              // --- RESULTS SECTION (Managed by Provider) ---
              Expanded(
                child: Consumer<GithubProvider>(
                  builder: (context, provider, child) {
                    // 1. Loading State
                    if (provider.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.blueGrey),
                      );
                    }

                    // 2. Error State
                    if (provider.errorMessage.isNotEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 60, color: Colors.redAccent),
                            const SizedBox(height: 15),
                            Text(provider.errorMessage, style: const TextStyle(fontSize: 16, color: Colors.black54)),
                          ],
                        ),
                      );
                    }

                    // 3. Data Fetched State (Profile Card)
                    if (provider.user != null) {
                      final user = provider.user!;
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
                              ]
                          ),
                          child: Column(
                            children: [
                              // Avatar
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: NetworkImage(user.avatarUrl),
                              ),
                              const SizedBox(height: 15),

                              // Name & Username
                              Text(user.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                              Text("@${user.login}", style: TextStyle(fontSize: 16, color: Colors.blueGrey.shade400, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 15),

                              // Bio
                              Text(
                                  user.bio,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 15, color: Colors.black87, fontStyle: FontStyle.italic)
                              ),
                              const SizedBox(height: 25),

                              // Stats Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildStatColumn("Repos", user.publicRepos, primaryColor),
                                  Container(height: 40, width: 1, color: Colors.grey.shade300),
                                  _buildStatColumn("Followers", user.followers, primaryColor),
                                  Container(height: 40, width: 1, color: Colors.grey.shade300),
                                  _buildStatColumn("Following", user.following, primaryColor),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    }

                    // 4. Initial/Empty State (Jab app khulegi)
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.code_rounded, size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 15),
                          const Text("Search for a developer to see their profile", style: TextStyle(color: Colors.black45, fontSize: 16)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function for Stats
  Widget _buildStatColumn(String label, int count, Color color) {
    return Column(
      children: [
        Text(count.toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
      ],
    );
  }
}