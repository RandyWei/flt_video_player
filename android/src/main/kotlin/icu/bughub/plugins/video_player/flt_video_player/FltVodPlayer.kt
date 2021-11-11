package icu.bughub.plugins.video_player.flt_video_player

import android.graphics.SurfaceTexture
import android.os.Bundle
import android.view.Surface
import com.tencent.rtmp.ITXVodPlayListener
import com.tencent.rtmp.TXVodPlayer
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry

class FltVodPlayer(private val flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) :
    FltBasePlayer(), MethodChannel.MethodCallHandler, ITXVodPlayListener {

    private val uninitialized = -1

    private var vodPlayer: TXVodPlayer? = null

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var netChannel: EventChannel? = null

    private var eventSink: PlayerEventSink = PlayerEventSink()
    private var netEventSink: PlayerEventSink = PlayerEventSink()

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

    override fun destory() {

        vodPlayer?.stopPlay(true)
        vodPlayer = null


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

        super.destory()

    }

    /**
     * 初始化播放器
     *
     * @return texture id
     */
    private fun initPlayer(): Long {
        if (vodPlayer == null) {
            vodPlayer = TXVodPlayer(flutterPluginBinding.applicationContext)
            vodPlayer?.setVodListener(this)
            setupPlayer()
        }
        return surfaceTextureEntry?.id() ?: -1
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
        vodPlayer?.enableHardwareDecode(true)
        vodPlayer?.setVodListener(this)
    }

    private fun startPlay(url: String): Int {
        return vodPlayer?.startPlay(url) ?: uninitialized
    }

    private fun getParams(event: Int, bundle: Bundle?): Map<String, Any?> {
        val param = HashMap<String, Any?>()

        if (event != 0) {
            param["event"] = event
        }

        if (bundle?.isEmpty == false) {
            val keySet = bundle.keySet()
            for (key in keySet) {
                val value = bundle.get(key)
                param[key] = value
            }
        }

        return param
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {

        when (call.method) {
            "init" -> {
                val id = initPlayer()
                result.success(id)
            }

            "play" -> {
                val url = call.argument<String>("url")
                if (url?.isNotEmpty() == true) {
                    val r = startPlay(url)
                    result.success(r)
                } else {
                    result.error("404", "url为空", "url为空")
                }
            }


        }
    }

    override fun onPlayEvent(player: TXVodPlayer?, i: Int, bundle: Bundle?) {
        eventSink.success(getParams(i, bundle))
    }

    override fun onNetStatus(player: TXVodPlayer?, bundle: Bundle?) {
        netEventSink.success(getParams(0, bundle))
    }
}