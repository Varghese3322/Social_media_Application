import 'package:flutter/material.dart';

class CategoryPage12 extends StatefulWidget {
  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage12> {
  final List<Map<String, dynamic>> categories = [
    {"name": "Gaming", "icon": Icons.videogame_asset},
    {"name": "Entertainment", "icon": Icons.movie},
    {"name": "Music", "icon": Icons.music_note},
    {"name": "Education", "icon": Icons.school},
    {"name": "Sports", "icon": Icons.sports_soccer},
    {"name": "News", "icon": Icons.newspaper},
  ];

  /// 🔹 Change this to true for single selection
  bool singleSelection = false;

  /// 🔹 For multiple selection
  Set<int> selectedIndexes = {};

  /// 🔹 For single selection
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(singleSelection ? "Single Selection" : "Multiple Selection"),
        actions: [
          Switch(
            value: singleSelection,
            onChanged: (val) {
              setState(() {
                singleSelection = val;
                selectedIndexes.clear();
                selectedIndex = null;
              });
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          itemCount: categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            bool isSelected = singleSelection
                ? selectedIndex == index
                : selectedIndexes.contains(index);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (singleSelection) {
                    // ✅ Only one selected
                    selectedIndex = index;
                  } else {
                    // ✅ Multiple selection
                    if (isSelected) {
                      selectedIndexes.remove(index);
                    } else {
                      selectedIndexes.add(index);
                    }
                  }
                });
              },
              child: Stack(
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    color: isSelected ? Colors.blue.shade100 : Colors.white,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(categories[index]["icon"],
                            size: 50,
                            color: isSelected ? Colors.blue : Colors.grey),
                        SizedBox(height: 10),
                        Text(
                          categories[index]["name"],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.blue : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ✅ Tick mark in top-right corner
                  if (isSelected)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.blue,
                        radius: 14,
                        child: Icon(Icons.check,
                            color: Colors.white, size: 18),
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


