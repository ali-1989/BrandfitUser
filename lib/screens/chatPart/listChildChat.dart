import 'package:flutter/material.dart';

import 'package:badges/badges.dart';
import 'package:iris_tools/api/helpers/colorHelper.dart';
import 'package:iris_tools/modules/stateManagers/common_refresh.dart';

import '/abstracts/stateBase.dart';
import '/managers/fontManager.dart';
import '/models/dataModels/chatModels/chatModel.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/models/holderModels/chatAvatarHolder.dart';
import '/screens/chatPart/chatScreenPart/chatScreen.dart';
import '/system/downloadUpload.dart';
import '/system/extensions.dart';
import '/system/icons.dart';
import '/system/keys.dart';
import '/system/session.dart';
import '/tools/app/appNavigator.dart';
import '/tools/mediaTools.dart';

class ListChildChat extends StatefulWidget {
  final ChatModel chatModel;

  const ListChildChat({
    required this.chatModel,
    Key? key,
  }) : super(key: key);

  @override
  _ListChildChatState createState() => _ListChildChatState();
}
///==================================================================================
class _ListChildChatState extends StateBase<ListChildChat> {
  late ChatModel chat;
  late UserModel user;

  @override
  void initState() {
    super.initState();

    chat = widget.chatModel;
    user = Session.getLastLoginUser()!;
  }

  @override
  Widget build(BuildContext context) {
    final unReadCount = chat.unReadCount();
    prepareAvatar();

    return GestureDetector(
      onTap: (){
        AppNavigator.pushNextPage(
            context,
            ChatScreen(chat: chat,),
            name: ChatScreen.screenName
        );
      },
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CommonRefresh(
                    tag: Keys.genCommonRefreshTag_chatAvatar(chat),
                    builder: (ctx, data){
                      if(data == null){
                        return CircleAvatar(
                          backgroundColor: ColorHelper.textToColor('chat${chat.id}'),
                          child: Text(chat.addressee(user.userId)?.userName.substring(0, 2)?? '',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        );
                      }

                      return CircleAvatar(
                        backgroundColor: ColorHelper.textToColor('chat${chat.id}'),
                        backgroundImage: chat.getAddresseeAvatarProvider(user.userId),
                      );
                    },
                  ),

                  SizedBox(height: 4,),

                  if(chat.isClose)
                    Icon(IconList.lock, size: 16,).alpha(),
                ],
              ),

              SizedBox(width: 10,),

              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(chat.addressee(user.userId)?.userName?? '-',
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                          ).bold(),
                        ),

                        Text(chat.getLastMessageDate()).subAlpha(),
                      ],
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Builder(
                          builder: (ctx){
                            if(chat.lastMessage != null && !chat.lastMessage!.senderIsAddressee(chat)){
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(chat.lastMessage?.getStateIcon(),
                                    size:12,
                                    color: chat.lastMessage?.getStateColor(),
                                  ),

                                  SizedBox(width: 8,),
                                ],
                              );
                            }

                            return SizedBox();
                          },
                        ),

                        Expanded(
                          child: Text(getChatMessage(),
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                          ).boldFont().subAlpha(),
                        ),

                        Badge(
                          showBadge: unReadCount > 0,
                          padding: EdgeInsets.all(10),
                          elevation: 0,
                          badgeContent: Text('$unReadCount',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              fontFamily: FontManager.instance.getEnglishFont()?.family
                            ),
                          ),
                          badgeColor: Colors.green,
                          alignment: Alignment.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose(){
    super.dispose();
  }

  String getChatMessage(){
    if(chat.lastMessage == null){
      return '';
    }

    if(chat.lastMessage!.type == 1) {
      return chat.lastMessage?.text ?? '';
    }

    final type = chat.getChatMessageType(chat.lastMessage);
    return context.tInMap('chatData', type)!;
  }

  void prepareAvatar() async {
    final path = chat.getAddresseeAvatarPath(user.userId);

    /// means not exist uri
    if(path == null){
      return;
    }

    final tag = Keys.genCommonRefreshTag_chatAvatar(chat);
    final isDownloading = DownloadUpload.downloadManager.getByTag(tag);

    if(isDownloading == null) {
      final holder = ChatAvatarHolder();
      holder.userId = user.userId;
      holder.chatId = chat.id;
      holder.userModel = chat.addressee(user.userId);
      holder.addresseeId = holder.userModel?.userId;
      holder.chatModel = chat;

      final di = DownloadUpload.downloadManager.createDownloadItem(chat.getAddresseeAvatarUri(user.userId)!, tag: tag, savePath: path);
      di.category = DownloadCategory.chatAvatar;
      di.attach = holder;

      await DownloadUpload.downloadManager.enqueue(di);
    }
    else {
      if(isDownloading.canReset()){
        await DownloadUpload.downloadManager.enqueue(isDownloading);
      }

      if(chat.addressee(user.userId)?.profilePath != null){
        return;
      }

      if(await MediaTools.isImage(path)){
        chat.addressee(user.userId)?.profilePath = path;
        update();
      }
    }
  }
}
