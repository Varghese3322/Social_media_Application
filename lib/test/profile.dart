import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Profile Image
            const CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(
                  "https://i.pravatar.cc/300"), // Dummy image
            ),
            const SizedBox(height: 10),
            // User Name
            const Text(
              "John Doe",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              "johndoe@gmail.com",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Info Cards
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: ListTile(
                leading: const Icon(Icons.phone, color: Colors.teal),
                title: const Text("Phone"),
                subtitle: const Text("+91 98765 43210"),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {},
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: ListTile(
                leading: const Icon(Icons.location_on, color: Colors.teal),
                title: const Text("Address"),
                subtitle: const Text("123, Flutter Street, India"),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {},
                ),
              ),
            ),

            // Logout Button
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                // logout action
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
            )
          ],
        ),
      ),
    );
  }
}
