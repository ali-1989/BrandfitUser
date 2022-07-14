import 'package:flutter/material.dart';

import 'package:badges/badges.dart';

import '/abstracts/stateBase.dart';
import '/managers/fontManager.dart';
import '/models/dataModels/ticketModels/ticketModel.dart';
import '/screens/supportPart/chatPart/ticketChatScreen.dart';
import '/system/downloadUpload.dart';
import '/system/extensions.dart';
import '/system/icons.dart';
import '/system/keys.dart';
import '/system/session.dart';
import '/tools/app/appNavigator.dart';
import '/tools/mediaTools.dart';

class ListChildTicket extends StatefulWidget {
  final TicketModel ticketModel;

  const ListChildTicket({
    required this.ticketModel,
    Key? key,
  }) : super(key: key);

  @override
  _ListChildTicketState createState() => _ListChildTicketState();
}
///==================================================================================
class _ListChildTicketState extends StateBase<ListChildTicket> {
  late TicketModel ticket;

  @override
  void initState() {
    super.initState();

    ticket = widget.ticketModel;
  }

  @override
  Widget build(BuildContext context) {
    final unReadCount = ticket.unReadCount();
    //prepareAvatar();

    return GestureDetector(
      onTap: (){
        AppNavigator.pushNextPage(
            context,
            TicketChatScreen(ticket: ticket,),
            name: TicketChatScreen.screenName
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
                  SizedBox(height: 4,),

                  if(ticket.isClose)
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
                          child: Text('${ticket.title}',
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                          ).bold(),
                        ),

                        Text(ticket.genLastDate()).subAlpha(),
                      ],
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Builder(
                          builder: (ctx){
                            if(ticket.lastMessage != null && ticket.lastMessage!.senderIsUser(ticket)){
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(ticket.lastMessage?.getStateIcon(),
                                    size:12,
                                    color: ticket.lastMessage?.getStateColor(),
                                  ),

                                  SizedBox(width: 8,),
                                ],
                              );
                            }

                            return SizedBox();
                          },
                        ),

                        Expanded(
                          child: Text(getTicketMessage(),
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

  String getTicketMessage(){
    if(ticket.lastMessage == null){
      return '';
    }

    if(ticket.lastMessage!.type == 1) {
      return ticket.lastMessage?.text ?? '';
    }

    final type = ticket.getTicketMessageType(ticket.lastMessage);
    return context.tInMap('chatData', type)!;
  }

  void prepareAvatar() async {
    final path = ticket.getAvatarPath();

    /// means not exist uri
    if(path == null){
      return;
    }

    final tag = Keys.genCommonRefreshTag_ticketAvatar(ticket);
    final isDownloading = DownloadUpload.downloadManager.getByTag(tag);

    if(isDownloading == null) {
      final di = DownloadUpload.downloadManager.createDownloadItem(ticket.getAvatarUri()!, tag: tag, savePath: path);
      di.category = DownloadCategory.ticketAvatar;
      di.subCategory = '${ticket.id}';
      di.attach = Session.getLastLoginUser()?.userId;

      await DownloadUpload.downloadManager.enqueue(di);
    }
    else {
      if(isDownloading.canReset()){
        await DownloadUpload.downloadManager.enqueue(isDownloading);
      }

      if(ticket.starterUser()?.profilePath != null){
        return;
      }

      if(await MediaTools.isImage(path)){
        ticket.starterUser()?.profilePath = path;
        update();
      }
    }
  }
}
