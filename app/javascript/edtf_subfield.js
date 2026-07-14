import edtf, { format, defaults } from "edtf"

defaults.level = 3
// Keep the legacy globals available for existing validator code paths.
window.edtf = edtf
window.edtf_format = format

function updateEdtf(input) {
  let parsedDate
  let defaultLocale = "en-US"

  const formats = {
    weekday: "long",
    year: "numeric",
    month: "long",
    day: "numeric",
  }

  const message = document.getElementById("edtf-message")
  const error = document.getElementById("edtf-error")

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

function initEdtfSubfield() {
  const input = document.getElementById("input-edtf")

  if (!input || input.dataset.edtfInitialized === "true") {
    return
  }

  input.dataset.edtfInitialized = "true"
  input.addEventListener("keyup", (event) => {
    event.preventDefault()
    updateEdtf(input)
  })

  updateEdtf(input)
}

document.addEventListener("DOMContentLoaded", initEdtfSubfield)
document.addEventListener("turbo:load", initEdtfSubfield)
