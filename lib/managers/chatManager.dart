// ignore_for_file: empty_catches

import 'dart:async';
import 'dart:core';

import 'package:flutter/foundation.dart';

import 'package:iris_db/iris_db.dart';
import 'package:iris_tools/api/converter.dart';
import 'package:iris_tools/api/generator.dart';
import 'package:iris_tools/api/helpers/jsonHelper.dart';
import 'package:iris_tools/api/helpers/pathHelper.dart';
import 'package:iris_tools/dateSection/dateHelper.dart';

import '/database/models/userAdvancedModelDb.dart';
import '/managers/userAdvancedManager.dart';
import '/models/dataModels/chatModels/chatMediaModel.dart';
import '/models/dataModels/chatModels/chatMessageModel.dart';
import '/models/dataModels/chatModels/chatModel.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/models/holderModels/chatDownloadUploadHolder.dart';
import '/system/downloadUpload.dart';
import '/system/keys.dart';
import '/system/requester.dart';
import '/system/session.dart';
import '/tools/app/appManager.dart';
import '/tools/centers/broadcastCenter.dart';
import '/tools/centers/dbCenter.dart';
import '/tools/centers/httpCenter.dart';
import '/tools/serverTimeTools.dart';

class ChatManager {
  static final Map<int, ChatManager> _holderLink = {};
  static final List<ChatMessageModel> _allChatMessageList = [];
  static final List<ChatMediaModel> _allMediaMessageList = [];
  static Timer? _failSendTimer;
  static int _failSendCounter = 0;

  final List<ChatModel> _list = [];
  late int userId;
  DateTime? lastUpdateTime;

