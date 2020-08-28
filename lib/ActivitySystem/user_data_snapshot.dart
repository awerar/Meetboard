import 'package:flutter/material.dart';
import 'package:meetboard/Models/user_model.dart';

enum ActivityRole {
  Owner, Participant
}

class UserDataSnapshot {
  final String uid;
  final String username;
  final bool coming;
  final ActivityRole role;

  UserDataSnapshot({@required this.uid, @required this.username, @required this.coming, @required this.role});
  UserDataSnapshot.fromData(String uid, Map<String, dynamic> data) : this(uid: uid, username: data["username"], coming: data["coming"], role: data["role"] == "owner" ? ActivityRole.Owner : ActivityRole.Participant);

  static UserDataSnapshot getDefaultCreateUser() {
    return UserDataSnapshot(
      uid: UserModel.instance.user.uid,
      username: UserModel.instance.username,
      coming: true,
      role: ActivityRole.Owner
    );
  }

  @override
  int get hashCode => uid.hashCode;
}