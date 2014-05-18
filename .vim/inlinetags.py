import re
from mock import MockDocument, Cursor, Range, HitDocumentBounds

self_closing_tags = {
    "area", "base", "br", "col", "command", "embed", "hr", "img", "input",
    "keygen", "link", "meta", "param", "source", "track", "wbr",
}

def search(pos, direction, needles, delimiters):
    increment = 1 if direction == 'right' else -1
    initial_pos = pos
    while True:
        if pos.char in needles:
            return pos
        elif pos.char in delimiters and pos != initial_pos:
            return None
        pos = pos.advance_chars(increment)

class NotInTag(Exception):
    pass

class BadSyntax(Exception):
    pass

def get_tag_bounds(pos):
    """
    Given a cursor, if the cursor is within the bounds of a tag, returns two
    cursors to the bounds of that tag. In other case, returns None.
    """
    # Search for '>' to the right
    end_tag_right = search(pos, 'right', ['>'], ['<'])
    # Search for '<' to the left
    start_tag_left = search(pos, 'left', ['<'], ['>'])

    # The cursor is in a tag if it is between '<' and '>'
    if start_tag_left is None or end_tag_right is None:
        raise NotInTag
    else:
        return (start_tag_left, end_tag_right)

def cursor_in_tag(pos):
    try:
        get_tag_bounds(pos)
        return True
    except NotInTag:
        return False

def is_closing_tag(tag_code):
    return re.match(r'^<\s*/', tag_code) is not None

def get_tag_name(tag_code):
    match = re.match(r'^<\s*([^ >]+)', tag_code)
    if match:
        return match.groups()[0]
    else:
        raise BadSyntax

def get_tag_stack_level(tag_code):
    if is_closing_tag(tag_code):
        return -1
    else:
        tag_name = get_tag_name(tag_code)
        if tag_name in self_closing_tags:
            return 0
        else:
            return 1

def find_tag_pair(pos):
    try:
        tag_start, tag_end = get_tag_bounds(pos)
        tag_code = Range(tag_start, tag_end).text
    except NotInTag:
        return None

    if get_tag_stack_level(tag_code) == 1:
        # It is an opening tag, search the closing tag
        stack_size = 1
        after_previous_tag = tag_end.next_char()
        try:
            while True:
                next_tag_start = search(after_previous_tag, 'right', ['<'], [])
                if next_tag_start is None:
                    return None

                next_tag_start, next_tag_end = get_tag_bounds(next_tag_start)
                next_tag_code = Range(next_tag_start, next_tag_end).text
                stack_size += get_tag_stack_level(next_tag_code)

                if stack_size == 0:
                    # Closed the initial item!
                    return next_tag_start, next_tag_end
                else:
                    after_previous_tag = next_tag_end.next_char()
        except HitDocumentBounds:
            return None #exhausted entire document without empting the stack

    elif get_tag_stack_level(tag_code) == 0:
        # This tag can't have a pairing! (eg. <img>)
        return None 

    else:
        # Closing tag, search backwards
        stack_size = -1
        before_prev_tag = tag_start.prev_char()
        try:
            while True:
                prev_tag_start = search(before_prev_tag, 'left', ['>'], [])
                if prev_tag_start is None:
                    return None

                prev_tag_start, prev_tag_end = get_tag_bounds(prev_tag_start)
                prev_tag_code = Range(prev_tag_start, prev_tag_end).text
                stack_size += get_tag_stack_level(prev_tag_code)
                if stack_size == 0:
                    # Closed the initial item!
                    return prev_tag_start, prev_tag_end
                else:
                    before_prev_tag = prev_tag_start.prev_char()
        except HitDocumentBounds:
            return None #exhausted entire document without empting the stack

import unittest
from conversion import pos_to_xy

def TC(code, pos=None):
    """Test cursor"""
    if pos is None:
        pos = code.find('{|}')
        code = code.replace('{|}', '')

    doc = MockDocument(code.split("\n"))

    line, col = pos_to_xy(doc.lines, pos)

    return doc.make_cursor(line, col)

class TestTC(unittest.TestCase):
    def test_tc(self):
        cursor = TC("world", 2)
        self.assertEqual(cursor.line, 0)
        self.assertEqual(cursor.col, 2)
        self.assertEqual(cursor.document.lines, ["world"])

    def test_auto_tc(self):
        cursor = TC("wo{|}rld")
        self.assertEqual(cursor.line, 0)
        self.assertEqual(cursor.col, 2)
        self.assertEqual(cursor.document.lines, ["world"])

    def test_auto_tc_lines(self):
        cursor = TC("foo\nbar{|}\nmiau")
        self.assertEqual(cursor.document.lines, ["foo", "bar", "miau"])
        self.assertEqual((cursor.line, cursor.col), (1, 3))

def cut(string, start, end):
    if end >= start:
        return string[start:end + 1]
    else:
        raise RuntimeError("Not satisfiable")

def cursor(code_with_cursor):
    pos = code_with_cursor.find('{|}')
    return code_with_cursor.replace('{|}', ''), pos


