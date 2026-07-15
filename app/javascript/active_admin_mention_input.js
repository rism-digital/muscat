import { Editor, mergeAttributes } from "@tiptap/core"
import { PluginKey } from "@tiptap/pm/state"
import StarterKit from "@tiptap/starter-kit"
import Mention from "@tiptap/extension-mention"

const MAX_VISIBLE_SUGGESTIONS = 7

function csrfToken() {
  const meta = document.querySelector('meta[name="csrf-token"]')
  return meta ? meta.content : ""
}

function stripHtml(value) {
  const wrapper = document.createElement("div")
  wrapper.innerHTML = value || ""
  return (wrapper.textContent || wrapper.innerText || "").trim()
}

function normalizeUser(record) {
  const label = stripHtml(record.name || record.label || record.username || record.id || "")
  const id = record.id || record.username || label

  return {
    id,
    label,
    name: record.name,
  }
}

async function fetchUsers(url, query) {
  const response = await fetch(url, {
    method: "POST",
    credentials: "same-origin",
    headers: {
      "Accept": "application/json",
      "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
      "X-CSRF-Token": csrfToken(),
    },
    body: new URLSearchParams({ q: query.trim() }),
  })

  if (!response.ok) {
    return []
  }

  const payload = await response.json()
  if (!Array.isArray(payload)) {
    return []
  }

  return payload.map(normalizeUser).filter((record) => record.label.length > 0)
}

function safeParseJson(value) {
  if (!value || value.trim().length === 0) {
    return null
  }

  try {
    return JSON.parse(value)
  } catch (_error) {
    return null
  }
}

function createSuggestionMenu() {
  let props
  let selectedIndex = 0
  let onDocumentPointerDown
  const popup = document.createElement("div")
  popup.className = "mention-editor__menu"

  function hide() {
    popup.style.display = "none"
    if (onDocumentPointerDown) {
      document.removeEventListener("pointerdown", onDocumentPointerDown, true)
      onDocumentPointerDown = null
    }
  }

  function mount() {
    if (!popup.isConnected) {
      document.body.appendChild(popup)
    }
    popup.style.display = "block"
  }

  function position() {
    const rect = props.clientRect?.()
    const margin = 8
    const viewportWidth = window.innerWidth
    const viewportHeight = window.innerHeight
    const menuWidth = popup.offsetWidth || 240
    const menuHeight = popup.scrollHeight || popup.offsetHeight || 0
    const sampleItem = popup.querySelector(".mention-editor__menu-item, .mention-editor__menu-empty")
    const itemHeight = sampleItem?.offsetHeight || 28
    const maxVisibleHeight = itemHeight * MAX_VISIBLE_SUGGESTIONS

    if (!rect) {
      popup.style.display = "block"
      popup.style.position = "fixed"
      popup.style.top = `${margin}px`
      popup.style.left = `${margin}px`
      return
    }

    const spaceBelow = viewportHeight - rect.bottom - margin
    const spaceAbove = rect.top - margin
    const naturalHeight = Math.min(menuHeight || maxVisibleHeight, maxVisibleHeight)
    const enoughSpaceAbove = spaceAbove >= naturalHeight
    const enoughSpaceBelow = spaceBelow >= naturalHeight
    const useAbove = enoughSpaceAbove || (!enoughSpaceBelow && spaceAbove > spaceBelow)
    const availableHeight = Math.max(96, useAbove ? spaceAbove : spaceBelow)
    const visibleHeight = Math.min(naturalHeight, availableHeight, maxVisibleHeight)
    const top = useAbove
      ? Math.max(margin, rect.top - visibleHeight - margin)
      : Math.min(rect.bottom + margin, viewportHeight - margin - 96)
    const left = Math.min(rect.left, Math.max(margin, viewportWidth - menuWidth - margin))

    popup.style.display = "block"
    popup.style.position = "fixed"
    popup.style.top = `${top}px`
    popup.style.left = `${left}px`
    popup.style.minWidth = `${Math.max(rect.width, 240)}px`
    popup.style.maxHeight = `${visibleHeight}px`
    popup.dataset.mentionPlacement = useAbove ? "above" : "below"
  }

  function renderItems() {
    popup.innerHTML = ""

    if (!props.items || props.items.length === 0) {
      selectedIndex = -1
      const empty = document.createElement("div")
      empty.className = "mention-editor__menu-empty"
      empty.textContent = "No matches"
      popup.appendChild(empty)
      return
    }

    props.items.forEach((item, index) => {
      const button = document.createElement("button")
      button.type = "button"
      button.className = "mention-editor__menu-item"
      button.dataset.mentionLabel = item.label || item.name || item.id || String(item)
      button.textContent = item.label || item.name || item.id || String(item)
      button.setAttribute("aria-selected", index === selectedIndex ? "true" : "false")
      button.addEventListener("mousedown", (event) => {
        event.preventDefault()
        props.command({
          id: item.id || item.label || item.name || String(item),
          label: item.label || item.name || item.id || String(item),
        })
      })
      popup.appendChild(button)
    })

    const activeItem = popup.querySelector('.mention-editor__menu-item[aria-selected="true"]')
    activeItem?.scrollIntoView({ block: "nearest" })
  }

  return {
    onStart(nextProps) {
      props = nextProps
      selectedIndex = 0
      renderItems()
      mount()
      onDocumentPointerDown = (event) => {
        if (popup.contains(event.target)) {
          return
        }
        hide()
      }
      document.addEventListener("pointerdown", onDocumentPointerDown, true)
      position()
    },
    onUpdate(nextProps) {
      props = nextProps
      if (selectedIndex >= props.items.length) {
        selectedIndex = 0
      }
      mount()
      renderItems()
      position()
    },
    onKeyDown(nextProps) {
      if (!props.items || props.items.length === 0) {
        return false
      }

      if (nextProps.event.key === "ArrowDown") {
        selectedIndex = (selectedIndex + 1) % props.items.length
        renderItems()
        return true
      }

      if (nextProps.event.key === "ArrowUp") {
        selectedIndex = (selectedIndex - 1 + props.items.length) % props.items.length
        renderItems()
        return true
      }

      if (nextProps.event.key === "Enter") {
        const item = props.items[selectedIndex]
        if (item) {
          props.command({ id: item.id, label: item.label })
          return true
        }
      }

      if (nextProps.event.key === "Tab") {
        if (props.items.length === 1) {
          const item = props.items[0]
          props.command({ id: item.id, label: item.label })
        }
        return true
      }

      if (nextProps.event.key === "Escape") {
        hide()
        return true
      }

      return false
    },
    onExit() {
      hide()
      popup.remove()
    },
  }
}

