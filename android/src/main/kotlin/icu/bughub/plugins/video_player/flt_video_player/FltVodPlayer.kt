package icu.bughub.plugins.video_player.flt_video_player

import android.graphics.SurfaceTexture
import android.os.Bundle
import android.view.Surface
import com.tencent.rtmp.ITXVodPlayListener
import com.tencent.rtmp.TXVodPlayConfig
import com.tencent.rtmp.TXVodPlayer
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry
import kotlin.math.max
import kotlin.math.min

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

        stopPlay(false)
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
    private fun initPlayer(playConfig: TXVodPlayConfig): Long {
        if (vodPlayer == null) {
            vodPlayer = TXVodPlayer(flutterPluginBinding.applicationContext)
            setupPlayer(playConfig)
        }
        return surfaceTextureEntry?.id() ?: -1
    }

    /**
     * 配置播放器
     *
     */
    private fun setupPlayer(playConfig: TXVodPlayConfig) {
        surfaceTextureEntry = flutterPluginBinding.textureRegistry.createSurfaceTexture()
        surfaceTexture = surfaceTextureEntry?.surfaceTexture()
        surface = Surface(surfaceTexture)


        vodPlayer?.setConfig(playConfig)
        vodPlayer?.setSurface(surface)
        vodPlayer?.enableHardwareDecode(true)
        vodPlayer?.setVodListener(this)
    }

    private fun startPlay(url: String): Int {
        return vodPlayer?.startPlay(url) ?: uninitialized
    }


    private fun stopPlay(isNeedClearLastImg: Boolean): Int? {
        return vodPlayer?.stopPlay(isNeedClearLastImg)
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

                val playConfig = TXVodPlayConfig()

                playConfig.setConnectRetryCount(call.argument<Int>("connectRetryCount") ?: 3)
                playConfig.setConnectRetryInterval(call.argument<Int>("connectRetryInterval") ?: 3)
                playConfig.setTimeout(call.argument<Int>("timeout") ?: 10)
                playConfig.setFirstStartPlayBufferTime(
                    call.argument<Int>("firstStartPlayBufferTime") ?: 100
                )
                playConfig.setNextStartPlayBufferTime(
                    call.argument<Int>("nextStartPlayBufferTime") ?: 250
                )

                playConfig.setCacheFolderPath(call.argument("cacheFolderPath"))
                playConfig.setMaxCacheItems(call.argument<Int>("maxCacheItems") ?: 0)
                playConfig.setHeaders(call.argument("headers"))
                //< 是否精确 seek，默认YES。开启精确后seek，seek 的时间平均多出200ms
                playConfig.setEnableAccurateSeek(
                    call.argument<Boolean>("enableAccurateSeek") ?: false
                )
                playConfig.setProgressInterval(
                    (call.argument<Double>("progressInterval")?.toInt() ?: 0)
                )

                playConfig.setMaxBufferSize(call.argument<Int>("maxBufferSize") ?: 0)

                playConfig.setOverlayKey(call.argument("overlayKey"))
                playConfig.setOverlayIv(call.argument("overlayIv"))


                val id = initPlayer(playConfig)
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

            "stop" -> {
                val isNeedClearLastImg = call.argument<Boolean>("isNeedClearLastImg") ?: false
                val r: Int? = stopPlay(isNeedClearLastImg)
                result.success(r)
            }


            "isPlaying" -> {
                result.success(vodPlayer?.isPlaying ?: false)
            }

            "pause" -> {
                vodPlayer?.pause()
                result.success(null)
            }

            "resume" -> {
                vodPlayer?.resume()
                result.success(null)
            }

            "seek" -> {
                val time = call.argument<Int>("time")
                if (time != null) {
                    vodPlayer?.seek(time)
                }
                result.success(null)
            }

            "currentPlaybackTime" -> {
                result.success(vodPlayer?.currentPlaybackTime)
            }

            "duration" -> result.success(vodPlayer?.duration)

            "playableDuration" -> result.success(vodPlayer?.playableDuration)

            "setMute" -> {
                val enable = call.argument<Boolean>("enable") ?: false
                vodPlayer?.setMute(enable)
                result.success(null)
            }

            "setAudioPlayoutVolume" -> {
                var volume = call.argument<Int>("volume") ?: 0
                volume = max(0, volume)
                volume = min(100, volume)
                vodPlayer?.setAudioPlayoutVolume(volume)
                result.success(null)
            }

            "setRate" -> {
                val rate = (call.argument<Double>("rate") ?: 1.0).toFloat()
                vodPlayer?.setRate(rate)
                result.success(null)
            }

            "setMirror" -> {
                val mirror = call.argument<Boolean>("mirror") ?: false
                vodPlayer?.setMirror(mirror)
                result.success(null)
            }

            "setLoop" -> {
                val loop = call.argument<Boolean>("loop") ?: false
                vodPlayer?.isLoop = loop
                result.success(null)
            }

            "setRenderRotation" -> {
                val rotation = call.argument<Int>("rotation") ?: 1
                vodPlayer?.setRenderRotation(rotation)
                result.success(null)
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