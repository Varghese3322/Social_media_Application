import 'package:flutter/material.dart';

class GenderCheckPage extends StatefulWidget {
  @override
  _GenderCheckPageState createState() => _GenderCheckPageState();
}

class _GenderCheckPageState extends State<GenderCheckPage> {
  String? _gender; // holds selected gender

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Gender Selection")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Select Gender",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),

            RadioListTile<String>(
              title: Text("Male"),
              value: "Male",
              groupValue: _gender,
              onChanged: (value) {
                setState(() {
                  _gender = value;
                });
              },
            ),
            RadioListTile<String>(
              title: Text("Female"),
              value: "Female",
              groupValue: _gender,
              onChanged: (value) {
                setState(() {
                  _gender = value;
                });
              },
            ),
            RadioListTile<String>(
              title: Text("Other"),
              value: "Other",
              groupValue: _gender,
              onChanged: (value) {
                setState(() {
                  _gender = value;
                });
              },
            ),

            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (_gender != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Selected Gender: $_gender")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please select a gender")),
                    );
                  }
                },
                child: Text("Submit"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
