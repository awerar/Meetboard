import 'package:flutter/material.dart';
import 'package:meetboard/Models/user_model.dart';

class UserDataSnapshot {
  final String uid;
  final String username;
  final bool coming;

  UserDataSnapshot({@required this.uid, @required this.username, @required this.coming});
  UserDataSnapshot.fromData(String uid, Map<String, dynamic> data) : this(uid: uid, username: data["username"], coming: data["coming"]);

  static UserDataSnapshot getDefaultCreateUser() {
    return UserDataSnapshot(
      uid: UserModel.instance.user.uid,
      username: UserModel.instance.username,
      coming: true
    );
  }

  @override
  // TODO: implement hashCode
  int get hashCode => uid.hashCode;
}