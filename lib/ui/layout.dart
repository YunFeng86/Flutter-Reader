// Layout constants tuned for desktop-first RSS reading.
//
// These are used to decide when to drop panes (3 -> 2 -> 2 -> 1) and to keep
// the reading measure comfortable.

// Maximum text measure for comfortable reading. This value also participates
// in desktop layout decisions (when to drop panes).
const double kMaxReadingWidth = 700;

// Desktop fixed panes (in logical pixels).
const double kDesktopSidebarWidth = 260;
const double kDesktopListWidth = 400;
const double kDividerWidth = 1;

// Classic compact breakpoint; desktop can still be narrower when the window is
// resized, but this helps keep mobile behavior consistent.
const double kCompactWidth = 600;

/// Desktop progressive layout modes (4 stages):
///
/// 1) threePane: sidebar + list + reader (reader reserved even when empty)
/// 2) splitListReader: list + reader (sidebar in drawer)
/// 3) splitSidebarList: sidebar + list (reader is a secondary page)
/// 4) listOnly: list only (sidebar in drawer; reader is a secondary page)
enum DesktopPaneMode { threePane, splitListReader, splitSidebarList, listOnly }

DesktopPaneMode desktopModeForWidth(double width) {
  // Stage 1 -> 2 boundary: when the reader pane would shrink below the maximum
  // comfortable measure, we fold the sidebar into a drawer.
  final needFor3 = kDesktopSidebarWidth +
      kDesktopListWidth +
      kMaxReadingWidth +
      kDividerWidth * 2;

  // Stage 2 -> 3 boundary: when list+reader would make the reader narrower than
  // the max reading width, we move the reader into a secondary page.
  final needForListReader =
      kDesktopListWidth + kMaxReadingWidth + kDividerWidth;

  // Stage 3 -> 4 boundary: when sidebar+list no longer fits, we fold sidebar
  // into a drawer and keep only the list.
  final needForSidebarList =
      kDesktopSidebarWidth + kDesktopListWidth + kDividerWidth;

  if (width >= needFor3) return DesktopPaneMode.threePane;
  if (width >= needForListReader) return DesktopPaneMode.splitListReader;
  if (width >= needForSidebarList) return DesktopPaneMode.splitSidebarList;
  return DesktopPaneMode.listOnly;
}

bool desktopSidebarInline(DesktopPaneMode mode) =>
    mode == DesktopPaneMode.threePane || mode == DesktopPaneMode.splitSidebarList;

bool desktopSidebarInDrawer(DesktopPaneMode mode) =>
    mode == DesktopPaneMode.splitListReader || mode == DesktopPaneMode.listOnly;

bool desktopReaderEmbedded(DesktopPaneMode mode) =>
    mode == DesktopPaneMode.threePane || mode == DesktopPaneMode.splitListReader;

