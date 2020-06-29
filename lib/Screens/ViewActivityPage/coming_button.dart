import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meetboard/Models/activity.dart';

class ComingButton extends StatefulWidget {
  final Activity _activity;
  ComingButton(this._activity);

  @override
  _ComingButtonState createState() => _ComingButtonState(_activity);
}

class _ComingButtonState extends State<ComingButton> with WidgetsBindingObserver {
  Activity _activity;
  bool _changedComingStatus = false;

  _ComingButtonState(this._activity);

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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) _trySaveComingState();
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    bool coming = _activity.coming;

    Duration animationDuration = Duration(milliseconds: 100);

    Text comingText = Text((coming ? "" : "Not ") + "Coming", key: Key("Coming Text",), overflow: TextOverflow.fade, maxLines: 1, softWrap: false,);

    return WillPopScope(
      child: FloatingActionButton.extended(
        onPressed: () {
          setState(() => _activity.coming = !coming);
          _changedComingStatus = !_changedComingStatus;
          if (_changedComingStatus) Future.delayed(Duration(seconds: 5), () {
            if (_changedComingStatus) _trySaveComingState();
          });
        },
        label: AnimatedContainer(child: comingText, duration: animationDuration, width: coming ? 60 : 90,),
        heroTag: "CreateButton",
        backgroundColor: coming ? Colors.teal : Colors.red,
        icon: AnimatedSwitcher(child: Icon(coming ? Icons.check : Icons.check_box_outline_blank, key: Key(coming ? "Coming Icon" : "Noy Coming Icon"),), duration: animationDuration,),
      ),
      onWillPop: () async {
        _trySaveComingState();

        return true;
      },
    );
  }

  void _trySaveComingState() {
    if (_changedComingStatus) {
      Firestore.instance.collection("/Activities").document(_activity.code).updateData(_activity.fireStoreMap());
      _changedComingStatus = false;
    }
  }
}
