import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:video_player/video_player.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ added

class PhotoVideoUploadForm extends StatefulWidget {
  const PhotoVideoUploadForm({super.key});

  @override
  State<PhotoVideoUploadForm> createState() => _PhotoVideoUploadFormState();
}

class _PhotoVideoUploadFormState extends State<PhotoVideoUploadForm> {
  final _formKey = GlobalKey<FormState>();
  File? _file;
  String? _fileType; // "image" or "video"
  final ImagePicker picker = ImagePicker();
  VideoPlayerController? _videoController;
  bool _isUploading = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String? _selectedCategory;
  String? _selectedSubCategory;

  final List<String> _categories = [
    "Nature",
    "Technology",
    "Food",
    "Travel",
    "Lifestyle",
    "Education",
    "Art",
    "Sports",
  ];

  final Map<String, List<String>> _subCategories = {
    "Nature": ["Mountains", "Rivers", "Forests", "Animals", "Beaches"],
    "Technology": ["AI", "Robotics", "Gadgets", "Software", "Mobile"],
    "Food": ["Recipes", "Restaurants", "Healthy", "Desserts"],
    "Travel": ["Adventure", "Cultural", "Beaches", "Cities", "Road Trips"],
    "Lifestyle": ["Fashion", "Home", "Fitness", "Beauty"],
    "Education": ["Learning", "Tutorials", "Schools", "Online Courses"],
    "Art": ["Digital Art", "Painting", "Photography", "Sculpture"],
    "Sports": ["Football", "Basketball", "Cricket", "Tennis", "Fitness"],
  };

