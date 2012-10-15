window.diff = {}

diff.jsdiff = (base_raw, newtext_raw) ->
    # get the baseText and newText values from the two textboxes, and split them into lines
    base = difflib.stringAsLines(base_raw)
    newtxt = difflib.stringAsLines(newtext_raw)

    # create a SequenceMatcher instance that diffs the two sets of lines
    sm = new difflib.SequenceMatcher(base, newtxt)

    # get the opcodes from the SequenceMatcher instance
    # opcodes is a list of 3-tuples describing what changes should be made to the base text
    # in order to yield the new text
    opcodes = sm.get_opcodes()

    # build the diff view and add it to the current DOM
    return diffview.buildView
        baseTextLines: base
        newTextLines: newtxt
        opcodes: opcodes
        # set the display titles for each resource
        baseTextName: "Base Text"
        newTextName: "New Text"
        contextSize: 16
        viewType: 0

diff.parse_diff = (contents) ->
    lines = contents.split('\n')
    index = 0
    file_changes = {}

    while index < lines.length
        current_changes = []

        [_diff_line, _index_line, first_file, _second_file] = lines[index...index+4]
        index += 4
        file_path = first_file.match(/.+? a\/(.+)/)[1]

        # find all hunks in this file
        while index < lines.length and lines[index][0] != 'd'
            hunk = lines[index++]
            line_number = hunk.match(/@@ \-(\d+),\d+ \+\d+,\d+ @@/)[1]

            while index < lines.length and lines[index][0] not in ['d', '@']
                c = lines[index][0]
                if c == '+'
                    content = lines[index][1..]
                    current_changes.push({action: 'add', line: line_number, content: content})
                else if c == '-'
                    current_changes.push({action: 'del', line: line_number})
                    line_number++
                else
                    line_number++

                index++

        file_changes[file_path] = current_changes

    return file_changes

diff.invert_diff = (contents) ->
    result = []
    # perform a limited sort of inversion of the diff
    for line in contents.split('\n')
        match = line.match(/^@@ \-(\d+),(\d+) \+(\d+),(\d+) @@(.*)/)
        if match?
            [_, l1, s1, l2, s2, content] = match
            result.push("@@ -#{l2},#{s2} +#{l1},#{s1} @@#{content}")
            continue

        match = line.match(/^(\+|\-)(.*)/)
        if match?
            [_, plus_or_minus, content] = match
            plus_or_minus = {'+': '-', '-': '+'}[plus_or_minus]
            result.push("#{plus_or_minus}#{content}")
            continue

        result.push(line)

    return result.join('\n')

diff.apply_changes = (file_path, changes, content) ->
    file_changes = changes[file_path]

    lines = content.split('\n')
    result = []
    change_index = 0
    line_index = 0

    while line_index < lines.length
        line = lines[line_index]
        line_number = line_index + 1

        change = file_changes[change_index]
        if change? and change.line == line_number
            change_index++

            if change.action == 'add'
                result.push(change.content)
                continue
            if change.action == 'del'
                line_index++
                continue

        result.push(line)
        line_index++

    return result.join('\n')
