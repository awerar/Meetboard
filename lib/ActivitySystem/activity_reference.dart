import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meetboard/ActivitySystem/activity_snapshot.dart';

import 'activity_tracking_manager.dart';

class ActivityReference {
  final String id;

  ActivityReference(this.id);

  Stream<ActivitySnapshot> getChangeStream() {
    return ActivityTrackingManager.instance.getActivityChangeStream(this);
  }

  DocumentReference get activityDocument => Firestore.instance.collection("activities").document(id);

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(other) {
    return this.hashCode == other.hashCode && other is ActivityReference;
  }
}