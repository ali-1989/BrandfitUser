import 'package:iris_tools/api/converter.dart';
import 'package:iris_tools/api/generator.dart';

import '/models/dataModels/counterModels/mealModel.dart';
import '/system/keys.dart';

class CaloriesCounterDayModel {
  late int id;
  String? date;
  int userId = 0;
  List<MealModel> meals = [];
  //-------------------------- local

  CaloriesCounterDayModel() : id = Generator.generateIntId(10);

  CaloriesCounterDayModel.fromMap(Map map){
    final List<Map> mealsMap = Converter.correctList(map['meals'])?? [];

    id = map[Keys.id]?? Generator.generateIntId(10);
    date = map['date'];
    userId = map['user_id']?? 0;
    meals = mealsMap.map((e) => MealModel.fromMap(e)).toList();
  }

  Map<String, dynamic> toMap(){
    final map = <String, dynamic>{};
    map[Keys.id] = id;
    map['date'] = date;
    map['user_id'] = userId;
    map['meals'] = meals.map((e) => e.toMap()).toList(growable: false);

    return map;
  }

  void matchBy(CaloriesCounterDayModel other){
    id = other.id;
    date = other.date;
    userId = other.userId;
    meals = other.meals;
  }

  void sortMeals(){
    meals.sort((MealModel o1, MealModel o2){
      if(o1.ordering == o2.ordering){
        return 0;
      }

      if(o1.ordering > o2.ordering){
        return 1;
      }

      return -1;
    });
  }

  int getMaxMealsNumber(){
    var r = 0;

    for(final m in meals){
      if(m.ordering > r){
        r = m.ordering;
      }
    }

    return r;
  }
}
