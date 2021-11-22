# flt_video_player

基于腾讯云原生播放器封装的 Flutter 版本。
使用本播放器前建议查看腾讯云[官方文档](https://cloud.tencent.com/document/product/881/20191)

## 安装

```yaml
//import
dependencies:
  flt_video_player:
    git:
      url: git://github.com/RandyWei/flt_video_player.git
```
## Android

在 app/build.gradle 的 defaultConfig 中添加配置
```groovy
ndk {
    abiFilters "armeabi", "armeabi-v7a", "arm64-v8a"
}
```
在 android/app/src/main/AndroidManifest.xml 中增加如下配置
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
    ...
    >
    <uses-permission android:name="android.permission.INTERNET"/>
    <application
        tools:replace="android:label">
    ...
    </application>
    ...
<manifest
```

## Example

```dart

class SimpleDemo extends StatefulWidget {
  const SimpleDemo({Key? key}) : super(key: key);

  @override
  _SimpleDemoState createState() => _SimpleDemoState();
}

class _SimpleDemoState extends State<SimpleDemo> {
  late VodPlayerController controller;
  double _aspectRation = 16 / 9;

  @override
  void initState() {
    super.initState();

    var playerConfig = PlayerConfig();

    //可以通过renderType来配置使用外接纹理方式还是 PlatformView 方式对接，经实测同一视频在安卓机型中两者在内存占用上区别不大，iOS 环境下外接纹理稍高
    controller = VodPlayerController(config: playerConfig);

    //监听播放状态
    controller.playState.listen((event) {
      debugPrint("playerState:$event");
    });

    controller.onPlayerEvent.listen((event) {
      debugPrint("PlayerEvent:$event");
    });

    controller.onNetEvent.listen((event) {
      //获取视频宽度高度
      double w = (event["VIDEO_WIDTH"]).toDouble();
      double h = (event["VIDEO_HEIGHT"]).toDouble();

      //计算比例
      if (w > 0 && h > 0) {
        _aspectRation = 1.0 * w / h;
        setState(() {});
      }
    });

    controller.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: _aspectRation,
          child: VodPlayer(
            controller: controller,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.play(
              "https://stream7.iqilu.com/10339/article/202002/18/2fca1c77730e54c7b500573c2437003f.mp4");
        },
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
```

更多示例，可以查看 example 示例