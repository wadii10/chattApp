import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String photoUrl;
  final String nickname;
  //final DateTime createdAt;

  User({
    required this.id,
    required this.photoUrl,
    required this.nickname,
    //required this.createdAt,
  });

  factory User.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;

    return User(
      id: doc.id,
      photoUrl: data['photoUrl'],
      nickname: data['nickname'],
      //createdAt: data['createdAt'],
    );
  }
}