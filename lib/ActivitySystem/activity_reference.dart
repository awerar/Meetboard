import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:meetboard/ActivitySystem/activity_handler.dart';
import 'package:meetboard/ActivitySystem/activity_snapshot.dart';

import 'activity_tracking_manager.dart';

class ActivityReference {
  final String id;

  ActivityReference(this.id);

  DocumentReference get activityDocument => Firestore.instance.collection("activities").document(id);

  Stream<ActivitySnapshot> get changeStream {
    assert(exists);
    return ActivityTrackingManager.instance.getActivityChangeStream(this);
  }

  bool get exists => ActivityTrackingManager.instance.trackingActivity(this);

  Future<void> join() {
    return ActivityTrackingManager.instance.joinActivity(this);
  }

  static Future<ActivityReference> create(String name, DateTime time) {
    return ActivityTrackingManager.instance.createActivity(name, time);
  }

  void write(ActivityWriteFunc writeFunc) {
    assert(exists);
    ActivityTrackingManager.instance.write(this, writeFunc);
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

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(other) {
    return this.hashCode == other.hashCode && other is ActivityReference;
  }
}