import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'amin_homepage.dart';

/// =============================
/// PENDING MEDIA PAGE
/// =============================
class PendingMediaPage extends StatefulWidget {
  final String baseUrl;
  const PendingMediaPage({super.key, required this.baseUrl});

  @override
  State<PendingMediaPage> createState() => _PendingMediaPageState();
}

class _PendingMediaPageState extends State<PendingMediaPage> {
  List<dynamic> pendingMediaList = [];
  bool isLoading = false;
  String? adminName;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
    fetchPendingMedia();
  }

  /// =============================
  /// LOAD ADMIN DATA FROM SHARED PREFERENCES
  /// =============================
  Future<void> _loadAdminData() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        adminName = prefs.getString("name") ?? "Admin";
      });
    } catch (e) {
      debugPrint("Error loading admin data: $e");
      setState(() {
        adminName = "Admin";
      });
    }
  }

  /// =============================
  /// API CALLS
  /// =============================
  Future<void> fetchPendingMedia() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse("${widget.baseUrl}/api/media-list/"));
      if (response.statusCode == 200) {
        final allMedia = jsonDecode(response.body);
        // Filter media where both is_approved and is_rejected are false
        setState(() {
          pendingMediaList = allMedia.where((media) {
            final isApproved = media["is_approved"] ?? false;
            final isRejected = media["is_rejected"] ?? false;
            return !isApproved && !isRejected;
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("Fetch pending media error: $e");
      _showErrorSnackBar("Failed to load pending media");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> approveMedia(int id, bool approve) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String adminName = prefs.getString("name") ?? "Admin";

      final response = await http.post(
        Uri.parse("${widget.baseUrl}/api/${approve ? "approve-media" : "reject-media"}/$id/"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "is_approved": approve,
          "is_rejected": !approve, // If not approved, then rejected
          "approved_by": adminName,
          "action_taken_at": DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        _showSuccessSnackBar("Media ${approve ? "approved" : "rejected"} successfully");
        // Remove the media from local list immediately
        setState(() {
          pendingMediaList.removeWhere((media) => media["id"] == id);
        });

        // Log the action
        _logAdminAction(
            mediaId: id,
            action: approve ? "approved" : "rejected",
            adminName: adminName
        );
      } else {
        _showErrorSnackBar("Failed to ${approve ? "approve" : "reject"} media");
      }
    } catch (e) {
      debugPrint("Approve media error: $e");
      _showErrorSnackBar("Network error - failed to ${approve ? "approve" : "reject"} media");
    }
  }

  /// =============================
  /// LOG ADMIN ACTIONS TO SHARED PREFERENCES
  /// =============================
  Future<void> _logAdminAction({
    required int mediaId,
    required String action,
    required String adminName
  }) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Get existing logs or create new list
      final String? existingLogs = prefs.getString("admin_actions_log");
      final List<dynamic> logs = existingLogs != null ? jsonDecode(existingLogs) : [];

      // Add new log entry
      logs.add({
        "media_id": mediaId,
        "action": action,
        "admin_name": adminName,
        "timestamp": DateTime.now().toIso8601String(),
        "date": DateTime.now().toString(),
      });

      // Save back to shared preferences
      await prefs.setString("admin_actions_log", jsonEncode(logs));

      debugPrint("Admin action logged: $adminName $action media $mediaId");
    } catch (e) {
      debugPrint("Error logging admin action: $e");
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

  Color _getUserColor(String name) {
    if (name.isEmpty) return Colors.grey;

    final colors = [
      Colors.blue.shade700,
      Colors.purple.shade700,
      Colors.orange.shade700,
      Colors.green.shade700,
      Colors.pink.shade700,
      Colors.teal.shade700,
    ];
    final index = name.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[index];
  }

  String _getUserInitials(String name) {
    if (name.isEmpty) return "?";

    final words = name.trim().split(RegExp(r'\s+'));

    if (words.length == 1) {
      return words[0].length >= 2
          ? words[0].substring(0, 2).toUpperCase()
          : words[0].toUpperCase();
    } else {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
  }

  Widget _buildUserAvatar(String name, {double size = 42}) {
    final String userInitials = _getUserInitials(name);
    final Color userColor = _getUserColor(name);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            userColor,
            userColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: userColor.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          userInitials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: size * 0.28,
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      if (difference.inDays < 7) return '${difference.inDays}d ago';

      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  /// =============================
  /// UI COMPONENTS
  /// =============================
  Widget pendingMediaCard(dynamic media) {
    final String? image = media["image"];
    final String? video = media["video"];
    final String title = media["title"] ?? "No Title";
    final String description = media["description"] ?? "No Description";
    final String category = media["category"] ?? "Uncategorized";
    final String subcategory = media["subcategory"] ?? "General";
    final String uploader = media["uploader"]?.toString() ?? "Unknown User";
    final String uploadedAt = media["uploaded_at"] ?? "Unknown date";
    final int likes = media["like"] ?? 0;
    final int comments = media["comment"] ?? 0;
    final int mediaId = media["id"];

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
            // Header with user info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildUserAvatar(uploader),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            uploader,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15
                            )
                        ),
                        Text(
                            _formatDate(uploadedAt),
                            style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12
                            )
                        ),
                      ],
                    ),
                  ),
                  // Pending badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      "Pending",
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Category and subcategory
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (subcategory.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        subcategory,
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Title and description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (description.isNotEmpty && description != "No Description") ...[
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Media content
            if (image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  "${widget.baseUrl}$image",
                  height: 280,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey, size: 50),
                      ),
                    );
                  },
                ),
              ),

            if (video != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: VideoPlayerWidget(videoUrl: "${widget.baseUrl}$video"),
              ),

            // Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.favorite, color: Colors.red.shade400, size: 16),
                  const SizedBox(width: 4),
                  Text("$likes", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(width: 16),
                  Icon(Icons.comment, color: Colors.blue.shade400, size: 16),
                  const SizedBox(width: 4),
                  Text("$comments", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const Spacer(),
                  Text(
                    "ID: $mediaId",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // Action buttons with admin name
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (adminName != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        "Action by: $adminName",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check, size: 18),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => _showApproveConfirmation(mediaId, title, uploader),
                          label: const Text("Approve", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.close, size: 18),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => _showRejectConfirmation(mediaId, title, uploader),
                          label: const Text("Reject", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ));
    }

  /// =============================
  /// CONFIRMATION DIALOGS
  /// =============================
  void _showApproveConfirmation(int mediaId, String title, String uploader) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Approve Media"),
        content: Text("Are you sure you want to approve '$title' by $uploader?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(context);
              approveMedia(mediaId, true);
            },
            child: const Text("Approve", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRejectConfirmation(int mediaId, String title, String uploader) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reject Media"),
        content: Text("Are you sure you want to reject '$title' by $uploader?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              approveMedia(mediaId, false);
            },
            child: const Text("Reject", style: TextStyle(color: Colors.white)),
          ),
        ],
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
          "Pending Media (${pendingMediaList.length})",
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (adminName != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  "Admin: $adminName",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pendingMediaList.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("No pending media", style: TextStyle(color: Colors.grey, fontSize: 16)),
            SizedBox(height: 8),
            Text("All media has been moderated", style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: fetchPendingMedia,
        child: ListView.builder(
          itemCount: pendingMediaList.length,
          itemBuilder: (_, index) => pendingMediaCard(pendingMediaList[index]),
        ),
      ),
    );
  }
}

// Placeholder for VideoPlayerWidget - replace with your actual video player implementation
class VideoPlayerWidget extends StatelessWidget {
  final String videoUrl;

  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_filled, size: 50, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              "Video: ${videoUrl.split('/').last}",
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}