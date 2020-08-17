import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meetboard/Screens/ActivityPage/settings_tab.dart';

class SettingsModel extends ChangeNotifier {
  final Map<String, SettingsField> _settings;
  int _saving = 0;

  bool get saving => _saving > 0;
  bool get hasUnsavedChanges => _settings.values.toList().where((element) => element.hasChanges).length > 0;

  SettingsModel(this._settings);

  void setValue<T>(String setting, T value) {
    _settings[setting].currentValue = value;
    notifyListeners();
  }

  void modifyValue<T>(String setting, T Function(T oldVal) modifier) {
    (_settings[setting] as SettingsField<T>).modifyValue(modifier);
    notifyListeners();
  }

  Future<void> save() async {
    Map<DocumentReference, Map<String, dynamic>> changes = {};

    for (var field in _settings.values.where((element) => element.hasChanges)) {
      for(MapEntry<DocumentReference, Map<String, dynamic>> saveData in field.getSaveData().entries) {
        if(!changes.containsKey(saveData.key)) changes[saveData.key] = saveData.value;
        else changes[saveData.key].addAll(saveData.value);
      }
    }

    _saving++;
    _settings.updateAll((key, value) => value.getReset());
    notifyListeners();

    await Future.wait(
        changes.entries.map((change) {
          return change.key.setData(change.value, merge: true);
        })
    );

    _saving--;
    notifyListeners();
  }

  void revert() {
    _settings.forEach((key, value) => value.currentValue = value.initialValue);
    notifyListeners();
  }

  T getValue<T>(String setting) {
    return _settings[setting].currentValue;
  }
}

class SettingsField<T> {
  final T initialValue;
  final Map<DocumentReference, Map<String, dynamic>> Function(T) _getSaveData;
  T currentValue;

  bool get hasChanges => currentValue != initialValue;

  SettingsField({@required this.initialValue, @required Map<DocumentReference, Map<String, dynamic>> Function(T) getSaveData}) : _getSaveData = getSaveData {
    currentValue = initialValue;
  }

  Map<DocumentReference, Map<String, dynamic>> getSaveData() {
    return _getSaveData(currentValue);
  }

  void modifyValue(T Function(T oldVal) modifier) {
    currentValue = modifier(currentValue);
  }

  SettingsField<T> getReset() {
    return SettingsField<T>(initialValue: currentValue, getSaveData: _getSaveData);
  }
}