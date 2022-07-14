import 'package:flutter/material.dart';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '/abstracts/stateBase.dart';
import '/managers/settingsManager.dart';

class AboutUsScreen extends StatefulWidget {
  static const screenName = 'AboutUsScreen';

  AboutUsScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return AboutUsScreenState();
  }
}
///=====================================================================================
class AboutUsScreenState extends StateBase<AboutUsScreen> {
  late InAppWebViewGroupOptions webViewGroupOptions;
  InAppWebViewController? webViewController;

  @override
  void initState() {
    super.initState();

    webViewGroupOptions = InAppWebViewGroupOptions(
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
        clearSessionCache: true,
        overScrollMode: AndroidOverScrollMode.OVER_SCROLL_NEVER,
        minimumLogicalFontSize: 20,
        databaseEnabled: true,
        domStorageEnabled: true,
        allowContentAccess: true,
        allowFileAccess: true,
        loadsImagesAutomatically: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ),
        crossPlatform: InAppWebViewOptions(
          allowFileAccessFromFileURLs: true,
          allowUniversalAccessFromFileURLs: true,
          cacheEnabled: false,
          clearCache: true,
          disableHorizontalScroll: false,
          horizontalScrollBarEnabled: true,
          disableVerticalScroll: false,
          verticalScrollBarEnabled: true,
          useOnLoadResource: true,
          supportZoom: true,
          minimumFontSize: 22,
          transparentBackground: true,
          javaScriptEnabled: true,
          javaScriptCanOpenWindowsAutomatically: false,
          mediaPlaybackRequiresUserGesture: true,
        )
    );

    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
    });
  }

  @override
  Widget build(BuildContext context) {
    rotateToPortrait();

    return getScaffold();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget getScaffold() {
    return WillPopScope(
      onWillPop: () => onWillBack(this),
      child: Scaffold(
        key: scaffoldKey,
        appBar: getAppbar(),
        body: getScaffoldBody(),
      ),
    );
  }

  PreferredSizeWidget getAppbar() {
    return AppBar(
      title: Text(tC('aboutUs')!),
    );
  }

  Widget getScaffoldBody() {
    return SizedBox.expand(

      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: InAppWebView(
              initialOptions: webViewGroupOptions,
              initialData: InAppWebViewInitialData(
                encoding: 'utf8',
                data: getContent(),
              ),
              onWebViewCreated: (InAppWebViewController controller) {
                webViewController = controller;
              },
              onLoadStart: (InAppWebViewController controller, Uri? url) {},
              onLoadStop: (InAppWebViewController controller, Uri? url) {},
            ),
          ),
        ],
      ),
    );
  }
  ///========================================================================================================
  String getContent(){
    final lCode = SettingsManager.settingsModel.appLocale.languageCode;

    var res = contents[lCode];

    res ??= contents['en'];

    return res!;
  }
  
  Map<String, String> contents = {
    'en': '''<html lang="en">
      <head>
          <title></title>
          <meta charset="UTF-8" />
          <style type="text/css">
              html, body {
              max-width: 100%;
              overflow-x: hidden;
              }
      
              .title {
                font-size: 50px;
                color: rgb(10, 20, 200);
                text-align: center;
              }
              .text{
                  font-size:35px;
                  padding: 0 5%;
                  text-align: justify;
                  text-justify: inter-word;
              }
      
              .fadeIn div {
                animation: fadeIn 3s cubic-bezier(0, 0, 1, 1) backwards, move 1s forwards;
                -webkit-animation: fadeIn 3s cubic-bezier(0, 0, 1, 1) backwards, move 1s forwards;
              }
      
              @keyframes fadeIn {
                0% {opacity:0;}
                100% {opacity:1;}
              }
      
              @-webkit-keyframes fadeIn {
                from {opacity:0;}
                to {opacity:1;}
              }
      
              @keyframes move {
                  from { transform : translate(0, 70px); }
                  to   { transform : translate(0, 0); }
              }
      
              @-webkit-keyframes move {
                from {-webkit-transform: translate(0, 70px);}
                to {-webkit-transform: translate(0, 0);}
              }
      
          </style>
      </head>
      <body>
      <div dir="rtl" class="fadeIn">
          <div class="title" style="font-weight: bold"><span>برندفیت </span></div>
          <p>&nbsp;</p>
          <p>&nbsp;</p>
      
          <div class="text"><span>تیم برندفیت در زمینه<strong> تناسب اندام</strong>، <strong>تغذیه</strong> و <strong>سلامتی</strong> فعالیت دارد.</span></div>
          <div class="text"><span>این تیم متشکل از مربیان و مشاورین مجرب همواره تلاش دارد که به جامعه و افراد کمک کند تا بهترین خود باشند.</span></div>
          <p>&nbsp;</p>
      
          <div class="text"><span>آکادمی تخصصی برندفیت واقع در استان اصفهان شهر ابریشم می باشد و پذیرای علاقه مندان در دوره های حضوری است.</span></div>
          <p>&nbsp;</p>
          <div class="text"><span>اما برای برندفیتی شدن نیازی نیست که حتما در دوره های حضوری شرکت نمایید ، شما هم همچون اشخاص زیادی میتوانید در دوره های <strong>رژیم غذایی</strong>، <strong>برنامه تمرینی</strong> به صورت مجازی و آنلاین شرکت نمایید و به خانواده بزرگ برندفیت بپیوندید.</span></div>
          <p>&nbsp;</p>
          <div class="text"><span>برای آشنایی بیشتر با برندفیت و دوره های آن و همچنین مشاهده ی نتایج افرادی که تاکنون با ما به هدفشان دست یافته اند به پیج اینستاگرام ما به آدرس <a href="https://www.instagram.com/brandfit.ir/" rel="noopener noreferrer">brandfit.ir@</a> مراجعه نمایید.</span></div>
      </div>
      <script>
          var x = document.querySelectorAll(".fadeIn div");
          for(var i = 0; i < x.length; i++){
             x[i].style.animationDelay = (i*0.5)+"s";
             x[i].style.webkitAnimationDelay = (i*0.5)+"s";
          }
      </script>
      </body>
  </html>''',

    'fa': '''<html>
      <head>
          <title></title>
          <meta charset="UTF-8" />
          <style type="text/css">
              html, body {
              max-width: 100%;
              overflow-x: hidden;
              }
      
              .title {
                font-size: 50px;
                color: rgb(10, 20, 200);
                text-align: center;
              }
              .text{
                  font-size:35px;
                  padding: 0 5%;
                  text-align: justify;
                  text-justify: inter-word;
              }
      
              .fadeIn div {
                animation: fadeIn 3s cubic-bezier(0, 0, 1, 1) backwards, move 1s forwards;
                -webkit-animation: fadeIn 3s cubic-bezier(0, 0, 1, 1) backwards, move 1s forwards;
              }
      
              @keyframes fadeIn {
                0% {opacity:0;}
                100% {opacity:1;}
              }
      
              @-webkit-keyframes fadeIn {
                from {opacity:0;}
                to {opacity:1;}
              }
      
              @keyframes move {
                  from { transform : translate(0, 70px); }
                  to   { transform : translate(0, 0); }
              }
      
              @-webkit-keyframes move {
                from {-webkit-transform: translate(0, 70px);}
                to {-webkit-transform: translate(0, 0);}
              }
      
          </style>
      </head>
      <body>
      <div dir="rtl" class="fadeIn">
          <div class="title" style="font-weight: bold"><span>برندفیت </span></div>
          <p>&nbsp;</p>
          <p>&nbsp;</p>
      
          <div class="text"><span>تیم برندفیت در زمینه<strong> تناسب اندام</strong>، <strong>تغذیه</strong> و <strong>سلامتی</strong> فعالیت دارد.</span></div>
          <div class="text"><span>این تیم متشکل از مربیان و مشاورین مجرب همواره تلاش دارد که به جامعه و افراد کمک کند تا بهترین خود باشند.</span></div>
          <p>&nbsp;</p>
      
          <div class="text"><span>آکادمی تخصصی برندفیت واقع در استان اصفهان شهر ابریشم می باشد و پذیرای علاقه مندان در دوره های حضوری است.</span></div>
          <p>&nbsp;</p>
          <div class="text"><span>اما برای برندفیتی شدن نیازی نیست که حتما در دوره های حضوری شرکت نمایید ، شما هم همچون اشخاص زیادی میتوانید در دوره های <strong>رژیم غذایی</strong>، <strong>برنامه تمرینی</strong> به صورت مجازی و آنلاین شرکت نمایید و به خانواده بزرگ برندفیت بپیوندید.</span></div>
          <p>&nbsp;</p>
          <div class="text"><span>برای آشنایی بیشتر با برندفیت و دوره های آن و همچنین مشاهده ی نتایج افرادی که تاکنون با ما به هدفشان دست یافته اند به پیج اینستاگرام ما به آدرس <a href="https://www.instagram.com/brandfit.ir/" rel="noopener noreferrer">brandfit.ir@</a> مراجعه نمایید.</span></div>
      </div>
      <script>
          var x = document.querySelectorAll(".fadeIn div");
          for(var i = 0; i < x.length; i++){
             x[i].style.animationDelay = (i*0.5)+"s";
             x[i].style.webkitAnimationDelay = (i*0.5)+"s";
          }
      </script>
      </body>
  </html>'''
  };
}

