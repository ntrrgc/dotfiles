import re

self_closing_tags = {
    "area", "base", "br", "col", "command", "embed", "hr", "img", "input",
    "keygen", "link", "meta", "param", "source", "track", "wbr",
}

def cut(string, start, end):
    if end >= start:
        return string[start:end + 1]
    else:
        raise RuntimeError("Not satisfiable")

def cursor(code_with_cursor):
    pos = code_with_cursor.find('{|}')
    return code_with_cursor.replace('{|}', ''), pos

def search(code, pos, direction, needles, delimiters):
    increment = 1 if direction == 'right' else -1
    initial_pos = pos
    while True:
        if code[pos] in needles:
            return pos
        elif code[pos] in delimiters and pos != initial_pos:
            return None
        pos += increment

class NotInTag(Exception):
    pass

class BadSyntax(Exception):
    pass

def get_tag_bounds(code, pos):
    # Search for '>' to the right
    end_tag_right = search(code, pos, 'right', ['>'], ['<'])
    # Search for '<' to the left
    start_tag_left = search(code, pos, 'left', ['<'], ['>'])

    # The cursor is in a tag if it is between '<' and '>'
    if start_tag_left is None or end_tag_right is None:
        raise NotInTag
    else:
        return (start_tag_left, end_tag_right)

def cursor_in_tag(code, pos):
    try:
        get_tag_bounds(code, pos)
        return True
    except NotInTag:
        return False

def is_closing_tag(code, start_tag, end_tag):
    return re.match(r'^<\s*/', cut(code, start_tag, end_tag)) is not None

def get_tag_name(code, start_tag, end_tag):
    match = re.match(r'^<\s*(\w+)', cut(code, start_tag, end_tag))
    if match:
        return match.groups()[0]
    else:
        raise BadSyntax

def get_tag_stack_level(code, start_tag, end_tag):
    if is_closing_tag(code, start_tag, end_tag):
        return -1
    else:
        tag_name = get_tag_name(code, start_tag, end_tag)
        if tag_name in self_closing_tags:
            return 0
        else:
            return 1

def find_tag_pair(code, pos):
    try:
        start_tag, end_tag = get_tag_bounds(code, pos)
    except NotInTag:
        return None

    if not is_closing_tag(code, start_tag, end_tag):
        stack_size = 1
        after_previous_tag = end_tag + 1
        while True:
            if after_previous_tag >= len(code):
                return None #exhausted entire document without empting the stack

            next_tag_start = search(code, after_previous_tag, 'right', ['<'], [])
            if next_tag_start is None:
                return None
            next_tag_start, next_tag_end = get_tag_bounds(code, next_tag_start)

            stack_size += get_tag_stack_level(code, next_tag_start,
                                              next_tag_end)
            if stack_size == 0:
                # Closed the initial item!
                return next_tag_start, next_tag_end
            else:
                after_previous_tag = next_tag_end + 1
    elif get_tag_stack_level(code, start_tag, end_tag) == 0:
        # This tag can't have a pairing! (eg. <img>)
        return None 
    else:
        # Closing tag, search backwards
        stack_size = -1
        before_prev_tag = start_tag - 1
        while True:
            if start_tag < 0:
                return None #exhausted entire document without empting the stack

            prev_tag_start = search(code, before_prev_tag, 'left', ['>'], [])
            if prev_tag_start is None:
                return None
            prev_tag_start, prev_tag_end = get_tag_bounds(code, prev_tag_start)

            stack_size += get_tag_stack_level(code, prev_tag_start,
                                              prev_tag_end)
            if stack_size == 0:
                # Closed the initial item!
                return prev_tag_start, prev_tag_end
            else:
                before_prev_tag = prev_tag_start - 1


import unittest

class TestCut(unittest.TestCase):
    def test_cut(self):
        self.assertEqual(cut('012345', 2, 4), '234')
        self.assertEqual(cut('012345', 0, 2), '012')
        self.assertEqual(cut('012345', 3, 3), '3')
        with self.assertRaises(RuntimeError):
            cut('012345', 3, 2)

class TestSearch(unittest.TestCase):
    def test_thing(self):
        self.assertEqual(search('<li></li>', 1, 'right', ['>'], []), 3)
        self.assertEqual(search('<li></li>', 1, 'left', ['<'], []), 0)

