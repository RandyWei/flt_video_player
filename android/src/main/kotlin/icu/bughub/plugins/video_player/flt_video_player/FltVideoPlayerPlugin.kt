package icu.bughub.plugins.video_player.flt_video_player

import android.util.SparseArray
import androidx.annotation.NonNull
import icu.bughub.plugins.video_player.flt_video_player.Constants.CHANNEL_PREFIX

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** FltVideoPlayerPlugin */
class FltVideoPlayerPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {


    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel

    //存储播放器
    private val players = SparseArray<FltBasePlayer>()

    private var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        this.flutterPluginBinding = flutterPluginBinding
        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "${CHANNEL_PREFIX}/flt_video_player"
        )
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "createVodPlayer" -> {
                val vodPlayer = flutterPluginBinding?.let { FltVodPlayer(it) }
                val playerId = vodPlayer?.getPlayerId() ?: -1
                players.append(playerId, vodPlayer)
                result.success(playerId)
            }
            "releaseVodPlayer" -> {
                val playerId = call.argument<Int>("playerId") ?: -1
                val player = players[playerId]
                player.destory()
                players.remove(playerId)
            }
            else -> {
                result.notImplemented()
            }
        }
    }


    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        flutterPluginBinding?.platformViewRegistry?.registerViewFactory(
            "FltVideoView",
            FltVideoViewFactory(flutterPluginBinding!!) { viewId: Int, view: FltVideoView ->
                players.append(viewId, view)
            }
        )
    }

    override fun onDetachedFromActivityForConfigChanges() {

    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {

    }

    override fun onDetachedFromActivity() {

    }
}
