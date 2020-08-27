import 'dart:collection';

import 'package:flutter/cupertino.dart';

import 'ActivityHandler.dart';
import 'UserDataSnapshot.dart';

abstract class IActivityValue<T> with ChangeNotifier {
  ActivityHandler _handler;

  void link(ActivityHandler handler) {
    _handler = handler;
  }

  T get currentValue;
}

class ActivityValue<T> extends IActivityValue<T> {
  T get currentValue => _hasLocalValue ? _localValue : _globalValue;
  bool get _hasLocalValue {
    if(_handler.listeningToUpdates) {
      assert(_globalValue != null);
      return _localValue != null;
    } else {
      assert(_localValue != null);
      return true;
    }
  }

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
  List<UserDataSnapshot> get currentValue => _handler.listeningToUpdates ?
    (_globalUsers..addAll(_localAddedUsers)..removeAll(_localRemovedUsers)).toList() :
    _localAddedUsers.toList();

  ActivityUsersValue.local(List<UserDataSnapshot> users) : _globalUsers = HashSet(), _localAddedUsers = HashSet.from(users), _localRemovedUsers = HashSet();
  ActivityUsersValue.global(List<UserDataSnapshot> users) : _globalUsers = HashSet.from(users), _localAddedUsers = HashSet(), _localRemovedUsers = HashSet();

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