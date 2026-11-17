(() => {
  // app/javascript/bulk_marc_editor.js
  (function() {
    function initialize() {
      var root = document.getElementById("bulk-marc-editor");
      if (!root || root.dataset.initialized) return;
      root.dataset.initialized = "true";
      var fields = JSON.parse(root.querySelector("[data-bulk-marc-fields]").textContent);
      var tag = root.querySelector("#bulk_marc_tag");
      var subfield = root.querySelector("#bulk_marc_subfield");
      var action = root.querySelector("#bulk_marc_action");
      var target = root.querySelector("#bulk_marc_target");
      var matchSubfield = root.querySelector("#bulk_marc_match_subfield");
      fields.forEach(function(field) {
        tag.add(new Option(field.label, field.code));
      });
      function selectedField() {
        return fields.find(function(field) {
          return field.code === tag.value;
        });
      }
      function selectedSubfield(code) {
        var field = selectedField();
        return field && field.subfields.find(function(entry) {
          return entry.code === code;
        });
      }
      function visible(selector, show) {
        root.querySelectorAll(selector).forEach(function(row) {
          row.hidden = !show;
          row.querySelectorAll("input, select").forEach(function(input) {
            input.disabled = !show || input.dataset.customInactive === "true";
          });
        });
      }
      function valueInput(name, field) {
        var container = root.querySelector('[data-bulk-value="' + name + '"]');
        container.textContent = "";
        var input = document.createElement("input");
        input.type = "text";
        input.id = "bulk_marc_" + name;
        input.name = "operations[][" + name + "]";
        input.required = name === "value";
        var choices = field ? field.choices : [];
        if (!choices.length) {
          container.appendChild(input);
          return;
        }
        var select = document.createElement("select");
        select.name = input.name;
        select.id = input.id;
        input.id += "_custom";
        input.setAttribute("aria-label", "Other value");
        input.placeholder = "Enter another value";
        select.required = input.required;
        select.add(new Option("Choose a value\u2026", ""));
        var groups = {};
        choices.forEach(function(choice) {
          var parent = select;
          if (choice.group) {
            if (!groups[choice.group]) {
              groups[choice.group] = document.createElement("optgroup");
              groups[choice.group].label = choice.group;
              select.appendChild(groups[choice.group]);
            }
            parent = groups[choice.group];
          }
          parent.appendChild(new Option(choice.label, choice.value));
        });
        var other = new Option("Other value\u2026", "");
        other.dataset.custom = "true";
        select.add(other);
        input.hidden = input.disabled = true;
        input.dataset.customInactive = "true";
        select.addEventListener("change", function() {
          var custom = select.options[select.selectedIndex].dataset.custom === "true";
          select.name = custom ? "" : input.name;
          select.required = custom ? false : name === "value";
          input.hidden = input.disabled = !custom;
          input.dataset.customInactive = String(!custom);
          if (custom) input.focus();
        });
        container.appendChild(select);
        container.appendChild(input);
      }
      function refreshVisibility() {
        var adding = action.value === "add";
        visible("[data-bulk-target]", adding);
        visible("[data-bulk-condition]", adding && target.value === "matching");
        visible("[data-bulk-old]", !adding);
      }
      function refreshValues() {
        valueInput("value", selectedSubfield(subfield.value));
        valueInput("old_value", selectedSubfield(subfield.value));
        valueInput("match_value", selectedSubfield(matchSubfield.value));
        refreshVisibility();
      }
      tag.addEventListener("change", function() {
        subfield.textContent = matchSubfield.textContent = "";
        var field = selectedField();
        if (field) field.subfields.forEach(function(entry) {
          subfield.add(new Option(entry.label, entry.code));
          matchSubfield.add(new Option(entry.label, entry.code));
        });
        subfield.required = !(field && field.subfields.some(function(entry) {
          return entry.code === "";
        }));
        refreshValues();
      });
      subfield.addEventListener("change", refreshValues);
      matchSubfield.addEventListener("change", function() {
        valueInput("match_value", selectedSubfield(matchSubfield.value));
        refreshVisibility();
      });
      action.addEventListener("change", refreshVisibility);
      target.addEventListener("change", refreshVisibility);
      refreshValues();
      var submitted = JSON.parse(root.querySelector("[data-bulk-marc-operation]").textContent);
      if (submitted.tag && fields.some(function(field) {
        return field.code === submitted.tag;
      })) {
        tag.value = submitted.tag;
        tag.dispatchEvent(new Event("change"));
        subfield.value = submitted.subfield || "";
        subfield.dispatchEvent(new Event("change"));
        if (submitted.action) action.value = submitted.action;
        if (submitted.target) target.value = submitted.target;
        if (submitted.match_subfield !== void 0) matchSubfield.value = submitted.match_subfield;
        matchSubfield.dispatchEvent(new Event("change"));
        ["value", "old_value", "match_value"].forEach(function(name) {
          if (typeof submitted[name] !== "string") return;
          var container = root.querySelector('[data-bulk-value="' + name + '"]');
          var select = container.querySelector("select");
          var input = container.querySelector("input");
          if (select) {
            var listed = Array.from(select.options).find(function(option) {
              return option.value === submitted[name] && !option.dataset.custom;
            });
            select.selectedIndex = listed ? listed.index : select.options.length - 1;
            select.dispatchEvent(new Event("change"));
          }
          input.value = submitted[name];
        });
        refreshVisibility();
      }
    }
    document.addEventListener("DOMContentLoaded", initialize);
    document.addEventListener("turbolinks:load", initialize);
  })();
})();
