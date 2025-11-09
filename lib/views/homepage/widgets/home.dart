import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import 'Notification.dart';




enum MenuItem { save, delete, edit, report }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  List<dynamic> mediaList = [];
  String? userName;
  String? userProfile;
  String? userEmail;
  int? currentUserId;
  bool isLoading = true;
  String? profileImage;
  final String baseUrl = "http://192.168.1.33:8000";

  // Track liked posts
  Map<int, bool> likedPosts = {};
  // Cache for user data
  Map<int, Map<String, dynamic>> userCache = {};

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
    _fetchMedia();
    fetchProfileData();
  }


  Future<void> fetchProfileData() async {

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print('token: $token');

    String url='http://192.168.1.33:8000/api/profile/';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Token $token'},
      );
      print('Response status code: ${response.statusCode}');


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          profileImage = data['profile_photo'];
        });
        print('profile image: ${profileImage}');
      } else {
        print('Error fetching profile: ${response.body}');
      }
    } catch (e) {
      print('Exception fetching profile: $e');
    } finally {
    }
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      currentUserId = int.tryParse('${prefs.getString('user_id')}');
      print('Current User ID: $currentUserId');
      if (currentUserId != null) {
        await _fetchUserLikes();
      }

      setState(() {

      });
    } catch (e) {
      print('Error fetching current user: $e');
    }
  }


  Future<void> _fetchUserLikes() async {
    if (currentUserId == null) return;
    try {
      final url = Uri.parse('http://192.168.1.33:8000/api/like-media/$currentUserId/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> likedData = json.decode(response.body);
        print('Liked posts fetched: ${likedData.length}');

        // Mark all liked posts
        for (var item in likedData) {
          final int mediaId = item['media'];
          likedPosts[mediaId] = true;
        }

        setState(() {});
      } else {
        print('Failed to fetch liked posts: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching liked posts: $e');
    }
  }


  Future<void> _fetchMedia() async {
    try {
      final url = Uri.parse('$baseUrl/api/media-list/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Fetched ${data.length} media items');

        // Filter only approved media
        final approvedMedia = data.where((media) {
          final isApproved = media["is_approved"] ?? false;
          final isRejected = media["is_rejected"] ?? false;
          return isApproved && !isRejected;
        }).toList();

        print('Approved media: ${approvedMedia.length}');

        // Initialize liked posts map
        for (var media in approvedMedia) {
          likedPosts[media['id']] = media['is_liked'] ?? false;

          // Debug user information
          final userId = media['user'] ?? media['user_id'];
          print('Post ${media['id']} - User ID: $userId');
        }

        setState(() {
          mediaList = approvedMedia;
          isLoading = false;
        });

        // Pre-fetch user data for all posts
        await _prefetchUserData(approvedMedia);
      } else {
        print('Failed to load media: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching media: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _prefetchUserData(List<dynamic> mediaList) async {
    final uniqueUserIds = <int>{};

    for (var media in mediaList) {
      final userId = _getUserId(media);
      if (userId != null) {
        uniqueUserIds.add(userId);
      }
    }

    for (var userId in uniqueUserIds) {
      if (!userCache.containsKey(userId)) {
        await _fetchUserData(userId);
      }
    }
  }

  Future<void> _fetchUserData(int userId) async {

    try {
      final url = Uri.parse('$baseUrl/api/users/$userId/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        setState(() {
          userCache[userId] = {
            'name': userData['name'] ?? userData['username'] ?? 'User',
            'profile_picture': userData['profile_picture'] ?? userData['avatar'],
            'email': userData['email'] ?? '',
          };
        });
      }
    } catch (e) {
      print('Error fetching user data for user $userId: $e');
      // Set default user data if fetch fails
      setState(() {
        userCache[userId] = {
          'name': 'User $userId',
          'profile_picture': null,
          'email': '',
        };
      });
    }
  }

  int? _getUserId(dynamic media) {
    if (media['user'] is int) {
      return media['user'];
    } else if (media['user_id'] is int) {
      return media['user_id'];
    } else if (media['user'] is Map) {
      return media['user']['id'];
    }
    return null;
  }

  String _getUserName(dynamic media) {
    final userId = _getUserId(media);
    if (userId != null && userCache.containsKey(userId)) {
      return userCache[userId]!['name'] ?? 'User';
    }

    // Fallback to direct fields if user cache not available
    if (media['user_name'] != null) return media['user_name'];
    if (media['username'] != null) return media['username'];
    if (media['author'] != null) return media['author'];
    if (media['user'] is Map) {
      return media['user']['name'] ?? media['user']['username'] ?? 'User';
    }

    return 'User';
  }

  String? _getUserProfileImage(dynamic media) {
    final userId = _getUserId(media);
    if (userId != null && userCache.containsKey(userId)) {
      final profilePic = userCache[userId]!['profile_picture'];
      return profilePic != null ? '$baseUrl$profilePic' : null;
    }

    // Fallback to direct fields
    if (media['user_profile'] != null) return '$baseUrl${media['user_profile']}';
    if (media['profile_picture'] != null) return '$baseUrl${media['profile_picture']}';
    if (media['user'] is Map && media['user']['profile_picture'] != null) {
      return '$baseUrl${media['user']['profile_picture']}';
    }

    return null;
  }

  String _getUserEmail(dynamic media) {
    final userId = _getUserId(media);
    if (userId != null && userCache.containsKey(userId)) {
      return userCache[userId]!['email'] ?? '';
    }

    if (media['user_email'] != null) return media['user_email'];
    if (media['user'] is Map) return media['user']['email'] ?? '';

    return '';
  }

  bool _isCurrentUserPost(dynamic media) {
    final postUserId = _getUserId(media);
    return postUserId != null && postUserId == currentUserId;
  }

  Future<void> _refreshMedia() async {
    setState(() {
      isLoading = true;
      userCache.clear();
    });
    await _fetchMedia();
  }

  Future<void> _toggleLikePost(int postId) async {
    if (currentUserId == null) {
      _showSnackBar('Please log in to like posts.');
      return;
    }

    final prevLiked = likedPosts[postId] ?? false;

    // Optimistic UI update
    setState(() {
      likedPosts[postId] = !prevLiked;
    });

    try {
      final url = Uri.parse('http://192.168.1.33:8000/api/like-media/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'media_id': postId,
          'user_id': currentUserId,
        }),
      );
      print(response.body);

      if (response.statusCode == 200) {
        print('success');
        final data = json.decode(response.body);
        final isLiked = data['is_liked'] ?? false;
        final likeCount = data['like_count'] ?? 0;

        setState(() {
          likedPosts[postId] = isLiked;
          final index = mediaList.indexWhere((item) => item['id'] == postId);
          if (index != -1) {
            mediaList[index]['like'] = likeCount;
          }
        });
      } else if (response.statusCode==201) {

      }else{
        print('failed');

        // Revert state on error
        setState(() {
          likedPosts[postId] = prevLiked;
        });
        _showSnackBar('Failed to like post. Please try again.');
      }
    }

    catch (e) {
      // Revert state on network failure
      setState(() {
        likedPosts[postId] = prevLiked;
      });
      _showSnackBar('Network error. Please check your connection.');
      print('Error toggling like: $e');
    }
  }

  Future<void> fetchUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    final response = await http.get(Uri.parse('$baseUrl/api/user-profile/$userId/'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        currentUserProfile = data['profile_photo'];
      });
    }
  }


  Future<void> _showCommentDialog(int postId, String userName) async {
    final TextEditingController _commentController = TextEditingController();
    List<dynamic> comments = [];
    bool isLoading = true;

    // Fetch comments from API
    Future<void> fetchComments() async {
      try {
        final url = Uri.parse('$baseUrl/api/media-comments/$postId/');
        final response = await http.get(url);

        if (response.statusCode == 200) {
          comments = json.decode(response.body);
        } else {
          comments = [];
          print('Failed to fetch comments: ${response.statusCode}');
        }
      } catch (e) {
        print('Error fetching comments: $e');
        comments = [];
      } finally {
        isLoading = false;
      }
    }

    await fetchComments();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> refreshComments() async {
              await fetchComments();
              setModalState(() {});
            }


            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.75,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Text(
                        "Comments",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Divider(),
                      const SizedBox(height: 12),

                      // Comments list
                      Expanded(
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : comments.isEmpty
                            ? Center(
                          child: Text(
                            'No comments yet',
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        )
                            : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage:
                                comment['profile_photo'] != null &&
                                    comment['profile_photo'].toString().isNotEmpty
                                    ? NetworkImage('$baseUrl${comment['profile_photo']}')
                                    : null,
                                backgroundColor: Colors.grey.shade200,
                                child: comment['profile_photo'] == null
                                    ? const Icon(Icons.person, color: Colors.grey)
                                    : null,
                              ),
                              title: Text(
                                comment['user_name'] ?? 'Unknown User',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Text(
                                comment['text'] ?? '',
                                style: GoogleFonts.poppins(fontSize: 13),
                              ),
                              trailing: Text(
                                _formatDateTime(comment['created_at']),
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Input field for new comment
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: (currentUserProfile != null && currentUserProfile!.isNotEmpty)
                                ? NetworkImage('$baseUrl$currentUserProfile')
                                : null,
                            child: (currentUserProfile == null || currentUserProfile!.isEmpty)
                                ? Icon(Icons.person, size: 16, color: Colors.grey.shade600)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Add a comment...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                      ,
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
  String? currentUserProfile;










  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return '';
    }
  }



  Future<void> _addComment(int postId, String comment) async {
    try {
      final url = Uri.parse('$baseUrl/api/comment-media/');
      print('111');
      final response = await http.post(
        url,
        body: {'user_id': currentUserId.toString(),'media_id': postId.toString(), 'text': comment},
      );
      print('222');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 201) {
        setState(() {
          // Update comment count locally
          final index = mediaList.indexWhere((item) => item['id'] == postId);
          if (index != -1) {
            mediaList[index]['comment'] = (mediaList[index]['comment'] ?? 0) + 1;
          }
        });
        _showSnackBar('Comment added!');
      }
    } catch (e) {
      print('Error adding comment: $e');
    }
  }

  Future<void> _deletePost(int postId) async {
    try {
      final url = Uri.parse('$baseUrl/api/posts/$postId/delete/');
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        setState(() {
          mediaList.removeWhere((item) => item['id'] == postId);
          likedPosts.remove(postId);
        });
        _showSnackBar('Post deleted successfully!');
      } else {
        _showSnackBar('Failed to delete post: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting post: $e');
      _showSnackBar('Error deleting post: $e');
    }
  }

  Future<void> _savePost(int postId) async {
    try {
      final url = Uri.parse('$baseUrl/api/posts/$postId/save/');
      final response = await http.post(url);

      if (response.statusCode == 200) {
        _showSnackBar('Post saved!');
      }
    } catch (e) {
      print('Error saving post: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: Color(0xFF6C63FF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: Duration(seconds: 2),
      ),
    );
  }


  void _showEditDialog(dynamic media) {
    final TextEditingController titleController = TextEditingController(text: media['title'] ?? '');
    final TextEditingController descController = TextEditingController(text: media['description'] ?? '');
    final TextEditingController categoryController = TextEditingController(text: media['category'] ?? '');
    final TextEditingController subcategoryController = TextEditingController(text: media['subcategory'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Post',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 12),
              TextField(
                controller: categoryController,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: subcategoryController,
                decoration: InputDecoration(
                  labelText: 'Subcategory',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              _updatePost(
                media['id'],
                titleController.text,
                descController.text,
                categoryController.text,
                subcategoryController.text,
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6C63FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Update', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePost(int postId, String title, String description, String category, String subcategory) async {
    try {
      final url = Uri.parse('$baseUrl/api/posts/$postId/update/');
      final response = await http.put(
        url,
        body: {
          'title': title,
          'description': description,
          'category': category,
          'subcategory': subcategory,
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          final index = mediaList.indexWhere((item) => item['id'] == postId);
          if (index != -1) {
            mediaList[index]['title'] = title;
            mediaList[index]['description'] = description;
            mediaList[index]['category'] = category;
            mediaList[index]['subcategory'] = subcategory;
          }
        });
        _showSnackBar('Post updated successfully!');
      }
    } catch (e) {
      print('Error updating post: $e');
    }
  }

  void _showFullScreenMedia(String imageUrl, bool isVideo, String? description, String? title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenMediaPage(
          imageUrl: imageUrl,
          isVideo: isVideo,
          description: description,
          title: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          "Insta x",
          style: GoogleFonts.hammersmithOne(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black12,
        actions: [
          CircleAvatar(
            radius: 16,
            backgroundImage: (profileImage != null && profileImage!.isNotEmpty)
                ? NetworkImage('http://192.168.1.33:8000/$profileImage')
                : null,
            child: (profileImage == null || profileImage!.isEmpty)
                ? Icon(Icons.person, size: 20, color: Colors.grey.shade600)
                : null,

            backgroundColor: Colors.grey.shade300,
       )

          ,
          Container(
            margin: EdgeInsets.only(right: 15),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF0F2F5),
            ),
            child: IconButton(
              icon: Icon(Icons.notifications_none,
                color: Color(0xFF1A1A1A),
                size: 24,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NoNotificationsPage()),
                );
              },
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshMedia,
        color: Color(0xFF6C63FF),
        child: isLoading
            ? _buildLoadingState()
            : mediaList.isEmpty
            ? _buildEmptyState()
            : _buildMediaList(),
      ),
    );
  }
  Widget _buildLoadingState() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade300,
              radius: 24,
            ),
            title: Container(
              height: 120,
              width: 120,
              color: Colors.grey.shade300,
            ),
            subtitle: Container(
              height: 120,
              width: 200,
              margin: EdgeInsets.only(top: 8),
              color: Colors.grey.shade300,
            ),
          ),
        );
      },
    );
  }


  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 80,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: 16),
              Text(
                "No posts yet",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Be the first to share something!",
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade500,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _refreshMedia,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6C63FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Refresh',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaList() {
    return ListView.builder(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(vertical: 8),
      itemCount: mediaList.length,
      itemBuilder: (context, index) {
        final media = mediaList[index];
        final imageUrl = media['image']?.toString() ?? '';
        final isVideo = imageUrl.toLowerCase().endsWith('.mp4') ||
            imageUrl.toLowerCase().endsWith('.webm') ||
            imageUrl.toLowerCase().endsWith('.mov');

        // Get user information using user ID
        final String displayName = _getUserName(media);
        final String? userProfileImage = _getUserProfileImage(media);
        final String postOwnerEmail = _getUserEmail(media);
        final bool isCurrentUserPost = _isCurrentUserPost(media);

        return _MediaCard(
          id: media['id'] ?? 0,
          title: media['title'] ?? 'Untitled',
          description: media['description'] ?? '',
          imageUrl: imageUrl.isNotEmpty ? '$baseUrl$imageUrl' : '',
          isVideo: isVideo,
          category: media['category'] ?? 'General',
          subcategory: media['subcategory'] ?? 'Other',
          likes: media['like'] ?? 0,
          comments: media['comment'] ?? 0,
          uploadedAt: media['uploaded_at'] ?? '',
          isApproved: media['is_approved'] ?? false,
          userName: media['user_name'] ?? 'User',
          userProfileUrl: userProfileImage,
          currentUserEmail: userEmail ?? '',
          postOwnerEmail: postOwnerEmail,
          isCurrentUserPost: isCurrentUserPost,
          isLiked: likedPosts[media['id']] ?? false,
          onLike: () => _toggleLikePost(media['id']),
          onComment: () => _showCommentDialog(media['id'], userName ?? 'User'),
          onShare: () => Share.share('$baseUrl${media['image']}'),
          onSave: () => _savePost(media['id']),
          onDelete: () => _deletePost(media['id']),
          onEdit: () => _showEditDialog(media),
          onMediaTap: () => _showFullScreenMedia(
              '$baseUrl$imageUrl',
              isVideo,
              media['description'],
              media['title']
          ), userid: media['user'],
        );
      },
    );
  }
}



