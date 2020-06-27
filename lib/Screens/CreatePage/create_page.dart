import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreatePage extends StatefulWidget {
  @override
  _CreatePageState createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  DateTime _dateTime = DateTime.now();

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
              showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 365*100)),
              ).then((date) {
                if (date != null) {
                  setState(() {
                    if (_dateTime == null) _dateTime = date;
                    else _dateTime = DateTime.utc(date.year, date.month, date.day, _dateTime.hour, _dateTime.minute);
                  });
                }
              });
            },
          ),
          Expanded(
            child: TextFormField(
              decoration: InputDecoration(
                labelText: "Date",
              ),
              enabled: false,
              controller: TextEditingController(text: DateFormat("yMMMEd").format(_dateTime)),
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
