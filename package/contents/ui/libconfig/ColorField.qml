// Version 8

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs as QtDialogs
import QtQuick.Window
import org.kde.kirigami as Kirigami


QQC2.TextField {
	id: colorField
	font.family: "monospace"
	readonly property string defaultText: "#AARRGGBB"
	placeholderText: defaultColor ? defaultColor : defaultText

	onTextChanged: {
		// Make sure the text is:
		//   Empty (use default)
		//   or #123 or #112233 or #11223344 before applying the color.
		if (text.length === 0
			|| (text.indexOf('#') === 0 && (text.length == 4 || text.length == 7 || text.length == 9))
		) {
			colorField.value = text
		}
	}

	property bool showAlphaChannel: true
	property bool showPreviewBg: true

	property string configKey: ''
	property string defaultColor: ''
	property string value: {
		if (configKey) {
			return plasmoid.configuration[configKey]
		} else {
			return "#000"
		}
	}

	readonly property color defaultColorValue: defaultColor
	readonly property color valueColor: {
		if (value == '' && defaultColor) {
			return defaultColor
		} else {
			return value
		}
	}

	onValueChanged: {
		if (!activeFocus) {
			text = colorField.value
		}
		if (configKey) {
			if (value == defaultColorValue) {
				plasmoid.configuration[configKey] = ""
			} else {
				plasmoid.configuration[configKey] = value
			}
		}
	}

	leftPadding: rightPadding + mouseArea.height + rightPadding

	FontMetrics {
		id: fontMetrics
		font.family: colorField.font.family
		font.italic: colorField.font.italic
		font.pointSize: colorField.font.pointSize
		font.pixelSize: colorField.font.pixelSize
		font.weight: colorField.font.weight
	}
	readonly property int defaultWidth: Math.ceil(fontMetrics.advanceWidth(defaultText))
	implicitWidth: rightPadding + Math.max(defaultWidth, contentWidth) + leftPadding

	MouseArea {
		id: mouseArea
		anchors.leftMargin: parent.rightPadding
		anchors.topMargin: parent.topPadding
		anchors.bottomMargin: parent.bottomPadding
		anchors.left: parent.left
		anchors.top: parent.top
		anchors.bottom: parent.bottom
		width: height
		hoverEnabled: true
		cursorShape: Qt.PointingHandCursor

		onClicked: dialogLoader.active = true

		// Color Preview Circle
		Rectangle {
			id: previewBgGradient
			visible: colorField.showPreviewBg
			anchors.fill: parent
			radius: width / 2
			clip: true
			color: "white"

			Rectangle {
				width: parent.width / 2
				height: parent.height / 2
				x: parent.width / 2
				color: "#cccccc"
			}
			Rectangle {
				width: parent.width / 2
				height: parent.height / 2
				y: parent.height / 2
				color: "#cccccc"
			}
		}
		Rectangle {
			id: previewFill
			anchors.fill: parent
			color: colorField.valueColor
			border.width: 1 * Screen.devicePixelRatio
			border.color: Kirigami.ColorUtils.linearInterpolation(color, Kirigami.Theme.textColor, 0.5)
			radius: width / 2
		}
	}

	Loader {
		id: dialogLoader
		active: false
		sourceComponent: QtDialogs.ColorDialog {
			id: dialog
			visible: true
			modality: Qt.WindowModal
			options: colorField.showAlphaChannel ? QtDialogs.ColorDialog.ShowAlphaChannel : 0
			selectedColor: colorField.valueColor
			onSelectedColorChanged: {
				if (visible) {
					colorField.text = selectedColor
				}
			}
			onAccepted: {
				colorField.text = selectedColor
				dialogLoader.active = false
			}
			onRejected: {
				// This event is also triggered when the user clicks outside the popup modal.
				// TODO Find a way to only trigger when Cancel is clicked.
				colorField.text = initColor
				dialogLoader.active = false
			}

			property color initColor
			Component.onCompleted: {
				initColor = colorField.valueColor
			}
		}
	}
}
