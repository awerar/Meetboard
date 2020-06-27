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
      ),
      body: _buildForm(),
      floatingActionButton: _buildFloatingButton(),
    );
  }

  Widget _buildForm() {
    return Container();
  }

  Widget _buildFloatingButton() {
    final createButton = FloatingActionButton.extended(
      tooltip: "Create",
      label: Text("Create"),
      onPressed: () {
        _createActivity();
        Navigator.of(context).pop();
      },
    );



    return createButton;
  }

  void _createActivity() {

  }
}
