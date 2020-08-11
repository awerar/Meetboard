import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meetboard/Models/activity.dart';
import 'package:meetboard/Models/activity_list_model.dart';
import 'package:meetboard/Models/activity_preview.dart';
import 'package:provider/provider.dart';

class EditActivityPage extends StatefulWidget {
  @override
  _EditActivityPageState createState() => _EditActivityPageState();
}

class _EditActivityPageState extends State<EditActivityPage> {
  DateTime _date;
  TimeOfDay _time;
  String _name;
  bool _hasTriedSubmitting = false;
  EditActivityPageSettings _settings;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final _firstDate = DateTime.now();
  final _lastDate = DateTime.now().add(Duration(days: 365*100));

  @override
  Widget build(BuildContext context) {
    if (_settings == null) {
      Object args = ModalRoute.of(context).settings.arguments;
      assert(args != null && args is EditActivityPageSettings);
      _settings = args;

      if (_settings.baseActivity != null) {
        _name = _settings.baseActivity.name;
        _date = _settings.baseActivity.time;
        _time = TimeOfDay.fromDateTime(_settings.baseActivity.time);
        _hasTriedSubmitting = true;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_settings.appbarLabel),
        centerTitle: true,
      ),
      body: GestureDetector(child: _buildForm(), onTap:() => FocusScope.of(context).requestFocus(new FocusNode()), behavior: HitTestBehavior.translucent,),
      floatingActionButton: FloatingActionButton(onPressed: _createActivity, child: Icon(Icons.save),),
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
        validator: (name) => name.length >= 3 ? (name.length <= 20 ? null : "Name too long") : "Name too short",
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
                icon: Icon(Icons.calendar_today),
                onPressed: _pickDate,
                color: Theme.of(context).colorScheme.onSurface,
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
                border: OutlineInputBorder(),
                prefixIcon: IconButton(
                  icon: Icon(Icons.access_time, ),
                  onPressed: _pickDate,
                  color: Theme.of(context).colorScheme.onSurface,
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

  void _createActivity() async {
    if (_formKey.currentState.validate()) {
      assert(_date != null && _time != null && _name != null);

      DateTime activityTime = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

      if (_settings.baseActivity == null) {
        Navigator.of(context).pop(Provider.of<ActivityListModel>(context).createActivity(name: _name, time: activityTime));
      } else {
        Activity newActivity = _settings.baseActivity.copyWith(name: _name, time: activityTime);
        Navigator.of(context).pop(newActivity);
      }
    } else _hasTriedSubmitting = true;
  }
}

class EditActivityPageSettings{
  final Activity baseActivity;
  final String appbarLabel;

  EditActivityPageSettings({@required this.appbarLabel, this.baseActivity});
}