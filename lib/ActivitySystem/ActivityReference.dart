import 'package:flutter/material.dart';
import 'package:meetboard/ActivitySystem/ActivitySnapshot.dart';
import 'package:meetboard/Models/ActivityListModel.dart';

class ActivityReference {
  final String id;

  ActivityReference(this.id);

  ActivitySubscription listen(OnActivityChangeFunction onChange) {
    return ActivityListModel.instance.listenForActivityChange(this, onChange);
  }

  @override
  int get hashCode => id.hashCode;
}