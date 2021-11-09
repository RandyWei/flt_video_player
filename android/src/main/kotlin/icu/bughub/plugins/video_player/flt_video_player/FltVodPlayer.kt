package icu.bughub.plugins.video_player.flt_video_player

import android.graphics.SurfaceTexture
import android.os.Bundle
import android.view.Surface
import com.tencent.rtmp.ITXVodPlayListener
import com.tencent.rtmp.TXVodPlayer
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry

class FltVodPlayer(private val flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) :
    FltBasePlayer(), MethodChannel.MethodCallHandler, ITXVodPlayListener {

    private val uninitailized = -1

    private var vodPlayer: TXVodPlayer? = null

    private var methodChannel: MethodChannel? = null

    private var surfaceTextureEntry: TextureRegistry.SurfaceTextureEntry? = null
    private var surfaceTexture: SurfaceTexture? = null
    private var surface: Surface? = null


    init {
        methodChannel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "${Constants.CHANNEL_PREFIX}/vodplayer/${getPlayerId()}"
        )
        methodChannel?.setMethodCallHandler(this)
    }

    override fun destory() {

        vodPlayer?.stopPlay(true)
        vodPlayer = null



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
    }

    private fun startPlay(url: String): Int {
        return vodPlayer?.startPlay(url) ?: uninitailized
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

    override fun onPlayEvent(p0: TXVodPlayer?, p1: Int, p2: Bundle?) {

    }

    override fun onNetStatus(p0: TXVodPlayer?, p1: Bundle?) {

    }
}