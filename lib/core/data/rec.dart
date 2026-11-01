import 'package:cloud_firestore/cloud_firestore.dart';

/// One Firestore document: id + raw map, with small typed getters.
/// Money fields are int halalas (see core/utils/money.dart).
class Rec {
  final String id;
  final Map<String, dynamic> d;
  const Rec(this.id, this.d);

  String s(String k, [String def = '']) {
    final v = d[k];
    return v == null ? def : v.toString();
  }

  int i(String k) {
    final v = d[k];
    return v is num ? v.round() : 0;
  }

  bool b(String k) => d[k] == true;

  DateTime? dt(String k) {
    final v = d[k];
    return v is Timestamp ? v.toDate() : null;
  }

  bool get deleted => d['isDeleted'] == true;
}
