import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meetboard/ActivitySystem/ActivityReference.dart';
import 'package:meetboard/ActivitySystem/ActivitySnapshot.dart';

class ActivityHandler with ChangeNotifier {
  final ActivityReference ref;

  DocumentSnapshot _lastDocumentSnapshot;
  bool _listeningToUpdates = false;

  ActivitySnapshot _latestSnapshot;
  ActivitySnapshot get latestSnapshot => _latestSnapshot;

  LocalValue<String> name;
  LocalValue<DateTime> time;

  ActivityHandler.fromFromOnline(this.ref) {
    _listeningToUpdates = true;
  }

  ActivityHandler.fromData(this.ref, String name, DateTime time) {
    this.name = LocalValue.value(this, name);
    this.time = LocalValue.value(this, time);
  }

  void onActivityChanged() {
    _latestSnapshot = _getLatestSnapshot();
    notifyListeners();
  }

  ActivitySnapshot _getLatestSnapshot() {
    if (_listeningToUpdates) {
      return A
    } else {

    }
  }

  void _startListen() {
    assert(!_listeningToUpdates);
    _listeningToUpdates = true;
  }

  void _stopListen() {
    assert(_listeningToUpdates);
    _listeningToUpdates = false;
  }
}

class LocalValue<T> {
  final ActivityHandler _listener;
  T _value;

  T get value => _value;

  LocalValue.value(this._listener, this._value);
  LocalValue(this._listener);

  void updateValue(T Function(T currentValue) modifier) {
    T newValue = modifier(_value);
    if (newValue != null) _value = newValue;
  }
}