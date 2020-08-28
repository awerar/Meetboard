import 'package:flutter/material.dart';
import 'package:meetboard/ActivitySystem/activity_reference.dart';

class ActivityPreviewSnapshot {
  final String name;
  final DateTime time;
  final bool coming;
  final ActivityReference ref;

  ActivityPreviewSnapshot({@required this.name, @required this.time, @required this.coming, @required this.ref});
}