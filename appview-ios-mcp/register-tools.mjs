import { z } from "zod";
import { appviewClient } from "./client.mjs";
import { appSession } from "./app-session.mjs";

const appGuardSchema = {
  expectedBundleId: z
    .string()
    .optional()
    .describe(
      "Fail with wrong_app if foreground bundleId differs. Falls back to appview_set_expected_app session value."
    ),
};

const oidSchema = z.number().optional();
const pointSchema = {
  ...appGuardSchema,
  oid: oidSchema.describe("View oid."),
  x: z.number().optional().describe("Window X."),
  y: z.number().optional().describe("Window Y."),
};

const searchSchema = {
  ...appGuardSchema,
  className: z.string().optional().describe("Exact UIView class name."),
  classNameContains: z.string().optional().describe("Class name substring."),
  accessibilityIdentifier: z.string().optional(),
  accessibilityLabel: z.string().optional().describe("Substring match."),
  title: z.string().optional().describe("Button/control title substring."),
  textContains: z.string().optional().describe("Text in field/button substring."),
  maxResults: z.number().optional().describe("Max matches (default 20)."),
};

const SYSTEM_CONTAINER_CLASSES = new Set([
  "UITransitionView",
  "UIDropShadowView",
  "UILayoutContainerView",
  "UINavigationTransitionView",
  "UIViewControllerWrapperView",
]);

const READ_ONLY = { readOnlyHint: true, destructiveHint: false, openWorldHint: true };
const MUTATING = { readOnlyHint: false, destructiveHint: true, openWorldHint: true };
const STATEFUL = { readOnlyHint: false, destructiveHint: false, openWorldHint: true };

const MUTATING_TOOLS = new Set([
  "appview_modify_attribute",
  "appview_modify_custom_attr",
  "appview_invoke_method",
  "appview_tap",
  "appview_tap_by_label",
  "appview_double_tap",
  "appview_long_press",
  "appview_swipe",
  "appview_drag",
  "appview_pinch",
  "appview_scroll",
  "appview_toggle",
  "appview_select_row",
  "appview_type_text",
  "appview_clear_text",
  "appview_keyboard",
  "appview_relisten_peertalk",
]);

const STATEFUL_TOOLS = new Set([
  "appview_set_expected_app",
  "appview_clear_expected_app",
  "appview_connect_device",
  "appview_set_orientation",
  "appview_set_appearance",
  "appview_shake",
  "appview_compare_screenshots",
]);

function toolAnnotations(name) {
  if (MUTATING_TOOLS.has(name)) return MUTATING;
  if (STATEFUL_TOOLS.has(name)) return STATEFUL;
  return READ_ONLY;
}

function defineTool(server, name, ...args) {
  const handler = args.at(-1);
  if (typeof handler !== "function") {
    throw new Error(`MCP tool ${name} is missing a handler`);
  }
  server.tool(name, ...args.slice(0, -1), toolAnnotations(name), handler);
}

function isSystemContainer(className) {
  if (!className) return false;
  const shortName = className.includes(".") ? className.split(".").pop() : className;
  if (shortName.startsWith("_") || className.startsWith("_")) return true;
  return SYSTEM_CONTAINER_CLASSES.has(shortName);
}

function omitSystemContainers(items) {
  const result = [];
  for (const item of items) {
    const children = omitSystemContainers(item.children ?? []);
    if (isSystemContainer(item.className)) {
      result.push(...children);
    } else {
      const next = { ...item };
      if (children.length > 0) next.children = children;
      else delete next.children;
      result.push(next);
    }
  }
  return result;
}

function jsonResult(result) {
  return { content: [{ type: "text", text: JSON.stringify(result) }] };
}

function blockedResult(blocked) {
  return { content: [{ type: "text", text: blocked }] };
}

function jsonResultWithContext(result, appContext) {
  if (!appContext?.warning && !appContext?.appChanged) {
    return jsonResult(result);
  }
  const payload =
    result !== null && typeof result === "object" && !Array.isArray(result)
      ? {
          ...result,
          _appContext: {
            appChanged: appContext.appChanged,
            warning: appContext.warning,
            activeApp: appContext.activeApp,
            previousBundleId: appContext.previousBundleId,
            expectedBundleId: appContext.expectedBundleId,
          },
        }
      : {
          data: result,
          _appContext: {
            appChanged: appContext.appChanged,
            warning: appContext.warning,
            activeApp: appContext.activeApp,
            previousBundleId: appContext.previousBundleId,
            expectedBundleId: appContext.expectedBundleId,
          },
        };
  return jsonResult(payload);
}

