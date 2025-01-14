import 'package:crawller_backend/_common/abstract/WithDocId.dart';
import 'package:crawller_backend/_common/util/AuthUtil.dart';
import 'package:crawller_backend/_common/util/LogUtil.dart';
import 'package:crawller_backend/_common/util/firebase/firedart/FiredartStoreUtil.dart';
import 'package:firedart/firedart.dart';

abstract class FirebaseStoreUtilInterface<Type extends WithDocId> {
  String collectionName;
  Type Function(Map<String, dynamic> map) fromMap;
  Map<String, dynamic> Function(Type instance) toMap;

  FirebaseStoreUtilInterface(
      {required this.collectionName,
      required this.fromMap,
      required this.toMap});

  static FirebaseStoreUtilInterface<Type> init<Type extends WithDocId>(
      {required String collectionName,
      required Type Function(Map<String, dynamic>) fromMap,
      required Map<String, dynamic> Function(Type instance) toMap}) {
    return FiredartStoreUtil<Type>(
        collectionName: collectionName, fromMap: fromMap, toMap: toMap);
  }

  CollectionReference cRef();

  DocumentReference dRef({int? documentId});

  Future<Map<String, dynamic>> dRefToMap(dRef);

  Type? applyInstance(Map<String, dynamic>? map) =>
      (map == null || map.isEmpty) ? null : fromMap(map);

  Future<Type?> getOneByField(
      {required QueryReference query,
      bool useSort = true,
      bool descending = false}) async {
    List<Type?> list =
        await getList(query: query, useSort: useSort, descending: descending);
    return list.isNotEmpty ? list.first : null;
  }

  Future<void> deleteOne({required int documentId}) async {
    return await dRef(documentId: documentId).delete();
  }

  Future<bool> exist({required QueryReference query}) async {
    var data = await getOneByField(query: query);
    return data != null;
  }

  Future<Type?> getOne({required int documentId}) async {
    return applyInstance(await dRefToMap(dRef(documentId: documentId)));
  }

  Map<String, dynamic> dSnapshotToMap(dSnapshot);

  List<Type> getListFromDocs(List docs,
      {bool useSort = true, bool descending = false}) {
    List<Type> typeList = List.from(docs
        .map((e) => applyInstance(dSnapshotToMap(e)))
        .where((e) => e != null)
        .toList());

    if (useSort) {
      typeList.sort((a, b) => (((a.documentId ?? 0) < (b.documentId ?? 0))
          ? (descending ? 1 : 0)
          : (descending ? 0 : 1)));
    }

    return typeList;
  }

  Future<List> cRefToList();

  Future<List> queryToList(query);

  Future<List<Type>> getList({
    required QueryReference query,
    bool useSort = true,
    bool descending = false,
  }) async {
    return getListFromDocs(
      await queryToList(query),
      useSort: useSort,
      descending: descending,
    );
  }

  Future<Type?> saveByDocumentId(
      {required Type instance, int? documentId}) async {
    var ref = dRef(documentId: documentId ?? instance.documentId);
    await ref.set(toMap(instance));
    return applyInstance(await dRefToMap(ref));
  }

  Future<void> deleteListByField(
      {required String key, required String value}) async {
    List list = await queryToList(cRef().where(key, isEqualTo: value));
    for (var documentSnapshot in list) {
      await documentSnapshot.reference.delete();
    }
  }

  Future<void> deleteOneByField(
      {required String key, required String value}) async {
    List list = await queryToList(cRef().where(key, isEqualTo: value));
    if (list.length != 1) {
      LogUtil.error("해당 key, value에 해당하는 문서가 1개가 아닙니다.");
      return;
    }

    await list[0].reference.delete();
  }
}
