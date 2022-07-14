import '/models/dataModels/chartModels/chartDataModel.dart';
import '/models/dataModels/usersModels/fitnessDataModel.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/system/session.dart';

class UserChartManager {
  static final Map<int, UserChartManager> _holderLink = {};

  late int userId;
  DateTime? lastUpdateTime;

  static UserChartManager managerFor(int userId){
    if(_holderLink.keys.contains(userId)){
      return _holderLink[userId]!;
    }

    return _holderLink[userId] = UserChartManager._(userId);
  }

  static void removeManager(int userId){
    _holderLink.removeWhere((key, value) => key == userId);
  }

  bool isUpdated({Duration duration = const Duration(minutes: 10)}){
    var now = DateTime.now();
    now = now.subtract(duration);

    return lastUpdateTime != null && lastUpdateTime!.isAfter(now);
  }

  void setUpdate(){
    lastUpdateTime = DateTime.now();
  }
  ///-----------------------------------------------------------------------------------------
  UserChartManager._(this.userId);
  ///-----------------------------------------------------------------------------------------
  bool get canShowChart {
    final user = Session.getExistLoginUserById(userId);

    return user?.fitnessDataModel.height != null && user?.fitnessDataModel.weight != null;
  }

  bool canShowChartFor(UserModel user) {
    return user.fitnessDataModel.height != null && user.fitnessDataModel.weight != null;
  }

  ChartDataModel chartDataFor(NodeNames nodeName, {UserModel? user}){
    user ??= Session.getExistLoginUserById(userId);
    final list = user?.fitnessDataModel.getNodes(nodeName);

    if(list != null) {
      return ChartDataModel.of(nodeName, list);
    }

    return ChartDataModel(nodeName);
  }
}
