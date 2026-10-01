import edtf, { format, defaults } from "edtf"

defaults.level = 3
// Keep the legacy globals available for existing validator code paths.
window.edtf = edtf
window.edtf_format = format

window.muscatWidgetInitializers = window.muscatWidgetInitializers || []
window.muscatRegisterWidgetInitializer = window.muscatRegisterWidgetInitializer || function(initializer) {
  if (!window.muscatWidgetInitializers.includes(initializer)) {
    window.muscatWidgetInitializers.push(initializer)
  }
}
window.muscatInitializeWidgetsInBlock = window.muscatInitializeWidgetsInBlock || function(root) {
  const scope = root || document

  window.muscatWidgetInitializers.forEach((initializer) => {
    initializer(scope)
  })
}

function bindEdtfDelegatedKeyup() {
  if (window.muscatEdtfDelegatedKeyupBound) {
    return
  }

  window.muscatEdtfDelegatedKeyupBound = true
  document.addEventListener("keyup", (event) => {
    if (!(event.target instanceof HTMLElement)) {
      return
    }

    if (!event.target.matches(".input-edtf")) {
      return
    }

    updateEdtf(event.target)
  })
}

function updateEdtf(input) {
  let parsedDate
  let defaultLocale = "en-US"

  const formats = {
    weekday: "long",
    year: "numeric",
    month: "long",
    day: "numeric",
  }

  const container = input.closest(".edtf-subfield") || input.parentElement || document
  const message = container.querySelector(".edtf-message")
  const error = container.querySelector(".edtf-error")

  function setErrorText(text) {
    if (!error) {
      return
    }

    error.innerHTML = ""
    const pre = document.createElement("pre")
    pre.textContent = text
    error.appendChild(pre)
  }

  if (!input.value) {
    if (message) {
      message.textContent = ""
    }
    if (error) {
      error.innerHTML = ""
    }
    return
  }

  try {
    parsedDate = edtf(input.value)
  } catch (err) {
    const first3Lines = err.message.split(/\r?\n/).slice(0, 4).join("\n")
    if (message) {
      message.textContent = "It was not possible to parse the EDTF date ☹"
    }
    setErrorText(first3Lines)
    return
  }

  let formatted = parsedDate

  try {
    formatted = format(parsedDate, defaultLocale, formats)
  } catch (_err) {
    // Keep the parsed representation if formatting fails.
  }

  if (message) {
    message.textContent = `Formatted date: ${formatted}`
  }
  if (error) {
    error.innerHTML = ""
  }
}

function initEdtfSubfield(root) {
  const scope = root || document
  const inputs = scope.querySelectorAll(".input-edtf")

  inputs.forEach((input) => {
    if (input.dataset.edtfInitialized === "true") {
      return
    }

    input.dataset.edtfInitialized = "true"

    updateEdtf(input)
  })
}

bindEdtfDelegatedKeyup()
window.muscatRegisterWidgetInitializer(initEdtfSubfield)

document.addEventListener("DOMContentLoaded", () => {
  window.muscatInitializeWidgetsInBlock(document)
})
document.addEventListener("turbo:load", () => {
  window.muscatInitializeWidgetsInBlock(document)
})
