// Generated by IcedCoffeeScript 1.3.3f
(function() {

  window.diff = {};

  diff.jsdiff = function(base_raw, newtext_raw) {
    var base, newtxt, opcodes, sm;
    base = difflib.stringAsLines(base_raw);
    newtxt = difflib.stringAsLines(newtext_raw);
    sm = new difflib.SequenceMatcher(base, newtxt);
    opcodes = sm.get_opcodes();
    return diffview.buildView({
      baseTextLines: base,
      newTextLines: newtxt,
      opcodes: opcodes,
      baseTextName: "Base Text",
      newTextName: "New Text",
      contextSize: 16,
      viewType: 0
    });
  };

  diff.parse_diff = function(contents) {
    var c, content, current_changes, file_changes, file_path, hunk, index, line_number, lines, _ref;
    lines = contents.split('\n');
    index = 0;
    file_changes = {};
    while (index < lines.length) {
      current_changes = [];
      while (index < lines.length) {
        if (lines[index].match(/^\+\+\+/)) {
          console.log('line', lines[index]);
          file_path = lines[index].match(/^\+\+\+ b\/(.+)/)[1];
          index++;
          break;
        }
        console.log('skip line', lines[index]);
        index++;
      }
      console.log("file_path", file_path);
      while (index < lines.length && lines[index][0] !== 'd') {
        hunk = lines[index++];
        line_number = hunk.match(/@@ \-(\d+),\d+ .*/)[1];
        while (index < lines.length && ((_ref = lines[index][0]) !== 'd' && _ref !== '@')) {
          c = lines[index][0];
          if (c === '+') {
            content = lines[index].slice(1);
            current_changes.push({
              action: 'add',
              line: line_number,
              content: content
            });
          } else if (c === '-') {
            current_changes.push({
              action: 'del',
              line: line_number
            });
            line_number++;
          } else {
            line_number++;
          }
          index++;
        }
      }
      file_changes[file_path] = current_changes;
    }
    return file_changes;
  };

  diff.invert_diff = function(contents) {
    var content, l1, l2, line, match, plus_or_minus, result, s1, s2, _, _i, _len, _ref;
    result = [];
    _ref = contents.split('\n');
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      line = _ref[_i];
      match = line.match(/^@@ \-(\d+),(\d+) \+(\d+),(\d+) @@(.*)/);
      if (match != null) {
        _ = match[0], l1 = match[1], s1 = match[2], l2 = match[3], s2 = match[4], content = match[5];
        result.push("@@ -" + l2 + "," + s2 + " +" + l1 + "," + s1 + " @@" + content);
        continue;
      }
      match = line.match(/^(\+|\-)(.*)/);
      if (match != null) {
        if (line.match(/^(\+\+\+|\-\-\-)/)) {
          result.push(line);
          continue;
        }
        _ = match[0], plus_or_minus = match[1], content = match[2];
        plus_or_minus = {
          '+': '-',
          '-': '+'
        }[plus_or_minus];
        result.push("" + plus_or_minus + content);
        continue;
      }
      result.push(line);
    }
    return result.join('\n');
  };

  diff.apply_changes = function(file_path, changes, content) {
    var change, change_index, file_changes, line, line_index, line_number, lines, result;
    file_changes = changes[file_path];
    lines = content.split('\n');
    result = [];
    change_index = 0;
    line_index = 0;
    while (line_index < lines.length) {
      line = lines[line_index];
      line_number = line_index + 1;
      change = file_changes[change_index];
      if ((change != null) && change.line === line_number) {
        change_index++;
        if (change.action === 'add') {
          result.push(change.content);
          continue;
        }
        if (change.action === 'del') {
          line_index++;
          continue;
        }
      }
      result.push(line);
      line_index++;
    }
    return result.join('\n');
  };

}).call(this);
