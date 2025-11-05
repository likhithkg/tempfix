import 'package:cloud_firestore/cloud_firestore.dart';
import 'soil_sample_model.dart';

class SoilService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> addSoilSample(SoilSample sample) async {
    await firestore.collection("soil_samples").doc(sample.id).set(sample.toMap());
  }

  Future<List<SoilSample>> getSoilSamples(String userId) async {
    QuerySnapshot snapshot = await firestore
        .collection("soil_samples")
        .where("userId", isEqualTo: userId)
        .orderBy("date", descending: true)
        .get();

    return snapshot.docs.map((doc) => SoilSample.fromMap(doc.data() as Map<String, dynamic>)).toList();
  }

  Future<void> deleteSoilSample(String id) async {
    await firestore.collection("soil_samples").doc(id).delete();
  }
}
