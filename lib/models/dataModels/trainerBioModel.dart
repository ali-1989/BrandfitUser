import 'package:brandfit_user/models/dataModels/usersModels/userModel.dart';
import 'package:brandfit_user/system/keys.dart';
import 'package:brandfit_user/tools/uriTools.dart';

class TrainerBioModel extends UserModel {
  String biography = '';
  List bioImages = <String>[];
  int courseCount = 0;

  TrainerBioModel();

  TrainerBioModel.fromMap(Map<String, dynamic> map, {String? domain}): super.fromMap(map, domain: domain) {
    biography = map['bio'];
    courseCount = map['course_count']?? 0;

    profileUri = map[Keys.imageUri];
    profileUri = UriTools.correctAppUrl(profileUri, domain: domain);

    final temp = map['bio_images']?? [];
    final correctList = <String>[];

    for(final f in temp){
      correctList.add(UriTools.correctAppUrl(f, domain: domain)!);
    }

    bioImages.addAll(correctList);
  }

  @override
  void matchBy(UserModel other, {String? domain}) {
    super.matchBy(other);

    if(other is TrainerBioModel) {
      biography = other.biography;
      bioImages = other.bioImages;
      courseCount = other.courseCount;
    }
  }

  @override
  Map<String, dynamic> toMap(){
    final map = super.toMap();

    map['bio'] = biography;
    map['course_count'] = courseCount;
    map['bio_images'] = bioImages;

    return map;//JsonHelper.removeNullsByKey<String, dynamic>(map, notNullKeys)!;
  }
}