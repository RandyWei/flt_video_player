///
/// Created by wei on 2021/11/17.<br/>
///
import 'package:flutter/material.dart';
import "package:flutter/widgets.dart";

class PlatformViewDemo extends StatefulWidget {
  const PlatformViewDemo({Key? key}) : super(key: key);

  @override
  _PlatformViewDemoState createState() => _PlatformViewDemoState();
}

class _PlatformViewDemoState extends State<PlatformViewDemo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Platform View Demo"),
      ),
      body: Center(
        child: Column(
          children: const [
            AspectRatio(
                aspectRatio: 16 / 9,
                child: UiKitView(viewType: "FltVideoView")),
            AspectRatio(
                aspectRatio: 16 / 9, child: UiKitView(viewType: "FltVideoView"))
          ],
        ),
      ),
    );
  }
}
