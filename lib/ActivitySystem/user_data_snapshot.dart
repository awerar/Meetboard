import 'package:flutter/material.dart';
import 'package:meetboard/ActivitySystem/user_reference.dart';
import 'package:meetboard/Models/user_model.dart';

enum ActivityRole {
  Owner, Participant
}

class UserDataSnapshot {
  final UserReference ref;
  final String username;
  final bool coming;
  final ActivityRole role;

  UserDataSnapshot({@required this.ref, @required this.username, @required this.coming, @required this.role});
  UserDataSnapshot.fromData(UserReference ref, Map<String, dynamic> data) : this(ref: ref, username: data["username"], coming: data["coming"], role: data["role"] == "owner" ? ActivityRole.Owner : ActivityRole.Participant);

  static UserDataSnapshot get defaultCreateUser =>
      UserDataSnapshot(
          ref: UserReference(UserModel.instance.user.uid),
          username: UserModel.instance.username,
          coming: true,
          role: ActivityRole.Owner
      );

  static UserDataSnapshot get defaultJoinUser =>
      UserDataSnapshot(
          ref: UserReference(UserModel.instance.user.uid),
          username: UserModel.instance.username,
          coming: true,
          role: ActivityRole.Participant
      );

  static UserDataSnapshot get defaultUser =>
      UserDataSnapshot(
          ref: UserReference(UserModel.instance.user.uid),
          username: UserModel.instance.username,
          coming: true,
          role: ActivityRole.Participant
      );

  @override
  int get hashCode => ref.hashCode;

  @override
  bool operator ==(other) {
    return (other is UserDataSnapshot && this.ref == other.ref) || (other is UserReference && this.ref == other);
  }
}