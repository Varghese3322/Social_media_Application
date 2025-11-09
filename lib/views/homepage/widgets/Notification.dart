import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:http/http.dart' as http;
import 'dart:convert';

class NoNotificationsPage extends StatefulWidget {
  const NoNotificationsPage({super.key});

  @override
  State<NoNotificationsPage> createState() => _NoNotificationsPageState();
}

class _NoNotificationsPageState extends State<NoNotificationsPage> {
  List<NotificationItem> notifications = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.33:8000/api/like-media/41/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        await _processApiResponse(responseData);
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
      print('Error loading notifications: $e');
    }
  }

  Future<void> _processApiResponse(Map<String, dynamic> responseData) async {
    List<NotificationItem> loadedNotifications = [];

    try {
      // Adjust these keys based on your actual API response structure
      if (responseData.containsKey('likes') && responseData['likes'] is List) {
        List<dynamic> likes = responseData['likes'];

        for (var likeData in likes) {
          try {
            NotificationItem notification = NotificationItem(
              id: likeData['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
              type: NotificationType.like,
              title: _getLikeNotificationTitle(likeData),
              description: _getLikeNotificationDescription(likeData),
              avatarUrl: likeData['user']?['profile_picture'] ?? '',
              time: _parseDateTime(likeData['created_at']),
              isRead: false,
              postImage: likeData['media']?['thumbnail_url'] ?? likeData['media']?['file_url'],
              likeData: likeData, // Store raw data for future use
            );
            loadedNotifications.add(notification);
          } catch (e) {
            print('Error parsing like data: $e');
          }
        }
      }

      // If the API returns a different structure, adjust accordingly
      if (responseData.containsKey('data') && responseData['data'] is List) {
        List<dynamic> notificationsData = responseData['data'];

        for (var notificationData in notificationsData) {
          try {
            NotificationItem notification = NotificationItem(
              id: notificationData['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
              type: _parseNotificationType(notificationData['type']),
              title: notificationData['title'] ?? 'New Notification',
              description: notificationData['message'] ?? notificationData['description'] ?? '',
              avatarUrl: notificationData['user']?['avatar'] ?? notificationData['user']?['profile_picture'] ?? '',
              time: _parseDateTime(notificationData['created_at']),
              isRead: notificationData['is_read'] ?? false,
              postImage: notificationData['media']?['image_url'] ?? notificationData['post']?['image'],
              likeData: notificationData,
            );
            loadedNotifications.add(notification);
          } catch (e) {
            print('Error parsing notification data: $e');
          }
        }
      }

      // If no specific structure found, create a default notification
      if (loadedNotifications.isEmpty) {
        loadedNotifications.add(
          NotificationItem(
            id: '1',
            type: NotificationType.system,
            title: 'Welcome to Insta X!',
            description: 'Start exploring and sharing your moments with the world',
            avatarUrl: '',
            time: DateTime.now().subtract(Duration(days: 2)),
            isRead: true,
          ),
        );
      }

      setState(() {
        notifications = loadedNotifications;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error processing notifications: $e';
        isLoading = false;
      });
    }
  }

  String _getLikeNotificationTitle(Map<String, dynamic> likeData) {
    String username = likeData['user']?['username'] ?? 'Someone';
    return '$username liked your post';
  }

  String _getLikeNotificationDescription(Map<String, dynamic> likeData) {
    String mediaType = likeData['media']?['type'] ?? 'post';
    return 'Liked your ${mediaType.toLowerCase()}';
  }

  NotificationType _parseNotificationType(String type) {
    switch (type.toLowerCase()) {
      case 'like':
        return NotificationType.like;
      case 'comment':
        return NotificationType.comment;
      case 'follow':
        return NotificationType.follow;
      default:
        return NotificationType.system;
    }
  }

  DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return DateTime.now();

    if (dateTime is String) {
      try {
        return DateTime.parse(dateTime).toLocal();
      } catch (e) {
        return DateTime.now();
      }
    }

    return DateTime.now();
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in notifications) {
        notification.isRead = true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All notifications marked as read', style: GoogleFonts.poppins()),
        backgroundColor: Color(0xFF6C63FF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear All Notifications',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to clear all notifications? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey.shade700),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                notifications.clear();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('All notifications cleared', style: GoogleFonts.poppins()),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(
              'Clear All',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _onNotificationTap(NotificationItem notification) {
    setState(() {
      notification.isRead = true;
    });

    // Handle different notification types
    switch (notification.type) {
      case NotificationType.like:
        _handleLikeNotification(notification);
        break;
      case NotificationType.comment:
        _handleCommentNotification(notification);
        break;
      case NotificationType.follow:
        _handleFollowNotification(notification);
        break;
      case NotificationType.system:
        _handleSystemNotification(notification);
        break;
    }
  }

  void _handleLikeNotification(NotificationItem notification) {
    // Navigate to the liked post
    if (notification.likeData != null) {
      final mediaId = notification.likeData!['media']?['id'];
      final userId = notification.likeData!['user']?['id'];

      // Navigate to post detail page with mediaId and userId
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigating to post...', style: GoogleFonts.poppins()),
          backgroundColor: Color(0xFF6C63FF),
        ),
      );
    }
  }

  void _handleCommentNotification(NotificationItem notification) {
    // Navigate to comments section
  }

  void _handleFollowNotification(NotificationItem notification) {
    // Navigate to user profile
  }

  void _handleSystemNotification(NotificationItem notification) {
    // Show system message details
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios, size: 18),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Color(0xFF1A1A1A)),
        actions: [
          if (notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Color(0xFF1A1A1A)),
              onSelected: (value) {
                if (value == 'mark_all_read') {
                  _markAllAsRead();
                } else if (value == 'clear_all') {
                  _clearAllNotifications();
                } else if (value == 'refresh') {
                  _loadNotifications();
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, size: 20, color: Color(0xFF6C63FF)),
                      SizedBox(width: 8),
                      Text('Refresh', style: GoogleFonts.poppins()),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      Icon(Icons.mark_email_read, size: 20, color: Color(0xFF6C63FF)),
                      SizedBox(width: 8),
                      Text('Mark all as read', style: GoogleFonts.poppins()),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Clear all', style: GoogleFonts.poppins()),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Error Message
            if (errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                color: Colors.red.shade50,
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: GoogleFonts.poppins(color: Colors.red),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          errorMessage = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],

            // Header Stats
            if (notifications.isNotEmpty) ...[
              Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Notifications',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFF6C63FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${notifications.where((n) => !n.isRead).length} New',
                        style: GoogleFonts.poppins(
                          color: Color(0xFF6C63FF),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 1),
            ],

            // Notifications List
            Expanded(
              child: isLoading
                  ? _buildLoadingState()
                  : errorMessage != null && notifications.isEmpty
                  ? _buildErrorState()
                  : notifications.isEmpty
                  ? _buildEmptyState()
                  : _buildNotificationsList(),
            ),
          ],
        ),
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
              height: 12,
              width: 120,
              color: Colors.grey.shade300,
            ),
            subtitle: Container(
              height: 10,
              width: 200,
              margin: EdgeInsets.only(top: 8),
              color: Colors.grey.shade300,
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 50,
              color: Colors.red.shade400,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Failed to Load',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 12),
          Text(
            errorMessage ?? 'Unknown error occurred',
            style: GoogleFonts.poppins(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: _loadNotifications,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6C63FF),
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Try Again',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none,
              size: 50,
              color: Colors.grey.shade400,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No Notifications',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 12),
          Text(
            "When you get notifications, they'll appear here",
            style: GoogleFonts.poppins(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: _loadNotifications,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6C63FF),
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Refresh',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      backgroundColor: Colors.white,
      color: Color(0xFF6C63FF),
      child: ListView.separated(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        itemCount: notifications.length,
        separatorBuilder: (context, index) => SizedBox(height: 8),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _NotificationTile(
            notification: notification,
            onTap: () => _onNotificationTap(notification),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
          border: notification.isRead
              ? null
              : Border.all(color: Color(0xFF6C63FF).withOpacity(0.3), width: 1),
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  if (notification.avatarUrl.isNotEmpty)
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: NetworkImage(notification.avatarUrl),
                    )
                  else
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Color(0xFF6C63FF).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getNotificationIcon(notification.type),
                        color: Color(0xFF6C63FF),
                        size: 24,
                      ),
                    ),

                  SizedBox(width: 12),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          notification.description,
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        Text(
                          timeago.format(notification.time),
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Post Image (if available)
                  if (notification.postImage != null && notification.postImage!.isNotEmpty) ...[
                    SizedBox(width: 12),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade200,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          notification.postImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.photo, color: Colors.grey.shade400);
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Unread indicator
            if (!notification.isRead)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Color(0xFF6C63FF),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return Icons.favorite;
      case NotificationType.comment:
        return Icons.comment;
      case NotificationType.follow:
        return Icons.person_add;
      case NotificationType.system:
        return Icons.info_outline;
    }
  }
}

enum NotificationType {
  like,
  comment,
  follow,
  system,
}

class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String description;
  final String avatarUrl;
  final DateTime time;
  bool isRead;
  final String? postImage;
  final Map<String, dynamic>? likeData; // Store raw API data

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.avatarUrl,
    required this.time,
    required this.isRead,
    this.postImage,
    this.likeData,
  });
}