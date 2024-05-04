import 'package:appsocial/main.dart';
import 'package:appsocial/models/user.dart';
import 'package:appsocial/pages/setting.dart';
import 'package:appsocial/widgets/progress_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  final String currentUserId;
  const HomePage({super.key, required this.currentUserId});

  @override
  State<HomePage> createState() => _HomePageState(currentUserId: currentUserId);
}

class _HomePageState extends State<HomePage> {

  _HomePageState({super.key, required this.currentUserId});

  
  TextEditingController searchtextEditingController = TextEditingController();
  Future<QuerySnapshot> futureSearchResult;
  final String currentUserId;


  HomePageHeader(){
    return AppBar(
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
            onPressed: (){
              Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsOpt()));
            },
            icon: Icon(Icons.settings, size:30, color: Colors.white)
        )
      ],
      elevation: 0,
      backgroundColor: Colors.grey.shade900,
      title: Container(
        height: 38,
        child: TextField(
          controller: searchtextEditingController,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[850],
              contentPadding: EdgeInsets.all(0),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade500,),
              suffixIcon: IconButton(
                onPressed: emptyText,
                icon: Icon(Icons.clear_rounded, color: Colors.grey.shade500,),),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: BorderSide.none
              ),
              hintStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500
              ),
              hintText: "Search users"
          ),
          onSubmitted: controlSearching,
        ),
      ),
    );
  }

  controlSearching(String userName) {
    Future<QuerySnapshot> allFoundUsers = FirebaseFirestore.instance.collection("users")
        .where("nickname", isGreaterThanOrEqualTo: userName).get();

    setState(() {
      futureSearchResult = allFoundUsers;
    });
  }

  emptyText() {
    searchtextEditingController.clear();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomePageHeader(),
      body: futureSearchResult == null ? displayNoSearchResult() :displaySearchResult(),
    );
  }

  displaySearchResult(){
    return FutureBuilder(
        future: futureSearchResult,
        builder: (context, dataSnapshot) {

          if(!dataSnapshot.hasData){
            return circularProgress();
          }

          List<UserResult> searchUserResult = [];
          dataSnapshot.data?.docs.forEach((doc) {
            User eachUser = User.fromDocument(doc);
            UserResult userResult = UserResult(eachUser);

            if(currentUserId != doc["id"]){
              searchUserResult.add(userResult);
            }
          });

          return ListView(
            children:
            searchUserResult
          ,);
        },
    );
  }

  displayNoSearchResult() {
    final Orientation orientation = MediaQuery.of(context).orientation;

    return Container(
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: [
            Icon(Icons.group, color: Colors.grey, size: 200.0),
            Text(
              "search users",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.blueAccent,
                fontSize: 50.0,
                fontWeight: FontWeight.w500
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserResult extends StatelessWidget {

  final User eachUser;
  UserResult(this.eachUser);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(4.0),
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            GestureDetector(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.black,
                  backgroundImage: CachedNetworkImageProvider(
                    eachUser.photoUrl
                  ),
                ),
                title: Text(
                  eachUser.nickname,
                  style: TextStyle(
                    color: Colors.black, fontSize: 16.0, fontWeight: FontWeight.bold
                  ),
                ),
                subtitle: Text(
                  "joined: " + eachUser.createdAt.toString(),
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14.0,
                    fontStyle: FontStyle.italic
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

}




