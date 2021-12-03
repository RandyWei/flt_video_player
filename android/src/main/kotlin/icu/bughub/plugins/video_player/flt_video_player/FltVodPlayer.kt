package icu.bughub.plugins.video_player.flt_video_player

import android.graphics.SurfaceTexture
import android.view.Surface
import com.tencent.rtmp.TXVodPlayConfig
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry

class FltVodPlayer(private val flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) :
    FltBasePlayer(flutterPluginBinding) {

    private var surfaceTextureEntry: TextureRegistry.SurfaceTextureEntry? = null
    private var surfaceTexture: SurfaceTexture? = null
    private var surface: Surface? = null


    init {
        methodChannel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "${Constants.CHANNEL_PREFIX}/vodplayer/${getPlayerId()}"
        )
        methodChannel?.setMethodCallHandler(this)

        //注册通信通道
        eventChannel = EventChannel(
            flutterPluginBinding.binaryMessenger,
            "${Constants.CHANNEL_PREFIX}/vodplayer/event/${getPlayerId()}"
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
            "${Constants.CHANNEL_PREFIX}/vodplayer/net/${getPlayerId()}"
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

    override fun destroy() {

        super.destroy()

        surfaceTextureEntry?.release()
        surfaceTextureEntry = null

        surfaceTexture?.release()
        surfaceTexture = null

        surface?.release()
        surface = null


        methodChannel?.setMethodCallHandler(null)
        methodChannel = null

        eventChannel?.setStreamHandler(null)
        eventChannel = null
        netChannel?.setStreamHandler(null)
        netChannel = null


    }

    override fun initPlayer(playConfig: TXVodPlayConfig) {
        super.initPlayer(playConfig)
        setupPlayer()
    }

    /**
     * 配置播放器
     *
     */
    private fun setupPlayer() {
        surfaceTextureEntry = flutterPluginBinding.textureRegistry.createSurfaceTexture()
        surfaceTexture = surfaceTextureEntry?.surfaceTexture()
        surface = Surface(surfaceTexture)

        vodPlayer?.setSurface(surface)

        textureId = surfaceTextureEntry?.id() ?: -1
    }

}