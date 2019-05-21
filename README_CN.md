# flt_video_player

基于腾讯云播放器TXVodPlayer封装的Flutter Video Player

## Installation
First, add `flt_video_player` as a [dependency in your pubspec.yaml file](https://flutter.io/using-packages/).

### Android

Ensure the following permission is present in your Android Manifest file, located in `<project root>/android/app/src/main/AndroidManifest.xml:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

The Flutter project template adds it, so it may already be there.

### Supported Formats
The backing player is [TxVodPlayer](https://cloud.tencent.com/document/product/881/),
  please refer [here](https://cloud.tencent.com/document/product/881/) for list of supported formats.