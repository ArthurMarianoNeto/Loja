import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:loja/helpers/firebase_errors.dart';
import 'package:loja/models/app_user.dart';

class UserManager extends ChangeNotifier {

  UserManager({FirebaseAuth? auth, FirebaseFirestore? firestore,
    this._getToken})
      : auth = auth ?? FirebaseAuth.instance,
        firestore = firestore ?? FirebaseFirestore.instance {
    _loadCurrentUser();
  }

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  // token do FCM; injetável para os testes (sem Firebase Messaging)
  final Future<String?> Function()? _getToken;

  AppUser? user;

  bool _loading = false;
  bool get loading => _loading;
  set loading(bool value){
    _loading = value;
    notifyListeners();
  }

  bool _loadingFace = false;
  bool get loadingFace => _loadingFace;
  set loadingFace(bool value){
    _loadingFace = value;
    notifyListeners();
  }

  bool get isLoggedIn => user != null;

  Future<void> signIn({
    required AppUser user,
    required void Function(String) onFail,
    required VoidCallback onSuccess,
  }) async {
    loading = true;
    try {
      final UserCredential result = await auth.signInWithEmailAndPassword(
          email: user.email!, password: user.password!);

      await _loadCurrentUser(firebaseUser: result.user);

      onSuccess();
    } on FirebaseAuthException catch (e){
      onFail(getErrorString(e.code));
    }
    loading = false;
  }

  Future<void> facebookLogin({
    required void Function(String) onFail,
    required VoidCallback onSuccess,
  }) async {
    loadingFace = true;

    final result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile']);

    switch(result.status){
      case LoginStatus.success:
        final credential = FacebookAuthProvider.credential(
            result.accessToken!.tokenString
        );

        final authResult = await auth.signInWithCredential(credential);

        final firebaseUser = authResult.user;
        if(firebaseUser != null){

          final newUser = AppUser(
              id: firebaseUser.uid,
              name: firebaseUser.displayName,
              email: firebaseUser.email,
              firestore: firestore,
          );
          user = newUser;

          await newUser.saveData();
          newUser.saveToken(_getToken);

          onSuccess();
        }
        break;
      case LoginStatus.cancelled:
      case LoginStatus.operationInProgress:
        break;
      case LoginStatus.failed:
        onFail(result.message ?? 'Falha no login com Facebook');
        break;
    }

    loadingFace = false;
  }

  Future<void> signUp({
    required AppUser user,
    required void Function(String) onFail,
    required VoidCallback onSuccess,
  }) async {
    loading = true;
    try {
      final UserCredential result = await auth.createUserWithEmailAndPassword(
          email: user.email!, password: user.password!);

      user.id = result.user!.uid;
      user.firestore = firestore;
      this.user = user;

      await user.saveData();
      user.saveToken(_getToken);

      onSuccess();
    } on FirebaseAuthException catch (e){
      onFail(getErrorString(e.code));
    }
    loading = false;
  }

  void signOut(){
    auth.signOut();
    user = null;
    notifyListeners();
  }
//--------
  void recoverPass(String email) {
    auth.sendPasswordResetEmail(email: email);
    notifyListeners();
  }
//---------
  Future<void> _loadCurrentUser({User? firebaseUser}) async {
    final User? currentUser = firebaseUser ?? auth.currentUser;
    if(currentUser != null){
      final DocumentSnapshot<Map<String, dynamic>> docUser = await firestore.collection('users')
          .doc(currentUser.uid).get();
      final loadedUser = AppUser.fromDocument(docUser);
      user = loadedUser;
      loadedUser.saveToken(_getToken);

      // verificando se é administrador

      final docAdmin = await firestore.collection('admins').doc(loadedUser.id).get();
      if(docAdmin.exists){
        loadedUser.admin = true;
      }

      notifyListeners();
    }
  }

  bool get adminEnabled => user != null && user!.admin;
}
