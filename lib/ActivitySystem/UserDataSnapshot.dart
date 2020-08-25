import 'package:flutter/material.dart';

class UserDataSnapshot {
  final String uid;
  final String username;
  final bool coming;

  UserDataSnapshot({@required this.uid, @required this.username, @required this.coming});
}