import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityPreview {
  final String name, id;
  final DateTime time;
  final bool coming;

  ActivityPreview(this.name, this.time, {this.coming = true, this.id = ""});

  ActivityPreview copyWith({String name, DateTime time, String id, bool coming}) {
    return ActivityPreview(name == null ? this.name : name, time == null ? this.time : time, coming: coming == null ? this.coming : coming, id: id == null ? this.id : id);
  }

  static ActivityPreview fromDocument(DocumentSnapshot document) {
    return ActivityPreview(document.data["name"], document.data["time"].toDate(), coming: document["coming"], id: document.reference.documentID);
  }

  Map<String, dynamic> encode() {
    return {
      "time": time.millisecondsSinceEpoch,
      "coming": coming,
      "name": name,
    };
  }
}