import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project_model.dart';
import '../models/service_model.dart';
import '../models/book_model.dart';
import '../models/social_model.dart';
import '../models/cv_model.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<ProjectModel>> getProjects() {
    return _db.collection('projects').snapshots().map((snap) {
      return snap.docs
          .map((doc) => ProjectModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Stream<List<ServiceModel>> getServices() {
    return _db.collection('services').snapshots().map((snap) {
      return snap.docs
          .map((doc) => ServiceModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Stream<List<BookModel>> getBooks() {
    return _db.collection('books').snapshots().map((snap) {
      return snap.docs
          .map((doc) => BookModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Stream<List<SocialModel>> getSocial() {
    return _db.collection('social').snapshots().map((snap) {
      return snap.docs
          .map((doc) => SocialModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Stream<CvModel?> getCv() {
    return _db.collection('cv').limit(1).snapshots().map((snap) {
      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      return CvModel.fromMap(doc.id, doc.data());
    });
  }
}
