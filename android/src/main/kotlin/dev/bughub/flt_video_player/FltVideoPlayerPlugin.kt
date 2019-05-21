package dev.bughub.flt_video_player

import com.chinahrt.flutter_plugin_demo3.FLTVideoPlayer
import com.tencent.rtmp.TXLiveConstants
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

class FltVideoPlayerPlugin(var registrar: Registrar) : MethodCallHandler {

    private val videoPlayers: MutableMap<Long, FLTVideoPlayer> = mutableMapOf()

    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val plugin = FltVideoPlayerPlugin(registrar)
            val channel = MethodChannel(registrar.messenger(), "bughub.dev/flutterVideoPlayer")
            channel.setMethodCallHandler(plugin)
            registrar.addViewDestroyListener {
                plugin.onDestroy()
                false
            }
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val textures = registrar.textures()
        if (textures == null) {
            result.error("no_activity", "video_player plugin requires a foreground activity", null)
            return
        }
        val textureId: Long = call.argument<Number>("textureId")?.toLong() ?: 0
        when {
            call.method == "init" -> {
                for (player in videoPlayers.values) {
                    player.dispose()
                }
                videoPlayers.clear()
                result.success(null)
            }
            call.method == "create" -> {//初始化播放器和创建SurfaceTexture，并返回textureId供flutter的Texture使用

                val handle = textures.createSurfaceTexture()
                val eventChannel = EventChannel(registrar.messenger(), "bughub.dev/flutterVideoPlayer/videoEvents${handle.id()}")

                val path = call.argument<String>("path")

                val playerConfigArg = call.argument<Map<Any, Any>>("playerConfig")

                val startPosition: Int = call.argument<Int>("startPosition") ?: 0
                val player = FLTVideoPlayer(registrar.context(), eventChannel, handle, path, result, playerConfigArg, startPosition)
                videoPlayers[handle.id()] = player


            }
            call.method == "dispose" -> {
                val txVodPlayer = videoPlayers[textureId]
                txVodPlayer?.dispose()
                onDestroy()
                result.success(null)
            }
            call.method == "setLoop" -> {
                val loop = call.argument<Boolean>("loop") ?: false
                val txVodPlayer = videoPlayers[textureId]
                txVodPlayer?.setLoop(loop)
                result.success(null)
            }
            call.method == "play" -> {//恢复播放,重新获取流数据.
                val txVodPlayer = videoPlayers[textureId]
                txVodPlayer?.resume()
                result.success(null)
            }
            call.method == "enableHardwareDecode" -> {//enable - 启用或禁用视频硬解码. true:启用视频硬解码. false:禁用视频硬解码.启用默认的视频软解码.

            }
            call.method == "position" -> {//获取当前播放位置,单位秒
                val txVodPlayer = videoPlayers[textureId]
                result.success(txVodPlayer?.position())
            }
            call.method == "seekTo" -> {//跳转进度
                val txVodPlayer = videoPlayers[textureId]
                val position = call.argument<Int>("position") ?: 0
                txVodPlayer?.seekTo(position)
                result.success(null)
            }
            call.method == "pause" -> {//暂停播放,停止获取流数据,保留最后一帧画面.
                val txVodPlayer = videoPlayers[textureId]
                txVodPlayer?.pause()
                result.success(null)
            }
            call.method == "playableDuration" -> {//获取可播放时长,单位秒
                val txVodPlayer = videoPlayers[textureId]
                result.success(txVodPlayer?.getPlayableDuration())
            }
            call.method == "width" -> {//宽度
                val txVodPlayer = videoPlayers[textureId]
                result.success(txVodPlayer?.width())
            }
            call.method == "height" -> {//宽度
                val txVodPlayer = videoPlayers[textureId]
                result.success(txVodPlayer?.height())
            }
            call.method == "setRenderMode" -> {
                /// 图像铺满屏幕
                /// RENDER_MODE_FILL_SCREEN  = 0,
                /// 图像长边填满屏幕
                /// RENDER_MODE_FILL_EDGE
                val renderMode = call.argument<String>("renderMode") ?: ""
                val txVodPlayer = videoPlayers[textureId]
                if ("RENDER_MODE_FILL_SCREEN" == renderMode) {
                    txVodPlayer?.setRenderMode(TXLiveConstants.RENDER_MODE_FULL_FILL_SCREEN)
                } else if ("RENDER_MODE_FILL_EDGE" == renderMode) {
                    txVodPlayer?.setRenderMode(TXLiveConstants.RENDER_MODE_ADJUST_RESOLUTION)
                }
                result.success(null)
            }
            call.method == "setRenderRotation" -> {
                /// home在右边
                /// HOME_ORIENTATION_RIGHT  = 0,
                /// home在下面
                /// HOME_ORIENTATION_DOWN,
                /// home在左边
                /// HOME_ORIENTATION_LEFT,
                /// home在上面
                /// HOME_ORIENTATION_UP,
                val renderRotation = call.argument<String>("renderRotation") ?: ""
                val txVodPlayer = videoPlayers[textureId]
                if ("HOME_ORIENTATION_RIGHT" == renderRotation) {
                    txVodPlayer?.setRenderRotation(TXLiveConstants.RENDER_ROTATION_0)
                } else if ("HOME_ORIENTATION_DOWN" == renderRotation) {
                    txVodPlayer?.setRenderRotation(TXLiveConstants.RENDER_ROTATION_90)
                } else if ("HOME_ORIENTATION_LEFT" == renderRotation) {
                    txVodPlayer?.setRenderRotation(TXLiveConstants.RENDER_ROTATION_180)
                } else if ("HOME_ORIENTATION_UP" == renderRotation) {
                    txVodPlayer?.setRenderRotation(TXLiveConstants.RENDER_ROTATION_270)
                }
                result.success(null)
            }
            call.method == "setMirror" -> {//设置镜像
                val txVodPlayer = videoPlayers[textureId]
                val mirror = call.argument<Boolean>("mirror") ?: false
                txVodPlayer?.setMirror(mirror)
                result.success(null)
            }
            call.method == "setMute" -> {//设置是否静音播放.
                val txVodPlayer = videoPlayers[textureId]
                val mute = call.argument<Boolean>("mute") ?: false
                txVodPlayer?.setMute(mute)
                result.success(null)
            }
            call.method == "setRate" -> {//设置点播的播放速率。默认1.0
                val txVodPlayer = videoPlayers[textureId]
                val rate = call.argument<Double>("rate") ?: 1.0
                txVodPlayer?.setRate(rate)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }


    fun onDestroy() {
        for (player in videoPlayers.values) {
            player.dispose()
        }
        videoPlayers.clear()
    }
}

