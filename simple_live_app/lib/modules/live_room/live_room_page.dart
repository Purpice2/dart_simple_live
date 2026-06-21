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

      Widget page = Scaffold(
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
              buildMediaPlayer(),

              if (!full)
                Column(
                  children: [
                    buildUserProfile(context),
                    Expanded(child: buildMessageArea()),

                    /// ✅ 修复点：Android bottom inset
                    SafeArea(
                      top: false,
                      child: buildBottomActions(context),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );

      if (!Platform.isAndroid) return page;

      return PiPSwitcher(
        floating: controller.pip,
        childWhenDisabled: page,
        childWhenEnabled: buildMediaPlayer(),
      );
    });
  }

  Widget buildMediaPlayer() {
    var boxFit = BoxFit.contain;
    double? aspectRatio;

    if (AppSettingsController.instance.scaleMode.value == 0) {
      boxFit = BoxFit.contain;
    } else if (AppSettingsController.instance.scaleMode.value == 1) {
      boxFit = BoxFit.fill;
    } else if (AppSettingsController.instance.scaleMode.value == 2) {
      boxFit = BoxFit.cover;
    } else if (AppSettingsController.instance.scaleMode.value == 3) {
      boxFit = BoxFit.contain;
      aspectRatio = 16 / 9;
    } else if (AppSettingsController.instance.scaleMode.value == 4) {
      boxFit = BoxFit.contain;
      aspectRatio = 4 / 3;
    }

    return Stack(
      children: [
        Video(
          key: controller.globalPlayerKey,
          controller: controller.videoController,
          pauseUponEnteringBackgroundMode:
              AppSettingsController.instance.playerAutoPause.value,
          resumeUponEnteringForegroundMode:
              AppSettingsController.instance.playerAutoPause.value,
          controls: (state) {
            return playerControls(state, controller);
          },
          aspectRatio: aspectRatio,
          fit: boxFit,
          wakelock: false,
        ),
        Obx(
          () => Visibility(
            visible: !controller.liveStatus.value,
            child: const Center(
              child: Text("未开播",
                  style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildBottomActions(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: Colors.grey.withAlpha(25)),
        ),
      ),

      /// 🔥 修复点：用系统 inset，不用写死高度
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
      ),

      child: Row(
        children: [
          Expanded(
            child: Obx(
              () => controller.followed.value
                  ? TextButton.icon(
                      onPressed: controller.removeFollowUser,
                      icon: const Icon(Remix.heart_fill),
                      label: const Text("取消关注"),
                    )
                  : TextButton.icon(
                      onPressed: controller.followUser,
                      icon: const Icon(Remix.heart_line),
                      label: const Text("关注"),
                    ),
            ),
          ),
          Expanded(
            child: TextButton.icon(
              onPressed: controller.refreshRoom,
              icon: const Icon(Remix.refresh_line),
              label: const Text("刷新"),
            ),
          ),
          Expanded(
            child: TextButton.icon(
              onPressed: controller.share,
              icon: const Icon(Remix.share_line),
              label: const Text("分享"),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildUserProfile(BuildContext context) => Container(
        padding: AppStyle.edgeInsetsA8,
        child: Obx(
          () => Row(
            children: [
              NetImage(controller.detail.value?.userAvatar ?? "",
                  width: 48, height: 48, borderRadius: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(controller.detail.value?.userName ?? ""),
              ),
            ],
          ),
        ),
      );

  Widget buildMessageArea() => const SizedBox();

  List<Widget> buildAppbarActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.more_horiz),
          onPressed: () {},
        )
      ];
}
