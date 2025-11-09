import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// =============================
/// BLOCKED USERS PAGE - ENHANCED
/// =============================
class BlockedUsersPage extends StatefulWidget {
  final String baseUrl;
  const BlockedUsersPage({super.key, required this.baseUrl});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  List<dynamic> blockedUsers = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchBlockedUsers();
  }

  /// =============================
  /// API CALLS - CORRECTED
  /// =============================

  // Option 1: If you have a dedicated endpoint for blocked users
  Future<void> fetchBlockedUsers() async {
    setState(() => isLoading = true);
    try {
      // Try dedicated blocked users endpoint first
      final response = await http.get(Uri.parse("${widget.baseUrl}/api/blocked-users/"));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => blockedUsers = data is List ? data : []);
      } else if (response.statusCode == 404) {
        // If dedicated endpoint doesn't exist, filter from all users
        await _fetchAndFilterUsers();
      }
    } catch (e) {
      debugPrint("Fetch blocked users error: $e");
      // Fallback to filtering from all users
      await _fetchAndFilterUsers();
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Option 2: Fallback method to filter from all users
  Future<void> _fetchAndFilterUsers() async {
    try {
      final response = await http.get(Uri.parse("${widget.baseUrl}/api/user-list/"));
      if (response.statusCode == 200) {
        final users = jsonDecode(response.body);
        // Filter blocked users based on your API response structure
        setState(() {
          blockedUsers = users.where((user) {
            // Try different possible field names for blocked status
            return user["is_blocked"] == true ||
                user["blocked"] == true ||
                user["status"] == "blocked" ||
                user["is_active"] == false;
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("Fallback fetch error: $e");
    }
  }

  Future<void> unblockUser(int id) async {
    try {
      final response = await http.post(
        Uri.parse("${widget.baseUrl}/api/manage-user/$id/"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"action": "unblock"}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("User unblocked successfully"),
            backgroundColor: Colors.green,
          ),
        );
        // Remove the user from local list immediately for better UX
        setState(() {
          blockedUsers.removeWhere((user) => user["id"] == id);
        });
        // Refresh the list to ensure consistency
        fetchBlockedUsers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to unblock user: ${response.statusCode}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Unblock user error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to unblock user - Network error"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// =============================
  /// UI COMPONENTS
  /// =============================
  Widget blockedCard(dynamic user) {
    final String joinDate = user["joined_date"] ?? "Unknown";
    final String registeredDate = user["registered_date"] ?? "Unknown";
    final String createdAt = user["created_at"] ?? "Unknown";
    final int reportCount = user["report_count"] ?? 0;
    final String email = user["email"] ?? "No email";
    final String username = user["username"] ?? user["name"] ?? "Unknown User";

    // Use the first available date
    final String displayDate = joinDate != "Unknown" ? joinDate :
    registeredDate != "Unknown" ? registeredDate :
    createdAt;

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
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.red.withOpacity(0.8),
          child: Text(
            username[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Row(
              children: [
                Text("Joined $displayDate", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                if (reportCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "$reportCount reports",
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => unblockUser(user["id"]),
          child: const Text("Unblock", style: TextStyle(fontWeight: FontWeight.bold)),
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
          "Blocked Users (${blockedUsers.length})",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchBlockedUsers,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : blockedUsers.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("No blocked users", style: TextStyle(color: Colors.grey, fontSize: 16)),
            SizedBox(height: 8),
            Text("All users are currently active", style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: fetchBlockedUsers,
        child: Column(
          children: [
            // Header info
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.red.withOpacity(0.05),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Blocked users cannot access the platform until unblocked",
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            // Users list
            Expanded(
              child: ListView.builder(
                itemCount: blockedUsers.length,
                itemBuilder: (_, i) => blockedCard(blockedUsers[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}