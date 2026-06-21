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

  /// ✅ 统一安全区底部 inset
  double _bottomInset(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  @override
  Widget build(BuildContext context) {
    final page = Obx(() {
      if (controller.loadError.value) {
        return Scaffold(
          appBar: AppBar(title: const Text("直播间加载失败")),
          body: const Center(child: Text("加载失败")),
        );
      }

      // ✅ 全屏模式
      if (controller.fullScreenState.value) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (e, r) {
            controller.exitFull();
          },
          child: Scaffold(
            body: SafeArea(
              top: false,
              bottom: true,
              child: buildMediaPlayer(),
            ),
          ),
        );
      }

      return buildPageUI(context);
    });

    if (!Platform.isAndroid) return page;

    return PiPSwitcher(
      floating: controller.pip,
      childWhenDisabled: page,
      childWhenEnabled: buildMediaPlayer(),
    );
  }

  Widget buildPageUI(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          appBar: AppBar(
            title: Obx(() => Text(controller.detail.value?.title ?? "直播间")),
            actions: buildAppbarActions(context),
          ),
          body: orientation == Orientation.portrait
              ? buildPhoneUI(context)
              : buildTabletUI(context),
        );
      },
    );
  }

  Widget buildPhoneUI(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: buildMediaPlayer(),
        ),
        buildUserProfile(context),
        buildMessageArea(),
        buildBottomActions(context),
      ],
    );
  }

  Widget buildTabletUI(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: buildMediaPlayer()),
              SizedBox(width: 300, child: buildMessageArea()),
            ],
          ),
        ),

        // ✅ 修复 bottom inset
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              top: BorderSide(color: Colors.grey.withAlpha(25)),
            ),
          ),
          padding: AppStyle.edgeInsetsV4.copyWith(
            bottom: _bottomInset(context) + 4,
          ),
          child: Row(
            children: [
              TextButton(
                onPressed: controller.refreshRoom,
                child: const Text("刷新"),
              ),
              const Spacer(),
              TextButton(
                onPressed: controller.share,
                child: const Text("分享"),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildBottomActions(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Colors.grey.withAlpha(25))),
      ),

      // ✅ 修复点：动态 safe area
      padding: EdgeInsets.only(
        bottom: _bottomInset(context),
      ),

      child: Row(
        children: [
          Expanded(
            child: Obx(() => TextButton.icon(
                  onPressed: controller.followed.value
                      ? controller.removeFollowUser
                      : controller.followUser,
                  icon: Icon(controller.followed.value
                      ? Remix.heart_fill
                      : Remix.heart_line),
                  label: Text(
                      controller.followed.value ? "取消关注" : "关注"),
                )),
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

  Widget buildMediaPlayer() {
    return Stack(
      children: [
        Video(
          key: controller.globalPlayerKey,
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
  }

  Widget buildUserProfile(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Obx(() => Row(
            children: [
              NetImage(controller.detail.value?.userAvatar ?? "",
                  width: 40, height: 40),
              const SizedBox(width: 8),
              Expanded(
                child: Text(controller.detail.value?.userName ?? ""),
              ),
            ],
          )),
    );
  }

  Widget buildMessageArea() {
    return Expanded(
      child: const Center(child: Text("聊天区域")),
    );
  }

  List<Widget> buildAppbarActions(BuildContext context) {
    return [
      IconButton(
        onPressed: controller.refreshRoom,
        icon: const Icon(Icons.refresh),
      ),
    ];
  }
}
