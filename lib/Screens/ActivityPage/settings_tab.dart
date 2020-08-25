import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meetboard/Models/settings_model.dart';
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
  AnimationController bannerController;
  GlobalKey<FormState> formKey = GlobalKey();
  void Function() removeSettingsListener;

  TextEditingController nameController, dateController, timeController;

  @override
  void initState() {
    SettingsModel settings = Provider.of<SettingsModel>(context, listen: false);
    settings.addListener(_settingsChanged);
    removeSettingsListener = () => settings.removeListener(_settingsChanged);

    bannerController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 250),
    );
    bannerController.value = settings.hasUnsavedChanges ? 1 : 0;

    nameController = TextEditingController(text: settings.getValue("name"));
    dateController = TextEditingController(text: _formatDate(settings.getValue("date")));

    super.initState();
  }

  @override
  void didChangeDependencies() {
    SettingsModel settings = Provider.of<SettingsModel>(context, listen: false);

    timeController = TextEditingController(text: settings.getValue<TimeOfDay>("time").format(context));

    super.didChangeDependencies();
  }

  @override
  void dispose() {
    nameController.dispose();
    dateController.dispose();
    timeController.dispose();

    bannerController.dispose();
    removeSettingsListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Flex(
        direction: Axis.vertical,
          children: <Widget>[
            Consumer<SettingsModel>(builder: (context, settings, child) => settings.saving ? LinearProgressIndicator() : Container(),),
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
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                child: Form(
                  key: formKey,
                  child: Builder(
                    builder: (context) {
                      EdgeInsets padding = EdgeInsets.symmetric(horizontal: 5);

                      return ListView(
                        shrinkWrap: true,
                        children: <Widget>[
                          _buildTitle("Personal Settings"),
                          Divider(),
                          Padding(
                            padding: padding,
                            child: _buildPersonalSettings(),
                          ),
                          SizedBox(height: 30,),
                          _buildTitle("Activity Settings"),
                          Divider(),
                          Padding(
                            padding: padding,
                            child: _buildActivitySettings(true),
                          ),
                        ],
                      );
                    }
                  ),
                ),
              ),
            )
          ]
      ),
    );
  }

  Widget _buildTitle(String text) {
    return Text(text, style: Theme.of(context).textTheme.caption,);
  }

  Widget _buildPersonalSettings() {
    return Consumer<SettingsModel>(
      builder: (context, settings, child) => Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text("Coming", style: Theme.of(context).textTheme.subtitle1,),
              Switch(onChanged: (newValue) => settings.setValue("coming", newValue), value: settings.getValue("coming"),)
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySettings(bool enabled) {
    return Consumer<SettingsModel>(
      builder: (BuildContext context, SettingsModel settings, Widget child) => Column(
        children: <Widget>[
          _buildNameSettingField(enabled, settings),
          _buildDateSettingField(enabled, settings),
          _buildTimeSettingField(enabled, settings)
        ].expand((element) => [element, SizedBox(height: 20,)]).toList()..removeLast(),
      ),
    );
  }

  Widget _buildNameSettingField(bool enabled, SettingsModel settings) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: "Activity Name",
        filled: true
      ),
      controller: nameController,
      onChanged: (v) => settings.setValue("name", v),
      autocorrect: true,
      enableSuggestions: true,
      textCapitalization: TextCapitalization.words,
      validator: (name) => name.length >= 3 ? (name.length <= 20 ? null : "Name must be at most 20 letters long") : "Name must be at least 3 letters long",
      enabled: enabled,
      maxLength: 20,
    );
  }

  Widget _buildDateSettingField(bool enabled, SettingsModel settings) {
    return GestureDetector(
      child: IgnorePointer(
        child: TextFormField(
          decoration: InputDecoration(
            filled: true,
            labelText: "Date",
            prefixIcon: Icon(Icons.calendar_today)
          ),
          controller: dateController,
        ),
      ),
      behavior: HitTestBehavior.translucent,
      onTap: () async {
        DateTime date = await showDatePicker(context: context, initialDate: settings.getValue("date"), firstDate: DateTime.now(), lastDate: DateTime.now().add(Duration(days: 365 * 100)));
        settings.setValue("date", date);
      },
    );
  }

  Widget _buildTimeSettingField(bool enabled, SettingsModel settings) {
    return GestureDetector(
      child: IgnorePointer(
        child: TextFormField(
          decoration: InputDecoration(
              filled: true,
              labelText: "Time",
              prefixIcon: Icon(Icons.access_time)
          ),
          controller: timeController,
        ),
      ),
      behavior: HitTestBehavior.translucent,
      onTap: () async {
        TimeOfDay time = await showTimePicker(context: context, initialTime: settings.getValue("time"));
        settings.setValue("time", time);
      },
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat("yMMMEd").format(date);
  }

  Widget _buildSaveBanner() {
    return Column(
      children: <Widget>[
        MaterialBanner(
          content: Text("You have unsaved changes",),
          actions: <Widget>[
            FlatButton(
              child: Text("SAVE"),
              onPressed: () {
                if (formKey.currentState.validate()) {
                  Provider.of<SettingsModel>(context, listen: false).save(Scaffold.of(context));
                }
              },
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

  void _revert() {
    FocusScope.of(context).unfocus();

    SettingsModel settings = Provider.of<SettingsModel>(context, listen: false);
    settings.revert();
    nameController.text = settings.getValue("name");
  }

  void _settingsChanged() {
    SettingsModel settings = Provider.of<SettingsModel>(context, listen: false);

    dateController.text = _formatDate(settings.getValue<DateTime>("date"));
    timeController.text = settings.getValue<TimeOfDay>("time").format(context);

    if(settings.hasUnsavedChanges) bannerController.forward();
    else bannerController.reverse();
  }
}