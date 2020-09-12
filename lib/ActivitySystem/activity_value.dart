library activity_system;

import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:meetboard/ActivitySystem/activity_reference.dart';
import 'package:meetboard/ActivitySystem/user_reference.dart';
import 'package:meetboard/Models/user_model.dart';

import 'activity_handler.dart';
import 'user_data_snapshot.dart';

//Keeps track of global and local data, and merges them for the theoretical current global data
abstract class IActivityValue<T> with ChangeNotifier {
  ActivityHandler _handler;

  void link(ActivityHandler handler) {
    _handler = handler;
  }

  T get currentValue;

  bool get _online => _handler.listeningToUpdates;
}

//Acts as a wrapper for an activity value only exposing part of the interface
//Keeps track of changes and reports what to change in the database for these local changes to become global
abstract class IActivityValueWriter<T, C extends IActivityValue<T>> {
  final C _activityValue;
  final T _initialValue;

  IActivityValueWriter._(this._activityValue, this._initialValue);
  IActivityValueWriter(C activityValue) : this._(activityValue, activityValue.currentValue);

  T get currentValue => _activityValue.currentValue;

  FirestoreChange getChanges();
}

class ActivityValue<T> extends IActivityValue<T> {
  @override
  T get currentValue => _hasLocalValue ? _localValue : _globalValue;
  bool get _hasLocalValue => _online ? _localValue != null : true;

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

class ActivityValueWriter<Q> extends IActivityValueWriter<Q, ActivityValue<Q>> {
  final FirestoreChange Function(Q value) _getChange;

  ActivityValueWriter(ActivityValue<Q> activityValue, this._getChange) : super(activityValue);

  @override
  FirestoreChange getChanges() {
    return _activityValue.currentValue != _initialValue ? _getChange(currentValue) : FirestoreChange.none();
  }

  void updateValue(Q Function(Q currentValue) modifier) {
    Q res = modifier(_activityValue.currentValue);
    assert(res != null);

    _activityValue.setLocalValue(res);
  }
}

class UserListActivityValue extends IActivityValue<List<UserDataSnapshot>> {
  final HashSet<UserReference> _localAddedUsers, _localRemovedUsers;
  final Map<UserReference, UserActivityValue> _currentUsers;

  @override
  List<UserDataSnapshot> get currentValue => _currentUsers.values.map((e) => e.currentValue).toList();

  UserListActivityValue.local(List<UserDataSnapshot> users) :
        _localAddedUsers = HashSet.from(users.map((e) => e.ref)),
        _localRemovedUsers = HashSet(),
        _currentUsers = Map.fromIterable(users, key: (d) => d.ref, value: (d) => UserActivityValue.local(d));

  UserListActivityValue.global(List<UserDataSnapshot> users) :
        _localAddedUsers = HashSet(),
        _localRemovedUsers = HashSet(),
        _currentUsers = Map.fromIterable(users, key: (d) => d.ref, value: (d) => UserActivityValue.global(d));

  UserListActivityValue.noValue() : _localAddedUsers = HashSet(), _localRemovedUsers = HashSet(), _currentUsers = Map();

  void setGlobalUsers(List<UserDataSnapshot> usersData) {
    Iterable<UserReference> users = usersData.map((e) => e.ref);

    _localAddedUsers.removeAll(users);
    _localRemovedUsers.removeAll(_localRemovedUsers.where((user) => !users.contains(user)));

    usersData.where((userData) => !_localRemovedUsers.contains(userData.ref)).forEach((userData) {
      _currentUsers[userData.ref].setGlobalData(userData);
    });

    notifyListeners();
  }

  void removeUserLocally(UserReference ref) {
    assert(ref != UserModel.instance.user);

    if (_localAddedUsers.contains(ref)) {
      _localAddedUsers.remove(ref);
    } else {
      _localRemovedUsers.add(ref);
    }

    _currentUsers.remove(ref);

    notifyListeners();
  }

  void addUserLocally(UserDataSnapshot user) {
    assert(user.ref != UserModel.instance.user);

    if (_localRemovedUsers.contains(user.ref)) {
      _localRemovedUsers.remove(user.ref);
    } else {
      _localAddedUsers.add(user.ref);
    }

    _currentUsers[user.ref] = UserActivityValue.local(user);

    notifyListeners();
  }
}

//At the moment we don't support adding or removing users outside the API, nor modifying values of other users than the current user
class UserListActivityValueWriter extends IActivityValueWriter<List<UserDataSnapshot>, UserListActivityValue> {
  UserListActivityValueWriter(UserListActivityValue activityValue) : super(activityValue) {
    _currentUserWriter = UserActivityValueWriter(activityValue._currentUsers[UserModel.instance.user]);
  }

 UserActivityValueWriter _currentUserWriter;
  UserActivityValueWriter get currentUser => _currentUserWriter;

  @override
  FirestoreChange getChanges() {
    return _currentUserWriter.getChanges();
  }
}

class UserActivityValue extends IActivityValue<UserDataSnapshot> {
  final UserReference ref;

  final ActivityValue<ActivityRole> _role;
  final ActivityValue<bool> _coming;
  List<IActivityValue> get _values => [ _role, _coming];

  String _username;

  UserActivityValue(this.ref, this._role, this._coming, this._username) {
    _values.forEach((value) {
      value.link(_handler);
      value.addListener(() => notifyListeners());
    });
  }

  UserActivityValue.global(UserDataSnapshot data) : this(
    data.ref,
    ActivityValue.global(data.role),
    ActivityValue.global(data.coming),
    data.username
  );

  UserActivityValue.local(UserDataSnapshot data) : this(
      data.ref,
      ActivityValue.local(data.role),
      ActivityValue.local(data.coming),
      data.username
  );

  @override
  UserDataSnapshot get currentValue => UserDataSnapshot(uid: ref.uid, username: _username, role: _role.currentValue, coming: _coming.currentValue);

  void setGlobalData(UserDataSnapshot data) {
    _username = data.username;
    _role.setGlobalValue(data.role);
    _coming.setGlobalValue(data.coming);
  }
}

//At the moment we only support changing the coming status of a user
class UserActivityValueWriter extends IActivityValueWriter<UserDataSnapshot, UserActivityValue> {
  UserActivityValueWriter(UserActivityValue activityValue) : super(activityValue);

  @override
  FirestoreChange getChanges() {
    FirestoreChange change = FirestoreChange.none();
    if(_initialValue.coming !=_activityValue.currentValue.coming) change = change.merge(FirestoreChange.single(
            _activityValue.ref.getActivityUserDocument(_activityValue._handler.ref),
            { "coming": _activityValue.currentValue.coming}));
    return change;
  }

  void setComing(bool coming) {
    _activityValue._coming.setLocalValue(coming);
  }
}