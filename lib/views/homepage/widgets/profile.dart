import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:publisher_app/main.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../loginscreen/loginpage.dart';
import '../settings.dart';
import 'editprofiler.dart';

class SocialProfilePage extends StatefulWidget {
  final int? userId; // <— add this
  final String? token; // <— add this

  const SocialProfilePage({super.key, this.userId, String? userProfileUrl, this.token}); // optional user ID

  @override
  State<SocialProfilePage> createState() => _SocialProfilePageState();
}


class _SocialProfilePageState extends State<SocialProfilePage> {

  String userName = "";
  String userEmail = "";
  String userBio = "";
  String? profileImage;

  List<dynamic> mediaList = [];
  bool isLoading = false;
  bool isProfileLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProfileData();
    fetchUserMedia();
  }

  /// ======================================
  /// Fetch user profile from API
  /// ======================================
  Future<void> fetchProfileData() async {
    setState(() => isProfileLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    String url;
    if (widget.userId != null) {
      print('111');
      // Viewing another user's profile
      url = "http://192.168.1.33:8000/api/profile/${widget.userId}/";
    } else {
      // Viewing logged-in user's profile
      url = "http://192.168.1.33:8000/api/profile/";
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Token $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          userName = data['name'] ?? 'No name';
          userEmail = data['email'] ?? 'No email';
          userBio = data['bio'] ?? 'No bio available';
          profileImage = data['profile_photo'];
        });
      } else {
        print('Error fetching profile: ${response.body}');
      }
    } catch (e) {
      print('Exception fetching profile: $e');
    } finally {
      setState(() => isProfileLoading = false);
    }
  }


  /// ======================================
  /// Fetch user media (photos & videos)
  /// ======================================
  Future<void> fetchUserMedia() async {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    int? userId = widget.userId;

    // If viewing own profile, fetch from profile endpoint
    if (userId == null) {
      print('hasuserid');
      final profileResponse = await http.get(
        Uri.parse("http://192.168.1.33:8000/api/profile/"),
        headers: {'Authorization': 'Token $token'},
      );
      if (profileResponse.statusCode == 200) {
        final profileData = jsonDecode(profileResponse.body);
        userId = profileData['id'];
      }
    }else {
      print('nouserid');

    }

    print('User ID: $userId');
    widget.userId!=null?print('h77h77'):print('j7u6');



    final url = Uri.parse("http://192.168.1.33:8000/api/media-list/${widget.userId!=null?widget.userId:userId}/");
    print(url);
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final approvedMedia = data.where((item) => item['is_approved'] == true).toList();
        setState(() => mediaList = approvedMedia);
      }
    } catch (e) {
      print("Exception fetching media: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }



  Future<void> _deleteMedia(int mediaId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('http://192.168.1.33:8000/api/delete-media/$mediaId/');
    print('Deleting media $mediaId');

    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Token $token'},
      );

      print('Delete response: ${response.statusCode}');
      if (response.statusCode == 204) {
        setState(() {
          mediaList.removeWhere((item) => item['id'] == mediaId);
        });
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete post (${response.statusCode})')),
        );
      }
    } catch (e) {
      print('Error deleting post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error deleting post')),
      );
    }
  }




  /// ======================================
  /// UI
  /// ======================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          "Profile",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          widget.userId!=null?
              SizedBox.shrink():
          IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF1A1A1A)),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: isProfileLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
            : RefreshIndicator(
          onRefresh: () async {
            await fetchProfileData();
            await fetchUserMedia();
          },
          color: const Color(0xFF6C63FF),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 16),
                _buildActionButtons(),
                const SizedBox(height: 16),
                isLoading
                    ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                )
                    : _buildMediaGrid(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 👤 Header (Profile Picture + Bio)
  Widget _buildProfileHeader() {
    return Container(
      width: scrWidth*1,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: scrWidth*0.3,
            height: scrHeight*0.1,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey, width: 3),
            ),
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: profileImage != null
                  ? NetworkImage("http://192.168.1.33:8000$profileImage")
                  : const NetworkImage("https://cdn-icons-png.flaticon.com/512/3135/3135715.png"),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            userName,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userEmail,
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              userBio.isNotEmpty ? userBio : "📸 Sharing my world one post at a time!",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.grey.shade700,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ✏️ Buttons (Edit Profile)
  Widget _buildActionButtons() {
    // If viewing someone else's profile, hide the Edit button
    if (widget.userId != null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 70),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _editProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Edit Profile",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // 🖼️ Grid of images/videos
  Widget _buildMediaGrid() {
    if (mediaList.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.photo_library_outlined, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              "No posts yet",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "When you share photos and videos, they'll appear here.",
              style: GoogleFonts.poppins(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Posts",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          Divider(),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: mediaList.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemBuilder: (context, index) {
              final media = mediaList[index];
              final image = media["image"];
              final isVideo = image.toString().endsWith('.mp4') ||
                  image.toString().endsWith('.mov') ||
                  image.toString().endsWith('.webm');

              return GestureDetector(
                onTap: () => _openPostDialog(media),

                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        "http://192.168.1.33:8000$image",
                        fit: BoxFit.cover,
                        errorBuilder: (context, _, __) => const Icon(Icons.broken_image),
                      ),
                      if (isVideo)
                        Container(
                          color: Colors.black26,
                          child: const Icon(Icons.play_circle_fill, color: Colors.white, size: 30),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 🔍 Open Post Dialog
  void _openPostDialog(Map<String, dynamic> media) {
    final url = media['image'];
    final isVideo = url.toString().endsWith('.mp4') ||
        url.toString().endsWith('.mov') ||
        url.toString().endsWith('.webm');
    final mediaId = media['id'];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            // Display image or video
            Center(
              child: isVideo
                  ? _VideoPlayerWidget(videoUrl: "http://192.168.1.33:8000$url")
                  : Image.network(
                "http://192.168.1.33:8000$url",
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white),
              ),
            ),

            // Close button
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

            // Delete button (only for logged-in user)
            if (widget.userId == null)
              Positioned(
                bottom: 20,
                right: 20,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Delete Post"),
                        content: const Text("Are you sure you want to delete this post?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      _deleteMedia(mediaId);
                    }
                  },
                  icon: const Icon(Icons.delete, color: Colors.white),
                  label: const Text("Delete", style: TextStyle(color: Colors.white)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 🧭 Edit Profile
  void _editProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfilePage()),
    );
    fetchProfileData(); // refresh profile after returning
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const _VideoPlayerWidget({required this.videoUrl});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: VideoPlayer(_controller),
    )
        : const Center(child: CircularProgressIndicator(color: Colors.white));
  }
}
