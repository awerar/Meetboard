import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:meetboard/Models/activity.dart';
import 'package:meetboard/Models/activity_list_model.dart';
import 'package:meetboard/Models/settings_model.dart';
import 'package:meetboard/Models/user_model.dart';
import 'package:meetboard/Screens/ActivityPage/settings_tab.dart';
import 'package:meetboard/Screens/EditActivityPage/edit_activity_page.dart';
import 'package:meetboard/Screens/ActivityPage/people_tab.dart';
import 'package:meetboard/themes.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ActivityPage extends StatefulWidget {
  static const String routeName = "/view_activity_page";

  @override
  _ActivityPageState createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> with SingleTickerProviderStateMixin {
  ValueReference<Activity> activityReference;
  String _userUID;
  UserActivityData get _user => activityReference.value.users[_userUID];

  TabController tabController;

  SettingsModel settings;

  @override
  void initState() {
    tabController = TabController(
      vsync: this,
      length: 4
    )..addListener(() => FocusScope.of(context).unfocus());

    super.initState();
  }

  @override
  void didChangeDependencies() {
    activityReference = ModalRoute.of(context).settings.arguments;
    assert(activityReference != null);

    try {
      _userUID = Provider.of<UserModel>(context, listen: false).user.uid;
    } catch (e) {
      _userUID = activityReference.value.users.keys.first;
    }

    if(settings == null) settings = SettingsModel(_getSettings());
    else settings.updateInitialValues(SettingsModel(_getSettings()));

    super.didChangeDependencies();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityListModel>(builder: (context, activityList, child) {
      Activity activity = activityReference.value;
      settings.updateInitialValues(SettingsModel(_getSettings()));

      return ChangeNotifierProvider<SettingsModel>.value(
        value: settings,
        child: Scaffold(
            appBar: AppBar(
              centerTitle: true,
              title: Builder(builder: (context) => Text(Provider.of<SettingsModel>(context).getSavedValue("name"),)),
              actions: <Widget>[
                Builder(
                  builder: (context) => IconButton(
                    onPressed: () => _showInviteSheet(context),
                    icon: Icon(Icons.person_add),
                  ),
                ),
                SizedBox(width: 7.5,),
              ],
              bottom: TabBar(
                controller: tabController,
                tabs: <Widget>[
                  Tab(icon: Icon(Icons.info), text: "Info",),
                  Tab(icon: Icon(Icons.people), text: "People",),
                  Tab(icon: Icon(Icons.playlist_add_check), text: "Items",),
                  Tab(icon: Icon(Icons.settings), text: "Settings",),
                ],
              ),
            ),
            body: TabBarView(
                controller: tabController,
                children: <Widget>[
                  Container(),
                  PeopleTab(activity, _user),
                  Container(),
                  SettingsTab(_user, activity),
                ]
            )
        ),
      );
    });
  }

  void _showInviteSheet(BuildContext context) {
    Widget Function(BuildContext context) buildSheet = (context) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            title: Builder(builder: (context) => Text("Invite With", style: DefaultTextStyle.of(context).style.copyWith(color: Colors.grey),
            )),
          ),
          ListTile(
            title: Text("Link"),
            leading: Icon(MdiIcons.link),
            onTap: _inviteWithLink,
          ),
          ListTile(
            title: Text("QR Code"),
            leading: Icon(MdiIcons.qrcode),
            onTap: () => _inviteWithQRCode(context),
          ),
        ],
      );
    };

    showModalBottomSheet(
      context: context,
      builder: buildSheet,
    );
  }

  void _inviteWithQRCode(BuildContext context) async {
    GlobalKey qrKey = GlobalKey();
    String qrData = (await activityReference.value.getInviteLinkParams().buildUrl()).toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox.fromSize(
              size: Size.square(200),
              child: RepaintBoundary(
                key: qrKey,
                child: QrImage(
                  data: qrData,
                ),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          FlatButton(child: Text("Share"), onPressed: () => _shareQRCode(qrKey),),
          FlatButton(child: Text("Done"), onPressed: () => Navigator.of(context).pop(),),
        ],
      ),
    );
  }

  void _shareQRCode(GlobalKey qrKey) async {
    RenderRepaintBoundary boundary = qrKey.currentContext.findRenderObject();
    var image = await boundary.toImage();
    ByteData byteData = await image.toByteData(format: ImageByteFormat.png);
    Uint8List pngBytes = byteData.buffer.asUint8List();
    Share.file('${activityReference.value.name} Invitation QR Code', '${activityReference.value.name.replaceAll(" ", "_")}_QR.png', pngBytes, 'image/png',);
  }

  void _inviteWithLink() async {
    Share.text("Invitation Code", (await activityReference.value.getInviteLinkParams().buildShortLink()).shortUrl.toString(), "text/plain");
  }

  Map<String, SettingsField> _getSettings() {
    return {
      "coming": SettingsField<bool>(
          initialValue: _user.coming,
          getSaveData: (coming, settings) {
            return {
              activityReference.value.getUserDataDocument(_user.uid): {
                "coming": coming
              }
            };
          }
      ),
      "name": SettingsField<String>(
        initialValue: activityReference.value.name,
        getSaveData: (name, settings) {
          return {
            activityReference.value.activityDocument: {
              "name": name
            }
          };
        }
      ),
      "time": SettingsField<TimeOfDay>(
          initialValue: TimeOfDay.fromDateTime(activityReference.value.time),
          getSaveData: (time, settings) {
            DateTime date = settings.getValue<DateTime>("date");
            DateTime activityTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);

            return {
              activityReference.value.activityDocument: {
                "time": Timestamp.fromDate(activityTime)
              }
            };
          }
      ),
      "date": SettingsField<DateTime>(
          initialValue: _calculateActivityDate(),
          getSaveData: (date, settings) {
            TimeOfDay time = settings.getValue<TimeOfDay>("time");
            DateTime activityTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);

            return {
              activityReference.value.activityDocument: {
                "time": Timestamp.fromDate(activityTime)
              }
            };
          }
      )
    };
  }

  DateTime _calculateActivityDate() {
    DateTime date = activityReference.value.time;
    return date.subtract(Duration(hours: date.hour, minutes: date.minute, seconds: date.second, milliseconds: date.millisecond, microseconds: date.microsecond));
  }
}