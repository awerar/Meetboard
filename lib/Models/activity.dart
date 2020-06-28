import 'package:cloud_firestore/cloud_firestore.dart';

class Activity {
  String name, code;
  DateTime time;
  bool coming;

  Activity(this.name, this.time, {this.coming = true, this.code = ""});

  Map<String, dynamic> fireStoreMap() {
    return {
      "Name": name,
      "Time": Timestamp.fromDate(time),
      "Coming": coming
    };
  }
}