import 'package:flutter/material.dart';

class CreatePage extends StatefulWidget {
  @override
  _CreatePageState createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create new activity", style: Theme.of(context).textTheme.headline1),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _createActivity,
          )
        ],
      ),
      body: _buildForm(),
    );
  }

  Widget _buildForm() {
    List<Widget> sections = [
      TextFormField(
        decoration: InputDecoration(
          labelText: "Activity Name"
        ),
      ),
      Row(
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: (){

            },
          ),
          Expanded(
            child: TextFormField(
              decoration: InputDecoration(labelText: "Date",),
              enabled: false,
            ),
          )
        ],
      )
    ];

    var tiles = sections.map((e) {
      return ListTile(title: e);
    });

    return ListView(children: ListTile.divideTiles(tiles: tiles, context: context).toList());
  }

  void _createActivity() {
    Navigator.of(context).pop();
  }
}
