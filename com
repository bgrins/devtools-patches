# HG changeset patch
# User Brian Grinstead <bgrinstead@mozilla.com>
# Parent  f805f27183c35c40305a5deb0396182133195829

diff --git a/browser/base/content/browser.js b/browser/base/content/browser.js
--- a/browser/base/content/browser.js
+++ b/browser/base/content/browser.js
@@ -22,16 +22,17 @@ XPCOMUtils.defineLazyModuleGetters(this,
   NewTabPagePreloading: "resource:///modules/NewTabPagePreloading.jsm",
   BrowserSearchTelemetry: "resource:///modules/BrowserSearchTelemetry.jsm",
   BrowserUsageTelemetry: "resource:///modules/BrowserUsageTelemetry.jsm",
   BrowserUtils: "resource://gre/modules/BrowserUtils.jsm",
   BrowserWindowTracker: "resource:///modules/BrowserWindowTracker.jsm",
   CFRPageActions: "resource://activity-stream/lib/CFRPageActions.jsm",
   CharsetMenu: "resource://gre/modules/CharsetMenu.jsm",
   Color: "resource://gre/modules/Color.jsm",
+  CompanionWindow: "resource:///modules/Companion.jsm",
   ContentSearch: "resource:///modules/ContentSearch.jsm",
   ContextualIdentityService:
     "resource://gre/modules/ContextualIdentityService.jsm",
   CustomizableUI: "resource:///modules/CustomizableUI.jsm",
   Deprecated: "resource://gre/modules/Deprecated.jsm",
   DownloadsCommon: "resource:///modules/DownloadsCommon.jsm",
   DownloadUtils: "resource://gre/modules/DownloadUtils.jsm",
   E10SUtils: "resource://gre/modules/E10SUtils.jsm",
@@ -1725,16 +1726,28 @@ var gBrowserInit = {
     window.browserDOMWindow = new nsBrowserAccess();
 
     gBrowser = window._gBrowser;
     delete window._gBrowser;
     gBrowser.init();
 
     BrowserWindowTracker.track(window);
 
+    CompanionWindow.init();
+    window.addEventListener("keydown", e => {
+      if (e.key == "F10") {
+        CompanionWindow.focus();
+      }
+      // if (e.key == "Control" || e.key == "Shift") {
+      //   if (e.ctrlKey && e.shiftKey) {
+      //     CompanionWindow.focus();
+      //   }
+      // }
+    });
+
     gNavToolbox.palette = document.getElementById(
       "BrowserToolbarPalette"
     ).content;
     let areas = CustomizableUI.areas;
     areas.splice(areas.indexOf(CustomizableUI.AREA_FIXED_OVERFLOW_PANEL), 1);
     for (let area of areas) {
       let node = document.getElementById(area);
       CustomizableUI.registerToolbarNode(node);
diff --git a/browser/components/companion/Companion.jsm b/browser/components/companion/Companion.jsm
new file mode 100644
--- /dev/null
+++ b/browser/components/companion/Companion.jsm
@@ -0,0 +1,54 @@
+/* This Source Code Form is subject to the terms of the Mozilla Public
+ * License, v. 2.0. If a copy of the MPL was not distributed with this
+ * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
+"use strict";
+
+var EXPORTED_SYMBOLS = ["Companion", "CompanionWindow"];
+
+const { Services } = ChromeUtils.import("resource://gre/modules/Services.jsm");
+const { XPCOMUtils } = ChromeUtils.import(
+  "resource://gre/modules/XPCOMUtils.jsm"
+);
+const { AppConstants } = ChromeUtils.import(
+  "resource://gre/modules/AppConstants.jsm"
+);
+
+const CompanionWindow = {
+  init() {
+    console.log("hi");
+    this.win = Services.ww.openWindow(
+      null,
+      "chrome://browser/content/companion/companion.html",
+      "_blank",
+      "chrome",
+      []
+    );
+
+    this.win.addEventListener("keydown", e => {
+      if (e.key == "F10") {
+        CompanionWindow.blur();
+      }
+      // if (e.key == "Control" || e.key == "Shift") {
+      //   if (e.ctrlKey && e.shiftKey) {
+      //     CompanionWindow.blur();
+      //   }
+      // }
+    });
+  },
+
+  focus() {
+    if (!this.win) {
+      return;
+    }
+    this.win.focus();
+  },
+
+  blur() {
+    if (!this.win) {
+      return;
+    }
+    this.win.blur();
+  },
+};
+
+const Companion = {};
diff --git a/browser/components/companion/content/companion.css b/browser/components/companion/content/companion.css
new file mode 100644
--- /dev/null
+++ b/browser/components/companion/content/companion.css
@@ -0,0 +1,127 @@
+html {
+  appearance: auto;
+  -moz-default-appearance: dialog;
+  background-color: #FFFFFF;
+  color: -moz-DialogText;
+}
+body, html {
+  height: 100vh;
+  margin: 0;
+  padding: 0;
+  overflow: hidden;
+}
+
+body {
+  --toolbar-bgcolor: #fbfbfb;
+  --toolbar-border: #b5b5b5;
+  --toolbar-hover: #ebebeb;
+  --popup-bgcolor: #fbfbfb;
+  --popup-border: #b5b5b5;
+  --font-color: #4c4c4c;
+  --icon-fill: #808080;
+  --icon-disabled-fill: #8080807F;
+  /* light colours */
+}
+
+body.dark {
+  --toolbar-bgcolor: #2a2a2d;
+  --toolbar-border: #4B4A50;
+  --toolbar-hover: #737373;
+  --popup-bgcolor: #4b4a50;
+  --popup-border: #65646a;
+  --font-color: #fff;
+  --icon-fill: #fff;
+  --icon-disabled-fill: #ffffff66;
+  /* dark colours */
+}
+
+body {
+  display: grid;
+  grid-template-rows: auto minmax(0, 1fr);
+}
+
+#main {
+  padding: 0 var(--card-padding);
+  background: green;
+  overflow: scroll;
+  flex-grow: 1;
+}
+#main-inner {
+
+}
+#main-inner ul {
+  /* display: grid;
+  align-items: center;
+  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); */
+}
+named-deck > section {
+  display: flex;
+  height: 100%;
+}
+
+
+/* #sidebar {
+  border-right: 1px solid var(--in-content-box-border-color);
+  padding: 0 var(--card-padding);
+} */
+
+#timeline {
+  text-align: center;
+}
+
+.tab-group {
+  margin-top: 0 !important;
+  padding: 0 var(--card-padding) !important;
+}
+button.tab-button {
+  padding: 4px 6px !important;
+}
+/* Copied from aboutaddons.css */
+
+.tab-group {
+  display: block;
+  margin-top: 8px;
+  /* Pull the buttons flush with the side of the card */
+  margin-inline: calc(var(--card-padding) * -1);
+  border-bottom: 1px solid var(--in-content-box-border-color);
+  border-top: 1px solid var(--in-content-box-border-color);
+  font-size: 0;
+  line-height: 0;
+}
+
+button.tab-button {
+  appearance: none;
+  border-inline: none;
+  border-block: 2px solid transparent;
+  border-radius: 0;
+  background: transparent;
+  font-size: 14px;
+  line-height: 20px;
+  margin: 0;
+  padding: 4px 16px;
+  color: var(--in-content-text-color);
+}
+
+button.tab-button:hover {
+  background-color: var(--in-content-button-background);
+  border-top-color: var(--in-content-box-border-color);
+}
+
+button.tab-button:hover:active {
+  background-color: var(--in-content-button-background-hover);
+}
+
+button.tab-button[selected] {
+  border-top-color: var(--in-content-border-highlight);
+  color: var(--in-content-category-text-selected) !important;
+}
+
+button.tab-button:-moz-focusring {
+  outline-offset: -2px;
+  -moz-outline-radius: 0;
+}
+
+.tab-group[last-input-type="mouse"] > button.tab-button:-moz-focusring {
+  outline: none;
+  box-shadow: none;
+}
\ No newline at end of file
diff --git a/browser/components/companion/content/companion.html b/browser/components/companion/content/companion.html
new file mode 100644
--- /dev/null
+++ b/browser/components/companion/content/companion.html
@@ -0,0 +1,146 @@
+<!-- This Source Code Form is subject to the terms of the Mozilla Public
+   - License, v. 2.0. If a copy of the MPL was not distributed with this
+   - file, You can obtain one at http://mozilla.org/MPL/2.0/. -->
+<!DOCTYPE html>
+<html dir="" windowtype="browser:companion" width="900" height="350" persist="screenX screenY width height sizemode">
+
+<head>
+  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
+  <link rel="stylesheet" href="chrome://global/skin/global.css" />
+
+
+  <link rel="stylesheet" href="chrome://global/skin/in-content/common.css">
+  <link rel="stylesheet" href="chrome://global/skin/in-content/toggle-button.css">
+  <link rel="stylesheet" href="chrome://browser/content/companion/companion.css" />
+  <script src="chrome://mozapps/content/extensions/named-deck.js"></script>
+</head>
+
+<body role="application">
+  <button-group class="tab-group">
+    <button is="named-deck-button" deck="details-deck" name="details" data-l10n-id="details-addon-button"
+      class="tab-button">Timeline</button>
+    <button is="named-deck-button" deck="details-deck" name="preferences" data-l10n-id="preferences-addon-button"
+      class="tab-button">Windows</button>
+    <button is="named-deck-button" deck="details-deck" name="permissions" data-l10n-id="permissions-addon-button"
+      class="tab-button">Tasks</button>
+  </button-group>
+  <named-deck id="details-deck">
+    <section name="details">
+      <aside>
+        <div id="timeline">
+          <div><button>Today</button></div>
+          <div>.</div>
+          <div>.</div>
+          <div><button>Yesterday</button></div>
+          <div>.</div>
+          <div>.</div>
+          <div>.</div>
+          <div><button>Last week</button></div>
+        </div>
+      </aside>
+      <div id="main">
+        <div id="main-inner"></div>
+      </div>
+    </section>
+    <section name="preferences">
+      asdf
+    </section>
+    <section name="permissions">
+      a</section>
+  </named-deck>
+  <!--
+  <div id="root">
+  <link rel="stylesheet" href="chrome://activity-stream/content/css/activity-stream.css" />
+
+  <div class="discovery-stream ds-layout"><div class="ds-column ds-column-12"><div class="ds-column-grid"><div><div><div class="ds-card-grid ds-card-grid-border "><div class="ds-card "><a href="https://getpocket.com/explore/item/recipe-5-ingredient-kale-caesar-salad?utm_source=pocket-newtab" class="ds-card-link"><div class="img-wrapper"><picture class="ds-image
+    img
+   
+    loaded
+ "><img loading="lazy" crossorigin="anonymous" sizes="(min-width: 1122px) 296px,(min-width: 866px) 218px,(max-width: 610px) 202px,202px" src="https://pocket-image-cache.com/1200x/filters:no_upscale():format(jpg):extract_cover()/https%3A%2F%2Fpocket-syndicated-images.s3.amazonaws.com%2Farticles%2F5572%2F1599050937_at_archive_01f15b0491662278e56104cf50ab499e7f6e2a8f.jpg" srcset="https://img-getpocket.cdn.mozilla.net/296x148/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fpocket-syndicated-images.s3.amazonaws.com%252Farticles%252F5572%252F1599050937_at_archive_01f15b0491662278e56104cf50ab499e7f6e2a8f.jpg 296w,https://img-getpocket.cdn.mozilla.net/592x296/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fpocket-syndicated-images.s3.amazonaws.com%252Farticles%252F5572%252F1599050937_at_archive_01f15b0491662278e56104cf50ab499e7f6e2a8f.jpg 592w,https://img-getpocket.cdn.mozilla.net/218x109/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fpocket-syndicated-images.s3.amazonaws.com%252Farticles%252F5572%252F1599050937_at_archive_01f15b0491662278e56104cf50ab499e7f6e2a8f.jpg 218w,https://img-getpocket.cdn.mozilla.net/436x218/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fpocket-syndicated-images.s3.amazonaws.com%252Farticles%252F5572%252F1599050937_at_archive_01f15b0491662278e56104cf50ab499e7f6e2a8f.jpg 436w,https://img-getpocket.cdn.mozilla.net/202x101/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fpocket-syndicated-images.s3.amazonaws.com%252Farticles%252F5572%252F1599050937_at_archive_01f15b0491662278e56104cf50ab499e7f6e2a8f.jpg 202w,https://img-getpocket.cdn.mozilla.net/404x202/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fpocket-syndicated-images.s3.amazonaws.com%252Farticles%252F5572%252F1599050937_at_archive_01f15b0491662278e56104cf50ab499e7f6e2a8f.jpg 404w"></picture></div><div class="meta"><div class="info-wrap"><p class="source clamp">thekitchn.com</p><header class="title clamp">Recipe: 5-Ingredient Kale Caesar Salad</header><p class="excerpt clamp">A twist on the beloved classic that’s great for meal prep.</p></div><div class="story-footer"></div></div><div class="impression-observer"></div></a><div><button aria-haspopup="true" data-l10n-id="newtab-menu-content-tooltip" data-l10n-args="{&quot;title&quot;:&quot;Recipe: 5-Ingredient Kale Caesar Salad&quot;}" class="context-menu-button icon" title="Open menu" aria-label="Open context menu for Recipe: 5-Ingredient Kale Caesar Salad"></button></div></div><div class="ds-card "><a href="https://getpocket.com/explore/best-of-2020?utm_source=pocket-newtab" class="ds-card-link"><div class="img-wrapper"><picture class="ds-image
+    img
+   
+    loaded
+ "><img loading="lazy" crossorigin="anonymous" sizes="(min-width: 1122px) 296px,(min-width: 866px) 218px,(max-width: 610px) 202px,202px" src="https://new-tab-assets.getpocket.com/eoy-2020/bestOf-newTab-3.png" srcset="https://img-getpocket.cdn.mozilla.net/296x148/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fnew-tab-assets.getpocket.com%2Feoy-2020%2FbestOf-newTab-3.png 296w,https://img-getpocket.cdn.mozilla.net/592x296/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fnew-tab-assets.getpocket.com%2Feoy-2020%2FbestOf-newTab-3.png 592w,https://img-getpocket.cdn.mozilla.net/218x109/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fnew-tab-assets.getpocket.com%2Feoy-2020%2FbestOf-newTab-3.png 218w,https://img-getpocket.cdn.mozilla.net/436x218/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fnew-tab-assets.getpocket.com%2Feoy-2020%2FbestOf-newTab-3.png 436w,https://img-getpocket.cdn.mozilla.net/202x101/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fnew-tab-assets.getpocket.com%2Feoy-2020%2FbestOf-newTab-3.png 202w,https://img-getpocket.cdn.mozilla.net/404x202/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fnew-tab-assets.getpocket.com%2Feoy-2020%2FbestOf-newTab-3.png 404w"></picture></div><div class="meta"><div class="info-wrap"><p class="source clamp">getpocket.com</p><header class="title clamp">Explore 2020’s Top Articles on Pocket</header><p class="excerpt clamp">Fuel your mind with the best of science, technology, long reads, and more.</p></div><div class="story-footer"></div></div><div class="impression-observer"></div></a><div><button aria-haspopup="true" data-l10n-id="newtab-menu-content-tooltip" data-l10n-args="{&quot;title&quot;:&quot;Explore 2020’s Top Articles on Pocket&quot;}" class="context-menu-button icon" title="Open menu" aria-label="Open context menu for Explore 2020’s Top Articles on Pocket"></button></div></div><div class="ds-card "><a href="https://monday.com/lp/mb/pmfun/?utm_source=mb&amp;utm_campaign=pocketlp&amp;utm_banner=pmfun5" class="ds-card-link"><div class="img-wrapper"><picture class="ds-image
+    img
+   
+    loaded
+ "><img loading="lazy" crossorigin="anonymous" sizes="(min-width: 1122px) 296px,(min-width: 866px) 218px,(max-width: 610px) 202px,202px" src="https://s.zkcdn.net/Advertisers/317531ca399d40979c1153da476a0394.png" srcset="https://img-getpocket.cdn.mozilla.net/296x148/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fs.zkcdn.net%2FAdvertisers%2F317531ca399d40979c1153da476a0394.png 296w,https://img-getpocket.cdn.mozilla.net/592x296/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fs.zkcdn.net%2FAdvertisers%2F317531ca399d40979c1153da476a0394.png 592w,https://img-getpocket.cdn.mozilla.net/218x109/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fs.zkcdn.net%2FAdvertisers%2F317531ca399d40979c1153da476a0394.png 218w,https://img-getpocket.cdn.mozilla.net/436x218/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fs.zkcdn.net%2FAdvertisers%2F317531ca399d40979c1153da476a0394.png 436w,https://img-getpocket.cdn.mozilla.net/202x101/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fs.zkcdn.net%2FAdvertisers%2F317531ca399d40979c1153da476a0394.png 202w,https://img-getpocket.cdn.mozilla.net/404x202/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fs.zkcdn.net%2FAdvertisers%2F317531ca399d40979c1153da476a0394.png 404w"></picture></div><div class="meta"><div class="info-wrap"><p class="source clamp">monday.com</p><header class="title clamp">Plan All Your Assignments in One Place With monday.com</header><p class="excerpt clamp">Let your team focus on what’s important and see who’s in charge of what in one collaborative tool.</p></div><div class="story-footer"><p class="story-sponsored-label clamp"><span data-l10n-args="{&quot;sponsor&quot;:&quot;monday.com&quot;}" data-l10n-id="newtab-label-sponsored-by">Sponsored by monday.com</span></p></div></div><div class="impression-observer"></div></a><div><button aria-haspopup="true" data-l10n-id="newtab-menu-content-tooltip" data-l10n-args="{&quot;title&quot;:&quot;Plan All Your Assignments in One Place With monday.com&quot;}" class="context-menu-button icon" title="Open menu" aria-label="Open context menu for Plan All Your Assignments in One Place With monday.com"></button></div></div><div class="ds-card "><a href="https://www.bbc.com/future/article/20201210-lockheed-u-2-spyplane?utm_source=pocket-newtab" class="ds-card-link"><div class="img-wrapper"><picture class="ds-image
+    img
+    use-transition
+   
+ "><img loading="lazy" crossorigin="anonymous" sizes="(min-width: 1122px) 296px,(min-width: 866px) 218px,(max-width: 610px) 202px,202px" src="https://ychef.files.bbci.co.uk/live/624x351/p0910j7g.jpg" srcset="https://img-getpocket.cdn.mozilla.net/296x148/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fychef.files.bbci.co.uk%2Flive%2F624x351%2Fp0910j7g.jpg 296w,https://img-getpocket.cdn.mozilla.net/592x296/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fychef.files.bbci.co.uk%2Flive%2F624x351%2Fp0910j7g.jpg 592w,https://img-getpocket.cdn.mozilla.net/218x109/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fychef.files.bbci.co.uk%2Flive%2F624x351%2Fp0910j7g.jpg 218w,https://img-getpocket.cdn.mozilla.net/436x218/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fychef.files.bbci.co.uk%2Flive%2F624x351%2Fp0910j7g.jpg 436w,https://img-getpocket.cdn.mozilla.net/202x101/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fychef.files.bbci.co.uk%2Flive%2F624x351%2Fp0910j7g.jpg 202w,https://img-getpocket.cdn.mozilla.net/404x202/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fychef.files.bbci.co.uk%2Flive%2F624x351%2Fp0910j7g.jpg 404w"></picture></div><div class="meta"><div class="info-wrap"><p class="source clamp">bbc.com</p><header class="title clamp">The veteran spyplane too valuable to replace</header><p class="excerpt clamp">Satellites – and drones – were intended to replace it. But the 65-year-old Lockheed U-2 is still at the top of its game, flying missions in an environment no other aircraft can operate in.</p></div><div class="story-footer"></div></div><div class="impression-observer"></div></a><div><button aria-haspopup="true" data-l10n-id="newtab-menu-content-tooltip" data-l10n-args="{&quot;title&quot;:&quot;The veteran spyplane too valuable to replace&quot;}" class="context-menu-button icon" title="Open menu" aria-label="Open context menu for The veteran spyplane too valuable to replace"></button></div></div><div class="ds-card "><a href="https://auto.everquote.com/?h1=drive_less&amp;h2=25_miles&amp;auuid=8c0e2634-28e3-498c-8168-a070c05b7bf2&amp;tid=1601&amp;cok=g" class="ds-card-link"><div class="img-wrapper"><picture class="ds-image
+    img
+    use-transition
+   
+ "><img loading="lazy" crossorigin="anonymous" sizes="(min-width: 1122px) 296px,(min-width: 866px) 218px,(max-width: 610px) 202px,202px" src="https://s.zkcdn.net/Advertisers/79f5ddf0721e4246b3df31610aa82a5d.jpg" srcset="https://img-getpocket.cdn.mozilla.net/296x148/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fs.zkcdn.net%2FAdvertisers%2F79f5ddf0721e4246b3df31610aa82a5d.jpg 296w,https://img-getpocket.cdn.mozilla.net/592x296/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fs.zkcdn.net%2FAdvertisers%2F79f5ddf0721e4246b3df31610aa82a5d.jpg 592w,https://img-getpocket.cdn.mozilla.net/218x109/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fs.zkcdn.net%2FAdvertisers%2F79f5ddf0721e4246b3df31610aa82a5d.jpg 218w,https://img-getpocket.cdn.mozilla.net/436x218/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fs.zkcdn.net%2FAdvertisers%2F79f5ddf0721e4246b3df31610aa82a5d.jpg 436w,https://img-getpocket.cdn.mozilla.net/202x101/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fs.zkcdn.net%2FAdvertisers%2F79f5ddf0721e4246b3df31610aa82a5d.jpg 202w,https://img-getpocket.cdn.mozilla.net/404x202/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fs.zkcdn.net%2FAdvertisers%2F79f5ddf0721e4246b3df31610aa82a5d.jpg 404w"></picture></div><div class="meta"><div class="info-wrap"><p class="source clamp">everquote.com</p><header class="title clamp">Is Your Car Driven Less Than 32.88 Miles a Day?</header><p class="excerpt clamp">Driving less could mean big savings. Compare rates today before you get back on the road again.</p></div><div class="story-footer"><p class="story-sponsored-label clamp"><span data-l10n-args="{&quot;sponsor&quot;:&quot;EverQuote&quot;}" data-l10n-id="newtab-label-sponsored-by">Sponsored by EverQuote</span></p></div></div><div class="impression-observer"></div></a><div><button aria-haspopup="true" data-l10n-id="newtab-menu-content-tooltip" data-l10n-args="{&quot;title&quot;:&quot;Is Your Car Driven Less Than 32.88 Miles a Day?&quot;}" class="context-menu-button icon" title="Open menu" aria-label="Open context menu for Is Your Car Driven Less Than 32.88 Miles a Day?"></button></div></div><div class="ds-card "><a href="https://slate.com/technology/2020/12/why-are-the-best-chess-players-men.html?utm_source=pocket-newtab" class="ds-card-link"><div class="img-wrapper"><picture class="ds-image
+    img
+    use-transition
+   
+ "><img loading="lazy" crossorigin="anonymous" sizes="(min-width: 1122px) 296px,(min-width: 866px) 218px,(max-width: 610px) 202px,202px" src="https://compote.slate.com/images/a7a63f55-ec96-417b-9acf-d4c15d91f67d.jpeg?width=780&amp;height=520&amp;rect=1560x1040&amp;offset=0x0" srcset="https://img-getpocket.cdn.mozilla.net/296x148/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fcompote.slate.com%2Fimages%2Fa7a63f55-ec96-417b-9acf-d4c15d91f67d.jpeg%3Fwidth%3D780%26height%3D520%26rect%3D1560x1040%26offset%3D0x0 296w,https://img-getpocket.cdn.mozilla.net/592x296/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fcompote.slate.com%2Fimages%2Fa7a63f55-ec96-417b-9acf-d4c15d91f67d.jpeg%3Fwidth%3D780%26height%3D520%26rect%3D1560x1040%26offset%3D0x0 592w,https://img-getpocket.cdn.mozilla.net/218x109/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fcompote.slate.com%2Fimages%2Fa7a63f55-ec96-417b-9acf-d4c15d91f67d.jpeg%3Fwidth%3D780%26height%3D520%26rect%3D1560x1040%26offset%3D0x0 218w,https://img-getpocket.cdn.mozilla.net/436x218/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fcompote.slate.com%2Fimages%2Fa7a63f55-ec96-417b-9acf-d4c15d91f67d.jpeg%3Fwidth%3D780%26height%3D520%26rect%3D1560x1040%26offset%3D0x0 436w,https://img-getpocket.cdn.mozilla.net/202x101/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fcompote.slate.com%2Fimages%2Fa7a63f55-ec96-417b-9acf-d4c15d91f67d.jpeg%3Fwidth%3D780%26height%3D520%26rect%3D1560x1040%26offset%3D0x0 202w,https://img-getpocket.cdn.mozilla.net/404x202/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fcompote.slate.com%2Fimages%2Fa7a63f55-ec96-417b-9acf-d4c15d91f67d.jpeg%3Fwidth%3D780%26height%3D520%26rect%3D1560x1040%26offset%3D0x0 404w"></picture></div><div class="meta"><div class="info-wrap"><p class="source clamp">slate.com</p><header class="title clamp">The Real Reasons All the Top Chess Players Are Men</header><p class="excerpt clamp">The fact that top male players are consistently ranked higher than top female players may have nothing to do with talent, and everything to do with statistics and external factors.</p></div><div class="story-footer"></div></div><div class="impression-observer"></div></a><div><button aria-haspopup="true" data-l10n-id="newtab-menu-content-tooltip" data-l10n-args="{&quot;title&quot;:&quot;The Real Reasons All the Top Chess Players Are Men&quot;}" class="context-menu-button icon" title="Open menu" aria-label="Open context menu for The Real Reasons All the Top Chess Players Are Men"></button></div></div><div class="ds-card "><a href="https://getpocket.com/explore/item/until-i-was-a-man-i-had-no-idea-how-good-men-had-it-at-work?utm_source=pocket-newtab" class="ds-card-link"><div class="img-wrapper"><picture class="ds-image
+    img
+    use-transition
+   
+ "><img loading="lazy" crossorigin="anonymous" sizes="(min-width: 1122px) 296px,(min-width: 866px) 218px,(max-width: 610px) 202px,202px" src="https://pocket-image-cache.com/1200x/filters:no_upscale():format(jpg):extract_cover()/https%3A%2F%2Fs3.amazonaws.com%2Fpocket-syndicated-images%2Farticles%2F2048%2F1572274781_draper.jpg" srcset="https://img-getpocket.cdn.mozilla.net/296x148/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fs3.amazonaws.com%252Fpocket-syndicated-images%252Farticles%252F2048%252F1572274781_draper.jpg 296w,https://img-getpocket.cdn.mozilla.net/592x296/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fs3.amazonaws.com%252Fpocket-syndicated-images%252Farticles%252F2048%252F1572274781_draper.jpg 592w,https://img-getpocket.cdn.mozilla.net/218x109/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fs3.amazonaws.com%252Fpocket-syndicated-images%252Farticles%252F2048%252F1572274781_draper.jpg 218w,https://img-getpocket.cdn.mozilla.net/436x218/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fs3.amazonaws.com%252Fpocket-syndicated-images%252Farticles%252F2048%252F1572274781_draper.jpg 436w,https://img-getpocket.cdn.mozilla.net/202x101/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fs3.amazonaws.com%252Fpocket-syndicated-images%252Farticles%252F2048%252F1572274781_draper.jpg 202w,https://img-getpocket.cdn.mozilla.net/404x202/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fs3.amazonaws.com%252Fpocket-syndicated-images%252Farticles%252F2048%252F1572274781_draper.jpg 404w"></picture></div><div class="meta"><div class="info-wrap"><p class="source clamp">qz.com</p><header class="title clamp">Until I Was a Man, I Had No Idea How Good Men Had It at Work</header><p class="excerpt clamp">The reach&nbsp;of implicit bias is troubling, it can even get instilled into our “best” business practices.</p></div><div class="story-footer"></div></div><div class="impression-observer"></div></a><div><button aria-haspopup="true" data-l10n-id="newtab-menu-content-tooltip" data-l10n-args="{&quot;title&quot;:&quot;Until I Was a Man, I Had No Idea How Good Men Had It at Work&quot;}" class="context-menu-button icon" title="Open menu" aria-label="Open context menu for Until I Was a Man, I Had No Idea How Good Men Had It at Work"></button></div></div><div class="ds-card "><a href="https://getpocket.com/explore/item/the-bed-that-saved-me-from-the-taliban?utm_source=pocket-newtab" class="ds-card-link"><div class="img-wrapper"><picture class="ds-image
+    img
+    use-transition
+   
+ "><img loading="lazy" crossorigin="anonymous" sizes="(min-width: 1122px) 296px,(min-width: 866px) 218px,(max-width: 610px) 202px,202px" src="https://pocket-image-cache.com/1200x/filters:no_upscale():format(jpg):extract_cover()/https%3A%2F%2Fpocket-syndicated-images.s3.amazonaws.com%2Farticles%2F2190%2F1589211744__105194479_img-20181206-wa0000.jpg" srcset="https://img-getpocket.cdn.mozilla.net/296x148/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fpocket-syndicated-images.s3.amazonaws.com%252Farticles%252F2190%252F1589211744__105194479_img-20181206-wa0000.jpg 296w,https://img-getpocket.cdn.mozilla.net/592x296/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fpocket-syndicated-images.s3.amazonaws.com%252Farticles%252F2190%252F1589211744__105194479_img-20181206-wa0000.jpg 592w,https://img-getpocket.cdn.mozilla.net/218x109/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fpocket-syndicated-images.s3.amazonaws.com%252Farticles%252F2190%252F1589211744__105194479_img-20181206-wa0000.jpg 218w,https://img-getpocket.cdn.mozilla.net/436x218/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fpocket-syndicated-images.s3.amazonaws.com%252Farticles%252F2190%252F1589211744__105194479_img-20181206-wa0000.jpg 436w,https://img-getpocket.cdn.mozilla.net/202x101/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fpocket-syndicated-images.s3.amazonaws.com%252Farticles%252F2190%252F1589211744__105194479_img-20181206-wa0000.jpg 202w,https://img-getpocket.cdn.mozilla.net/404x202/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fpocket-syndicated-images.s3.amazonaws.com%252Farticles%252F2190%252F1589211744__105194479_img-20181206-wa0000.jpg 404w"></picture></div><div class="meta"><div class="info-wrap"><p class="source clamp">bbc.com</p><header class="title clamp">‘The Bed That Saved Me From the Taliban’</header><p class="excerpt clamp">In 2018, Greek pilot Vasileios Vasileiou checked into a luxury hilltop hotel in Kabul that was popular among foreign visitors. Then Taliban gunmen stormed it, killing at least 40 people. Vasileios explains how he survived.</p></div><div class="story-footer"></div></div><div class="impression-observer"></div></a><div><button aria-haspopup="true" data-l10n-id="newtab-menu-content-tooltip" data-l10n-args="{&quot;title&quot;:&quot;‘The Bed That Saved Me From the Taliban’&quot;}" class="context-menu-button icon" title="Open menu" aria-label="Open context menu for ‘The Bed That Saved Me From the Taliban’"></button></div></div><div class="ds-card "><a href="https://getpocket.com/explore/item/my-life-without-sugar?utm_source=pocket-newtab" class="ds-card-link"><div class="img-wrapper"><picture class="ds-image
+    img
+    use-transition
+   
+ "><img loading="lazy" crossorigin="anonymous" sizes="(min-width: 1122px) 296px,(min-width: 866px) 218px,(max-width: 610px) 202px,202px" src="https://pocket-image-cache.com/1200x/filters:no_upscale():format(jpg):extract_cover()/https%3A%2F%2Fs3.amazonaws.com%2Fpocket-syndicated-images%2Farticles%2F1463%2F1567048471_GettyImages-1163613086.jpg" srcset="https://img-getpocket.cdn.mozilla.net/296x148/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fs3.amazonaws.com%252Fpocket-syndicated-images%252Farticles%252F1463%252F1567048471_GettyImages-1163613086.jpg 296w,https://img-getpocket.cdn.mozilla.net/592x296/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fs3.amazonaws.com%252Fpocket-syndicated-images%252Farticles%252F1463%252F1567048471_GettyImages-1163613086.jpg 592w,https://img-getpocket.cdn.mozilla.net/218x109/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fs3.amazonaws.com%252Fpocket-syndicated-images%252Farticles%252F1463%252F1567048471_GettyImages-1163613086.jpg 218w,https://img-getpocket.cdn.mozilla.net/436x218/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fs3.amazonaws.com%252Fpocket-syndicated-images%252Farticles%252F1463%252F1567048471_GettyImages-1163613086.jpg 436w,https://img-getpocket.cdn.mozilla.net/202x101/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fs3.amazonaws.com%252Fpocket-syndicated-images%252Farticles%252F1463%252F1567048471_GettyImages-1163613086.jpg 202w,https://img-getpocket.cdn.mozilla.net/404x202/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fs3.amazonaws.com%252Fpocket-syndicated-images%252Farticles%252F1463%252F1567048471_GettyImages-1163613086.jpg 404w"></picture></div><div class="meta"><div class="info-wrap"><p class="source clamp">theguardian.com</p><header class="title clamp">My Life Without Sugar</header><p class="excerpt clamp">My plan was to have a sugar-free month. But now I feel so much better that I can’t imagine going back.</p></div><div class="story-footer"></div></div><div class="impression-observer"></div></a><div><button aria-haspopup="true" data-l10n-id="newtab-menu-content-tooltip" data-l10n-args="{&quot;title&quot;:&quot;My Life Without Sugar&quot;}" class="context-menu-button icon" title="Open menu" aria-label="Open context menu for My Life Without Sugar"></button></div></div><div class="ds-card "><a href="https://www.nytimes.com/2020/12/14/sports/basketball/anthony-carter-bill-duffy-miami-heat.html?utm_source=pocket-newtab" class="ds-card-link"><div class="img-wrapper"><picture class="ds-image
+    img
+    use-transition
+   
+ "><img loading="lazy" crossorigin="anonymous" sizes="(min-width: 1122px) 296px,(min-width: 866px) 218px,(max-width: 610px) 202px,202px" src="https://static01.nyt.com/images/2020/12/14/sports/14nba-carter/14nba-carter-facebookJumbo.jpg" srcset="https://img-getpocket.cdn.mozilla.net/296x148/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fstatic01.nyt.com%2Fimages%2F2020%2F12%2F14%2Fsports%2F14nba-carter%2F14nba-carter-facebookJumbo.jpg 296w,https://img-getpocket.cdn.mozilla.net/592x296/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fstatic01.nyt.com%2Fimages%2F2020%2F12%2F14%2Fsports%2F14nba-carter%2F14nba-carter-facebookJumbo.jpg 592w,https://img-getpocket.cdn.mozilla.net/218x109/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fstatic01.nyt.com%2Fimages%2F2020%2F12%2F14%2Fsports%2F14nba-carter%2F14nba-carter-facebookJumbo.jpg 218w,https://img-getpocket.cdn.mozilla.net/436x218/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fstatic01.nyt.com%2Fimages%2F2020%2F12%2F14%2Fsports%2F14nba-carter%2F14nba-carter-facebookJumbo.jpg 436w,https://img-getpocket.cdn.mozilla.net/202x101/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fstatic01.nyt.com%2Fimages%2F2020%2F12%2F14%2Fsports%2F14nba-carter%2F14nba-carter-facebookJumbo.jpg 202w,https://img-getpocket.cdn.mozilla.net/404x202/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fstatic01.nyt.com%2Fimages%2F2020%2F12%2F14%2Fsports%2F14nba-carter%2F14nba-carter-facebookJumbo.jpg 404w"></picture></div><div class="meta"><div class="info-wrap"><p class="source clamp">nytimes.com</p><header class="title clamp">An Agent’s Mistake Cost an N.B.A. Player $3 Million. He Paid Him Back.</header><p class="excerpt clamp">All Bill Duffy had to do was inform the Miami Heat that Anthony Carter planned to return. Two decades after failing to do that, Duffy has made his client whole.</p></div><div class="story-footer"></div></div><div class="impression-observer"></div></a><div><button aria-haspopup="true" data-l10n-id="newtab-menu-content-tooltip" data-l10n-args="{&quot;title&quot;:&quot;An Agent’s Mistake Cost an N.B.A. Player $3 Million. He Paid Him Back.&quot;}" class="context-menu-button icon" title="Open menu" aria-label="Open context menu for An Agent’s Mistake Cost an N.B.A. Player $3 Million. He Paid Him Back."></button></div></div><div class="ds-card "><a href="https://getpocket.com/explore/item/4-shower-products-that-are-ruining-your-pipes-according-to-plumbers?utm_source=pocket-newtab" class="ds-card-link"><div class="img-wrapper"><picture class="ds-image
+    img
+    use-transition
+   
+ "><img loading="lazy" crossorigin="anonymous" sizes="(min-width: 1122px) 296px,(min-width: 866px) 218px,(max-width: 610px) 202px,202px" src="https://pocket-image-cache.com/1200x/filters:no_upscale():format(jpg):extract_cover()/https%3A%2F%2Fpocket-syndicated-images.s3.amazonaws.com%2Farticles%2F5232%2F1596128252_ezgif.com-webp-to-jpg28.jpgcrop.jpg22.jpg" srcset="https://img-getpocket.cdn.mozilla.net/296x148/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fpocket-syndicated-images.s3.amazonaws.com%252Farticles%252F5232%252F1596128252_ezgif.com-webp-to-jpg28.jpgcrop.jpg22.jpg 296w,https://img-getpocket.cdn.mozilla.net/592x296/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fpocket-syndicated-images.s3.amazonaws.com%252Farticles%252F5232%252F1596128252_ezgif.com-webp-to-jpg28.jpgcrop.jpg22.jpg 592w,https://img-getpocket.cdn.mozilla.net/218x109/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fpocket-syndicated-images.s3.amazonaws.com%252Farticles%252F5232%252F1596128252_ezgif.com-webp-to-jpg28.jpgcrop.jpg22.jpg 218w,https://img-getpocket.cdn.mozilla.net/436x218/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fpocket-syndicated-images.s3.amazonaws.com%252Farticles%252F5232%252F1596128252_ezgif.com-webp-to-jpg28.jpgcrop.jpg22.jpg 436w,https://img-getpocket.cdn.mozilla.net/202x101/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fpocket-syndicated-images.s3.amazonaws.com%252Farticles%252F5232%252F1596128252_ezgif.com-webp-to-jpg28.jpgcrop.jpg22.jpg 202w,https://img-getpocket.cdn.mozilla.net/404x202/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fpocket-syndicated-images.s3.amazonaws.com%252Farticles%252F5232%252F1596128252_ezgif.com-webp-to-jpg28.jpgcrop.jpg22.jpg 404w"></picture></div><div class="meta"><div class="info-wrap"><p class="source clamp">apartmenttherapy.com</p><header class="title clamp">4 Shower Products That Are Ruining Your Pipes, According to Plumbers</header><p class="excerpt clamp">What to skip, what’s safe, and how to fix any problems that do pop up.</p></div><div class="story-footer"></div></div><div class="impression-observer"></div></a><div><button aria-haspopup="true" data-l10n-id="newtab-menu-content-tooltip" data-l10n-args="{&quot;title&quot;:&quot;4 Shower Products That Are Ruining Your Pipes, According to Plumbers&quot;}" class="context-menu-button icon" title="Open menu" aria-label="Open context menu for 4 Shower Products That Are Ruining Your Pipes, According to Plumbers"></button></div></div><div class="ds-card "><a href="https://go.helixsleep.com/the-best-mattress-in-a-box/?utm_source=firefox&amp;utm_medium=influnencer-laying-stomach-reading&amp;utm_campaign=newtab&amp;utm_term=bestmattress2020&amp;utm_content=gqonhelix" class="ds-card-link"><div class="img-wrapper"><picture class="ds-image
+    img
+    use-transition
+   
+ "><img loading="lazy" crossorigin="anonymous" sizes="(min-width: 1122px) 296px,(min-width: 866px) 218px,(max-width: 610px) 202px,202px" src="https://s.zkcdn.net/Advertisers/69c9565d37a24e159983d91b37cc3513.png" srcset="https://img-getpocket.cdn.mozilla.net/296x148/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fs.zkcdn.net%2FAdvertisers%2F69c9565d37a24e159983d91b37cc3513.png 296w,https://img-getpocket.cdn.mozilla.net/592x296/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fs.zkcdn.net%2FAdvertisers%2F69c9565d37a24e159983d91b37cc3513.png 592w,https://img-getpocket.cdn.mozilla.net/218x109/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fs.zkcdn.net%2FAdvertisers%2F69c9565d37a24e159983d91b37cc3513.png 218w,https://img-getpocket.cdn.mozilla.net/436x218/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fs.zkcdn.net%2FAdvertisers%2F69c9565d37a24e159983d91b37cc3513.png 436w,https://img-getpocket.cdn.mozilla.net/202x101/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fs.zkcdn.net%2FAdvertisers%2F69c9565d37a24e159983d91b37cc3513.png 202w,https://img-getpocket.cdn.mozilla.net/404x202/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fs.zkcdn.net%2FAdvertisers%2F69c9565d37a24e159983d91b37cc3513.png 404w"></picture></div><div class="meta"><div class="info-wrap"><p class="source clamp">helixsleep.com</p><header class="title clamp">GQ Found the Best Mattress of 2020</header><p class="excerpt clamp">GQ staffers tested 20 popular mattress brands and found the runaway favorite.</p></div><div class="story-footer"><p class="story-sponsored-label clamp"><span data-l10n-args="{&quot;sponsor&quot;:&quot;Helix&quot;}" data-l10n-id="newtab-label-sponsored-by">Sponsored by Helix</span></p></div></div><div class="impression-observer"></div></a><div><button aria-haspopup="true" data-l10n-id="newtab-menu-content-tooltip" data-l10n-args="{&quot;title&quot;:&quot;GQ Found the Best Mattress of 2020&quot;}" class="context-menu-button icon" title="Open menu" aria-label="Open context menu for GQ Found the Best Mattress of 2020"></button></div></div><div class="ds-card "><a href="https://getpocket.com/explore/item/if-everyone-ate-beans-instead-of-beef?utm_source=pocket-newtab" class="ds-card-link"><div class="img-wrapper"><picture class="ds-image
+    img
+    use-transition
+   
+ "><img loading="lazy" crossorigin="anonymous" sizes="(min-width: 1122px) 296px,(min-width: 866px) 218px,(max-width: 610px) 202px,202px" src="https://pocket-image-cache.com/1200x/filters:no_upscale():format(jpg):extract_cover()/https%3A%2F%2Fcdn.theatlantic.com%2Fassets%2Fmedia%2Fimg%2Fmt%2F2017%2F08%2FGettyImages_804182918%2Flead_720_405.jpg%3Fmod%3D1533691898" srcset="https://img-getpocket.cdn.mozilla.net/296x148/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fcdn.theatlantic.com%252Fassets%252Fmedia%252Fimg%252Fmt%252F2017%252F08%252FGettyImages_804182918%252Flead_720_405.jpg%253Fmod%253D1533691898 296w,https://img-getpocket.cdn.mozilla.net/592x296/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fcdn.theatlantic.com%252Fassets%252Fmedia%252Fimg%252Fmt%252F2017%252F08%252FGettyImages_804182918%252Flead_720_405.jpg%253Fmod%253D1533691898 592w,https://img-getpocket.cdn.mozilla.net/218x109/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fcdn.theatlantic.com%252Fassets%252Fmedia%252Fimg%252Fmt%252F2017%252F08%252FGettyImages_804182918%252Flead_720_405.jpg%253Fmod%253D1533691898 218w,https://img-getpocket.cdn.mozilla.net/436x218/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fcdn.theatlantic.com%252Fassets%252Fmedia%252Fimg%252Fmt%252F2017%252F08%252FGettyImages_804182918%252Flead_720_405.jpg%253Fmod%253D1533691898 436w,https://img-getpocket.cdn.mozilla.net/202x101/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fcdn.theatlantic.com%252Fassets%252Fmedia%252Fimg%252Fmt%252F2017%252F08%252FGettyImages_804182918%252Flead_720_405.jpg%253Fmod%253D1533691898 202w,https://img-getpocket.cdn.mozilla.net/404x202/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fcdn.theatlantic.com%252Fassets%252Fmedia%252Fimg%252Fmt%252F2017%252F08%252FGettyImages_804182918%252Flead_720_405.jpg%253Fmod%253D1533691898 404w"></picture></div><div class="meta"><div class="info-wrap"><p class="source clamp">theatlantic.com</p><header class="title clamp">If Everyone Ate Beans Instead of Beef</header><p class="excerpt clamp">With one dietary change, the U.S. could almost meet greenhouse-gas emission goals.</p></div><div class="story-footer"></div></div><div class="impression-observer"></div></a><div><button aria-haspopup="true" data-l10n-id="newtab-menu-content-tooltip" data-l10n-args="{&quot;title&quot;:&quot;If Everyone Ate Beans Instead of Beef&quot;}" class="context-menu-button icon" title="Open menu" aria-label="Open context menu for If Everyone Ate Beans Instead of Beef"></button></div></div><div class="ds-card "><a href="https://getpocket.com/explore/item/the-quest-to-find-and-save-the-world-s-most-famous-shipwreck?utm_source=pocket-newtab" class="ds-card-link"><div class="img-wrapper"><picture class="ds-image
+    img
+    use-transition
+   
+ "><img loading="lazy" crossorigin="anonymous" sizes="(min-width: 1122px) 296px,(min-width: 866px) 218px,(max-width: 610px) 202px,202px" src="https://pocket-image-cache.com/1200x/filters:no_upscale():format(jpg):extract_cover()/https%3A%2F%2Fpocket-syndicated-images.s3.amazonaws.com%2Farticles%2F4583%2F1591279740_568289.karolina_kristensson_the_swedish_national_maritime_museums.vasa_02_2.jpg" srcset="https://img-getpocket.cdn.mozilla.net/296x148/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fpocket-syndicated-images.s3.amazonaws.com%252Farticles%252F4583%252F1591279740_568289.karolina_kristensson_the_swedish_national_maritime_museums.vasa_02_2.jpg 296w,https://img-getpocket.cdn.mozilla.net/592x296/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fpocket-syndicated-images.s3.amazonaws.com%252Farticles%252F4583%252F1591279740_568289.karolina_kristensson_the_swedish_national_maritime_museums.vasa_02_2.jpg 592w,https://img-getpocket.cdn.mozilla.net/218x109/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fpocket-syndicated-images.s3.amazonaws.com%252Farticles%252F4583%252F1591279740_568289.karolina_kristensson_the_swedish_national_maritime_museums.vasa_02_2.jpg 218w,https://img-getpocket.cdn.mozilla.net/436x218/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fpocket-syndicated-images.s3.amazonaws.com%252Farticles%252F4583%252F1591279740_568289.karolina_kristensson_the_swedish_national_maritime_museums.vasa_02_2.jpg 436w,https://img-getpocket.cdn.mozilla.net/202x101/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fpocket-syndicated-images.s3.amazonaws.com%252Farticles%252F4583%252F1591279740_568289.karolina_kristensson_the_swedish_national_maritime_museums.vasa_02_2.jpg 202w,https://img-getpocket.cdn.mozilla.net/404x202/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fpocket-syndicated-images.s3.amazonaws.com%252Farticles%252F4583%252F1591279740_568289.karolina_kristensson_the_swedish_national_maritime_museums.vasa_02_2.jpg 404w"></picture></div><div class="meta"><div class="info-wrap"><p class="source clamp">mentalfloss.com</p><header class="title clamp">The Quest to Find—and Save—the World’s Most Famous Shipwreck</header><p class="excerpt clamp">In 1628, the ‘Vasa’ sank on its maiden voyage. For the next 300 years, it sat in a watery grave—until one man sparked a monumental effort to salvage it.</p></div><div class="story-footer"></div></div><div class="impression-observer"></div></a><div><button aria-haspopup="true" data-l10n-id="newtab-menu-content-tooltip" data-l10n-args="{&quot;title&quot;:&quot;The Quest to Find—and Save—the World’s Most Famous Shipwreck&quot;}" class="context-menu-button icon" title="Open menu" aria-label="Open context menu for The Quest to Find—and Save—the World’s Most Famous Shipwreck"></button></div></div><div class="ds-card "><a href="https://www.bloomberg.com/news/articles/2020-12-10/he-went-from-homeless-musician-to-ceo-of-a-1-billion-company?utm_source=pocket-newtab" class="ds-card-link"><div class="img-wrapper"><picture class="ds-image
+    img
+    use-transition
+   
+ "><img loading="lazy" crossorigin="anonymous" sizes="(min-width: 1122px) 296px,(min-width: 866px) 218px,(max-width: 610px) 202px,202px" src="https://assets.bwbx.io/images/users/iqjWHBFdfxIU/ihUmvt1t3N_M/v0/1200x800.jpg" srcset="https://img-getpocket.cdn.mozilla.net/296x148/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fassets.bwbx.io%2Fimages%2Fusers%2FiqjWHBFdfxIU%2FihUmvt1t3N_M%2Fv0%2F1200x800.jpg 296w,https://img-getpocket.cdn.mozilla.net/592x296/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fassets.bwbx.io%2Fimages%2Fusers%2FiqjWHBFdfxIU%2FihUmvt1t3N_M%2Fv0%2F1200x800.jpg 592w,https://img-getpocket.cdn.mozilla.net/218x109/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fassets.bwbx.io%2Fimages%2Fusers%2FiqjWHBFdfxIU%2FihUmvt1t3N_M%2Fv0%2F1200x800.jpg 218w,https://img-getpocket.cdn.mozilla.net/436x218/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fassets.bwbx.io%2Fimages%2Fusers%2FiqjWHBFdfxIU%2FihUmvt1t3N_M%2Fv0%2F1200x800.jpg 436w,https://img-getpocket.cdn.mozilla.net/202x101/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fassets.bwbx.io%2Fimages%2Fusers%2FiqjWHBFdfxIU%2FihUmvt1t3N_M%2Fv0%2F1200x800.jpg 202w,https://img-getpocket.cdn.mozilla.net/404x202/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fassets.bwbx.io%2Fimages%2Fusers%2FiqjWHBFdfxIU%2FihUmvt1t3N_M%2Fv0%2F1200x800.jpg 404w"></picture></div><div class="meta"><div class="info-wrap"><p class="source clamp">bloomberg.com</p><header class="title clamp">How a Homeless High School Dropout Became CEO of a $1 Billion Company</header><p class="excerpt clamp">Taihei Kobayashi has gone from sleeping on the streets of Tokyo to heading a technology startup whose market value topped $1 billion.</p></div><div class="story-footer"></div></div><div class="impression-observer"></div></a><div><button aria-haspopup="true" data-l10n-id="newtab-menu-content-tooltip" data-l10n-args="{&quot;title&quot;:&quot;How a Homeless High School Dropout Became CEO of a $1 Billion Company&quot;}" class="context-menu-button icon" title="Open menu" aria-label="Open context menu for How a Homeless High School Dropout Became CEO of a $1 Billion Company"></button></div></div><div class="ds-card "><a href="https://getpocket.com/explore/item/did-prehistoric-women-hunt-new-research-suggests-so?utm_source=pocket-newtab" class="ds-card-link"><div class="img-wrapper"><picture class="ds-image
+    img
+    use-transition
+   
+ "><img loading="lazy" crossorigin="anonymous" sizes="(min-width: 1122px) 296px,(min-width: 866px) 218px,(max-width: 610px) 202px,202px" src="https://pocket-image-cache.com/1200x/filters:no_upscale():format(jpg):extract_cover()/https%3A%2F%2Fimages.theconversation.com%2Ffiles%2F367451%2Foriginal%2Ffile-20201104-13-zrxzcx.jpg%3Fixlib%3Drb-1.1.0%26rect%3D0%252C38%252C1024%252C882%26q%3D45%26auto%3Dformat%26w%3D496%26fit%3Dclip" srcset="https://img-getpocket.cdn.mozilla.net/296x148/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fimages.theconversation.com%252Ffiles%252F367451%252Foriginal%252Ffile-20201104-13-zrxzcx.jpg%253Fixlib%253Drb-1.1.0%2526rect%253D0%25252C38%25252C1024%25252C882%2526q%253D45%2526auto%253Dformat%2526w%253D496%2526fit%253Dclip 296w,https://img-getpocket.cdn.mozilla.net/592x296/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fimages.theconversation.com%252Ffiles%252F367451%252Foriginal%252Ffile-20201104-13-zrxzcx.jpg%253Fixlib%253Drb-1.1.0%2526rect%253D0%25252C38%25252C1024%25252C882%2526q%253D45%2526auto%253Dformat%2526w%253D496%2526fit%253Dclip 592w,https://img-getpocket.cdn.mozilla.net/218x109/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fimages.theconversation.com%252Ffiles%252F367451%252Foriginal%252Ffile-20201104-13-zrxzcx.jpg%253Fixlib%253Drb-1.1.0%2526rect%253D0%25252C38%25252C1024%25252C882%2526q%253D45%2526auto%253Dformat%2526w%253D496%2526fit%253Dclip 218w,https://img-getpocket.cdn.mozilla.net/436x218/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fimages.theconversation.com%252Ffiles%252F367451%252Foriginal%252Ffile-20201104-13-zrxzcx.jpg%253Fixlib%253Drb-1.1.0%2526rect%253D0%25252C38%25252C1024%25252C882%2526q%253D45%2526auto%253Dformat%2526w%253D496%2526fit%253Dclip 436w,https://img-getpocket.cdn.mozilla.net/202x101/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fimages.theconversation.com%252Ffiles%252F367451%252Foriginal%252Ffile-20201104-13-zrxzcx.jpg%253Fixlib%253Drb-1.1.0%2526rect%253D0%25252C38%25252C1024%25252C882%2526q%253D45%2526auto%253Dformat%2526w%253D496%2526fit%253Dclip 202w,https://img-getpocket.cdn.mozilla.net/404x202/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fimages.theconversation.com%252Ffiles%252F367451%252Foriginal%252Ffile-20201104-13-zrxzcx.jpg%253Fixlib%253Drb-1.1.0%2526rect%253D0%25252C38%25252C1024%25252C882%2526q%253D45%2526auto%253Dformat%2526w%253D496%2526fit%253Dclip 404w"></picture></div><div class="meta"><div class="info-wrap"><p class="source clamp">blog.getpocket.com</p><header class="title clamp">Did Prehistoric Women Hunt? New Research Suggests So</header><p class="excerpt clamp">This idea goes against a hypothesis, dating back to the 1960s, known as the “Man-The-Hunter model.”</p></div><div class="story-footer"></div></div><div class="impression-observer"></div></a><div><button aria-haspopup="true" data-l10n-id="newtab-menu-content-tooltip" data-l10n-args="{&quot;title&quot;:&quot;Did Prehistoric Women Hunt? New Research Suggests So&quot;}" class="context-menu-button icon" title="Open menu" aria-label="Open context menu for Did Prehistoric Women Hunt? New Research Suggests So"></button></div></div><div class="ds-card "><a href="https://getpocket.com/explore/item/the-quote-that-finally-changed-my-mind-on-minimalism?utm_source=pocket-newtab" class="ds-card-link"><div class="img-wrapper"><picture class="ds-image
+    img
+    use-transition
+   
+ "><img loading="lazy" crossorigin="anonymous" sizes="(min-width: 1122px) 296px,(min-width: 866px) 218px,(max-width: 610px) 202px,202px" src="https://pocket-image-cache.com/1200x/filters:no_upscale():format(jpg):extract_cover()/https%3A%2F%2Fpocket-syndicated-images.s3.amazonaws.com%2Farticles%2F5395%2F1597673872_projectprism_colorsearcharchive_a0d97e2b2fd2124de6228ee12c91fa12afa21742.jpg" srcset="https://img-getpocket.cdn.mozilla.net/296x148/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fpocket-syndicated-images.s3.amazonaws.com%252Farticles%252F5395%252F1597673872_projectprism_colorsearcharchive_a0d97e2b2fd2124de6228ee12c91fa12afa21742.jpg 296w,https://img-getpocket.cdn.mozilla.net/592x296/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fpocket-syndicated-images.s3.amazonaws.com%252Farticles%252F5395%252F1597673872_projectprism_colorsearcharchive_a0d97e2b2fd2124de6228ee12c91fa12afa21742.jpg 592w,https://img-getpocket.cdn.mozilla.net/218x109/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fpocket-syndicated-images.s3.amazonaws.com%252Farticles%252F5395%252F1597673872_projectprism_colorsearcharchive_a0d97e2b2fd2124de6228ee12c91fa12afa21742.jpg 218w,https://img-getpocket.cdn.mozilla.net/436x218/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fpocket-syndicated-images.s3.amazonaws.com%252Farticles%252F5395%252F1597673872_projectprism_colorsearcharchive_a0d97e2b2fd2124de6228ee12c91fa12afa21742.jpg 436w,https://img-getpocket.cdn.mozilla.net/202x101/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fpocket-syndicated-images.s3.amazonaws.com%252Farticles%252F5395%252F1597673872_projectprism_colorsearcharchive_a0d97e2b2fd2124de6228ee12c91fa12afa21742.jpg 202w,https://img-getpocket.cdn.mozilla.net/404x202/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fpocket-syndicated-images.s3.amazonaws.com%252Farticles%252F5395%252F1597673872_projectprism_colorsearcharchive_a0d97e2b2fd2124de6228ee12c91fa12afa21742.jpg 404w"></picture></div><div class="meta"><div class="info-wrap"><p class="source clamp">apartmenttherapy.com</p><header class="title clamp">The Quote That Finally Changed My Mind on Minimalism</header><p class="excerpt clamp">There’s more to minimalism than just purging yourself of stuff.</p></div><div class="story-footer"></div></div><div class="impression-observer"></div></a><div><button aria-haspopup="true" data-l10n-id="newtab-menu-content-tooltip" data-l10n-args="{&quot;title&quot;:&quot;The Quote That Finally Changed My Mind on Minimalism&quot;}" class="context-menu-button icon" title="Open menu" aria-label="Open context menu for The Quote That Finally Changed My Mind on Minimalism"></button></div></div><div class="ds-card "><a href="https://getpocket.com/explore/item/lessons-in-the-decline-of-democracy-from-the-ruined-roman-republic?utm_source=pocket-newtab" class="ds-card-link"><div class="img-wrapper"><picture class="ds-image
+    img
+    use-transition
+   
+ "><img loading="lazy" crossorigin="anonymous" sizes="(min-width: 1122px) 296px,(min-width: 866px) 218px,(max-width: 610px) 202px,202px" src="https://pocket-image-cache.com/1200x/filters:no_upscale():format(jpg):extract_cover()/https%3A%2F%2Fpocket-syndicated-images.s3.amazonaws.com%2Farticles%2F5223%2F1596117491_Eugene_Guillaume_-_the_Gracchi.jpgcrop.jpg" srcset="https://img-getpocket.cdn.mozilla.net/296x148/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fpocket-syndicated-images.s3.amazonaws.com%252Farticles%252F5223%252F1596117491_Eugene_Guillaume_-_the_Gracchi.jpgcrop.jpg 296w,https://img-getpocket.cdn.mozilla.net/592x296/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fpocket-syndicated-images.s3.amazonaws.com%252Farticles%252F5223%252F1596117491_Eugene_Guillaume_-_the_Gracchi.jpgcrop.jpg 592w,https://img-getpocket.cdn.mozilla.net/218x109/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fpocket-syndicated-images.s3.amazonaws.com%252Farticles%252F5223%252F1596117491_Eugene_Guillaume_-_the_Gracchi.jpgcrop.jpg 218w,https://img-getpocket.cdn.mozilla.net/436x218/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fpocket-syndicated-images.s3.amazonaws.com%252Farticles%252F5223%252F1596117491_Eugene_Guillaume_-_the_Gracchi.jpgcrop.jpg 436w,https://img-getpocket.cdn.mozilla.net/202x101/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fpocket-syndicated-images.s3.amazonaws.com%252Farticles%252F5223%252F1596117491_Eugene_Guillaume_-_the_Gracchi.jpgcrop.jpg 202w,https://img-getpocket.cdn.mozilla.net/404x202/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fpocket-syndicated-images.s3.amazonaws.com%252Farticles%252F5223%252F1596117491_Eugene_Guillaume_-_the_Gracchi.jpgcrop.jpg 404w"></picture></div><div class="meta"><div class="info-wrap"><p class="source clamp">smithsonianmag.com</p><header class="title clamp">Lessons in the Decline of Democracy From the Ruined Roman Republic</header><p class="excerpt clamp">Historian Edward Watts argues that violent rhetoric and disregard for political norms was the beginning of Rome’s end.</p></div><div class="story-footer"></div></div><div class="impression-observer"></div></a><div><button aria-haspopup="true" data-l10n-id="newtab-menu-content-tooltip" data-l10n-args="{&quot;title&quot;:&quot;Lessons in the Decline of Democracy From the Ruined Roman Republic&quot;}" class="context-menu-button icon" title="Open menu" aria-label="Open context menu for Lessons in the Decline of Democracy From the Ruined Roman Republic"></button></div></div><div class="ds-card "><a href="https://getpocket.com/explore/item/top-10-myths-about-bedbugs?utm_source=pocket-newtab" class="ds-card-link"><div class="img-wrapper"><picture class="ds-image
+    img
+    use-transition
+   
+ "><img loading="lazy" crossorigin="anonymous" sizes="(min-width: 1122px) 296px,(min-width: 866px) 218px,(max-width: 610px) 202px,202px" src="https://pocket-image-cache.com/1200x/filters:no_upscale():format(jpg):extract_cover()/https%3A%2F%2Fstatic.scientificamerican.com%2Fsciam%2Fcache%2Ffile%2F824C8DCC-4CBF-40B1-BE63680FF6CEA2DA_source.jpg%3Fw%3D590%26h%3D800%26DA6BDDE7-75A8-4953-941D4D5DD37FA77B" srcset="https://img-getpocket.cdn.mozilla.net/296x148/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fstatic.scientificamerican.com%252Fsciam%252Fcache%252Ffile%252F824C8DCC-4CBF-40B1-BE63680FF6CEA2DA_source.jpg%253Fw%253D590%2526h%253D800%2526DA6BDDE7-75A8-4953-941D4D5DD37FA77B 296w,https://img-getpocket.cdn.mozilla.net/592x296/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fstatic.scientificamerican.com%252Fsciam%252Fcache%252Ffile%252F824C8DCC-4CBF-40B1-BE63680FF6CEA2DA_source.jpg%253Fw%253D590%2526h%253D800%2526DA6BDDE7-75A8-4953-941D4D5DD37FA77B 592w,https://img-getpocket.cdn.mozilla.net/218x109/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fstatic.scientificamerican.com%252Fsciam%252Fcache%252Ffile%252F824C8DCC-4CBF-40B1-BE63680FF6CEA2DA_source.jpg%253Fw%253D590%2526h%253D800%2526DA6BDDE7-75A8-4953-941D4D5DD37FA77B 218w,https://img-getpocket.cdn.mozilla.net/436x218/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fstatic.scientificamerican.com%252Fsciam%252Fcache%252Ffile%252F824C8DCC-4CBF-40B1-BE63680FF6CEA2DA_source.jpg%253Fw%253D590%2526h%253D800%2526DA6BDDE7-75A8-4953-941D4D5DD37FA77B 436w,https://img-getpocket.cdn.mozilla.net/202x101/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fstatic.scientificamerican.com%252Fsciam%252Fcache%252Ffile%252F824C8DCC-4CBF-40B1-BE63680FF6CEA2DA_source.jpg%253Fw%253D590%2526h%253D800%2526DA6BDDE7-75A8-4953-941D4D5DD37FA77B 202w,https://img-getpocket.cdn.mozilla.net/404x202/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fstatic.scientificamerican.com%252Fsciam%252Fcache%252Ffile%252F824C8DCC-4CBF-40B1-BE63680FF6CEA2DA_source.jpg%253Fw%253D590%2526h%253D800%2526DA6BDDE7-75A8-4953-941D4D5DD37FA77B 404w"></picture></div><div class="meta"><div class="info-wrap"><p class="source clamp">scientificamerican.com</p><header class="title clamp">Top 10 Myths About Bedbugs</header><p class="excerpt clamp">The insects, making a comeback around the globe, cannot fly and are really not interested in hanging out on your body—but they do occasionally bite during the day.</p></div><div class="story-footer"></div></div><div class="impression-observer"></div></a><div><button aria-haspopup="true" data-l10n-id="newtab-menu-content-tooltip" data-l10n-args="{&quot;title&quot;:&quot;Top 10 Myths About Bedbugs&quot;}" class="context-menu-button icon" title="Open menu" aria-label="Open context menu for Top 10 Myths About Bedbugs"></button></div></div><div class="ds-card "><a href="https://getpocket.com/explore/item/the-witness?utm_source=pocket-newtab" class="ds-card-link"><div class="img-wrapper"><picture class="ds-image
+    img
+    use-transition
+   
+ "><img loading="lazy" crossorigin="anonymous" sizes="(min-width: 1122px) 296px,(min-width: 866px) 218px,(max-width: 610px) 202px,202px" src="https://pocket-image-cache.com/1200x/filters:no_upscale():format(jpg):extract_cover()/https%3A%2F%2Fimg.texasmonthly.com%2F2014%2F08%2FMichelle-Lyons-The-Witness-680.jpg%3Fauto%3Dcompress%26crop%3Dfaces%26fit%3Dfit%26fm%3Djpg%26h%3D0%26ixlib%3Dphp-1.2.1%26q%3D45%26w%3D600" srcset="https://img-getpocket.cdn.mozilla.net/296x148/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fimg.texasmonthly.com%252F2014%252F08%252FMichelle-Lyons-The-Witness-680.jpg%253Fauto%253Dcompress%2526crop%253Dfaces%2526fit%253Dfit%2526fm%253Djpg%2526h%253D0%2526ixlib%253Dphp-1.2.1%2526q%253D45%2526w%253D600 296w,https://img-getpocket.cdn.mozilla.net/592x296/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fimg.texasmonthly.com%252F2014%252F08%252FMichelle-Lyons-The-Witness-680.jpg%253Fauto%253Dcompress%2526crop%253Dfaces%2526fit%253Dfit%2526fm%253Djpg%2526h%253D0%2526ixlib%253Dphp-1.2.1%2526q%253D45%2526w%253D600 592w,https://img-getpocket.cdn.mozilla.net/218x109/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fimg.texasmonthly.com%252F2014%252F08%252FMichelle-Lyons-The-Witness-680.jpg%253Fauto%253Dcompress%2526crop%253Dfaces%2526fit%253Dfit%2526fm%253Djpg%2526h%253D0%2526ixlib%253Dphp-1.2.1%2526q%253D45%2526w%253D600 218w,https://img-getpocket.cdn.mozilla.net/436x218/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fimg.texasmonthly.com%252F2014%252F08%252FMichelle-Lyons-The-Witness-680.jpg%253Fauto%253Dcompress%2526crop%253Dfaces%2526fit%253Dfit%2526fm%253Djpg%2526h%253D0%2526ixlib%253Dphp-1.2.1%2526q%253D45%2526w%253D600 436w,https://img-getpocket.cdn.mozilla.net/202x101/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fimg.texasmonthly.com%252F2014%252F08%252FMichelle-Lyons-The-Witness-680.jpg%253Fauto%253Dcompress%2526crop%253Dfaces%2526fit%253Dfit%2526fm%253Djpg%2526h%253D0%2526ixlib%253Dphp-1.2.1%2526q%253D45%2526w%253D600 202w,https://img-getpocket.cdn.mozilla.net/404x202/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fpocket-image-cache.com%2F1200x%2Ffilters%3Ano_upscale()%3Aformat(jpg)%3Aextract_cover()%2Fhttps%253A%252F%252Fimg.texasmonthly.com%252F2014%252F08%252FMichelle-Lyons-The-Witness-680.jpg%253Fauto%253Dcompress%2526crop%253Dfaces%2526fit%253Dfit%2526fm%253Djpg%2526h%253D0%2526ixlib%253Dphp-1.2.1%2526q%253D45%2526w%253D600 404w"></picture></div><div class="meta"><div class="info-wrap"><p class="source clamp">texasmonthly.com</p><header class="title clamp">The Witness</header><p class="excerpt clamp">For more than a decade, it was Michelle Lyons’s job to observe the final moments of death row inmates—but watching 278 executions did not come without a cost.</p></div><div class="story-footer"></div></div><div class="impression-observer"></div></a><div><button aria-haspopup="true" data-l10n-id="newtab-menu-content-tooltip" data-l10n-args="{&quot;title&quot;:&quot;The Witness&quot;}" class="context-menu-button icon" title="Open menu" aria-label="Open context menu for The Witness"></button></div></div><div class="ds-card "><a href="https://ck.lendingtree.com/?a=625&amp;c=3823&amp;p=r&amp;s1=pocket&amp;s2=dothismort_bluestonehouse&amp;placement_name=ffnewtab&amp;ad_headline=dothismort&amp;ad_image_name=bluestonehouse&amp;ctype=ffnewtab" class="ds-card-link"><div class="img-wrapper"><picture class="ds-image
+    img
+    use-transition
+   
+ "><img loading="lazy" crossorigin="anonymous" sizes="(min-width: 1122px) 296px,(min-width: 866px) 218px,(max-width: 610px) 202px,202px" src="https://s.zkcdn.net/Advertisers/a129d20f64454f2f85f76a31302141e6.jpg" srcset="https://img-getpocket.cdn.mozilla.net/296x148/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fs.zkcdn.net%2FAdvertisers%2Fa129d20f64454f2f85f76a31302141e6.jpg 296w,https://img-getpocket.cdn.mozilla.net/592x296/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fs.zkcdn.net%2FAdvertisers%2Fa129d20f64454f2f85f76a31302141e6.jpg 592w,https://img-getpocket.cdn.mozilla.net/218x109/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fs.zkcdn.net%2FAdvertisers%2Fa129d20f64454f2f85f76a31302141e6.jpg 218w,https://img-getpocket.cdn.mozilla.net/436x218/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fs.zkcdn.net%2FAdvertisers%2Fa129d20f64454f2f85f76a31302141e6.jpg 436w,https://img-getpocket.cdn.mozilla.net/202x101/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fs.zkcdn.net%2FAdvertisers%2Fa129d20f64454f2f85f76a31302141e6.jpg 202w,https://img-getpocket.cdn.mozilla.net/404x202/filters:format(jpeg):quality(60):no_upscale():strip_exif()/https%3A%2F%2Fs.zkcdn.net%2FAdvertisers%2Fa129d20f64454f2f85f76a31302141e6.jpg 404w"></picture></div><div class="meta"><div class="info-wrap"><p class="source clamp">lendingtree.com</p><header class="title clamp">Do This Before Your Next Mortgage Payment (It’s Genius)</header><p class="excerpt clamp">You're just minutes away from seeing great offers, absolutely free.</p></div><div class="story-footer"><p class="story-sponsored-label clamp"><span data-l10n-args="{&quot;sponsor&quot;:&quot;LendingTree&quot;}" data-l10n-id="newtab-label-sponsored-by">Sponsored by LendingTree</span></p></div></div><div class="impression-observer"></div></a><div><button aria-haspopup="true" data-l10n-id="newtab-menu-content-tooltip" data-l10n-args="{&quot;title&quot;:&quot;Do This Before Your Next Mortgage Payment (It’s Genius)&quot;}" class="context-menu-button icon" title="Open menu" aria-label="Open context menu for Do This Before Your Next Mortgage Payment (It’s Genius)"></button></div></div></div></div></div><div><div class="ds-navigation ds-navigation-left-align ds-navigation-variant-basic"><span class="ds-header" data-l10n-id="newtab-pocket-read-more">Popular Topics:</span><ul><li><a href="https://getpocket.com/explore/must-reads?src=fx_new_tab">Must Reads</a></li><li><a href="https://getpocket.com/explore/self-improvement?src=fx_new_tab">Self Improvement</a></li><li><a href="https://getpocket.com/explore/health?src=fx_new_tab">Health</a></li><li><a href="https://getpocket.com/explore/business?src=fx_new_tab">Business</a></li><li><a href="https://getpocket.com/explore/technology?src=fx_new_tab">Technology</a></li><li><a href="https://getpocket.com/explore?src=fx_new_tab&amp;cdn=0">More Recommendations ›</a></li></ul></div></div></div></div><style data-styles="[[null,{&quot;.ds-navigation&quot;:&quot;margin-top: -10px;&quot;}]]"></style></div>
+</div>
+
+-->
+  <script src="chrome://browser/content/companion/companion.js"></script>
+</body>
+
+</html>
\ No newline at end of file
diff --git a/browser/components/companion/content/companion.js b/browser/components/companion/content/companion.js
new file mode 100644
--- /dev/null
+++ b/browser/components/companion/content/companion.js
@@ -0,0 +1,34 @@
+var { XPCOMUtils } = ChromeUtils.import(
+  "resource://gre/modules/XPCOMUtils.jsm"
+);
+var { Services } = ChromeUtils.import("resource://gre/modules/Services.jsm");
+var { AppConstants } = ChromeUtils.import(
+  "resource://gre/modules/AppConstants.jsm"
+);
+
+// lazy module getters
+
+XPCOMUtils.defineLazyModuleGetters(this, {
+  Companion: "resource:///modules/Companion.jsm",
+  CompanionWindow: "resource:///modules/Companion.jsm",
+  BrowserWindowTracker: "resource:///modules/BrowserWindowTracker.jsm",
+});
+
+console.log("Hello from companion", window);
+
+function render() {
+  let outerContainer = document.querySelector("#main-inner");
+  let container = document.createElement("ul");
+  for (let window of BrowserWindowTracker.orderedWindows) {
+    let winContainer = document.createElement("li");
+    winContainer.textContent = window.document.title;
+    container.append(winContainer);
+  }
+  outerContainer.textContent = "";
+  outerContainer.append(container);
+}
+
+BrowserWindowTracker.addEventListener("onwindowadded", render);
+BrowserWindowTracker.addEventListener("onwindowremoved", render);
+
+render();
diff --git a/browser/components/companion/content/jar.mn b/browser/components/companion/content/jar.mn
new file mode 100644
--- /dev/null
+++ b/browser/components/companion/content/jar.mn
@@ -0,0 +1,5 @@
+
+browser.jar:
+  content/browser/companion/companion.html
+  content/browser/companion/companion.css
+  content/browser/companion/companion.js
diff --git a/browser/components/companion/content/moz.build b/browser/components/companion/content/moz.build
new file mode 100644
--- /dev/null
+++ b/browser/components/companion/content/moz.build
@@ -0,0 +1,2 @@
+
+JAR_MANIFESTS += ["jar.mn"]
diff --git a/browser/components/companion/moz.build b/browser/components/companion/moz.build
new file mode 100644
--- /dev/null
+++ b/browser/components/companion/moz.build
@@ -0,0 +1,16 @@
+# -*- Mode: python; indent-tabs-mode: nil; tab-width: 40 -*-
+# vim: set filetype=python:
+# This Source Code Form is subject to the terms of the Mozilla Public
+# License, v. 2.0. If a copy of the MPL was not distributed with this
+# file, You can obtain one at http://mozilla.org/MPL/2.0/.
+
+DIRS += [
+    "content",
+]
+
+EXTRA_JS_MODULES += [
+    "Companion.jsm",
+]
+
+with Files("**"):
+    BUG_COMPONENT = ("Firefox", "Toolbars and Customization")
diff --git a/browser/components/moz.build b/browser/components/moz.build
--- a/browser/components/moz.build
+++ b/browser/components/moz.build
@@ -26,16 +26,17 @@ with Files("controlcenter/**"):
     BUG_COMPONENT = ("Firefox", "General")
 
 
 DIRS += [
     "about",
     "aboutconfig",
     "aboutlogins",
     "attribution",
+    "companion",
     "contextualidentity",
     "customizableui",
     "doh",
     "downloads",
     "enterprisepolicies",
     "extensions",
     "fxmonitor",
     "migration",
diff --git a/browser/modules/BrowserWindowTracker.jsm b/browser/modules/BrowserWindowTracker.jsm
--- a/browser/modules/BrowserWindowTracker.jsm
+++ b/browser/modules/BrowserWindowTracker.jsm
@@ -115,44 +115,50 @@ var WindowHelper = {
     WINDOW_EVENTS.forEach(function(event) {
       window.addEventListener(event, _handleEvent);
     });
 
     _trackWindowOrder(window);
 
     // Update the selected tab's content outer window ID.
     _updateCurrentContentOuterWindowID(window.gBrowser.selectedBrowser);
+
+    let event = new CustomEvent("onwindowadded");
+    BrowserWindowTracker.dispatchEvent(event);
   },
 
   removeWindow(window) {
     _untrackWindowOrder(window);
 
     // Remove the event listeners
     TAB_EVENTS.forEach(function(event) {
       window.gBrowser.tabContainer.removeEventListener(event, _handleEvent);
     });
     WINDOW_EVENTS.forEach(function(event) {
       window.removeEventListener(event, _handleEvent);
     });
+
+    let event = new CustomEvent("onwindowremoved");
+    BrowserWindowTracker.dispatchEvent(event);
   },
 
   onActivate(window) {
     // If this window was the last focused window, we don't need to do anything
     if (window == _trackedWindows[0]) {
       return;
     }
 
     _untrackWindowOrder(window);
     _trackWindowOrder(window);
 
     _updateCurrentContentOuterWindowID(window.gBrowser.selectedBrowser);
   },
 };
 
