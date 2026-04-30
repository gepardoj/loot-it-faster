package listener

import "../level"
import rl "vendor:raylib"

EventType :: enum u8 {
	DRAGGING_STARTED,
	DRAGGING,
	DRAGGING_ENDED,
}

ListenerCtx :: struct {
	camera:      ^rl.Camera,
	chest_model: ^rl.Model,
	chests:      ^[dynamic]level.Chest,
}


StoredCallback :: struct {
	type: EventType,
	ctx:  rawptr,
	call: proc(ctx: rawptr, data: rawptr),
}

@(private)
_stored_callbacks: [dynamic]StoredCallback

init :: proc() {
	_stored_callbacks = make([dynamic]StoredCallback)
}

cleanup :: proc() {
	delete(_stored_callbacks)
}

subscribe :: proc(event_type: EventType, ctx: rawptr, callback: proc(ctx: rawptr, data: rawptr)) {
	append(&_stored_callbacks, StoredCallback{event_type, ctx, callback})
}

emit :: proc(event_type: EventType, data: rawptr) {
	for callback in _stored_callbacks {
		if callback.type == event_type do callback.call(callback.ctx, data)
	}
}
