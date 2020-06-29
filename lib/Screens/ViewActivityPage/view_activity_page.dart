import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meetboard/Components/double_floating_action_button.dart';
import 'package:meetboard/Models/activity.dart';

class ViewActivityPage extends StatefulWidget {
  static const String routeName = "/view_activity_page";

  @override
  _ViewActivityPageState createState() => _ViewActivityPageState();
}

class _ViewActivityPageState extends State<ViewActivityPage> with WidgetsBindingObserver{
  Activity _activity;
  bool _edit = false, _changedComingStatus = false;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_activity == null) {
      _activity = ModalRoute.of(context).settings.arguments;
      assert(_activity != null);
    }

    return WillPopScope(
        child: Scaffold(
          appBar: AppBar(
            title: Text(_activity.name, style: Theme.of(context).textTheme.headline1,),
            actions: <Widget>[
              IconButton(icon: Icon(Icons.edit), onPressed: _startEdit,)
            ],
          ),
          floatingActionButton: _buildFloatingButtons(),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        ),
      onWillPop: () async {
          _trySaveComing();

          return true;
      },
    );
  }

  Widget _buildFloatingButtons(){
    bool coming = _activity.coming;
    Widget comingButton = FloatingActionButton.extended(
      onPressed: () {
        setState(() => _activity.coming = !coming);
        _changedComingStatus = !_changedComingStatus;
        if (_changedComingStatus) Future.delayed(Duration(seconds: 5), () {
          if (_changedComingStatus) _trySaveComing();
        });
      },
      label: Text((coming ? "" : "Not ") + "Coming"),
      heroTag: "CreateButton",
      backgroundColor: coming ? Colors.teal : Colors.red,
      icon: Icon(coming ? Icons.check : Icons.check_box_outline_blank),
    );
    Widget editButton = FloatingActionButton.extended(onPressed: null, label: Text("Edit"), icon: Icon(Icons.edit), );

    return DoubleFloatingActionButton(
      leftButton: editButton,
      rightButton: comingButton,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) _trySaveComing();
    super.didChangeAppLifecycleState(state);
  }

  void _trySaveComing() {
    if (_changedComingStatus) {
      Firestore.instance.collection("/Activities").document(_activity.code).updateData(_activity.fireStoreMap());
      _changedComingStatus = false;
    }
  }

  void _startEdit() {

  }
}