  static ChatManager managerFor(int userId) {
    if (_holderLink.keys.contains(userId)) {
      return _holderLink[userId]!;
    }

    return _holderLink[userId] = ChatManager._(userId);
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
  ChatManager._(this.userId);

  List<ChatModel> get allChatList => _list;
  static List<ChatMessageModel> get allMessageList => _allChatMessageList;
  static List<ChatMediaModel> get allMediaMessageList => _allMediaMessageList;

  ChatModel? getById(int id) {
    try {
      return _list.firstWhere((element) => element.id == id);
    }
    catch (e) {
      return null;
    }
  }

  ChatModel addItem(ChatModel item) {
    final existItem = getById(item.id ?? 0);

    if (existItem == null) {
      _list.add(item);
      return item;
    }
    else {
      existItem.matchBy(item);
      existItem.invalidate();
      return existItem;
    }
  }

  List<ChatModel> addItemsFromMap(List? itemList, {String? domain}) {
    final res = <ChatModel>[];

    if (itemList != null) {
      for (var row in itemList) {
        final itm = ChatModel.fromMap(row, domain: domain);
        addItem(itm);

        res.add(itm);
      }
    }

    return res;
  }

  Future<int> loadByIds(List<int> ids) async {
    return (await fetchChatsByIds(ids)).length;
  }

  Future sinkItems(List<ChatModel> list) async {
    return sinkChats(list);
  }

  Future sinkDraftItem(ChatModel tm) async {
    final con = Conditions();
    con.add(Condition()..key = Keys.id..value = tm.id);

    await DbCenter.db.insertOrUpdate(DbCenter.tbChatDraft, tm.toMap(), con);
  }

  Future removeItem(int id, bool fromDb) async {
    _list.removeWhere((element) => element.id == id);

    if (fromDb) {
      final con = Conditions();
      con.add(Condition()..key = Keys.id..value = id);

      await DbCenter.db.delete(DbCenter.tbChats, con);
    }
  }

  void sortList(bool asc) async {
    _list.sort((ChatModel p1, ChatModel p2) {
      final d1 = p1.chatSortTime;
      final d2 = p2.chatSortTime;

      if (d1 == null) {
        return asc ? 1 : 1;
      }

      if (d2 == null) {
        return asc ? 1 : 1;
      }

      return asc ? d1.compareTo(d2) : d2.compareTo(d1);
    });
  }

  Future removeNotMatchByServer(List<int> serverIds) async {
    _list.removeWhere((element) => !element.isDraft && !serverIds.contains(element.id));

    final con = Conditions();
    con.add(Condition(ConditionType.NotIn)..key = Keys.id..value = serverIds);

    //return DbCenter.db.delete(DbCenter.tbChats, con);
  }
  ///-----------------------------------------------------------------------------------------
  ChatModel? findByReceiver(int id) {
    try {
      return _list.firstWhere((element) => element.receiverId == id);
    }
    catch (e) {
      return null;
    }
  }

  static ChatMessageModel? getMessageById(BigInt id) {
    try {
      return _allChatMessageList.firstWhere((element) => element.id == id);
    }
    catch (e) {
      return null;
    }
  }

  static ChatMediaModel? getMediaById(BigInt id) {
    try {
      return _allMediaMessageList.firstWhere((element) => element.id == id);
    }
    catch (e) {
      return null;
    }
  }

  static ChatMessageModel addMessage(ChatMessageModel tm) {
    final existItem = getMessageById(tm.id!);

    if (existItem == null) {
      _allChatMessageList.add(tm);
      return tm;
    }
    else {
      existItem.matchBy(tm);
      return existItem;
    }
  }

  static ChatMediaModel addMediaMessage(ChatMediaModel mm) {
    final existItem = getMediaById(mm.id!);

    if (existItem == null) {
      allMediaMessageList.add(mm);
      return mm;
    }
    else {
      existItem.matchBy(mm);
      return existItem;
    }
  }

  static List<ChatMessageModel> addMessagesFromMap(List? itemList) {
    final res = <ChatMessageModel>[];

    if (itemList != null) {
      for (var row in itemList) {
        var tm = ChatMessageModel.fromMap(row);
        tm = addMessage(tm);

        res.add(tm);
      }
    }

    return res;
  }

  static List<ChatMediaModel> addMediaMessagesFromMap(List? itemList) {
    final res = <ChatMediaModel>[];

    if (itemList != null) {
      for (var row in itemList) {
        var tm = ChatMediaModel.fromMap(row);
        tm = addMediaMessage(tm);

        res.add(tm);
      }
    }

    return res;
  }

  List<ChatModel> getUnSeenList() {
    return allChatList.where((tm) => tm.unReadCount() > 0).toList();
  }

  static List<BigInt> takeMediaIdsByMessageIds(List<BigInt> ids) {
    final itr = _allChatMessageList.where((element) => ids.contains(element.id));
    final mediaIds = <BigInt>[];

    for (var msg in itr) {
      if (msg.mediaId != null) {
        mediaIds.add(msg.mediaId!);
      }
    }

    return mediaIds;
  }

  static List<int> takeUserIdsByMessageIds(List<BigInt> ids) {
    final itr = _allChatMessageList.where((element) => ids.contains(element.id));
    final userIds = <int>[];

    for (var msg in itr) {
      if (!userIds.contains(msg.senderUserId)) {
        userIds.add(msg.senderUserId);
      }
    }

    return userIds;
  }

  void sortChatsById(bool asc) {
    allChatList.sort((e1, e2) {
      if (asc) {
        return e1.id!.compareTo(e2.id!);
      }

      return e2.id!.compareTo(e1.id!);
    });
  }

  Future<List<int>> fetchChatsByIds(List<int> ids) {
    final con = Conditions()
      ..add(Condition(ConditionType.IN)..key = Keys.id..value = ids);

    final cursorList = DbCenter.db.query(DbCenter.tbChats, con);

    final chatIds = <int>[];

    for (var itm in cursorList) {
      final r = ChatModel.fromMap(itm);

      chatIds.add(r.id!);
      addItem(r);
    }

    return SynchronousFuture(chatIds);
  }

  Future<ChatModel?> fetchChatsByReceiverId(int id) async {
    final con = Conditions();
    con.add(Condition()..key = 'receiver_id'..value = id);

    var cursor = DbCenter.db.queryFirst(DbCenter.tbChats, con);
    cursor ??= DbCenter.db.queryFirst(DbCenter.tbChatDraft, con);

    if(cursor == null){
      return null;
    }

    var r = ChatModel.fromMap(cursor);
    r = addItem(r);

    return r;
  }

  Future<List<int>> fetchChats({int limit = 200, String? lastTs}) {
    final con = Conditions();
    con.add(Condition()..key = 'creator_user_id'..value = userId);

    if (lastTs != null) {
      con.add(Condition(ConditionType.IsBeforeTs)..key = 'creation_date'..value = lastTs);
    }

    int orderByServerTs(j1, j2) {
      final s1 = j1.value['server_receive_ts'];
      final s2 = j2.value['server_receive_ts'];

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

    final conForSort1 = Conditions();
    final conForSort2 = Conditions();

    List getServerReceiveTs(j1, j2) {
      conForSort1.clearConditions();
      conForSort2.clearConditions();
      conForSort1.add(Condition()..key = 'chat_id'..value = j1.value['id']);
      conForSort2.add(Condition()..key = 'chat_id'..value = j2.value['id']);

      final msg1 = DbCenter.db.query(DbCenter.tbChatMessage, conForSort1, limit: 1, orderBy: orderByServerTs);
      final msg2 = DbCenter.db.query(DbCenter.tbChatMessage, conForSort2, limit: 1, orderBy: orderByServerTs);

      var v1 = '';
      var v2 = '';

      if (msg1.isNotEmpty) {
        v1 = msg1.first['server_receive_ts'];
      }

      if (msg2.isNotEmpty) {
        v2 = msg2.first['server_receive_ts'];
      }

      return [v1, v2];
    }

    int orderBy(j1, j2) {
      final serverTs = getServerReceiveTs(j1, j2);

      String ser1 = serverTs[0];
      String ser2 = serverTs[1];

      final s1 = ser1.isEmpty ? j1.value['creation_date'] : ser1;
      final s2 = ser2.isEmpty ? j2.value['creation_date'] : ser2;

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

    final cursorList = DbCenter.db.query(DbCenter.tbChats, con, limit: limit, orderBy: orderBy);
    final cursorList2 = DbCenter.db.query(DbCenter.tbChatDraft, con, limit: limit, orderBy: orderBy);

    final chatIds = <int>[];

    for (final itm in cursorList) {
      final r = ChatModel.fromMap(itm);

      chatIds.add(r.id!);
      addItem(r);
    }

    for(final itm in cursorList2){
      final r = ChatModel.fromMap(itm);
      r.isDraft = true;

      chatIds.add(r.id!);
      addItem(r);
    }

    return SynchronousFuture(chatIds);
  }

  Future<ChatModel?> fetchDraftChat(int id) async {
    final fetched = getById(id);

    if(fetched != null && fetched.isDraft){
      return fetched;
    }

    final con = Conditions();
    con.add(Condition()..key = 'id'..value = id);

    final cursor = DbCenter.db.queryFirst(DbCenter.tbChatDraft, con);

    if(cursor == null){
      return null;
    }

    final tm = ChatModel.fromMap(cursor);
    tm.isDraft = true;

    return SynchronousFuture(tm);
  }

  Future<List<int>> fetchUnSeenChats({int limit = 100, String? lastTs}) {
    final innerCon = Conditions();
    final con = Conditions();

    con.add(Condition(ConditionType.TestFn)..testFn = (v){
      innerCon.clearConditions();
      final lastSeenTs = v['last_message_ts'];

      if(lastSeenTs == null){
        innerCon.add(Condition(ConditionType.EQUAL)..key = 'conversation_id'..value = v['id']);

        return DbCenter.db.exist(DbCenter.tbChatMessage, innerCon);
      }

      innerCon.add(Condition(ConditionType.IsAfterTs)..key = 'server_receive_ts'..value = lastSeenTs);

      return DbCenter.db.exist(DbCenter.tbChatMessage, innerCon);
    });

    if(lastTs != null){
      con.add(Condition(ConditionType.IsBeforeTs)..key = 'creation_date'..value = lastTs);
    }

    int orderBy(j1, j2) {
      final s1 = j1.value['creation_date'];
      final s2 = j2.value['creation_date'];

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

    final cursorList = DbCenter.db.query(DbCenter.tbChats, con, limit: limit, orderBy: orderBy);
    final chatIds = <int>[];

    for (var itm in cursorList) {
      final r = ChatModel.fromMap(itm);

      chatIds.add(r.id!);
      addItem(r);
    }

    return SynchronousFuture(chatIds);
  }

  static Future<List<BigInt>> fetchMessageByChatIds(List<int> chatIds) {
    final con = Conditions()
      ..add(Condition(ConditionType.IN)..key = 'conversation_id'..value = chatIds);

    var fetchList = DbCenter.db.query(DbCenter.tbChatMessage, con,);

    final ids = <BigInt>[];

    for (var row in fetchList) {
      final tm = ChatMessageModel.fromMap(row);

      addMessage(tm);
      ids.add(tm.id!);
    }

    fetchList = DbCenter.db.query(DbCenter.tbChatMessageDraft, con, limit: chatIds.length);
    for (var row in fetchList) {
      final tm = ChatMessageModel.fromMap(row);
      tm.isDraft = true;

      addMessage(tm);
      ids.add(tm.id!);
    }

    return SynchronousFuture(ids);
  }

  static Future<void> fetchMediaMessageByIds(List<BigInt> mediaIds) {
    final con = Conditions();
    con.add(Condition(ConditionType.IN)..key = 'id'..value = mediaIds);

    var fetchList = DbCenter.db.query(DbCenter.tbMediaMessage, con, limit: mediaIds.length);

    for (var row in fetchList) {
      final mm = ChatMediaModel.fromMap(row);
      addMediaMessage(mm);
    }

    fetchList = DbCenter.db.query(DbCenter.tbMediaMessageDraft, con, limit: mediaIds.length);

    for (var row in fetchList) {
      final mm = ChatMediaModel.fromMap(row);
      mm.isDraft = true;

      addMediaMessage(mm);
    }

    return Future.value();
    //return SynchronousFuture(fetchList.length);
  }

  int findChatLittleId() {
    var res = _list.first.id ?? 0;

    for (var element in allChatList) {
      if (element.id! < res) {
        res = element.id!;
      }
    }

    return res;
  }

  String findChatLittleTs() {
    var res = '';
    final ch = _list.first.creationDate!;

    for (var element in allChatList) {
      if (element.creationDate!.compareTo(ch) < 0) {
        res = element.creationDateTs!;
      }
    }

    return res;
  }

  ChatModel generateDraftChat(UserModel user, {
    int? receiverId,
    int? type,
    String? title,
    }){
    final chatModel = ChatModel();
    chatModel.id = Generator.generateIntId(10);
    chatModel.creatorUserId = user.userId;
    chatModel.creationDate = ServerTimeTools.utcTimeMatchServer;
    chatModel.creationDateTs = DateHelper.toTimestamp(chatModel.creationDate!);
    chatModel.title = title;
    chatModel.isDraft = true;
    chatModel.receiverId = receiverId?? 0;
    chatModel.type = type?? 10;

    addItem(chatModel);
    sortList(false);
    sinkDraftItem(chatModel);

    if(UserAdvancedManager.getById(user.userId) == null) {
      final self = UserAdvancedModelDb.fromMap(user.toMap());
      UserAdvancedManager.addItem(self);
      self.sink();
    }

    return chatModel;
  }

  static Future sinkChats(List<ChatModel> list) async {
    before(oldVal, newVal) {
      final o = oldVal['last_message_ts'];
      final n = newVal['last_message_ts'];
      final oo = DateHelper.tsToSystemDate(o);
      final nn = DateHelper.tsToSystemDate(n);

      if (DateHelper.compareDates(oo, nn) > 0) {
        newVal['last_message_ts'] = o;
      }

      return newVal;
    }

    for (var row in list) {
      final con = Conditions();
      con.add(Condition()..key = Keys.id..value = row.id);

      if(row.isDraft){
        await DbCenter.db.insertOrUpdateEx(DbCenter.tbChatDraft, row.toMap(), con, before);
      }
      else {
        await DbCenter.db.insertOrUpdateEx(DbCenter.tbChats, row.toMap(), con, before);
      }
    }
  }

  static Future sinkChatMessages(List<ChatMessageModel> list) async {
    for (var row in list) {
      final con = Conditions();
      con.add(Condition()..key = Keys.id..value = row.id);

      if (row.isDraft) {
        await DbCenter.db.insertOrUpdate(DbCenter.tbChatMessageDraft, row.toMap(), con);
      }
      else {
        await DbCenter.db.insertOrUpdate(DbCenter.tbChatMessage, row.toMap(), con);
      }
    }
  }

  static Future deleteMessages(List<ChatMessageModel> list) async {
    for (var row in list) {
      final con = Conditions();
      con.add(Condition()..key = Keys.id..value = row.id);

      await DbCenter.db.delete(DbCenter.tbChatMessage, con);
    }
  }

  static Future deleteDraftMessages(List<ChatMessageModel> list) async {
    for (var row in list) {
      final con = Conditions();
      con.add(Condition()..key = Keys.id..value = row.id);

      await DbCenter.db.delete(DbCenter.tbChatMessageDraft, con);
    }
  }

  static Future deleteDraftMedias(List<ChatMediaModel> list) async {
    for (var row in list) {
      final con = Conditions();
      con.add(Condition()..key = Keys.id..value = row.id);

      await DbCenter.db.delete(DbCenter.tbMediaMessageDraft, con);
    }
  }

  static Future deleteDraftChats(List<ChatModel> list) async {
    for(var row in list) {
      final con = Conditions();
      con.add(Condition()..key = Keys.id..value = row.id);

      await DbCenter.db.delete(DbCenter.tbChatDraft, con);
    }
  }

  static Future deleteMedias(List<ChatMediaModel> list) async {
    for (var row in list) {
      final con = Conditions();
      con.add(Condition()..key = Keys.id..value = row.id);

      await DbCenter.db.delete(DbCenter.tbMediaMessage, con);
    }
  }

  static Future deleteMessage(ChatMessageModel msg, bool fromDb) async {
    _allChatMessageList.removeWhere((element) {
      return element.id == msg.id;
    });

    if (fromDb) {
      if (msg.isDraft) {
        // ignore: unawaited_futures
        deleteDraftMessages([msg]);
      }
      else {
        // ignore: unawaited_futures
        deleteMessages([msg]);
      }
    }

    if (msg.mediaId != null) {
      allMediaMessageList.removeWhere((element) {
        return element.id == msg.mediaId;
      });

      if (fromDb) {
        if (msg.isDraft) {
          // ignore: unawaited_futures
          deleteDraftMedias([getMediaById(msg.mediaId!)!]);
        }
        else {
          // ignore: unawaited_futures
          deleteMedias([getMediaById(msg.mediaId!)!]);
        }
      }
    }
  }

  static Future sinkChatMedia(List<ChatMediaModel> list) async {
    for (var row in list) {
      final con = Conditions();
      con.add(Condition()..key = Keys.id..value = row.id);

      if (row.isDraft) {
        await DbCenter.db.insertOrUpdate(DbCenter.tbMediaMessageDraft, row.toMap(), con);
      }
      else {
        await DbCenter.db.insertOrUpdate(DbCenter.tbMediaMessage, row.toMap(), con);
      }
    }
  }

  static void sendLastSeenToServer(int userId, int chatId, String ts) {
    final js = <String, dynamic>{};
    js[Keys.request] = 'UpdateLastSeenChat';
    js[Keys.userId] = userId;
    js['conversation_id'] = chatId;
    js['date_ts'] = ts;

    final r = Requester();
    r.bodyJson = js;
    r.requestPath = RequestPath.SetData;

    final failDb = <String, dynamic>{};
    failDb['key'] = '$userId-$chatId';
    failDb[Keys.userId] = userId;
    failDb['conversation_id'] = chatId;
    failDb['date_ts'] = ts;

    r.httpRequestEvents.onFailState = (req) async {
      // ignore: unawaited_futures
      saveFailLastSeen(failDb);
    };

    r.request();
  }

  static Future saveFailLastSeen(Map data) {
    final con = Conditions();
    con.add(Condition(ConditionType.DefinedNotNull)..key = 'FailLastChatSeen'..value = data['key']);

    return DbCenter.db.insertOrUpdate(DbCenter.tbKv, data, con);
  }

  static void sendFailLastSeen() {
    final con = Conditions();
    con.add(Condition(ConditionType.DefinedNotNull)..key = 'FailLastChatSeen');

    final cursor = DbCenter.db.query(DbCenter.tbKv, con);

    DbCenter.db.delete(DbCenter.tbKv, con);

    for (var m in cursor) {
      sendLastSeenToServer(m['user_id'], m['conversation_id'], m['date_ts']);
    }
  }

  static void sendFailMessages() {
    final userId = Session.getLastLoginUser()?.userId;

    if (userId == null) {
      return;
    }

    int orderBy(j1, j2) {
      final d1 = j1.value['user_send_ts'];
      final d2 = j2.value['user_send_ts'];

      return DateHelper.compareDatesTs(d1, d2);
    }

    // ..add(Condition()..key = 'sender_user_id'..value = userId)
    final cursor = DbCenter.db.query(DbCenter.tbChatMessageDraft, Conditions(), orderBy: orderBy);

    for (final m in cursor) {
      var tm = getMessageById(BigInt.parse(m['id']));
      tm ??= ChatMessageModel.fromMap(m);

      sendMessage(tm);
    }
  }

  static void sendMessage(ChatMessageModel tm) {
    if (tm.mediaId == null) {
      _sendTextMessage(tm);
    }
    else {
      _sendMediaMessage(tm);
    }
  }

  static void _sendTextMessage(ChatMessageModel tm) async {
    final js = <String, dynamic>{};
    js[Keys.request] = 'NewChatTextMessage';
    js[Keys.userId] = tm.senderUserId;
    js['message_data'] = tm.toMap();

    final man = managerFor(tm.senderUserId); // Session.getLastLoginUser()?.userId?? 0
    final draftChat = await man.fetchDraftChat(tm.chatId?? 0);

    if(draftChat != null){
      js['chat_data'] = draftChat.toMap();
    }

    final r = Requester();
    r.bodyJson = js;
    r.requestPath = RequestPath.SetData;

    r.httpRequestEvents.onResultOk = (req, data) async {
      final serverCMsg = ChatMessageModel.fromMap(data[Keys.mirror]);

      if(draftChat != null) {
        deleteDraftChats([draftChat]);
        draftChat.isDraft = false;
        draftChat.id = serverCMsg.chatId;

        man.sinkItems([draftChat]);
      }

      // ignore: unawaited_futures
      deleteDraftMessages([tm]);

      tm.matchBy(serverCMsg);
      tm.isDraft = false;
      // ignore: unawaited_futures
      sinkChatMessages([tm]);

      BroadcastCenter.chatMessageUpdateNotifier.value = tm;
    };

    r.httpRequestEvents.onFailState = (f) async {
      ChatManager.startSendFailedTimer();
    };

    r.request();
  }

  static void _sendMediaMessage(ChatMessageModel cm) async {
    var media = getMediaById(cm.mediaId!);

    if (media == null) {
      await fetchMediaMessageByIds([cm.mediaId!]);
      media = getMediaById(cm.mediaId!);

      if (media == null) {
        return;
      }
    }

    final tag = Keys.genDownloadTag_chatMedia(media);
    final current = DownloadUpload.uploadManager.getByTag(tag);

    if (current != null && current.isInProcess()) {
      return;
    }

    if (!await media.existMediaFile()) {
      media.isBroken = true;
      return;
    }

    final screenshotBytesExist = media.screenshotModel?.screenshotBytes != null;

    if (media.screenshotModel != null) { //tm.type == ChatType.VIDEO.typeNum
      if (!screenshotBytesExist && !await media.existScreenshotFile()) {
        //deleteDraftMedias([media]);
        //deleteDraftMessages([tm]);
        media.isBroken = true;
        return;
      }
    }

    final man = managerFor(cm.senderUserId);
    final draftChat = await man.fetchDraftChat(cm.chatId?? 0);

    //final fileName = PathHelper.getFileName(media.mediaPath!);
    final ext = media.extension;
    final fileName = Generator.generateDateMillWithKey(8) + '$ext';

    final js = <String, dynamic>{};
    js[Keys.request] = 'NewChatMediaMessage';
    js[Keys.userId] = cm.senderUserId;
    js['message_data'] = cm.toMap();
    js['media_data'] = media.toMap();
    js[Keys.fileName] = fileName;
    js[Keys.partName] = 'ChatMediaFile';

    String? screenShotFileName;

    if (media.screenshotModel != null) {
      screenShotFileName = PathHelper.getFileName(media.screenshotPath!);

      js['screenshot_file_name'] = screenShotFileName;
      js['screenshot_js'] = media.screenshotModel?.toMap();
    }

    if(draftChat != null){
      js['chat_data'] = draftChat.toMap();
    }

    AppManager.addAppInfo(js);

    final url = HttpCenter.baseUri + '/set-data';
    final holder = ChatDownloadUploadHolder();
    holder.ownerId = cm.senderUserId;
    holder.chatId = cm.chatId;
    holder.messageId = cm.id;
    holder.mediaId = cm.mediaId;
    holder.messageModel = cm;

    final up = DownloadUpload.uploadManager.createUploadItem(url, tag);
    up.category = DownloadCategory.chatMedia;
    up.subCategory = Keys.genCommonRefreshTag_chatMessage(cm);
    up.attach = holder;
    up.countOfRetry = 5;
    up.addField(JsonHelper.mapToJson(js), Keys.jsonHttpPart);
    up.addFile(media.mediaPath!, 'ChatMediaFile', fileName);

    if (screenshotBytesExist) {
      up.addBytes(media.screenshotModel!.screenshotBytes!.toList(), 'screenshot', screenShotFileName!);
    }
    else if (media.screenshotPath != null) {
      up.addFile(media.screenshotPath!, 'screenshot', screenShotFileName!);
    }

    DownloadUpload.uploadManager.enqueue(up);
  }

  Future<bool> requestUserTopChats() async {
    final js = <String, dynamic>{};
    js[Keys.request] = 'GetChatsForUser';
    js[Keys.userId] = userId;

    AppManager.addAppInfo(js);

    final http = HttpItem();
    http.setResponseIsPlain();
    http.pathSection = '/get-data';
    http.method = 'POST';
    http.setBody(JsonHelper.mapToJson(js));

    final httpRequester = HttpCenter.send(http);

    var f = httpRequester.responseFuture.catchError((e) {
      if (httpRequester.isDioCancelError) {
        return httpRequester.emptyError;
      }
    });


    f = f.then((val) async {
      final Map js = httpRequester.getBodyAsJson() ?? {};
      final result = js[Keys.result] ?? Keys.error;

      if (httpRequester.isOk && result == Keys.ok) {
        List? chatMap = js['chat_list'];
        List? messageMap = js['message_list'];
        List? mediaMap = js['media_list'];
        List? userMap = js['user_list'];
        List<int>? allIdsMap = Converter.correctList<int>(js['all_chat_ids']);
        final domain = js[Keys.domain];

        final uList = UserAdvancedManager.addItemsFromMap(userMap, domain: domain);
        UserAdvancedManager.sinkItems(uList);

        final mList = ChatManager.addMediaMessagesFromMap(mediaMap);
        final m2List = ChatManager.addMessagesFromMap(messageMap);
        final tList1 = addItemsFromMap(chatMap);

        if (allIdsMap != null) {
          removeNotMatchByServer(allIdsMap);
        }

        sortList(false);

        ChatManager.sinkChatMedia(mList);
        ChatManager.sinkChatMessages(m2List);
        ChatManager.sinkChats(tList1);

        return true;
      }

      return false;
    });

    return f.then((value) => value ?? false);
  }

  static void sendOpenChat(int chatId) {
    final js = <String, dynamic>{};
    js[Keys.request] = 'OpenChat';
    js[Keys.forUserId] = Session.getLastLoginUser();
    js['chat_id'] = chatId;

    final requester = Requester();
    requester.requestPath = RequestPath.SetData;
    requester.bodyJson = js;

    requester.httpRequestEvents.onFailState = (req) async {
      DbCenter.addToList(Keys.mustOpenChat, chatId);
    };

    requester.httpRequestEvents.onResultOk = (req, data) async {
      DbCenter.removeFromList(Keys.mustOpenChat, chatId);
    };

    requester.request();
  }

  static void sendFailOpenChat() {
    final userId = Session.getLastLoginUser()?.userId;
    final idList = DbCenter.fetchAsList(Keys.mustOpenChat);

    if (userId == null || idList.isEmpty) {
      return;
    }

    for (final m in idList) {
      sendOpenChat(m);
    }
  }

  static void startSendFailedTimer() {
    if(_failSendCounter > 0 && _failSendCounter < 5) {
      return;
    }

    _failSendTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      _failSendCounter++;

      if (_failSendCounter > 4) {
        stopSendFailedTimer();
      }
      else {
        sendFailOpenChat();
        sendFailMessages();
      }
    });
  }

  static void stopSendFailedTimer() {
    _failSendTimer?.cancel();
    _failSendCounter = 0;
  }
}