function initMentionField(root) {
  if (root.dataset.mentionInitialized === "true") {
    return
  }

  const editorMount = root.querySelector("[data-mention-editor]")
  const hiddenField = root.querySelector("[data-mention-hidden]")
  const hiddenJsonField = root.querySelector("[data-mention-hidden-json]")
  const usersUrl = root.dataset.mentionUsersUrl
  const trigger = root.dataset.mentionTrigger || "@"
  const outputMode = root.dataset.mentionOutputMode || (hiddenJsonField ? "text_json" : "html")

  if (!editorMount || !hiddenField || !usersUrl) {
    return
  }

  if (root._mentionEditor) {
    root._mentionEditor.destroy()
    root._mentionEditor = null
  }

  root.dataset.mentionInitialized = "true"
  const pluginKey = new PluginKey(
    `mention-${editorMount.id || hiddenField.id || Math.random().toString(36).slice(2)}`
  )

  const editor = new Editor({
    element: editorMount,
    content: hiddenJsonField ? safeParseJson(hiddenJsonField.value) || hiddenField.value || "" : hiddenField.value || "",
    editorProps: {
      attributes: {
        class: "mention-editor__content",
      },
    },
    extensions: [
      StarterKit.configure({
        blockquote: false,
        bold: false,
        bulletList: false,
        code: false,
        codeBlock: false,
        dropcursor: false,
        gapcursor: false,
        heading: false,
        horizontalRule: false,
        italic: false,
        listItem: false,
        orderedList: false,
        strike: false,
        underline: false,
        link: false,
      }),
      Mention.configure({
        HTMLAttributes: {
          class: "mention-editor__mention",
        },
        renderHTML({ node, HTMLAttributes }) {
          const label = node.attrs.label || node.attrs.id

          return [
            "span",
            mergeAttributes(HTMLAttributes, {
              "data-mention-id": node.attrs.id,
              "data-mention-label": label,
              style:
                "display:inline;padding:0.05rem 0.2rem;border-radius:0.25rem;background:#dbeafe;color:#1d4ed8;font-weight:400;text-decoration:none;white-space:nowrap;",
            }),
            `${trigger}${label}`,
          ]
        },
        renderText({ node }) {
          const label = node.attrs.label || node.attrs.id
          return `${trigger}${label}`
        },
        suggestion: {
          pluginKey,
          char: trigger,
          allowSpaces: true,
          items: async ({ query }) => fetchUsers(usersUrl, query),
          render: () => createSuggestionMenu(),
        },
      }),
    ],
    onUpdate: ({ editor: currentEditor }) => {
      if (outputMode === "text_json") {
        hiddenField.value = currentEditor.getText()
        if (hiddenJsonField) {
          hiddenJsonField.value = JSON.stringify(currentEditor.getJSON())
        }
      } else {
        hiddenField.value = currentEditor.getHTML()
      }
    },
  })

  root._mentionEditor = editor

  hiddenField.form?.addEventListener("reset", () => {
    window.setTimeout(() => {
      editor.commands.setContent(hiddenField.value || "", false)
    }, 0)
  })
}

function initMentionEditors() {
  document.querySelectorAll("[data-mention-field]").forEach(initMentionField)
}

document.addEventListener("DOMContentLoaded", initMentionEditors)
document.addEventListener("turbo:load", initMentionEditors)
