import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/cupertino.dart';

class Activity {
  final String name;
  final DateTime time;
  final Map<String, UserActivityData> users;
  final String id;

  DocumentReference get activityDocument => Firestore.instance.collection("activities").document(id);

  Activity({@required this.name, @required this.time, @required Map<String, UserActivityData> users, @required this.id}) : users = Map.unmodifiable(users);

  Activity.fromSnapshot(DocumentSnapshot snapshot) :
        name = snapshot.data["name"],
        time = (snapshot.data["time"] as Timestamp).toDate(),
        id = snapshot.documentID,
        users = (Map<dynamic, dynamic>.from(snapshot.data["users"])).map((uid, data) {
          return MapEntry(
              uid,
              UserActivityData.fromData(Map<String, dynamic>.from(data), uid, Firestore.instance.collection("activities").document(snapshot.documentID))
          );
        });

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

  DocumentReference getUserDataDocument(String uid) {
    return activityDocument.collection("users").document(uid);
  }

  DynamicLinkParameters getInviteLinkParams() {
    return DynamicLinkParameters(
      link: Uri.parse("http://meetboard/activities/join?code=$id"),
      uriPrefix: "https://meetboard.page.link",
      androidParameters: AndroidParameters(
        packageName: "awerar.meetboard",
      ),
      iosParameters: IosParameters(
        bundleId: "awerar.meetboard"
      ),
      dynamicLinkParametersOptions: DynamicLinkParametersOptions(
        shortDynamicLinkPathLength: ShortDynamicLinkPathLength.unguessable
      )
    );
  }
}

class UserActivityData {
  final String uid;
  final ActivityRole role;
  final bool coming;
  final String username;

  UserActivityData({@required this.uid, @required this.role, @required this.coming, @required this.username});

  static UserActivityData fromData(Map<String, dynamic> data, String uid, DocumentReference activityDoc) {
    return UserActivityData(role: data["role"] == "owner" ? ActivityRole.Owner : ActivityRole.Participant, uid: uid, coming: data["coming"], username: data["username"]);
  }

  Map<String, dynamic> getUpdateData({bool coming}) {
    Map<String, dynamic> data = Map();

    if (coming != null) data["coming"] = coming;

    return data;
  }

  @override
  int get hashCode => uid.hashCode;

  @override
  bool operator ==(other) {
    return other is UserActivityData && uid == other.uid;
  }
}

enum ActivityRole {
  Owner, Participant
}