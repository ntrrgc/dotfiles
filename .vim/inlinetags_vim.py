import sys
import vim
from vimlines import vim_to_pos, pos_to_vim
from inlinetags import find_tag_pair, cursor_in_tag

def get_vim_document():
    document = vim.current.buffer[:]
    code = '\n'.join(document)
    line, col = vim.current.window.cursor
    pos = vim_to_pos(document, line, col)

    return code, document, pos

def jump_to_pairing():
    code, document, pos = get_vim_document()

    if cursor_in_tag(code, pos):
        # Find matching HTML pair
        pairing_pos = find_tag_pair(code, pos)
        if pairing_pos is not None:
            start_tag, end_tag = pairing_pos
            vim.current.window.cursor = pos_to_vim(document, start_tag)
        else:
            print("No pairing.")
    else:
        # Fallback to vim's %
        vim.command("normal! %")
