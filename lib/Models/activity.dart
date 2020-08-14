import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class Activity {
  final String name;
  final DateTime time;
  final Map<String, UserActivityData> users;
  final String id;

  Activity({@required this.name, @required this.time, @required Map<String, UserActivityData> users, @required this.id}) : users = Map.unmodifiable(users);

  static Activity fromSnapshot(DocumentSnapshot snapshot) {
    Map<String, UserActivityData> users = Map();
    (Map<dynamic, dynamic>.from(snapshot.data["users"])).forEach((uid, data) {
      users[uid] = UserActivityData.fromData(Map<String, dynamic>.from(data), uid);
    });

    return Activity(time: (snapshot.data["time"] as Timestamp).toDate(), name: snapshot.data["name"], users: users, id: snapshot.documentID);
  }

  Activity copyWith({String name, DateTime time, String id}) {
    return Activity(
        name: name == null ? this.name : name,
        time: time == null ? this.time : time,
        id: id == null ? this.id : id,
        users: users
    );
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
  final bool coming;
  final String username;

  UserActivityData({@required this.uid, @required this.role, @required this.coming, @required this.username});

  static UserActivityData fromData(Map<String, dynamic> data, String uid) {
    return UserActivityData(role: data["role"] == "owner" ? ActivityRole.Owner : ActivityRole.Participant, uid: uid, coming: data["coming"], username: data["username"]);
  }

  Map<String, dynamic> getUpdateData({bool coming}) {
    Map<String, dynamic> data = Map();

    if (coming != null) data["coming"] = coming;

    return data;
  }
}

enum ActivityRole {
  Owner, Participant
}