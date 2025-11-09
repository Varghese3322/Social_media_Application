import 'package:flutter/material.dart';

class SignUpPage112 extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage112> {
  bool _agree = false; // checkbox state

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: "Email"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Enter your email";
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              TextFormField(
                decoration: InputDecoration(labelText: "Password"),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Enter your password";
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Privacy policy checkbox
              CheckboxListTile(
                value: _agree,
                onChanged: (value) {
                  setState(() {
                    _agree = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                title: Row(
                  children: [
                    Text("I agree to the "),
                    GestureDetector(
                      onTap: () {
                        // Navigate to Privacy Policy Page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PrivacyPolicyPage(),
                          ),
                        );
                      },
                      child: Text(
                        "Privacy Policy",
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    if (!_agree) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("You must agree to Privacy Policy"),
                        ),
                      );
                      return;
                    }
                    // Proceed with signup
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Signed Up Successfully!")),
                    );
                  }
                },
                child: Text("Sign Up"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrivacyPolicyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Privacy Policy")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          "Here you can show your Privacy Policy text...",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
