import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class JoinActivityPage extends StatefulWidget {
  @override
  _JoinActivityPageState createState() => _JoinActivityPageState();
}

class _JoinActivityPageState extends State<JoinActivityPage> {
  GlobalKey<FormState> _formKey = GlobalKey();
  bool _validID = false;
  String _activityID = "";
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Join an existing activity"), centerTitle: false, actions: <Widget>[
        IconButton(icon: Icon(Icons.person_add), onPressed: _join,),
      ],),
      body: SizedBox.expand(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _unfocus,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Column(
              children: <Widget>[
                if (_isLoading) SizedBox(height: 5,),
                if (_isLoading) CircularProgressIndicator(),
                if (_isLoading) SizedBox(height: 15,),
                Form(
                  key: _formKey,
                  child: TextFormField(
                    textCapitalization: TextCapitalization.characters,
                    validator: (id) => _validID ? null : "Invalid ID",
                    onChanged: (id) => _activityID = id,
                    decoration: InputDecoration(
                      labelText: "Activity ID",
                      border: OutlineInputBorder()
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _join() async {
    if (_isLoading) return;

    _unfocus();
    setState(() {
      _isLoading = true;
    });
    if (await _validateID()) {
      bool worked = true;

      try {
        await CloudFunctions.instance.getHttpsCallable(functionName: "joinActivity").call({"id": _activityID});
      }  catch(e) {
        worked = false;
      }
      Navigator.pop(context, worked);
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<bool> _validateID() async {
    _validID = true;
    _formKey.currentState.validate();

    _validID = (await CloudFunctions.instance.getHttpsCallable(functionName: "activityExists").call({"id": _activityID})).data as bool;
    return _formKey.currentState.validate();
  }

  void _unfocus() {
    FocusScope.of(context).requestFocus(new FocusNode());
  }
}