class _MediaCard extends StatefulWidget {
  final int id;
  final int userid;
  final String title;
  final String description;
  final String imageUrl;
  final bool isVideo;
  final String category;
  final String subcategory;
  final int likes;
  final int comments;
  final String uploadedAt;
  final bool isApproved;
  final String userName;
  final String? userProfileUrl;
  final String currentUserEmail;
  final String postOwnerEmail;
  final bool isCurrentUserPost;
  final bool isLiked;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onSave;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onMediaTap;

  const _MediaCard({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.isVideo,
    required this.category,
    required this.subcategory,
    required this.likes,
    required this.comments,
    required this.uploadedAt,
    required this.isApproved,
    required this.userName,
    this.userProfileUrl,
    required this.currentUserEmail,
    required this.postOwnerEmail,
    required this.isCurrentUserPost,
    required this.isLiked,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onSave,
    required this.onDelete,
    required this.onEdit,
    required this.onMediaTap,
    required this.userid,
  });

  @override
  State<_MediaCard> createState() => _MediaCardState();
}


class _MediaCardState extends State<_MediaCard> {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  bool _isVideoInitialized = false;
  bool _isVideoLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo && widget.imageUrl.isNotEmpty) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    if (widget.imageUrl.isEmpty) return;

    setState(() {
      _isVideoLoading = true;
    });

    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.imageUrl));
      await _controller!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _controller!,
        autoPlay: false,
        looping: true,
        showControls: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: Color(0xFF6C63FF),
          handleColor: Color(0xFF6C63FF),
          backgroundColor: Colors.grey.shade300,
          bufferedColor: Colors.grey.shade200,
        ),
        placeholder: Container(
          color: Colors.grey.shade200,
          child: Center(
            child: CircularProgressIndicator(
              color: Color(0xFF6C63FF),
            ),
          ),
        ),
      );

      setState(() {
        _isVideoInitialized = true;
        _isVideoLoading = false;
      });
    } catch (error) {
      print("Video loading error: $error");
      setState(() {
        _isVideoInitialized = false;
        _isVideoLoading = false;
      });
    }
  }

  String _formatDateTime(String dateTime) {
    try {
      final parsedDate = DateTime.parse(dateTime);
      final now = DateTime.now();
      final difference = now.difference(parsedDate);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Recently';
    }
  }




  @override
  void dispose() {
    _controller?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Widget _buildVideoContent() {
    if (_isVideoLoading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF6C63FF),
          ),
        ),
      );
    }

    if (!_isVideoInitialized || _chewieController == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off, color: Colors.grey.shade400, size: 40),
            SizedBox(height: 8),
            Text(
              'Video not available',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio > 0 ? _controller!.value.aspectRatio : 16/9,
      child: Chewie(controller: _chewieController!),
    );
  }

  Widget _buildImageContent() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Image.network(
          widget.imageUrl,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                  color: Color(0xFF6C63FF),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 40, color: Colors.grey.shade400),
                  SizedBox(height: 8),
                  Text(
                    'Failed to load image',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Header Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: widget.userProfileUrl != null &&
                      widget.userProfileUrl!.isNotEmpty
                      ? NetworkImage(widget.userProfileUrl!)
                      : null,
                  child: widget.userProfileUrl == null ||
                      widget.userProfileUrl!.isEmpty
                      ? Icon(Icons.person, size: 22, color: Colors.grey.shade600)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        _formatDateTime(widget.uploadedAt),
                        style: GoogleFonts.poppins(),
                      )],
                  ),
                ),
                const Icon(Icons.more_vert_rounded, color: Colors.grey),
              ],
            ),
          ),

          // 🔹 Image Section
          if (widget.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: GestureDetector(
                onTap: widget.onMediaTap,
                child: widget.isVideo
                    ? _buildVideoContent()
                    : Image.network(
                  widget.imageUrl,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 250,
                      color: Colors.grey.shade100,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                ),
              ),
            ),

          const SizedBox(height: 6),

          // 🔹 Action Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              children: [
                InkWell(
                  onTap: widget.onLike,
                  child: Row(
                    children: [
                      Icon(
                        widget.isLiked
                            ? FontAwesomeIcons.solidHeart
                            : FontAwesomeIcons.heart,
                        size: 22,
                        color: widget.isLiked ? Colors.redAccent : Colors.black87,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.likes.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                InkWell(
                  onTap: widget.onComment,
                  child: Row(
                    children: [
                      const FaIcon(FontAwesomeIcons.comment,
                          size: 22, color: Colors.black87),
                      const SizedBox(width: 6),
                      Text(
                        widget.comments.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                InkWell(
                  onTap: widget.onShare,
                  child: const Icon(Icons.send_rounded,
                      size: 22, color: Colors.black87),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.bookmark_border_rounded,
                      color: Colors.black54, size: 22),
                ),
              ],
            ),
          ),

          // 🔹 Caption
          if (widget.title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Text(
                widget.title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),

          const SizedBox(height: 10),
          Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ],
      ),
    );
  }



  /// 🔸 Tag Builder
  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  /// 🔸 Action Button Builder
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color ?? Colors.grey.shade800),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color ?? Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

}







