import 'package:flutter/material.dart';

import 'package:photo_view/photo_view.dart';

import '/system/enums.dart';

/// Usage:
/// final view = ImageFullScreen(heroTag: '');
/// AppNavigator.pushNextPageExtra(context, view, name: ImageFullScreen.screenName);

///===============================================================================================================
class ImageFullScreen extends StatefulWidget {
  static const screenName = 'ImageFullScreen';
  late final ImageType imageType;
  late final dynamic imageObj;
  late final String heroTag;
  final String? info;
  final TextStyle? infoStyle;

  ImageFullScreen({
    Key? key,
    required this.imageType,
    required this.imageObj,
    required this.heroTag,
    this.info,
    this.infoStyle,
  })
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ImageFullScreenState();
  }
}
///===============================================================================================================
class ImageFullScreenState extends State<ImageFullScreen> {
  ImageProvider? pic;
  TextStyle? infoStyle;

  @override
  void initState() {
    super.initState();

    infoStyle = widget.infoStyle?? const TextStyle(color: Colors.white);

    switch(widget.imageType){
      case ImageType.File:
        pic = FileImage(
          widget.imageObj,
        );
        break;
      case ImageType.Bytes:
        pic = MemoryImage(
          widget.imageObj,
        );
        break;
      case ImageType.Asset:
        pic = AssetImage(
          widget.imageObj,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    //Widget pic;
    /*
    ImageType.File:
        pic = Image.file(
          widget.imageObj,
          fit: BoxFit.fill,
          filterQuality: FilterQuality.high,
        );
     */

    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(),
      body: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: PhotoView(
                imageProvider: pic,
                basePosition: Alignment.center,
                disableGestures: false,
                enableRotation: true,
                gaplessPlayback: true,
                maxScale: 3.0,
                gestureDetectorBehavior: HitTestBehavior.translucent,
                //initialScale: 1.0,
                heroAttributes: PhotoViewHeroAttributes(tag: widget.heroTag,),
              ),
            ),


            Positioned(
                bottom: 0, left: 0, right: 0,
                child: Builder(
                  builder: (ctx){
                    if(widget.info == null){
                      return SizedBox();
                    }

                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(70), //AppThemes.currentTheme.inactiveTextColor.withAlpha(200),
                        //borderRadius: BorderRadius.circular(8.0)
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 15.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              overflow: TextOverflow.fade,
                              maxLines: 6,
                              text: TextSpan(
                                text: widget.info,
                                style: infoStyle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ),
          ]
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  void update(){
    if(mounted){
      setState(() {});
    }
  }
}