class TestInsideTag(unittest.TestCase):
    def test_inside_tag(self):
        self.assertTrue(cursor_in_tag(*cursor(
            '<li ng-repeat{|}="prod...">Awesome things</li>'
        )))
        self.assertFalse(cursor_in_tag(*cursor(
            '<li ng-repeat="prod...">Awesome {|}things</li>'
        )))

class TestGetBounds(unittest.TestCase):
    def test_with_opening(self):
        code_with_cursor = '<ul><li class{|}="foo">A precious item</li><li>An unrelated item</li></ul>'
        code, pos = cursor(code_with_cursor)

        start, end = get_tag_bounds(code, pos)
        self.assertEqual(cut(code, start, end), '<li class="foo">')
    
    def test_with_closing(self):
        code_with_cursor = '<ul><li class="foo">A precious item</{|}li><li>An unrelated item</li></ul>'
        code, pos = cursor(code_with_cursor)
        start, end = get_tag_bounds(code, pos)
        self.assertEqual(cut(code, start, end), '</li>')
        self.assertEqual((start, end), (35, 39))

    def test_with_left_bound(self):
        self.assertEqual(get_tag_bounds('<li>', 0), (0, 3))

    def test_with_right_bound(self):
        self.assertEqual(get_tag_bounds('<li>', 3), (0, 3))

class TestIsOpening(unittest.TestCase):
    def test_opening(self):
        self.assertFalse(is_closing_tag('<li class="foo">', 0, 15))
        self.assertFalse(is_closing_tag('< li  class="foo" >', 0, 18))

    def test_opening(self):
        self.assertTrue(is_closing_tag('</li>', 0, 4))
        self.assertTrue(is_closing_tag('</ li>', 0, 5))
        self.assertTrue(is_closing_tag('< / li>', 0, 6))

class TestGetPairing(unittest.TestCase):
    def test_opening_li(self):
        code_with_cursor = """
        <ul>
          <li ng-repeat{|}="prod">{{ prod.name }} ({{ prod.price }})</li>
        </ul>
        """
        code, pos = cursor(code_with_cursor)
        self.assertEqual(cut(code, *find_tag_pair(code, pos)), '</li>')

    def test_opening_li(self):
        code_with_cursor = """
        <ul>
          <li ng-repeat="prod">{{ prod.name }} ({{ prod.price }})</l{|}i>
        </ul>
        """
        code, pos = cursor(code_with_cursor)
        self.assertEqual(cut(code, *find_tag_pair(code, pos)),
                         '<li ng-repeat="prod">')

    def test_opening_ul(self):
        code_with_cursor = """
        <ul{|}>
          <li ng-repeat="prod">{{ prod.name }} ({{ prod.price }})</li>
        </ul>
        """
        code, pos = cursor(code_with_cursor)
        self.assertEqual(cut(code, *find_tag_pair(code, pos)), '</ul>')

    def test_closing_ul(self):
        code_with_cursor = """
        <ul>
          <li ng-repeat="prod">{{ prod.name }} ({{ prod.price }})</li>
        </ul{|}>
        """
        code, pos = cursor(code_with_cursor)
        self.assertEqual(cut(code, *find_tag_pair(code, pos)), '<ul>')

    def test_closing_ul_left_bound(self):
        code_with_cursor = """
        <ul>
          <li ng-repeat="prod">{{ prod.name }} ({{ prod.price }})</li>
        {|}</ul>
        """
        code, pos = cursor(code_with_cursor)
        self.assertEqual(cut(code, *find_tag_pair(code, pos)), '<ul>')

class TestGetTagName(unittest.TestCase):
    def test_names(self):
        self.assertEqual(get_tag_name('<li>', 0, 3), 'li')
        self.assertEqual(get_tag_name('< li >', 0, 5), 'li')
        self.assertEqual(get_tag_name('< li class="foo">', 0, 16), 'li')

    def test_bad_tag(self):
        with self.assertRaises(BadSyntax):
            get_tag_name('< >', 0, 2)

class TestTagStackLevel(unittest.TestCase):
    def test_tags(self):
        self.assertEqual(get_tag_stack_level('<li>', 0, 3), 1)
        self.assertEqual(get_tag_stack_level('</li>', 0, 3), -1)
        self.assertEqual(get_tag_stack_level('<img>', 0, 4), 0)
    

if __name__ == "__main__":
    unittest.main()
