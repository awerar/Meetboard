import 'package:flutter/material.dart';
import 'package:meetboard/ActivitySystem/user_reference.dart';
import 'package:meetboard/Models/user_model.dart';

enum ActivityRole {
  Owner, Participant
}

class UserDataSnapshot {
  final String uid;
  final String username;
  final bool coming;
  final ActivityRole role;

  UserReference get ref => UserReference(uid);

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

  static UserDataSnapshot getDefaultJoinUser() {
    return UserDataSnapshot(
        uid: UserModel.instance.user.uid,
        username: UserModel.instance.username,
        coming: true,
        role: ActivityRole.Participant
    );
  }

  @override
  int get hashCode => uid.hashCode;

  @override
  bool operator ==(other) {
    return (other is UserDataSnapshot && this.uid == other.uid) || (other is String && this.uid == other);
  }
}