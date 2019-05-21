package com.chinahrt.flutter_plugin_demo

import io.flutter.plugin.common.EventChannel
import java.util.ArrayList

/**
 * 这个类是从Google官方copy的
 *
 * And implementation of {@link EventChannel.EventSink} which can wrap an underlying sink.
 *
 * <p>It delivers messages immediately when downstream is available, but it queues messages before
 * the delegate event sink is set with setDelegate.
 *
 * <p>This class is not thread-safe. All calls must be done on the same thread or synchronized
 * externally.
 */
class QueuingEventSink : EventChannel.EventSink {

    private var delegate: EventChannel.EventSink? = null
    private val eventQueue = ArrayList<Any>()
    private var done = false

    fun setDelegate(delegate: EventChannel.EventSink?) {
        this.delegate = delegate
        maybeFlush()
    }

    override fun endOfStream() {
        enqueue(EndOfStreamEvent())
        maybeFlush()
        done = true
    }

    override fun error(code: String, message: String, details: Any) {
        enqueue(ErrorEvent(code, message, details))
        maybeFlush()
    }

    override fun success(event: Any) {
        enqueue(event)
        maybeFlush()
    }

    private fun enqueue(event: Any) {
        if (done) {
            return
        }
        eventQueue.add(event)
    }

    private fun maybeFlush() {
        if (delegate == null) {
            return
        }
        for (event in eventQueue) {
            when (event) {
                is EndOfStreamEvent -> delegate?.endOfStream()
                is ErrorEvent -> {
                    val errorEvent = event as ErrorEvent
                    delegate?.error(errorEvent.code, errorEvent.message, errorEvent.details)
                }
                else -> delegate?.success(event)
            }
        }
        eventQueue.clear()
    }

    private class EndOfStreamEvent

    private class ErrorEvent internal constructor(internal var code: String, internal var message: String, internal var details: Any)
}