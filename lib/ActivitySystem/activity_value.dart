library activity_system;

import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:meetboard/ActivitySystem/activity_reference.dart';
import 'package:meetboard/ActivitySystem/activity_snapshot.dart';
import 'package:meetboard/ActivitySystem/user_reference.dart';
import 'package:meetboard/Models/user_model.dart';

import 'activity_handler.dart';
import 'user_data_snapshot.dart';

//Keeps track of global and local data, and merges them for the theoretical current global data
abstract class IActivityData<T> with ChangeNotifier {
  bool _linked = false;

  T get currentValue;

  void linkParent(ChangeNotifier parent) {
    if (!_linked) {
      addListener(() => parent.notifyListeners());
      _linked = true;
    }
  }
}

//Acts as a wrapper for an activity value only exposing part of the interface
//Keeps track of changes and reports what to change in the database for these local changes to become global
abstract class IActivityDataWriter<T, C extends IActivityData<T>> {
  final C _activityData;
  final T _initialValue;
  final ActivityReference _ref;

  IActivityDataWriter._(this._activityData, this._initialValue, this._ref);
  IActivityDataWriter(C activityData, ActivityReference ref) : this._(activityData, activityData.currentValue, ref);

  T get currentValue => _activityData.currentValue;

  FirestoreChange getChanges();
}

class ActivityData extends IActivityData<ActivitySnapshot> {
  final ActivityReference _ref;

  final ActivityDataField<DateTime> _time;
  final ActivityDataField<String> _name;
  final ActivityDataUserList _users;

  Iterable<IActivityData> get _children => [_time, _name, _users];

  ActivityData(this._ref, this._time, this._name, this._users) {
    _children.forEach((data) => data.linkParent(this));
  }

  ActivityData.global(ActivitySnapshot globalData) : this(
    globalData.ref,
    ActivityDataField.global(globalData.time),
    ActivityDataField.global(globalData.name),
    ActivityDataUserList.global(globalData.users.values.toList())
  );

  ActivityData.local(ActivitySnapshot globalData) : this(
      globalData.ref,
      ActivityDataField.local(globalData.time),
      ActivityDataField.local(globalData.name),
      ActivityDataUserList.local(globalData.users.values.toList())
  );

  void setGlobalValue(ActivitySnapshot globalValue) {
    _time.setGlobalValue(globalValue.time);
    _name.setGlobalValue(globalValue.name);
    _users.setGlobalUsers(globalValue.users.values.toList());
  }

  @override
  ActivitySnapshot get currentValue => ActivitySnapshot(
      ref: _ref,
      name: _name.currentValue,
      time: _time.currentValue,
      users: _users.currentValue.toList()
  );
}

class ActivityDataWriter extends IActivityDataWriter<ActivitySnapshot, ActivityData> {
  ActivityDataWriter(ActivityData activityData) : super(activityData, activityData._ref) {
    _usersWriter = ActivityDataUserListWriter(activityData._users, activityData._ref);
  }

  ActivityDataUserListWriter _usersWriter;
  ActivityDataUserListWriter get users => _usersWriter;

  void setTime(DateTime time) {
    _activityData._time.setLocalValue(time);
  }

  void setName(String name) {
    _activityData._name.setLocalValue(name);
  }

  @override
  FirestoreChange getChanges() {
    FirestoreChange change = users.getChanges();
    if (_activityData.currentValue.time != _initialValue.time) change = change.merge(FirestoreChange.single(_ref.activityDocument, { "time": Timestamp.fromDate(_activityData._time.currentValue) }));
    if (_activityData.currentValue.name != _initialValue.name) change = change.merge(FirestoreChange.single(_ref.activityDocument, { "name": _activityData._time.currentValue }));
    return change;
  }
}

class ActivityDataField<T> extends IActivityData<T> {
  @override
  T get currentValue => _value;

  T _value;
  bool _synced;

  ActivityDataField.global(this._value) : _synced = true;
  ActivityDataField.local(this._value) : _synced = false;

  void setGlobalValue(T globalValue) {
    if (_synced) _value = globalValue;
    else if (globalValue == _value) _synced = true;

    notifyListeners();
  }

  void setLocalValue(T localValue) {
    _value = localValue;
    _synced = false;

    notifyListeners();
  }
}

class ActivityDataFieldWriter<Q> extends IActivityDataWriter<Q, ActivityDataField<Q>> {
  final FirestoreChange Function(Q value) _getChange;

