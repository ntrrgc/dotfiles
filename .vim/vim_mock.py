from functools import total_ordering


class HitDocumentBounds(Exception):
    pass

class InvalidCursor(Exception):
    pass


class MockDocument(object):
    def __init__(self, lines, indent_width=4):
        self.lines = lines
        self.indent_width = indent_width
    
    def make_cursor(self, line, col):
        return Cursor(self, line, col)

    def insert_line_before(self, line, text):
        self.lines[line:line] = [text]

    def insert_line_after(self, line, text):
        self.lines[line + 1:line + 1] = [text]

    def insert_after_cursor(self, text, cursor):
        new_lines = text.split("\n")
        if len(new_lines) == 0: # empty text
            return

        before = self.lines[cursor.line][:cursor.col + 1]
        after = self.lines[cursor.line][cursor.col + 1:]

        # First line
        self.lines[cursor.line] = before + new_lines[0]

        # Lines from second to penultimate
        for insert_after, new_line in enumerate(new_lines[1:], cursor.line):
            self.insert_line_after(insert_after, new_line)

        # Last line
        last_line = cursor.line + len(new_lines) - 1
        self.lines[last_line] += after


def advance_function(prev_function, next_function):
    def _advance_function(function):
        def _advance(self, increment):
            if increment == 1:
                return next_function(self)
            elif increment == -1:
                return prev_function(self)
            elif increment == 0:
                raise ValueError
            else:
                # Advance several times
                orientation = 1 if increment > 0 else -1
                cursor = self
                for i in range(abs(increment)):
                    cursor = _advance(cursor, orientation)
                return cursor
        return _advance
    return _advance_function


@total_ordering
class Cursor(object):
    def __init__(self, document, line, col):
        self.document = document
        self.line = line
        self.col = col

        if line >= len(document.lines):
            raise InvalidCursor
        elif col > len(document.lines[line]):
            raise InvalidCursor
        elif line < 0 or col < 0:
            raise InvalidCursor

    @property
    def line_text(self):
        return self.document.lines[self.line]
    
    @line_text.setter
    def set_line_text(self, value):
        self.document.lines[self.line] = value

    @property
    def is_eol(self):
        return self.col == len(self.line_text)
    
    @property
    def char(self):
        if not self.is_eol:
            return self.line_text[self.col]
        else:
            return "\n"

    @property
    def is_first_line(self):
        return self.line == 0
    
    @property
    def is_last_line(self):
        return self.line == len(self.document.lines) - 1

    def next_line(self):
        if not self.is_last_line:
            return Cursor(self.document, self.line + 1, 0)
        else:
            raise HitDocumentBounds

    def prev_line(self):
        if self.line > 0:
            return Cursor(self.document, self.line - 1, 0)
        else:
            raise HitDocumentBounds

    @advance_function(prev_line, next_line)
    def advance_lines(self, increment):
        pass

    def next_char(self):
        if self.col < len(self.line_text):
            return Cursor(self.document, self.line, self.col + 1)
        else:
            return self.next_line()
    
    def prev_char(self):
        if self.col > 0:
            return Cursor(self.document, self.line, self.col - 1)
        else:
            prev_line = self.prev_line()
            return Cursor(self.document, prev_line.line,
                              len(prev_line.line_text))

    @advance_function(prev_char, next_char)
    def advance_chars(self, increment):
        pass
    
    def __eq__(self, other):
        if isinstance(other, Cursor):
            other = (other.line, other.col)
        return (self.line, self.col) == other
    
    def __lt__(self, other):
        if isinstance(other, Cursor):
            other = (other.line, other.col)
        return (self.line, self.col) < other
    
    
class Range(object):
    def __init__(self, start, end):
        self.start = start
        self.end = end
    
    @property
    def text(self):
        buf = ""
        i = self.start
        while i <= self.end:
            buf += i.char
            i = i.next_char()
        return buf
    
import unittest


class TestRead(unittest.TestCase):
    def setUp(self):
        self.doc = MockDocument([
            "<!doctype html>",
            "<html>",
            "  <head>",
            "    <title></title>",
            "  </head>",
            "</html>",
        ], indent_width=2)

    def test_get_line(self):
        c = self.doc.make_cursor(1, 3)
        self.assertEqual(c.line_text, "<html>")

    def test_get_char(self):
        c = self.doc.make_cursor(2, 2)
        self.assertEqual(c.char, "<")

        c = self.doc.make_cursor(2, 3)
        self.assertEqual(c.char, "h")

        c = self.doc.make_cursor(2, 4)
        self.assertEqual(c.char, "e")

    def test_eol(self):
        c = self.doc.make_cursor(1, 6)

        self.assertTrue(c.is_eol)
        self.assertEqual(c.char, "\n")
    
    def test_invalid_cursors(self):
        with self.assertRaises(InvalidCursor):
            self.doc.make_cursor(1, 7)

        with self.assertRaises(InvalidCursor):
            self.doc.make_cursor(1, -10)

        with self.assertRaises(InvalidCursor):
            self.doc.make_cursor(-1, 0)


