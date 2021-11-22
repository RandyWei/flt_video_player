package icu.bughub.plugins.video_player.flt_video_player

import android.content.Context
import android.view.View
import com.tencent.rtmp.TXVodPlayConfig
import com.tencent.rtmp.ui.TXCloudVideoView
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class FltVideoView(
    flutterPluginBinding: FlutterPlugin.FlutterPluginBinding,
    viewId: Int
) : PlatformView, FltBasePlayer(flutterPluginBinding) {

    private var container: TXCloudVideoView =
        TXCloudVideoView(flutterPluginBinding.applicationContext)

    init {
        methodChannel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "${Constants.CHANNEL_PREFIX}/vodplayer/${viewId}"
        )
        methodChannel?.setMethodCallHandler(this)

        //注册通信通道
        eventChannel = EventChannel(
            flutterPluginBinding.binaryMessenger,
            "${Constants.CHANNEL_PREFIX}/vodplayer/event/${viewId}"
        )
        eventChannel?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(p0: Any?, p1: EventChannel.EventSink?) {
                eventSink.setSinkProxy(p1)
            }

            override fun onCancel(p0: Any?) {
                eventSink.setSinkProxy(null)
            }
        })

        netChannel = EventChannel(
            flutterPluginBinding.binaryMessenger,
            "${Constants.CHANNEL_PREFIX}/vodplayer/net/${viewId}"
        )
        netChannel?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(p0: Any?, p1: EventChannel.EventSink?) {
                netEventSink.setSinkProxy(p1)
            }

            override fun onCancel(p0: Any?) {
                netEventSink.setSinkProxy(null)
            }
        })
    }

    override fun initPlayer(playConfig: TXVodPlayConfig) {
        super.initPlayer(playConfig)
        vodPlayer?.setPlayerView(container)
    }

    override fun getView(): View {
        return container
    }

    override fun dispose() {
    }
}

class FltVideoViewFactory(
    private val
    flutterPluginBinding: FlutterPlugin.FlutterPluginBinding,
    private val onViewCreated: (Int, FltVideoView) -> Unit
) : PlatformViewFactory(
    StandardMessageCodec.INSTANCE
) {

    override fun create(context: Context?, viewId: Int, args: Any?): PlatformView {
        val view = FltVideoView(flutterPluginBinding, viewId)
        onViewCreated.invoke(viewId, view)
        return view
    }

}