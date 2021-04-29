import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:loja/models/section.dart';

class HomeManager extends ChangeNotifier {

  HomeManager(){
    _loadSections();
  }

  List<Section> _sections = [];

  List<Section> _editingSections = [];

  bool editing = false;

  final Firestore firestore = Firestore.instance;

  Future<void> _loadSections() async {
    firestore.collection('home').snapshots().listen((snapshot) {
      _sections.clear();
      for(final DocumentSnapshot document in snapshot.documents){
        _sections.add(Section.fromDocument(document));
      }
     print(sections);
      notifyListeners();
    });
  }

  List<Section> get sections {
    if(editing)
      return _editingSections;
    else
      return _sections;
  }

  void enterEditing(){
    editing = true;
    notifyListeners();
  }

  void saveEditing(){
    editing = false;
    _editingSections = _sections.map((s) => s.clone()).toList();
    notifyListeners();
  }

  void discardEditing(){
    editing = false;
    notifyListeners();
  }
}