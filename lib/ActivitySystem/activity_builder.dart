import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meetboard/ActivitySystem/activity_reference.dart';
import 'package:meetboard/ActivitySystem/activity_snapshot.dart';

class ActivityBuilder extends StatelessWidget {
  final ActivityReference ref;
  final Widget Function(BuildContext context, AsyncSnapshot<ActivitySnapshot> snapshot) activityBuilder;

  const ActivityBuilder({Key key, @required this.ref, @required this.activityBuilder}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ActivitySnapshot>(
      stream: ref.changeStream,
      builder: (context, snapshot) {
        return activityBuilder(
            context,
            snapshot.hasData
                ? AsyncSnapshot.withData(ConnectionState.active, snapshot.requireData)
                : AsyncSnapshot.nothing()
        );
      },
    );
  }
}
