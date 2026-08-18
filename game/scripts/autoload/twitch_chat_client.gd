extends Node
## Direct WebSocket connection to Twitch IRC (anonymous, read-only - no bot account
## or OAuth needed). This is the entire "bridge" for chat-controlled trainers: no
## separate process, no emulator scripting, because Godot is a normal PC app with
## a built-in WebSocket client.

signal chat_message(username: String, text: String)
signal connection_state_changed(connected: bool)

const IRC_URL := "wss://irc-ws.chat.twitch.tv:443"
const MAX_RECONNECT_DELAY := 30.0

var _socket := WebSocketPeer.new()
var _channel := ""
var _connected := false
var _reconnect_delay := 1.0
var _reconnect_timer := 0.0
var _should_run := false

var _vote_active := false
var _vote_choice_count := 0
var _vote_tally: Dictionary = {}              # username -> choice_index (latest vote wins)
var _choice_first_seen_order: Dictionary = {} # choice_index -> sequence number
var _vote_sequence := 0

func is_connected_to_chat() -> bool:
	return _connected

func connect_to_channel(channel: String) -> void:
	_channel = channel.to_lower()
	_should_run = true
	_reconnect_delay = 1.0
	_open_socket()

func disconnect_from_chat() -> void:
	_should_run = false
	_socket.close()
	_connected = false

func _open_socket() -> void:
	_socket = WebSocketPeer.new()
	var err := _socket.connect_to_url(IRC_URL)
	if err != OK:
		_queue_reconnect()

func _queue_reconnect() -> void:
	if not _should_run:
		return
	_reconnect_timer = _reconnect_delay
	_reconnect_delay = min(_reconnect_delay * 2.0, MAX_RECONNECT_DELAY)

func _process(delta: float) -> void:
	if _reconnect_timer > 0.0:
		_reconnect_timer -= delta
		if _reconnect_timer <= 0.0:
			_open_socket()
		return
	if not _should_run:
		return

	_socket.poll()
	var state := _socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		if not _connected:
			_connected = true
			_reconnect_delay = 1.0
			connection_state_changed.emit(true)
			_send_line("PASS SCHMOOPIIE")
			_send_line("NICK justinfan%d" % (randi() % 100000))
			_send_line("JOIN #%s" % _channel)
		while _socket.get_available_packet_count() > 0:
			_handle_packet(_socket.get_packet().get_string_from_utf8())
	elif state == WebSocketPeer.STATE_CLOSED:
		if _connected:
			_connected = false
			connection_state_changed.emit(false)
		_queue_reconnect()

func _send_line(line: String) -> void:
	_socket.send_text(line + "\r\n")

func _handle_packet(packet: String) -> void:
	for line in packet.split("\r\n"):
		if line == "":
			continue
		if line.begins_with("PING"):
			_send_line("PONG :tmi.twitch.tv")
			continue
		_maybe_parse_privmsg(line)

func _maybe_parse_privmsg(line: String) -> void:
	if not line.begins_with(":"):
		return
	var priv_idx := line.find(" PRIVMSG #")
	if priv_idx == -1:
		return
	var username := line.substr(1, priv_idx - 1).split("!")[0]
	var msg_idx := line.find(" :", priv_idx)
	if msg_idx == -1:
		return
	var text := line.substr(msg_idx + 2)
	chat_message.emit(username, text)
	if _vote_active:
		_register_vote(username, text)

func _register_vote(username: String, text: String) -> void:
	var trimmed := text.strip_edges()
	for i in range(_vote_choice_count):
		if trimmed == "!%d" % (i + 1):
			if not _choice_first_seen_order.has(i):
				_choice_first_seen_order[i] = _vote_sequence
				_vote_sequence += 1
			_vote_tally[username] = i
			return

## Runs a majority vote (chat types !1.."!N") for duration_sec seconds - one vote per
## user, their latest message counts, ties broken by whichever choice was voted for
## first. Resolves immediately with -1 if chat isn't connected, so callers always get
## an answer and can fall back to AI without hanging.
func run_vote(choice_count: int, duration_sec: float) -> int:
	if not _connected:
		return -1
	_vote_choice_count = choice_count
	_vote_tally.clear()
	_choice_first_seen_order.clear()
	_vote_sequence = 0
	_vote_active = true
	await get_tree().create_timer(duration_sec).timeout
	_vote_active = false
	return _tally_result()

func _tally_result() -> int:
	if _vote_tally.is_empty():
		return -1
	var counts: Dictionary = {}
	for username in _vote_tally:
		var choice: int = _vote_tally[username]
		counts[choice] = counts.get(choice, 0) + 1
	var best_choice := -1
	var best_count := -1
	var best_order := INF
	for choice in counts:
		var count: int = counts[choice]
		var order: int = _choice_first_seen_order[choice]
		if count > best_count or (count == best_count and order < best_order):
			best_count = count
			best_choice = choice
			best_order = order
	return best_choice
