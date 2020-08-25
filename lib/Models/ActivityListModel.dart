import 'package:flutter/material.dart';
import 'package:meetboard/ActivitySystem/ActivityListener.dart';
import 'package:meetboard/ActivitySystem/ActivityReference.dart';
import 'package:meetboard/ActivitySystem/ActivitySnapshot.dart';

typedef OnActivityChangeFunction = void Function(ActivitySnapshot snapshot);

class ActivityListModel with ChangeNotifier {
  static ActivityListModel instance;

  Map<ActivityReference, List<OnActivityChangeFunction>> _onChangeFunctions = Map();
  Map<ActivityReference, ActivityListener> _activityListeners = Map();

  ActivitySubscription listenForActivityChange(ActivityReference ref, OnActivityChangeFunction onChange) {
    assert(_onChangeFunctions.containsKey(ref));

    _onChangeFunctions[ref].add(onChange);
    return ActivitySubscription(() => _onChangeFunctions[ref].remove(onChange));
  }
}

class ActivitySubscription {
  bool _hasStopped;

  final void Function() _stop;

  ActivitySubscription(this._stop);

  void stop() {
    if (!_hasStopped) {
      _hasStopped = true;
      _stop();
    }
  }
}