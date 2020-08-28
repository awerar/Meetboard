import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meetboard/ActivitySystem/ActivitySnapshot.dart';
import 'package:meetboard/Models/activity_list_model.dart';

class ActivityReference {
  final String id;

  ActivityReference(this.id);

  Stream<ActivitySnapshot> getChangeStream() {
    return ActivityListModel.instance.getActivityChangeStream(this);
  }

  DocumentReference get activityDocument => Firestore.instance.collection("activities").document(id);

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(other) {
    // TODO: implement ==
    return this.hashCode == other.hashCode && other is ActivityReference;
  }
}