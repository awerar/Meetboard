import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserActivity {
  final String name, id;
  final DateTime time;
  final bool coming;

  UserActivity(this.name, this.time, {this.coming = true, this.id = ""});

  UserActivity copyWith({String name, DateTime time, String id, bool coming}) {
    return UserActivity(name == null ? this.name : name, time == null ? this.time : time, coming: coming == null ? this.coming : coming, id: id == null ? this.id : id);
  }

  static UserActivity fromDocument(DocumentSnapshot document) {
    return UserActivity(document.data["Name"], document.data["Time"].toDate(), coming: document["Coming"], id: document.reference.documentID);
  }

  Map<String, dynamic> encode() {
    return {
      "Time": Timestamp.fromDate(time),
      "Coming": coming,
      "Name": name
    };
  }
}