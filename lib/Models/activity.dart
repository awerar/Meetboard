import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

//TODO: Make the activity automatically update when user data changes
class Activity {
  final String name;
  final DateTime time;
  final Map<String, UserActivityData> users;
  final String id;

  Activity({@required this.name, @required this.time, @required Map<String, UserActivityData> users, @required this.id}) : users = Map.unmodifiable(users);

  static Future<Activity> fromSnapshot(DocumentSnapshot snapshot) async {
    var query = await snapshot.reference.collection("users").getDocuments();
    Map<String, UserActivityData> users = Map();
    for(DocumentSnapshot snapshot in query.documents) {
      users[snapshot.documentID] = UserActivityData.fromSnapshot(snapshot);
    }

    return Activity(time: (snapshot.data["time"] as Timestamp).toDate(), name: snapshot.data["name"], users: users, id: snapshot.documentID);
  }

  Activity copyWith({String name, DateTime time}) {
    return Activity(name: name == null ? this.name : name, time: time == null ? this.time : time, users: users, id: id);
  }

  Map<String, dynamic> encode() {
    return {
      "name": name,
      "time": Timestamp.fromDate(time)
    };
  }
}

class UserActivityData {
  final String uid;
  final ActivityRole role;

  UserActivityData({@required this.uid, @required this.role});

  static UserActivityData fromSnapshot(DocumentSnapshot snapshot) {
    return UserActivityData(role: snapshot.data["role"] == "owner" ? ActivityRole.Owner : ActivityRole.Participant, uid: snapshot.documentID);
  }
}

enum ActivityRole {
  Owner, Participant
}