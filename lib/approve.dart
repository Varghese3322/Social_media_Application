import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

import 'amin_homepage.dart';

/// =============================
/// APPROVED MEDIA PAGE
/// =============================
class ApprovedMediaPage extends StatefulWidget {
  final String baseUrl;
  const ApprovedMediaPage({super.key, required this.baseUrl});

  @override
  State<ApprovedMediaPage> createState() => _ApprovedMediaPageState();
}

class _ApprovedMediaPageState extends State<ApprovedMediaPage> {
  List<dynamic> approvedMediaList = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchApprovedMedia();
  }

  /// =============================
  /// API CALLS
  /// =============================
  Future<void> fetchApprovedMedia() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse("${widget.baseUrl}/api/media-list/"));
      if (response.statusCode == 200) {
        final allMedia = jsonDecode(response.body);
        // Filter media where is_approved is true
        setState(() {
          approvedMediaList = allMedia.where((media) {
            final isApproved = media["is_approved"] ?? false;
            return isApproved == true;
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("Fetch approved media error: $e");
      _showErrorSnackBar("Failed to load approved media");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> unapproveMedia(int id) async {
    try {
      final response = await http.post(
        Uri.parse("${widget.baseUrl}/api/reject-media/$id/"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"is_approved": false}),
      );

      if (response.statusCode == 200) {
        _showSuccessSnackBar("Media unapproved successfully");
        // Remove the media from local list immediately
        setState(() {
          approvedMediaList.removeWhere((media) => media["id"] == id);
        });
      } else {
        _showErrorSnackBar("Failed to unapprove media");
      }
    } catch (e) {
      debugPrint("Unapprove media error: $e");
      _showErrorSnackBar("Network error - failed to unapprove media");
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
  Widget approvedMediaCard(dynamic media) {
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
                // Approved badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "Approved",
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
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

          // If no image or video, show placeholder
          if (image == null && video == null)
            Container(
              height: 120,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.text_fields, color: Colors.grey, size: 40),
                    SizedBox(height: 8),
                    Text(
                      "Text Only Post",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
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
                  "ID: ${media["id"]}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Action button - Unapprove
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.undo, size: 18),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: BorderSide(color: Colors.orange.shade400),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _showUnapproveDialog(media["id"]),
                label: const Text("Unapprove", style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUnapproveDialog(int mediaId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Unapprove Media"),
        content: const Text("Are you sure you want to unapprove this media? It will be moved back to pending."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            onPressed: () {
              Navigator.pop(context);
              unapproveMedia(mediaId);
            },
            child: const Text("Unapprove"),
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
          "Approved Media (${approvedMediaList.length})",
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
            onPressed: fetchApprovedMedia,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : approvedMediaList.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("No approved media", style: TextStyle(color: Colors.grey, fontSize: 16)),
            SizedBox(height: 8),
            Text("Approve some media to see them here", style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: fetchApprovedMedia,
        child: ListView.builder(
          itemCount: approvedMediaList.length,
          itemBuilder: (_, index) => approvedMediaCard(approvedMediaList[index]),
        ),
      ),
    );
  }
}