class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isLiked;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isLiked = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Color(0xFF666666),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
              icon,
              size: 20,
              color: isLiked ? Colors.red : Color(0xFF666666)
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isLiked ? Colors.red : Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}

// FullScreenMediaPage remains the same as previous...
class FullScreenMediaPage extends StatefulWidget {
  final String imageUrl;
  final bool isVideo;
  final String? description;
  final String? title;

  const FullScreenMediaPage({
    super.key,
    required this.imageUrl,
    required this.isVideo,
    this.description,
    this.title,
  });

  @override
  State<FullScreenMediaPage> createState() => _FullScreenMediaPageState();
}

class _FullScreenMediaPageState extends State<FullScreenMediaPage> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.imageUrl));
      await _videoController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: true,
        looping: true,
        showControls: true,
        allowMuting: true,
        allowFullScreen: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Color(0xFF6C63FF),
          handleColor: Color(0xFF6C63FF),
          backgroundColor: Colors.grey.shade300,
        ),
      );

      setState(() {
        _isVideoInitialized = true;
      });
    } catch (error) {
      print("Full screen video error: $error");
    }
  }

  @override
  void dispose() {
    if (widget.isVideo) {
      _videoController.dispose();
      _chewieController?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Media Content
            Center(
              child: widget.isVideo
                  ? _buildFullScreenVideo()
                  : _buildFullScreenImage(),
            ),

            // Close Button
            Positioned(
              top: 16,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),

            // Description (if available)
            if (widget.description != null && widget.description!.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.title != null && widget.title!.isNotEmpty)
                        Text(
                          widget.title!,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (widget.title != null && widget.description != null) SizedBox(height: 8),
                      Text(
                        widget.description!,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullScreenVideo() {
    if (!_isVideoInitialized || _chewieController == null) {
      return Center(
        child: CircularProgressIndicator(
          color: Color(0xFF6C63FF),
        ),
      );
    }

    return Chewie(controller: _chewieController!);
  }

  Widget _buildFullScreenImage() {
    return InteractiveViewer(
      panEnabled: true,
      minScale: 0.5,
      maxScale: 3.0,
      child: Center(
        child: Image.network(
          widget.imageUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6C63FF),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 60, color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Failed to load image',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}