function wrongAppPayload(appContext) {
  return JSON.stringify({
    error: "wrong_app",
    message: appContext.warning,
    activeApp: appContext.activeApp,
    expectedBundleId: appContext.expectedBundleId,
    hint: "Bring the expected app to foreground, call appview_set_expected_app, or omit expectedBundleId.",
  });
}

function noAppViewAppPayload(err) {
  const message = err instanceof Error ? err.message : String(err);
  return JSON.stringify({
    error: "no_appview_app",
    message,
    hint:
      "Launch a Debug app with AppViewServer MCP subspec in the foreground. On simulator only one app can own :47190 — check with: lsof -i tcp:47190",
  });
}

export const VIEW_TOOLS = [
  "appview_get_hierarchy",
  "appview_get_status",
  "appview_get_screen",
  "appview_get_orientation",
  "appview_set_orientation",
  "appview_get_appearance",
  "appview_set_appearance",
  "appview_shake",
  "appview_get_logs",
  "appview_compare_screenshots",
  "appview_get_active_app",
  "appview_get_tap_targets",
  "appview_list_text_inputs",
  "appview_get_attributes",
  "appview_get_all_properties",
  "appview_modify_attribute",
  "appview_get_screenshot",
  "appview_get_custom_info",
  "appview_get_hierarchy_details",
  "appview_get_selectors",
  "appview_find_view",
  "appview_get_view_at_point",
  "appview_wait_for_view",
  "appview_tap",
  "appview_tap_by_label",
  "appview_double_tap",
  "appview_long_press",
  "appview_swipe",
  "appview_drag",
  "appview_pinch",
  "appview_scroll",
  "appview_toggle",
  "appview_select_row",
  "appview_type_text",
  "appview_clear_text",
  "appview_keyboard",
  "appview_modify_custom_attr",
  "appview_invoke_method",
  "appview_wire_selftest",
  "appview_relisten_peertalk",
];

