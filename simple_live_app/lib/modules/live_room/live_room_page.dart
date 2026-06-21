import 'dart:io';

import 'package:floating/floating.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/constant.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/modules/live_room/live_room_controller.dart';
import 'package:simple_live_app/modules/live_room/player/player_controls.dart';
import 'package:simple_live_app/services/follow_service.dart';
import 'package:simple_live_app/widgets/desktop_refresh_button.dart';
import 'package:simple_live_app/widgets/follow_user_item.dart';
import 'package:simple_live_app/widgets/keep_alive_wrapper.dart';
import 'package:simple_live_app/widgets/net_image.dart';
import 'package:simple_live_app/widgets/settings/settings_action.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';
import 'package:simple_live_app/widgets/settings/settings_number.dart';
import 'package:simple_live_app/widgets/settings/settings_switch.dart';
import 'package:simple_live_app/widgets/superchat_card.dart';
import 'package:simple_live_core/simple_live_core.dart';

class LiveRoomPage extends GetView<LiveRoomController> {
  const LiveRoomPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final full = controller.fullScreenState.value;

      return Scaffold(
        extendBody: true,
        appBar: full
            ? null
            : AppBar(
                title: Obx(
                  () => Text(controller.detail.value?.title ?? "直播间"),
                ),
                actions: buildAppbarActions(context),
              ),
        body: SafeArea(
          top: false,
          bottom: !full,
          child: Stack(
            children: [
              _buildPlayer(),

              if (!full) _buildNormalUI(),
            ],
          ),
        ),
      );
    });
  }

  /// 🎬 播放器层
  Widget _buildPlayer() {
    return Center(
      child: buildMediaPlayer(),
    );
  }

  /// 📱 正常 UI
  Widget _buildNormalUI() {
    return Column(
      children: [
        buildUserProfile(Get.context!),
        Expanded(child: buildMessageArea()),
        SafeArea(
          top: false,
          child: buildBottomActions(Get.context!),
        ),
      ],
    );
  }

  Widget buildBottomActions(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: Colors.grey.withAlpha(25)),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: TextButton(onPressed: controller.followUser, child: Text("关注"))),
          Expanded(child: TextButton(onPressed: controller.refreshRoom, child: Text("刷新"))),
          Expanded(child: TextButton(onPressed: controller.share, child: Text("分享"))),
        ],
      ),
    );
  }

  List<Widget> buildAppbarActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.more_horiz),
          onPressed: () {},
        )
      ];

  Widget buildMediaPlayer() => Stack(
        children: [
          Video(
            controller: controller.videoController,
            controls: (state) => playerControls(state, controller),
            wakelock: false,
          ),
          Obx(() => Visibility(
                visible: !controller.liveStatus.value,
                child: const Center(child: Text("未开播")),
              )),
        ],
      );

  Widget buildUserProfile(BuildContext context) => const SizedBox();

  Widget buildMessageArea() => const SizedBox();
}
