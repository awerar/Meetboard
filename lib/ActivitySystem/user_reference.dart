import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meetboard/ActivitySystem/activity_reference.dart';
import 'package:meetboard/Models/user_model.dart';

class UserReference {
  final String uid;

  UserReference(this.uid);

  bool get isCurrentUser => UserModel.instance.user == this;

  DocumentReference get userDocument {
    assert(isCurrentUser);
    return Firestore.instance.collection("users").document(uid);
  }

  DocumentReference get userActivitiesDocument {
    assert(isCurrentUser);
    return userDocument.collection("private_data").document("user_activities");
  }

  DocumentReference getActivityUserDocument(ActivityReference ref) {
    assert(isCurrentUser);
    return ref.activityDocument.collection("users").document(uid);
  }

  @override
  int get hashCode => uid.hashCode;

  @override
  bool operator ==(other) {
    return (other is String && this.uid == other) || (other is UserReference && other.uid == this.uid);
  }
}