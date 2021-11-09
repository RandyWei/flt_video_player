package icu.bughub.plugins.video_player.flt_video_player

import java.util.concurrent.atomic.AtomicInteger

open class FltBasePlayer {
    private val mAtomicId = AtomicInteger(0)
    private var mPlayerId: Int = -1

    init {
        this.mPlayerId = mAtomicId.incrementAndGet()
    }

    open fun getPlayerId(): Int {
        return mPlayerId
    }


    open fun destory() {}

}