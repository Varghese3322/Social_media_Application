import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:publisher_app/views/OTPpage/widgets/verification.dart';

import '../../main.dart';

class OTPverificationPage extends StatefulWidget {
  const OTPverificationPage({super.key});

  @override
  State<OTPverificationPage> createState() => _OTPverificationPageState();
}

class _OTPverificationPageState extends State<OTPverificationPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.teal,Colors.green.shade500])
      ),
      child: SafeArea(
        child: Scaffold(
            appBar: AppBar(backgroundColor: Colors.white,
              leading: InkWell(onTap: (){
                Navigator.of(context).pop();
              },
                  child: Icon(Icons.arrow_back_ios,
                    color: Colors.black,
                    size: 18,
                  )),),
        body:
        Container(
        height: scrHeight,
        width: scrWidth,
        decoration: BoxDecoration(
        gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white,Colors.white])
        ),
            child:
            OtpScreenpage(phone: '', otp: '',) ,
        )),
      ),
    );
  }
}