-this.BrowserWindowTracker = {
+class BWT extends EventTarget {
   /**
    * Get the most recent browser window.
    *
    * @param options an object accepting the arguments for the search.
    *        * private: true to restrict the search to private windows
    *            only, false to restrict the search to non-private only.
    *            Omit the property to search in both groups.
    *        * allowPopups: true if popup windows are permissable.
@@ -165,51 +171,53 @@ this.BrowserWindowTracker = {
         (!("private" in options) ||
           PrivateBrowsingUtils.permanentPrivateBrowsing ||
           PrivateBrowsingUtils.isWindowPrivate(win) == options.private)
       ) {
         return win;
       }
     }
     return null;
-  },
+  }
 
   windowCreated(browser) {
     if (browser === browser.ownerGlobal.gBrowser.selectedBrowser) {
       _updateCurrentContentOuterWindowID(browser);
     }
-  },
+  }
 
   /**
    * Number of currently open browser windows.
    */
   get windowCount() {
     return _trackedWindows.length;
-  },
+  }
 
   /**
    * Array of browser windows ordered by z-index, in reverse order.
    * This means that the top-most browser window will be the first item.
    */
   get orderedWindows() {
     // Clone the windows array immediately as it may change during iteration,
     // we'd rather have an outdated order than skip/revisit windows.
     return [..._trackedWindows];
-  },
+  }
 
   getAllVisibleTabs() {
     let tabs = [];
     for (let win of BrowserWindowTracker.orderedWindows) {
       for (let tab of win.gBrowser.visibleTabs) {
         // Only use tabs which are not discarded / unrestored
         if (tab.linkedPanel) {
           let { contentTitle, browserId } = tab.linkedBrowser;
           tabs.push({ contentTitle, browserId });
         }
       }
     }
     return tabs;
-  },
+  }
 
   track(window) {
     return WindowHelper.addWindow(window);
-  },
-};
+  }
+}
+
+this.BrowserWindowTracker = new BWT();
