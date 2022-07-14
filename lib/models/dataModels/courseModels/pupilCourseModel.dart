import 'package:flutter/material.dart';

import 'package:iris_tools/api/generator.dart';
import 'package:iris_tools/api/helpers/fileHelper.dart';
import 'package:iris_tools/dateSection/dateHelper.dart';

import '/models/dataModels/countryModel.dart';
import '/system/enums.dart';
import '/system/extensions.dart';
import '/system/keys.dart';
import '/tools/app/appThemes.dart';
import '/tools/centers/directoriesCenter.dart';
import '/tools/uriTools.dart';

class PupilCourseModel {
  int id = 0;
  int requestId = 0;
  int creatorUserId = 0;
  late String title;
  late String description;
  late String price;
  late CurrencyModel currencyModel;
  bool hasFoodProgram = false;
  bool hasExerciseProgram = false;
  int durationDay = 0;
  DateTime? creationDate;
  DateTime? supportExpireDate;
  String? imageUri;
  Map answerJs = {};
  bool isSendProgram = false;

  PupilCourseModel(){
    id = Generator.generateIntId(16);
  }

  PupilCourseModel.fromMap(Map js, {String? domain}){
    id = js[Keys.id];
    requestId = js['request_id'];
    creatorUserId = js['creator_user_id'];
    title = js[Keys.title];
    description = js[Keys.description];
    price = js['price'];
    currencyModel = CurrencyModel.fromMap(js['currency_js']);
    durationDay = js['duration_day']?? 29;
    creationDate = DateHelper.tsToSystemDate(js['creation_date']);
    supportExpireDate = DateHelper.tsToSystemDate(js['support_expire_date']);
    hasFoodProgram = js['has_food_program']?? false;
    hasExerciseProgram = js['has_exercise_program']?? false;
    imageUri = js['image_uri'];
    isSendProgram = js['is_send_program']?? false;
    answerJs = js['answer_js']?? {};

    imageUri = UriTools.correctAppUrl(imageUri, domain: domain);
  }

  Map<String, dynamic> toMap(){
    final map = <String, dynamic>{};

    map[Keys.id] = id;
    map['request_id'] = requestId;
    map['creator_user_id'] = creatorUserId;
    map[Keys.title] = title;
    map[Keys.description] = description;
    map['price'] = price;
    map['currency_js'] = currencyModel.toMap();
    map['has_food_program'] = hasFoodProgram;
    map['has_exercise_program'] = hasExerciseProgram;
    map['duration_day'] = durationDay;
    map['creation_date'] = DateHelper.toTimestampNullable(creationDate);
    map[Keys.imageUri] = imageUri;
    map['answer_js'] = answerJs;
    map['is_send_program'] = isSendProgram;
    map['support_expire_date'] = supportExpireDate;

    return map;
  }

  void matchBy(PupilCourseModel other){
    id = other.id;
    requestId = other.requestId;
    creatorUserId = other.creatorUserId;
    title = other.title;
    description = other.description;
    price = other.price;
    currencyModel = other.currencyModel;
    hasFoodProgram = other.hasFoodProgram;
    hasExerciseProgram = other.hasExerciseProgram;
    durationDay = other.durationDay;
    answerJs = other.answerJs;
    creationDate = other.creationDate;
    imageUri = other.imageUri;
    isSendProgram = other.isSendProgram;
  }

  bool get isAccept => answerJs.containsKey('accept');

  bool get isReject => answerJs.containsKey('reject');

  bool get hasImage => imageUri != null || FileHelper.existSync(imagePath!);

  String? get imagePath => DirectoriesCenter.getSavePathUri(imageUri?? 'c$id.jpg', SavePathType.COURSE_PHOTO);

  String? getRejectCause(BuildContext ctx){
    if(isReject && answerJs.containsKey('cause')){
      return answerJs['cause'];
    }

    return null;
  }

  String getStatusText(BuildContext ctx){
    if(isAccept){
      return ctx.t('accepted')!;
    }
    else if(isReject){
      return ctx.t('rejected')!;
    }

    return ctx.t('pending')!;
  }

  Color getStatusColor(){
    if(isAccept){
      return AppThemes.currentTheme.successColor;
    }
    else if(isReject){
      return AppThemes.currentTheme.errorColor;
    }

    return AppThemes.currentTheme.textColor;
  }
}
