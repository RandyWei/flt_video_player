package com.chinahrt.flutter_plugin_demo3

import android.content.Context
import android.os.Bundle
import android.view.Surface
import com.chinahrt.flutter_plugin_demo.QueuingEventSink
import com.tencent.rtmp.ITXVodPlayListener
import com.tencent.rtmp.TXLiveConstants
import com.tencent.rtmp.TXVodPlayConfig
import com.tencent.rtmp.TXVodPlayer
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry


class FLTVideoPlayer(var context: Context, var eventChannel: EventChannel, var textureEntry: TextureRegistry.SurfaceTextureEntry, var path: String?,
                     var result: MethodChannel.Result, var playerConfigArg: Map<Any, Any>?, var startPosition: Int) {
    private var txVodPlayer: TXVodPlayer? = null
    private val eventSink = QueuingEventSink()
    private var surface: Surface? = null

    init {
        setupVideoPlayer()
    }

    private fun setupVideoPlayer() {
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(o: Any?, sink: EventChannel.EventSink?) {
                // 把eventSink存起来
                eventSink.setDelegate(sink)
            }

            override fun onCancel(o: Any?) {
                eventSink.setDelegate(null)
            }
        })
        surface = Surface(textureEntry.surfaceTexture())
        txVodPlayer = TXVodPlayer(context)


        val playConfig = TXVodPlayConfig()
        var autoPlay = true
        playerConfigArg?.let {
            val connectRetryCount: Int = it["connectRetryCount"] as Int
            val connectRetryInterval: Int = it["connectRetryInterval"] as Int
            val timeout: Int = it["timeout"] as Int
            val cacheFolderPath = it["cacheFolderPath"] as String?
            val maxCacheItems: Int = it["maxCacheItems"] as Int
            val progressInterval: Int = (it["progressInterval"] as Double).toInt()

            autoPlay = it["autoPlay"] as Boolean

            playConfig.apply {
                setConnectRetryCount(connectRetryCount)
                setConnectRetryInterval(connectRetryInterval)
                setTimeout(timeout)
                if ((cacheFolderPath ?: "").isNotEmpty())
                    setCacheFolderPath(cacheFolderPath)
                setMaxCacheItems(maxCacheItems)
                setProgressInterval(progressInterval)
            }
        }
        txVodPlayer?.setSurface(surface)
        txVodPlayer?.setConfig(playConfig)
        txVodPlayer?.setAutoPlay(autoPlay)
        txVodPlayer?.setStartTime(startPosition.toFloat())
        txVodPlayer?.startPlay(path)
        txVodPlayer?.setVodListener(object : ITXVodPlayListener {
            override fun onPlayEvent(player: TXVodPlayer, event: Int, param: Bundle) {
                when (event) {
                    TXLiveConstants.PLAY_EVT_VOD_PLAY_PREPARED// 点播准备完成
                    -> {
                        val eventResult = HashMap<String, Any>()
                        eventResult["event"] = "prepared"
                        eventSink.success(eventResult)
                    }
                    TXLiveConstants.PLAY_EVT_PLAY_BEGIN// 播放开始
                    -> {

                        val progress = param.getInt(TXLiveConstants.EVT_PLAY_PROGRESS_MS) / 1000
                        val duration = param.getInt(TXLiveConstants.EVT_PLAY_DURATION_MS) / 1000

                        val eventResult = HashMap<String, Any>()
                        eventResult["event"] = "PLAY_EVT_PLAY_BEGIN"
                        eventResult["rawEvent"] = event
                        eventResult["position"] = progress
                        eventResult["duration"] = duration
                        eventSink.success(eventResult)
                    }
                    TXLiveConstants.PLAY_EVT_RCV_FIRST_I_FRAME// 点播显示首帧画面
                    -> {
                        val eventResult = HashMap<String, Any>()
                        eventResult["event"] = "PLAY_EVT_RCV_FIRST_I_FRAME"
                        eventResult["rawEvent"] = event
                        eventSink.success(eventResult)
                    }
                    TXLiveConstants.PLAY_EVT_PLAY_PROGRESS// 播放中的进度
                    -> {
                        if (txVodPlayer?.isPlaying == true) {
                            val progress = param.getInt(TXLiveConstants.EVT_PLAY_PROGRESS_MS) / 1000
                            val duration = param.getInt(TXLiveConstants.EVT_PLAY_DURATION_MS) / 1000
                            val playable = param.getInt(TXLiveConstants.EVT_PLAYABLE_DURATION_MS) / 1000

                            val eventResult = HashMap<String, Any>()
                            eventResult["event"] = "PLAY_EVT_PLAY_PROGRESS"
                            eventResult["rawEvent"] = event
                            eventResult["position"] = progress
                            eventResult["duration"] = duration
                            eventResult["playable"] = playable

                            eventSink.success(eventResult)
                        }
                    }
                    TXLiveConstants.PLAY_EVT_PLAY_END// 播放完成
                    -> {
                        val eventResult = HashMap<String, Any>()
                        eventResult["event"] = "PLAY_EVT_PLAY_END"
                        eventResult["rawEvent"] = event
                        eventSink.success(eventResult)
                    }
                    TXLiveConstants.PLAY_EVT_PLAY_LOADING// 缓冲开始
                    -> {
                        val eventResult = HashMap<String, Any>()
                        eventResult["event"] = "PLAY_EVT_PLAY_LOADING"
                        eventResult["rawEvent"] = event
                        eventSink.success(eventResult)
                    }
                    TXLiveConstants.PLAY_EVT_VOD_LOADING_END// 缓冲结束
                    -> {
                        val eventResult = HashMap<String, Any>()
                        eventResult["event"] = "PLAY_EVT_VOD_LOADING_END"
                        eventResult["rawEvent"] = event
                        eventSink.success(eventResult)
                    }
                    TXLiveConstants.PLAY_ERR_NET_DISCONNECT// 网络断开
                    -> {
                        val eventResult = HashMap<String, Any>()
                        eventResult["event"] = "PLAY_ERR_NET_DISCONNECT"
                        eventResult["rawEvent"] = event
                        eventSink.success(eventResult)
                    }
                    TXLiveConstants.PLAY_ERR_FILE_NOT_FOUND// 找不到文件
                    -> {
                        val eventResult = HashMap<String, Any>()
                        eventResult["event"] = "PLAY_ERR_FILE_NOT_FOUND"
                        eventResult["rawEvent"] = event
                        eventSink.success(eventResult)
                    }
                }

                if (event < 0) {
//                            Toast.makeText(context, param.getString(TXLiveConstants.EVT_DESCRIPTION), Toast.LENGTH_SHORT).show()
                }
            }

            override fun onNetStatus(player: TXVodPlayer, status: Bundle) {

            }
        })

        val reply = HashMap<String, Any>()
        reply["textureId"] = textureEntry.id()
        result.success(reply)
    }

    fun dispose() {
        txVodPlayer?.stopPlay(true)
        textureEntry.release()
        eventChannel.setStreamHandler(null)
        surface?.release()
    }

    fun setLoop(loop: Boolean) {
        txVodPlayer?.isLoop = loop
    }

    fun resume() {
        txVodPlayer?.resume()
    }

    fun position(): Float? {
        return txVodPlayer?.currentPlaybackTime
    }

    fun seekTo(position: Int) {
        txVodPlayer?.seek(position)
    }

    fun pause() {
        txVodPlayer?.pause()
    }

    fun getPlayableDuration(): Float? {
        return txVodPlayer?.playableDuration
    }

    fun width(): Int? {
        return txVodPlayer?.width
    }

    fun height(): Int? {
        return txVodPlayer?.height
    }

    fun setMirror(mirror: Boolean) {
        txVodPlayer?.setMirror(mirror)
    }

    fun setMute(mute: Boolean) {
        txVodPlayer?.setMute(mute)
    }

    fun setRate(rate: Double) {
        txVodPlayer?.setRate(rate.toFloat())
    }

    fun setRenderMode(renderMode: Int) {
        txVodPlayer?.setRenderMode(renderMode)
    }

    fun setRenderRotation(renderRotation: Int) {
        txVodPlayer?.setRenderRotation(renderRotation)
    }
}