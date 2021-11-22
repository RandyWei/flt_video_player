///
/// Created by wei on 2021/11/22.<br/>
///
import 'dart:io';

import 'package:flutter/services.dart';
import "package:flutter/widgets.dart";

class PlatformVideoView extends StatelessWidget {
  const PlatformVideoView({Key? key, this.onPlatformViewCreated})
      : super(key: key);

  final Function(int)? onPlatformViewCreated;

  @override
  Widget build(BuildContext context) {
    return Platform.isAndroid
        ? AndroidView(
            viewType: "FltVideoView",
            creationParamsCodec: const StandardMessageCodec(),
            onPlatformViewCreated: onPlatformViewCreated,
          )
        : UiKitView(
            viewType: "FltVideoView",
            creationParamsCodec: const StandardMessageCodec(),
            onPlatformViewCreated: onPlatformViewCreated,
          );
  }
}
