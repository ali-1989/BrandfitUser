// ignore_for_file: empty_catches

import 'dart:core';

import 'package:flutter/foundation.dart';

import 'package:iris_db/iris_db.dart';
import 'package:iris_tools/dateSection/dateHelper.dart';

import '/models/dataModels/counterModels/caloriesCounterDayModel.dart';
import '/system/keys.dart';
import '/tools/centers/dbCenter.dart';

//*** use for clone [with user holder]

class CaloriesCounterManager {
  static final Map<int, CaloriesCounterManager> _holderLink = {};

  final List<CaloriesCounterDayModel> _list = [];
  late int userId;
  DateTime? lastUpdateTime;

  static CaloriesCounterManager managerFor(int userId) {
    if (_holderLink.keys.contains(userId)) {
      return _holderLink[userId]!;
    }

    return _holderLink[userId] = CaloriesCounterManager._(userId);
  }

  static void removeManager(int userId) {
    _holderLink.removeWhere((key, value) => key == userId);
  }

  bool isUpdated({Duration duration = const Duration(minutes: 10)}) {
    var now = DateTime.now();
    now = now.subtract(duration);

    return lastUpdateTime != null && lastUpdateTime!.isAfter(now);
  }

  void setUpdate() {
    lastUpdateTime = DateTime.now();
  }
  ///-----------------------------------------------------------------------------------------
  CaloriesCounterManager._(this.userId);

  List<CaloriesCounterDayModel> get allModelList => _list;

  CaloriesCounterDayModel? getById(int id) {
    try {
      return _list.firstWhere((element) => element.id == id);
    }
    catch (e) {
      return null;
    }
  }

  CaloriesCounterDayModel addItem(CaloriesCounterDayModel item) {
    final existItem = getById(item.id); //?? 0

    if (existItem == null) {
      _list.add(item);
      return item;
    }
    else {
      existItem.matchBy(item);
      return existItem;
    }
  }

  List<CaloriesCounterDayModel> addItemsFromMap(List? itemList, {String? domain}) {
    final res = <CaloriesCounterDayModel>[];

    if (itemList != null) {
      for (final row in itemList) {
        final itm = CaloriesCounterDayModel.fromMap(row);//, domain: domain
        addItem(itm);

        res.add(itm);
      }
    }

    return res;
  }

  Future<List<int>> loadByIds(List<int> ids) {
    final con = Conditions();
    con.add(Condition(ConditionType.IN)..key = Keys.id..value = ids);

    final cursorList = DbCenter.db.query(DbCenter.tbCaloriesCounter, con);

    final caseIds = <int>[];

    for (var itm in cursorList) {
      final r = CaloriesCounterDayModel.fromMap(itm);

      caseIds.add(r.id);
      addItem(r);
    }

    return SynchronousFuture(caseIds);
  }

  Future sinkItems(List<CaloriesCounterDayModel> list) async {
    for (final row in list) {
      final con = Conditions();
      con.add(Condition()..key = Keys.id..value = row.id);

      await DbCenter.db.insertOrUpdate(DbCenter.tbCaloriesCounter, row.toMap(), con);
      //await DbCenter.db.insertOrUpdateEx(DbCenter.tbCaloriesCounter, row.toMap(), con, before);
    }
  }
  
  Future removeItem(int id, bool fromDb) async {
    _list.removeWhere((element) => element.id == id);

    if (fromDb) {
      final con = Conditions();
      con.add(Condition()..key = Keys.id..value = id);

      await DbCenter.db.delete(DbCenter.tbCaloriesCounter, con);
    }
  }

  Future removeNotMatchByServer(List<int> serverIds) async {
    _list.removeWhere((element) => !serverIds.contains(element.id));

    final con = Conditions();
    con.add(Condition(ConditionType.NotIn)..key = Keys.id..value = serverIds);

    return DbCenter.db.delete(DbCenter.tbCaloriesCounter, con);
  }

  void sortList(bool asc) async {
    _list.sort((CaloriesCounterDayModel p1, CaloriesCounterDayModel p2) {
      final d1 = DateHelper.tsToSystemDate(p1.date);
      final d2 = DateHelper.tsToSystemDate(p2.date);

      if (d1 == null) {
        return asc ? 1 : 1;
      }

      if (d2 == null) {
        return asc ? 1 : 1;
      }

      return asc ? d1.compareTo(d2) : d2.compareTo(d1);
    });
  }
  ///-----------------------------------------------------------------------------------------
  CaloriesCounterDayModel? findByDateOnly(String date) {
    try {
      return _list.firstWhere((element) => element.date == date);
    }
    catch (e) {
      return null;
    }
  }

  Future<List<int>> loadItems({int limit = 50, String? lastTs}) {
    final con = Conditions();
    con.add(Condition()..key = Keys.userId..value = userId);

    if (lastTs != null) {
      con.add(Condition(ConditionType.IsBeforeTs)..key = 'date'..value = lastTs);
    }


    int orderBy(j1, j2) {
      final s1 = j1.value['date'];
      final s2 = j2.value['date'];

      final d1 = DateHelper.tsToSystemDate(s1);
      final d2 = DateHelper.tsToSystemDate(s2);

      if(d1 == null && d2 == null){
        return 0;
      }

      if(d1 == null){
        return -1;
      }

      if(d2 == null){
        return 1;
      }

      return d2.compareTo(d1);
    }

    final cursorList = DbCenter.db.query(DbCenter.tbCaloriesCounter, con, limit: limit, orderBy: orderBy);
    final caseIds = <int>[];

    for (var itm in cursorList) {
      final r = CaloriesCounterDayModel.fromMap(itm);

      caseIds.add(r.id);
      addItem(r);
    }

    return SynchronousFuture(caseIds);
  }

  CaloriesCounterDayModel generateModel({
    String? date,
    }){
    final model = CaloriesCounterDayModel();
    model.date = date?? DateHelper.getNowTimestampToUtc();

    addItem(model);
    sortList(false);
    sinkItems([model]);

    return model;
  }
}
