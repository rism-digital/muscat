(() => {
  var __create = Object.create;
  var __defProp = Object.defineProperty;
  var __defProps = Object.defineProperties;
  var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
  var __getOwnPropDescs = Object.getOwnPropertyDescriptors;
  var __getOwnPropNames = Object.getOwnPropertyNames;
  var __getOwnPropSymbols = Object.getOwnPropertySymbols;
  var __getProtoOf = Object.getPrototypeOf;
  var __hasOwnProp = Object.prototype.hasOwnProperty;
  var __propIsEnum = Object.prototype.propertyIsEnumerable;
  var __knownSymbol = (name, symbol) => (symbol = Symbol[name]) ? symbol : Symbol.for("Symbol." + name);
  var __typeError = (msg) => {
    throw TypeError(msg);
  };
  var __defNormalProp = (obj, key, value) => key in obj ? __defProp(obj, key, { enumerable: true, configurable: true, writable: true, value }) : obj[key] = value;
  var __spreadValues = (a, b) => {
    for (var prop in b || (b = {}))
      if (__hasOwnProp.call(b, prop))
        __defNormalProp(a, prop, b[prop]);
    if (__getOwnPropSymbols)
      for (var prop of __getOwnPropSymbols(b)) {
        if (__propIsEnum.call(b, prop))
          __defNormalProp(a, prop, b[prop]);
      }
    return a;
  };
  var __spreadProps = (a, b) => __defProps(a, __getOwnPropDescs(b));
  var __commonJS = (cb, mod) => function __require() {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  };
  var __export = (target, all) => {
    for (var name in all)
      __defProp(target, name, { get: all[name], enumerable: true });
  };
  var __copyProps = (to, from, except, desc) => {
    if (from && typeof from === "object" || typeof from === "function") {
      for (let key of __getOwnPropNames(from))
        if (!__hasOwnProp.call(to, key) && key !== except)
          __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
    }
    return to;
  };
  var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
    // If the importer is in node compatibility mode or this is not an ESM
    // file that has been converted to a CommonJS file using a Babel-
    // compatible transform (i.e. "__esModule" has not been set), then set
    // "default" to the CommonJS "module.exports" for node compatibility.
    isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
    mod
  ));
  var __await = function(promise, isYieldStar) {
    this[0] = promise;
    this[1] = isYieldStar;
  };
  var __yieldStar = (value) => {
    var obj = value[__knownSymbol("asyncIterator")], isAwait = false, method, it = {};
    if (obj == null) {
      obj = value[__knownSymbol("iterator")]();
      method = (k) => it[k] = (x) => obj[k](x);
    } else {
      obj = obj.call(value);
      method = (k) => it[k] = (v) => {
        if (isAwait) {
          isAwait = false;
          if (k === "throw") throw v;
          return v;
        }
        isAwait = true;
        return {
          done: false,
          value: new __await(new Promise((resolve) => {
            var x = obj[k](v);
            if (!(x instanceof Object)) __typeError("Object expected");
            resolve(x);
          }), 1)
        };
      };
    }
    return it[__knownSymbol("iterator")] = () => it, method("next"), "throw" in obj ? method("throw") : it.throw = (x) => {
      throw x;
    }, "return" in obj && method("return"), it;
  };

  // node_modules/nearley/lib/nearley.js
  var require_nearley = __commonJS({
    "node_modules/nearley/lib/nearley.js"(exports, module) {
      (function(root, factory) {
        if (typeof module === "object" && module.exports) {
          module.exports = factory();
        } else {
          root.nearley = factory();
        }
      })(exports, function() {
        function Rule(name, symbols, postprocess) {
          this.id = ++Rule.highestId;
          this.name = name;
          this.symbols = symbols;
          this.postprocess = postprocess;
          return this;
        }
        Rule.highestId = 0;
        Rule.prototype.toString = function(withCursorAt) {
          var symbolSequence = typeof withCursorAt === "undefined" ? this.symbols.map(getSymbolShortDisplay).join(" ") : this.symbols.slice(0, withCursorAt).map(getSymbolShortDisplay).join(" ") + " \u25CF " + this.symbols.slice(withCursorAt).map(getSymbolShortDisplay).join(" ");
          return this.name + " \u2192 " + symbolSequence;
        };
        function State(rule, dot, reference, wantedBy) {
          this.rule = rule;
          this.dot = dot;
          this.reference = reference;
          this.data = [];
          this.wantedBy = wantedBy;
          this.isComplete = this.dot === rule.symbols.length;
        }
        State.prototype.toString = function() {
          return "{" + this.rule.toString(this.dot) + "}, from: " + (this.reference || 0);
        };
        State.prototype.nextState = function(child) {
          var state = new State(this.rule, this.dot + 1, this.reference, this.wantedBy);
          state.left = this;
          state.right = child;
          if (state.isComplete) {
            state.data = state.build();
            state.right = void 0;
          }
          return state;
        };
        State.prototype.build = function() {
          var children = [];
          var node = this;
          do {
            children.push(node.right.data);
            node = node.left;
          } while (node.left);
          children.reverse();
          return children;
        };
        State.prototype.finish = function() {
          if (this.rule.postprocess) {
            this.data = this.rule.postprocess(this.data, this.reference, Parser.fail);
          }
        };
        function Column(grammar, index) {
          this.grammar = grammar;
          this.index = index;
          this.states = [];
          this.wants = {};
          this.scannable = [];
          this.completed = {};
        }
        Column.prototype.process = function(nextColumn) {
          var states = this.states;
          var wants = this.wants;
          var completed = this.completed;
          for (var w = 0; w < states.length; w++) {
            var state = states[w];
            if (state.isComplete) {
              state.finish();
              if (state.data !== Parser.fail) {
                var wantedBy = state.wantedBy;
                for (var i = wantedBy.length; i--; ) {
                  var left = wantedBy[i];
                  this.complete(left, state);
                }
                if (state.reference === this.index) {
                  var exp = state.rule.name;
                  (this.completed[exp] = this.completed[exp] || []).push(state);
                }
              }
            } else {
              var exp = state.rule.symbols[state.dot];
              if (typeof exp !== "string") {
                this.scannable.push(state);
                continue;
              }
              if (wants[exp]) {
                wants[exp].push(state);
                if (completed.hasOwnProperty(exp)) {
                  var nulls = completed[exp];
                  for (var i = 0; i < nulls.length; i++) {
                    var right = nulls[i];
                    this.complete(state, right);
                  }
                }
              } else {
                wants[exp] = [state];
                this.predict(exp);
              }
            }
          }
        };
        Column.prototype.predict = function(exp) {
          var rules = this.grammar.byName[exp] || [];
          for (var i = 0; i < rules.length; i++) {
            var r = rules[i];
            var wantedBy = this.wants[exp];
            var s = new State(r, 0, this.index, wantedBy);
            this.states.push(s);
          }
        };
        Column.prototype.complete = function(left, right) {
          var copy = left.nextState(right);
          this.states.push(copy);
        };
        function Grammar(rules, start) {
          this.rules = rules;
          this.start = start || this.rules[0].name;
          var byName = this.byName = {};
          this.rules.forEach(function(rule) {
            if (!byName.hasOwnProperty(rule.name)) {
              byName[rule.name] = [];
            }
            byName[rule.name].push(rule);
          });
        }
        Grammar.fromCompiled = function(rules, start) {
          var lexer = rules.Lexer;
          if (rules.ParserStart) {
            start = rules.ParserStart;
            rules = rules.ParserRules;
          }
          var rules = rules.map(function(r) {
            return new Rule(r.name, r.symbols, r.postprocess);
          });
          var g = new Grammar(rules, start);
          g.lexer = lexer;
          return g;
        };
        function StreamLexer() {
          this.reset("");
        }
        StreamLexer.prototype.reset = function(data2, state) {
          this.buffer = data2;
          this.index = 0;
          this.line = state ? state.line : 1;
          this.lastLineBreak = state ? -state.col : 0;
        };
        StreamLexer.prototype.next = function() {
          if (this.index < this.buffer.length) {
            var ch = this.buffer[this.index++];
            if (ch === "\n") {
              this.line += 1;
              this.lastLineBreak = this.index;
            }
            return { value: ch };
          }
        };
        StreamLexer.prototype.save = function() {
          return {
            line: this.line,
            col: this.index - this.lastLineBreak
          };
        };
        StreamLexer.prototype.formatError = function(token, message) {
          var buffer = this.buffer;
          if (typeof buffer === "string") {
            var lines = buffer.split("\n").slice(
              Math.max(0, this.line - 5),
              this.line
            );
            var nextLineBreak = buffer.indexOf("\n", this.index);
            if (nextLineBreak === -1) nextLineBreak = buffer.length;
            var col = this.index - this.lastLineBreak;
            var lastLineDigits = String(this.line).length;
            message += " at line " + this.line + " col " + col + ":\n\n";
            message += lines.map(function(line, i) {
              return pad2(this.line - lines.length + i + 1, lastLineDigits) + " " + line;
            }, this).join("\n");
            message += "\n" + pad2("", lastLineDigits + col) + "^\n";
            return message;
          } else {
            return message + " at index " + (this.index - 1);
          }
          function pad2(n, length) {
            var s = String(n);
            return Array(length - s.length + 1).join(" ") + s;
          }
        };
        function Parser(rules, start, options) {
          if (rules instanceof Grammar) {
            var grammar = rules;
            var options = start;
          } else {
            var grammar = Grammar.fromCompiled(rules, start);
          }
          this.grammar = grammar;
          this.options = {
            keepHistory: false,
            lexer: grammar.lexer || new StreamLexer()
          };
          for (var key in options || {}) {
            this.options[key] = options[key];
          }
          this.lexer = this.options.lexer;
          this.lexerState = void 0;
          var column = new Column(grammar, 0);
          var table = this.table = [column];
          column.wants[grammar.start] = [];
          column.predict(grammar.start);
          column.process();
          this.current = 0;
        }
        Parser.fail = {};
        Parser.prototype.feed = function(chunk) {
          var lexer = this.lexer;
          lexer.reset(chunk, this.lexerState);
          var token;
          while (true) {
            try {
              token = lexer.next();
              if (!token) {
                break;
              }
            } catch (e) {
              var nextColumn = new Column(this.grammar, this.current + 1);
              this.table.push(nextColumn);
              var err = new Error(this.reportLexerError(e));
              err.offset = this.current;
              err.token = e.token;
              throw err;
            }
            var column = this.table[this.current];
            if (!this.options.keepHistory) {
              delete this.table[this.current - 1];
            }
            var n = this.current + 1;
            var nextColumn = new Column(this.grammar, n);
            this.table.push(nextColumn);
            var literal = token.text !== void 0 ? token.text : token.value;
            var value = lexer.constructor === StreamLexer ? token.value : token;
            var scannable = column.scannable;
            for (var w = scannable.length; w--; ) {
              var state = scannable[w];
              var expect = state.rule.symbols[state.dot];
              if (expect.test ? expect.test(value) : expect.type ? expect.type === token.type : expect.literal === literal) {
                var next = state.nextState({ data: value, token, isToken: true, reference: n - 1 });
                nextColumn.states.push(next);
              }
            }
            nextColumn.process();
            if (nextColumn.states.length === 0) {
              var err = new Error(this.reportError(token));
              err.offset = this.current;
              err.token = token;
              throw err;
            }
            if (this.options.keepHistory) {
              column.lexerState = lexer.save();
            }
            this.current++;
          }
          if (column) {
            this.lexerState = lexer.save();
          }
          this.results = this.finish();
          return this;
        };
        Parser.prototype.reportLexerError = function(lexerError) {
          var tokenDisplay, lexerMessage;
          var token = lexerError.token;
          if (token) {
            tokenDisplay = "input " + JSON.stringify(token.text[0]) + " (lexer error)";
            lexerMessage = this.lexer.formatError(token, "Syntax error");
          } else {
            tokenDisplay = "input (lexer error)";
            lexerMessage = lexerError.message;
          }
          return this.reportErrorCommon(lexerMessage, tokenDisplay);
        };
        Parser.prototype.reportError = function(token) {
          var tokenDisplay = (token.type ? token.type + " token: " : "") + JSON.stringify(token.value !== void 0 ? token.value : token);
          var lexerMessage = this.lexer.formatError(token, "Syntax error");
          return this.reportErrorCommon(lexerMessage, tokenDisplay);
        };
        Parser.prototype.reportErrorCommon = function(lexerMessage, tokenDisplay) {
          var lines = [];
          lines.push(lexerMessage);
          var lastColumnIndex = this.table.length - 2;
          var lastColumn = this.table[lastColumnIndex];
          var expectantStates = lastColumn.states.filter(function(state) {
            var nextSymbol = state.rule.symbols[state.dot];
            return nextSymbol && typeof nextSymbol !== "string";
          });
          if (expectantStates.length === 0) {
            lines.push("Unexpected " + tokenDisplay + ". I did not expect any more input. Here is the state of my parse table:\n");
            this.displayStateStack(lastColumn.states, lines);
          } else {
            lines.push("Unexpected " + tokenDisplay + ". Instead, I was expecting to see one of the following:\n");
            var stateStacks = expectantStates.map(function(state) {
              return this.buildFirstStateStack(state, []) || [state];
            }, this);
            stateStacks.forEach(function(stateStack) {
              var state = stateStack[0];
              var nextSymbol = state.rule.symbols[state.dot];
              var symbolDisplay = this.getSymbolDisplay(nextSymbol);
              lines.push("A " + symbolDisplay + " based on:");
              this.displayStateStack(stateStack, lines);
            }, this);
          }
          lines.push("");
          return lines.join("\n");
        };
        Parser.prototype.displayStateStack = function(stateStack, lines) {
          var lastDisplay;
          var sameDisplayCount = 0;
          for (var j = 0; j < stateStack.length; j++) {
            var state = stateStack[j];
            var display = state.rule.toString(state.dot);
            if (display === lastDisplay) {
              sameDisplayCount++;
            } else {
              if (sameDisplayCount > 0) {
                lines.push("    ^ " + sameDisplayCount + " more lines identical to this");
              }
              sameDisplayCount = 0;
              lines.push("    " + display);
            }
            lastDisplay = display;
          }
        };
        Parser.prototype.getSymbolDisplay = function(symbol) {
          return getSymbolLongDisplay(symbol);
        };
        Parser.prototype.buildFirstStateStack = function(state, visited) {
          if (visited.indexOf(state) !== -1) {
            return null;
          }
          if (state.wantedBy.length === 0) {
            return [state];
          }
          var prevState = state.wantedBy[0];
          var childVisited = [state].concat(visited);
          var childResult = this.buildFirstStateStack(prevState, childVisited);
          if (childResult === null) {
            return null;
          }
          return [state].concat(childResult);
        };
        Parser.prototype.save = function() {
          var column = this.table[this.current];
          column.lexerState = this.lexerState;
          return column;
        };
        Parser.prototype.restore = function(column) {
          var index = column.index;
          this.current = index;
          this.table[index] = column;
          this.table.splice(index + 1);
          this.lexerState = column.lexerState;
          this.results = this.finish();
        };
        Parser.prototype.rewind = function(index) {
          if (!this.options.keepHistory) {
            throw new Error("set option `keepHistory` to enable rewinding");
          }
          this.restore(this.table[index]);
        };
        Parser.prototype.finish = function() {
          var considerations = [];
          var start = this.grammar.start;
          var column = this.table[this.table.length - 1];
          column.states.forEach(function(t) {
            if (t.rule.name === start && t.dot === t.rule.symbols.length && t.reference === 0 && t.data !== Parser.fail) {
              considerations.push(t);
            }
          });
          return considerations.map(function(c) {
            return c.data;
          });
        };
        function getSymbolLongDisplay(symbol) {
          var type = typeof symbol;
          if (type === "string") {
            return symbol;
          } else if (type === "object") {
            if (symbol.literal) {
              return JSON.stringify(symbol.literal);
            } else if (symbol instanceof RegExp) {
              return "character matching " + symbol;
            } else if (symbol.type) {
              return symbol.type + " token";
            } else if (symbol.test) {
              return "token matching " + String(symbol.test);
            } else {
              throw new Error("Unknown symbol type: " + symbol);
            }
          }
        }
        function getSymbolShortDisplay(symbol) {
          var type = typeof symbol;
          if (type === "string") {
            return symbol;
          } else if (type === "object") {
            if (symbol.literal) {
              return JSON.stringify(symbol.literal);
            } else if (symbol instanceof RegExp) {
              return symbol.toString();
            } else if (symbol.type) {
              return "%" + symbol.type;
            } else if (symbol.test) {
              return "<" + String(symbol.test) + ">";
            } else {
              throw new Error("Unknown symbol type: " + symbol);
            }
          }
        }
        return {
          Parser,
          Grammar,
          Rule
        };
      });
    }
  });

  // node_modules/edtf/src/types.js
  var types_exports = {};
  __export(types_exports, {
    Century: () => Century,
    Date: () => Date2,
    Decade: () => Decade,
    Interval: () => Interval,
    List: () => List,
    Season: () => Season,
    Set: () => Set,
    Year: () => Year
  });

  // node_modules/edtf/src/assert.js
  function assert(value, message) {
    return equal(!!value, true, message || `expected "${value}" to be ok`);
  }
  function equal(actual, expected, message) {
    if (actual == expected)
      return true;
    if (Number.isNaN(actual) && Number.isNaN(expected))
      return true;
    throw new Error(message || `expected "${actual}" to equal "${expected}"`);
  }
  assert.equal = equal;
  var assert_default = assert;

  // node_modules/edtf/src/bitmask.js
  var DAY = /^days?$/i;
  var MONTH = /^months?$/i;
  var YEAR = /^years?$/i;
  var SYMBOL = /^[xX]$/;
  var SYMBOLS = /[xX]/g;
  var PATTERN = /^[0-9xXdDmMyY]{8}$/;
  var YYYYMMDD = "YYYYMMDD".split("");
  var MAXDAYS = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  var { floor, pow, max, min } = Math;
  var Bitmask = class _Bitmask {
    static test(a, b) {
      return this.convert(a) & this.convert(b);
    }
    static convert(value = 0) {
      value = value || 0;
      if (value instanceof _Bitmask) return value.value;
      switch (typeof value) {
        case "number":
          return value;
        case "boolean":
          return value ? _Bitmask.YMD : 0;
        case "string":
          if (DAY.test(value)) return _Bitmask.DAY;
          if (MONTH.test(value)) return _Bitmask.MONTH;
          if (YEAR.test(value)) return _Bitmask.YEAR;
          if (PATTERN.test(value)) return _Bitmask.compute(value);
        // fall through!
        default:
          throw new Error(`invalid value: ${value}`);
      }
    }
    static compute(value) {
      return value.split("").reduce((memo, c, idx) => memo | (SYMBOL.test(c) ? pow(2, idx) : 0), 0);
    }
    static values(mask2, digit = 0, normalize2 = true) {
      let num2 = _Bitmask.numbers(mask2, digit).split("");
      let values = [Number(num2.slice(0, 4).join(""))];
      if (num2.length > 4) values.push(Number(num2.slice(4, 6).join("")));
      if (num2.length > 6) values.push(Number(num2.slice(6, 8).join("")));
      return normalize2 ? _Bitmask.normalize(values) : values;
    }
    static numbers(mask2, digit = 0) {
      return mask2.replace(SYMBOLS, digit);
    }
    static normalize(values) {
      if (values.length > 1)
        values[1] = min(11, max(0, values[1] - 1));
      if (values.length > 2)
        values[2] = min(MAXDAYS[values[1]] || NaN, max(1, values[2]));
      return values;
    }
    constructor(value = 0) {
      this.value = _Bitmask.convert(value);
    }
    test(value = 0) {
      return this.value & _Bitmask.convert(value);
    }
    bit(k) {
      return this.value & pow(2, k);
    }
    get day() {
      return this.test(_Bitmask.DAY);
    }
    get month() {
      return this.test(_Bitmask.MONTH);
    }
    get year() {
      return this.test(_Bitmask.YEAR);
    }
    add(value) {
      return this.value = this.value | _Bitmask.convert(value), this;
    }
    set(value = 0) {
      return this.value = _Bitmask.convert(value), this;
    }
    mask(input = YYYYMMDD, offset = 0, symbol = "X") {
      return input.map((c, idx) => this.bit(offset + idx) ? symbol : c);
    }
    masks(values, symbol = "X") {
      let offset = 0;
      return values.map((value) => {
        let mask2 = this.mask(value.split(""), offset, symbol);
        offset = offset + mask2.length;
        return mask2.join("");
      });
    }
    // eslint-disable-next-line complexity
    max([year2, month, day]) {
      if (!year2) return [];
      year2 = Number(
        this.test(_Bitmask.YEAR) ? this.masks([year2], "9")[0] : year2
      );
      if (!month) return [year2];
      month = Number(month) - 1;
      switch (this.test(_Bitmask.MONTH)) {
        case _Bitmask.MONTH:
          month = 11;
          break;
        case _Bitmask.MX:
          month = month < 9 ? 8 : 11;
          break;
        case _Bitmask.XM:
          month = (month + 1) % 10;
          month = month < 3 ? month + 9 : month - 1;
          break;
      }
      if (!day) return [year2, month];
      day = Number(day);
      switch (this.test(_Bitmask.DAY)) {
        case _Bitmask.DAY:
          day = MAXDAYS[month];
          break;
        case _Bitmask.DX:
          day = min(MAXDAYS[month], day + (9 - day % 10));
          break;
        case _Bitmask.XD:
          day = day % 10;
          if (month === 1) {
            day = day === 9 && !leap(year2) ? day + 10 : day + 20;
          } else {
            day = day < 2 ? day + 30 : day + 20;
            if (day > MAXDAYS[month]) day = day - 10;
          }
          break;
      }
      if (month === 1 && day > 28 && !leap(year2)) {
        day = 28;
      }
      return [year2, month, day];
    }
    // eslint-disable-next-line complexity
    min([year2, month, day]) {
      if (!year2) return [];
      year2 = Number(
        this.test(_Bitmask.YEAR) ? this.masks([year2], "0")[0] : year2
      );
      if (month == null) return [year2];
      month = Number(month) - 1;
      switch (this.test(_Bitmask.MONTH)) {
        case _Bitmask.MONTH:
        case _Bitmask.XM:
          month = 0;
          break;
        case _Bitmask.MX:
          month = month < 9 ? 0 : 9;
          break;
      }
      if (!day) return [year2, month];
      day = Number(day);
      switch (this.test(_Bitmask.DAY)) {
        case _Bitmask.DAY:
          day = 1;
          break;
        case _Bitmask.DX:
          day = max(1, floor(day / 10) * 10);
          break;
        case _Bitmask.XD:
          day = max(1, day % 10);
          break;
      }
      return [year2, month, day];
    }
    marks(values, symbol = "?") {
      return values.map((value, idx) => [
        this.qualified(idx * 2) ? symbol : "",
        value,
        this.qualified(idx * 2 + 1) ? symbol : ""
      ].join(""));
    }
    qualified(idx) {
      switch (idx) {
        case 1:
          return this.value === _Bitmask.YEAR || this.value & _Bitmask.YEAR && !(this.value & _Bitmask.MONTH);
        case 2:
          return this.value === _Bitmask.MONTH || this.value & _Bitmask.MONTH && !(this.value & _Bitmask.YEAR);
        case 3:
          return this.value === _Bitmask.YM;
        case 4:
          return this.value === _Bitmask.DAY || this.value & _Bitmask.DAY && this.value !== _Bitmask.YMD;
        case 5:
          return this.value === _Bitmask.YMD;
        default:
          return false;
      }
    }
    qualify(idx) {
      return this.value = this.value | _Bitmask.UA[idx], this;
    }
    toJSON() {
      return this.value;
    }
    toString(symbol = "X") {
      return this.masks(["YYYY", "MM", "DD"], symbol).join("-");
    }
  };
  Bitmask.prototype.is = Bitmask.prototype.test;
  function leap(year2) {
    if (year2 % 4 > 0) return false;
    if (year2 % 100 > 0) return true;
    if (year2 % 400 > 0) return false;
    return true;
  }
  Bitmask.DAY = Bitmask.D = Bitmask.compute("yyyymmxx");
  Bitmask.MONTH = Bitmask.M = Bitmask.compute("yyyyxxdd");
  Bitmask.YEAR = Bitmask.Y = Bitmask.compute("xxxxmmdd");
  Bitmask.MD = Bitmask.M | Bitmask.D;
  Bitmask.YMD = Bitmask.Y | Bitmask.MD;
  Bitmask.YM = Bitmask.Y | Bitmask.M;
  Bitmask.YYXX = Bitmask.compute("yyxxmmdd");
  Bitmask.YYYX = Bitmask.compute("yyyxmmdd");
  Bitmask.XXXX = Bitmask.compute("xxxxmmdd");
  Bitmask.DX = Bitmask.compute("yyyymmdx");
  Bitmask.XD = Bitmask.compute("yyyymmxd");
  Bitmask.MX = Bitmask.compute("yyyymxdd");
  Bitmask.XM = Bitmask.compute("yyyyxmdd");
  Bitmask.UA = [
    Bitmask.YEAR,
    Bitmask.YEAR,
    // YEAR !DAY
    Bitmask.MONTH,
    Bitmask.YM,
    Bitmask.DAY,
    // YEARDAY
    Bitmask.YMD
  ];

  // node_modules/edtf/src/parser.js
  var import_nearley = __toESM(require_nearley(), 1);

  // node_modules/edtf/src/defaults.js
  var defaults = {
    level: 2,
    offset: true,
    types: [],
    seasonIntervals: false,
    seasonUncertainty: false
  };

  // node_modules/edtf/src/util.js
  var { assign } = Object;
  function num(data2) {
    return Number(Array.isArray(data2) ? data2.join("") : data2);
  }
  function join(data2) {
    return data2.join("");
  }
  function zero() {
    return 0;
  }
  function nothing() {
    return null;
  }
  function pick(...args) {
    return args.length === 1 ? (data2) => data2[args[0]] : (data2) => concat(data2, args);
  }
  function pluck(...args) {
    return (data2) => args.map((i) => data2[i]);
  }
  function concat(data2, idx = data2.keys()) {
    return Array.from(idx).reduce((memo, i) => data2[i] !== null ? memo.concat(data2[i]) : memo, []);
  }
  function merge(...args) {
    if (typeof args[args.length - 1] === "object")
      var extra = args.pop();
    return (data2) => assign(args.reduce((a, i) => assign(a, data2[i]), {}), extra);
  }
  function interval(level) {
    return (data2) => ({
      values: [data2[0], data2[2]],
      type: "Interval",
      level
    });
  }
  function masked(type = "unspecified", symbol = "X", normalize2 = true) {
    return (data2, _, reject) => {
      data2 = data2.join("");
      let negative = data2.startsWith("-");
      let mask2 = data2.replace(/-/g, "");
      if (mask2.indexOf(symbol) === -1) return reject;
      let values = Bitmask.values(mask2, 0, normalize2);
      if (negative) values[0] = -values[0];
      return {
        values,
        [type]: Bitmask.compute(mask2)
      };
    };
  }
  function date(values, level = 0, extra = null) {
    return assign({
      type: "Date",
      level,
      values: Bitmask.normalize(values.map(Number))
    }, extra);
  }
  function year(values, level = 1, extra = null) {
    return assign({
      type: "Year",
      level,
      values: values.map(Number)
    }, extra);
  }
  function century(value, level = 0) {
    return {
      type: "Century",
      level,
      values: [value]
    };
  }
  function decade(value, level = 2) {
    return {
      type: "Decade",
      level,
      values: [value]
    };
  }
  function offsetToTimeZone(offset) {
    let sign = offset < 0 ? "-" : "+";
    let abs5 = Math.abs(offset);
    let h = String(Math.floor(abs5 / 60)).padStart(2, "0");
    let m = String(abs5 % 60).padStart(2, "0");
    return `${sign}${h}:${m}`;
  }
  function datetime(data2) {
    let offset = data2[3];
    let values = Bitmask.normalize(data2[0].map(Number)).concat(data2[2]);
    let timeZone;
    if (offset == null && !!defaults.offset) {
      if (typeof defaults.offset === "number") {
        offset = defaults.offset;
      } else {
        offset = -1 * new Date(...values).getTimezoneOffset();
      }
    } else if (offset != null) {
      timeZone = offsetToTimeZone(offset);
    }
    return {
      level: 0,
      offset,
      timeZone,
      type: "Date",
      values
    };
  }
  function season(values, level = 1) {
    return {
      type: "Season",
      level,
      values: values.map(Number)
    };
  }
  function list(data2) {
    return assign({ values: data2[1], level: 2 }, data2[0], data2[2]);
  }
  function qualified(fn, level = 2) {
    return ([parts], _, reject) => {
      let q = {
        uncertain: new Bitmask(),
        approximate: new Bitmask()
      };
      let values = parts.map(([lhs, part, rhs], idx) => {
        for (let ua in lhs) q[ua].qualify(idx * 2);
        for (let ua in rhs) q[ua].qualify(1 + idx * 2);
        return part;
      });
      return !q.uncertain.value && !q.approximate.value ? reject : __spreadProps(__spreadValues({}, fn(values, level)), {
        uncertain: q.uncertain.value,
        approximate: q.approximate.value
      });
    };
  }

  // node_modules/edtf/src/grammar.js
  function id(x) {
    return x[0];
  }
  var {
    DAY: DAY2,
    MONTH: MONTH2,
    YEAR: YEAR2,
    YMD,
    YM,
    MD,
    YYXX,
    YYYX,
    XXXX
  } = Bitmask;
  var Lexer = void 0;
  var ParserRules = [
    { "name": "edtf", "symbols": ["L0"], "postprocess": id },
    { "name": "edtf", "symbols": ["L1"], "postprocess": id },
    { "name": "edtf", "symbols": ["L2"], "postprocess": id },
    { "name": "edtf", "symbols": ["L3"], "postprocess": id },
    { "name": "L0", "symbols": ["date_time"], "postprocess": id },
    { "name": "L0", "symbols": ["century"], "postprocess": id },
    { "name": "L0", "symbols": ["L0i"], "postprocess": id },
    { "name": "L0i", "symbols": ["date_time", { "literal": "/" }, "date_time"], "postprocess": interval(0) },
    { "name": "century", "symbols": ["positive_century"], "postprocess": (data2) => century(data2[0]) },
    { "name": "century$string$1", "symbols": [{ "literal": "0" }, { "literal": "0" }], "postprocess": function joiner(d) {
      return d.join("");
    } },
    { "name": "century", "symbols": ["century$string$1"], "postprocess": (data2) => century(0) },
    { "name": "century", "symbols": [{ "literal": "-" }, "positive_century"], "postprocess": (data2) => century(-data2[1]) },
    { "name": "positive_century", "symbols": ["positive_digit", "digit"], "postprocess": num },
    { "name": "positive_century", "symbols": [{ "literal": "0" }, "positive_digit"], "postprocess": num },
    { "name": "date_time", "symbols": ["date"], "postprocess": id },
    { "name": "date_time", "symbols": ["datetime"], "postprocess": id },
    { "name": "date", "symbols": ["year"], "postprocess": (data2) => date(data2) },
    { "name": "date", "symbols": ["year_month"], "postprocess": (data2) => date(data2[0]) },
    { "name": "date", "symbols": ["year_month_day"], "postprocess": (data2) => date(data2[0]) },
    { "name": "year", "symbols": ["positive_year"], "postprocess": id },
    { "name": "year", "symbols": ["negative_year"], "postprocess": id },
    { "name": "year$string$1", "symbols": [{ "literal": "0" }, { "literal": "0" }, { "literal": "0" }, { "literal": "0" }], "postprocess": function joiner2(d) {
      return d.join("");
    } },
    { "name": "year", "symbols": ["year$string$1"], "postprocess": join },
    { "name": "positive_year", "symbols": ["positive_digit", "digit", "digit", "digit"], "postprocess": join },
    { "name": "positive_year", "symbols": [{ "literal": "0" }, "positive_digit", "digit", "digit"], "postprocess": join },
    { "name": "positive_year$string$1", "symbols": [{ "literal": "0" }, { "literal": "0" }], "postprocess": function joiner3(d) {
      return d.join("");
    } },
    { "name": "positive_year", "symbols": ["positive_year$string$1", "positive_digit", "digit"], "postprocess": join },
    { "name": "positive_year$string$2", "symbols": [{ "literal": "0" }, { "literal": "0" }, { "literal": "0" }], "postprocess": function joiner4(d) {
      return d.join("");
    } },
    { "name": "positive_year", "symbols": ["positive_year$string$2", "positive_digit"], "postprocess": join },
    { "name": "negative_year", "symbols": [{ "literal": "-" }, "positive_year"], "postprocess": join },
    { "name": "year_month", "symbols": ["year", { "literal": "-" }, "month"], "postprocess": pick(0, 2) },
    { "name": "year_month_day", "symbols": ["year", { "literal": "-" }, "month_day"], "postprocess": pick(0, 2) },
    { "name": "month", "symbols": ["d01_12"], "postprocess": id },
    { "name": "month_day", "symbols": ["m31", { "literal": "-" }, "day"], "postprocess": pick(0, 2) },
    { "name": "month_day", "symbols": ["m30", { "literal": "-" }, "d01_30"], "postprocess": pick(0, 2) },
    { "name": "month_day$string$1", "symbols": [{ "literal": "0" }, { "literal": "2" }], "postprocess": function joiner5(d) {
      return d.join("");
    } },
    { "name": "month_day", "symbols": ["month_day$string$1", { "literal": "-" }, "d01_29"], "postprocess": pick(0, 2) },
    { "name": "day", "symbols": ["d01_31"], "postprocess": id },
    { "name": "datetime$ebnf$1$subexpression$1", "symbols": ["timezone"], "postprocess": id },
    { "name": "datetime$ebnf$1", "symbols": ["datetime$ebnf$1$subexpression$1"], "postprocess": id },
    { "name": "datetime$ebnf$1", "symbols": [], "postprocess": function(d) {
      return null;
    } },
    { "name": "datetime", "symbols": ["year_month_day", { "literal": "T" }, "time", "datetime$ebnf$1"], "postprocess": datetime },
    { "name": "time", "symbols": ["hours", { "literal": ":" }, "minutes", { "literal": ":" }, "seconds", "milliseconds"], "postprocess": pick(0, 2, 4, 5) },
    { "name": "time", "symbols": ["hours", { "literal": ":" }, "minutes"], "postprocess": pick(0, 2) },
    { "name": "time$string$1", "symbols": [{ "literal": "2" }, { "literal": "4" }, { "literal": ":" }, { "literal": "0" }, { "literal": "0" }], "postprocess": function joiner6(d) {
      return d.join("");
    } },
    { "name": "time$ebnf$1$string$1", "symbols": [{ "literal": ":" }, { "literal": "0" }, { "literal": "0" }], "postprocess": function joiner7(d) {
      return d.join("");
    } },
    { "name": "time$ebnf$1", "symbols": ["time$ebnf$1$string$1"], "postprocess": id },
    { "name": "time$ebnf$1", "symbols": [], "postprocess": function(d) {
      return null;
    } },
    { "name": "time", "symbols": ["time$string$1", "time$ebnf$1"], "postprocess": () => [24, 0, 0] },
    { "name": "hours", "symbols": ["d00_23"], "postprocess": num },
    { "name": "minutes", "symbols": ["d00_59"], "postprocess": num },
    { "name": "seconds", "symbols": ["d00_59"], "postprocess": num },
    { "name": "milliseconds", "symbols": [] },
    { "name": "milliseconds", "symbols": [{ "literal": "." }, "d3s"], "postprocess": (data2) => num(data2.slice(1)) },
    { "name": "timezone", "symbols": [{ "literal": "Z" }], "postprocess": zero },
    { "name": "timezone$subexpression$1", "symbols": [{ "literal": "-" }] },
    { "name": "timezone$subexpression$1", "symbols": [{ "literal": "\u2212" }] },
    { "name": "timezone", "symbols": ["timezone$subexpression$1", "offset"], "postprocess": (data2) => -data2[1] },
    { "name": "timezone", "symbols": [{ "literal": "+" }, "positive_offset"], "postprocess": pick(1) },
    { "name": "positive_offset", "symbols": ["offset"], "postprocess": id },
    { "name": "positive_offset$string$1", "symbols": [{ "literal": "0" }, { "literal": "0" }], "postprocess": function joiner8(d) {
      return d.join("");
    } },
    { "name": "positive_offset$ebnf$1", "symbols": [{ "literal": ":" }], "postprocess": id },
    { "name": "positive_offset$ebnf$1", "symbols": [], "postprocess": function(d) {
      return null;
    } },
    { "name": "positive_offset$string$2", "symbols": [{ "literal": "0" }, { "literal": "0" }], "postprocess": function joiner9(d) {
      return d.join("");
    } },
    { "name": "positive_offset", "symbols": ["positive_offset$string$1", "positive_offset$ebnf$1", "positive_offset$string$2"], "postprocess": zero },
    { "name": "positive_offset$subexpression$1$string$1", "symbols": [{ "literal": "1" }, { "literal": "2" }], "postprocess": function joiner10(d) {
      return d.join("");
    } },
    { "name": "positive_offset$subexpression$1", "symbols": ["positive_offset$subexpression$1$string$1"] },
    { "name": "positive_offset$subexpression$1$string$2", "symbols": [{ "literal": "1" }, { "literal": "3" }], "postprocess": function joiner11(d) {
      return d.join("");
    } },
    { "name": "positive_offset$subexpression$1", "symbols": ["positive_offset$subexpression$1$string$2"] },
    { "name": "positive_offset$ebnf$2", "symbols": [{ "literal": ":" }], "postprocess": id },
    { "name": "positive_offset$ebnf$2", "symbols": [], "postprocess": function(d) {
      return null;
    } },
    { "name": "positive_offset", "symbols": ["positive_offset$subexpression$1", "positive_offset$ebnf$2", "minutes"], "postprocess": (data2) => num(data2[0]) * 60 + data2[2] },
    { "name": "positive_offset$string$3", "symbols": [{ "literal": "1" }, { "literal": "4" }], "postprocess": function joiner12(d) {
      return d.join("");
    } },
    { "name": "positive_offset$ebnf$3", "symbols": [{ "literal": ":" }], "postprocess": id },
    { "name": "positive_offset$ebnf$3", "symbols": [], "postprocess": function(d) {
      return null;
    } },
    { "name": "positive_offset$string$4", "symbols": [{ "literal": "0" }, { "literal": "0" }], "postprocess": function joiner13(d) {
      return d.join("");
    } },
    { "name": "positive_offset", "symbols": ["positive_offset$string$3", "positive_offset$ebnf$3", "positive_offset$string$4"], "postprocess": () => 840 },
    { "name": "positive_offset", "symbols": ["d00_14"], "postprocess": (data2) => num(data2[0]) * 60 },
    { "name": "offset$ebnf$1", "symbols": [{ "literal": ":" }], "postprocess": id },
    { "name": "offset$ebnf$1", "symbols": [], "postprocess": function(d) {
      return null;
    } },
    { "name": "offset", "symbols": ["d01_11", "offset$ebnf$1", "minutes"], "postprocess": (data2) => num(data2[0]) * 60 + data2[2] },
    { "name": "offset$string$1", "symbols": [{ "literal": "0" }, { "literal": "0" }], "postprocess": function joiner14(d) {
      return d.join("");
    } },
    { "name": "offset$ebnf$2", "symbols": [{ "literal": ":" }], "postprocess": id },
    { "name": "offset$ebnf$2", "symbols": [], "postprocess": function(d) {
      return null;
    } },
    { "name": "offset", "symbols": ["offset$string$1", "offset$ebnf$2", "d01_59"], "postprocess": (data2) => num(data2[2]) },
    { "name": "offset$string$2", "symbols": [{ "literal": "1" }, { "literal": "2" }], "postprocess": function joiner15(d) {
      return d.join("");
    } },
    { "name": "offset$ebnf$3", "symbols": [{ "literal": ":" }], "postprocess": id },
    { "name": "offset$ebnf$3", "symbols": [], "postprocess": function(d) {
      return null;
    } },
    { "name": "offset$string$3", "symbols": [{ "literal": "0" }, { "literal": "0" }], "postprocess": function joiner16(d) {
      return d.join("");
    } },
    { "name": "offset", "symbols": ["offset$string$2", "offset$ebnf$3", "offset$string$3"], "postprocess": () => 720 },
    { "name": "offset", "symbols": ["d01_12"], "postprocess": (data2) => num(data2[0]) * 60 },
    { "name": "L1", "symbols": ["L1d"], "postprocess": id },
    { "name": "L1", "symbols": ["L1Y"], "postprocess": id },
    { "name": "L1", "symbols": ["L1S"], "postprocess": id },
    { "name": "L1", "symbols": ["L1i"], "postprocess": id },
    { "name": "L1d", "symbols": ["date_ua"], "postprocess": id },
    { "name": "L1d", "symbols": ["L1X"], "postprocess": merge(0, { type: "Date", level: 1 }) },
    { "name": "date_ua", "symbols": ["date", "UA"], "postprocess": merge(0, 1, { level: 1 }) },
    { "name": "L1i", "symbols": ["L1i_date", { "literal": "/" }, "L1i_date"], "postprocess": interval(1) },
    { "name": "L1i", "symbols": ["date_time", { "literal": "/" }, "L1i_date"], "postprocess": interval(1) },
    { "name": "L1i", "symbols": ["L1i_date", { "literal": "/" }, "date_time"], "postprocess": interval(1) },
    { "name": "L1i_date", "symbols": [], "postprocess": nothing },
    { "name": "L1i_date", "symbols": ["date_ua"], "postprocess": id },
    { "name": "L1i_date", "symbols": ["INFINITY"], "postprocess": id },
    { "name": "INFINITY$string$1", "symbols": [{ "literal": "." }, { "literal": "." }], "postprocess": function joiner17(d) {
      return d.join("");
    } },
    { "name": "INFINITY", "symbols": ["INFINITY$string$1"], "postprocess": () => Infinity },
    { "name": "L1X$string$1", "symbols": [{ "literal": "-" }, { "literal": "X" }, { "literal": "X" }], "postprocess": function joiner18(d) {
      return d.join("");
    } },
    { "name": "L1X", "symbols": ["nd4", { "literal": "-" }, "md", "L1X$string$1"], "postprocess": masked() },
    { "name": "L1X$string$2", "symbols": [{ "literal": "-" }, { "literal": "X" }, { "literal": "X" }, { "literal": "-" }, { "literal": "X" }, { "literal": "X" }], "postprocess": function joiner19(d) {
      return d.join("");
    } },
    { "name": "L1X", "symbols": ["nd4", "L1X$string$2"], "postprocess": masked() },
    { "name": "L1X$string$3", "symbols": [{ "literal": "X" }, { "literal": "X" }, { "literal": "X" }, { "literal": "X" }, { "literal": "-" }, { "literal": "X" }, { "literal": "X" }, { "literal": "-" }, { "literal": "X" }, { "literal": "X" }], "postprocess": function joiner20(d) {
      return d.join("");
    } },
    { "name": "L1X", "symbols": ["L1X$string$3"], "postprocess": masked() },
    { "name": "L1X$string$4", "symbols": [{ "literal": "-" }, { "literal": "X" }, { "literal": "X" }], "postprocess": function joiner21(d) {
      return d.join("");
    } },
    { "name": "L1X", "symbols": ["nd4", "L1X$string$4"], "postprocess": masked() },
    { "name": "L1X$string$5", "symbols": [{ "literal": "X" }, { "literal": "X" }, { "literal": "X" }, { "literal": "X" }, { "literal": "-" }, { "literal": "X" }, { "literal": "X" }], "postprocess": function joiner22(d) {
      return d.join("");
    } },
    { "name": "L1X", "symbols": ["L1X$string$5"], "postprocess": masked() },
    { "name": "L1X$string$6", "symbols": [{ "literal": "X" }, { "literal": "X" }], "postprocess": function joiner23(d) {
      return d.join("");
    } },
    { "name": "L1X", "symbols": ["nd2", "L1X$string$6"], "postprocess": masked() },
    { "name": "L1X", "symbols": ["nd3", { "literal": "X" }], "postprocess": masked() },
    { "name": "L1X$string$7", "symbols": [{ "literal": "X" }, { "literal": "X" }, { "literal": "X" }, { "literal": "X" }], "postprocess": function joiner24(d) {
      return d.join("");
    } },
    { "name": "L1X", "symbols": ["L1X$string$7"], "postprocess": masked() },
    { "name": "L1Y", "symbols": [{ "literal": "Y" }, "d5+"], "postprocess": (data2) => year([num(data2[1])], 1) },
    { "name": "L1Y$string$1", "symbols": [{ "literal": "Y" }, { "literal": "-" }], "postprocess": function joiner25(d) {
      return d.join("");
    } },
    { "name": "L1Y", "symbols": ["L1Y$string$1", "d5+"], "postprocess": (data2) => year([-num(data2[1])], 1) },
    { "name": "UA", "symbols": [{ "literal": "?" }], "postprocess": () => ({ uncertain: true }) },
    { "name": "UA", "symbols": [{ "literal": "~" }], "postprocess": () => ({ approximate: true }) },
    { "name": "UA", "symbols": [{ "literal": "%" }], "postprocess": () => ({ approximate: true, uncertain: true }) },
    { "name": "L1S", "symbols": ["year", { "literal": "-" }, "d21_24"], "postprocess": (d) => season([d[0], d[2]], 1) },
    { "name": "L2", "symbols": ["L2d"], "postprocess": id },
    { "name": "L2", "symbols": ["L2Y"], "postprocess": id },
    { "name": "L2", "symbols": ["L2S"], "postprocess": id },
    { "name": "L2", "symbols": ["L2D"], "postprocess": id },
    { "name": "L2", "symbols": ["L2C"], "postprocess": id },
    { "name": "L2", "symbols": ["L2i"], "postprocess": id },
    { "name": "L2", "symbols": ["set"], "postprocess": id },
    { "name": "L2", "symbols": ["list"], "postprocess": id },
    { "name": "L2d", "symbols": ["ua_date"], "postprocess": id },
    { "name": "L2d", "symbols": ["L2X"], "postprocess": merge(0, { type: "Date", level: 2 }) },
    { "name": "L2D", "symbols": ["decade"], "postprocess": id },
    { "name": "L2D", "symbols": ["decade", "UA"], "postprocess": merge(0, 1) },
    { "name": "L2C", "symbols": ["century"], "postprocess": id },
    { "name": "L2C", "symbols": ["century", "UA"], "postprocess": merge(0, 1, { level: 2 }) },
    { "name": "ua_date", "symbols": ["ua_year"], "postprocess": qualified(date) },
    { "name": "ua_date", "symbols": ["ua_year_month"], "postprocess": qualified(date) },
    { "name": "ua_date", "symbols": ["ua_year_month_day"], "postprocess": qualified(date) },
    { "name": "ua_year", "symbols": ["UA", "year"], "postprocess": (data2) => [data2] },
    { "name": "ua_year_month$macrocall$2", "symbols": ["year"] },
    { "name": "ua_year_month$macrocall$1$ebnf$1", "symbols": ["UA"], "postprocess": id },
    { "name": "ua_year_month$macrocall$1$ebnf$1", "symbols": [], "postprocess": function(d) {
      return null;
    } },
    { "name": "ua_year_month$macrocall$1$ebnf$2", "symbols": ["UA"], "postprocess": id },
    { "name": "ua_year_month$macrocall$1$ebnf$2", "symbols": [], "postprocess": function(d) {
      return null;
    } },
    { "name": "ua_year_month$macrocall$1", "symbols": ["ua_year_month$macrocall$1$ebnf$1", "ua_year_month$macrocall$2", "ua_year_month$macrocall$1$ebnf$2"] },
    { "name": "ua_year_month$macrocall$4", "symbols": ["month"] },
    { "name": "ua_year_month$macrocall$3$ebnf$1", "symbols": ["UA"], "postprocess": id },
    { "name": "ua_year_month$macrocall$3$ebnf$1", "symbols": [], "postprocess": function(d) {
      return null;
    } },
    { "name": "ua_year_month$macrocall$3$ebnf$2", "symbols": ["UA"], "postprocess": id },
    { "name": "ua_year_month$macrocall$3$ebnf$2", "symbols": [], "postprocess": function(d) {
      return null;
    } },
    { "name": "ua_year_month$macrocall$3", "symbols": ["ua_year_month$macrocall$3$ebnf$1", "ua_year_month$macrocall$4", "ua_year_month$macrocall$3$ebnf$2"] },
    { "name": "ua_year_month", "symbols": ["ua_year_month$macrocall$1", { "literal": "-" }, "ua_year_month$macrocall$3"], "postprocess": pluck(0, 2) },
    { "name": "ua_year_month_day$macrocall$2", "symbols": ["year"] },
    { "name": "ua_year_month_day$macrocall$1$ebnf$1", "symbols": ["UA"], "postprocess": id },
    { "name": "ua_year_month_day$macrocall$1$ebnf$1", "symbols": [], "postprocess": function(d) {
      return null;
    } },
    { "name": "ua_year_month_day$macrocall$1$ebnf$2", "symbols": ["UA"], "postprocess": id },
    { "name": "ua_year_month_day$macrocall$1$ebnf$2", "symbols": [], "postprocess": function(d) {
      return null;
    } },
    { "name": "ua_year_month_day$macrocall$1", "symbols": ["ua_year_month_day$macrocall$1$ebnf$1", "ua_year_month_day$macrocall$2", "ua_year_month_day$macrocall$1$ebnf$2"] },
    { "name": "ua_year_month_day", "symbols": ["ua_year_month_day$macrocall$1", { "literal": "-" }, "ua_month_day"], "postprocess": (data2) => [data2[0], ...data2[2]] },
    { "name": "ua_month_day$macrocall$2", "symbols": ["m31"] },
    { "name": "ua_month_day$macrocall$1$ebnf$1", "symbols": ["UA"], "postprocess": id },
    { "name": "ua_month_day$macrocall$1$ebnf$1", "symbols": [], "postprocess": function(d) {
      return null;
    } },
    { "name": "ua_month_day$macrocall$1$ebnf$2", "symbols": ["UA"], "postprocess": id },
    { "name": "ua_month_day$macrocall$1$ebnf$2", "symbols": [], "postprocess": function(d) {
      return null;
    } },
    { "name": "ua_month_day$macrocall$1", "symbols": ["ua_month_day$macrocall$1$ebnf$1", "ua_month_day$macrocall$2", "ua_month_day$macrocall$1$ebnf$2"] },
    { "name": "ua_month_day$macrocall$4", "symbols": ["day"] },
    { "name": "ua_month_day$macrocall$3$ebnf$1", "symbols": ["UA"], "postprocess": id },
    { "name": "ua_month_day$macrocall$3$ebnf$1", "symbols": [], "postprocess": function(d) {
      return null;
    } },
    { "name": "ua_month_day$macrocall$3$ebnf$2", "symbols": ["UA"], "postprocess": id },
    { "name": "ua_month_day$macrocall$3$ebnf$2", "symbols": [], "postprocess": function(d) {
      return null;
    } },
    { "name": "ua_month_day$macrocall$3", "symbols": ["ua_month_day$macrocall$3$ebnf$1", "ua_month_day$macrocall$4", "ua_month_day$macrocall$3$ebnf$2"] },
    { "name": "ua_month_day", "symbols": ["ua_month_day$macrocall$1", { "literal": "-" }, "ua_month_day$macrocall$3"], "postprocess": pluck(0, 2) },
    { "name": "ua_month_day$macrocall$6", "symbols": ["m30"] },
    { "name": "ua_month_day$macrocall$5$ebnf$1", "symbols": ["UA"], "postprocess": id },
    { "name": "ua_month_day$macrocall$5$ebnf$1", "symbols": [], "postprocess": function(d) {
      return null;
    } },
    { "name": "ua_month_day$macrocall$5$ebnf$2", "symbols": ["UA"], "postprocess": id },
    { "name": "ua_month_day$macrocall$5$ebnf$2", "symbols": [], "postprocess": function(d) {
      return null;
    } },
    { "name": "ua_month_day$macrocall$5", "symbols": ["ua_month_day$macrocall$5$ebnf$1", "ua_month_day$macrocall$6", "ua_month_day$macrocall$5$ebnf$2"] },
    { "name": "ua_month_day$macrocall$8", "symbols": ["d01_30"] },
    { "name": "ua_month_day$macrocall$7$ebnf$1", "symbols": ["UA"], "postprocess": id },
    { "name": "ua_month_day$macrocall$7$ebnf$1", "symbols": [], "postprocess": function(d) {
      return null;
    } },
    { "name": "ua_month_day$macrocall$7$ebnf$2", "symbols": ["UA"], "postprocess": id },
    { "name": "ua_month_day$macrocall$7$ebnf$2", "symbols": [], "postprocess": function(d) {
      return null;
    } },
    { "name": "ua_month_day$macrocall$7", "symbols": ["ua_month_day$macrocall$7$ebnf$1", "ua_month_day$macrocall$8", "ua_month_day$macrocall$7$ebnf$2"] },
    { "name": "ua_month_day", "symbols": ["ua_month_day$macrocall$5", { "literal": "-" }, "ua_month_day$macrocall$7"], "postprocess": pluck(0, 2) },
    { "name": "ua_month_day$macrocall$10$string$1", "symbols": [{ "literal": "0" }, { "literal": "2" }], "postprocess": function joiner26(d) {
      return d.join("");
    } },
    { "name": "ua_month_day$macrocall$10", "symbols": ["ua_month_day$macrocall$10$string$1"] },
    { "name": "ua_month_day$macrocall$9$ebnf$1", "symbols": ["UA"], "postprocess": id },
    { "name": "ua_month_day$macrocall$9$ebnf$1", "symbols": [], "postprocess": function(d) {
      return null;
    } },
    { "name": "ua_month_day$macrocall$9$ebnf$2", "symbols": ["UA"], "postprocess": id },
    { "name": "ua_month_day$macrocall$9$ebnf$2", "symbols": [], "postprocess": function(d) {
      return null;
    } },
    { "name": "ua_month_day$macrocall$9", "symbols": ["ua_month_day$macrocall$9$ebnf$1", "ua_month_day$macrocall$10", "ua_month_day$macrocall$9$ebnf$2"] },
    { "name": "ua_month_day$macrocall$12", "symbols": ["d01_29"] },
    { "name": "ua_month_day$macrocall$11$ebnf$1", "symbols": ["UA"], "postprocess": id },
    { "name": "ua_month_day$macrocall$11$ebnf$1", "symbols": [], "postprocess": function(d) {
      return null;
    } },
    { "name": "ua_month_day$macrocall$11$ebnf$2", "symbols": ["UA"], "postprocess": id },
    { "name": "ua_month_day$macrocall$11$ebnf$2", "symbols": [], "postprocess": function(d) {
      return null;
    } },
    { "name": "ua_month_day$macrocall$11", "symbols": ["ua_month_day$macrocall$11$ebnf$1", "ua_month_day$macrocall$12", "ua_month_day$macrocall$11$ebnf$2"] },
    { "name": "ua_month_day", "symbols": ["ua_month_day$macrocall$9", { "literal": "-" }, "ua_month_day$macrocall$11"], "postprocess": pluck(0, 2) },
    { "name": "L2X", "symbols": ["dx4"], "postprocess": masked() },
    { "name": "L2X", "symbols": ["dx4", { "literal": "-" }, "mx"], "postprocess": masked() },
    { "name": "L2X", "symbols": ["dx4", { "literal": "-" }, "mdx"], "postprocess": masked() },
    { "name": "mdx", "symbols": ["m31x", { "literal": "-" }, "d31x"], "postprocess": join },
    { "name": "mdx", "symbols": ["m30x", { "literal": "-" }, "d30x"], "postprocess": join },
    { "name": "mdx$string$1", "symbols": [{ "literal": "0" }, { "literal": "2" }, { "literal": "-" }], "postprocess": function joiner27(d) {
      return d.join("");
    } },
    { "name": "mdx", "symbols": ["mdx$string$1", "d29x"], "postprocess": join },
    { "name": "L2i", "symbols": ["L2i_date", { "literal": "/" }, "L2i_date"], "postprocess": interval(2) },
    { "name": "L2i", "symbols": ["date_time", { "literal": "/" }, "L2i_date"], "postprocess": interval(2) },
    { "name": "L2i", "symbols": ["L2i_date", { "literal": "/" }, "date_time"], "postprocess": interval(2) },
    { "name": "L2i_date", "symbols": [], "postprocess": nothing },
    { "name": "L2i_date", "symbols": ["ua_date"], "postprocess": id },
    { "name": "L2i_date", "symbols": ["L2X"], "postprocess": id },
    { "name": "L2i_date", "symbols": ["INFINITY"], "postprocess": id },
    { "name": "L2Y", "symbols": ["exp_year"], "postprocess": id },
    { "name": "L2Y", "symbols": ["exp_year", "significant_digits"], "postprocess": merge(0, 1) },
    { "name": "L2Y", "symbols": ["L1Y", "significant_digits"], "postprocess": merge(0, 1, { level: 2 }) },
    { "name": "L2Y", "symbols": ["year", "significant_digits"], "postprocess": (data2) => year([data2[0]], 2, data2[1]) },
    { "name": "significant_digits", "symbols": [{ "literal": "S" }, "positive_digit"], "postprocess": (data2) => ({ significant: num(data2[1]) }) },
    { "name": "exp_year", "symbols": [{ "literal": "Y" }, "exp"], "postprocess": (data2) => year([data2[1]], 2) },
    { "name": "exp_year$string$1", "symbols": [{ "literal": "Y" }, { "literal": "-" }], "postprocess": function joiner28(d) {
      return d.join("");
    } },
    { "name": "exp_year", "symbols": ["exp_year$string$1", "exp"], "postprocess": (data2) => year([-data2[1]], 2) },
    { "name": "exp", "symbols": ["digits", { "literal": "E" }, "digits"], "postprocess": (data2) => num(data2[0]) * Math.pow(10, num(data2[2])) },
    { "name": "L2S", "symbols": ["year", { "literal": "-" }, "d25_41"], "postprocess": (d) => season([d[0], d[2]], 2) },
    { "name": "decade", "symbols": ["positive_decade"], "postprocess": (data2) => decade(data2[0]) },
    { "name": "decade$string$1", "symbols": [{ "literal": "0" }, { "literal": "0" }, { "literal": "0" }], "postprocess": function joiner29(d) {
      return d.join("");
    } },
    { "name": "decade", "symbols": ["decade$string$1"], "postprocess": () => decade(0) },
    { "name": "decade", "symbols": [{ "literal": "-" }, "positive_decade"], "postprocess": (data2) => decade(-data2[1]) },
    { "name": "positive_decade", "symbols": ["positive_digit", "digit", "digit"], "postprocess": num },
    { "name": "positive_decade", "symbols": [{ "literal": "0" }, "positive_digit", "digit"], "postprocess": num },
    { "name": "positive_decade$string$1", "symbols": [{ "literal": "0" }, { "literal": "0" }], "postprocess": function joiner30(d) {
      return d.join("");
    } },
    { "name": "positive_decade", "symbols": ["positive_decade$string$1", "positive_digit"], "postprocess": num },
    { "name": "set", "symbols": ["LSB", "OL", "RSB"], "postprocess": list },
    { "name": "list", "symbols": ["LLB", "OL", "RLB"], "postprocess": list },
    { "name": "LSB", "symbols": [{ "literal": "[" }], "postprocess": () => ({ type: "Set" }) },
    { "name": "LSB$string$1", "symbols": [{ "literal": "[" }, { "literal": "." }, { "literal": "." }], "postprocess": function joiner31(d) {
      return d.join("");
    } },
    { "name": "LSB", "symbols": ["LSB$string$1"], "postprocess": () => ({ type: "Set", earlier: true }) },
    { "name": "LLB", "symbols": [{ "literal": "{" }], "postprocess": () => ({ type: "List" }) },
    { "name": "LLB$string$1", "symbols": [{ "literal": "{" }, { "literal": "." }, { "literal": "." }], "postprocess": function joiner32(d) {
      return d.join("");
    } },
    { "name": "LLB", "symbols": ["LLB$string$1"], "postprocess": () => ({ type: "List", earlier: true }) },
    { "name": "RSB", "symbols": [{ "literal": "]" }], "postprocess": nothing },
    { "name": "RSB$string$1", "symbols": [{ "literal": "." }, { "literal": "." }, { "literal": "]" }], "postprocess": function joiner33(d) {
      return d.join("");
    } },
    { "name": "RSB", "symbols": ["RSB$string$1"], "postprocess": () => ({ later: true }) },
    { "name": "RLB", "symbols": [{ "literal": "}" }], "postprocess": nothing },
    { "name": "RLB$string$1", "symbols": [{ "literal": "." }, { "literal": "." }, { "literal": "}" }], "postprocess": function joiner34(d) {
      return d.join("");
    } },
    { "name": "RLB", "symbols": ["RLB$string$1"], "postprocess": () => ({ later: true }) },
    { "name": "OL", "symbols": ["LI"], "postprocess": (data2) => [data2[0]] },
    { "name": "OL", "symbols": ["OL", "_", { "literal": "," }, "_", "LI"], "postprocess": (data2) => [...data2[0], data2[4]] },
    { "name": "LI", "symbols": ["date"], "postprocess": id },
    { "name": "LI", "symbols": ["ua_date"], "postprocess": id },
    { "name": "LI", "symbols": ["L2X"], "postprocess": id },
    { "name": "LI", "symbols": ["consecutives"], "postprocess": id },
    { "name": "consecutives$string$1", "symbols": [{ "literal": "." }, { "literal": "." }], "postprocess": function joiner35(d) {
      return d.join("");
    } },
    { "name": "consecutives", "symbols": ["year_month_day", "consecutives$string$1", "year_month_day"], "postprocess": (d) => [date(d[0]), date(d[2])] },
    { "name": "consecutives$string$2", "symbols": [{ "literal": "." }, { "literal": "." }], "postprocess": function joiner36(d) {
      return d.join("");
    } },
    { "name": "consecutives", "symbols": ["year_month", "consecutives$string$2", "year_month"], "postprocess": (d) => [date(d[0]), date(d[2])] },
    { "name": "consecutives$string$3", "symbols": [{ "literal": "." }, { "literal": "." }], "postprocess": function joiner37(d) {
      return d.join("");
    } },
    { "name": "consecutives", "symbols": ["year", "consecutives$string$3", "year"], "postprocess": (d) => [date([d[0]]), date([d[2]])] },
    { "name": "L3", "symbols": ["L3i"], "postprocess": id },
    { "name": "L3", "symbols": ["L3S"], "postprocess": id },
    { "name": "L3i", "symbols": ["L3s", { "literal": "/" }, "L3s"], "postprocess": interval(3) },
    { "name": "L3s", "symbols": ["L1S"], "postprocess": id },
    { "name": "L3s", "symbols": ["L2S"], "postprocess": id },
    { "name": "L3s", "symbols": ["L3S"], "postprocess": id },
    { "name": "L3S", "symbols": ["ua_season"], "postprocess": qualified(season, 3) },
    { "name": "L3S", "symbols": ["xx_season"], "postprocess": merge(0, { type: "Season", level: 3 }) },
    { "name": "ua_season$macrocall$2", "symbols": ["year"] },
    { "name": "ua_season$macrocall$1$ebnf$1", "symbols": ["UA"], "postprocess": id },
    { "name": "ua_season$macrocall$1$ebnf$1", "symbols": [], "postprocess": function(d) {
      return null;
    } },
    { "name": "ua_season$macrocall$1$ebnf$2", "symbols": ["UA"], "postprocess": id },
    { "name": "ua_season$macrocall$1$ebnf$2", "symbols": [], "postprocess": function(d) {
      return null;
    } },
    { "name": "ua_season$macrocall$1", "symbols": ["ua_season$macrocall$1$ebnf$1", "ua_season$macrocall$2", "ua_season$macrocall$1$ebnf$2"] },
    { "name": "ua_season$macrocall$4", "symbols": ["d21_41"] },
    { "name": "ua_season$macrocall$3$ebnf$1", "symbols": ["UA"], "postprocess": id },
    { "name": "ua_season$macrocall$3$ebnf$1", "symbols": [], "postprocess": function(d) {
      return null;
    } },
    { "name": "ua_season$macrocall$3$ebnf$2", "symbols": ["UA"], "postprocess": id },
    { "name": "ua_season$macrocall$3$ebnf$2", "symbols": [], "postprocess": function(d) {
      return null;
    } },
    { "name": "ua_season$macrocall$3", "symbols": ["ua_season$macrocall$3$ebnf$1", "ua_season$macrocall$4", "ua_season$macrocall$3$ebnf$2"] },
    { "name": "ua_season", "symbols": ["ua_season$macrocall$1", { "literal": "-" }, "ua_season$macrocall$3"], "postprocess": pluck(0, 2) },
    { "name": "xx_season", "symbols": ["dx4", { "literal": "-" }, "d21_41"], "postprocess": masked("unspecified", "X", false) },
    { "name": "digit", "symbols": ["positive_digit"], "postprocess": id },
    { "name": "digit", "symbols": [{ "literal": "0" }], "postprocess": id },
    { "name": "digits", "symbols": ["digit"], "postprocess": id },
    { "name": "digits", "symbols": ["digits", "digit"], "postprocess": join },
    { "name": "nd4", "symbols": ["d4"] },
    { "name": "nd4", "symbols": [{ "literal": "-" }, "d4"], "postprocess": join },
    { "name": "nd3", "symbols": ["d3"] },
    { "name": "nd3", "symbols": [{ "literal": "-" }, "d3"], "postprocess": join },
    { "name": "nd2", "symbols": ["d2"] },
    { "name": "nd2", "symbols": [{ "literal": "-" }, "d2"], "postprocess": join },
    { "name": "d4", "symbols": ["d2", "d2"], "postprocess": join },
    { "name": "d3", "symbols": ["d2", "digit"], "postprocess": join },
    { "name": "d2", "symbols": ["digit", "digit"], "postprocess": join },
    { "name": "d3s", "symbols": ["digit"], "postprocess": id },
    { "name": "d3s", "symbols": ["d2"], "postprocess": id },
    { "name": "d3s", "symbols": ["d3"], "postprocess": id },
    { "name": "d3s", "symbols": ["d3", "digits"], "postprocess": pick(0) },
    { "name": "d5+", "symbols": ["positive_digit", "d3", "digits"], "postprocess": num },
    { "name": "d1x", "symbols": [/[1-9X]/], "postprocess": id },
    { "name": "dx", "symbols": ["d1x"], "postprocess": id },
    { "name": "dx", "symbols": [{ "literal": "0" }], "postprocess": id },
    { "name": "dx2", "symbols": ["dx", "dx"], "postprocess": join },
    { "name": "dx4", "symbols": ["dx2", "dx2"], "postprocess": join },
    { "name": "dx4", "symbols": [{ "literal": "-" }, "dx2", "dx2"], "postprocess": join },
    { "name": "md", "symbols": ["m31"], "postprocess": id },
    { "name": "md", "symbols": ["m30"], "postprocess": id },
    { "name": "md$string$1", "symbols": [{ "literal": "0" }, { "literal": "2" }], "postprocess": function joiner38(d) {
      return d.join("");
    } },
    { "name": "md", "symbols": ["md$string$1"], "postprocess": id },
    { "name": "mx", "symbols": [{ "literal": "0" }, "d1x"], "postprocess": join },
    { "name": "mx", "symbols": [/[1X]/, /[012X]/], "postprocess": join },
    { "name": "m31x", "symbols": [/[0X]/, /[13578X]/], "postprocess": join },
    { "name": "m31x", "symbols": [/[1X]/, /[02]/], "postprocess": join },
    { "name": "m31x$string$1", "symbols": [{ "literal": "1" }, { "literal": "X" }], "postprocess": function joiner39(d) {
      return d.join("");
    } },
    { "name": "m31x", "symbols": ["m31x$string$1"], "postprocess": id },
    { "name": "m30x", "symbols": [/[0X]/, /[469]/], "postprocess": join },
    { "name": "m30x$string$1", "symbols": [{ "literal": "1" }, { "literal": "1" }], "postprocess": function joiner40(d) {
      return d.join("");
    } },
    { "name": "m30x", "symbols": ["m30x$string$1"], "postprocess": join },
    { "name": "d29x", "symbols": [{ "literal": "0" }, "d1x"], "postprocess": join },
    { "name": "d29x", "symbols": [/[1-2X]/, "dx"], "postprocess": join },
    { "name": "d30x", "symbols": ["d29x"], "postprocess": join },
    { "name": "d30x$string$1", "symbols": [{ "literal": "3" }, { "literal": "0" }], "postprocess": function joiner41(d) {
      return d.join("");
    } },
    { "name": "d30x", "symbols": ["d30x$string$1"], "postprocess": id },
    { "name": "d31x", "symbols": ["d30x"], "postprocess": id },
    { "name": "d31x", "symbols": [{ "literal": "3" }, /[1X]/], "postprocess": join },
    { "name": "positive_digit", "symbols": [/[1-9]/], "postprocess": id },
    { "name": "m31$subexpression$1$string$1", "symbols": [{ "literal": "0" }, { "literal": "1" }], "postprocess": function joiner42(d) {
      return d.join("");
    } },
    { "name": "m31$subexpression$1", "symbols": ["m31$subexpression$1$string$1"] },
    { "name": "m31$subexpression$1$string$2", "symbols": [{ "literal": "0" }, { "literal": "3" }], "postprocess": function joiner43(d) {
      return d.join("");
    } },
    { "name": "m31$subexpression$1", "symbols": ["m31$subexpression$1$string$2"] },
    { "name": "m31$subexpression$1$string$3", "symbols": [{ "literal": "0" }, { "literal": "5" }], "postprocess": function joiner44(d) {
      return d.join("");
    } },
    { "name": "m31$subexpression$1", "symbols": ["m31$subexpression$1$string$3"] },
    { "name": "m31$subexpression$1$string$4", "symbols": [{ "literal": "0" }, { "literal": "7" }], "postprocess": function joiner45(d) {
      return d.join("");
    } },
    { "name": "m31$subexpression$1", "symbols": ["m31$subexpression$1$string$4"] },
    { "name": "m31$subexpression$1$string$5", "symbols": [{ "literal": "0" }, { "literal": "8" }], "postprocess": function joiner46(d) {
      return d.join("");
    } },
    { "name": "m31$subexpression$1", "symbols": ["m31$subexpression$1$string$5"] },
    { "name": "m31$subexpression$1$string$6", "symbols": [{ "literal": "1" }, { "literal": "0" }], "postprocess": function joiner47(d) {
      return d.join("");
    } },
    { "name": "m31$subexpression$1", "symbols": ["m31$subexpression$1$string$6"] },
    { "name": "m31$subexpression$1$string$7", "symbols": [{ "literal": "1" }, { "literal": "2" }], "postprocess": function joiner48(d) {
      return d.join("");
    } },
    { "name": "m31$subexpression$1", "symbols": ["m31$subexpression$1$string$7"] },
    { "name": "m31", "symbols": ["m31$subexpression$1"], "postprocess": id },
    { "name": "m30$subexpression$1$string$1", "symbols": [{ "literal": "0" }, { "literal": "4" }], "postprocess": function joiner49(d) {
      return d.join("");
    } },
    { "name": "m30$subexpression$1", "symbols": ["m30$subexpression$1$string$1"] },
    { "name": "m30$subexpression$1$string$2", "symbols": [{ "literal": "0" }, { "literal": "6" }], "postprocess": function joiner50(d) {
      return d.join("");
    } },
    { "name": "m30$subexpression$1", "symbols": ["m30$subexpression$1$string$2"] },
    { "name": "m30$subexpression$1$string$3", "symbols": [{ "literal": "0" }, { "literal": "9" }], "postprocess": function joiner51(d) {
      return d.join("");
    } },
    { "name": "m30$subexpression$1", "symbols": ["m30$subexpression$1$string$3"] },
    { "name": "m30$subexpression$1$string$4", "symbols": [{ "literal": "1" }, { "literal": "1" }], "postprocess": function joiner52(d) {
      return d.join("");
    } },
    { "name": "m30$subexpression$1", "symbols": ["m30$subexpression$1$string$4"] },
    { "name": "m30", "symbols": ["m30$subexpression$1"], "postprocess": id },
    { "name": "d01_11", "symbols": [{ "literal": "0" }, "positive_digit"], "postprocess": join },
    { "name": "d01_11", "symbols": [{ "literal": "1" }, /[0-1]/], "postprocess": join },
    { "name": "d01_12", "symbols": ["d01_11"], "postprocess": id },
    { "name": "d01_12$string$1", "symbols": [{ "literal": "1" }, { "literal": "2" }], "postprocess": function joiner53(d) {
      return d.join("");
    } },
    { "name": "d01_12", "symbols": ["d01_12$string$1"], "postprocess": id },
    { "name": "d01_13", "symbols": ["d01_12"], "postprocess": id },
    { "name": "d01_13$string$1", "symbols": [{ "literal": "1" }, { "literal": "3" }], "postprocess": function joiner54(d) {
      return d.join("");
    } },
    { "name": "d01_13", "symbols": ["d01_13$string$1"], "postprocess": id },
    { "name": "d00_14$string$1", "symbols": [{ "literal": "0" }, { "literal": "0" }], "postprocess": function joiner55(d) {
      return d.join("");
    } },
    { "name": "d00_14", "symbols": ["d00_14$string$1"], "postprocess": id },
    { "name": "d00_14", "symbols": ["d01_13"], "postprocess": id },
    { "name": "d00_14$string$2", "symbols": [{ "literal": "1" }, { "literal": "4" }], "postprocess": function joiner56(d) {
      return d.join("");
    } },
    { "name": "d00_14", "symbols": ["d00_14$string$2"], "postprocess": id },
    { "name": "d00_23$string$1", "symbols": [{ "literal": "0" }, { "literal": "0" }], "postprocess": function joiner57(d) {
      return d.join("");
    } },
    { "name": "d00_23", "symbols": ["d00_23$string$1"], "postprocess": id },
    { "name": "d00_23", "symbols": ["d01_23"], "postprocess": id },
    { "name": "d01_23", "symbols": [{ "literal": "0" }, "positive_digit"], "postprocess": join },
    { "name": "d01_23", "symbols": [{ "literal": "1" }, "digit"], "postprocess": join },
    { "name": "d01_23", "symbols": [{ "literal": "2" }, /[0-3]/], "postprocess": join },
    { "name": "d01_29", "symbols": [{ "literal": "0" }, "positive_digit"], "postprocess": join },
    { "name": "d01_29", "symbols": [/[1-2]/, "digit"], "postprocess": join },
    { "name": "d01_30", "symbols": ["d01_29"], "postprocess": id },
    { "name": "d01_30$string$1", "symbols": [{ "literal": "3" }, { "literal": "0" }], "postprocess": function joiner58(d) {
      return d.join("");
    } },
    { "name": "d01_30", "symbols": ["d01_30$string$1"], "postprocess": id },
    { "name": "d01_31", "symbols": ["d01_30"], "postprocess": id },
    { "name": "d01_31$string$1", "symbols": [{ "literal": "3" }, { "literal": "1" }], "postprocess": function joiner59(d) {
      return d.join("");
    } },
    { "name": "d01_31", "symbols": ["d01_31$string$1"], "postprocess": id },
    { "name": "d00_59$string$1", "symbols": [{ "literal": "0" }, { "literal": "0" }], "postprocess": function joiner60(d) {
      return d.join("");
    } },
    { "name": "d00_59", "symbols": ["d00_59$string$1"], "postprocess": id },
    { "name": "d00_59", "symbols": ["d01_59"], "postprocess": id },
    { "name": "d01_59", "symbols": ["d01_29"], "postprocess": id },
    { "name": "d01_59", "symbols": [/[345]/, "digit"], "postprocess": join },
    { "name": "d21_24", "symbols": [{ "literal": "2" }, /[1-4]/], "postprocess": join },
    { "name": "d25_41", "symbols": [{ "literal": "2" }, /[5-9]/], "postprocess": join },
    { "name": "d25_41", "symbols": [{ "literal": "3" }, "digit"], "postprocess": join },
    { "name": "d25_41", "symbols": [{ "literal": "4" }, /[01]/], "postprocess": join },
    { "name": "d21_41", "symbols": ["d21_24"], "postprocess": id },
    { "name": "d21_41", "symbols": ["d25_41"], "postprocess": id },
    { "name": "_$ebnf$1", "symbols": [] },
    { "name": "_$ebnf$1", "symbols": ["_$ebnf$1", { "literal": " " }], "postprocess": function arrpush(d) {
      return d[0].concat([d[1]]);
    } },
    { "name": "_", "symbols": ["_$ebnf$1"] }
  ];
  var ParserStart = "edtf";
  var grammar_default = { Lexer, ParserRules, ParserStart };

  // node_modules/edtf/src/parser.js
  function byLevel(a, b) {
    return a.level < b.level ? -1 : a.level > b.level ? 1 : 0;
  }
  function limit(results, constraints = {}) {
    if (!results.length) return results;
    let {
      level,
      types,
      seasonIntervals,
      seasonUncertainty
    } = __spreadValues(__spreadValues({}, defaults), constraints);
    return results.filter((res) => {
      if (seasonIntervals && isSeasonInterval(res))
        return true;
      if (seasonUncertainty && isSeasonLevel3(res))
        return true;
      if (res.level > level)
        return false;
      if (types.length && !types.includes(res.type))
        return false;
      return true;
    });
  }
  function isSeasonInterval({ type, values }) {
    return type === "Interval" && values[0].type === "Season";
  }
  function isSeasonLevel3({ type, level }) {
    return type === "Season" && level >= 3;
  }
  function best(results) {
    if (results.length < 2) return results[0];
    return results.sort(byLevel)[0];
  }
  function parse(input, constraints = {}) {
    try {
      let nep = parser();
      let res = best(limit(nep.feed(input).results, constraints));
      if (!res) throw new Error("edtf: No possible parsings (@EOS)");
      return res;
    } catch (error) {
      error.message += ` for "${input}"`;
      throw error;
    }
  }
  function parser() {
    return new import_nearley.default.Parser(grammar_default.ParserRules, grammar_default.ParserStart);
  }

  // node_modules/edtf/src/interface.js
  var ExtDateTime = class {
    static get type() {
      return this.name;
    }
    static parse(input) {
      return parse(input, { types: [this.type] });
    }
    static from(input) {
      return input instanceof this ? input : new this(input);
    }
    static UTC(...args) {
      let time = Date.UTC(...args);
      if (args[0] >= 0 && args[0] < 100)
        time = adj(new Date(time));
      return time;
    }
    get type() {
      return this.constructor.type;
    }
    get edtf() {
      return this.toEDTF();
    }
    get isEDTF() {
      return true;
    }
    toJSON() {
      return this.toEDTF();
    }
    toString() {
      return this.toEDTF();
    }
    toLocaleString(...args) {
      return this.localize(...args);
    }
    inspect() {
      return this.toEDTF();
    }
    valueOf() {
      return this.min;
    }
    [Symbol.toPrimitive](hint) {
      return hint === "number" ? this.valueOf() : this.toEDTF();
    }
    covers(other) {
      return this.min <= other.min && this.max >= other.max;
    }
    compare(other) {
      if (other.min == null || other.max == null) return null;
      let [a, x, b, y] = [this.min, this.max, other.min, other.max];
      if (a !== b)
        return a < b ? -1 : 1;
      if (x !== y)
        return x < y ? -1 : 1;
      return 0;
    }
    includes(other) {
      let covered = this.covers(other);
      if (!covered || !this[Symbol.iterator]) return covered;
      for (let cur of this) {
        if (cur.edtf === other.edtf) return true;
      }
      return false;
    }
    *until(then) {
      yield this;
      if (this.compare(then)) yield* __yieldStar(this.between(then));
    }
    *through(then) {
      yield* __yieldStar(this.until(then));
      if (this.compare(then)) yield then;
    }
    *between(then) {
      then = this.constructor.from(then);
      let cur = this;
      let dir = this.compare(then);
      if (!dir) return;
      for (; ; ) {
        cur = cur.next(-dir);
        if (cur.compare(then) !== dir) break;
        yield cur;
      }
    }
  };
  function adj(date2, by = 1900) {
    date2.setUTCFullYear(date2.getUTCFullYear() - by);
    return date2.getTime();
  }

  // node_modules/edtf/src/mixin.js
  var keys = Reflect.ownKeys.bind(Reflect);
  var descriptor = Object.getOwnPropertyDescriptor.bind(Object);
  var define = Object.defineProperty.bind(Object);
  var has = Object.prototype.hasOwnProperty;
  function mixin(target, ...mixins) {
    for (let source of mixins) {
      inherit(target, source);
      inherit(target.prototype, source.prototype);
    }
    return target;
  }
  function inherit(target, source) {
    for (let key of keys(source)) {
      if (!has.call(target, key)) {
        define(target, key, descriptor(source, key));
      }
    }
  }

  // node_modules/edtf/locale-data/en-US.json
  var en_US_default = {
    locale: "en-US",
    date: {
      approximate: {
        long: "circa %D",
        medium: "ca. %D",
        short: "c. %D"
      },
      uncertain: {
        long: "%D (unspecified)",
        medium: "%D (?)",
        short: "%D (?)"
      }
    }
  };

  // node_modules/edtf/locale-data/es-ES.json
  var es_ES_default = {
    locale: "es-ES",
    date: {
      approximate: {
        long: "circa %D",
        medium: "ca. %D",
        short: "c. %D"
      },
      uncertain: {
        long: "%D (?)",
        medium: "%D (?)",
        short: "%D (?)"
      }
    }
  };

  // node_modules/edtf/locale-data/de-DE.json
  var de_DE_default = {
    locale: "de-DE",
    date: {
      approximate: {
        long: "circa %D",
        medium: "ca. %D",
        short: "ca. %D"
      },
      uncertain: {
        long: "%D (?)",
        medium: "%D (?)",
        short: "%D (?)"
      }
    }
  };

  // node_modules/edtf/locale-data/fr-FR.json
  var fr_FR_default = {
    locale: "fr-FR",
    date: {
      approximate: {
        long: "circa %D",
        medium: "ca. %D",
        short: "c. %D"
      },
      uncertain: {
        long: "%D (?)",
        medium: "%D (?)",
        short: "%D (?)"
      }
    }
  };

  // node_modules/edtf/locale-data/it-IT.json
  var it_IT_default = {
    locale: "it-IT",
    date: {
      approximate: {
        long: "circa %D",
        medium: "ca. %D",
        short: "c. %D"
      },
      uncertain: {
        long: "%D (?)",
        medium: "%D (?)",
        short: "%D (?)"
      }
    }
  };

  // node_modules/edtf/locale-data/ja-JA.json
  var ja_JA_default = {
    locale: "ja-JA",
    date: {
      approximate: {
        long: "%D\u9803",
        medium: "%D\u9803",
        short: "%D\u9803"
      },
      uncertain: {
        long: "%D\u9803",
        medium: "%D\u9803",
        short: "%D\u9803"
      }
    }
  };

  // node_modules/edtf/locale-data/index.js
  var data = { en: en_US_default, es: es_ES_default, de: de_DE_default, fr: fr_FR_default, it: it_IT_default, ja: ja_JA_default };
  var alias = (lang, ...regions) => {
    for (let region of regions)
      data[`${lang}-${region}`] = data[lang];
  };
  alias("en", "AU", "CA", "GB", "NZ", "SA", "US");
  alias("de", "AT", "CH", "DE");
  alias("fr", "CH", "FR");
  var locale_data_default = data;

  // node_modules/edtf/src/format.js
  var DEFAULTS = [
    {
      day: "numeric",
      month: "numeric",
      year: "numeric",
      timeZoneName: void 0,
      hour: "numeric",
      minute: "numeric",
      second: "numeric"
    },
    {
      year: "numeric",
      timeZone: "UTC",
      timeZoneName: void 0
    },
    {
      month: "numeric",
      year: "numeric",
      timeZone: "UTC",
      timeZoneName: void 0
    },
    {
      day: "numeric",
      month: "numeric",
      year: "numeric",
      timeZone: "UTC",
      timeZoneName: void 0
    }
  ];
  function configure(level, options) {
    options = __spreadValues(__spreadValues({}, DEFAULTS[level]), options);
    switch (level) {
      case 1:
        options.month = void 0;
      // eslint-disable-next-line no-fallthrough
      case 2:
        options.day = void 0;
        options.weekday = void 0;
      // eslint-disable-next-line no-fallthrough
      case 3:
        options.hour = void 0;
        options.minute = void 0;
        options.second = void 0;
    }
    return options;
  }
  function getCacheId(locale, options) {
    return `${locale}:${JSON.stringify(normalize(options))}`;
  }
  function normalize(obj) {
    return Object.fromEntries(
      Object.entries(obj).filter(([, b]) => b != null).sort(([a], [b]) => a.localeCompare(b))
    );
  }
  function getFormat(date2, locale, options) {
    let opts = configure(date2.precision, options);
    let id2 = getCacheId(locale, opts);
    if (!format.cache.has(id2)) {
      if (format.cache.size >= 64)
        format.cache.clear();
      format.cache.set(id2, new Intl.DateTimeFormat(locale, opts));
    }
    return format.cache.get(id2);
  }
  function getPatternsFor(fmt) {
    const { locale, weekday, month, year: year2 } = fmt.resolvedOptions();
    const lc = locale_data_default[locale];
    if (lc == null) return null;
    const variant = weekday || month === "long" ? "long" : !month || year2 === "2-digit" ? "short" : "medium";
    return {
      approximate: lc.date.approximate[variant],
      uncertain: lc.date.uncertain[variant]
    };
  }
  function isDMY(type) {
    return type === "day" || type === "month" || type === "year";
  }
  function mask(date2, parts) {
    let string = "";
    for (let { type, value } of parts) {
      string += isDMY(type) && date2.unspecified.is(type) ? value.replace(/./g, "X") : value;
    }
    return string;
  }
  function format(date2, locale = "en-US", options = {}) {
    if (date2.timeZone && !options.timeZone) {
      options = __spreadProps(__spreadValues({
        timeZoneName: "short"
      }, options), {
        timeZone: date2.timeZone
      });
    }
    const fmt = getFormat(date2, locale, options);
    const pat = getPatternsFor(fmt);
    if (!date2.isEDTF || pat == null) {
      return fmt.format(date2);
    }
    if (date2.type === "Interval") {
      if (date2.finite) {
        return fmt.formatRange(date2.lower, date2.upper);
      } else {
        throw new Error("cannot format infinite intervals");
      }
    }
    let string = !date2.unspecified.value || !fmt.formatToParts ? fmt.format(date2) : mask(date2, fmt.formatToParts(date2));
    if (date2.approximate.value) {
      string = pat.approximate.replace("%D", string);
    }
    if (date2.uncertain.value) {
      string = pat.uncertain.replace("%D", string);
    }
    return string;
  }
  format.cache = /* @__PURE__ */ new Map();

  // node_modules/edtf/src/date.js
  var { abs } = Math;
  var { isArray } = Array;
  var P = /* @__PURE__ */ new WeakMap();
  var U = /* @__PURE__ */ new WeakMap();
  var A = /* @__PURE__ */ new WeakMap();
  var X = /* @__PURE__ */ new WeakMap();
  var Z = /* @__PURE__ */ new WeakMap();
  var PM = [Bitmask.YMD, Bitmask.Y, Bitmask.YM, Bitmask.YMD];
  var Date2 = class _Date extends globalThis.Date {
    constructor(...args) {
      let precision = 0;
      let uncertain, approximate, unspecified, timeZone;
      switch (args.length) {
        case 0:
          break;
        case 1:
          switch (typeof args[0]) {
            case "number":
              break;
            case "string":
              args = [_Date.parse(args[0])];
            // eslint-disable-next-line no-fallthrough
            case "object":
              if (isArray(args[0]))
                args[0] = { values: args[0] };
              {
                let obj = args[0];
                assert_default(obj != null);
                if (obj.type) assert_default.equal("Date", obj.type);
                if (obj.values && obj.values.length) {
                  precision = obj.values.length;
                  args = obj.values.slice();
                  if (args.length < 2) args.push(0);
                  if (obj.offset) {
                    if (args.length < 3) args.push(1);
                    while (args.length < 5) args.push(0);
                    args[4] = args[4] - obj.offset;
                  }
                  args = [ExtDateTime.UTC(...args)];
                }
                ({ uncertain, approximate, unspecified, timeZone } = obj);
              }
              break;
            default:
              throw new RangeError("Invalid time value");
          }
          break;
        default:
          precision = args.length;
      }
      super(...args);
      this.precision = precision;
      this.uncertain = uncertain;
      this.approximate = approximate;
      this.unspecified = unspecified;
      this.timeZone = timeZone;
    }
    set precision(value) {
      P.set(this, value > 3 ? 0 : Number(value));
    }
    get precision() {
      return P.get(this);
    }
    set uncertain(value) {
      U.set(this, this.bits(value));
    }
    get uncertain() {
      return U.get(this);
    }
    set approximate(value) {
      A.set(this, this.bits(value));
    }
    get approximate() {
      return A.get(this);
    }
    set unspecified(value) {
      X.set(this, new Bitmask(value));
    }
    get unspecified() {
      return X.get(this);
    }
    set timeZone(value) {
      Z.set(this, value);
    }
    get timeZone() {
      return Z.get(this);
    }
    get atomic() {
      return !(this.precision || this.unspecified.value);
    }
    get min() {
      if (this.unspecified.value && this.year < 0) {
        let values = this.unspecified.max(this.values.map(_Date.pad));
        values[0] = -values[0];
        return new _Date({ values }).getTime();
      }
      return this.getTime();
    }
    get max() {
      return this.atomic ? this.getTime() : this.next().getTime() - 1;
    }
    get year() {
      return this.getUTCFullYear();
    }
    get month() {
      return this.getUTCMonth();
    }
    get date() {
      return this.getUTCDate();
    }
    get hours() {
      return this.getUTCHours();
    }
    get minutes() {
      return this.getUTCMinutes();
    }
    get seconds() {
      return this.getUTCSeconds();
    }
    get values() {
      switch (this.precision) {
        case 1:
          return [this.year];
        case 2:
          return [this.year, this.month];
        case 3:
          return [this.year, this.month, this.date];
        default:
          return [
            this.year,
            this.month,
            this.date,
            this.hours,
            this.minutes,
            this.seconds
          ];
      }
    }
    /**
     * Returns the next second, day, month, or year, depending on
     * the current date's precision. Uncertain, approximate and
     * unspecified masks are copied.
     */
    next(k = 1) {
      let { values, unspecified, uncertain, approximate } = this;
      if (unspecified.value) {
        let bc = values[0] < 0;
        values = k < 0 ^ bc ? unspecified.min(values.map(_Date.pad)) : unspecified.max(values.map(_Date.pad));
        if (bc) values[0] = -values[0];
      }
      values.push(values.pop() + k);
      return new _Date({ values, unspecified, uncertain, approximate });
    }
    prev(k = 1) {
      return this.next(-k);
    }
    *[Symbol.iterator]() {
      let cur = this;
      while (cur <= this.max) {
        yield cur;
        cur = cur.next();
      }
    }
    toEDTF() {
      if (!this.precision) return this.toISOString();
      let sign = this.year < 0 ? "-" : "";
      let values = this.values.map(_Date.pad);
      if (this.unspecified.value)
        return sign + this.unspecified.masks(values).join("-");
      if (this.uncertain.value)
        values = this.uncertain.marks(values, "?");
      if (this.approximate.value) {
        values = this.approximate.marks(values, "~").map((value) => value.replace(/(~\?)|(\?~)/, "%"));
      }
      return sign + values.join("-");
    }
    format(...args) {
      return format(this, ...args);
    }
    static pad(number, idx = 0) {
      if (!idx) {
        let k = abs(number);
        if (k < 10) return `000${k}`;
        if (k < 100) return `00${k}`;
        if (k < 1e3) return `0${k}`;
        return `${k}`;
      }
      if (idx === 1) number = number + 1;
      return number < 10 ? `0${number}` : `${number}`;
    }
    bits(value) {
      if (value === true)
        value = PM[this.precision];
      return new Bitmask(value);
    }
  };
  mixin(Date2, ExtDateTime);
  var pad = Date2.pad;

  // node_modules/edtf/src/year.js
  var { abs: abs2 } = Math;
  var V = /* @__PURE__ */ new WeakMap();
  var S = /* @__PURE__ */ new WeakMap();
  var Year = class _Year extends ExtDateTime {
    constructor(input) {
      super();
      V.set(this, []);
      switch (typeof input) {
        case "number":
          this.year = input;
          break;
        case "string":
          input = _Year.parse(input);
        // eslint-disable-next-line no-fallthrough
        case "object":
          if (Array.isArray(input))
            input = { values: input };
          {
            assert_default(input !== null);
            if (input.type) assert_default.equal("Year", input.type);
            assert_default(input.values);
            assert_default(input.values.length);
            this.year = input.values[0];
            this.significant = input.significant;
          }
          break;
        case "undefined":
          this.year = (/* @__PURE__ */ new Date()).getUTCFullYear();
          break;
        default:
          throw new RangeError("Invalid year value");
      }
    }
    get year() {
      return this.values[0];
    }
    set year(year2) {
      this.values[0] = Number(year2);
    }
    get significant() {
      return S.get(this);
    }
    set significant(digits) {
      S.set(this, Number(digits));
    }
    get values() {
      return V.get(this);
    }
    get min() {
      return ExtDateTime.UTC(this.year, 0);
    }
    get max() {
      return ExtDateTime.UTC(this.year + 1, 0) - 1;
    }
    toEDTF() {
      let y = abs2(this.year);
      let s = this.significant ? `S${this.significant}` : "";
      if (y <= 9999) return `${this.year < 0 ? "-" : ""}${pad(this.year)}${s}`;
      return `Y${this.year}${s}`;
    }
  };

  // node_modules/edtf/src/decade.js
  var { abs: abs3, floor: floor2 } = Math;
  var V2 = /* @__PURE__ */ new WeakMap();
  var Decade = class _Decade extends ExtDateTime {
    constructor(input) {
      super();
      V2.set(this, []);
      this.uncertain = false;
      this.approximate = false;
      switch (typeof input) {
        case "number":
          this.decade = input;
          break;
        case "string":
          input = _Decade.parse(input);
        // eslint-disable-next-line no-fallthrough
        case "object":
          if (Array.isArray(input))
            input = { values: input };
          {
            assert_default(input !== null);
            if (input.type) assert_default.equal("Decade", input.type);
            assert_default(input.values);
            assert_default(input.values.length === 1);
            this.decade = input.values[0];
            this.uncertain = !!input.uncertain;
            this.approximate = !!input.approximate;
          }
          break;
        case "undefined":
          this.year = (/* @__PURE__ */ new Date()).getUTCFullYear();
          break;
        default:
          throw new RangeError("Invalid decade value");
      }
    }
    get decade() {
      return this.values[0];
    }
    set decade(decade2) {
      decade2 = floor2(Number(decade2));
      assert_default(abs3(decade2) < 1e3, `invalid decade: ${decade2}`);
      this.values[0] = decade2;
    }
    get year() {
      return this.values[0] * 10;
    }
    set year(year2) {
      this.decade = year2 / 10;
    }
    get values() {
      return V2.get(this);
    }
    get min() {
      return Date2.UTC(this.year, 0);
    }
    get max() {
      return Date2.UTC(this.year + 10, 0) - 1;
    }
    toEDTF() {
      let decade2 = _Decade.pad(this.decade);
      if (this.uncertain)
        decade2 = decade2 + "?";
      if (this.approximate)
        decade2 = (decade2 + "~").replace(/\?~/, "%");
      return decade2;
    }
    static pad(number) {
      let k = abs3(number);
      let sign = k === number ? "" : "-";
      if (k < 10) return `${sign}00${k}`;
      if (k < 100) return `${sign}0${k}`;
      return `${number}`;
    }
  };

  // node_modules/edtf/src/century.js
  var { abs: abs4, floor: floor3 } = Math;
  var V3 = /* @__PURE__ */ new WeakMap();
  var Century = class _Century extends ExtDateTime {
    constructor(input) {
      super();
      V3.set(this, []);
      this.uncertain = false;
      this.approximate = false;
      switch (typeof input) {
        case "number":
          this.century = input;
          break;
        case "string":
          input = _Century.parse(input);
        // eslint-disable-next-line no-fallthrough
        case "object":
          if (Array.isArray(input))
            input = { values: input };
          {
            assert_default(input !== null);
            if (input.type) assert_default.equal("Century", input.type);
            assert_default(input.values);
            assert_default(input.values.length === 1);
            this.century = input.values[0];
            this.uncertain = !!input.uncertain;
            this.approximate = !!input.approximate;
          }
          break;
        case "undefined":
          this.year = (/* @__PURE__ */ new Date()).getUTCFullYear();
          break;
        default:
          throw new RangeError("Invalid century value");
      }
    }
    get century() {
      return this.values[0];
    }
    set century(century2) {
      century2 = floor3(Number(century2));
      assert_default(abs4(century2) < 100, `invalid century: ${century2}`);
      this.values[0] = century2;
    }
    get year() {
      return this.values[0] * 100;
    }
    set year(year2) {
      this.century = year2 / 100;
    }
    get values() {
      return V3.get(this);
    }
    get min() {
      return Date2.UTC(this.year, 0);
    }
    get max() {
      return Date2.UTC(this.year + 100, 0) - 1;
    }
    toEDTF() {
      let century2 = _Century.pad(this.century);
      if (this.uncertain)
        century2 = century2 + "?";
      if (this.approximate)
        century2 = (century2 + "~").replace(/\?~/, "%");
      return century2;
    }
    static pad(number) {
      let k = abs4(number);
      let sign = k === number ? "" : "-";
      if (k < 10) return `${sign}0${k}`;
      return `${number}`;
    }
  };

  // node_modules/edtf/src/season.js
  var A2 = /* @__PURE__ */ new WeakMap();
  var U2 = /* @__PURE__ */ new WeakMap();
  var V4 = /* @__PURE__ */ new WeakMap();
  var X2 = /* @__PURE__ */ new WeakMap();
  var Season = class _Season extends ExtDateTime {
    constructor(input) {
      super();
      let uncertain, approximate, unspecified;
      V4.set(this, []);
      switch (typeof input) {
        case "number":
          this.year = input;
          this.season = arguments[1] || 21;
          break;
        case "string":
          input = _Season.parse(input);
        // eslint-disable-next-line no-fallthrough
        case "object":
          if (Array.isArray(input))
            input = { values: input };
          {
            assert_default(input !== null);
            if (input.type) assert_default.equal("Season", input.type);
            assert_default(input.values);
            assert_default.equal(2, input.values.length);
            this.year = input.values[0];
            this.season = input.values[1];
            ({ unspecified, uncertain, approximate } = input);
          }
          break;
        case "undefined":
          this.year = (/* @__PURE__ */ new Date()).getUTCFullYear();
          this.season = 21;
          break;
        default:
          throw new RangeError("Invalid season value");
      }
      this.unspecified = unspecified;
      this.uncertain = uncertain;
      this.approximate = approximate;
    }
    get year() {
      return this.values[0];
    }
    set year(year2) {
      this.values[0] = Number(year2);
    }
    get season() {
      return this.values[1];
    }
    set season(season2) {
      this.values[1] = validate(Number(season2));
    }
    get values() {
      return V4.get(this);
    }
    set uncertain(value) {
      U2.set(this, new Bitmask(value));
    }
    get uncertain() {
      return U2.get(this);
    }
    set approximate(value) {
      A2.set(this, new Bitmask(value));
    }
    get approximate() {
      return A2.get(this);
    }
    set unspecified(value) {
      X2.set(this, new Bitmask(value));
    }
    get unspecified() {
      return X2.get(this);
    }
    next(k = 1) {
      let { season: season2, year: year2, unspecified, approximate, uncertain } = this;
      switch (true) {
        case (season2 >= 21 && season2 <= 36):
          [year2, season2] = inc(year2, season2, k, season2 - (season2 - 21) % 4, 4);
          break;
        case (season2 >= 37 && season2 <= 39):
          [year2, season2] = inc(year2, season2, k, 37, 3);
          break;
        case (season2 >= 40 && season2 <= 41):
          [year2, season2] = inc(year2, season2, k, 40, 2);
          break;
        default:
          throw new RangeError(`Cannot compute next/prev for season ${season2}`);
      }
      return new _Season({
        values: [year2, season2],
        approximate,
        uncertain,
        unspecified
      });
    }
    prev(k = 1) {
      return this.next(-k);
    }
    get min() {
      switch (this.season) {
        case 21:
        case 25:
        case 32:
        case 33:
        case 40:
        case 37:
          return ExtDateTime.UTC(this.year, 0);
        case 22:
        case 26:
        case 31:
        case 34:
          return ExtDateTime.UTC(this.year, 3);
        case 23:
        case 27:
        case 30:
        case 35:
        case 41:
          return ExtDateTime.UTC(this.year, 6);
        case 24:
        case 28:
        case 29:
        case 36:
          return ExtDateTime.UTC(this.year, 9);
        case 38:
          return ExtDateTime.UTC(this.year, 4);
        case 39:
          return ExtDateTime.UTC(this.year, 8);
        default:
          return ExtDateTime.UTC(this.year, 0);
      }
    }
    get max() {
      let [year2] = this.unspecified.max([pad(this.year)]);
      switch (this.season) {
        case 21:
        case 25:
        case 32:
        case 33:
          return ExtDateTime.UTC(year2, 3) - 1;
        case 22:
        case 26:
        case 31:
        case 34:
        case 40:
          return ExtDateTime.UTC(year2, 6) - 1;
        case 23:
        case 27:
        case 30:
        case 35:
          return ExtDateTime.UTC(year2, 9) - 1;
        case 24:
        case 28:
        case 29:
        case 36:
        case 41:
        case 39:
          return ExtDateTime.UTC(year2 + 1, 0) - 1;
        case 37:
          return ExtDateTime.UTC(year2, 5) - 1;
        case 38:
          return ExtDateTime.UTC(year2, 9) - 1;
        default:
          return ExtDateTime.UTC(year2 + 1, 0) - 1;
      }
    }
    toEDTF() {
      let sign = this.year < 0 ? "-" : "";
      let values = [pad(this.year), String(this.season)];
      if (this.unspecified.value)
        return sign + this.unspecified.masks(values).join("-");
      if (this.uncertain.value)
        values = this.uncertain.marks(values, "?");
      if (this.approximate.value) {
        values = this.approximate.marks(values, "~").map((value) => value.replace(/(~\?)|(\?~)/, "%"));
      }
      return sign + values.join("-");
    }
  };
  function validate(season2) {
    if (isNaN(season2) || season2 < 21 || season2 === Infinity)
      throw new RangeError(`invalid division of year: ${season2}`);
    return season2;
  }
  function inc(year2, season2, by, base, size) {
    const m = season2 + by - base;
    return [
      year2 + Math.floor(m / size),
      validate(base + (m % size + size) % size)
    ];
  }

  // node_modules/edtf/src/interval.js
  var V5 = /* @__PURE__ */ new WeakMap();
  var Interval = class _Interval extends ExtDateTime {
    constructor(...args) {
      super();
      V5.set(this, [null, null]);
      switch (args.length) {
        case 2:
          this.lower = args[0];
          this.upper = args[1];
          break;
        case 1:
          switch (typeof args[0]) {
            case "string":
              args[0] = _Interval.parse(args[0]);
            // eslint-disable-next-line no-fallthrough
            case "object":
              if (Array.isArray(args[0]))
                args[0] = { values: args[0] };
              {
                let [obj] = args;
                assert_default(obj !== null);
                if (obj.type) assert_default.equal("Interval", obj.type);
                assert_default(obj.values);
                assert_default(obj.values.length < 3);
                this.lower = obj.values[0];
                this.upper = obj.values[1];
                this.earlier = obj.earlier;
                this.later = obj.later;
              }
              break;
            default:
              this.lower = args[0];
          }
          break;
        case 0:
          break;
        default:
          throw new RangeError(`invalid interval value: ${args}`);
      }
    }
    get lower() {
      return this.values[0];
    }
    set lower(value) {
      if (value == null)
        return this.values[0] = null;
      if (value === Infinity || value === -Infinity)
        return this.values[0] = Infinity;
      value = getDateOrSeasonFrom(value);
      if (value >= this.upper && this.upper != null)
        throw new RangeError(`invalid lower bound: ${value}`);
      this.values[0] = value;
    }
    get upper() {
      return this.values[1];
    }
    set upper(value) {
      if (value == null)
        return this.values[1] = null;
      if (value === Infinity)
        return this.values[1] = Infinity;
      value = getDateOrSeasonFrom(value);
      if (this.lower !== null && this.lower !== Infinity && value <= this.lower)
        throw new RangeError(`invalid upper bound: ${value}`);
      this.values[1] = value;
    }
    get finite() {
      return this.lower != null && this.lower !== Infinity && (this.upper != null && this.upper !== Infinity);
    }
    get precision() {
      var _a, _b, _c, _d;
      return (_d = (_c = (_a = this.lower) == null ? void 0 : _a.precision) != null ? _c : (_b = this.upper) == null ? void 0 : _b.precision) != null ? _d : 0;
    }
    *[Symbol.iterator]() {
      if (!this.finite) throw Error("cannot iterate infinite interval");
      yield* __yieldStar(this.lower.through(this.upper));
    }
    get values() {
      return V5.get(this);
    }
    get min() {
      let v = this.lower;
      return !v ? null : v === Infinity ? -Infinity : v.min;
    }
    get max() {
      let v = this.upper;
      return !v ? null : v === Infinity ? Infinity : v.max;
    }
    get isEDTFInterval() {
      return true;
    }
    toEDTF() {
      return this.values.map((v) => {
        if (v === Infinity) return "..";
        if (!v) return "";
        return v.edtf;
      }).join("/");
    }
  };
  function getDateOrSeasonFrom(value) {
    try {
      return Date2.from(value);
    } catch (e) {
      return Season.from(value);
    }
  }

  // node_modules/edtf/src/list.js
  var { isArray: isArray2 } = Array;
  var V6 = /* @__PURE__ */ new WeakMap();
  var List = class extends ExtDateTime {
    constructor(...args) {
      super();
      V6.set(this, []);
      if (args.length > 1) args = [args];
      if (args.length) {
        switch (typeof args[0]) {
          case "string":
            args[0] = new.target.parse(args[0]);
          // eslint-disable-next-line no-fallthrough
          case "object":
            if (isArray2(args[0]))
              args[0] = { values: args[0] };
            {
              let [obj] = args;
              assert_default(obj !== null);
              if (obj.type) assert_default.equal(this.type, obj.type);
              assert_default(obj.values);
              this.concat(...obj.values);
              this.earlier = !!obj.earlier;
              this.later = !!obj.later;
            }
            break;
          default:
            throw new RangeError(`invalid ${this.type} value: ${args}`);
        }
      }
    }
    get values() {
      return V6.get(this);
    }
    get length() {
      return this.values.length;
    }
    get empty() {
      return this.length === 0;
    }
    get first() {
      let value = this.values[0];
      return isArray2(value) ? value[0] : value;
    }
    get last() {
      let value = this.values[this.length - 1];
      return isArray2(value) ? value[0] : value;
    }
    clear() {
      return this.values.length = 0, this;
    }
    concat(...args) {
      for (let value of args) this.push(value);
      return this;
    }
    push(value) {
      if (isArray2(value)) {
        assert_default.equal(2, value.length);
        return this.values.push(value.map((v) => Date2.from(v)));
      }
      return this.values.push(Date2.from(value));
    }
    *[Symbol.iterator]() {
      for (let value of this.values) {
        if (isArray2(value))
          yield* __yieldStar(value[0].through(value[1]));
        else
          yield value;
      }
    }
    get min() {
      return this.earlier ? -Infinity : this.empty ? 0 : this.first.min;
    }
    get max() {
      return this.later ? Infinity : this.empty ? 0 : this.last.max;
    }
    content() {
      return this.values.map((v) => isArray2(v) ? v.map((d) => d.edtf).join("..") : v.edtf).join(",");
    }
    toEDTF() {
      return this.wrap(
        this.empty ? "" : `${this.earlier ? ".." : ""}${this.content()}${this.later ? ".." : ""}`
      );
    }
    wrap(content) {
      return `{${content}}`;
    }
  };

  // node_modules/edtf/src/set.js
  var Set = class extends List {
    static parse(input) {
      return parse(input, { types: ["Set"] });
    }
    get type() {
      return "Set";
    }
    wrap(content) {
      return `[${content}]`;
    }
  };

  // node_modules/edtf/src/edtf.js
  var UNIX_TIME = /^\d{5,}$/;
  function edtf(...args) {
    if (!args.length)
      return new Date2();
    if (args.length === 1) {
      switch (typeof args[0]) {
        case "object":
          return new (types_exports[args[0].type] || Date2)(args[0]);
        case "number":
          return new Date2(args[0]);
        case "string":
          if (UNIX_TIME.test(args[0]))
            return new Date2(Number(args[0]));
      }
    }
    let res = parse(...args);
    return new types_exports[res.type](res);
  }

  // app/javascript/edtf_subfield.js
  defaults.level = 3;
  window.edtf = edtf;
  window.edtf_format = format;
  window.muscatWidgetInitializers = window.muscatWidgetInitializers || [];
  window.muscatRegisterWidgetInitializer = window.muscatRegisterWidgetInitializer || function(initializer) {
    if (!window.muscatWidgetInitializers.includes(initializer)) {
      window.muscatWidgetInitializers.push(initializer);
    }
  };
  window.muscatInitializeWidgetsInBlock = window.muscatInitializeWidgetsInBlock || function(root) {
    const scope = root || document;
    window.muscatWidgetInitializers.forEach((initializer) => {
      initializer(scope);
    });
  };
  function bindEdtfDelegatedKeyup() {
    if (window.muscatEdtfDelegatedKeyupBound) {
      return;
    }
    window.muscatEdtfDelegatedKeyupBound = true;
    document.addEventListener("keyup", (event) => {
      if (!(event.target instanceof HTMLElement)) {
        return;
      }
      if (!event.target.matches(".input-edtf")) {
        return;
      }
      updateEdtf(event.target);
    });
  }
  function updateEdtf(input) {
    let parsedDate;
    let defaultLocale = "en-US";
    const formats = {
      weekday: "long",
      year: "numeric",
      month: "long",
      day: "numeric"
    };
    const container = input.closest(".edtf-subfield") || input.parentElement || document;
    const message = container.querySelector(".edtf-message");
    const error = container.querySelector(".edtf-error");
    function setErrorText(text) {
      if (!error) {
        return;
      }
      error.innerHTML = "";
      const pre = document.createElement("pre");
      pre.textContent = text;
      error.appendChild(pre);
    }
    if (!input.value) {
      if (message) {
        message.textContent = "";
      }
      if (error) {
        error.innerHTML = "";
      }
      return;
    }
    try {
      parsedDate = edtf(input.value);
    } catch (err) {
      const first3Lines = err.message.split(/\r?\n/).slice(0, 4).join("\n");
      if (message) {
        message.textContent = "It was not possible to parse the EDTF date \u2639";
      }
      setErrorText(first3Lines);
      return;
    }
    let formatted = parsedDate;
    try {
      formatted = format(parsedDate, defaultLocale, formats);
    } catch (_err) {
    }
    if (message) {
      message.textContent = `Formatted date: ${formatted}`;
    }
    if (error) {
      error.innerHTML = "";
    }
  }
  function initEdtfSubfield(root) {
    const scope = root || document;
    const inputs = scope.querySelectorAll(".input-edtf");
    inputs.forEach((input) => {
      if (input.dataset.edtfInitialized === "true") {
        return;
      }
      input.dataset.edtfInitialized = "true";
      updateEdtf(input);
    });
  }
  bindEdtfDelegatedKeyup();
  window.muscatRegisterWidgetInitializer(initEdtfSubfield);
  document.addEventListener("DOMContentLoaded", () => {
    window.muscatInitializeWidgetsInBlock(document);
  });
  document.addEventListener("turbo:load", () => {
    window.muscatInitializeWidgetsInBlock(document);
  });
})();
