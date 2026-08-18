(function () {
  "use strict";

  function deepCopy(value) {
    return JSON.parse(JSON.stringify(value));
  }

  function humanize(value) {
    return String(value || "")
      .replace(/_/g, " ")
      .replace(/\b\w/g, function (letter) { return letter.toUpperCase(); });
  }

  function option(value, label) {
    var element = document.createElement("option");
    element.value = value;
    element.textContent = label;
    return element;
  }

  function button(label, action, className) {
    var element = document.createElement("button");
    element.type = "button";
    element.className = className || "button";
    element.dataset.action = action;
    element.textContent = label;
    return element;
  }

  function NotificationRuleBuilder(root) {
    this.root = root;
    this.config = JSON.parse(root.dataset.config);
    this.hidden = root.querySelector("[data-notification-rules-legacy]");
    this.list = root.querySelector("[data-rule-list]");
    this.legacyLines = root.querySelector("[data-legacy-lines]");
    this.legacyPreview = root.querySelector("[data-legacy-preview]");
    this.state = this.parseLegacyRules(this.hidden.value);

    this.legacyLines.value = this.state.legacy_lines.join("\n");
    this.bind();
    this.render();
  }

  NotificationRuleBuilder.prototype.parseLegacyRules = function (value) {
    var self = this;
    var state = { rules: [], legacy_lines: [] };

    String(value || "").split(/\r?\n/).forEach(function (rawLine) {
      var line = rawLine.trim();
      if (!line) return;

      var rule = self.parseLegacyLine(line);
      if (rule) {
        state.rules.push(rule);
      } else {
        state.legacy_lines.push(line);
      }
    });

    return state;
  };

  NotificationRuleBuilder.prototype.parseLegacyLine = function (line) {
    var tokens = [];
    var tokenPattern = /([^\s:]+:"[^"]*"|[^\s]+)/g;
    var match;
    var lastIndex = 0;

    while ((match = tokenPattern.exec(line)) !== null) {
      if (line.slice(lastIndex, match.index).trim()) return null;
      tokens.push(match[0]);
      lastIndex = tokenPattern.lastIndex;
    }
    if (line.slice(lastIndex).trim() || tokens.length === 0) return null;

    var ungrouped = [];
    var parsed = [];
    for (var index = 0; index < tokens.length; index += 1) {
      var token = tokens[index];
      var colon = token.indexOf(":");
      if (colon === -1) {
        ungrouped.push(token);
        continue;
      }
      if (colon === 0 || colon !== token.lastIndexOf(":")) return null;

      var field = token.slice(0, colon);
      var pattern = token.slice(colon + 1);
      if (pattern.charAt(0) === "\"") {
        if (pattern.charAt(pattern.length - 1) !== "\"") return null;
        pattern = pattern.slice(1, -1);
      } else if (pattern.indexOf("\"") !== -1) {
        return null;
      }
      parsed.push({ field: field, pattern: pattern });
    }

    if (ungrouped.length > 1) return null;
    var explicitModel = ungrouped[0];
    if (explicitModel && (explicitModel === "all" || this.config.models.indexOf(explicitModel) === -1)) return null;

    var nonExclusions = parsed.filter(function (item) { return item.field !== "exclude"; });
    if (nonExclusions.length === 0) return null;

    var model;
    if (explicitModel) {
      model = explicitModel;
    } else if (parsed.every(function (item) { return item.field === "follow"; })) {
      model = "all";
    } else {
      model = "source";
    }

    var allowedFields = this.config.fields[model] || [];
    var rule = { model: model, conditions: [] };
    for (var itemIndex = 0; itemIndex < parsed.length; itemIndex += 1) {
      var item = parsed[itemIndex];
      if (item.field === "exclude") {
        if (item.pattern !== "mine" || rule.exclude) return null;
        rule.exclude = { own_changes: true };
        continue;
      }
      if (allowedFields.indexOf(item.field) === -1 || !item.pattern) return null;
      if (this.config.exact_fields.indexOf(item.field) >= 0 && item.pattern.indexOf("*") !== -1) return null;

      var operatorAndValue = this.operatorAndValueForPattern(item.pattern);
      rule.conditions.push({
        field: item.field,
        operator: operatorAndValue.operator,
        value: operatorAndValue.value
      });
    }

    return rule;
  };

  NotificationRuleBuilder.prototype.operatorAndValueForPattern = function (pattern) {
    var starCount = (pattern.match(/\*/g) || []).length;
    if (pattern.charAt(0) === "*" && pattern.charAt(pattern.length - 1) === "*" && starCount === 2) {
      return { operator: "contains", value: pattern.slice(1, -1) };
    }
    if (pattern.charAt(pattern.length - 1) === "*" && starCount === 1) {
      return { operator: "starts_with", value: pattern.slice(0, -1) };
    }
    if (pattern.charAt(0) === "*" && starCount === 1) {
      return { operator: "ends_with", value: pattern.slice(1) };
    }
    if (starCount > 0) return { operator: "glob", value: pattern };
    return { operator: "equals", value: pattern };
  };

  NotificationRuleBuilder.prototype.bind = function () {
    var self = this;

    this.root.querySelector("[data-add-rule]").addEventListener("click", function () {
      self.state.rules.push(self.newRule());
      self.render();
    });

    this.legacyLines.addEventListener("input", function () {
      self.state.legacy_lines = self.legacyLines.value
        .split(/\r?\n/)
        .map(function (line) { return line.trim(); })
        .filter(Boolean);
      self.sync();
    });
  };

  NotificationRuleBuilder.prototype.newRule = function () {
    return {
      model: "source",
      conditions: [{ field: "composer", operator: "equals", value: "" }]
    };
  };

  NotificationRuleBuilder.prototype.render = function () {
    var self = this;
    this.list.innerHTML = "";

    if (this.state.rules.length === 0) {
      var empty = document.createElement("div");
      empty.className = "notification-rule-builder__empty";
      empty.textContent = this.config.labels.empty;
      this.list.appendChild(empty);
    }

    this.state.rules.forEach(function (rule, ruleIndex) {
      if (ruleIndex > 0) {
        var separator = document.createElement("div");
        separator.className = "notification-rule-builder__or";
        separator.textContent = self.config.labels.or;
        self.list.appendChild(separator);
      }
      self.list.appendChild(self.renderRule(rule, ruleIndex));
    });

    this.sync();
  };

  NotificationRuleBuilder.prototype.renderRule = function (rule, ruleIndex) {
    var self = this;
    var card = document.createElement("section");
    card.className = "notification-rule-card";

    var header = document.createElement("div");
    header.className = "notification-rule-card__header";

    var badge = document.createElement("span");
    badge.className = "notification-rule-card__number";
    badge.textContent = this.config.labels.rule + " " + (ruleIndex + 1);
    header.appendChild(badge);
    card.appendChild(header);

    var overview = document.createElement("div");
    overview.className = "notification-rule-card__overview";
    var summary = document.createElement("strong");
    summary.className = "notification-rule-card__summary";
    summary.textContent = this.summary(rule);

    var actions = document.createElement("div");
    actions.className = "notification-rule-card__actions";
    actions.appendChild(button(this.config.labels.duplicate, "duplicate-rule", "button"));
    actions.appendChild(button(this.config.labels.remove, "remove-rule", "button button--danger"));
    overview.appendChild(summary);
    overview.appendChild(actions);
    card.appendChild(overview);

    actions.querySelector("[data-action='duplicate-rule']").addEventListener("click", function () {
      self.state.rules.splice(ruleIndex + 1, 0, deepCopy(rule));
      self.render();
    });
    actions.querySelector("[data-action='remove-rule']").addEventListener("click", function () {
      self.state.rules.splice(ruleIndex, 1);
      self.render();
    });

    var modelRow = document.createElement("div");
    modelRow.className = "notification-rule-card__model";
    var modelTitle = document.createElement("div");
    modelTitle.className = "notification-rule-card__model-title";
    modelTitle.textContent = this.config.labels.when;
    var modelSelect = document.createElement("select");
    modelSelect.className = "notification-rule-card__model-select";
    this.config.models.forEach(function (model) {
      modelSelect.appendChild(option(model, model === "all" ? self.config.labels.any_record : humanize(model)));
    });
    modelSelect.value = rule.model;
    var modelControl = document.createElement("div");
    modelControl.className = "notification-rule-card__model-control";
    modelControl.appendChild(modelSelect);
    modelRow.appendChild(modelTitle);
    modelRow.appendChild(modelControl);
    card.appendChild(modelRow);

    modelSelect.addEventListener("change", function () {
      rule.model = modelSelect.value;
      if (rule.model === "all") delete rule.exclude;
      rule.conditions.forEach(function (condition) {
        var fields = self.config.fields[rule.model] || [];
        if (fields.indexOf(condition.field) === -1) {
          condition.field = fields[0];
          delete condition.reference;
        }
      });
      self.render();
    });

    var conditions = document.createElement("div");
    conditions.className = "notification-rule-card__conditions";
    rule.conditions.forEach(function (condition, conditionIndex) {
      conditions.appendChild(self.renderCondition(rule, condition, ruleIndex, conditionIndex, summary));
    });
    card.appendChild(conditions);

    var footer = document.createElement("div");
    footer.className = "notification-rule-card__footer";
    var addCondition = button(this.config.labels.add_condition, "add-condition", "button");
    footer.appendChild(addCondition);

    var excludeLabel = document.createElement("label");
    excludeLabel.className = "notification-rule-card__exclude";
    var excludeCheckbox = document.createElement("input");
    excludeCheckbox.type = "checkbox";
    excludeCheckbox.checked = !!(rule.exclude && rule.exclude.own_changes);
    excludeCheckbox.disabled = rule.model === "all";
    excludeLabel.appendChild(excludeCheckbox);
    excludeLabel.appendChild(document.createTextNode(" " + (this.config.labels.exclude_own || "Do not notify me about my own changes")));
    footer.appendChild(excludeLabel);
    card.appendChild(footer);

    addCondition.addEventListener("click", function () {
      var field = (self.config.fields[rule.model] || [])[0];
      rule.conditions.push({ field: field, operator: "equals", value: "" });
      self.render();
    });
    excludeCheckbox.addEventListener("change", function () {
      if (excludeCheckbox.checked) {
        rule.exclude = { own_changes: true };
      } else {
        delete rule.exclude;
      }
      self.updateSummary(summary, rule);
      self.sync();
    });

    return card;
  };

  NotificationRuleBuilder.prototype.renderCondition = function (rule, condition, ruleIndex, conditionIndex, summary) {
    var self = this;
    var row = document.createElement("div");
    row.className = "notification-condition";

    var conjunction = document.createElement("span");
    conjunction.className = "notification-condition__and";
    conjunction.textContent = conditionIndex === 0 ? this.config.labels.where : this.config.labels.and;
    row.appendChild(conjunction);

    var field = document.createElement("select");
    field.className = "notification-condition__field";
    (this.config.fields[rule.model] || []).forEach(function (name) {
      field.appendChild(option(name, humanize(name)));
    });
    field.value = condition.field;
    row.appendChild(field);

    var operatorSelect = document.createElement("select");
    operatorSelect.className = "notification-condition__operator";
    var availableOperators = this.config.exact_fields.indexOf(condition.field) >= 0 ? ["equals"] : this.config.operators;
    if (availableOperators.indexOf(condition.operator) === -1) condition.operator = availableOperators[0];
    availableOperators.forEach(function (name) {
      operatorSelect.appendChild(option(name, humanize(name)));
    });
    operatorSelect.value = condition.operator;
    row.appendChild(operatorSelect);

    var value = document.createElement("input");
    value.type = "text";
    value.className = "notification-condition__value";
    value.value = condition.value || "";
    value.placeholder = humanize(condition.field);
    value.required = true;
    value.maxLength = 500;
    row.appendChild(value);
    this.validateValueInput(value);
    this.attachAutocomplete(value, rule, condition);

    var remove = button("×", "remove-condition", "notification-condition__remove");
    remove.title = this.config.labels.remove;
    remove.disabled = rule.conditions.length === 1;
    row.appendChild(remove);

    field.addEventListener("change", function () {
      condition.field = field.value;
      condition.value = "";
      delete condition.reference;
      self.render();
    });
    operatorSelect.addEventListener("change", function () {
      condition.operator = operatorSelect.value;
      self.updateSummary(summary, rule);
      self.sync();
    });
    value.addEventListener("input", function () {
      condition.value = value.value;
      delete condition.reference;
      self.validateValueInput(value);
      self.updateSummary(summary, rule);
      self.sync();
    });
    remove.addEventListener("click", function () {
      rule.conditions.splice(conditionIndex, 1);
      self.render();
    });

    return row;
  };

  NotificationRuleBuilder.prototype.validateValueInput = function (input) {
    var invalid = /[:"\r\n]/.test(input.value);
    input.setCustomValidity(invalid ? this.config.labels.invalid_value : "");
  };

  NotificationRuleBuilder.prototype.attachAutocomplete = function (input, rule, condition) {
    if (!window.jQuery || !jQuery.fn.autocomplete) return;

    var endpointType;
    if (condition.field === "follow" || condition.field === "owner") endpointType = "user";
    if (condition.field === "lib_siglum" || (rule.model === "institution" && condition.field === "siglum")) endpointType = "institution";
    if ((rule.model === "person" && condition.field === "full_name") || condition.field === "composer") endpointType = "person";
    if (!endpointType || !this.config.endpoints[endpointType]) return;

    var self = this;
    jQuery(input).autocomplete({
      source: function (request, response) {
        jQuery.getJSON(self.config.endpoints[endpointType], { q: request.term, term: request.term })
          .done(function (items) {
            response((items || []).map(function (item) {
              var label = item.label || item.value || item.name || item.full_name || item.siglum;
              return {
                label: label,
                value: item.value || item.name || item.full_name || item.siglum || label,
                id: item.id || item.shortid
              };
            }));
          })
          .fail(function () { response([]); });
      },
      minLength: 2,
      select: function (_event, ui) {
        var item = ui.item || {};
        condition.value = item.value || item.label || item.name || "";
        condition.reference = { type: endpointType, id: item.id || item.shortid };
        input.value = condition.value;
        self.validateValueInput(input);
        self.render();
        return false;
      }
    });
  };

  NotificationRuleBuilder.prototype.summary = function (rule) {
    var parts = (rule.conditions || []).map(function (condition) {
      var value = condition.value ? "“" + condition.value + "”" : "…";
      return humanize(condition.field) + " " + humanize(condition.operator).toLowerCase() + " " + value;
    });
    var model = rule.model === "all" ? this.config.labels.any_record : humanize(rule.model);
    return model + (parts.length ? " — " + parts.join(" " + this.config.labels.and.toLowerCase() + " ") : "");
  };

  NotificationRuleBuilder.prototype.updateSummary = function (element, rule) {
    element.textContent = this.summary(rule);
  };

  NotificationRuleBuilder.prototype.legacyForRule = function (rule) {
    var tokens = [];
    if (rule.model !== "all") tokens.push(rule.model);
    (rule.conditions || []).forEach(function (condition) {
      var value = condition.value || "";
      if (condition.operator === "starts_with") value += "*";
      if (condition.operator === "ends_with") value = "*" + value;
      if (condition.operator === "contains") value = "*" + value + "*";
      tokens.push(condition.field + ":\"" + value + "\"");
    });
    if (rule.exclude && rule.exclude.own_changes) tokens.push("exclude:mine");
    return tokens.join(" ");
  };

  NotificationRuleBuilder.prototype.sync = function () {
    var legacy = this.state.rules
      .map(this.legacyForRule.bind(this))
      .concat(this.state.legacy_lines || [])
      .join("\n");
    this.hidden.value = legacy;
    this.legacyPreview.value = legacy;
  };

  function initialize() {
    document.querySelectorAll("[data-notification-rule-builder]").forEach(function (root) {
      if (!root.dataset.initialized) {
        root.dataset.initialized = "true";
        new NotificationRuleBuilder(root);
      }
    });
  }

  document.addEventListener("DOMContentLoaded", initialize);
  document.addEventListener("turbo:load", initialize);
  if (window.jQuery) jQuery(initialize);
})();