class TestCut(unittest.TestCase):
    def test_cut(self):
        self.assertEqual(cut('012345', 2, 4), '234')
        self.assertEqual(cut('012345', 0, 2), '012')
        self.assertEqual(cut('012345', 3, 3), '3')
        with self.assertRaises(RuntimeError):
            cut('012345', 3, 2)

class TestSearch(unittest.TestCase):
    def test_thing(self):
        self.assertEqual(search(TC('<li></li>', 1), 'right', ['>'], []), (0, 3))
        self.assertEqual(search(TC('<li></li>', 1), 'left', ['<'], []), (0, 0))

class TestInsideTag(unittest.TestCase):
    def test_inside_tag(self):
        self.assertTrue(cursor_in_tag(TC(
            '<li ng-repeat{|}="prod...">Awesome things</li>'
        )))
        self.assertFalse(cursor_in_tag(TC(
            '<li ng-repeat="prod...">Awesome {|}things</li>'
        )))

class TestGetBounds(unittest.TestCase):
    def test_with_opening(self):
        pos = TC('<ul><li class{|}="foo">A precious item</li><li>An unrelated item</li></ul>')

        start, end = get_tag_bounds(pos)
        self.assertEqual(Range(start, end).text, '<li class="foo">')
    
    def test_with_closing(self):
        pos = TC('<ul><li class="foo">A precious item</{|}li><li>An unrelated item</li></ul>')

        start, end = get_tag_bounds(pos)
        self.assertEqual(Range(start, end).text, '</li>')
        self.assertEqual((start.col, end.col), (35, 39))

    def test_with_left_bound(self):
        doc = MockDocument(["<li>"])
        self.assertEqual(get_tag_bounds(doc.make_cursor(0, 0)), ((0,0), (0,3)))

    def test_with_right_bound(self):
        doc = MockDocument(["<li>"])
        self.assertEqual(get_tag_bounds(doc.make_cursor(0, 3)), ((0,0), (0,3)))

class TestIsOpening(unittest.TestCase):
    def test_opening(self):
        self.assertFalse(is_closing_tag('<li class="foo">'))
        self.assertFalse(is_closing_tag('< li  class="foo" >'))

    def test_opening(self):
        self.assertTrue(is_closing_tag('</li>'))
        self.assertTrue(is_closing_tag('</ li>'))
        self.assertTrue(is_closing_tag('< / li>'))

class TestGetPairing(unittest.TestCase):
    def test_opening_li(self):
        pos = TC("""
        <ul>
          <li ng-repeat{|}="prod">{{ prod.name }} ({{ prod.price }})</li>
        </ul>
        """)
        self.assertEqual(Range(*find_tag_pair(pos)).text, '</li>')

    def test_closing_li(self):
        pos = TC("""
        <ul>
          <li ng-repeat="prod">{{ prod.name }} ({{ prod.price }})</l{|}i>
        </ul>
        """)
        self.assertEqual(Range(*find_tag_pair(pos)).text,
                         '<li ng-repeat="prod">')

    def test_opening_ul(self):
        pos = TC("""
        <ul{|}>
          <li ng-repeat="prod">{{ prod.name }} ({{ prod.price }})</li>
        </ul>
        """)
        self.assertEqual(Range(*find_tag_pair(pos)).text, '</ul>')

    def test_closing_ul(self):
        pos = TC("""
        <ul>
          <li ng-repeat="prod">{{ prod.name }} ({{ prod.price }})</li>
        </ul{|}>
        """)
        self.assertEqual(Range(*find_tag_pair(pos)).text, '<ul>')

    def test_closing_ul_left_bound(self):
        pos = TC("""
        <ul>
          <li ng-repeat="prod">{{ prod.name }} ({{ prod.price }})</li>
        {|}</ul>
        """)
        self.assertEqual(Range(*find_tag_pair(pos)).text, '<ul>')

    def test_self_closing_only(self):
        pos = TC('<meta charset="UTF-8"{|}>')
        self.assertIsNone(find_tag_pair(pos))

    def test_self_closing(self):
        pos = TC('<head><meta charset="UTF-8"{|}></head>')
        self.assertIsNone(find_tag_pair(pos))
    

class TestGetTagName(unittest.TestCase):
    def test_names(self):
        self.assertEqual(get_tag_name('<li>'), 'li')
        self.assertEqual(get_tag_name('< li >'), 'li')
        self.assertEqual(get_tag_name('< li class="foo">'), 'li')

    def test_rare_names(self):
        self.assertEqual(get_tag_name('<ng-view>'), "ng-view")

    def test_bad_tag(self):
        with self.assertRaises(BadSyntax):
            get_tag_name('< >')

class TestTagStackLevel(unittest.TestCase):
    def test_tags(self):
        self.assertEqual(get_tag_stack_level('<li>'), 1)
        self.assertEqual(get_tag_stack_level('</li>'), -1)
        self.assertEqual(get_tag_stack_level('<img>'), 0)
        self.assertEqual(get_tag_stack_level('<meta charset="UTF-8">'), 0)
    

if __name__ == "__main__":
    unittest.main()
