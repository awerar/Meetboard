import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meetboard/Models/Activity.dart';

class CreatePage extends StatefulWidget {
  CreatePage(this._callback);
  final void Function(Activity) _callback;

  @override
  _CreatePageState createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  DateTime _date;
  TimeOfDay _time;
  String _name;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final _firstDate = DateTime.now();
  final _lastDate = DateTime.now().add(Duration(days: 365*100));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create a new activity", style: Theme.of(context).textTheme.headline1),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _createActivity,
          )
        ],
      ),
      body: GestureDetector(child: _buildForm(), onTap:() => FocusScope.of(context).requestFocus(new FocusNode()), behavior: HitTestBehavior.translucent,),
    );
  }

  Widget _buildForm() {
    List<Widget> sections = [
      //Name
      TextFormField(
        decoration: InputDecoration(
          labelText: "Activity Name",
          border: OutlineInputBorder(borderSide: BorderSide(),),
        ),
        onChanged: (name) => _name = name,
        autofocus: true,
        autocorrect: true,
        enableSuggestions: true,
        textCapitalization: TextCapitalization.words,
        validator: (name) => name.length >= 3 ? null : "Name too short",
        autovalidate: true,
      ),

      //Date
      GestureDetector(
        onTap: _pickDate,
        child: AbsorbPointer(
          child: TextFormField(
            decoration: InputDecoration(
              labelText: "Date",
              border: OutlineInputBorder(borderSide: BorderSide(),),
              prefixIcon: IconButton(
                icon: Icon(Icons.calendar_today, color: Colors.black,),
                onPressed: _pickDate,
              )
            ),
            controller: TextEditingController(text: _date != null ? DateFormat("yMMMEd").format(_date) : ""),
            validator: (v) => _date == null ? "Date not picked" : null,
          ),
        ),
      ),

      //Time
      GestureDetector(
        onTap: _pickTime,
        child: AbsorbPointer(
          child: TextFormField(
            decoration: InputDecoration(
                labelText: "Time",
                border: OutlineInputBorder(borderSide: BorderSide(),),
                prefixIcon: IconButton(
                  icon: Icon(Icons.access_time, color: Colors.black,),
                  onPressed: _pickDate,
                )
            ),
            controller: TextEditingController(text: _time != null ? _time.format(context) : ""),
            validator: (v) => _time == null ? "Time not set" : null,
          ),
        ),
      )
    ];

    var tiles = sections.map((e) {
      return ListTile(title: e);
    });

    return Form(
      child: ListView(children: tiles.toList(), padding: EdgeInsets.only(top: 15),),
      key: _formKey,
    );
  }

  void _pickDate() {
    showDatePicker(
      context: context,
      initialDate: _date == null ? DateTime.now().add(Duration(days: 1)) : _date,
      firstDate: _firstDate,
      lastDate: _lastDate,
    ).then((date) {
      if (date != null) {
        setState(() {
          _date = date;
        });
        _formKey.currentState.validate();
      }
    });
  }

  void _pickTime() {
    showTimePicker(context: context, initialTime: _time == null ? TimeOfDay(hour: 12, minute: 0) : _time).then((time) {
      if (time != null) {
        setState(() {
          _time = time;
        });
        _formKey.currentState.validate();
      }
    });
  }

  void _createActivity() {
    if (_formKey.currentState.validate()) {
      assert(_date != null && _time != null && _name != null);

      Activity activity = Activity(_name, DateTime(
          _date.year, _date.month, _date.day, _time.hour, _time.minute));

      widget._callback(activity);
      Navigator.of(context).pop();
    }
  }
}
