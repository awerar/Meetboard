import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meetboard/Models/activity.dart';
import 'package:meetboard/Models/activity_list_model.dart';
import 'package:meetboard/Models/user_model.dart';
import 'package:provider/provider.dart';

class SettingsTab extends StatefulWidget {
  final UserActivityData user;
  final Activity activity;

  SettingsTab(this.user, this.activity);

  @override
  _SettingsTabState createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> with SingleTickerProviderStateMixin {
  Map<String, SettingsField> fields = Map();
  AnimationController bannerController;
  int _saving = 0;

  @override
  void initState() {
    fields["coming"] = SettingsField<bool>(initialValue: widget.user.coming, getSaveData: (value) {
      return {
        widget.activity.getUserDataDocument(widget.user.uid): {
          "coming": value
        }
      };
    });

    bannerController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 250)
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        children: <Widget>[
          Builder(builder: (context) => _saving > 0 ? LinearProgressIndicator() : Container(),),
          AnimatedBuilder(
            animation: bannerController,
            child: _buildSaveBanner(),
            builder: (context, child) => SizeTransition(
              axisAlignment: 1,
              child: child,
              axis: Axis.vertical,
              sizeFactor: CurvedAnimation(curve: Curves.easeOut, reverseCurve: Curves.easeIn, parent: bannerController),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            child: ListView(
              shrinkWrap: true,
              children: <Widget>[
                _buildTitle("Personal"),
                Divider(),
                _buildPersonalSettings(),
                _buildTitle("General"),
                Divider(),
                _buildGeneralSettings(true),
              ],
            ),
          )
        ]
    );
  }

  Widget _buildTitle(String text) {
    return Text(text, style: Theme.of(context).textTheme.caption,);
  }

  Widget _buildPersonalSettings() {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text("Coming", style: Theme.of(context).textTheme.subtitle1,),
            Switch(onChanged: (newValue) => _setFieldValue("coming", newValue), value: fields["coming"].currentValue,)
          ],
        ),
      ],
    );
  }

  Widget _buildGeneralSettings(bool enabled) {
    return Column(

    );
  }

  void _setFieldValue<T>(String field, T value) {
    setState(() {
      fields[field].currentValue = value;
    });

    _handleBannerVisibility();
  }

  void _modifyFieldValue<T>(String field, T Function(T oldVal) modifier) {
    setState(() {
      (fields[field] as SettingsField<T>).modifyValue(modifier);
    });

    _handleBannerVisibility();
  }

  Future<void> _save() async {
    Map<DocumentReference, Map<String, dynamic>> changes = {};

    for (var field in fields.values.where((element) => element.hasChanges)) {
      for(MapEntry<DocumentReference, Map<String, dynamic>> saveData in field.getSaveData().entries) {
        if(!changes.containsKey(saveData.key)) changes[saveData.key] = saveData.value;
        else changes[saveData.key].addAll(saveData.value);
      }
    }

    setState(() {
      _saving++;
      fields.updateAll((key, value) => value.getReset());
    });

    await Future.wait(
      changes.entries.map((change) {
        return change.key.setData(change.value, merge: true);
      })
    );
    _handleBannerVisibility();

    setState(() {
      _saving--;
    });
  }

  void _revert() {
    setState(() {
      fields.forEach((key, value) => value.currentValue = value.initialValue);
    });

    _handleBannerVisibility();
  }

  Widget _buildSaveBanner() {
    return Column(
      children: <Widget>[
        MaterialBanner(
          content: Text("You have unsaved changes",),
          actions: <Widget>[
            FlatButton(
              child: Text("SAVE"),
              onPressed: _save,
            ),
            FlatButton(
              child: Text("REVERT"),
              onPressed: _revert,
            ),
          ],
        ),
      ],
    );
  }

  void _handleBannerVisibility() {
    if(fields.values.toList().where((element) => element.hasChanges).length > 0) {
      bannerController.forward();
    } else bannerController.reverse();
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