import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meetboard/Screens/ActivityPage/settings_tab.dart';
import 'package:meetboard/utils.dart';

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

  Future<void> save(ScaffoldState snackbarScaffold) async {
    Map<DocumentReference, Map<String, dynamic>> changes = {};

    for (var field in _settings.values.where((element) => element.hasChanges)) {
      for(MapEntry<DocumentReference, Map<String, dynamic>> saveData in field.getSaveData(this).entries) {
        if(!changes.containsKey(saveData.key)) changes[saveData.key] = saveData.value;
        else changes[saveData.key].addAll(saveData.value);
      }
    }

    _saving++;
    notifyListeners();

    var batch = Firestore.instance.batch();
    changes.entries.forEach((change) {
      batch.setData(change.key, change.value, merge: true);
    });

    void Function(String message) showErrorSnackbar = (message) {
      snackbarScaffold.showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text("ERROR: " + message),
        duration: Duration(seconds: 4),
        backgroundColor: Theme.of(snackbarScaffold.context).colorScheme.error,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5)
        ),
      ));
    };

    if (await hasInternetConnection()) {
      try {
        await batch.commit();
        _settings.updateAll((key, value) => value.getReset());
      } catch (e) {
        showErrorSnackbar("Something went wrong while saving.");
      }
    } else {
      showErrorSnackbar("Can not save without an internet connection.");
    }

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

  T getSavedValue<T>(String setting) {
    return _settings[setting].initialValue;
  }

  void updateInitialValues(SettingsModel otherSettings) {
    _settings.updateAll((key, value) => value.getResetWithInitialValue(otherSettings.getValue(key)));
    notifyListeners();
  }
}

class SettingsField<T> {
  final T initialValue;
  final Map<DocumentReference, Map<String, dynamic>> Function(T value, SettingsModel settings) _getSaveData;
  T currentValue;

  bool get hasChanges => currentValue != initialValue;

  SettingsField({@required this.initialValue, @required Map<DocumentReference, Map<String, dynamic>> Function(T value, SettingsModel settings) getSaveData}) : _getSaveData = getSaveData {
    currentValue = initialValue;
  }

  Map<DocumentReference, Map<String, dynamic>> getSaveData(SettingsModel settings) {
    return _getSaveData(currentValue, settings);
  }

  void modifyValue(T Function(T oldVal) modifier) {
    currentValue = modifier(currentValue);
  }

  SettingsField<T> getReset() {
    return SettingsField<T>(initialValue: currentValue, getSaveData: _getSaveData);
  }

  SettingsField<T> getResetWithInitialValue(T initialValue) {
    return SettingsField<T>(initialValue: initialValue, getSaveData: _getSaveData)..modifyValue((oldVal) => currentValue);
  }
}