  // ✅ Pick Image or Video
  Future<void> _pickMedia({required bool isVideo}) async {
    final XFile? pickedFile = isVideo
        ? await picker.pickVideo(source: ImageSource.gallery)
        : await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _file = File(pickedFile.path);
        _fileType = isVideo ? "video" : "image";
      });

      if (isVideo) {
        _videoController?.dispose();
        _videoController = VideoPlayerController.file(_file!)
          ..initialize().then((_) {
            setState(() {});
            _videoController!.play();
          });
      }
    }
  }

  // ✅ Upload API with SharedPreferences user_id
  Future<void> _uploadFile() async {
    if (_file == null) {
      _showSnackBar("Please select a file", Colors.orange);
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // ✅ Get stored user_id from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('user_id');
      print("userId  ${userId}");
      if (userId == null) {
        _showSnackBar("User ID not found. Please log in again.", Colors.red);
        setState(() => _isUploading = false);
        return;
      }

      var uri = Uri.parse("http://192.168.1.33:8000/api/upload/");
      var request = http.MultipartRequest('POST', uri);

      // ✅ Detect MIME type
      final mimeType = lookupMimeType(_file!.path);
      final mimeSplit = mimeType?.split('/') ?? ['application', 'octet-stream'];

      // ✅ File field
      request.files.add(await http.MultipartFile.fromPath(
        'image', // backend accepts both image/video
        _file!.path,
        contentType: MediaType(mimeSplit[0], mimeSplit[1]),
      ));

      // ✅ Add text fields
      request.fields['user'] = userId; // 🔥 Add user ID here
      request.fields['title'] = _titleController.text;
      request.fields['description'] = _descController.text;
      request.fields['category'] = _selectedCategory ?? "General";
      request.fields['subcategory'] = _selectedSubCategory ?? "Other";

      // ✅ Send request
      var response = await request.send();
      var respStr = await response.stream.bytesToString();
      print("Response: $respStr");

      if (response.statusCode == 201 || response.statusCode == 200) {
        _showSnackBar("Uploaded successfully!", Colors.green);
        _clearForm();
      } else {
        _showSnackBar("Upload failed: $respStr", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Error: $e", Colors.red);
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _clearForm() {
    setState(() {
      _file = null;
      _fileType = null;
      _titleController.clear();
      _descController.clear();
      _selectedCategory = null;
      _selectedSubCategory = null;
      _videoController?.dispose();
      _videoController = null;
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Color(0xFF1A1A1A)),
        ),
        title: Text(
          "Create Post",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMediaUploadSection(),
                const SizedBox(height: 24),
                _buildFormFields(),
                const SizedBox(height: 24),
                _buildUploadButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaUploadSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Add Media",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              if (_file != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullScreenMediaView(
                      file: _file!,
                      fileType: _fileType!,
                    ),
                  ),
                );
              } else {
                _showPicker(context);
              }
            },
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: _file == null
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_upload_outlined, size: 50, color: Colors.teal),
                  const SizedBox(height: 12),
                  Text(
                    "Tap to upload photo or video",
                    style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Supports: JPG, PNG, MP4",
                    style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              )
                  : _fileType == "image"
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_file!, fit: BoxFit.cover, width: double.infinity),
              )
                  : _videoController != null && _videoController!.value.isInitialized
                  ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    ),
                  ),
                  const Positioned(
                    bottom: 10,
                    right: 10,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      radius: 14,
                      child: Icon(Icons.play_arrow, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              )
                  : const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Post Details",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 16),
          _textField("Title", "Enter post title", _titleController),
          const SizedBox(height: 16),
          _textField("Description", "Describe your post...", _descController, maxLines: 3),
          const SizedBox(height: 16),
          _buildDropdown("Category", _categories, _selectedCategory, (value) {
            setState(() {
              _selectedCategory = value;
              _selectedSubCategory = null;
            });
          }),
          if (_selectedCategory != null) ...[
            const SizedBox(height: 16),
            _buildDropdown("Subcategory", _subCategories[_selectedCategory] ?? [],
                _selectedSubCategory, (value) {
                  setState(() => _selectedSubCategory = value);
                }),
          ],
        ],
      ),
    );
  }

  Widget _textField(String label, String hint, TextEditingController controller,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500, fontSize: 14, color: Colors.grey.shade700)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: GoogleFonts.poppins(fontSize: 14),
            validator: (value) => value!.isEmpty ? "Required field" : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? selectedValue, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500, fontSize: 14, color: Colors.grey.shade700)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonFormField<String>(
            value: selectedValue,
            decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16)),
            items: items.map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: GoogleFonts.poppins(fontSize: 14)))).toList(),
            onChanged: onChanged,
            validator: (value) => value == null ? "Required field" : null,
          ),
        ),
      ],
    );
  }

  Widget _buildUploadButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isUploading
            ? null
            : () {
          if (_formKey.currentState!.validate() && _file != null) {
            _uploadFile();
          } else {
           ;
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        child: _isUploading
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
                width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            const SizedBox(width: 12),
            Text("Uploading...", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        )
            : Text("Upload Post", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600,color: Colors.white)),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Text("Choose Media Type",
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: const Color(0xFF1A1A1A))),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: _PickerOption(
                  icon: Icons.photo,
                  title: "Photo",
                  color: const Color(0xFF6C63FF),
                  onTap: () {
                    Navigator.pop(context);
                    _pickMedia(isVideo: false);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PickerOption(
                  icon: Icons.videocam,
                  title: "Video",
                  color: const Color(0xFFFF6584),
                  onTap: () {
                    Navigator.pop(context);
                    _pickMedia(isVideo: true);
                  },
                ),
              ),
            ]),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _PickerOption(
      {required this.icon, required this.title, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(children: [
          Icon(icon, size: 30, color: color),
          const SizedBox(height: 8),
          Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: color)),
        ]),
      ),
    );
  }
}

// ✅ Fullscreen Preview
class FullScreenMediaView extends StatefulWidget {
  final File file;
  final String fileType;

  const FullScreenMediaView({super.key, required this.file, required this.fileType});

  @override
  State<FullScreenMediaView> createState() => _FullScreenMediaViewState();
}

class _FullScreenMediaViewState extends State<FullScreenMediaView> {
  VideoPlayerController? _controller;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    if (widget.fileType == "video") {
      _controller = VideoPlayerController.file(widget.file)
        ..initialize().then((_) {
          setState(() {});
          _controller!.play();
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          if (widget.fileType == "video" && _controller != null) {
            setState(() {
              if (_controller!.value.isPlaying) {
                _controller!.pause();
                _isPlaying = false;
              } else {
                _controller!.play();
                _isPlaying = true;
              }
            });
          }
        },
        child: Center(
          child: widget.fileType == "image"
              ? Image.file(widget.file, fit: BoxFit.contain)
              : _controller != null && _controller!.value.isInitialized
              ? AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          )
              : const CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
  }
}
