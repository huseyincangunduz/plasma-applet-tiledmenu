// Version 1

import QtQuick
import QtQuick.Controls as QQC2

QQC2.TextField {
	id: textField

	property string configKey: ''
	readonly property string configValue: configKey ? plasmoid.configuration[configKey] : ""
	onConfigValueChanged: {
		if (!activeFocus && text !== configValue) {
			text = configValue
		}
	}

	text: configValue
	onTextChanged: serializeTimer.restart()

	Timer { // throttle
		id: serializeTimer
		interval: 300
		onTriggered: {
			if (configKey && plasmoid.configuration[configKey] !== textField.text) {
				plasmoid.configuration[configKey] = textField.text
			}
		}
	}
}
