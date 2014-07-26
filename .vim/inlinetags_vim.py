import sys
import vim
from vim_mock import Cursor
from inlinetags import find_tag_pair, cursor_in_tag, expand_cursor

class VimLines(object):
    def __init__(self, buffer):
        self.buffer = buffer

    def __getitem__(self, index):
        return self.buffer[index]

    def __setitem__(self, index, value):
        self.buffer[index] = value

    def __len__(self):
        return len(self.buffer)


class VimDocument(object):
    def __init__(self, buffer=None):
        if buffer is None:
            buffer = vim.current.buffer

        self.buffer = buffer
        self.indent_width = self.buffer.options["shiftwidth"]
        self.lines = VimLines(self.buffer)

    def insert_line_before(self, line, text):
        self.buffer.append(text, line)

    def insert_line_after(self, line, text):
        self.buffer.append(text, line + 1)

    def make_cursor(self, line, col):
        return Cursor(self, line, col)

    def get_caret(self):
        line, col = vim.current.window.cursor
        return Cursor(self, line - 1, col)

    def set_caret(self, cursor):
        vim.current.window.cursor = (cursor.line + 1, cursor.col)


def jump_to_pairing(mode):
    document = VimDocument()
    if mode == "v":
        vim.command("normal! gv")

    pos = document.get_caret()
    if cursor_in_tag(pos):
        # Find matching HTML pair
        pairing_pos = find_tag_pair(pos)
        if pairing_pos is not None:
            start_tag, end_tag = pairing_pos
            document.set_caret(start_tag)
        else:
            print("No pairing.")
    else:
        # Fallback to vim's %
        vim.command("normal! %")

def vim_expand_tag(mode):
    document = VimDocument()
    if mode != "v":
        pos = document.get_caret()
        sel = expand_cursor(pos)
        document.set_caret(sel.start)
        # FIXME Does not work with line endings
        vim.command("normal! m<")
        document.set_caret(sel.end)
        vim.command("normal! m>")
        vim.command("normal! gv")