  ActivityDataFieldWriter(ActivityDataField<Q> activityValue, this._getChange, ActivityReference ref) : super(activityValue, ref);

  @override
  FirestoreChange getChanges() {
    return _activityData.currentValue != _initialValue ? _getChange(currentValue) : FirestoreChange.none();
  }

  void updateValue(Q Function(Q currentValue) modifier) {
    Q res = modifier(_activityData.currentValue);
    assert(res != null);

    _activityData.setLocalValue(res);
  }
}

class ActivityDataUserList extends IActivityData<List<UserDataSnapshot>> {
  final HashSet<UserReference> _localAddedUsers, _localRemovedUsers;
  final Map<UserReference, ActivityDataUser> _currentUsers;

  @override
  List<UserDataSnapshot> get currentValue => _currentUsers.values.map((e) => e.currentValue).toList();

  static ActivityDataUserList local(List<UserDataSnapshot> users) {
    ActivityDataUserList list = ActivityDataUserList.empty();
    users.forEach((user) => list.addUserLocally(user));
    return list;
  }

  static ActivityDataUserList global(List<UserDataSnapshot> users) {
    ActivityDataUserList list = ActivityDataUserList.empty();
    list.setGlobalUsers(users);
    return list;
  }

  ActivityDataUserList.empty() : _localAddedUsers = HashSet(), _localRemovedUsers = HashSet(), _currentUsers = Map();

  void setGlobalUsers(List<UserDataSnapshot> usersData) {
    Iterable<UserReference> users = usersData.map((e) => e.ref);

    _localAddedUsers.removeAll(users);
    _localRemovedUsers.removeAll(_localRemovedUsers.where((user) => !users.contains(user)));

    usersData.where((userData) => !_localRemovedUsers.contains(userData.ref)).forEach((userData) {
      if (_currentUsers.containsKey(userData.ref)) {
        _currentUsers[userData.ref].setGlobalData(userData);
      } else {
        _currentUsers[userData.ref] = ActivityDataUser.global(userData)..linkParent(this);
      }
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

    _currentUsers[user.ref] = ActivityDataUser.local(user)..linkParent(this);

    notifyListeners();
  }
}

//At the moment we don't support adding or removing users outside the API, nor modifying values of other users than the current user
class ActivityDataUserListWriter extends IActivityDataWriter<List<UserDataSnapshot>, ActivityDataUserList> {
  ActivityDataUserListWriter(ActivityDataUserList activityValue, ActivityReference ref) : super(activityValue, ref) {
    _currentUserWriter = ActivityDataUserWriter(activityValue._currentUsers[UserModel.instance.user], ref);
  }

 ActivityDataUserWriter _currentUserWriter;
  ActivityDataUserWriter get currentUser => _currentUserWriter;

  @override
  FirestoreChange getChanges() {
    return _currentUserWriter.getChanges();
  }
}

class ActivityDataUser extends IActivityData<UserDataSnapshot> {
  final UserReference ref;

  final ActivityDataField<ActivityRole> _role;
  final ActivityDataField<bool> _coming;
  Iterable<IActivityData> get _children => [_role, _coming];

  String _username;

  ActivityDataUser(this.ref, this._role, this._coming, this._username) {
    _children.forEach((child) => child.linkParent(this));
  }

  ActivityDataUser.global(UserDataSnapshot data) : this(
    data.ref,
    ActivityDataField.global(data.role),
    ActivityDataField.global(data.coming),
    data.username
  );

  ActivityDataUser.local(UserDataSnapshot data) : this(
      data.ref,
      ActivityDataField.local(data.role),
      ActivityDataField.local(data.coming),
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
class ActivityDataUserWriter extends IActivityDataWriter<UserDataSnapshot, ActivityDataUser> {
  ActivityDataUserWriter(ActivityDataUser activityValue, ActivityReference ref) : super(activityValue, ref);

  @override
  FirestoreChange getChanges() {
    FirestoreChange change = FirestoreChange.none();
    if(_initialValue.coming !=_activityData.currentValue.coming) change = change.merge(FirestoreChange.single(
            _activityData.ref.getActivityUserDocument(_ref),
            { "coming": _activityData.currentValue.coming}));
    return change;
  }

  void setComing(bool coming) {
    _activityData._coming.setLocalValue(coming);
  }
}