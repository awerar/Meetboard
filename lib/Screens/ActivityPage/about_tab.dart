import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meetboard/ActivitySystem/activity_snapshot.dart';
import 'package:meetboard/Models/settings_model.dart';
import 'package:provider/provider.dart';

import '../../themes.dart';

class AboutTab extends StatelessWidget {
  final ActivitySnapshot activity;
  final TabController tabController;

  AboutTab(this.activity, this.tabController);

  @override
  Widget build(BuildContext context) {
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
                  Expanded(child: Center(child: Text("${activity.users.values.where((user) => user.coming).length} coming", style: style.copyWith(color: green),))),
                  Expanded(child: Center(child: Text("${activity.users.length} in total", style: style,))),
                  Expanded(child: Center(child: Text("${activity.users.values.where((user) => !user.coming).length} not coming", style: style.copyWith(color: red),))),
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
                  label: Text(activity.coming ? "Coming" : "Not Coming",),
                  icon: Icon(activity.coming ? Icons.check : Icons.close),
                  onPressed: () => _onPressComing(context),
                  textColor: activity.coming ? green : red,
                  borderSide: BorderSide(color: activity.coming ? green : red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onPressComing(BuildContext context) async {
    throw UnimplementedError();
    /*SettingsModel settings = Provider.of<SettingsModel>(context, listen: false);
    tabController.animateTo(3);

    await Future.delayed(Duration(milliseconds: 550));

    settings.setValue("coming", !settings.getSavedValue("coming"));*/
  }
}