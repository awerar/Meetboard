import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meetboard/Models/activity.dart';

class CreateActivityPage extends StatefulWidget {
  static const String routeName = "/create_activity_page";

  @override
  _CreateActivityPageState createState() => _CreateActivityPageState();
}

class _CreateActivityPageState extends State<CreateActivityPage> {
  DateTime _date;
  TimeOfDay _time;
  String _name;
  bool _hasTriedSubmitting = false;
  Activity _baseActivity;
  String _finishedLabel;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final _firstDate = DateTime.now();
  final _lastDate = DateTime.now().add(Duration(days: 365*100));

  @override
  Widget build(BuildContext context) {
    if (_finishedLabel == null) {
      Object args = ModalRoute.of(context).settings.arguments;
      assert(args != null && args is Iterable<dynamic> && args.length >= 1 && args.elementAt(0) is String);

      List<dynamic> argsList = (args as Iterable<dynamic>).toList(growable: false);
      _finishedLabel = argsList[0];

      if (argsList.length >= 2 && argsList[2] is Activity) _baseActivity = argsList[1];
      if (_baseActivity != null) {
        _name = _baseActivity.name;
        _date = _baseActivity.time;
        _time = TimeOfDay.fromDateTime(_baseActivity.time);
        _hasTriedSubmitting = true;
      }
    }

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
      floatingActionButton: FloatingActionButton.extended(onPressed: _createActivity, label: Text(_finishedLabel,), heroTag: "CreateButton"),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
        autocorrect: true,
        enableSuggestions: true,
        textCapitalization: TextCapitalization.words,
        validator: (name) => name.length >= 3 ? null : "Name too short",
        autovalidate: true,
        controller: TextEditingController(text: _name),
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
            autovalidate: _hasTriedSubmitting,
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
            autovalidate: _hasTriedSubmitting,
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
      }
    });
  }

  void _pickTime() {
    showTimePicker(context: context, initialTime: _time == null ? TimeOfDay(hour: 12, minute: 0) : _time).then((time) {
      if (time != null) {
        setState(() {
          _time = time;
        });
      }
    });
  }

  void _createActivity() {
    if (_formKey.currentState.validate()) {
      assert(_date != null && _time != null && _name != null);

      DateTime activityTime = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

      if (_baseActivity == null) {
        Activity activity = Activity(_name, activityTime);

        Navigator.of(context).pop(activity);
      } else {
        _baseActivity.time = activityTime;
        _baseActivity.name = _name;

        Navigator.of(context).pop(_baseActivity);
      }
    } else _hasTriedSubmitting = true;
  }
}
