import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserModel extends ChangeNotifier {
  FirebaseUser _user;
  DocumentReference _userDocument;

  FirebaseUser get user => _user;
  DocumentReference get userDocument => _userDocument;

  UserModel() {
    _initializeUser();
  }

  void _initializeUser() async {
    _user = await FirebaseAuth.instance.currentUser();
    if (_user == null) {
      _user = (await FirebaseAuth.instance.signInAnonymously()).user;
    }

    _handleUserDocument();

    notifyListeners();
  }

  void _handleUserDocument() async {
    _userDocument = Firestore.instance.collection("Users").document(_user.uid);
    DocumentSnapshot documentSnapshot = await _userDocument.get();
    if (!documentSnapshot.exists) _initializeUserDocument();
  }

  void _initializeUserDocument() {

  }
}