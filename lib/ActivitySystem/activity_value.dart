library activity_system;

import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:meetboard/ActivitySystem/activity_reference.dart';
import 'package:meetboard/Models/user_model.dart';

import 'activity_handler.dart';
import 'user_data_snapshot.dart';

abstract class IActivityValue<T> with ChangeNotifier {
  ActivityHandler _handler;

  void link(ActivityHandler handler) {
    _handler = handler;
  }

  T get _currentValue;
  bool get hasValue;

  T get currentValue {
    assert(hasValue);
    return _currentValue;
  }
}

class ActivityValue<T> extends IActivityValue<T> {
  @override
  T get _currentValue => _hasLocalValue ? _localValue : _globalValue;
  bool get _hasLocalValue => _handler.listeningToUpdates ? _localValue != null : true;

  @override
  bool get hasValue => _hasLocalValue ? _localValue != null : _globalValue != null;

  T _globalValue;
  T _localValue;

  ActivityValue.local(T value) :
        _localValue = value;

  ActivityValue.global(T value) :
        _globalValue = value,
        _localValue = value;

  void setGlobalValue(T value) {
    _globalValue = value;
    if (_localValue == _globalValue) _localValue = null;

    notifyListeners();
  }

  void setLocalValue(T value) {
    _localValue = value;

    notifyListeners();
  }
}

class ActivityUsersValue extends IActivityValue<List<UserDataSnapshot>> {
  final HashSet<UserDataSnapshot> _globalUsers, _localAddedUsers, _localRemovedUsers;

  @override
  bool get hasValue => _handler.listeningToUpdates ? _globalUsers.length != 0 : _localAddedUsers.length != 0;

  @override
  List<UserDataSnapshot> get _currentValue => _handler.listeningToUpdates ?
    (HashSet<UserDataSnapshot>.from(_globalUsers)..addAll(_localAddedUsers)..removeAll(_localRemovedUsers)).toList() :
    _localAddedUsers.toList();

  ActivityUsersValue.local(List<UserDataSnapshot> users) : _globalUsers = HashSet(), _localAddedUsers = HashSet.from(users), _localRemovedUsers = HashSet();
  ActivityUsersValue.global(List<UserDataSnapshot> users) : _globalUsers = HashSet.from(users), _localAddedUsers = HashSet(), _localRemovedUsers = HashSet();
  ActivityUsersValue.noValue() : _globalUsers = HashSet(), _localAddedUsers = HashSet(), _localRemovedUsers = HashSet();

  void setGlobalUsers(List<UserDataSnapshot> users) {
    Iterable<UserDataSnapshot> addedUsers = users.where((element) => !_globalUsers.contains(element));
    addedUsers.forEach((element) {
      _localAddedUsers.remove(element);
    });

    Iterable<UserDataSnapshot> removedUsers = _globalUsers.where((element) => !users.contains(element));
    removedUsers.forEach((element) {
      _localRemovedUsers.remove(element);
    });

    _globalUsers.clear();
    _globalUsers.addAll(users);

    notifyListeners();
  }

  void removeUser(UserDataSnapshot user) {
    assert(_globalUsers.contains(user));
    _localRemovedUsers.remove(user);

    if (_localAddedUsers.contains(user)) _localAddedUsers.remove(user);

    notifyListeners();
  }

  void addUser(UserDataSnapshot user) {
    assert(!_globalUsers.contains(user));
    _localRemovedUsers.add(user);

    if (_localRemovedUsers.contains(user)) _localRemovedUsers.remove(user);

    notifyListeners();
  }
}

//Acts as a wrapper for an activity value only exposing part of the interface
abstract class IActivityValueWriter<T, C extends IActivityValue<T>> {
  final ActivityReference _ref;
  final C _activityValue;

  IActivityValueWriter(this._ref, this._activityValue);

  T get currentValue;

  FirestoreChange getChanges();
}

class ActivityValueWriter<Q> extends IActivityValueWriter<Q, ActivityValue<Q>> {
  final Q _startValue;
  final FirestoreChange Function(Q value) _getChange;

  ActivityValueWriter(ActivityReference ref, ActivityValue<Q> activityValue, this._getChange) : _startValue = activityValue.currentValue, super(ref, activityValue);

  @override
  Q get currentValue => _activityValue._localValue;

  @override
  FirestoreChange getChanges() {
    return _activityValue.currentValue != _startValue ? _getChange(currentValue) : FirestoreChange.none();
  }

  void updateValue(Q Function(Q currentValue) modifier) {
    Q res = modifier(_activityValue.currentValue);
    assert(res != null);

    _activityValue.setLocalValue(res);
  }
}

class ActivityUsersValueWriter extends IActivityValueWriter<List<UserDataSnapshot>, ActivityUsersValue> {
  ActivityUsersValueWriter(ActivityReference ref, ActivityUsersValue activityValue) : super(ref, activityValue);

  HashSet<UserDataSnapshot> _addedUsers = HashSet(), _removedUsers = HashSet();

  @override
  List<UserDataSnapshot> get currentValue => _activityValue.currentValue;

  @override
  FirestoreChange getChanges() {
    return FirestoreChange.none();
  }

  void addUser(UserDataSnapshot user) {
    throw UnimplementedError();
    assert(_activityValue._globalUsers.firstWhere((element) => element.uid == UserModel.instance.user.uid).role == ActivityRole.Owner);

    if(_removedUsers.contains(user)) _removedUsers.remove(user);
    _addedUsers.add(user);

    _activityValue.addUser(user);
  }

  void removeUser(UserDataSnapshot user) {
    throw UnimplementedError();
    assert(_activityValue._globalUsers.firstWhere((element) => element.uid == UserModel.instance.user.uid).role == ActivityRole.Owner);

    if(_addedUsers.contains(user)) _addedUsers.remove(user);
    _removedUsers.add(user);

    _activityValue.removeUser(user);
  }
}