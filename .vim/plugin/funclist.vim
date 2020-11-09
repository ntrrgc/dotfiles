pythonx << EOF
import vim
import re

def iter_chars(buffer, ln, col):
    while True:
        while col >= len(buffer[ln]):
            ln += 1
            col = 0
            if ln >= len(buffer):
                return
        yield ln, col, buffer[ln][col]
        col += 1

def match_opening_parentheses(buffer, opening_parenthesis_ln, opening_parenthesis_col):
    parenthesis_balance = 1
    assert buffer[opening_parenthesis_ln][opening_parenthesis_col] == "("
    for ln, col, char in iter_chars(buffer, opening_parenthesis_ln, opening_parenthesis_col + 1):
        if char == "(":
            parenthesis_balance += 1
        elif char == ")":
            parenthesis_balance -= 1
            if parenthesis_balance == 0:
                return ln, col

def buffer_trimmed_substr(buffer, start_ln, start_col, last_ln, last_col):
    if start_ln == last_ln:
        return buffer[start_ln][start_col:last_col + 1]
    else:
        ret = buffer[start_ln][start_col:]
        for ln in range(start_ln + 1, last_ln):
            ret += buffer[ln].lstrip()
        ret += buffer[last_ln][:last_col + 1].lstrip()
        return ret

def find_c_functions(buffer):
    functions = []
    for ln in range(len(buffer)):
        line = buffer[ln]
        if line.startswith(" ") or line.startswith("\t") or line.startswith("/*") \
           or line.startswith("//") or line.startswith("*") or line.startswith("#") \
           or line.strip() == "" or line.strip().endswith(";") or not "(" in line:
            continue

        opening_parenthesis_col = line.index("(")
        closing_parenthesis_match = match_opening_parentheses(buffer, ln, opening_parenthesis_col)
        if closing_parenthesis_match:
            closing_parenthesis_ln, closing_parenthesis_col = closing_parenthesis_match

            if buffer[closing_parenthesis_ln][closing_parenthesis_col + 1:].strip().startswith(";"):
                # We don't want function declarations, only definitions. There
                # is already a filter against declarations before, but it will
                # fail when the signature expands several lines, so we have to
                # check here.
                continue

            function_signature = buffer_trimmed_substr(buffer, ln, 0,
                                                       closing_parenthesis_ln, closing_parenthesis_col)
        else:
            # Parentheses are unmatched (likely wrong code), just use that one line as-is.
            function_signature = line.strip()

        has_type_in_the_same_line = " " in line[:opening_parenthesis_col].strip()
        if not has_type_in_the_same_line and ln > 0:
            # Assume GNU coding style, where the type is in the previous line
            function_signature = buffer[ln - 1].strip() + " " + function_signature

        functions.append({
            "bufnr": buffer.number,
            "lnum": ln - (0 if has_type_in_the_same_line else 1) + 1, # Vim lnum is 1-indexed
            "text": function_signature,
        })
    return functions

def show_function_list():
    functions = find_c_functions(vim.current.buffer)

    # Find the current function to use as default.
    current_line_lnum = vim.current.range.start + 1 # range.start is 0-indexed, lnum is 1-indexed
    for idx, function in enumerate(functions):
        if function["lnum"] > current_line_lnum:
            # We have found a function after the current line, which means the
            # previous function declaration is the one the user is focused on.
            current_function_idx = idx - 1
            break
    else:
        # We didn't find any function declaration after the user cursor, the user
        # is at the last function.
        current_function_idx = len(functions)

    vim.Function("setloclist")(0, [], " ", {
        "title": "Functions",
        "efm": "%m",
        "items": functions,
        "idx": current_function_idx + 1,
    })
    vim.command("lopen")

    # Remove the filenames to use less space
    vim.current.buffer.options["modifiable"] = True
    for ln in range(len(vim.current.buffer)):
        vim.current.buffer[ln] = re.sub(r"^.*?\|.*?\| ", "", vim.current.buffer[ln])
    vim.current.buffer.options["modifiable"] = False
EOF

augroup CFuncList
    autocmd FileType c,cpp noremap <buffer> <silent> <C-k> :pythonx show_function_list()<CR>
augroup END
