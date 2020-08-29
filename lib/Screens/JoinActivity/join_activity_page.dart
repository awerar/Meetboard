import 'dart:math';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/*class JoinActivityPage extends StatefulWidget {
  @override
  _JoinActivityPageState createState() => _JoinActivityPageState();
}

class _JoinActivityPageState extends State<JoinActivityPage> {
  GlobalKey<FormState> _formKey = GlobalKey();
  bool _validID = false;
  String _activityID = "";
  bool _isLoading = false;

  TextEditingController textController;

  @override
  void initState() {
    textController = TextEditingController();

    super.initState();
  }

  @override
  void didChangeDependencies() {
    Object args = ModalRoute.of(context).settings.arguments;

    if (args is Map<String, String>) {
      if (args.containsKey("code")) textController.text = args["code"];
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Join an activity"), centerTitle: true,),
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
                  child: Flex(
                    direction: Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Flexible(
                        flex: 6,
                        child: TextFormField(
                          controller: textController,
                          textCapitalization: TextCapitalization.characters,
                          validator: (id) => _validID ? null : "Invalid Code",
                          onChanged: (id) => _activityID = id,
                          decoration: InputDecoration(
                            labelText: "Activity Code",
                            filled: true,
                          ),
                        ),
                      ),
                      Spacer(),
                      Expanded(
                        flex: 3,
                          child: Builder(
                              builder: (context) {
                                double buttonHeight = 50;

                                return Padding(
                                  padding: EdgeInsets.only(top: max(0, (62 - buttonHeight) / 2)),
                                  child: SizedBox(
                                    child: RaisedButton(
                                      child: Text("JOIN",),
                                      onPressed: !_isLoading ? _onPressJoinButton : null,
                                      color: Theme
                                          .of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                    height: buttonHeight,
                                  ),
                                );
                              }
                          )
                      )
                    ],
                  ),
                ),
                SizedBox(height: 20,),
                Builder(builder: (context) => Flex(
                  direction: Axis.horizontal,
                  children: <Widget>[
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlineButton.icon(
                          label: Text("SCAN QR CODE",),
                          icon: Icon(MdiIcons.qrcodeScan),
                          onPressed: () => !_isLoading ? _scanQRCode(context) : null,
                          borderSide: BorderSide(color: !_isLoading ? Theme.of(context).colorScheme.primary : Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ))
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _scanQRCode(BuildContext context) async {
    ScanResult result = await BarcodeScanner.scan(
      options: ScanOptions(restrictFormat: [BarcodeFormat.qr])
    );

    try {
      Uri uri = (await FirebaseDynamicLinks.instance.getDynamicLink(Uri.parse(result.rawContent))).link;

      if(uri.host == "meetboard" && uri.path == "/activities/join" && uri.queryParameters.containsKey("code")) {
        _join(uri.queryParameters["code"]);
      } else {
        Scaffold.of(context).showSnackBar(SnackBar(
          content: Text("Invalid QR code!"),
        ));
      }
    } catch(e) {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("Error decoding QR code!"),
      ));
    }
  }

  void _onPressJoinButton() async {
    _unfocus();

    setState(() {
      _isLoading = true;
    });

    if (await _validateID()) {
      _join(_activityID);
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _join(String id) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });
    bool worked = true;

    try {
      await CloudFunctions.instance.getHttpsCallable(functionName: "joinActivity").call({"id": id});
    }  catch(e) {
      worked = false;
    }
    Navigator.pop(context, worked);
    setState(() {
      _isLoading = false;
    });
  }

  Future<bool> _validateID() async {
    _validID = true;
    _formKey.currentState.validate();

    if (_activityID.length > 0) _validID = (await CloudFunctions.instance.getHttpsCallable(functionName: "activityExists").call({"id": _activityID})).data as bool;
    else _validID = false;
    return _formKey.currentState.validate();
  }

  void _unfocus() {
    FocusScope.of(context).requestFocus(new FocusNode());
  }
}*/
