import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreUserScope {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  const FirestoreUserScope({required this.firestore, required this.auth});

  String get requiredUid {
    final uid = auth.currentUser?.uid;
    if (uid == null || uid.trim().isEmpty) {
      throw StateError('User is not authenticated.');
    }
    return uid;
  }

  DocumentReference<Map<String, dynamic>> userDoc() {
    return firestore.collection('users').doc(requiredUid);
  }

  CollectionReference<Map<String, dynamic>> transactionsCollection() {
    return userDoc().collection('transactions');
  }

  CollectionReference<Map<String, dynamic>> banksCollection() {
    return userDoc().collection('banks');
  }
}
