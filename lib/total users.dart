import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// =============================
/// TOTAL USERS LIST PAGE
/// =============================
class TotalUsersPage extends StatefulWidget {
  final String baseUrl;
  const TotalUsersPage({super.key, required this.baseUrl});

  @override
  State<TotalUsersPage> createState() => _TotalUsersPageState();
}

class _TotalUsersPageState extends State<TotalUsersPage> {
  List<dynamic> allUsers = [];
  List<dynamic> filteredUsers = [];
  bool isLoading = false;
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchAllUsers();
  }

  /// =============================
  /// API CALLS
  /// =============================
  Future<void> fetchAllUsers() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse("${widget.baseUrl}/api/user-list/"));
      if (response.statusCode == 200) {
        final users = jsonDecode(response.body);
        setState(() {
          allUsers = users;
          filteredUsers = users;
        });
      }
    } catch (e) {
      debugPrint("Fetch all users error: $e");
      _showErrorSnackBar("Failed to load users");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> manageUser(int id, String action) async {
    try {
      final response = await http.post(
        Uri.parse("${widget.baseUrl}/api/manage-user/$id/"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"action": action}),
      );

      if (response.statusCode == 200) {
        _showSuccessSnackBar("User ${action == "block" ? "blocked" : action == "unblock" ? "unblocked" : "deleted"} successfully");
        fetchAllUsers(); // Refresh the list
      } else {
        _showErrorSnackBar("Failed to $action user");
      }
    } catch (e) {
      debugPrint("Manage user error: $e");
      _showErrorSnackBar("Network error - failed to $action user");
    }
  }

  /// =============================
  /// HELPER METHODS
  /// =============================
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _filterUsers(String query) {
    setState(() {
      isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        filteredUsers = allUsers;
      } else {
        filteredUsers = allUsers.where((user) {
          final name = user["name"]?.toString().toLowerCase() ?? "";
          final email = user["email"]?.toString().toLowerCase() ?? "";
          return name.contains(query.toLowerCase()) ||
              email.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Color _getUserColor(String name) {
    final colors = [
      Colors.blueAccent,
      Colors.purpleAccent,
      Colors.orangeAccent,
      Colors.greenAccent,
      Colors.pinkAccent,
      Colors.teal,
      Colors.indigoAccent,
      Colors.amber,
      Colors.cyan,
      Colors.deepPurple,
    ];
    final index = name.length % colors.length;
    return colors[index];
  }

  /// =============================
  /// UI COMPONENTS
  /// =============================
  Widget _buildUserStats() {
    final totalUsers = allUsers.length;
    final activeUsers = allUsers.where((user) => user["is_blocked"] != true).length;
    final blockedUsers = allUsers.where((user) => user["is_blocked"] == true).length;
    final reportedUsers = allUsers.where((user) => (user["report_count"] ?? 0) > 0).length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatItem("Total Users", totalUsers.toString(), Icons.people, Colors.blue),
            const SizedBox(width: 12),
            _buildStatItem("Active", activeUsers.toString(), Icons.check_circle, Colors.green),
            const SizedBox(width: 12),
            _buildStatItem("Blocked", blockedUsers.toString(), Icons.block, Colors.red),
            const SizedBox(width: 12),
            _buildStatItem("Reported", reportedUsers.toString(), Icons.flag, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: "Search users by name or email...",
          prefixIcon: const Icon(Icons.search),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              searchController.clear();
              _filterUsers("");
            },
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        onChanged: _filterUsers,
      ),
    );
  }

  Widget userCard(dynamic user) {
    final bool isBlocked = user["is_blocked"] ?? false;
    final int reportCount = user["report_count"] ?? 0;
    final String joinDate = user["joined_date"] ?? "Unknown";
    final String username = user["name"] ?? "Unknown User";
    final String email = user["email"] ?? "No email";

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Stack(
          children: [
            // Enhanced CircleAvatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    _getUserColor(username),
                    _getUserColor(username).withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getUserColor(username).withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: isBlocked ? Colors.red : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  username[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            if (isBlocked)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.block, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
        title: Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 2),
            Row(
              children: [
                Text("Joined $joinDate", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                if (reportCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text("$reportCount reports",
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.grey),
          onSelected: (action) => manageUser(user["id"], action),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: isBlocked ? "unblock" : "block",
              child: Row(
                children: [
                  Icon(isBlocked ? Icons.lock_open : Icons.block,
                      color: isBlocked ? Colors.green : Colors.red),
                  const SizedBox(width: 8),
                  Text(isBlocked ? "Unblock User" : "Block User"),
                ],
              ),
            ),
            if (reportCount > 0)
              PopupMenuItem(
                value: "report",
                child: Row(
                  children: [
                    const Icon(Icons.flag, color: Colors.orange),
                    const SizedBox(width: 8),
                    const Text("Report Details"),
                  ],
                ),
              ),
            PopupMenuItem(
              value: "delete",
              child: Row(
                children: [
                  const Icon(Icons.delete, color: Colors.red),
                  const SizedBox(width: 8),
                  Text("Delete User", style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// =============================
  /// BUILD METHOD
  /// =============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(
          "All Users ",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
            size: 18,),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // User Statistics
          _buildUserStats(),

          // Search Bar
          _buildSearchBar(),

          // Users List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredUsers.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSearching ? Icons.search_off : Icons.people_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isSearching ? "No users found" : "No users available",
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  if (isSearching) ...[
                    const SizedBox(height: 8),
                    const Text(
                      "Try different search terms",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: fetchAllUsers,
              child: ListView.builder(
                itemCount: filteredUsers.length,
                itemBuilder: (_, index) => userCard(filteredUsers[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}