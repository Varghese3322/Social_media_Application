import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryListPage extends StatelessWidget {
  const CategoryListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Category list with background images
    final category = [
      {
        "title": "Comedy",
        "color": Colors.orangeAccent,
        "icon": Icons.mic_none,
        "image": "assets/images/emoticon-emoji-group-vector-design-260nw-1576163983.webp"
      },
      {
        "title": "Social",
        "color": Colors.purpleAccent,
        "icon": Icons.share_location_rounded,
        "image": "assets/images/360_F_389328016_ak3iUrk15slWfEZdYL96O6eKTUyImDeC.jpg"
      },
      {
        "title": "Politics",
        "color": Colors.amber,
        "icon": Icons.history_edu_outlined,
        "image": "assets/images/politis.jpg"
      },
      {
        "title": "Technologies",
        "color": Colors.tealAccent,
        "icon": Icons.computer,
        "image": "assets/images/bigstock-Technology-And-Biometric-Conce-213062104_kygpiv.jpg"
      },
      {
        "title": "News",
        "color": Colors.cyanAccent,
        "icon": Icons.newspaper,
        "image": "assets/images/news.jpg"
      },
      {
        "title": "Nature",
        "color": Colors.redAccent,
        "icon": Icons.star_border,
        "image": "assets/images/nature.jpg"
      },
      {
        "title": "Sports",
        "color": Colors.greenAccent,
        "icon": Icons.sports_esports_outlined,
        "image": "assets/images/sports.jpg"
      },
      {
        "title": "Fashion Lifestyle",
        "color": Colors.orange,
        "icon": Icons.favorite_border,
        "image": "assets/images/lifestyle.png"
      },
    ];

    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- Header ----------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Explore",
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ---------- GridView ----------
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.6,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: category.length,
                  itemBuilder: (context, index) {
                    final cat = category[index];
                    return _buildCategoryCard(
                      title: cat["title"] as String,
                      color: cat["color"] as Color,
                      icon: cat["icon"] as IconData,
                      imagePath: cat["image"] as String,
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

  // ---------- Tab Button ----------
  Widget _buildTab(String text, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.black : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: isActive ? Colors.white : Colors.black54,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ---------- Category Card ----------
  Widget _buildCategoryCard({
    required String title,
    required Color color,
    required IconData icon,
    String? imagePath,
  }) {
    return GestureDetector(
      onTap: () {
        // TODO: Handle category tap
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          image: imagePath != null
              ? DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          )
              : null,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.1),
                Colors.black.withOpacity(0.5),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: 12,
                top: 12,
                child: Icon(
                  icon,
                  color: Colors.white.withOpacity(0.9),
                  size: 28,
                ),
              ),
              Positioned(
                left: 16,
                bottom: 16,
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
