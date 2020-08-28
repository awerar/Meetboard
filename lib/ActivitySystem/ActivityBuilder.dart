import 'dart:async';

import 'package:flutter/material.dart';
import 'package:meetboard/ActivitySystem/ActivityReference.dart';
import 'package:meetboard/Models/ActivityListModel.dart';

import 'ActivitySnapshot.dart';

typedef ActivityBuilderFunc = Widget Function(BuildContext context, ActivitySnapshot snapshot);

class ActivityBuilder extends StatefulWidget {
  final ActivityReference ref;
  final ActivityBuilderFunc builder;

  const ActivityBuilder({Key key, this.ref, this.builder}) : super(key: key);

  @override
  _ActivityBuilderState createState() => _ActivityBuilderState();
}

class _ActivityBuilderState extends State<ActivityBuilder> {
  StreamController<ActivitySnapshot> _streamController;
  Stream<ActivitySnapshot> get _stream => _streamController.stream;

  ActivitySnapshot _lastSnapshot;

  ActivitySubscription _subscription;

  @override
  void initState() async {
    super.initState();

    _streamController = StreamController();
    _subscription = ActivityListModel.instance.listenForActivityChange(widget.ref, (snapshot) {
      setState(() {
        _streamController.add(snapshot);
        _lastSnapshot = snapshot;
      });
    });

    await _stream.first;
  }

  @override
  void dispose() {
    _subscription.unsubscribe();
    _streamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _lastSnapshot);
  }
}
