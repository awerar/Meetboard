import 'package:flutter/material.dart';
import 'package:meetboard/ActivitySystem/activity_reference.dart';
import 'package:meetboard/ActivitySystem/user_data_snapshot.dart';
import 'package:meetboard/Models/user_model.dart';

class ActivitySnapshot {
  final ActivityReference ref;

  final String name;
  final DateTime time;
  final Map<String, UserDataSnapshot> users;

  UserDataSnapshot get currentUser => users[UserModel.instance.user.uid];

  ActivitySnapshot({@required this.ref, @required this.name, @required this.time, @required List<UserDataSnapshot> users}) : this.users = Map.fromIterable(users, key: (u) => u.uid);
}