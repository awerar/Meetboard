import 'package:flutter/material.dart';
import 'package:meetboard/Models/activity.dart';

class ViewActivityPage extends StatefulWidget {
  static const String routeName = "/view_activity_page";

  @override
  _ViewActivityPageState createState() => _ViewActivityPageState();
}

class _ViewActivityPageState extends State<ViewActivityPage> {
  Activity _activity;
  bool _edit = false;

  @override
  Widget build(BuildContext context) {
    if (_activity == null) {
      _activity = ModalRoute.of(context).settings.arguments;
      assert(_activity != null);
    }

    return Scaffold(
        appBar: AppBar(
          title: Text(_activity.name, style: Theme.of(context).textTheme.headline1,),
          actions: <Widget>[
            IconButton(icon: Icon(Icons.edit), onPressed: _startEdit,)
          ],
        ),
      floatingActionButton: _buildFloatingButtons(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildFloatingButtons(){
    EdgeInsetsGeometry padding = EdgeInsets.symmetric(horizontal: 15, vertical: 0);

    bool coming = _activity.coming;
    Widget comingButton = FloatingActionButton.extended(
      onPressed: () => setState(() => _activity.coming = !coming),
      label: Text((coming ? "" : "Not ") + "Coming"),
      heroTag: "CreateButton",
      backgroundColor: coming ? Colors.teal : Colors.red,
      icon: Icon(coming ? Icons.check : Icons.check_box_outline_blank),
    );
    Widget editButton = FloatingActionButton.extended(onPressed: null, label: Text("Edit"), icon: Icon(Icons.edit), );

    return Stack(
      children: <Widget>[
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(padding: padding, child: editButton),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(padding: padding, child: comingButton),
        ),
      ],
    );
  }

  void _startEdit() {

  }
}
