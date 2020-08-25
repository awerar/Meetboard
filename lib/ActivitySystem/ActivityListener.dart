import 'package:flutter/material.dart';
import 'package:meetboard/ActivitySystem/ActivityReference.dart';

class ActivityListener with ChangeNotifier {
  final ActivityReference ref;

  ActivityListener(this.ref);
}