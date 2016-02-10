# HG changeset patch
# User Brian Grinstead <bgrinstead@mozilla.com>
# Parent  c356f2d919d9d24096c9528c2c3acee8911fa7e7
Bug 1243968 - e10s fixes for browser_console_variables_view_while_debugging.js;r=linclark

diff --git a/devtools/client/webconsole/test/browser.ini b/devtools/client/webconsole/test/browser.ini
--- a/devtools/client/webconsole/test/browser.ini
+++ b/devtools/client/webconsole/test/browser.ini
@@ -180,17 +180,16 @@ skip-if = e10s # Bug 1042253 - webconsol
 [browser_console_server_logging.js]
 [browser_console_variables_view.js]
 skip-if = e10s # Bug 1042253 - webconsole tests disabled with e10s
 [browser_console_variables_view_filter.js]
 [browser_console_variables_view_dom_nodes.js]
 [browser_console_variables_view_dont_sort_non_sortable_classes_properties.js]
 [browser_console_variables_view_special_names.js]
 [browser_console_variables_view_while_debugging.js]
-skip-if = e10s # Bug 1042253 - webconsole tests disabled with e10s
 [browser_console_variables_view_while_debugging_and_inspecting.js]
 [browser_eval_in_debugger_stackframe.js]
 skip-if = e10s # Bug 1042253 - webconsole tests disabled with e10s
 [browser_eval_in_debugger_stackframe2.js]
 [browser_jsterm_inspect.js]
 skip-if = e10s && debug && os == 'win'
 [browser_longstring_hang.js]
 [browser_output_breaks_after_console_dir_uninspectable.js]
diff --git a/devtools/client/webconsole/test/browser_console_variables_view_while_debugging.js b/devtools/client/webconsole/test/browser_console_variables_view_while_debugging.js
--- a/devtools/client/webconsole/test/browser_console_variables_view_while_debugging.js
+++ b/devtools/client/webconsole/test/browser_console_variables_view_while_debugging.js
@@ -7,120 +7,96 @@
 // from the js debugger, when changing the value of a property in the variables
 // view.
 
 "use strict";
 
 const TEST_URI = "http://example.com/browser/devtools/client/webconsole/" +
                  "test/test-eval-in-stackframe.html";
 
