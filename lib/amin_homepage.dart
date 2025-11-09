import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:publisher_app/pending.dart';
import 'package:publisher_app/total%20users.dart';
import 'package:publisher_app/views/loginscreen/loginpage.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;

import 'approve.dart';

/// =============================
/// ADMIN DASHBOARD - REDESIGNED
/// =============================
class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> with SingleTickerProviderStateMixin {
  final String baseUrl = "http://192.168.1.33:8000";

  bool isLoading = false;
  List<dynamic> mediaList = [];
  List<dynamic> userList = [];
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchMedia();
    fetchUsers();
  }

  /// =============================
  /// API CALLS
  /// =============================
  Future<void> fetchMedia() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse("$baseUrl/api/media-list/"));
      if (response.statusCode == 200) setState(() => mediaList = jsonDecode(response.body));
    } catch (e) {
      debugPrint("Media fetch error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse("$baseUrl/api/user-list/"));
      if (response.statusCode == 200) setState(() => userList = jsonDecode(response.body));
    } catch (e) {
      debugPrint("User fetch error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> approveMedia(int id, bool approve) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/${approve ? "approve-media" : "reject-media"}/$id/"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"is_approved": approve}),
      );
      if (response.statusCode == 200) fetchMedia();
    } catch (e) {
      debugPrint("Approve media error: $e");
    }
  }

  Future<void> manageUser(int id, String action) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/manage-user/$id/"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"action": action}),
      );
      if (response.statusCode == 200) fetchUsers();
    } catch (e) {
      debugPrint("Manage user error: $e");
    }
  }

  void showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                      (route) => false);
            },
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// =============================
  /// UI COMPONENTS - REDESIGNED
  /// =============================
  Widget _buildStatsCard(String title, String count, Color color, IconData icon) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget mediaCard(dynamic media) {
    final String? fileUrl = media["image"]; // this may be image or video
    final bool? approved = media["is_approved"];
    final String uploaderName = media["user_name"] ?? "Unknown";
    final int userId = media["user"] ?? 0;
    final String timeAgo = media["uploaded_at"]?.toString().substring(0, 10) ?? "";
    final String? profileImage = media["user_profile"];

    // Detect file type
    final bool isVideo = fileUrl != null &&
        (fileUrl.endsWith('.mp4') ||
            fileUrl.endsWith('.mov') ||
            fileUrl.endsWith('.webm') ||
            fileUrl.endsWith('.avi'));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 👤 Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _getUserColor(uploaderName),
                  backgroundImage: profileImage != null
                      ? NetworkImage("$baseUrl$profileImage")
                      : null,
                  child: profileImage == null
                      ? Text(
                    uploaderName.isNotEmpty
                        ? uploaderName[0].toUpperCase()
                        : "?",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(uploaderName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(timeAgo,
                          style:
                          const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                if (approved != null)
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: approved
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      approved ? "Approved" : "Rejected",
                      style: TextStyle(
                        color: approved ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 📸 Image or Video Content
          if (fileUrl != null)
            GestureDetector(
              onTap: () {
                _openMediaPreview("$baseUrl$fileUrl", isVideo);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: isVideo
                    ? Stack(
                  alignment: Alignment.center,
                  children: [
                    // 🔹 Video thumbnail
                    Container(
                      color: Colors.black12,
                      height: 280,
                      width: double.infinity,
                      child: VideoPlayerWidget(videoUrl: "$baseUrl$fileUrl"),
                    ),
                    const Icon(Icons.play_circle_fill,
                        color: Colors.white70, size: 60),
                  ],
                )
                    : Image.network(
                  "$baseUrl$fileUrl",
                  height: 280,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image, size: 60),
                ),
              ),
            ),

          // 📝 Title + Description
          if (media["title"] != null || media["description"] != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (media["title"] != null)
                    Text(media["title"] ?? "",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  if (media["description"] != null) const SizedBox(height: 4),
                  if (media["description"] != null)
                    Text(media["description"] ?? "",
                        style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),

          // ✅ Approve / Reject Buttons (if needed)
          if (approved == null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check, size: 18),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => approveMedia(media["id"], true),
                      label: const Text("Approve",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.close, size: 18),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => approveMedia(media["id"], false),
                      label: const Text("Reject",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _openMediaPreview(String url, bool isVideo) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            Center(
              child: isVideo
                  ? VideoPlayerWidget(videoUrl: url)
                  : Image.network(url, fit: BoxFit.contain),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                radius: 18,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }







  Widget userCard(dynamic user) {
    final bool isBlocked = user["is_blocked"] ?? false;
    final int reportCount = user["report_count"] ?? 0;
    final String joinDate = user["joined_date"] ?? "Jan 2024";

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
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: user['profile_photo'] != null && user['profile_photo']!.isNotEmpty
                  ? NetworkImage('http://192.168.1.33:8000/media/${user['profile_photo']!}')
                  : null,
              child: user['profile_photo'] == null || user['profile_photo']!.isEmpty
                  ? Icon(Icons.person, size: 18, color: Colors.grey.shade400)
                  : null,
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
        title: Text(user["name"], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user["email"], style: const TextStyle(color: Colors.grey)),
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
                  Icon(isBlocked ? Icons.lock_open : Icons.block, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(isBlocked ? "Unblock User" : "Block User"),
                ],
              ),
            ),
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

  Color _getUserColor(String name) {
    final colors = [
      Colors.blueAccent,
      Colors.purpleAccent,
      Colors.orangeAccent,
      Colors.greenAccent,
      Colors.pinkAccent,
    ];
    final index = name.length % colors.length;
    return colors[index];
  }

  /// =============================
  /// BUILD - REDESIGNED
  /// =============================
  @override
  Widget build(BuildContext context) {
    final pendingMedia = mediaList.where((media) => media["is_approved"] == null).length;
    final totalUsers = userList.length;
    final blockedUsers = userList.where((user) => user["is_blocked"] == true).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (selectedIndex == 0) fetchMedia();
              if (selectedIndex == 1) fetchUsers();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: showLogoutDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Overview
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  InkWell(
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context) => PendingMediaPage(baseUrl: baseUrl)));
                    },
                      child: _buildStatsCard("Pending Media", pendingMedia.toString(), Colors.orange, Icons.pending_actions)),

                  InkWell(
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context) => TotalUsersPage(baseUrl: baseUrl)));
                    },
                      child: _buildStatsCard("Total Users", totalUsers.toString(), Colors.blue, Icons.people)),



                  InkWell(
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context) => BlockedUsersPage(baseUrl: baseUrl)));
                    },
                      child: _buildStatsCard("Blocked Users", blockedUsers.toString(), Colors.red, Icons.block)),
                  InkWell(
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ApprovedMediaPage(baseUrl: '',)));
                    },
                      child: _buildStatsCard("Approved Media", (mediaList.length - pendingMedia).toString(), Colors.green, Icons.check_circle)),
                ],
              ),
            ),
          ),

          // Navigation Tabs
          Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _NavigationTab(
                    title: "Content Moderation",
                    isSelected: selectedIndex == 0,
                    icon: Icons.photo_library,
                    onTap: () => setState(() => selectedIndex = 0),
                  ),
                  const SizedBox(width: 16),
                  _NavigationTab(
                    title: "User Management",
                    isSelected: selectedIndex == 1,
                    icon: Icons.people,
                    onTap: () => setState(() => selectedIndex = 1),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Content Area
          Expanded(
            child: IndexedStack(
              index: selectedIndex,
              children: [
                // Media Tab
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                  onRefresh: fetchMedia,
                  child: mediaList.isEmpty
                      ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text("No media to moderate", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                      : ListView.builder(
                    itemCount: mediaList.length,
                    itemBuilder: (_, i) => mediaCard(mediaList[i]),
                  ),
                ),

                // Users Tab
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                  onRefresh: fetchUsers,
                  child: userList.isEmpty
                      ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text("No users found", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                      : ListView.builder(
                    itemCount: userList.length,
                    itemBuilder: (_, i) => userCard(userList[i]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Navigation Tab Widget
class _NavigationTab extends StatelessWidget {
  final String title;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;

  const _NavigationTab({
    required this.title,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.blueAccent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: isSelected ? Colors.blueAccent : Colors.grey),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.blueAccent : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// =============================
/// BLOCKED USERS PAGE - REDESIGNED
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

  Future<void> fetchBlockedUsers() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse("${widget.baseUrl}/api/user-list/"));
      if (response.statusCode == 200) {
        final users = jsonDecode(response.body);
        setState(() => blockedUsers = users.where((u) => u["is_blocked"] == true).toList());
      }
    } catch (e) {
      debugPrint("Fetch blocked users error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> unblockUser(int id) async {
    try {
      final response = await http.post(
          Uri.parse("${widget.baseUrl}/api/manage-user/$id/"),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({"action": "unblock"}));
      if (response.statusCode == 200) fetchBlockedUsers();
    } catch (e) {
      debugPrint("Unblock user error: $e");
    }
  }

  Widget blockedCard(dynamic user) {
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
          child: Text(user["name"][0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        title: Text(user["name"], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(user["email"], style: const TextStyle(color: Colors.grey)),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => unblockUser(user["id"]),
          child: const Text("Unblock", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Blocked Users", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: fetchBlockedUsers,
        child: ListView.builder(
            itemCount: blockedUsers.length,
            itemBuilder: (_, i) => blockedCard(blockedUsers[i])),
      ),
    );
  }
}

/// =============================
/// VIDEO PLAYER - ENHANCED
/// =============================
class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.setLooping(true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
        ),
        if (!_controller.value.isInitialized)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
        if (_controller.value.isInitialized)
          Positioned.fill(
            child: GestureDetector(
              onTap: _togglePlay,
              child: Container(
                color: Colors.transparent,
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}