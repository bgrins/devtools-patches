# HG changeset patch
# User Brian Grinstead <bgrinstead@mozilla.com>
# Parent  d551d37b9ad0dd1c8ad2e87c74344f623fc4b694

diff --git a/browser/base/content/browser.xhtml b/browser/base/content/browser.xhtml
--- a/browser/base/content/browser.xhtml
+++ b/browser/base/content/browser.xhtml
@@ -1,3 +1,1378 @@
-#define BROWSER_XHTML
-#include browser.xul
-#undef BROWSER_XHTML
+#filter substitution
+<?xml version="1.0"?>
+# -*- Mode: HTML -*-
+#
+# This Source Code Form is subject to the terms of the Mozilla Public
+# License, v. 2.0. If a copy of the MPL was not distributed with this
+# file, You can obtain one at http://mozilla.org/MPL/2.0/.
+
+<!-- The "global.css" stylesheet is imported first to allow other stylesheets to
+     override rules using selectors with the same specificity. This applies to
+     both "content" and "skin" packages, which bug 1385444 will unify later. -->
+<?xml-stylesheet href="chrome://global/skin/" type="text/css"?>
+
+<!-- While these stylesheets are defined in Toolkit, they are only used in the
+     main browser window, so we can load them here. Bug 1474241 is on file to
+     consider moving these widgets to the "browser" folder. -->
+<?xml-stylesheet href="chrome://global/content/tabprompts.css" type="text/css"?>
+<?xml-stylesheet href="chrome://global/skin/tabprompts.css" type="text/css"?>
+
+<?xml-stylesheet href="chrome://browser/content/browser.css" type="text/css"?>
+<?xml-stylesheet href="chrome://browser/content/tabbrowser.css" type="text/css"?>
+<?xml-stylesheet href="chrome://browser/content/downloads/downloads.css" type="text/css"?>
+<?xml-stylesheet href="chrome://browser/content/places/places.css" type="text/css"?>
+<?xml-stylesheet href="chrome://browser/content/usercontext/usercontext.css" type="text/css"?>
+<?xml-stylesheet href="chrome://browser/skin/" type="text/css"?>
+<?xml-stylesheet href="chrome://browser/skin/controlcenter/panel.css" type="text/css"?>
+<?xml-stylesheet href="chrome://browser/skin/customizableui/panelUI.css" type="text/css"?>
+<?xml-stylesheet href="chrome://browser/skin/downloads/downloads.css" type="text/css"?>
+<?xml-stylesheet href="chrome://browser/skin/searchbar.css" type="text/css"?>
+<?xml-stylesheet href="chrome://browser/skin/places/tree-icons.css" type="text/css"?>
+<?xml-stylesheet href="chrome://browser/skin/places/editBookmark.css" type="text/css"?>
+
+# All DTD information is stored in a separate file so that it can be shared by
+# hiddenWindowMac.xhtml.
+<!DOCTYPE window [
+#include browser-doctype.inc
+]>
+
+<window id="main-window"
+        xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
+        xmlns:svg="http://www.w3.org/2000/svg"
+        xmlns:html="http://www.w3.org/1999/xhtml"
+        xmlns:xul="http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul"
+        xmlns="http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul"
+        title="&mainWindow.title;"
+        title_normal="&mainWindow.title;"
+#ifdef XP_MACOSX
+        title_privatebrowsing="&mainWindow.title;&mainWindow.titlemodifiermenuseparator;&mainWindow.titlePrivateBrowsingSuffix;"
+        titledefault="&mainWindow.title;"
+        titlemodifier=""
+        titlemodifier_normal=""
+        titlemodifier_privatebrowsing="&mainWindow.titlePrivateBrowsingSuffix;"
+#else
+        title_privatebrowsing="&mainWindow.titlemodifier; &mainWindow.titlePrivateBrowsingSuffix;"
+        titlemodifier="&mainWindow.titlemodifier;"
+        titlemodifier_normal="&mainWindow.titlemodifier;"
+        titlemodifier_privatebrowsing="&mainWindow.titlemodifier; &mainWindow.titlePrivateBrowsingSuffix;"
+#endif
+#ifdef XP_WIN
+        chromemargin="0,2,2,2"
+#else
+        chromemargin="0,-1,-1,-1"
+#endif
+        tabsintitlebar="true"
+        titlemenuseparator="&mainWindow.titlemodifiermenuseparator;"
+        windowtype="navigator:browser"
+        macanimationtype="document"
+        screenX="4" screenY="4"
+        fullscreenbutton="true"
+        sizemode="normal"
+        retargetdocumentfocus="urlbar"
+        persist="screenX screenY width height sizemode"
+#ifdef BROWSER_XHTML
+        mozpersist=""
+#endif
+        >
+
+# All JS files which are needed by browser.xul and other top level windows to
+# support MacOS specific features *must* go into the global-scripts.inc file so
+# that they can be shared with macWindow.inc.xul.
+#include global-scripts.inc
+
+<script>
+  Services.scriptloader.loadSubScript("chrome://global/content/contentAreaUtils.js", this);
+  Services.scriptloader.loadSubScript("chrome://browser/content/browser-captivePortal.js", this);
+  Services.scriptloader.loadSubScript("chrome://browser/content/browser-contentblocking.js", this);
+#ifdef MOZ_DATA_REPORTING
+  Services.scriptloader.loadSubScript("chrome://browser/content/browser-data-submission-info-bar.js", this);
+#endif
+#ifndef MOZILLA_OFFICIAL
+  Services.scriptloader.loadSubScript("chrome://browser/content/browser-development-helpers.js", this);
+#endif
+  Services.scriptloader.loadSubScript("chrome://browser/content/browser-media.js", this);
+  Services.scriptloader.loadSubScript("chrome://browser/content/browser-pageActions.js", this);
+  Services.scriptloader.loadSubScript("chrome://browser/content/browser-plugins.js", this);
+  Services.scriptloader.loadSubScript("chrome://browser/content/browser-sidebar.js", this);
+  Services.scriptloader.loadSubScript("chrome://browser/content/browser-tabsintitlebar.js", this);
+  Services.scriptloader.loadSubScript("chrome://browser/content/tabbrowser.js", this);
+  Services.scriptloader.loadSubScript("chrome://browser/content/search/autocomplete-popup.js", this);
+  Services.scriptloader.loadSubScript("chrome://browser/content/search/searchbar.js", this);
+
+  window.onload = gBrowserInit.onLoad.bind(gBrowserInit);
+  window.onunload = gBrowserInit.onUnload.bind(gBrowserInit);
+  window.onclose = WindowIsClosing;
+
+  window.addEventListener("MozBeforeInitialXULLayout",
+    gBrowserInit.onBeforeInitialXULLayout.bind(gBrowserInit), { once: true });
+
+  // The listener of DOMContentLoaded must be set on window, rather than
+  // document, because the window can go away before the event is fired.
+  // In that case, we don't want to initialize anything, otherwise we
+  // may be leaking things because they will never be destroyed after.
+  window.addEventListener("DOMContentLoaded",
+    gBrowserInit.onDOMContentLoaded.bind(gBrowserInit), { once: true });
+</script>
+
+# All sets except for popupsets (commands, keys, and stringbundles)
+# *must* go into the browser-sets.inc file so that they can be shared with other
+# top level windows in macWindow.inc.xul.
+#include browser-sets.inc
+
+  <popupset id="mainPopupSet">
+    <menupopup id="tabContextMenu"
+               onpopupshowing="if (event.target == this) TabContextMenu.updateContextMenu(this);"
+               onpopuphidden="if (event.target == this) TabContextMenu.contextTab = null;">
+      <menuitem id="context_reloadTab" data-lazy-l10n-id="reload-tab"
+                oncommand="gBrowser.reloadTab(TabContextMenu.contextTab);"/>
+      <menuitem id="context_reloadSelectedTabs" data-lazy-l10n-id="reload-tabs" hidden="true"
+                oncommand="gBrowser.reloadMultiSelectedTabs();"/>
+      <menuitem id="context_toggleMuteTab" oncommand="TabContextMenu.contextTab.toggleMuteAudio();"/>
+      <menuitem id="context_toggleMuteSelectedTabs" hidden="true"
+                oncommand="gBrowser.toggleMuteAudioOnMultiSelectedTabs(TabContextMenu.contextTab);"/>
+      <menuitem id="context_pinTab" data-lazy-l10n-id="pin-tab"
+                oncommand="gBrowser.pinTab(TabContextMenu.contextTab);"/>
+      <menuitem id="context_unpinTab" data-lazy-l10n-id="unpin-tab" hidden="true"
+                oncommand="gBrowser.unpinTab(TabContextMenu.contextTab);"/>
+      <menuitem id="context_pinSelectedTabs" data-lazy-l10n-id="pin-selected-tabs" hidden="true"
+                oncommand="gBrowser.pinMultiSelectedTabs();"/>
+      <menuitem id="context_unpinSelectedTabs" data-lazy-l10n-id="unpin-selected-tabs" hidden="true"
+                oncommand="gBrowser.unpinMultiSelectedTabs();"/>
+      <menuitem id="context_duplicateTab" data-lazy-l10n-id="duplicate-tab"
+                oncommand="duplicateTabIn(TabContextMenu.contextTab, 'tab');"/>
+      <menuitem id="context_duplicateTabs" data-lazy-l10n-id="duplicate-tabs"
+                oncommand="TabContextMenu.duplicateSelectedTabs();"/>
+      <menuseparator/>
+      <menuitem id="context_selectAllTabs" data-lazy-l10n-id="select-all-tabs"
+                oncommand="gBrowser.selectAllTabs();"/>
+      <menuitem id="context_bookmarkSelectedTabs"
+                hidden="true"
+                data-lazy-l10n-id="bookmark-selected-tabs"
+                oncommand="PlacesCommandHook.bookmarkPages(PlacesCommandHook.uniqueSelectedPages);"/>
+      <menuitem id="context_bookmarkTab"
+                data-lazy-l10n-id="bookmark-tab"
+                oncommand="PlacesCommandHook.bookmarkPages(PlacesCommandHook.getUniquePages([TabContextMenu.contextTab]));"/>
+      <menu id="context_reopenInContainer"
+            data-lazy-l10n-id="reopen-in-container"
+            hidden="true">
+        <menupopup oncommand="TabContextMenu.reopenInContainer(event);"
+                   onpopupshowing="TabContextMenu.createReopenInContainerMenu(event);"/>
+      </menu>
+      <menu id="context_moveTabOptions">
+        <menupopup id="moveTabOptionsMenu">
+          <menuitem id="context_moveToStart"
+                    data-lazy-l10n-id="move-to-start"
+                    tbattr="tabbrowser-multiple"
+                    oncommand="gBrowser.moveTabsToStart(TabContextMenu.contextTab);"/>
+          <menuitem id="context_moveToEnd"
+                    data-lazy-l10n-id="move-to-end"
+                    tbattr="tabbrowser-multiple"
+                    oncommand="gBrowser.moveTabsToEnd(TabContextMenu.contextTab);"/>
+          <menuitem id="context_openTabInWindow" data-lazy-l10n-id="move-to-new-window"
+                    tbattr="tabbrowser-multiple"
+                    oncommand="gBrowser.replaceTabsWithWindow(TabContextMenu.contextTab);"/>
+        </menupopup>
+      </menu>
+      <menu id="context_sendTabToDevice"
+            class="sync-ui-item">
+        <menupopup id="context_sendTabToDevicePopupMenu"
+                   onpopupshowing="gSync.populateSendTabToDevicesMenu(event.target, TabContextMenu.contextTab.linkedBrowser.currentURI.spec, TabContextMenu.contextTab.linkedBrowser.contentTitle, TabContextMenu.contextTab.multiselected);"/>
+      </menu>
+      <menuseparator/>
+      <menuitem id="context_closeTabsToTheEnd" data-lazy-l10n-id="close-tabs-to-the-end"
+                oncommand="gBrowser.removeTabsToTheEndFrom(TabContextMenu.contextTab, {animate: true});"/>
+      <menuitem id="context_closeOtherTabs" data-lazy-l10n-id="close-other-tabs"
+                oncommand="gBrowser.removeAllTabsBut(TabContextMenu.contextTab);"/>
+      <menuitem id="context_undoCloseTab"
+                data-lazy-l10n-id="undo-close-tab"
+                observes="History:UndoCloseTab"/>
+      <menuitem id="context_closeTab" data-lazy-l10n-id="close-tab"
+                oncommand="gBrowser.removeTab(TabContextMenu.contextTab, { animate: true });"/>
+      <menuitem id="context_closeSelectedTabs" data-lazy-l10n-id="close-tabs"
+                hidden="true"
+                oncommand="gBrowser.removeMultiSelectedTabs();"/>
+    </menupopup>
+
+    <!-- bug 415444/582485: event.stopPropagation is here for the cloned version
+         of this menupopup -->
+    <menupopup id="backForwardMenu"
+               onpopupshowing="return FillHistoryMenu(event.target);"
+               oncommand="gotoHistoryIndex(event); event.stopPropagation();"
+               onclick="checkForMiddleClick(this, event);"/>
+    <tooltip id="aHTMLTooltip" page="true"/>
+    <tooltip id="remoteBrowserTooltip"/>
+
+    <!-- for search and content formfill/pw manager -->
+
+    <panel is="autocomplete-richlistbox-popup"
+           type="autocomplete-richlistbox"
+           id="PopupAutoComplete"
+           role="group"
+           noautofocus="true"
+           hidden="true"
+           overflowpadding="4"
+           norolluponanchor="true"
+           nomaxresults="true" />
+
+    <!-- for search with one-off buttons -->
+    <panel is="search-autocomplete-richlistbox-popup"
+           type="autocomplete-richlistbox"
+           id="PopupSearchAutoComplete"
+           role="group"
+           noautofocus="true"
+           hidden="true" />
+
+    <!-- for url bar autocomplete -->
+    <panel type="autocomplete-richlistbox"
+           id="PopupAutoCompleteRichResult"
+           role="group"
+           noautofocus="true"
+           hidden="true"
+           flip="none"
+           level="parent"
+           overflowpadding="15" />
+
+    <!-- for date/time picker. consumeoutsideclicks is set to never, so that
+         clicks on the anchored input box are never consumed. -->
+    <panel id="DateTimePickerPanel"
+           type="arrow"
+           hidden="true"
+           orient="vertical"
+           noautofocus="true"
+           norolluponanchor="true"
+           consumeoutsideclicks="never"
+           level="parent"
+           tabspecific="true">
+    </panel>
+
+    <!-- for select dropdowns. The menupopup is what shows the list of options,
+         and the popuponly menulist makes things like the menuactive attributes
+         work correctly on the menupopup. ContentSelectDropdown expects the
+         popuponly menulist to be its immediate parent. -->
+    <menulist popuponly="true" id="ContentSelectDropdown" hidden="true">
+      <menupopup rolluponmousewheel="true"
+                 activateontab="true" position="after_start"
+                 level="parent"
+#ifdef XP_WIN
+                 consumeoutsideclicks="false" ignorekeys="shortcuts"
+#endif
+        />
+    </menulist>
+
+    <!-- for invalid form error message -->
+    <panel id="invalid-form-popup" type="arrow" orient="vertical" noautofocus="true" hidden="true" level="parent">
+      <description/>
+    </panel>
+
+    <panel id="editBookmarkPanel"
+           type="arrow"
+           orient="vertical"
+           ignorekeys="true"
+           hidden="true"
+           tabspecific="true"
+           aria-labelledby="editBookmarkPanelTitle">
+      <box class="panel-header">
+        <label id="editBookmarkPanelTitle"/>
+        <toolbarbutton id="editBookmarkPanelInfoButton" oncommand="StarUI.toggleRecommendation();" >
+          <image/>
+        </toolbarbutton>
+      </box>
+      <html:div id="editBookmarkPanelInfoArea">
+        <html:div id="editBookmarkPanelRecommendation"></html:div>
+        <html:div id="editBookmarkPanelFaviconContainer">
+          <html:img id="editBookmarkPanelFavicon"/>
+        </html:div>
+        <html:div id="editBookmarkPanelImage"></html:div>
+      </html:div>
+#include ../../components/places/content/editBookmarkPanel.inc.xul
+      <vbox id="editBookmarkPanelBottomContent"
+            flex="1">
+        <checkbox id="editBookmarkPanel_showForNewBookmarks"
+                  label="&editBookmark.showForNewBookmarks.label;"
+                  accesskey="&editBookmark.showForNewBookmarks.accesskey;"
+                  oncommand="StarUI.onShowForNewBookmarksCheckboxCommand();"/>
+      </vbox>
+      <hbox id="editBookmarkPanelBottomButtons"
+            class="panel-footer"
+            style="min-width: &editBookmark.panel.width;;">
+#ifndef XP_UNIX
+        <button id="editBookmarkPanelDoneButton"
+                class="editBookmarkPanelBottomButton"
+                label="&editBookmark.done.label;"
+                default="true"
+                oncommand="StarUI.panel.hidePopup();"/>
+        <button id="editBookmarkPanelRemoveButton"
+                class="editBookmarkPanelBottomButton"
+                oncommand="StarUI.removeBookmarkButtonCommand();"/>
+#else
+        <button id="editBookmarkPanelRemoveButton"
+                class="editBookmarkPanelBottomButton"
+                oncommand="StarUI.removeBookmarkButtonCommand();"/>
+        <button id="editBookmarkPanelDoneButton"
+                class="editBookmarkPanelBottomButton"
+                label="&editBookmark.done.label;"
+                default="true"
+                oncommand="StarUI.panel.hidePopup();"/>
+#endif
+      </hbox>
+    </panel>
+
+    <!-- UI tour experience -->
+    <panel id="UITourTooltip"
+           type="arrow"
+           hidden="true"
+           noautofocus="true"
+           noautohide="true"
+           align="start"
+           orient="vertical"
+           role="alert">
+     <vbox>
+      <hbox id="UITourTooltipBody">
+        <image id="UITourTooltipIcon"/>
+        <vbox flex="1">
+          <hbox id="UITourTooltipTitleContainer">
+            <label id="UITourTooltipTitle" flex="1"/>
+            <toolbarbutton id="UITourTooltipClose" class="close-icon"
+                           tooltiptext="&uiTour.infoPanel.close;"/>
+          </hbox>
+          <description id="UITourTooltipDescription" flex="1"/>
+        </vbox>
+      </hbox>
+      <hbox id="UITourTooltipButtons" flex="1" align="center"/>
+     </vbox>
+    </panel>
+    <!-- type="default" forces frames to be created so that the panel's size can be determined -->
+    <panel id="UITourHighlightContainer"
+           type="default"
+           hidden="true"
+           noautofocus="true"
+           noautohide="true"
+           flip="none"
+           consumeoutsideclicks="false"
+           mousethrough="always">
+      <box id="UITourHighlight"></box>
+    </panel>
+
+    <panel id="sidebarMenu-popup"
+           class="cui-widget-panel"
+           role="group"
+           type="arrow"
+           hidden="true"
+           flip="slide"
+           orient="vertical"
+           position="bottomcenter topleft">
+      <toolbarbutton id="sidebar-switcher-bookmarks"
+                     type="checkbox"
+                     label="&bookmarksButton.label;"
+                     class="subviewbutton subviewbutton-iconic"
+                     key="viewBookmarksSidebarKb"
+                     oncommand="SidebarUI.show('viewBookmarksSidebar');"/>
+      <toolbarbutton id="sidebar-switcher-history"
+                     type="checkbox"
+                     label="&historyButton.label;"
+                     class="subviewbutton subviewbutton-iconic"
+                     key="key_gotoHistory"
+                     oncommand="SidebarUI.show('viewHistorySidebar');"/>
+      <toolbarbutton id="sidebar-switcher-tabs"
+                     type="checkbox"
+                     label="&syncedTabs.sidebar.label;"
+                     class="subviewbutton subviewbutton-iconic sync-ui-item"
+                     oncommand="SidebarUI.show('viewTabsSidebar');"/>
+      <toolbarseparator/>
+      <!-- Extension toolbarbuttons go here. -->
+      <toolbarseparator id="sidebar-extensions-separator"/>
+      <toolbarbutton id="sidebar-reverse-position"
+                     class="subviewbutton"
+                     oncommand="SidebarUI.reversePosition()"/>
+      <toolbarseparator/>
+      <toolbarbutton label="&sidebarMenuClose.label;"
+                     class="subviewbutton"
+                     oncommand="SidebarUI.hide()"/>
+    </panel>
+
+    <menupopup id="toolbar-context-menu"
+               onpopupshowing="onViewToolbarsPopupShowing(event, document.getElementById('viewToolbarsMenuSeparator')); ToolbarContextMenu.updateDownloadsAutoHide(this); ToolbarContextMenu.updateExtension(this)">
+      <menuitem oncommand="ToolbarContextMenu.openAboutAddonsForContextAction(this.parentElement)"
+                accesskey="&customizeMenu.manageExtension.accesskey;"
+                label="&customizeMenu.manageExtension.label;"
+                contexttype="toolbaritem"
+                class="customize-context-manageExtension"/>
+      <menuitem oncommand="ToolbarContextMenu.removeExtensionForContextAction(this.parentElement)"
+                accesskey="&customizeMenu.removeExtension.accesskey;"
+                label="&customizeMenu.removeExtension.label;"
+                contexttype="toolbaritem"
+                class="customize-context-removeExtension"/>
+      <menuitem oncommand="ToolbarContextMenu.reportExtensionForContextAction(this.parentElement, 'toolbar_context_menu')"
+                accesskey="&customizeMenu.reportExtension.accesskey;"
+                label="&customizeMenu.reportExtension.label;"
+                contexttype="toolbaritem"
+                class="customize-context-reportExtension"/>
+      <menuseparator/>
+      <menuitem oncommand="gCustomizeMode.addToPanel(document.popupNode)"
+                accesskey="&customizeMenu.pinToOverflowMenu.accesskey;"
+                label="&customizeMenu.pinToOverflowMenu.label;"
+                contexttype="toolbaritem"
+                class="customize-context-moveToPanel"/>
+      <menuitem id="toolbar-context-autohide-downloads-button"
+                oncommand="ToolbarContextMenu.onDownloadsAutoHideChange(event);"
+                type="checkbox"
+                accesskey="&customizeMenu.autoHideDownloadsButton.accesskey;"
+                label="&customizeMenu.autoHideDownloadsButton.label;"
+                contexttype="toolbaritem"/>
+      <menuitem oncommand="gCustomizeMode.removeFromArea(document.popupNode)"
+                accesskey="&customizeMenu.removeFromToolbar.accesskey;"
+                label="&customizeMenu.removeFromToolbar.label;"
+                contexttype="toolbaritem"
+                class="customize-context-removeFromToolbar"/>
+      <menuitem id="toolbar-context-reloadSelectedTab"
+                contexttype="tabbar"
+                oncommand="gBrowser.reloadMultiSelectedTabs();"
+                data-lazy-l10n-id="toolbar-context-menu-reload-selected-tab"/>
+      <menuitem id="toolbar-context-reloadSelectedTabs"
+                contexttype="tabbar"
+                oncommand="gBrowser.reloadMultiSelectedTabs();"
+                data-lazy-l10n-id="toolbar-context-menu-reload-selected-tabs"/>
+      <menuitem id="toolbar-context-bookmarkSelectedTab"
+                contexttype="tabbar"
+                oncommand="PlacesCommandHook.bookmarkPages(PlacesCommandHook.uniqueSelectedPages);"
+                data-lazy-l10n-id="toolbar-context-menu-bookmark-selected-tab"/>
+      <menuitem id="toolbar-context-bookmarkSelectedTabs"
+                contexttype="tabbar"
+                oncommand="PlacesCommandHook.bookmarkPages(PlacesCommandHook.uniqueSelectedPages);"
+                data-lazy-l10n-id="toolbar-context-menu-bookmark-selected-tabs"/>
+      <menuitem id="toolbar-context-selectAllTabs"
+                contexttype="tabbar"
+                oncommand="gBrowser.selectAllTabs();"
+                data-lazy-l10n-id="toolbar-context-menu-select-all-tabs"/>
+      <menuitem id="toolbar-context-undoCloseTab"
+                contexttype="tabbar"
+                data-lazy-l10n-id="toolbar-context-menu-undo-close-tab"
+                observes="History:UndoCloseTab"/>
+      <menuseparator/>
+      <menuseparator id="viewToolbarsMenuSeparator"/>
+      <!-- XXXgijs: we're using oncommand handler here to avoid the event being
+                    redirected to the command element, thus preventing
+                    listeners on the menupopup or further up the tree from
+                    seeing the command event pass by. The observes attribute is
+                    here so that the menuitem is still disabled and re-enabled
+                    correctly. -->
+      <menuitem oncommand="gCustomizeMode.enter()"
+                observes="cmd_CustomizeToolbars"
+                class="viewCustomizeToolbar"
+                label="&viewCustomizeToolbar.label;"
+                accesskey="&viewCustomizeToolbar.accesskey;"/>
+    </menupopup>
+
+    <menupopup id="blockedPopupOptions"
+               onpopupshowing="gPopupBlockerObserver.fillPopupList(event);"
+               onpopuphiding="gPopupBlockerObserver.onPopupHiding(event);">
+      <menuitem id="blockedPopupAllowSite"
+                accesskey="&allowPopups.accesskey;"
+                oncommand="gPopupBlockerObserver.toggleAllowPopupsForSite(event);"/>
+      <menuitem
+#ifdef XP_WIN
+                label="&editPopupSettings.label;"
+#else
+                label="&editPopupSettingsUnix.label;"
+#endif
+                accesskey="&editPopupSettings.accesskey;"
+                oncommand="gPopupBlockerObserver.editPopupSettings();"/>
+      <menuitem id="blockedPopupDontShowMessage"
+                accesskey="&dontShowMessage.accesskey;"
+                type="checkbox"
+                oncommand="gPopupBlockerObserver.dontShowMessage();"/>
+      <menuseparator id="blockedPopupsSeparator"/>
+    </menupopup>
+
+    <menupopup id="autohide-context"
+           onpopupshowing="FullScreen.getAutohide(this.firstChild);">
+      <menuitem type="checkbox" label="&fullScreenAutohide.label;"
+                accesskey="&fullScreenAutohide.accesskey;"
+                oncommand="FullScreen.setAutohide();"/>
+      <menuseparator/>
+      <menuitem label="&fullScreenExit.label;"
+                accesskey="&fullScreenExit.accesskey;"
+                oncommand="BrowserFullScreen();"/>
+    </menupopup>
+
+    <menupopup id="contentAreaContextMenu" pagemenu="#page-menu-separator"
+               onpopupshowing="if (event.target != this)
+                                 return true;
+                               gContextMenu = new nsContextMenu(this, event.shiftKey);
+                               if (gContextMenu.shouldDisplay)
+                                 updateEditUIVisibility();
+                               return gContextMenu.shouldDisplay;"
+               onpopuphiding="if (event.target != this)
+                                return;
+                              gContextMenu.hiding();
+                              gContextMenu = null;
+                              updateEditUIVisibility();">
+#include browser-context.inc
+    </menupopup>
+
+#include ../../components/places/content/placesContextMenu.inc.xul
+
+    <panel id="ctrlTab-panel" hidden="true" norestorefocus="true" level="top">
+      <hbox id="ctrlTab-previews"/>
+      <hbox id="ctrlTab-showAll-container" pack="center"/>
+    </panel>
+
+    <panel id="pageActionPanel"
+           class="cui-widget-panel"
+           role="group"
+           type="arrow"
+           hidden="true"
+           flip="slide"
+           photon="true"
+           position="bottomcenter topright"
+           tabspecific="true"
+           noautofocus="true"
+           pinTab-title="&pinTab.label;"
+           unpinTab-title="&unpinTab.label;"
+           pocket-title="&saveToPocketCmd.label;"
+           copyURL-title="&pageAction.copyLink.label;"
+           emailLink-title="&emailPageCmd.label;"
+           sendToDevice-notReadyTitle="&sendToDevice.syncNotReady.label;"
+           shareURL-title="&pageAction.shareUrl.label;"
+           shareMore-label="&pageAction.shareMore.label;">
+      <panelmultiview id="pageActionPanelMultiView"
+                      mainViewId="pageActionPanelMainView"
+                      viewCacheId="appMenu-viewCache">
+        <panelview id="pageActionPanelMainView"
+                   context="pageActionContextMenu"
+                   class="PanelUI-subView">
+          <vbox class="panel-subview-body"/>
+        </panelview>
+      </panelmultiview>
+    </panel>
+
+    <panel id="confirmation-hint"
+           role="alert"
+           type="arrow"
+           hidden="true"
+           flip="slide"
+           position="bottomcenter topright"
+           tabspecific="true"
+           noautofocus="true">
+      <hbox id="confirmation-hint-checkmark-animation-container">
+       <image id="confirmation-hint-checkmark-image"/>
+      </hbox>
+      <vbox id="confirmation-hint-message-container">
+       <label id="confirmation-hint-message"/>
+       <label id="confirmation-hint-description"/>
+      </vbox>
+    </panel>
+
+    <menupopup id="pageActionContextMenu"
+               onpopupshowing="BrowserPageActions.onContextMenuShowing(event, this);">
+      <menuitem class="pageActionContextMenuItem builtInUnpinned"
+                label="&pageAction.addToUrlbar.label;"
+                oncommand="BrowserPageActions.togglePinningForContextAction();"/>
+      <menuitem class="pageActionContextMenuItem builtInPinned"
+                label="&pageAction.removeFromUrlbar.label;"
+                oncommand="BrowserPageActions.togglePinningForContextAction();"/>
+      <menuitem class="pageActionContextMenuItem extensionUnpinned"
+                label="&pageAction.addToUrlbar.label;"
+                oncommand="BrowserPageActions.togglePinningForContextAction();"/>
+      <menuitem class="pageActionContextMenuItem extensionPinned"
+                label="&pageAction.removeFromUrlbar.label;"
+                oncommand="BrowserPageActions.togglePinningForContextAction();"/>
+      <menuseparator class="pageActionContextMenuItem extensionPinned extensionUnpinned"/>
+      <menuitem class="pageActionContextMenuItem extensionPinned extensionUnpinned"
+                label="&pageAction.manageExtension.label;"
+                oncommand="BrowserPageActions.openAboutAddonsForContextAction();"/>
+    </menupopup>
+
+#include ../../components/places/content/bookmarksHistoryTooltip.inc.xul
+
+    <tooltip id="tabbrowser-tab-tooltip" onpopupshowing="gBrowser.createTooltip(event);"/>
+
+    <tooltip id="back-button-tooltip">
+      <description class="tooltip-label" value="&backButton.tooltip;"/>
+#ifdef XP_MACOSX
+      <description class="tooltip-label" value="&backForwardButtonMenuMac.tooltip;"/>
+#else
+      <description class="tooltip-label" value="&backForwardButtonMenu.tooltip;"/>
+#endif
+    </tooltip>
+
+    <tooltip id="forward-button-tooltip">
+      <description class="tooltip-label" value="&forwardButton.tooltip;"/>
+#ifdef XP_MACOSX
+      <description class="tooltip-label" value="&backForwardButtonMenuMac.tooltip;"/>
+#else
+      <description class="tooltip-label" value="&backForwardButtonMenu.tooltip;"/>
+#endif
+    </tooltip>
+
+#include popup-notifications.inc
+
+#include ../../components/customizableui/content/panelUI.inc.xul
+#include ../../components/controlcenter/content/identityPanel.inc.xul
+#include ../../components/controlcenter/content/protectionsPanel.inc.xul
+#include ../../components/downloads/content/downloadsPanel.inc.xul
+#include browser-allTabsMenu.inc.xul
+
+    <hbox id="downloads-animation-container" mousethrough="always">
+      <vbox id="downloads-notification-anchor" hidden="true">
+        <vbox id="downloads-indicator-notification"/>
+      </vbox>
+    </hbox>
+
+    <tooltip id="dynamic-shortcut-tooltip"
+             onpopupshowing="UpdateDynamicShortcutTooltipText(this);"/>
+
+    <menupopup id="SyncedTabsSidebarContext">
+      <menuitem data-lazy-l10n-id="synced-tabs-context-open"
+                id="syncedTabsOpenSelected" where="current"/>
+      <menuitem data-lazy-l10n-id="synced-tabs-context-open-in-new-tab"
+                id="syncedTabsOpenSelectedInTab" where="tab"/>
+      <menuitem data-lazy-l10n-id="synced-tabs-context-open-in-new-window"
+                id="syncedTabsOpenSelectedInWindow" where="window"/>
+      <menuitem data-lazy-l10n-id="synced-tabs-context-open-in-new-private-window"
+                id="syncedTabsOpenSelectedInPrivateWindow" where="window" private="true"/>
+      <menuseparator/>
+      <menuitem data-lazy-l10n-id="synced-tabs-context-bookmark-single-tab"
+                id="syncedTabsBookmarkSelected"/>
+      <menuitem data-lazy-l10n-id="synced-tabs-context-copy"
+                id="syncedTabsCopySelected"/>
+      <menuseparator/>
+      <menuitem data-lazy-l10n-id="synced-tabs-context-open-all-in-tabs"
+                id="syncedTabsOpenAllInTabs"/>
+      <menuitem data-lazy-l10n-id="synced-tabs-context-manage-devices"
+                id="syncedTabsManageDevices"
+                oncommand="gSync.openDevicesManagementPage('syncedtabs-sidebar');"/>
+      <menuitem label="&syncSyncNowItem.label;"
+                accesskey="&syncSyncNowItem.accesskey;"
+                id="syncedTabsRefresh"/>
+    </menupopup>
+    <menupopup id="SyncedTabsSidebarTabsFilterContext"
+               class="textbox-contextmenu">
+      <menuitem label="&undoCmd.label;"
+                accesskey="&undoCmd.accesskey;"
+                cmd="cmd_undo"/>
+      <menuseparator/>
+      <menuitem label="&cutCmd.label;"
+                accesskey="&cutCmd.accesskey;"
+                cmd="cmd_cut"/>
+      <menuitem label="&copyCmd.label;"
+                accesskey="&copyCmd.accesskey;"
+                cmd="cmd_copy"/>
+      <menuitem label="&pasteCmd.label;"
+                accesskey="&pasteCmd.accesskey;"
+                cmd="cmd_paste"/>
+      <menuitem label="&deleteCmd.label;"
+                accesskey="&deleteCmd.accesskey;"
+                cmd="cmd_delete"/>
+      <menuseparator/>
+      <menuitem label="&selectAllCmd.label;"
+                accesskey="&selectAllCmd.accesskey;"
+                cmd="cmd_selectAll"/>
+      <menuseparator/>
+      <menuitem label="&syncSyncNowItem.label;"
+                accesskey="&syncSyncNowItem.accesskey;"
+                id="syncedTabsRefreshFilter"/>
+    </menupopup>
+
+    <hbox id="statuspanel" inactive="true" renderroot="content">
+      <hbox id="statuspanel-inner">
+        <label id="statuspanel-label"
+               role="status"
+               aria-live="off"
+               flex="1"
+               crop="end"/>
+      </hbox>
+    </hbox>
+  </popupset>
+  <box id="appMenu-viewCache" hidden="true"/>
+
+  <toolbox id="navigator-toolbox">
+
+    <vbox id="titlebar">
+      <!-- Menu -->
+      <toolbar type="menubar" id="toolbar-menubar"
+               class="browser-toolbar chromeclass-menubar titlebar-color"
+               customizable="true"
+               mode="icons"
+#ifdef MENUBAR_CAN_AUTOHIDE
+               toolbarname="&menubarCmd.label;"
+               accesskey="&menubarCmd.accesskey;"
+               autohide="true"
+#endif
+               context="toolbar-context-menu">
+        <toolbaritem id="menubar-items" align="center">
+# The entire main menubar is placed into browser-menubar.inc, so that it can be
+# shared with other top level windows in macWindow.inc.xul.
+#include browser-menubar.inc
+        </toolbaritem>
+        <spacer flex="1" skipintoolbarset="true" ordinal="1000"/>
+#include titlebar-items.inc.xul
+      </toolbar>
+
+      <toolbar id="TabsToolbar"
+               class="browser-toolbar titlebar-color"
+               fullscreentoolbar="true"
+               customizable="true"
+               customizationtarget="TabsToolbar-customization-target"
+               mode="icons"
+               aria-label="&tabsToolbar.label;"
+               context="toolbar-context-menu"
+               flex="1">
+
+        <hbox class="titlebar-spacer" type="pre-tabs"/>
+
+        <hbox flex="1" align="end" class="toolbar-items">
+          <hbox id="TabsToolbar-customization-target" flex="1">
+            <tabs id="tabbrowser-tabs"
+                  flex="1"
+                  setfocus="false"
+                  tooltip="tabbrowser-tab-tooltip"
+                  stopwatchid="FX_TAB_CLICK_MS">
+              <tab class="tabbrowser-tab" selected="true" visuallyselected="true" fadein="true"/>
+            </tabs>
+
+            <toolbarbutton id="new-tab-button"
+                           class="toolbarbutton-1 chromeclass-toolbar-additional"
+                           label="&tabCmd.label;"
+                           command="cmd_newNavigatorTab"
+                           onclick="checkForMiddleClick(this, event);"
+                           tooltip="dynamic-shortcut-tooltip"
+                           ondrop="newTabButtonObserver.onDrop(event)"
+                           ondragover="newTabButtonObserver.onDragOver(event)"
+                           ondragenter="newTabButtonObserver.onDragOver(event)"
+                           ondragexit="newTabButtonObserver.onDragExit(event)"
+                           cui-areatype="toolbar"
+                           removable="true"/>
+
+            <toolbarbutton id="alltabs-button"
+                           class="toolbarbutton-1 chromeclass-toolbar-additional tabs-alltabs-button"
+                           badged="true"
+                           oncommand="gTabsPanel.showAllTabsPanel();"
+                           label="&listAllTabs.label;"
+                           tooltiptext="&listAllTabs.label;"
+                           removable="false"/>
+          </hbox>
+        </hbox>
+
+        <hbox class="titlebar-spacer" type="post-tabs"/>
+
+#ifndef XP_MACOSX
+        <button class="accessibility-indicator" tooltiptext="&accessibilityIndicator.tooltip;"
+                aria-live="polite"/>
+        <hbox class="private-browsing-indicator"/>
+#endif
+
+#include titlebar-items.inc.xul
+
+#ifdef XP_MACOSX
+        <!-- OS X does not natively support RTL for its titlebar items, so we prevent this secondary
+             buttonbox from reversing order in RTL by forcing an LTR direction. -->
+        <hbox id="titlebar-secondary-buttonbox" dir="ltr">
+          <button class="accessibility-indicator" tooltiptext="&accessibilityIndicator.tooltip;" aria-live="polite"/>
+          <hbox class="private-browsing-indicator"/>
+          <hbox id="titlebar-fullscreen-button"/>
+        </hbox>
+#endif
+      </toolbar>
+
+    </vbox>
+
+    <toolbar id="nav-bar"
+             class="browser-toolbar"
+             aria-label="&navbarCmd.label;"
+             fullscreentoolbar="true" mode="icons" customizable="true"
+             customizationtarget="nav-bar-customization-target"
+             overflowable="true"
+             overflowbutton="nav-bar-overflow-button"
+             overflowtarget="widget-overflow-list"
+             overflowpanel="widget-overflow"
+             context="toolbar-context-menu">
+
+      <toolbartabstop/>
+      <hbox id="nav-bar-customization-target" flex="1">
+        <toolbarbutton id="back-button" class="toolbarbutton-1 chromeclass-toolbar-additional"
+                       label="&backCmd.label;"
+                       removable="false" overflows="false"
+                       keepbroadcastattributeswhencustomizing="true"
+                       command="Browser:BackOrBackDuplicate"
+                       onclick="checkForMiddleClick(this, event);"
+                       tooltip="back-button-tooltip"
+                       context="backForwardMenu"/>
+        <toolbarbutton id="forward-button" class="toolbarbutton-1 chromeclass-toolbar-additional"
+                       label="&forwardCmd.label;"
+                       removable="false" overflows="false"
+                       keepbroadcastattributeswhencustomizing="true"
+                       command="Browser:ForwardOrForwardDuplicate"
+                       onclick="checkForMiddleClick(this, event);"
+                       tooltip="forward-button-tooltip"
+                       context="backForwardMenu"/>
+        <toolbaritem id="stop-reload-button" class="chromeclass-toolbar-additional"
+                     title="&reloadCmd.label;"
+                     removable="true" overflows="false">
+          <toolbarbutton id="reload-button" class="toolbarbutton-1"
+                         label="&reloadCmd.label;"
+                         command="Browser:ReloadOrDuplicate"
+                         onclick="checkForMiddleClick(this, event);"
+                         tooltip="dynamic-shortcut-tooltip">
+            <box class="toolbarbutton-animatable-box">
+              <image class="toolbarbutton-animatable-image"/>
+            </box>
+          </toolbarbutton>
+          <toolbarbutton id="stop-button" class="toolbarbutton-1"
+                         label="&stopCmd.label;"
+                         command="Browser:Stop"
+                         tooltip="dynamic-shortcut-tooltip">
+            <box class="toolbarbutton-animatable-box">
+              <image class="toolbarbutton-animatable-image"/>
+            </box>
+          </toolbarbutton>
+        </toolbaritem>
+        <toolbarbutton id="home-button" class="toolbarbutton-1 chromeclass-toolbar-additional"
+                       removable="true"
+                       label="&homeButton.label;"
+                       ondragover="homeButtonObserver.onDragOver(event)"
+                       ondragenter="homeButtonObserver.onDragOver(event)"
+                       ondrop="homeButtonObserver.onDrop(event)"
+                       ondragexit="homeButtonObserver.onDragExit(event)"
+                       key="goHome"
+                       onclick="BrowserHome(event);"
+                       cui-areatype="toolbar"
+                       tooltiptext="&homeButton.defaultPage.tooltip;"/>
+        <toolbarspring cui-areatype="toolbar" class="chromeclass-toolbar-additional"/>
+        <toolbaritem id="urlbar-container" flex="400" persist="width"
+                     removable="false"
+                     class="chromeclass-location" overflows="false">
+            <toolbartabstop/>
+            <textbox id="urlbar" flex="1"
+                     placeholder="&urlbar.placeholder2;"
+                     defaultPlaceholder="&urlbar.placeholder2;"
+                     focused="true"
+                     pageproxystate="invalid">
+              <!-- Use onclick instead of normal popup= syntax since the popup
+                   code fires onmousedown, and hence eats our favicon drag events. -->
+              <box id="identity-box" role="button"
+                   align="center"
+                   aria-label="&urlbar.viewSiteInfo.label;"
+                   onclick="gIdentityHandler.handleIdentityButtonEvent(event);"
+                   onkeypress="gIdentityHandler.handleIdentityButtonEvent(event);"
+                   ondragstart="gIdentityHandler.onDragStart(event);">
+                <image id="identity-icon"
+                       consumeanchor="identity-box"
+                       onclick="PageProxyClickHandler(event);"/>
+                <image id="sharing-icon" mousethrough="always"/>
+                <box id="tracking-protection-icon-box" animationsenabled="true">
+                  <image id="tracking-protection-icon"/>
+                  <box id="tracking-protection-icon-animatable-box" flex="1">
+                    <image id="tracking-protection-icon-animatable-image" flex="1"/>
+                  </box>
+                </box>
+                <box id="blocked-permissions-container" align="center">
+                  <image data-permission-id="geo" class="blocked-permission-icon geo-icon" role="button"
+                         tooltiptext="&urlbar.geolocationBlocked.tooltip;"/>
+                  <image data-permission-id="desktop-notification" class="blocked-permission-icon desktop-notification-icon" role="button"
+                         tooltiptext="&urlbar.webNotificationsBlocked.tooltip;"/>
+                  <image data-permission-id="camera" class="blocked-permission-icon camera-icon" role="button"
+                         tooltiptext="&urlbar.cameraBlocked.tooltip;"/>
+                  <image data-permission-id="microphone" class="blocked-permission-icon microphone-icon" role="button"
+                         tooltiptext="&urlbar.microphoneBlocked.tooltip;"/>
+                  <image data-permission-id="screen" class="blocked-permission-icon screen-icon" role="button"
+                         tooltiptext="&urlbar.screenBlocked.tooltip;"/>
+                  <image data-permission-id="persistent-storage" class="blocked-permission-icon persistent-storage-icon" role="button"
+                         tooltiptext="&urlbar.persistentStorageBlocked.tooltip;"/>
+                  <image data-permission-id="popup" class="blocked-permission-icon popup-icon" role="button"
+                         tooltiptext="&urlbar.popupBlocked.tooltip;"/>
+                  <image data-permission-id="autoplay-media" class="blocked-permission-icon autoplay-media-icon" role="button"
+                         tooltiptext="&urlbar.autoplayMediaBlocked.tooltip;"/>
+                  <image data-permission-id="canvas" class="blocked-permission-icon canvas-icon" role="button"
+                         tooltiptext="&urlbar.canvasBlocked.tooltip;"/>
+                  <image data-permission-id="plugin:flash" class="blocked-permission-icon plugin-icon" role="button"
+                         tooltiptext="&urlbar.flashPluginBlocked.tooltip;"/>
+                  <image data-permission-id="midi" class="blocked-permission-icon midi-icon" role="button"
+                         tooltiptext="&urlbar.midiBlocked.tooltip;"/>
+                  <image data-permission-id="install" class="blocked-permission-icon install-icon" role="button"
+                         tooltiptext="&urlbar.installBlocked.tooltip;"/>
+                </box>
+                <box id="notification-popup-box"
+                     hidden="true"
+                     onmouseover="document.getElementById('identity-box').classList.add('no-hover');"
+                     onmouseout="document.getElementById('identity-box').classList.remove('no-hover');"
+                     align="center">
+                  <image id="default-notification-icon" class="notification-anchor-icon" role="button"
+                         tooltiptext="&urlbar.defaultNotificationAnchor.tooltip;"/>
+                  <image id="geo-notification-icon" class="notification-anchor-icon geo-icon" role="button"
+                         tooltiptext="&urlbar.geolocationNotificationAnchor.tooltip;"/>
+                  <image id="autoplay-media-notification-icon" class="notification-anchor-icon autoplay-media-icon" role="button"
+                         tooltiptext="&urlbar.autoplayNotificationAnchor.tooltip;"/>
+                  <image id="addons-notification-icon" class="notification-anchor-icon install-icon" role="button"
+                         tooltiptext="&urlbar.addonsNotificationAnchor.tooltip;"/>
+                  <image id="canvas-notification-icon" class="notification-anchor-icon" role="button"
+                         tooltiptext="&urlbar.canvasNotificationAnchor.tooltip;"/>
+                  <image id="indexedDB-notification-icon" class="notification-anchor-icon indexedDB-icon" role="button"
+                         tooltiptext="&urlbar.indexedDBNotificationAnchor.tooltip;"/>
+                  <image id="password-notification-icon" class="notification-anchor-icon login-icon" role="button"
+                         tooltiptext="&urlbar.passwordNotificationAnchor.tooltip;"/>
+                  <stack id="plugins-notification-icon" class="notification-anchor-icon" role="button" align="center"
+                         tooltiptext="&urlbar.pluginsNotificationAnchor.tooltip;">
+                    <image class="plugin-icon" />
+                    <image id="plugin-icon-badge" />
+                  </stack>
+                  <image id="web-notifications-notification-icon" class="notification-anchor-icon desktop-notification-icon" role="button"
+                         tooltiptext="&urlbar.webNotificationAnchor.tooltip;"/>
+                  <image id="webRTC-shareDevices-notification-icon" class="notification-anchor-icon camera-icon" role="button"
+                         tooltiptext="&urlbar.webRTCShareDevicesNotificationAnchor.tooltip;"/>
+                  <image id="webRTC-shareMicrophone-notification-icon" class="notification-anchor-icon microphone-icon" role="button"
+                         tooltiptext="&urlbar.webRTCShareMicrophoneNotificationAnchor.tooltip;"/>
+                  <image id="webRTC-shareScreen-notification-icon" class="notification-anchor-icon screen-icon" role="button"
+                         tooltiptext="&urlbar.webRTCShareScreenNotificationAnchor.tooltip;"/>
+                  <image id="servicesInstall-notification-icon" class="notification-anchor-icon service-icon" role="button"
+                         tooltiptext="&urlbar.servicesNotificationAnchor.tooltip;"/>
+                  <image id="translate-notification-icon" class="notification-anchor-icon translation-icon" role="button"
+                         tooltiptext="&urlbar.translateNotificationAnchor.tooltip;"/>
+                  <image id="translated-notification-icon" class="notification-anchor-icon translation-icon in-use" role="button"
+                         tooltiptext="&urlbar.translatedNotificationAnchor.tooltip;"/>
+                  <image id="eme-notification-icon" class="notification-anchor-icon drm-icon" role="button"
+                         tooltiptext="&urlbar.emeNotificationAnchor.tooltip;"/>
+                  <image id="persistent-storage-notification-icon" class="notification-anchor-icon persistent-storage-icon" role="button"
+                         tooltiptext="&urlbar.persistentStorageNotificationAnchor.tooltip;"/>
+                  <image id="midi-notification-icon" class="notification-anchor-icon midi-icon" role="button"
+                         tooltiptext="&urlbar.midiNotificationAnchor.tooltip;"/>
+                  <image id="webauthn-notification-icon" class="notification-anchor-icon" role="button"
+                         tooltiptext="&urlbar.webAuthnAnchor.tooltip;"/>
+                  <image id="storage-access-notification-icon" class="notification-anchor-icon storage-access-icon" role="button"
+                         tooltiptext="&urlbar.storageAccessAnchor.tooltip;"/>
+                </box>
+                <image id="connection-icon"/>
+                <image id="extension-icon"/>
+                <image id="remote-control-icon"
+                       tooltiptext="&urlbar.remoteControlNotificationAnchor.tooltip;"/>
+                <hbox id="identity-icon-labels">
+                  <label id="identity-icon-label" class="plain" flex="1"/>
+                  <label id="identity-icon-country-label" class="plain"/>
+                </hbox>
+              </box>
+              <box id="urlbar-display-box" align="center">
+                <label id="switchtab" class="urlbar-display urlbar-display-switchtab" value="&urlbar.switchToTab.label;"/>
+                <label id="extension" class="urlbar-display urlbar-display-extension" value="&urlbar.extension.label;"/>
+              </box>
+              <hbox id="page-action-buttons" context="pageActionContextMenu">
+                <toolbartabstop/>
+                <hbox id="contextual-feature-recommendation" role="button" hidden="true">
+                  <hbox id="cfr-label-container">
+                    <label id="cfr-label"/>
+                  </hbox>
+                  <image id="cfr-button"
+                         class="urlbar-icon urlbar-page-action"
+                         role="presentation"/>
+                </hbox>
+                <hbox id="userContext-icons" hidden="true">
+                  <label id="userContext-label"/>
+                  <image id="userContext-indicator"/>
+                </hbox>
+                <image id="reader-mode-button"
+                       class="urlbar-icon urlbar-page-action"
+                       tooltip="dynamic-shortcut-tooltip"
+                       role="button"
+                       hidden="true"
+                       onclick="ReaderParent.buttonClick(event);"/>
+                <toolbarbutton id="urlbar-zoom-button"
+                       onclick="FullZoom.reset();"
+                       tooltip="dynamic-shortcut-tooltip"
+                       hidden="true"/>
+                <box id="pageActionSeparator" class="urlbar-page-action"/>
+                <image id="pageActionButton"
+                       class="urlbar-icon urlbar-page-action"
+                       role="button"
+                       tooltiptext="&pageActionButton.tooltip;"
+                       onmousedown="BrowserPageActions.mainButtonClicked(event);"
+                       onkeypress="BrowserPageActions.mainButtonClicked(event);"/>
+                <hbox id="pocket-button-box"
+                      hidden="true"
+                      class="urlbar-icon-wrapper urlbar-page-action"
+                      onclick="BrowserPageActions.doCommandForAction(PageActions.actionForID('pocket'), event, this);">
+                  <image id="pocket-button"
+                         class="urlbar-icon"
+                         tooltiptext="&pocketButton.tooltiptext;"
+                         role="button"/>
+                  <hbox id="pocket-button-animatable-box">
+                    <image id="pocket-button-animatable-image"
+                           tooltiptext="&pocketButton.tooltiptext;"
+                           role="presentation"/>
+                  </hbox>
+                </hbox>
+                <hbox id="star-button-box"
+                      hidden="true"
+                      class="urlbar-icon-wrapper urlbar-page-action"
+                      onclick="BrowserPageActions.doCommandForAction(PageActions.actionForID('bookmark'), event, this);">
+                  <image id="star-button"
+                         class="urlbar-icon"
+                         role="button"/>
+                  <hbox id="star-button-animatable-box">
+                    <image id="star-button-animatable-image"
+                           role="presentation"/>
+                  </hbox>
+                </hbox>
+              </hbox>
+            </textbox>
+            <toolbartabstop/>
+        </toolbaritem>
+
+        <toolbarspring cui-areatype="toolbar" class="chromeclass-toolbar-additional"/>
+
+        <!-- This is a placeholder for the Downloads Indicator.  It is visible
+             during the customization of the toolbar, in the palette, and before
+             the Downloads Indicator overlay is loaded. -->
+        <toolbarbutton id="downloads-button"
+                       class="toolbarbutton-1 chromeclass-toolbar-additional"
+                       badged="true"
+                       key="key_openDownloads"
+                       onmousedown="DownloadsIndicatorView.onCommand(event);"
+                       onkeypress="DownloadsIndicatorView.onCommand(event);"
+                       ondrop="DownloadsIndicatorView.onDrop(event);"
+                       ondragover="DownloadsIndicatorView.onDragOver(event);"
+                       ondragenter="DownloadsIndicatorView.onDragOver(event);"
+                       label="&downloads.label;"
+                       removable="true"
+                       overflows="false"
+                       cui-areatype="toolbar"
+                       hidden="true"
+                       tooltip="dynamic-shortcut-tooltip"
+                       indicator="true">
+            <!-- The panel's anchor area is smaller than the outer button, but must
+                 always be visible and must not move or resize when the indicator
+                 state changes, otherwise the panel could change its position or lose
+                 its arrow unexpectedly. -->
+            <stack id="downloads-indicator-anchor"
+                   consumeanchor="downloads-button">
+              <box id="downloads-indicator-icon"/>
+              <stack id="downloads-indicator-progress-outer">
+                <box id="downloads-indicator-progress-inner"/>
+              </stack>
+            </stack>
+          </toolbarbutton>
+
+        <toolbarbutton id="library-button" class="toolbarbutton-1 chromeclass-toolbar-additional subviewbutton-nav"
+                       removable="true"
+                       onmousedown="PanelUI.showSubView('appMenu-libraryView', this, event);"
+                       onkeypress="PanelUI.showSubView('appMenu-libraryView', this, event);"
+                       closemenu="none"
+                       cui-areatype="toolbar"
+                       tooltiptext="&libraryButton.tooltip;"
+                       label="&places.library.title;"/>
+
+        <toolbarbutton id="fxa-toolbar-menu-button" class="toolbarbutton-1 chromeclass-toolbar-additional subviewbutton-nav"
+                       badged="true"
+                       onmousedown="gSync.toggleAccountPanel('PanelUI-fxa', event)"
+                       onkeypress="gSync.toggleAccountPanel('PanelUI-fxa', event)"
+                       consumeanchor="fxa-toolbar-menu-button"
+                       closemenu="none"
+                       label="&fxa.menu.firefoxAccount;"
+                       tooltiptext="&fxa.menu.firefoxAccount;"
+                       cui-areatype="toolbar"
+                       removable="true">
+                       <vbox>
+                        <image id="fxa-avatar-image"/>
+                       </vbox>
+        </toolbarbutton>
+      </hbox>
+
+      <toolbarbutton id="nav-bar-overflow-button"
+                     class="toolbarbutton-1 chromeclass-toolbar-additional overflow-button"
+                     skipintoolbarset="true"
+                     tooltiptext="&navbarOverflow.label;">
+        <box class="toolbarbutton-animatable-box">
+          <image class="toolbarbutton-animatable-image"/>
+        </box>
+      </toolbarbutton>
+
+      <toolbaritem id="PanelUI-button"
+                   removable="false">
+        <toolbarbutton id="PanelUI-menu-button"
+                       class="toolbarbutton-1"
+                       badged="true"
+                       consumeanchor="PanelUI-button"
+                       label="&brandShortName;"
+                       tooltiptext="&appmenu.tooltip;"/>
+      </toolbaritem>
+
+      <hbox id="window-controls" hidden="true" pack="end" skipintoolbarset="true"
+            ordinal="1000">
+        <toolbarbutton id="minimize-button"
+                       tooltiptext="&fullScreenMinimize.tooltip;"
+                       oncommand="window.minimize();"/>
+
+        <toolbarbutton id="restore-button"
+#ifdef XP_MACOSX
+# Prior to 10.7 there wasn't a native fullscreen button so we use #restore-button
+# to exit fullscreen and want it to behave like other toolbar buttons.
+                       class="toolbarbutton-1"
+#endif
+                       tooltiptext="&fullScreenRestore.tooltip;"
+                       oncommand="BrowserFullScreen();"/>
+
+        <toolbarbutton id="close-button"
+                       tooltiptext="&fullScreenClose.tooltip;"
+                       oncommand="BrowserTryToCloseWindow();"/>
+      </hbox>
+
+      <box id="library-animatable-box" class="toolbarbutton-animatable-box">
+        <image class="toolbarbutton-animatable-image"/>
+      </box>
+    </toolbar>
+
+    <toolbar id="PersonalToolbar"
+             mode="icons"
+             class="browser-toolbar chromeclass-directories"
+             context="toolbar-context-menu"
+             toolbarname="&personalbarCmd.label;" accesskey="&personalbarCmd.accesskey;"
+             collapsed="true"
+             customizable="true">
+      <toolbartabstop skipintoolbarset="true"/>
+      <toolbaritem id="personal-bookmarks"
+                   title="&bookmarksToolbarItem.label;"
+                   cui-areatype="toolbar"
+                   removable="true">
+        <toolbarbutton id="bookmarks-toolbar-placeholder"
+                       class="bookmark-item"
+                       label="&bookmarksToolbarItem.label;"/>
+        <toolbarbutton id="bookmarks-toolbar-button"
+                       class="toolbarbutton-1"
+                       flex="1"
+                       label="&bookmarksToolbarItem.label;"
+                       oncommand="PlacesToolbarHelper.onPlaceholderCommand();"/>
+        <hbox flex="1"
+              id="PlacesToolbar"
+              context="placesContext"
+              onmouseup="BookmarksEventHandler.onMouseUp(event);"
+              onclick="BookmarksEventHandler.onClick(event, this._placesView);"
+              oncommand="BookmarksEventHandler.onCommand(event);"
+              tooltip="bhTooltip"
+              popupsinherittooltip="true">
+          <hbox flex="1">
+            <hbox id="PlacesToolbarDropIndicatorHolder" align="center" collapsed="true">
+              <image id="PlacesToolbarDropIndicator"
+                     mousethrough="always"
+                     collapsed="true"/>
+            </hbox>
+            <scrollbox orient="horizontal"
+                       id="PlacesToolbarItems"
+                       flex="1"/>
+            <toolbarbutton type="menu"
+                           id="PlacesChevron"
+                           class="toolbarbutton-1"
+                           mousethrough="never"
+                           collapsed="true"
+                           tooltiptext="&bookmarksToolbarChevron.tooltip;"
+                           onpopupshowing="document.getElementById('PlacesToolbar')
+                                                   ._placesView._onChevronPopupShowing(event);">
+              <menupopup id="PlacesChevronPopup"
+                         placespopup="true"
+                         tooltip="bhTooltip" popupsinherittooltip="true"
+                         context="placesContext"/>
+            </toolbarbutton>
+          </hbox>
+        </hbox>
+      </toolbaritem>
+    </toolbar>
+
+    <toolbarpalette id="BrowserToolbarPalette">
+
+      <toolbarbutton id="print-button" class="toolbarbutton-1 chromeclass-toolbar-additional"
+#ifdef XP_MACOSX
+                     command="cmd_print"
+                     tooltip="dynamic-shortcut-tooltip"
+#else
+                     command="cmd_printPreview"
+                     tooltiptext="&printButton.tooltip;"
+#endif
+                     label="&printButton.label;"/>
+
+
+      <toolbarbutton id="new-window-button" class="toolbarbutton-1 chromeclass-toolbar-additional"
+                     label="&newNavigatorCmd.label;"
+                     command="cmd_newNavigator"
+                     tooltip="dynamic-shortcut-tooltip"
+                     ondrop="newWindowButtonObserver.onDrop(event)"
+                     ondragover="newWindowButtonObserver.onDragOver(event)"
+                     ondragenter="newWindowButtonObserver.onDragOver(event)"
+                     ondragexit="newWindowButtonObserver.onDragExit(event)"/>
+
+      <toolbarbutton id="fullscreen-button" class="toolbarbutton-1 chromeclass-toolbar-additional"
+                     observes="View:FullScreen"
+                     type="checkbox"
+                     label="&fullScreenCmd.label;"
+                     tooltip="dynamic-shortcut-tooltip"/>
+
+      <toolbarbutton id="bookmarks-menu-button"
+                     class="toolbarbutton-1 chromeclass-toolbar-additional subviewbutton-nav"
+                     type="menu"
+                     label="&bookmarksMenuButton2.label;"
+                     tooltip="dynamic-shortcut-tooltip"
+                     ondragenter="PlacesMenuDNDHandler.onDragEnter(event);"
+                     ondragover="PlacesMenuDNDHandler.onDragOver(event);"
+                     ondragleave="PlacesMenuDNDHandler.onDragLeave(event);"
+                     ondrop="PlacesMenuDNDHandler.onDrop(event);"
+                     oncommand="BookmarkingUI.onCommand(event);">
+        <menupopup id="BMB_bookmarksPopup"
+                   class="cui-widget-panel cui-widget-panelview cui-widget-panelWithFooter PanelUI-subView"
+                   placespopup="true"
+                   context="placesContext"
+                   openInTabs="children"
+                   side="top"
+                   onmouseup="BookmarksEventHandler.onMouseUp(event);"
+                   oncommand="BookmarksEventHandler.onCommand(event);"
+                   onclick="BookmarksEventHandler.onClick(event, this.parentNode._placesView);"
+                   onpopupshowing="BookmarkingUI.onPopupShowing(event);
+                                   BookmarkingUI.attachPlacesView(event, this);"
+                   tooltip="bhTooltip" popupsinherittooltip="true">
+          <menuitem id="BMB_viewBookmarksSidebar"
+                    class="menuitem-iconic subviewbutton"
+                    label-show="&viewBookmarksSidebar2.label;"
+                    label-hide="&hideBookmarksSidebar.label;"
+                    oncommand="SidebarUI.toggle('viewBookmarksSidebar');"/>
+          <!-- NB: temporary solution for bug 985024, this should go away soon. -->
+          <menuitem id="BMB_bookmarksShowAllTop"
+                    class="menuitem-iconic subviewbutton"
+                    label="&showAllBookmarks2.label;"
+                    command="Browser:ShowAllBookmarks"
+                    key="manBookmarkKb"/>
+          <menuseparator/>
+          <menu id="BMB_bookmarksToolbar"
+                class="menu-iconic bookmark-item subviewbutton"
+                label="&personalbarCmd.label;"
+                container="true">
+            <menupopup id="BMB_bookmarksToolbarPopup"
+                       placespopup="true"
+                       context="placesContext"
+                       onpopupshowing="if (!this.parentNode._placesView)
+                                         new PlacesMenu(event, `place:parent=${PlacesUtils.bookmarks.toolbarGuid}`,
+                                                        PlacesUIUtils.getViewForNode(this.parentNode.parentNode).options);">
+              <menuitem id="BMB_viewBookmarksToolbar"
+                        class="menuitem-iconic subviewbutton"
+                        label-show="&viewBookmarksToolbar.label;"
+                        label-hide="&hideBookmarksToolbar.label;"
+                        oncommand="BookmarkingUI.toggleBookmarksToolbar();"/>
+              <menuseparator/>
+              <!-- Bookmarks toolbar items -->
+            </menupopup>
+          </menu>
+          <menu id="BMB_unsortedBookmarks"
+                class="menu-iconic bookmark-item subviewbutton"
+                label="&bookmarksMenuButton.other.label;"
+                container="true">
+            <menupopup id="BMB_unsortedBookmarksPopup"
+                       placespopup="true"
+                       context="placesContext"
+                       onpopupshowing="if (!this.parentNode._placesView)
+                                         new PlacesMenu(event, `place:parent=${PlacesUtils.bookmarks.unfiledGuid}`,
+                                                        PlacesUIUtils.getViewForNode(this.parentNode.parentNode).options);"/>
+          </menu>
+          <menu id="BMB_mobileBookmarks"
+                class="menu-iconic bookmark-item subviewbutton"
+                label="&bookmarksMenuButton.mobile.label;"
+                hidden="true"
+                container="true">
+            <menupopup id="BMB_mobileBookmarksPopup"
+                       placespopup="true"
+                       context="placesContext"
+                       onpopupshowing="if (!this.parentNode._placesView)
+                                         new PlacesMenu(event, `place:parent=${PlacesUtils.bookmarks.mobileGuid}`,
+                                                        PlacesUIUtils.getViewForNode(this.parentNode.parentNode).options);"/>
+          </menu>
+
+          <menuseparator/>
+          <!-- Bookmarks menu items will go here -->
+          <menuitem id="BMB_bookmarksShowAll"
+                    class="subviewbutton panel-subview-footer"
+                    label="&showAllBookmarks2.label;"
+                    command="Browser:ShowAllBookmarks"
+                    key="manBookmarkKb"/>
+        </menupopup>
+      </toolbarbutton>
+
+      <toolbaritem id="search-container"
+                   class="chromeclass-toolbar-additional"
+                   title="&searchItem.title;"
+                   align="center"
+                   flex="100"
+                   persist="width">
+        <toolbartabstop/>
+        <searchbar id="searchbar" flex="1"/>
+        <toolbartabstop/>
+      </toolbaritem>
+    </toolbarpalette>
+  </toolbox>
+
+  <hbox id="fullscr-toggler" hidden="true"/>
+
+  <deck id="content-deck" flex="1" renderroot="content">
+    <hbox flex="1" id="browser">
+      <vbox id="browser-border-start" hidden="true" layer="true"/>
+      <vbox id="sidebar-box" hidden="true" class="chromeclass-extrachrome">
+        <sidebarheader id="sidebar-header" align="center">
+          <toolbarbutton id="sidebar-switcher-target" flex="1" class="tabbable">
+            <image id="sidebar-icon" consumeanchor="sidebar-switcher-target"/>
+            <label id="sidebar-title" crop="end" flex="1" control="sidebar"/>
+            <image id="sidebar-switcher-arrow"/>
+          </toolbarbutton>
+          <image id="sidebar-throbber"/>
+# To ensure the button label's intrinsic width doesn't expand the sidebar
+# if the label is long, the button needs flex=1.
+# To ensure the button doesn't expand unnecessarily for short labels, the
+# spacer should significantly out-flex the button.
+          <spacer flex="1000"/>
+          <toolbarbutton id="sidebar-close" class="close-icon tabbable" tooltiptext="&sidebarCloseButton.tooltip;" oncommand="SidebarUI.hide();"/>
+        </sidebarheader>
+        <browser id="sidebar" flex="1" autoscroll="false" disablehistory="true" disablefullscreen="true"
+                  style="min-width: 14em; width: 18em; max-width: 36em;" tooltip="aHTMLTooltip"/>
+      </vbox>
+
+      <splitter id="sidebar-splitter" class="chromeclass-extrachrome sidebar-splitter" hidden="true"/>
+      <vbox id="appcontent" flex="1">
+        <!-- gHighPriorityNotificationBox will be added here lazily. -->
+        <tabbox id="tabbrowser-tabbox"
+                flex="1" tabcontainer="tabbrowser-tabs">
+          <tabpanels id="tabbrowser-tabpanels"
+                     flex="1" class="plain" selectedIndex="0"/>
+        </tabbox>
+      </vbox>
+      <vbox id="browser-border-end" hidden="true" layer="true"/>
+    </hbox>
+    <box id="customization-container" flex="1" hidden="true"><![CDATA[
+#include ../../components/customizableui/content/customizeMode.inc.xul
+    ]]></box>
+  </deck>
+
+  <html:div id="fullscreen-warning" class="pointerlockfswarning" hidden="true" renderroot="content">
+    <html:div class="pointerlockfswarning-domain-text">
+      &fullscreenWarning.beforeDomain.label;
+      <html:span class="pointerlockfswarning-domain"/>
+      &fullscreenWarning.afterDomain.label;
+    </html:div>
+    <html:div class="pointerlockfswarning-generic-text">
+      &fullscreenWarning.generic.label;
+    </html:div>
+    <html:button id="fullscreen-exit-button"
+                 onclick="FullScreen.exitDomFullScreen();">
+#ifdef XP_MACOSX
+            &exitDOMFullscreenMac.button;
+#else
+            &exitDOMFullscreen.button;
+#endif
+    </html:button>
+  </html:div>
+
+  <html:div id="pointerlock-warning" class="pointerlockfswarning" hidden="true" renderroot="content">
+    <html:div class="pointerlockfswarning-domain-text">
+      &pointerlockWarning.beforeDomain.label;
+      <html:span class="pointerlockfswarning-domain"/>
+      &pointerlockWarning.afterDomain.label;
+    </html:div>
+    <html:div class="pointerlockfswarning-generic-text">
+      &pointerlockWarning.generic.label;
+    </html:div>
+  </html:div>
+
+  <vbox id="browser-bottombox" layer="true" renderroot="content">
+    <!-- gNotificationBox will be added here lazily. -->
+  </vbox>
+</window>
diff --git a/browser/base/content/browser.xul b/browser/base/content/browser2.xhtml
copy from browser/base/content/browser.xul
copy to browser/base/content/browser2.xhtml