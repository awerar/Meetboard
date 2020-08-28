import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meetboard/Models/ActivityListModel.dart';

class ActivityReference {
  final String id;

  ActivityReference(this.id);

  ActivitySubscription listen(OnActivityChangeFunction onChange) {
    return ActivityListModel.instance.listenForActivityChange(this, onChange);
  }

  DocumentReference get activityDocument => Firestore.instance.collection("activities").document(id);

  @override
  int get hashCode => id.hashCode;
}