-var gWebConsole, gJSTerm, gDebuggerWin, gThread, gDebuggerController,
-    gStackframes, gVariablesView;
+add_task(function*() {
+  yield loadTab(TEST_URI);
+  let hud = yield openConsole();
 
-function test() {
-  loadTab(TEST_URI).then(() => {
-    openConsole().then(consoleOpened);
+  let dbgPanel = yield openDebugger();
+  yield waitForFrameAdded(dbgPanel);
+  yield openConsole();
+  yield testVariablesView(hud);
+});
+
+function* waitForFrameAdded(dbgPanel) {
+  let thread = dbgPanel.panelWin.DebuggerController.activeThread;
+
+  info("Waiting for framesadded");
+  yield new Promise(resolve => {
+    thread.addOneTimeListener("framesadded", resolve);
+    info("firstCall()");
+    ContentTask.spawn(gBrowser.selectedBrowser, {}, function*() {
+      content.wrappedJSObject.firstCall();
+    });
   });
 }
 
-function consoleOpened(hud) {
-  gWebConsole = hud;
-  gJSTerm = hud.jsterm;
-
-  executeSoon(() => {
-    info("openDebugger");
-    openDebugger().then(debuggerOpened);
-  });
-}
-
-function debuggerOpened(aResult) {
-  gDebuggerWin = aResult.panelWin;
-  gDebuggerController = gDebuggerWin.DebuggerController;
-  gThread = gDebuggerController.activeThread;
-  gStackframes = gDebuggerController.StackFrames;
-
-  executeSoon(() => {
-    gThread.addOneTimeListener("framesadded", onFramesAdded);
-
-    info("firstCall()");
-    content.wrappedJSObject.firstCall();
-  });
-}
-
-function onFramesAdded() {
-  info("onFramesAdded");
-
-  executeSoon(() =>
-    openConsole().then(() =>
-      gJSTerm.execute("fooObj").then(onExecuteFooObj)
-    )
-  );
-}
-
-function onExecuteFooObj(msg) {
+function* testVariablesView(hud) {
+  let jsterm = hud.jsterm;
+  let msg = yield jsterm.execute("fooObj");
   ok(msg, "output message found");
   ok(msg.textContent.includes('{ testProp2: "testValue2" }'),
                               "message text check");
 
   let anchor = msg.querySelector("a");
   ok(anchor, "object link found");
 
-  gJSTerm.once("variablesview-fetched", onFooObjFetch);
+  info("Waiting for variable view to appear");
+  let variable = yield new Promise(resolve => {
+    jsterm.once("variablesview-fetched", (e, variable) => {
+      resolve(variable);
+    });
+    executeSoon(() => EventUtils.synthesizeMouse(anchor, 2, 2, {},
+                                                 hud.iframeWindow));
+  });
 
-  executeSoon(() => EventUtils.synthesizeMouse(anchor, 2, 2, {},
-                                               gWebConsole.iframeWindow));
-}
-
-function onFooObjFetch(aEvent, aVar) {
-  gVariablesView = aVar._variablesView;
-  ok(gVariablesView, "variables view object");
-
-  findVariableViewProperties(aVar, [
+  info("Waiting for findVariableViewProperties");
+  let results = yield findVariableViewProperties(variable, [
     { name: "testProp2", value: "testValue2" },
     { name: "testProp", value: "testValue", dontMatch: true },
-  ], { webconsole: gWebConsole }).then(onTestPropFound);
-}
+  ], { webconsole: hud });
 
-function onTestPropFound(aResults) {
-  let prop = aResults[0].matchedProp;
+  let prop = results[0].matchedProp;
   ok(prop, "matched the |testProp2| property in the variables view");
 
   // Check that property value updates work and that jsterm functions can be
   // used.
-  updateVariablesViewProperty({
+  variable = yield updateVariablesViewProperty({
     property: prop,
     field: "value",
     string: "document.title + foo2 + $('p')",
-    webconsole: gWebConsole
-  }).then(onFooObjFetchAfterUpdate);
-}
+    webconsole: hud
+  });
 
-function onFooObjFetchAfterUpdate(aVar) {
   info("onFooObjFetchAfterUpdate");
-  let para = content.wrappedJSObject.document.querySelector("p");
-  let expectedValue = content.document.title + "foo2SecondCall" + para;
+  let expectedValue = yield ContentTask.spawn(gBrowser.selectedBrowser, {}, function* () {
+    let para = content.wrappedJSObject.document.querySelector("p");
+    return content.document.title + "foo2SecondCall" + para;
+  });
 
-  findVariableViewProperties(aVar, [
+  results = yield findVariableViewProperties(variable, [
     { name: "testProp2", value: expectedValue },
-  ], { webconsole: gWebConsole }).then(onUpdatedTestPropFound);
-}
+  ], { webconsole: hud });
 
-function onUpdatedTestPropFound(aResults) {
-  let prop = aResults[0].matchedProp;
+  prop = results[0].matchedProp;
   ok(prop, "matched the updated |testProp2| property value");
 
   // Check that testProp2 was updated.
-  executeSoon(() => {
-    gJSTerm.execute("fooObj.testProp2").then(onExecuteFooObjTestProp2);
+  yield new Promise(resolve => {
+    executeSoon(() => {
+      jsterm.execute("fooObj.testProp2").then(resolve);
+    });
   });
+
+  expectedValue = yield ContentTask.spawn(gBrowser.selectedBrowser, {}, function* () {
+    let para = content.wrappedJSObject.document.querySelector("p");
+    return content.document.title + "foo2SecondCall" + para;
+  });
+
+  isnot(hud.outputNode.textContent.indexOf(expectedValue), -1,
+        "fooObj.testProp2 is correct");
 }
-
-function onExecuteFooObjTestProp2() {
-  let para = content.wrappedJSObject.document.querySelector("p");
-  let expected = content.document.title + "foo2SecondCall" + para;
-
-  isnot(gWebConsole.outputNode.textContent.indexOf(expected), -1,
-        "fooObj.testProp2 is correct");
-
-  gWebConsole = gJSTerm = gDebuggerWin = gThread = gDebuggerController =
-    gStackframes = gVariablesView = null;
-  executeSoon(finishTest);
-}