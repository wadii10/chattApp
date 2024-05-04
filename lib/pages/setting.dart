import 'dart:html';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  TextEditingController nickNameController =TextEditingController();
  TextEditingController aboutMeController =TextEditingController();

  SharedPreferences ?preferences;
  String id="";
  String nickname="";
  String photoUrl="";
  String aboutMe="";
  File ?imageAvatar;
  bool isLoading = false;



@override
void initState() {
    // TODO: implement initState
    readDataFromLocal();
  }


  void readDataFromLocal()async{

    preferences = await SharedPreferences.getInstance();
    id=preferences!.getString("id")!;
    nickname=preferences!.getString("nickname")!;
    photoUrl=preferences!.getString("photoUrl")!;
    aboutMe=preferences!.getString("aboutMe")!;

    nickNameController =TextEditingController(text: nickname);
    aboutMeController =TextEditingController(text: aboutMe);

    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            children: [
              // Profile Image - Avatar
              Container(
                child: Center(
                  child: Stack(
                    children: [
                      // Conditional logic for displaying avatar
                      (imageAvatar == null)
                          ? (photoUrl != "")
                          ?  Material() : Icon(Icons.account_circle, size: 90.0, color: Colors.grey,)
                         : Material()
                    ],
                  ),
                ),
              ),
              // Add other widgets for your profile section here
            ],
          ),
        ),
      ],
    );
  }

}





