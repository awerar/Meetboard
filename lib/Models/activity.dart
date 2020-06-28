import 'package:cloud_firestore/cloud_firestore.dart';

class Activity {
  String name;
  DateTime time;

  Activity(String name, DateTime time) {
    this.name = name;
    this.time = time;
  }

  Map<String, dynamic> fireStoreMap() {
    return {
      "Name": name,
      "Time": Timestamp.fromDate(time)
    };
  }
}