export function registerAppViewTools(server, deps) {
  const { ensureDeviceSelected, limitDepth, countItems, deviceManager } = deps;

  const guardApp = async (expectedBundleId) => {
    const blocked = await ensureDeviceSelected(VIEW_TOOLS);
    if (blocked) return { blocked };
    try {
      const status = await appviewClient.getStatus();
      const appContext = appSession.evaluateStatus(status, expectedBundleId);
      if (appContext.wrongApp) {
        return { blocked: wrongAppPayload(appContext) };
      }
      return { appContext };
    } catch (err) {
      return { blocked: noAppViewAppPayload(err) };
    }
  };

  const runGuarded = async (expectedBundleId, work) => {
    const g = await guardApp(expectedBundleId);
    if (g.blocked) return blockedResult(g.blocked);
    const result = await work(g.appContext);
    return jsonResultWithContext(result, g.appContext);
  };

  const stripExpectedBundleId = (args) => {
    const { expectedBundleId, ...rest } = args;
    return { expectedBundleId, rest };
  };

  defineTool(server, 
    "appview_get_hierarchy",
    "UI view hierarchy tree (oid, className, frame, enabled). includeSystemViews defaults to true; false drops system containers and hoists their children. A node has layoutIssueCount (only when > 0): cached ambiguous-layout hits plus recorded constraint conflicts for that view; open it with appview_get_attributes (al_l, al_c_c). The count only reads the server cache: the ambiguous-layout scan runs when the mac AppView client connects or reloads, never for MCP calls.",
    {
      ...appGuardSchema,
      includeSystemViews: z.boolean().optional().describe("Default true. False omits _* containers and UIKit chrome wrappers."),
      maxDepth: z.number().optional(),
    },
    async ({ expectedBundleId, includeSystemViews, maxDepth }) => {
      return runGuarded(expectedBundleId, async () => {
        const result = await appviewClient.getHierarchy();
        const depth = maxDepth ?? 0;
        let items = depth > 0 ? limitDepth(result.items ?? [], depth) : (result.items ?? []);
        if (includeSystemViews === false) items = omitSystemContainers(items);
        return { appName: result.appName, totalViews: countItems(items), hierarchy: items };
      });
    }
  );

  defineTool(server, 
    "appview_get_status",
    "App status: name, bundle, screen, Peertalk.",
    { ...appGuardSchema },
    async ({ expectedBundleId }) => {
      const g = await guardApp(expectedBundleId);
      if (g.blocked) return blockedResult(g.blocked);
      const status = await appviewClient.getStatus();
      appSession.evaluateStatus(status, expectedBundleId);
      return jsonResult(status);
    }
  );

  defineTool(server, 
    "appview_get_active_app",
    "Foreground AppView app: bundleId, appName, app-changed warning vs last call.",
    { ...appGuardSchema },
    async ({ expectedBundleId }) => {
      const g = await guardApp(expectedBundleId);
      if (g.blocked) return blockedResult(g.blocked);
      const status = await appviewClient.getStatus();
      return jsonResult(appSession.activeAppPayload(status, expectedBundleId));
    }
  );

  defineTool(server, 
    "appview_set_expected_app",
    "Remember expected bundleId for all subsequent view tools (wrong_app guard).",
    { bundleId: z.string().describe("e.g. AppView.AppViewMCPSample") },
    async ({ bundleId }) => {
      const set = appSession.setExpectedBundleId(bundleId);
      return jsonResult({
        success: true,
        expectedBundleId: set,
        hint: "View tools will fail with wrong_app if foreground app bundleId differs.",
      });
    }
  );

  defineTool(server, 
    "appview_clear_expected_app",
    "Clear session expected bundleId (stop wrong_app guard).",
    {},
    async () => {
      appSession.clearExpectedBundleId();
      return jsonResult({ success: true, expectedBundleId: null });
    }
  );

  defineTool(server, 
    "appview_get_tap_targets",
    "Tappable views: oid, frame, enabled, title, action (control/gesture/cell).",
    { ...appGuardSchema },
    async ({ expectedBundleId }) => {
      return runGuarded(expectedBundleId, async () => appviewClient.getTapTargets());
    }
  );

  defineTool(server, 
    "appview_list_text_inputs",
    "All typeable text inputs: UITextField, UITextView, SwiftUI TextField, UITextInput (oid, frame, text).",
    { ...appGuardSchema },
    async ({ expectedBundleId }) => {
      return runGuarded(expectedBundleId, async () => appviewClient.getTextInputs());
    }
  );

  defineTool(server, 
    "appview_get_attributes",
    "Inbuilt attribute groups for a view/layer oid (each attribute includes enabled + setterSelector when modifiable). Auto Layout group: al_l = layout issues [{ kind: ambiguous|conflict, title, constraintIds }] (from the ambiguous-layout cache and recorded conflicts kept until the app resolves them, across Reloads; absent when none; constraintIds only cite rows of this view's al_c_c, never ancestor or sibling constraints); al_c_c = constraints [{ id, effective, active, firstItem, firstAttribute, relation, secondItem, secondAttribute, multiplier, constant, priority, identifier }] where each id matches an al_l constraintIds entry; encapsulated-layout system constraints are never listed. al_c_i = constraints stored on this view between other items (its subviews, or its layout guides and a subview), same row shape as al_c_c. A conflict's broken constraint stays in al_c_c with effective=false.",
    { ...appGuardSchema, oid: z.number() },
    async ({ expectedBundleId, oid }) => {
      return runGuarded(expectedBundleId, async () => appviewClient.getAttributes(oid));
    }
  );

  defineTool(server, 
    "appview_get_all_properties",
    "All inspector properties for oid: view state, inbuilt + custom attribute groups, flat allAttributes list.",
    { ...appGuardSchema, oid: z.number() },
    async ({ expectedBundleId, oid }) => {
      return runGuarded(expectedBundleId, async () => appviewClient.getAllProperties(oid));
    }
  );

  defineTool(server, 
    "appview_modify_attribute",
    "Modify inbuilt attribute (hidden, alpha, colors, etc.).",
    {
      ...appGuardSchema,
      oid: z.number(),
      setterSelector: z.string().describe("e.g. setHidden:, setAlpha:"),
      attrType: z.number().describe("AVAttrType raw value from get_attributes."),
      value: z.union([z.string(), z.number(), z.boolean(), z.record(z.unknown())]).describe("New value."),
    },
    async ({ expectedBundleId, oid, setterSelector, attrType, value }) => {
      return runGuarded(expectedBundleId, async () =>
        appviewClient.modifyAttribute(oid, { setterSelector, attrType, value })
      );
    }
  );

  defineTool(server, 
    "appview_get_screenshot",
    "PNG screenshot of view (oid optional — root window).",
    { ...appGuardSchema, oid: z.number().optional() },
    async ({ expectedBundleId, oid }) => {
      const g = await guardApp(expectedBundleId);
      if (g.blocked) return blockedResult(g.blocked);
      let targetOid = oid;
      if (targetOid === undefined) {
        const hierarchy = await appviewClient.getHierarchy();
        const root = hierarchy.items?.[0];
        if (!root) return { content: [{ type: "text", text: "No views found." }] };
        targetOid = root.oid;
      }
      const result = await appviewClient.getScreenshot(targetOid);
      if (!result.imageBase64) {
        return { content: [{ type: "text", text: "Screenshot not available." }] };
      }
      const warningText =
        g.appContext?.warning && g.appContext.appChanged
          ? `\n_appContext: ${g.appContext.warning}`
          : "";
      return {
        content: [
          { type: "image", data: result.imageBase64, mimeType: result.mimeType ?? "image/png" },
          { type: "text", text: `Screenshot: ${result.width}×${result.height}px${warningText}` },
        ],
      };
    }
  );

  defineTool(server, 
    "appview_get_custom_info",
    "AppView custom attribute groups (AppViewCustomInfo API).",
    { ...appGuardSchema, oid: z.number() },
    async ({ expectedBundleId, oid }) => {
      return runGuarded(expectedBundleId, async () => appviewClient.getCustomInfo(oid));
    }
  );

  defineTool(server, 
    "appview_get_hierarchy_details",
    "Full inspector detail: inbuilt + custom attrs, frame, alpha.",
    { ...appGuardSchema, oid: z.number() },
    async ({ expectedBundleId, oid }) => {
      return runGuarded(expectedBundleId, async () => appviewClient.getHierarchyDetails(oid));
    }
  );

  defineTool(server, 
    "appview_get_selectors",
    "Instance method names for a class (invoke_method helper).",
    {
      ...appGuardSchema,
      className: z.string(),
      hasArg: z.boolean().optional().describe("Methods with arguments (default false)."),
    },
    async ({ expectedBundleId, className, hasArg }) => {
      return runGuarded(expectedBundleId, async () =>
        appviewClient.getSelectors({ className, hasArg: hasArg ?? false })
      );
    }
  );

  defineTool(server, 
    "appview_find_view",
    "Search views by class, a11y id/label, title, or text.",
    searchSchema,
    async (args) => {
      const { expectedBundleId, rest } = stripExpectedBundleId(args);
      return runGuarded(expectedBundleId, async () => appviewClient.findView(rest));
    }
  );

  defineTool(server, 
    "appview_get_view_at_point",
    "Hit-test: view at window coordinates.",
    { ...appGuardSchema, x: z.number(), y: z.number() },
    async ({ expectedBundleId, x, y }) => {
      return runGuarded(expectedBundleId, async () => appviewClient.viewAtPoint({ x, y }));
    }
  );

  defineTool(server, 
    "appview_wait_for_view",
    "Poll find_view until match or timeout.",
    { ...searchSchema, timeout: z.number().optional().describe("Seconds (default 10, max 60).") },
    async (args) => {
      const { expectedBundleId, rest } = stripExpectedBundleId(args);
      return runGuarded(expectedBundleId, async () => appviewClient.waitForView(rest));
    }
  );

  defineTool(server, "appview_tap", "Synthetic tap by oid or x/y.", pointSchema, async (args) => {
    const { expectedBundleId, rest } = stripExpectedBundleId(args);
    return runGuarded(expectedBundleId, async () => appviewClient.tap(rest));
  });

  defineTool(server, 
    "appview_tap_by_label",
    "Find first matching view and tap its center.",
    searchSchema,
    async (args) => {
      const { expectedBundleId, rest } = stripExpectedBundleId(args);
      return runGuarded(expectedBundleId, async () => appviewClient.tapByLabel(rest));
    }
  );

  defineTool(server, 
    "appview_double_tap",
    "Double tap by oid or x/y.",
    pointSchema,
    async (args) => {
      const { expectedBundleId, rest } = stripExpectedBundleId(args);
      return runGuarded(expectedBundleId, async () => appviewClient.doubleTap(rest));
    }
  );

  defineTool(server, 
    "appview_long_press",
    "Long press by oid or x/y.",
    {
      ...pointSchema,
      duration: z.number().optional().describe("Hold seconds (0.2–5, default 0.6)."),
    },
    async (args) => {
      const { expectedBundleId, rest } = stripExpectedBundleId(args);
      return runGuarded(expectedBundleId, async () => appviewClient.longPress(rest));
    }
  );

  defineTool(server, 
    "appview_swipe",
    "Swipe by oid+direction or from/to coordinates.",
    {
      ...appGuardSchema,
      oid: oidSchema,
      direction: z.enum(["up", "down", "left", "right"]).optional(),
      fromX: z.number().optional(),
      fromY: z.number().optional(),
      toX: z.number().optional(),
      toY: z.number().optional(),
      duration: z.number().optional(),
    },
    async (args) => {
      const { expectedBundleId, rest } = stripExpectedBundleId(args);
      return runGuarded(expectedBundleId, async () => appviewClient.swipe(rest));
    }
  );

  defineTool(server, 
    "appview_drag",
    "Drag gesture (same as swipe: oid+direction or from/to).",
    {
      ...appGuardSchema,
      oid: oidSchema,
      direction: z.enum(["up", "down", "left", "right"]).optional(),
      fromX: z.number().optional(),
      fromY: z.number().optional(),
      toX: z.number().optional(),
      toY: z.number().optional(),
      duration: z.number().optional(),
    },
    async (args) => {
      const { expectedBundleId, rest } = stripExpectedBundleId(args);
      return runGuarded(expectedBundleId, async () => appviewClient.drag(rest));
    }
  );

  defineTool(server, 
    "appview_pinch",
    "Pinch zoom on UIScrollView or UIPinchGestureRecognizer.",
    {
      ...pointSchema,
      direction: z.enum(["in", "out"]).optional().describe("Default out."),
      scale: z.number().optional().describe("Scale multiplier (default 1.5 in / 0.67 out)."),
    },
    async (args) => {
      const { expectedBundleId, rest } = stripExpectedBundleId(args);
      return runGuarded(expectedBundleId, async () => appviewClient.pinch(rest));
    }
  );

  defineTool(server, 
    "appview_scroll",
    "Scroll UIScrollView by oid or point.",
    {
      ...appGuardSchema,
      oid: oidSchema,
      x: z.number().optional(),
      y: z.number().optional(),
      direction: z.enum(["up", "down", "left", "right"]).optional(),
      delta: z.number().optional(),
      offsetX: z.number().optional(),
      offsetY: z.number().optional(),
      animated: z.boolean().optional(),
    },
    async (args) => {
      const { expectedBundleId, rest } = stripExpectedBundleId(args);
      return runGuarded(expectedBundleId, async () => appviewClient.scroll(rest));
    }
  );

  defineTool(server, 
    "appview_toggle",
    "Toggle UISwitch or UISegmentedControl.",
    {
      ...appGuardSchema,
      oid: z.number(),
      on: z.boolean().optional().describe("UISwitch target state."),
      segment: z.number().optional().describe("UISegmentedControl index."),
    },
    async (args) => {
      const { expectedBundleId, rest } = stripExpectedBundleId(args);
      return runGuarded(expectedBundleId, async () => appviewClient.toggle(rest));
    }
  );

  defineTool(server, 
    "appview_select_row",
    "Select UITableView/UICollectionView row.",
    {
      ...appGuardSchema,
      oid: z.number(),
      section: z.number().optional(),
      row: z.number().optional(),
    },
    async (args) => {
      const { expectedBundleId, rest } = stripExpectedBundleId(args);
      return runGuarded(expectedBundleId, async () => appviewClient.selectRow(rest));
    }
  );

  defineTool(server, 
    "appview_type_text",
    "Type into UITextField/UITextView/UITextInput by oid or focused field.",
    {
      ...appGuardSchema,
      text: z.string(),
      oid: oidSchema,
      replace: z.boolean().optional(),
      focus: z.boolean().optional(),
    },
    async (args) => {
      const { expectedBundleId, rest } = stripExpectedBundleId(args);
      return runGuarded(expectedBundleId, async () => appviewClient.typeText(rest));
    }
  );

  defineTool(server, 
    "appview_clear_text",
    "Clear text field by oid or focused field.",
    { ...appGuardSchema, oid: oidSchema, focus: z.boolean().optional() },
    async (args) => {
      const { expectedBundleId, rest } = stripExpectedBundleId(args);
      return runGuarded(expectedBundleId, async () => appviewClient.clearText(rest));
    }
  );

  defineTool(server, 
    "appview_keyboard",
    "Keyboard: dismiss, return, insert, delete (backspace).",
    {
      ...appGuardSchema,
      action: z.enum(["dismiss", "return", "insert", "delete"]).optional(),
      key: z.string().optional(),
    },
    async (args) => {
      const { expectedBundleId, rest } = stripExpectedBundleId(args);
      return runGuarded(expectedBundleId, async () => appviewClient.keyboard(rest));
    }
  );

  defineTool(server, 
    "appview_modify_custom_attr",
    "Modify AppView custom attribute via customSetterID.",
    {
      ...appGuardSchema,
      oid: z.number(),
      customSetterID: z.string(),
      attrType: z.number(),
      value: z.union([z.string(), z.number(), z.boolean(), z.record(z.unknown())]).optional(),
    },
    async ({ expectedBundleId, oid, customSetterID, attrType, value }) => {
      return runGuarded(expectedBundleId, async () => {
        const body = { customSetterID, attrType };
        if (value !== undefined) body.value = value;
        return appviewClient.modifyCustomAttr(oid, body);
      });
    }
  );

  defineTool(server, 
    "appview_invoke_method",
    "Invoke parameterless instance method on object by oid.",
    { ...appGuardSchema, oid: z.number(), selector: z.string().describe("e.g. reloadData") },
    async ({ expectedBundleId, oid, selector }) => {
      return runGuarded(expectedBundleId, async () => appviewClient.invokeMethod({ oid, selector }));
    }
  );

  defineTool(server, 
    "appview_wire_selftest",
    "Wire v2 self-test diagnostics (AppViewServer dev).",
    { ...appGuardSchema },
    async ({ expectedBundleId }) => {
      return runGuarded(expectedBundleId, async () => appviewClient.wireSelftest());
    }
  );

  defineTool(server, 
    "appview_get_screen",
    "Compact screen snapshot: app, visible view controllers, alert, and tappable controls. outline=true adds a frame-free tree (oid, class, text, accessibility).",
    {
      ...appGuardSchema,
      outline: z.boolean().optional().describe("Include compact view outline without frames."),
    },
    async ({ expectedBundleId, outline }) => {
      return runGuarded(expectedBundleId, async () => appviewClient.getScreen({ outline: outline === true }));
    }
  );

  defineTool(server, 
    "appview_get_orientation",
    "Current interface orientation of the key window scene.",
    { ...appGuardSchema },
    async ({ expectedBundleId }) => {
      return runGuarded(expectedBundleId, async () => appviewClient.getOrientation());
    }
  );

  defineTool(server, 
    "appview_set_orientation",
    "Request interface orientation via UIWindowScene.requestGeometryUpdate (iOS 16+). Does not use a private orientation hack.",
    {
      ...appGuardSchema,
      orientation: z.enum(["portrait", "portraitUpsideDown", "landscapeLeft", "landscapeRight"]),
    },
    async ({ expectedBundleId, orientation }) => {
      return runGuarded(expectedBundleId, async () => appviewClient.setOrientation({ orientation }));
    }
  );

  defineTool(server, 
    "appview_get_appearance",
    "Current user interface style override on the key window (light, dark, or unspecified).",
    { ...appGuardSchema },
    async ({ expectedBundleId }) => {
      return runGuarded(expectedBundleId, async () => appviewClient.getAppearance());
    }
  );

  defineTool(server, 
    "appview_set_appearance",
    "Set overrideUserInterfaceStyle on all windows (and the window scene on iOS 17+).",
    {
      ...appGuardSchema,
      style: z.enum(["light", "dark", "unspecified"]),
    },
    async ({ expectedBundleId, style }) => {
      return runGuarded(expectedBundleId, async () => appviewClient.setAppearance({ style }));
    }
  );

  defineTool(server, 
    "appview_shake",
    "Deliver a motion shake to the first responder in the key window chain that overrides motionBegan or motionEnded.",
    { ...appGuardSchema },
    async ({ expectedBundleId }) => {
      return runGuarded(expectedBundleId, async () => appviewClient.shake());
    }
  );

  defineTool(server, 
    "appview_get_logs",
    "Recent OSLogStore entries for this process (iOS 15+), newest last. Default limit 100, cap 500.",
    {
      ...appGuardSchema,
      limit: z.number().optional().describe("Max entries (1–500, default 100)."),
      subsystem: z.string().optional(),
      category: z.string().optional(),
    },
    async ({ expectedBundleId, limit, subsystem, category }) => {
      return runGuarded(expectedBundleId, async () => appviewClient.getLogs({ limit, subsystem, category }));
    }
  );

  defineTool(server, 
    "appview_compare_screenshots",
    "Compare a view PNG with the previous capture for that oid. First call stores a baseline and does not return image bytes.",
    {
      ...appGuardSchema,
      oid: z.number().optional().describe("View oid. Defaults to the key window."),
      includeDiffImage: z.boolean().optional().describe("Include a downscaled diff PNG when true."),
    },
    async ({ expectedBundleId, oid, includeDiffImage }) => {
      return runGuarded(expectedBundleId, async () => {
        const body = {};
        if (oid !== undefined) body.oid = oid;
        if (includeDiffImage !== undefined) body.includeDiffImage = includeDiffImage;
        return appviewClient.compareScreenshots(body);
      });
    }
  );

  defineTool(server, 
    "appview_relisten_peertalk",
    "Restart Peertalk listen (mac AppView client reconnect).",
    { ...appGuardSchema },
    async ({ expectedBundleId }) => {
      return runGuarded(expectedBundleId, async () => appviewClient.relistenPeertalk());
    }
  );

  defineTool(server, "appview_list_devices", "List USB devices and booted simulators.", {}, async () => {
    let devices;
    try {
      devices = await deviceManager.listDevices();
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      return jsonResult({ error: message, activeTarget: deviceManager.getActiveTarget(), devices: [] });
    }
    return jsonResult({
      activeTarget: deviceManager.getActiveTarget(),
      devices,
      hint:
        devices.length === 0
          ? "No devices. Connect iOS device via USB."
          : `Found ${devices.length} device(s). Use appview_connect_device.`,
    });
  });

  defineTool(server, 
    "appview_connect_device",
    "Switch target: UDID or 'simulator'.",
    { target: z.string() },
    async ({ target }) => {
      try {
        if (target === "simulator") await deviceManager.connectSimulator();
        else await deviceManager.connectDevice(target);
      } catch (err) {
        const message = err instanceof Error ? err.message : String(err);
        return jsonResult({ success: false, error: message });
      }
      appSession.clearExpectedBundleId();
      appSession.resetTracking();
      try {
        const status = await appviewClient.getStatus();
        return jsonResult({
          success: true,
          target: deviceManager.getActiveTarget(),
          serverStatus: status,
          activeApp: appSession.activeAppPayload(status),
        });
      } catch (err) {
        const errMsg = err instanceof Error ? err.message : String(err);
        return jsonResult({
          success: true,
          target: deviceManager.getActiveTarget(),
          warning: `Port forwarding active but AppViewServer not responding: ${errMsg}`,
        });
      }
    }
  );
}
