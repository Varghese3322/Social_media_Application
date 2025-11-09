import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:publisher_app/main.dart';
import 'package:publisher_app/views/forgotpassword/widgets/forgot.dart';

class ForgotPasswordpage extends StatefulWidget {
  const ForgotPasswordpage({super.key});

  @override
  State<ForgotPasswordpage> createState() => _ForgotPasswordpageState();
}

class _ForgotPasswordpageState extends State<ForgotPasswordpage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: scrHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.teal,Colors.green.shade500])
      ),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(backgroundColor: Colors.white,
            leading: InkWell(onTap: (){
              Navigator.of(context).pop();
            },
                child: Icon(Icons.arrow_back_ios,
                  color: Colors.black,
                  size: 18,
                )),),
          body: Container(
        height: scrHeight,
        width: scrWidth,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white,Colors.white])
        ),
        child:

        // Forgot your Password
         ForgotyourAccount(),
          ),

        ),
      ),
    );
  }
}
