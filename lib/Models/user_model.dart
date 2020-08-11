import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserModel extends ChangeNotifier {
  FirebaseUser _user;
  DocumentReference _userDocument, _userActivitiesDocument;
  CollectionReference _userActivityCollection;

  FirebaseUser get user => _user;
  DocumentReference get userDocument => _userDocument;
  CollectionReference get userActivityCollection => _userActivityCollection;

  UserModel() {
    _initializeUser();
  }

  void _initializeUser() async {
    _user = await FirebaseAuth.instance.currentUser();
    if (_user == null) {
      _user = (await FirebaseAuth.instance.signInAnonymously()).user;
    }
    FirebaseAuth.instance.onAuthStateChanged.listen((newUser) async {
      if (newUser == null) {
        _user = newUser;
        notifyListeners();

        _user = (await FirebaseAuth.instance.signInAnonymously()).user;
        notifyListeners();
      }
    });

    _handleUserDocument();

    notifyListeners();
  }

  void _handleUserDocument() async {
    _userDocument = Firestore.instance.collection("users").document(_user.uid);
    _userActivitiesDocument = _userDocument.collection("private_data").document("user_activities");
    _userActivityCollection = _userActivitiesDocument.collection("user_activities");
    DocumentSnapshot documentSnapshot = await _userDocument.get();
    if (!documentSnapshot.exists) _initializeUserDocument();
  }

  void _initializeUserDocument() {
    Map<String, dynamic> startPrivateData = Map<String, dynamic>();
    startPrivateData["activity_count"] = 0;
    startPrivateData["activities"] = [];

    _userDocument.setData(Map());
    _userActivitiesDocument.setData(startPrivateData);
  }
}