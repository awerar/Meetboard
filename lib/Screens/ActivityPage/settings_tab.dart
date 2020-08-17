import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meetboard/Models/activity.dart';
import 'package:meetboard/Models/activity_list_model.dart';
import 'package:meetboard/Models/settings_model.dart';
import 'package:meetboard/Models/user_model.dart';
import 'package:provider/provider.dart';

class SettingsTab extends StatefulWidget {
  final UserActivityData user;
  final Activity activity;
  final SettingsModel settings;

  SettingsTab(this.user, this.activity, this.settings);

  @override
  _SettingsTabState createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> with SingleTickerProviderStateMixin {
  AnimationController bannerController;
  GlobalKey<FormState> formKey = GlobalKey();

  @override
  void initState() {
    bannerController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 250),
    );

    bannerController.value = widget.settings.hasUnsavedChanges ? 1 : 0;
    widget.settings.addListener(() {
      if(widget.settings.hasUnsavedChanges) bannerController.forward();
      else bannerController.reverse();
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            child: Form(
              key: formKey,
              child: ListView(
                shrinkWrap: true,
                children: <Widget>[
                  _buildTitle("Personal Settings"),
                  Divider(),
                  _buildPersonalSettings(),
                  SizedBox(height: 30,),
                  _buildTitle("Activity Settings"),
                  Divider(),
                  _buildActivitySettings(true),
                ],
              ),
            ),
          )
        ]
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
    return Column(

    );
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
                  Provider.of<SettingsModel>(context).save();
                }
              },
            ),
            FlatButton(
              child: Text("REVERT"),
              onPressed: Provider.of<SettingsModel>(context).revert,
            ),
          ],
        ),
      ],
    );
  }
}