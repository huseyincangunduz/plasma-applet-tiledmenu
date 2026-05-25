import QtQuick
import QtQuick.Layouts
import "lib" as Lib

Item {
	id: presetTileButton
	Layout.fillWidth: parent.width
	Layout.preferredHeight: image.paintedHeight

	visible: source
	property QtObject xdgUserDir: Lib.XdgUserDir {}
	property alias source: image.source
	property string filename: 'temp.jpg'
	property int w: 0
	property int h: 0

	Image {
		id: image
		anchors.centerIn: parent
		width: Math.min(parent.width, sourceSize.width)

		fillMode: Image.PreserveAspectFit
	}

	HoverOutlineEffect {
		id: hoverOutlineEffect
		anchors.fill: image
		hoverRadius: Math.min(width, height)
		property alias control: mouseArea
	}

	MouseArea {
		id: mouseArea
		anchors.fill: image
		hoverEnabled: true
		acceptedButtons: Qt.LeftButton
		cursorShape: Qt.ArrowCursor
		
		onClicked: presetTileButton.select()
	}

	function getDownloadDir() {
		// Allow users to override where preset images are cached.
		var configuredDir = '' + plasmoid.configuration.presetTileCacheDir
		if (!configuredDir || configuredDir == 'undefined') {
			var homeDir = '' + xdgUserDir.home
			if (homeDir.indexOf('file://') == 0) {
				homeDir = homeDir.substr('file://'.length)
			}
			configuredDir = homeDir + '/.cache'
			plasmoid.configuration.presetTileCacheDir = configuredDir
		}

		if (configuredDir.indexOf('file://') == 0) {
			configuredDir = configuredDir.substr('file://'.length)
		}
		return configuredDir

		// TODO: Download to ~/.local/share since it's hidden.
		// Note, this folder does not exist! So we need to create it somehow.
		// Maybe we could run `mkdir -p /path/to/folder` using the exec dataengine.

		// Requires: import Qt.labs.platform 1.0
		// ~/.local/share/
		// var localDownloadDir = StandardPaths.writableLocation(StandardPaths.GenericDataLocation)
		// console.log('localDownloadDir', localDownloadDir)

		// Remove file:// URL scheme
		// localFilepath = localDownloadDir.substr('file://'.length)

		// ~/.local/share/plasma_com.github.zren.tiledmenu
		// var tiledMenuDir = localDownloadDir + '/' + 'plasma_' + plasmoid.pluginName
		// console.log('tiledMenuDir', tiledMenuDir)
		// return tiledMenuDir
	}

	function resizeTile() {
		var sizeChanged = false
		if (presetTileButton.w > 0) {
			appObj.tile.w = presetTileButton.w
			sizeChanged = true
		}
		if (presetTileButton.h > 0) {
			appObj.tile.h = presetTileButton.h
			sizeChanged = true
		}
		if (sizeChanged) {
			appObj.tileChanged()
			tileGrid.tileModelChanged()
		}
	}

	function setTileBackgroundImage(filepath) {
		backgroundImageField.text = filepath
		labelField.checked = false
		iconField.checked = false
	}

	function select() {
		logger.debug('select', source)

		var sourceFilepath = '' + source // cast to string

		var isLocalFilepath = sourceFilepath.indexOf('file://') == 0 || sourceFilepath.indexOf('/') == 0
		if (isLocalFilepath) {
			presetTileButton.setTileBackgroundImage(source)
			presetTileButton.resizeTile()
		} else {
			var tiledMenuDir = getDownloadDir()
			if (tiledMenuDir[tiledMenuDir.length - 1] != '/') {
				tiledMenuDir += '/'
			}
			var localFilepath = tiledMenuDir + filename
			if (localFilepath.indexOf('file://') == 0) {
				localFilepath = localFilepath.substr('file://'.length)
			}

			logger.debug('localFilepath', localFilepath)

			// Save tile image to file
			logger.debug('grabToImage.start')
			image.grabToImage(function(result){
				logger.debug('grabToImage.done', result, result.url)
				var saved = result.saveToFile(localFilepath)
				logger.debug('saveToFile', saved, localFilepath)
				if (saved) {
					presetTileButton.setTileBackgroundImage(localFilepath)
				} else {
					// Keep using the remote URL if local save fails.
					presetTileButton.setTileBackgroundImage(source)
				}
				presetTileButton.resizeTile()
			}, image.sourceSize)
		}
	}

}
