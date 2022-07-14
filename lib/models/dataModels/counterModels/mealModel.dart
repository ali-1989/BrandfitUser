import 'package:iris_tools/api/converter.dart';
import 'package:iris_tools/api/generator.dart';
import 'package:iris_tools/api/helpers/localeHelper.dart';
import 'package:iris_tools/api/helpers/mathHelper.dart';

import '/models/dataModels/foodModels/materialWithValueModel.dart';
import '/system/keys.dart';

class MealModel {
  late int id;
  int ordering = 1;
  String? mealName;
  List<MaterialWithValueModel> materials = [];

  MealModel() : id = Generator.generateIntId(10);

  MealModel.fromMap(Map map){
    final List<Map> mat = Converter.correctList(map['materials'])?? [];

    id = map[Keys.id]?? Generator.generateIntId(10);
    mealName = map[Keys.name];
    ordering = map['ordering']?? 1;
    materials = mat.map((e) => MaterialWithValueModel.fromMap(e)).toList();
  }

  Map<String, dynamic> toMap(){
    final map = <String, dynamic>{};
    map[Keys.id] = id;
    map[Keys.name] = mealName;
    map['ordering'] = ordering;
    map['materials'] = materials.map((e) => e.toMap()).toList(growable: false);
    map['calories'] = sumCalories();

    return map;
  }

  void addMaterial(MaterialWithValueModel food){
    materials.add(food);
  }

  void removeMaterial(MaterialWithValueModel food){
    materials.remove(food);
  }

  List<MaterialWithValueModel> getProgramMaterials(){
    return materials;
  }

  int getMaterialCount(){
    return materials.length;
  }

  double sumCalories(){
    var res = 0.0;
    var find = false;

    for(final pm in materials){
      if(pm.material == null){
        continue;
      }

      find = false;
      final unitVal = MathHelper.clearToInt(pm.material!.measure.unitValue);

      for(var j in pm.material!.mainFundamentals){
        if(j.key == 'calories'){
          final val = MathHelper.clearToInt(j.value);
          res += pm.materialValue * val / unitVal;
          find = true;
          break;
        }
      }

      if(!find) {
        for (var j in pm.material!.otherFundamentals) {
          if (j.key == 'calories') {
            final val = MathHelper.clearToInt(j.value);
            res += pm.materialValue * val / unitVal;
            break;
          }
        }
      }
    }

    return res;
  }

  double sumProtein(){
    var res = 0.0;

    for(final pm in materials){
      if(pm.material == null){
        continue;
      }
      final unitVal = MathHelper.clearToInt(pm.material!.measure.unitValue);

      for(var j in pm.material!.fundamentals){
        if(j.key == 'protein'){
          final val = MathHelper.clearToInt(j.value);
          res += pm.materialValue * val / unitVal;
        }
      }
    }

    return res;
  }

  double sumFat(){
    var res = 0.0;

    for(final pm in materials){
      if(pm.material == null){
        continue;
      }

      final unitVal = MathHelper.clearToInt(pm.material!.measure.unitValue);

      for(var j in pm.material!.fundamentals){
        if(j.key == 'fat'){
          final val = MathHelper.clearToInt(j.value);
          res += pm.materialValue * val / unitVal;
        }
      }
    }

    return res;
  }

  double sumCarbohydrate(){
    var res = 0.0;

    for(final pm in materials){
      if(pm.material == null){
        continue;
      }

      final unitVal = MathHelper.clearToInt(pm.material!.measure.unitValue);

      for(var j in pm.material!.fundamentals){
        if(j.key == 'carbohydrate'){
          final val = MathHelper.clearToInt(j.value);
          res += pm.materialValue * val / unitVal;
        }
      }
    }

    return res;
  }

  int currentCaloriesPercent(int? max){
    if(max == null){
      return 0;
    }

    final res = sumCalories();
    return (res * 100 / max).round();
  }

  double caloriesPercentChart(int? max){
    var p = currentCaloriesPercent(max);

    if(p > 100) {
      p = 100;
    }

    return p / 100;
  }

  String getCaloriesChartText(int? max){
    if(max == null){
      return '${sumCalories()}';
    }

    return LocaleHelper.embedLtr('${sumCalories()}  -  (${currentCaloriesPercent(max)} %)');
  }
}