class TestMoveLines(unittest.TestCase):
    def setUp(self):
        self.doc = MockDocument([
            "<!doctype html>",
            "<html>",
            "  <head>",
            "    <title></title>",
            "  </head>",
            "</html>",
        ], indent_width=2)

    def test_next_line(self):
        c = self.doc.make_cursor(0, 0)
        self.assertEqual(c.next_line().line, 1)
    
    def test_next_line_last(self):
        c = self.doc.make_cursor(5, 0)
        with self.assertRaises(HitDocumentBounds):
            c.next_line()

    def test_prev_line(self):
        c = self.doc.make_cursor(5, 0)
        self.assertEqual(c.prev_line().line, 4)

    def test_prev_line_first(self):
        c = self.doc.make_cursor(0, 0)
        with self.assertRaises(HitDocumentBounds):
            c.prev_line()
    
    def test_advance_lines_forward(self):
        c = self.doc.make_cursor(0, 0)
        self.assertEqual(c.advance_lines(2).line, 2)

    def test_advance_lines_backwards(self):
        c = self.doc.make_cursor(2, 0)
        self.assertEqual(c.advance_lines(-2).line, 0)


class TestMoveCharacters(unittest.TestCase):
    def setUp(self):
        self.doc = MockDocument([
            "<!doctype html>",
            "<html>",
            "  <head>",
            "    <title></title>",
            "  </head>",
            "</html>",
        ], indent_width=2)

    def test_next_char(self):
        c = self.doc.make_cursor(1, 0)
        self.assertEqual(c.char, "<")
        self.assertEqual(c.next_char().char, "h")
    
    def test_next_char_line_ending(self):
        c = self.doc.make_cursor(1, 6)
        self.assertEqual(c.char, "\n")
        self.assertEqual(c.next_char().char, " ")

    def test_next_char_eof(self):
        c = self.doc.make_cursor(5, 7)
        self.assertTrue(c.is_eol)
        with self.assertRaises(HitDocumentBounds):
            c.next_char()

    def test_prev_char(self):
        c = self.doc.make_cursor(0, 3)
        self.assertEqual(c.char, "o")
        self.assertEqual(c.prev_char().char, "d")

    def test_prev_char_line_beginning(self):
        c = self.doc.make_cursor(2, 0)
        self.assertEqual(c.char, " ")
        self.assertEqual(c.prev_char().line, 1)
        self.assertEqual(c.prev_char().col, 6)

    def test_prev_char_start_of_file(self):
        c = self.doc.make_cursor(0, 0)
        with self.assertRaises(HitDocumentBounds):
            c.prev_char()
    
    def test_advance_chars_forward(self):
        c = self.doc.make_cursor(0, 0)
        self.assertEqual(c.advance_chars(3).char, "o")

    def test_advance_lines_backwards(self):
        c = self.doc.make_cursor(2, 0)
        self.assertEqual(c.advance_chars(-2).char, ">")


class TestComparation(unittest.TestCase):
    def setUp(self):
        self.doc = MockDocument([
            "<!doctype html>",
            "<html>",
            "  <head>",
            "    <title></title>",
            "  </head>",
            "</html>",
        ], indent_width=2)

    def test_operators(self):
        self.assertEqual(self.doc.make_cursor(1, 2),
                         self.doc.make_cursor(1, 2))

        self.assertLess(self.doc.make_cursor(1, 1),
                        self.doc.make_cursor(1, 2))

        self.assertLess(self.doc.make_cursor(1, 3),
                        self.doc.make_cursor(2, 0))

        self.assertGreaterEqual(self.doc.make_cursor(3, 3),
                                self.doc.make_cursor(2, 0))
    
    
class TestWrite(unittest.TestCase):
    def setUp(self):
        self.doc = MockDocument([
            "<!doctype html>",
            "<html>",
            "  <head>",
            "    <title></title>",
            "  </head>",
            "</html>",
        ], indent_width=2)

    def test_insert_before(self):
        self.doc.insert_line_before(1, "foo")
        self.assertEqual(self.doc.lines, [
            "<!doctype html>",
            "foo",
            "<html>",
            "  <head>",
            "    <title></title>",
            "  </head>",
            "</html>",
        ])

    def test_insert_before_beginning(self):
        self.doc.insert_line_before(0, "foo")
        self.assertEqual(self.doc.lines, [
            "foo",
            "<!doctype html>",
            "<html>",
            "  <head>",
            "    <title></title>",
            "  </head>",
            "</html>",
        ])

    def test_insert_after(self):
        self.doc.insert_line_after(1, "foo")
        self.assertEqual(self.doc.lines, [
            "<!doctype html>",
            "<html>",
            "foo",
            "  <head>",
            "    <title></title>",
            "  </head>",
            "</html>",
        ])

    def test_insert_ending(self):
        self.doc.insert_line_after(5, "foo")
        self.assertEqual(self.doc.lines, [
            "<!doctype html>",
            "<html>",
            "  <head>",
            "    <title></title>",
            "  </head>",
            "</html>",
            "foo",
        ])

    def test_cursor_insert_after(self):
        c = self.doc.make_cursor(3, 10) # > of <title>
        self.assertEqual(c.char, ">")

        self.doc.insert_after_cursor("Hello World", c)
        self.assertEqual(c.line_text, "    <title>Hello World</title>")
    
    def test_cursor_insert_after_eol(self):
        c = self.doc.make_cursor(1, 6)
        self.assertTrue(c.is_eol)

        self.doc.insert_after_cursor("Hello World", c)
        self.assertEqual(c.line_text, "<html>Hello World")

    def test_cursor_insert_after_lines(self):
        c = self.doc.make_cursor(3, 10) # > of <title>
        self.assertEqual(c.char, ">")

        self.doc.insert_after_cursor("Hello\nWorld", c)
        self.assertEqual(c.line_text, "    <title>Hello")

        c2 = c.next_line()
        self.assertEqual(c2.line_text, "World</title>")
    

if __name__ == "__main__":
    unittest.main()
