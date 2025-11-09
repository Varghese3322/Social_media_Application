import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';



class MyApp11 extends StatelessWidget {
  const MyApp11({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Animated Notch Bottom Bar Demo',
    theme: ThemeData(primarySwatch: Colors.blue),
    home: const MyHomePage(),
  );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _pageController = PageController(initialPage: 0);
  final NotchBottomBarController _controller = NotchBottomBarController(index: 0);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomBarPages = [
      ColoredPage(color: Colors.yellow, label: 'Page 1', onTapPage: 2, controller: _controller),
      const ColoredPage(color: Colors.green, label: 'Page 2'),
      const ColoredPage(color: Colors.red, label: 'Page 3'),
      const ColoredPage(color: Colors.blue, label: 'Page 4'),
    ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: bottomBarPages,
      ),
      extendBody: true,
      bottomNavigationBar: AnimatedNotchBottomBar(
        notchBottomBarController: _controller,
        color: Colors.white,
        showLabel: true,
        itemLabelStyle: const TextStyle(fontSize: 12),
        shadowElevation: 5,
        kBottomRadius: 28.0,
        notchColor: Colors.black87,
        removeMargins: false,
        bottomBarWidth: 500,
        showShadow: false,
        durationInMilliSeconds: 300,
        elevation: 1,
        bottomBarItems: const [
          BottomBarItem(
            inActiveItem: Icon(Icons.home_filled, color: Colors.blueGrey),
            activeItem: Icon(Icons.home_filled, color: Colors.blueAccent),
            itemLabel: 'Home',
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.star, color: Colors.blueGrey),
            activeItem: Icon(Icons.star, color: Colors.blueAccent),
            itemLabel: 'Favorites',
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.settings, color: Colors.blueGrey),
            activeItem: Icon(Icons.settings, color: Colors.pink),
            itemLabel: 'Settings',
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.person, color: Colors.blueGrey),
            activeItem: Icon(Icons.person, color: Colors.yellow),
            itemLabel: 'Profile',
          ),
        ],
        onTap: (index) {
          log('Selected index: $index');
          _pageController.jumpToPage(index);
        },
        kIconSize: 24.0,
      ),
    );
  }
}

class ColoredPage extends StatelessWidget {
  final Color color;
  final String label;
  final int? onTapPage;
  final NotchBottomBarController? controller;

  const ColoredPage({
    super.key,
    required this.color,
    required this.label,
    this.onTapPage,
    this.controller,
  });

  @override
  Widget build(BuildContext context) => Container(
    color: color,
    child: Center(
      child: GestureDetector(
        onTap: onTapPage != null
            ? () => controller?.jumpTo(onTapPage!)
            : null,
        child: Text(label),
      ),
    ),
  );
}
