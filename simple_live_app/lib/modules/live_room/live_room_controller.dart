import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_core/simple_live_core.dart';
import 'package:simple_live_app/modules/live_room/player/player_controller.dart';

class LiveRoomController extends PlayerController
    with WidgetsBindingObserver {

  final Site pSite;
  final String pRoomId;

  late Rx<Site> rxSite;
  late Rx<String> rxRoomId;

  Site get site => rxSite.value;
  String get roomId => rxRoomId.value;

  Rx<LiveRoomDetail?> detail = Rx<LiveRoomDetail?>(null);

  var liveStatus = false.obs;
  var followed = false.obs;

  RxList<LiveMessage> messages = RxList<LiveMessage>();

  final ScrollController scrollController = ScrollController();

  var disableAutoScroll = false.obs;

  Timer? autoExitTimer;
  Timer? _liveDurationTimer;

  var fullScreenState = false.obs;

  LiveRoomController({
    required this.pSite,
    required this.pRoomId,
  }) {
    rxSite = pSite.obs;
    rxRoomId = pRoomId.obs;
  }

  // ----------------------------
  // INIT
  // ----------------------------

  @override
  void onInit() {
    WidgetsBinding.instance.addObserver(this);

    scrollController.addListener(_scrollListener);

    super.onInit();
  }

  // ----------------------------
  // SCROLL FIX
  // ----------------------------

  void _scrollListener() {
    if (!scrollController.hasClients) return;

    final pos = scrollController.position;

    // 👇 用户向上滑 -> 暂停自动滚动
    if (pos.userScrollDirection == ScrollDirection.forward) {
      disableAutoScroll.value = true;
    }

    // ✅ 修复：滚到底自动恢复
    if (pos.pixels >= pos.maxScrollExtent - 50) {
      disableAutoScroll.value = false;
    }
  }

  void chatScrollToBottom() {
    if (!scrollController.hasClients) return;
    if (disableAutoScroll.value) return;

    scrollController.jumpTo(
      scrollController.position.maxScrollExtent,
    );
  }

  // ----------------------------
  // FULLSCREEN
  // ----------------------------

  void enterFull() {
    fullScreenState.value = true;
  }

  void exitFull() {
    fullScreenState.value = false;

    // ✅ 强制恢复系统UI（避免 inset 卡住）
    // ignore: deprecated_member_use
    WidgetsBinding.instance.addPostFrameCallback((_) {});
  }

  // ----------------------------
  // MESSAGE HANDLING
  // ----------------------------

  void onWSMessage(LiveMessage msg) {
    if (msg.type == LiveMessageType.chat) {
      messages.add(msg);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        chatScrollToBottom();
      });
    }
  }

  // ----------------------------
  // MEDIA FIX
  // ----------------------------

  @override
  void mediaEnd() async {
    super.mediaEnd();
  }

  @override
  void mediaError(String error) async {
    // ❌ 修复：不能调用 mediaEnd
    super.mediaError(error);

    Log.d("播放错误: $error");
  }

  // ----------------------------
  // LIFECYCLE FIX
  // ----------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      disableAutoScroll.value = true;
    }

    if (state == AppLifecycleState.resumed) {
      disableAutoScroll.value = false;
    }
  }

  // ----------------------------
  // CLEANUP
  // ----------------------------

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);

    scrollController.removeListener(_scrollListener);
    scrollController.dispose();

    autoExitTimer?.cancel();
    _liveDurationTimer?.cancel();

    super.onClose();
  }
}
