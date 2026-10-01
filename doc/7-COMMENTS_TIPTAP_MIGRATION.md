# Comments Mention System Migration

This document explains how the legacy ActiveAdmin comment input worked, how the new Tiptap-based input works, and which files are involved in each path.

## Old system

### How it worked

The old comment box was a plain ActiveAdmin textarea enhanced with Tribute.js. When a user typed `@`, Tribute queried `/admin/users/list`, showed a dropdown, and inserted a mention token into the textarea. The backend then stored the textarea body as plain text.

That old flow only had one real payload:

- `body` as text

Mentions were not stored as structured data. Notifications relied on scanning the text body for `@...` patterns.

### Files involved

- `app/assets/javascripts/tribute_load.js`
- `app/assets/javascripts/application.js`
- `app/assets/javascripts/active_admin.js.coffee`
- `app/admin/user.rb`
- `app/admin/comments.rb`
- `app/views/shared/_active_admin_comment_form.html.erb`
- `config/initializers/active_admin.rb`
- `app/mailers/comment_notifications.rb`

### What to know about the legacy path

- `tribute_load.js` attaches Tribute to the old textarea.
- `app/admin/user.rb` serves the `/admin/users/list` lookup endpoint.
- `comment_notifications.rb` extracted mentioned users by regex from `body`.
- The old ActiveAdmin comment panel came from ActiveAdmin defaults, with local patches in this app to fit Muscat.

## New system

### How it works

The new system replaces the textarea editor with a Tiptap editor inside a reusable partial. The editor writes both plain text and structured JSON into hidden fields.

The current payload model is:

- `body` for backward-compatible plain text
- `body_json` for canonical editor state
- `mentioned_user_ids` for notification targeting

The flow is:

1. The page renders a reusable mention editor partial.
2. `active_admin_mention_input.js` initializes a Tiptap editor for each `[data-mention-field]`.
3. When the user types `@`, the editor fetches users from `/admin/users/list`.
4. On every change, the editor updates:
   - the plain text hidden field
   - the JSON hidden field
5. The ActiveAdmin comment resource normalizes the payload before save.
6. Notifications use `mentioned_user_ids` when present, and fall back to text parsing for legacy comments.

### Files involved

- `app/javascript/active_admin_mention_input.js`
- `app/assets/stylesheets/mention_input.css`
- `app/views/shared/_mention_editor.html.erb`
- `app/views/shared/_active_admin_comment_form.html.erb`
- `app/helpers/active_admin/views_helper.rb`
- `app/admin/comments.rb`
- `app/models/active_admin/comment.rb`
- `app/mailers/comment_notifications.rb`
- `app/admin/user.rb`
- `config/initializers/active_admin.rb`
- `db/migrate/20260713130000_add_rich_fields_to_active_admin_comments.rb`
- `db/schema.rb`

### What each file does

- `app/views/shared/_mention_editor.html.erb` renders the editor mount point and hidden fields.
- `app/javascript/active_admin_mention_input.js` owns Tiptap setup, mention lookup, menu behavior, and hidden-field syncing.
- `app/assets/stylesheets/mention_input.css` styles the editor, mention highlights, and suggestion menu.
- `app/views/shared/_active_admin_comment_form.html.erb` plugs the editor partial into the ActiveAdmin comment form.
- `app/helpers/active_admin/views_helper.rb` renders the custom comments panel and the custom comment form wrapper.
- `app/admin/comments.rb` controls comment persistence, parameter permitting, and notification delivery.
- `app/models/active_admin/comment.rb` derives plain text and mentioned user IDs from `body_json`.
- `app/mailers/comment_notifications.rb` sends notifications based on structured mention IDs first, with legacy regex fallback.
- `app/admin/user.rb` serves the mention lookup endpoint for the editor.
- `db/migrate/20260713130000_add_rich_fields_to_active_admin_comments.rb` adds the new JSON columns.

## Compatibility rule

The system keeps `body` as the human-readable text representation so old code paths and legacy comments remain usable.

At the same time, `body_json` and `mentioned_user_ids` preserve structured data for the new editor and for notification logic.

## Practical summary

- Legacy comments: plain text only, regex-based mention detection.
- New comments: Tiptap JSON + plain text + extracted mention user IDs.
- Existing records: still readable through `body`.
- Future records: should write all three fields.
