import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meetboard/Models/settings_model.dart';
import 'package:provider/provider.dart';

import '../../themes.dart';

/*class AboutTab extends StatelessWidget {
  final Activity activity;
  final UserActivityData user;
  final TabController tabController;

  AboutTab(this.activity, this.user, this.tabController);

  @override
  Widget build(BuildContext context) {
    bool coming = Provider.of<SettingsModel>(context).getSavedValue("coming");

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: <Widget>[
          Builder(
            builder: (context) {
              TextStyle style = Theme.of(context).textTheme.subtitle2;

              return Flex(
                direction: Axis.horizontal,
                children: <Widget>[
                  Expanded(child: Center(child: Text("${activity.localUsers.values.where((element) => (element.coming && element.uid != user.uid) || (coming && element.uid == user.uid)).length} coming", style: style.copyWith(color: green),))),
                  Expanded(child: Center(child: Text("${activity.localUsers.length} in total", style: style,))),
                  Expanded(child: Center(child: Text("${activity.localUsers.values.where((element) => (!element.coming && element.uid != user.uid) || (!coming && element.uid == user.uid)).length} not coming", style: style.copyWith(color: red),))),
                ],
              );
            }
          ),
          SizedBox(height: 16,),
          Flex(
            direction: Axis.horizontal,
            children: <Widget>[
              Expanded(
                child: OutlineButton.icon(
                  label: Text(coming ? "Coming" : "Not Coming",),
                  icon: Icon(coming ? Icons.check : Icons.close),
                  onPressed: () => _onPressComing(context),
                  textColor: coming ? green : red,
                  borderSide: BorderSide(color: coming ? green : red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onPressComing(BuildContext context) async {
    SettingsModel settings = Provider.of<SettingsModel>(context, listen: false);
    tabController.animateTo(3);

    await Future.delayed(Duration(milliseconds: 550));

    settings.setValue("coming", !settings.getSavedValue("coming"));
  }
}*/