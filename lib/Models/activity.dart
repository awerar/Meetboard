import 'package:cloud_firestore/cloud_firestore.dart';

class Activity {
  final String name, id;
  final DateTime time;
  final bool coming;

  Activity(this.name, this.time, {this.coming = true, this.id = ""});

  Activity copyWith({String name, DateTime time, String id, bool coming}) {
    return Activity(name == null ? this.name : name, time == null ? this.time : time, coming: coming == null ? this.coming : coming, id: id == null ? this.id : id);
  }

  static Activity fromDocument(DocumentSnapshot document) {
    return Activity(document.data["Name"], document.data["Time"].toDate(), coming: document["Coming"], id: document.reference.documentID);
  }

  Map<String, dynamic> encode() {
    return {
      "Time": Timestamp.fromDate(time),
      "Coming": coming,
      "Name": name
    };
  }
}