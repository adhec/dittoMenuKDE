/***************************************************************************
 *   Copyright (C) 2014 by Weng Xuetian <wengxt@gmail.com>
 *   Copyright (C) 2013-2017 by Eike Hein <hein@kde.org>                   *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 ***************************************************************************/

import QtQuick 2.4
import QtQuick.Layouts 1.1
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.components 3.0 as PlasmaComponents3

import org.kde.plasma.extras 2.0 as PlasmaExtras

import org.kde.plasma.private.kicker 0.1 as Kicker
import org.kde.kcoreaddons 1.0 as KCoreAddons // kuser
import org.kde.plasma.private.shell 2.0

import org.kde.kwindowsystem 1.0
import QtGraphicalEffects 1.0
import org.kde.kquickcontrolsaddons 2.0
import org.kde.plasma.private.quicklaunch 1.0

import QtQuick.Controls 2.1

Item{

    id: main
    property int sizeImage: units.iconSizes.large * 2

    onVisibleChanged: {
        root.visible = !root.visible
    }

    PlasmaCore.Dialog {
        id: root

        objectName: "popupWindow"
        flags: Qt.Window
        location: PlasmaCore.Types.Floating
        hideOnWindowDeactivate: true

        property int iconSize: units.iconSizes.large
        property int cellSize: iconSize
                               + units.gridUnit * 2
                               + (2 * Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom,
                                               highlightItemSvg.margins.left + highlightItemSvg.margins.right))
        property bool searching: (searchField.text != "")


        onVisibleChanged: {
            reset();
            if (visible) {
                var pos = popupPosition(width, height);
                x = pos.x;
                y = pos.y;
                requestActivate();
                reset();
                animation1.start()
            }else{
                focusScope.opacity = 0
            }
        }

        onHeightChanged: {
            var pos = popupPosition(width, height);
            x = pos.x;
            y = pos.y;
        }

        onWidthChanged: {
            var pos = popupPosition(width, height);
            x = pos.x;
            y = pos.y;
        }

        onSearchingChanged: {
            if (root.searching) {
                pageList.model = runnerModel;
                paginationBar.model = runnerModel;
            } else {
                reset();
            }
        }


        function reset() {

            if (!root.searching) {
                pageList.model = rootModel.modelForRow(0);
                paginationBar.model = rootModel.modelForRow(0);
            }
            searchField.text = "";
            pageListScrollArea.focus = true;
            pageList.currentIndex = plasmoid.configuration.showFavoritesFirst ? 0 : 1;
            //pageList.currentItem.itemGrid.currentIndex = -1;
        }

        function popupPosition(width, height) {
            var screenAvail = plasmoid.availableScreenRect;
            var screenGeom = plasmoid.screenGeometry;

            var screen = Qt.rect(screenAvail.x + screenGeom.x,
                                 screenAvail.y + screenGeom.y,
                                 screenAvail.width,
                                 screenAvail.height);


            var offset = units.largeSpacing * 0.5;

            // Fall back to bottom-left of screen area when the applet is on the desktop or floating.
            var x = offset;
            var y = screen.height - height - offset;
            var appletTopLeft;
            var horizMidPoint;
            var vertMidPoint;


            if (plasmoid.configuration.displayPosition === 1) {
                horizMidPoint = screen.x + (screen.width / 2);
                vertMidPoint = screen.y + (screen.height / 2);
                x = horizMidPoint - width / 2;
                y = vertMidPoint - height / 2;
            } else if (plasmoid.configuration.displayPosition === 2) {
                horizMidPoint = screen.x + (screen.width / 2);
                vertMidPoint = screen.y + (screen.height / 2);
                x = horizMidPoint - width / 2;
                y = screen.height - height - offset - panelSvg.margins.top;
            } else if (plasmoid.location === PlasmaCore.Types.BottomEdge) {
                horizMidPoint = screen.x + (screen.width / 2);
                appletTopLeft = parent.mapToGlobal(0, 0);
                x = (appletTopLeft.x < horizMidPoint) ? screen.x + offset : (screen.x + screen.width) - width - offset;
                y = screen.height - height - offset - panelSvg.margins.top;
            } else if (plasmoid.location === PlasmaCore.Types.TopEdge) {
                horizMidPoint = screen.x + (screen.width / 2);
                var appletBottomLeft = parent.mapToGlobal(0, parent.height);
                x = (appletBottomLeft.x < horizMidPoint) ? screen.x + offset : (screen.x + screen.width) - width - offset;
                y = parent.height + panelSvg.margins.bottom + offset;
                y = y + (plasmoid.configuration.viewUser ? main.sizeImage*0.5 : 0);
            } else if (plasmoid.location === PlasmaCore.Types.LeftEdge) {
                vertMidPoint = screen.y + (screen.height / 2);
                appletTopLeft = parent.mapToGlobal(0, 0);
                x = parent.width + panelSvg.margins.right + offset;
                y = (appletTopLeft.y < vertMidPoint) ? screen.y + offset : (screen.y + screen.height) - height - offset;
                y = y + (plasmoid.configuration.viewUser ? main.sizeImage*0.5 : 0);
            } else if (plasmoid.location === PlasmaCore.Types.RightEdge) {
                vertMidPoint = screen.y + (screen.height / 2);
                appletTopLeft = parent.mapToGlobal(0, 0);
                x = appletTopLeft.x - panelSvg.margins.left - offset - width;
                y = (appletTopLeft.y < vertMidPoint) ? screen.y + offset : (screen.y + screen.height) - height - offset;
                y = y + (plasmoid.configuration.viewUser ? main.sizeImage*0.5 : 0);
            }

            return Qt.point(x, y);
        }


        FocusScope {

            id: focusScope
            Layout.minimumWidth:  (root.cellSize *  plasmoid.configuration.numberColumns)
            Layout.maximumWidth:  (root.cellSize *  plasmoid.configuration.numberColumns)
            Layout.minimumHeight: (root.cellSize *  plasmoid.configuration.numberRows) + searchField.implicitHeight + paginationBar.height + (plasmoid.configuration.viewUser ? main.sizeImage*0.5 : units.largeSpacing * 1.5 ) +  units.largeSpacing * 5
            Layout.maximumHeight: (root.cellSize *  plasmoid.configuration.numberRows) + searchField.implicitHeight + paginationBar.height + (plasmoid.configuration.viewUser ? main.sizeImage*0.5 : units.largeSpacing * 1.5 ) +  units.largeSpacing * 5

            focus: true
            opacity: 0

            KCoreAddons.KUser {   id: kuser  }
            Logic {   id: logic }


            OpacityAnimator { id: animation1; target: focusScope; from: 0; to: 1; }

            PlasmaCore.DataSource {
                id: pmEngine
                engine: "powermanagement"
                connectedSources: ["PowerDevil", "Sleep States"]
                function performOperation(what) {
                    var service = serviceForSource("PowerDevil")
                    var operation = service.operationDescription(what)
                    service.startOperationCall(operation)
                }
            }

            PlasmaCore.DataSource {
                id: executable
                engine: "executable"
                connectedSources: []
                onNewData: {
                    var exitCode = data["exit code"]
                    var exitStatus = data["exit status"]
                    var stdout = data["stdout"]
                    var stderr = data["stderr"]
                    exited(sourceName, exitCode, exitStatus, stdout, stderr)
                    disconnectSource(sourceName)
                }
                function exec(cmd) {
                    if (cmd) {
                        connectSource(cmd)
                    }
                }
                signal exited(string cmd, int exitCode, int exitStatus, string stdout, string stderr)
            }

            PlasmaComponents.Highlight {
                id: delegateHighlight
                visible: false
                z: -1 // otherwise it shows ontop of the icon/label and tints them slightly
            }

            PlasmaExtras.Heading {
                id: dummyHeading
                visible: false
                width: 0
                level: 5
            }

            TextMetrics {
                id: headingMetrics
                font: dummyHeading.font
            }

            ActionMenu {
                id: actionMenu
                onActionClicked: visualParent.actionTriggered(actionId, actionArgument)
                onClosed: {
                    if (pageList.currentItem) {
                        pageList.currentItem.itemGrid.currentIndex = -1;
                    }
                }
            }




            PlasmaCore.FrameSvgItem {
                id : headingSvg
                width: parent.width + backgroundSvg.margins.right + backgroundSvg.margins.left
                height:  root.cellSize * plasmoid.configuration.numberRows  + paginationBar.height + units.largeSpacing * 2 + backgroundSvg.margins.bottom - 1
                y: pageListScrollArea.y - units.largeSpacing
                x: - backgroundSvg.margins.left
                imagePath: "widgets/plasmoidheading"
                prefix: "footer"
                opacity: 0.7
            }

            RowLayout{
                id: rowTop
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: units.smallSpacing
                    topMargin: units.largeSpacing / 2
                }

                PlasmaComponents3.ToolButton {
                    icon.name:  "configure"
                    onClicked: logic.openUrl("file:///usr/share/applications/systemsettings.desktop")
                    ToolTip.delay: 1000
                    ToolTip.timeout: 1000
                    ToolTip.visible: hovered
                    ToolTip.text: i18n("System Preferences")
                }

                Item{
                    Layout.fillWidth: true
                }

                PlasmaComponents3.ToolButton {
                    icon.name:  "user-home"
                    onClicked: logic.openUrl("file:///usr/share/applications/org.kde.dolphin.desktop")
                    ToolTip.delay: 1000
                    ToolTip.timeout: 1000
                    ToolTip.visible: hovered
                    ToolTip.text: i18n("User Home")
                }

                PlasmaComponents3.ToolButton {
                    icon.name:  "system-lock-screen"
                    onClicked: pmEngine.performOperation("lockScreen")
                    enabled: pmEngine.data["Sleep States"]["LockScreen"]
                    ToolTip.delay: 1000
                    ToolTip.timeout: 1000
                    ToolTip.visible: hovered
                    ToolTip.text: i18nc("@action", "Lock Screen")
                }

                PlasmaComponents3.ToolButton {
                    icon.name:   "system-shutdown"
                    onClicked: pmEngine.performOperation("requestShutDown")
                    ToolTip.delay: 1000
                    ToolTip.timeout: 1000
                    ToolTip.visible: hovered
                    ToolTip.text: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Leave ... ")
                }
            }

            PlasmaExtras.Heading {
                anchors {
                    top: rowTop.bottom
                    topMargin: units.largeSpacing
                    horizontalCenter: parent.horizontalCenter
                }
                horizontalAlignment: Text.AlignHCenter
                level: 1
                color: theme.textColor
                text: i18n("Hi, ")+ kuser.fullName
                font.bold: true
                visible: plasmoid.configuration.viewUser
            }

            PlasmaComponents3.TextField {
                id: searchField
                anchors{
                    top: plasmoid.configuration.viewUser ? parent.top : rowTop.bottom
                    topMargin: plasmoid.configuration.viewUser ? units.largeSpacing*2  + sizeImage/2 : units.largeSpacing/2
                    left: parent.left
                    right: parent.right
                    leftMargin:  units.largeSpacing * 3
                    rightMargin: units.largeSpacing * 3
                }

                width: parent.width - units.iconSizes.large
                placeholderText: i18n("Type here to search ...")
                leftPadding: units.largeSpacing + units.iconSizes.small
                text: ""
                //clearButtonShown: true  // TODO: kubuntu 20.04
                onTextChanged: {
                    runnerModel.query = text;
                }

                Keys.onPressed: {
                    if (event.key == Qt.Key_Down) {
                        event.accepted = true;
                        pageList.currentItem.itemGrid.tryActivate(0, 0);
                    } else if (event.key == Qt.Key_Right) {
                        if (cursorPosition == length) {
                            event.accepted = true;

                            if (pageList.currentItem.itemGrid.currentIndex == -1) {
                                pageList.currentItem.itemGrid.tryActivate(0, 0);
                            } else {
                                pageList.currentItem.itemGrid.tryActivate(0, 1);
                            }
                        }
                    } else if (event.key == Qt.Key_Return || event.key == Qt.Key_Enter) {
                        if (text != "" && pageList.currentItem.itemGrid.count > 0) {
                            event.accepted = true;
                            pageList.currentItem.itemGrid.tryActivate(0, 0);
                            pageList.currentItem.itemGrid.model.trigger(0, "", null);
                            root.visible = false;
                        }
                    } else if (event.key == Qt.Key_Tab) {
                        event.accepted = true;
                    } else if (event.key == Qt.Key_Backtab) {
                        event.accepted = true;
                        if (!root.searching) {
                            filterList.forceActiveFocus();
                        }
                    }
                }

                function backspace() {
                    if (!root.visible) {
                        return;
                    }

                    focus = true;
                    text = text.slice(0, -1);
                }

                function appendText(newText) {
                    if (!root.visible) {
                        return;
                    }
                    focus = true;
                    text = text + newText;
                }
            }

            PlasmaCore.IconItem {
                source: 'search'
                anchors {
                    left: searchField.left
                    verticalCenter: searchField.verticalCenter
                    leftMargin: units.smallSpacing * 2

                }
                height: units.iconSizes.small
                width: height
            }


            PlasmaExtras.ScrollArea {
                id: pageListScrollArea

                anchors {
                    top: searchField.bottom
                    topMargin: units.largeSpacing * 2
                    left: parent.left
                    right: parent.right
                    bottomMargin: units.smallSpacing
                }

                width: (root.cellSize * plasmoid.configuration.numberColumns)
                height: (root.cellSize * plasmoid.configuration.numberRows)
                focus: true;
                frameVisible: false;
                horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
                verticalScrollBarPolicy: Qt.ScrollBarAlwaysOff

                ListView {
                    id: pageList

                    anchors.fill: parent

                    orientation: Qt.Horizontal
                    snapMode: ListView.SnapOneItem
                    highlightMoveDuration: 400
                    highlightFollowsCurrentItem: true

                    currentIndex: (root.searching || plasmoid.configuration.showFavoritesFirst) ? 0 : 1


                    onCurrentIndexChanged: {
                        positionViewAtIndex(currentIndex, ListView.Contain);
                    }

                    onCurrentItemChanged: {
                        if (!currentItem) {
                            return;
                        }

                        currentItem.itemGrid.focus = true;
                    }

                    onModelChanged: {
                        //currentIndex = 0;
                        currentIndex = (root.searching || plasmoid.configuration.showFavoritesFirst) ? 0 : 1;

                    }



                    onFlickingChanged: {
                        if (!flicking) {
                            var pos = mapToItem(contentItem, root.width / 2, root.height / 2);
                            var itemIndex = indexAt(pos.x, pos.y);
                            currentIndex = itemIndex;
                        }
                    }

                    function cycle() {
                        enabled = false;
                        enabled = true;
                    }

                    function activateNextPrev(next) {
                        if (next) {
                            var newIndex = pageList.currentIndex + 1;

                            if (newIndex == pageList.count) {
                                newIndex = 0;
                            }

                            pageList.currentIndex = newIndex;
                        } else {
                            var newIndex = pageList.currentIndex - 1;

                            if (newIndex < 0) {
                                newIndex = (pageList.count - 1);
                            }

                            pageList.currentIndex = newIndex;
                        }
                    }

                    delegate: Item {
                        width:  root.cellSize * plasmoid.configuration.numberColumns
                        height: root.cellSize * plasmoid.configuration.numberRows
                        property Item itemGrid: gridView

                        ItemGridView {
                            id: gridView

                            anchors.fill: parent

                            cellWidth: root.cellSize
                            cellHeight: root.cellSize

                            horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
                            verticalScrollBarPolicy: Qt.ScrollBarAlwaysOff
                            iconSize: root.iconSize

                            dragEnabled: (index == 0)

                            model: root.searching ? runnerModel.modelForRow(index) : rootModel.modelForRow(0).modelForRow(index)

                            onCurrentIndexChanged: {
                                if (currentIndex != -1 && !root.searching) {
                                    pageListScrollArea.focus = true;
                                    focus = true;
                                }
                            }

                            onCountChanged: {
                                if (root.searching && index == 0) {
                                    currentIndex = 0;
                                }
                            }

                            onKeyNavUp: {
                                currentIndex = -1;
                                searchField.focus = true;
                            }

                            onKeyNavRight: {
                                var newIndex = pageList.currentIndex + 1;
                                var cRow = currentRow();

                                if (newIndex === pageList.count) {
                                    newIndex = 0;
                                }

                                pageList.currentIndex = newIndex;
                                pageList.currentItem.itemGrid.tryActivate(cRow, 0);
                            }

                            onKeyNavLeft: {
                                var newIndex = pageList.currentIndex - 1;
                                var cRow = currentRow();

                                if (newIndex < 0) {
                                    newIndex = (pageList.count - 1);
                                }

                                pageList.currentIndex = newIndex;
                                pageList.currentItem.itemGrid.tryActivate(cRow, 5);
                            }
                        }

                        Kicker.WheelInterceptor {
                            anchors.fill: parent
                            z: 1

                            property int wheelDelta: 0

                            function scrollByWheel(wheelDelta, eventDelta) {
                                // magic number 120 for common "one click"
                                // See: http://qt-project.org/doc/qt-5/qml-qtquick-wheelevent.html#angleDelta-prop
                                wheelDelta += eventDelta;

                                var increment = 0;

                                while (wheelDelta >= 120) {
                                    wheelDelta -= 120;
                                    increment++;
                                }

                                while (wheelDelta <= -120) {
                                    wheelDelta += 120;
                                    increment--;
                                }

                                while (increment != 0) {
                                    pageList.activateNextPrev(increment < 0);
                                    increment += (increment < 0) ? 1 : -1;
                                }

                                return wheelDelta;
                            }

                            onWheelMoved: {
                                wheelDelta = scrollByWheel(wheelDelta, delta.y);
                            }
                        }
                    }
                }
            }

            ListView {
                id: paginationBar

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                    bottomMargin: units.largeSpacing/2
                }

                width: 100//model.count * units.iconSizes.small
                height: units.iconSizes.small

                orientation: Qt.Horizontal
                delegate: Item {
                    width: units.iconSizes.small
                    height: width

                    Rectangle {
                        id: pageDelegate

                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            verticalCenter: parent.verticalCenter
                        }

                        width: parent.width  * 0.7
                        height: width

                        property bool isCurrent: (pageList.currentIndex == index)

                        radius: width / 2

                        color: theme.textColor
                        opacity: 0.3

                        Behavior on width { SmoothedAnimation { duration: units.longDuration; velocity: 0.01 } }
                        Behavior on opacity { SmoothedAnimation { duration: units.longDuration; velocity: 0.01 } }

                        states: [
                            State {
                                when: pageDelegate.isCurrent
                                PropertyChanges { target: pageDelegate; width: parent.width * 0.5; }
                                PropertyChanges { target: pageDelegate; opacity: 1 }
                            }
                        ]
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: pageList.currentIndex = index;

                        property int wheelDelta: 0

                        function scrollByWheel(wheelDelta, eventDelta) {
                            // magic number 120 for common "one click"
                            // See: http://qt-project.org/doc/qt-5/qml-qtquick-wheelevent.html#angleDelta-prop
                            wheelDelta += eventDelta;

                            var increment = 0;

                            while (wheelDelta >= 120) {
                                wheelDelta -= 120;
                                increment++;
                            }

                            while (wheelDelta <= -120) {
                                wheelDelta += 120;
                                increment--;
                            }

                            while (increment != 0) {
                                pageList.activateNextPrev(increment < 0);
                                increment += (increment < 0) ? 1 : -1;
                            }

                            return wheelDelta;
                        }

                        onWheel: {
                            wheelDelta = scrollByWheel(wheelDelta, wheel.angleDelta.y);
                        }
                    }
                }
            }

            Keys.onPressed: {
                if (event.key == Qt.Key_Escape) {
                    event.accepted = true;

                    if (root.searching) {
                        reset();
                    } else {
                        root.visible = false;
                    }

                    return;
                }

                if (searchField.focus) {
                    return;
                }

                if (event.key == Qt.Key_Backspace) {
                    event.accepted = true;
                    searchField.backspace();
                } else if (event.key == Qt.Key_Tab || event.key == Qt.Key_Backtab) {
                    if (pageListScrollArea.focus == true && pageList.currentItem.itemGrid.currentIndex == -1) {
                        event.accepted = true;
                        pageList.currentItem.itemGrid.tryActivate(0, 0);
                    }
                } else if (event.text != "") {
                    event.accepted = true;
                    searchField.appendText(event.text);
                }
            }

        }

        Component.onCompleted: {
            kicker.reset.connect(reset);
            dragHelper.dropped.connect(pageList.cycle);
            reset();
        }
    }



    PlasmaCore.Dialog {
        id: dialog

        width:  main.sizeImage
        height: width

        visible: root.visible

        x: root.x + root.width/2 - sizeImage/2
        y: root.y

        objectName: "popupWindowIcon"
        flags: Qt.WindowStaysOnTopHint
        location: PlasmaCore.Types.Floating
        hideOnWindowDeactivate: false
        backgroundHints: PlasmaCore.Dialog.NoBackground

        mainItem:  Rectangle{
            width: main.sizeImage
            height: width
            color: 'transparent'

            Image {
                id: iconUser
                anchors.centerIn: parent
                source:  kuser.faceIconUrl.toString() || "user-identity"
                cache: false
                visible: source !== "" && plasmoid.configuration.viewUser
                sourceSize.width: main.sizeImage
                sourceSize.height: main.sizeImage

                fillMode: Image.PreserveAspectFit
                // Crop the avatar to fit in a circle, like the lock and login screens
                // but don't on software rendering where this won't render
                layer.enabled:true // iconUser.GraphicsInfo.api !== GraphicsInfo.Software
                layer.effect: OpacityMask {
                    // this Rectangle is a circle due to radius size
                    maskSource: Rectangle {
                        width: main.sizeImage
                        height: width
                        radius: height / 2
                        visible: false
                    }
                }
                state: "hide"
                states: [
                    State {
                        name: "show"
                        when: dialog.visible
                        PropertyChanges { target: dialog; y: root.y - sizeImage*0.5; opacity: 1}
                    },
                    State {
                        name: "hide"
                        when: !dialog.visible
                        PropertyChanges { target: dialog; y: root.y ; opacity: 0 }
                    }
                ]
                transitions: Transition {
                    PropertyAnimation { properties: "y,opacity"; }
                }
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    onClicked: KCMShell.openSystemSettings("kcm_users")
                    visible: KCMShell.authorize("user_manager.desktop").length > 0
                }
            }
        }
    }
}
