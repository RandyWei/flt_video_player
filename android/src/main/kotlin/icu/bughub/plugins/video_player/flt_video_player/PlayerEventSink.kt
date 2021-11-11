package icu.bughub.plugins.video_player.flt_video_player

import io.flutter.plugin.common.EventChannel
import java.util.*

class PlayerEventSink : EventChannel.EventSink {

    private var eventSink: EventChannel.EventSink? = null

    private val eventQueue: Queue<Any> = LinkedList()

    private var isEnd = false

    fun setSinkProxy(sink: EventChannel.EventSink?) {
        this.eventSink = sink
        consume()
    }

    private fun enqueue(event: Any?) {
        if (isEnd) return
        eventQueue.offer(event)
    }

    private fun consume() {
        while (!eventQueue.isEmpty()) {
            when (val event = eventQueue.poll()) {
                is EndEvent -> {
                    eventSink?.endOfStream()
                }
                is ErrorEvent -> {
                    val errorEvent: ErrorEvent = event
                    eventSink?.error(errorEvent.code, errorEvent.message, errorEvent.details)
                }
                else -> {
                    eventSink?.success(event)
                }
            }
        }
    }

    override fun success(event: Any?) {
        enqueue(event)
        consume()
    }

    override fun error(code: String?, message: String?, details: Any?) {
        enqueue(ErrorEvent(code, message, details))
        consume()
    }

    override fun endOfStream() {
        enqueue(EndEvent())
        consume()
        isEnd = true
    }

    private class EndEvent

    private data class ErrorEvent(val code: String?, val message: String?, val details: Any?)
}