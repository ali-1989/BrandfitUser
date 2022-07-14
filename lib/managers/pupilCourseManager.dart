import '/models/dataModels/courseModels/pupilCourseModel.dart';

class PupilCourseManager {
  static final Map<int, PupilCourseManager> _holderLink = {};

  final List<PupilCourseModel> _list = [];
  final List<int> _myRequestedList = [];
  late int userId;
  DateTime? lastUpdateTime;

  static PupilCourseManager managerFor(int userId) {
    if (_holderLink.keys.contains(userId)) {
      return _holderLink[userId]!;
    }

    return _holderLink[userId] = PupilCourseManager._(userId);
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
  PupilCourseManager._(this.userId);

  List<PupilCourseModel> get courseList => _list;
  List<PupilCourseModel> get courseShopList => _list.where((element) => !_myRequestedList.contains(element.id)).toList();
  List<PupilCourseModel> get myRequestedList => _list.where((element) => _myRequestedList.contains(element.id)).toList();

  PupilCourseModel? getById(int id){
    try{
      return _list.firstWhere((element) => element.id == id);
    }
    catch(e){
      return null;
    }
  }

  PupilCourseModel? getShopById(int id){
    try{
      return courseShopList.firstWhere((element) => element.id == id);
    }
    catch(e){
      return null;
    }
  }

  PupilCourseModel? getMyRequestedById(int id){
    try{
      return myRequestedList.firstWhere((element) => element.id == id);
    }
    catch(e){
      return null;
    }
  }

  bool addItem(PupilCourseModel cm){
    final find = getById(cm.id);

    if(find == null) {
      _list.add(cm);
      return true;
    }
    else {
      find.matchBy(cm);
      return false;
    }
  }

  void addRequestedId(int id){
    _myRequestedList.add(id);
  }

  Future removeItem(int id, bool fromDb) async {
    _list.removeWhere((element) => element.id == id);

    /*if(fromDb){
      PupilCourseModel.deleteRecords([id]);
    }*/
  }

  void sortList(bool asc) async {
    _list.sort((PupilCourseModel p1, PupilCourseModel p2){
      final d1 = p1.creationDate;
      final d2 = p2.creationDate;

      if(d1 == null){
        return asc? 1: 1;
      }

      if(d2 == null){
        return asc? 1: 1;
      }

      return asc? d1.compareTo(d2) : d2.compareTo(d1);
    });
  }

  bool isRequestedByMe(int userId, int cId) {
    return PupilCourseManager.managerFor(userId)._myRequestedList.contains(cId);
  }
}