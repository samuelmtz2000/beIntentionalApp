Adds Archive pill and panel to Habits screen.

- Lists archived Areas/Habits/Bad Habits from GET /archive
- Swipe to restore each item (calls new restore endpoints)

Backend dependency
- Requires API branch adding soft delete + restore + /archive

Test plan
- Delete one of each type; verify it appears in Archive
- Restore and confirm it returns to active lists
