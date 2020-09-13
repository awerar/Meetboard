import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meetboard/ActivitySystem/activity_reference.dart';
import 'package:meetboard/ActivitySystem/activity_snapshot.dart';
import 'package:meetboard/ActivitySystem/activity_tracking_manager.dart';
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
  bool _creating = false;

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
        validator: (name) => name.length >= 3 ? (name.length <= 20 ? null : "Name must be at most 20 letters long") : "Name must be at least 3 letters long",
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
      return ListTile(title: e) as Widget;
    });

    return Form(
      child: ListView(children: tiles.toList()..insert(0, Column(
        children: <Widget>[
          if (_creating) CircularProgressIndicator(),
          if(_creating) SizedBox(height: 10)
        ],
      )), padding: EdgeInsets.only(top: 15),),
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
    if (_creating) return;

    if (_formKey.currentState.validate()) {
      assert(_date != null && _time != null && _name != null);

      DateTime activityTime = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

      setState(() {
        _creating = true;
      });
      if (_settings.baseActivity == null) {
        ActivityReference ref = (await ActivityTrackingManager.instance.createActivity(_name, activityTime));
        _settings._editFinished.complete(ref);
      } else {
        _settings.baseActivity.ref.write((writer) {
          writer.setName(_name);
          writer.setTime(activityTime);
        });
        _settings._editFinished.complete(_settings.baseActivity.ref);
      }
      Navigator.of(context).pop();
    } else _hasTriedSubmitting = true;
  }
}

class EditActivityPageSettings{
  final ActivitySnapshot baseActivity;
  final String appbarLabel;
  final Completer<ActivityReference> _editFinished = Completer();
  final void Function(Future<ActivityReference> ref) handleOnEditFinished;

  EditActivityPageSettings({@required this.appbarLabel, this.baseActivity, this.handleOnEditFinished}) {
    if (handleOnEditFinished != null) handleOnEditFinished(_editFinished.future);
  }
}