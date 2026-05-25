// Version 4

import QtQuick

QtObject {
	readonly property string _base64Alphabet: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	property string configKey
	readonly property string configValue: configKey ? plasmoid.configuration[configKey] : ""
	property variant value: { return {} }
	property variant defaultValue: { return {} }
	property bool writing: false
	property bool loadOnConfigChange: true
	signal loaded()

	Component.onCompleted: {
		load()
	}

	onConfigValueChanged: {
		if (loadOnConfigChange && !writing) {
			load()
		}
	}

	onDefaultValueChanged: {
		if (configValue === '') { // Optimization
			load()
		}
	}

	function getBase64Json(key, defaultValue) {
		if (configValue === '') {
			return defaultValue
		}
		var bytes = base64ToBytes(configValue)
		var val = utf8BytesToString(bytes)
		val = JSON.parse(val)
		return val
	}

	function setBase64Json(key, data) {
		var val = JSON.stringify(data)
		val = bytesToBase64(stringToUtf8Bytes(val))
		writing = true
		plasmoid.configuration[key] = val
		writing = false
	}

	function stringToUtf8Bytes(str) {
		if (typeof TextEncoder !== "undefined") {
			return new TextEncoder().encode(str)
		}

		var utf8 = unescape(encodeURIComponent(str))
		var out = new Uint8Array(utf8.length)
		for (var i = 0; i < utf8.length; i++) {
			out[i] = utf8.charCodeAt(i)
		}
		return out
	}

	function utf8BytesToString(bytes) {
		if (typeof TextDecoder !== "undefined") {
			return new TextDecoder("utf-8").decode(bytes)
		}

		var bin = ""
		for (var i = 0; i < bytes.length; i++) {
			bin += String.fromCharCode(bytes[i])
		}
		return decodeURIComponent(escape(bin))
	}

	function bytesToBase64(bytes) {
		var out = ""
		for (var i = 0; i < bytes.length; i += 3) {
			var b1 = bytes[i]
			var b2 = i + 1 < bytes.length ? bytes[i + 1] : 0
			var b3 = i + 2 < bytes.length ? bytes[i + 2] : 0
			var n = (b1 << 16) | (b2 << 8) | b3

			out += _base64Alphabet[(n >> 18) & 63]
			out += _base64Alphabet[(n >> 12) & 63]
			out += i + 1 < bytes.length ? _base64Alphabet[(n >> 6) & 63] : "="
			out += i + 2 < bytes.length ? _base64Alphabet[n & 63] : "="
		}
		return out
	}

	function base64ToBytes(base64) {
		var clean = (base64 || "").replace(/\s+/g, "")
		if (clean.length === 0) {
			return new Uint8Array(0)
		}

		var padding = 0
		if (clean.charAt(clean.length - 1) === "=") {
			padding++
		}
		if (clean.charAt(clean.length - 2) === "=") {
			padding++
		}

		var byteLength = (clean.length * 3 >> 2) - padding
		var out = new Uint8Array(byteLength)
		var outIndex = 0

		for (var i = 0; i < clean.length; i += 4) {
			var c1 = _base64Alphabet.indexOf(clean.charAt(i))
			var c2 = _base64Alphabet.indexOf(clean.charAt(i + 1))
			var c3 = clean.charAt(i + 2) === "=" ? 0 : _base64Alphabet.indexOf(clean.charAt(i + 2))
			var c4 = clean.charAt(i + 3) === "=" ? 0 : _base64Alphabet.indexOf(clean.charAt(i + 3))

			var n = (c1 << 18) | (c2 << 12) | (c3 << 6) | c4
			if (outIndex < byteLength) {
				out[outIndex++] = (n >> 16) & 255
			}
			if (outIndex < byteLength) {
				out[outIndex++] = (n >> 8) & 255
			}
			if (outIndex < byteLength) {
				out[outIndex++] = n & 255
			}
		}

		return out
	}

	function set(obj) {
		setBase64Json(configKey, obj)
	}

	function setItemProperty(key1, key2, val) {
		var item = value[key1] || {}
		item[key2] = val
		value[key1] = item
		set(value)
		valueChanged()
	}

	function getItemProperty(key1, key2, def) {
		var item = value[key1] || {}
		return typeof item[key2] !== "undefined" ? item[key2] : def
	}

	function load() {
		// console.log('load')
		// console.log('configKey', configKey)
		// console.log('plasmoid.configuration[key]', plasmoid.configuration[configKey])
		value = getBase64Json(configKey, defaultValue)
		loaded()
	}

	function save() {
		// console.log('save')
		// console.log('configKey', configKey)
		// console.log('plasmoid.configuration[key]', plasmoid.configuration[configKey])
		setBase64Json(configKey, value || defaultValue)
	}

	onValueChanged: {
		// console.log('onValueChanged', configKey, value)
	}
}
