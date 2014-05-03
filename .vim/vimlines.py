def vim_to_pos(document, line, col):
    line -= 1
    if line < 0 or line >= len(document):
        raise RuntimeError("Not satisfiable")
    pos = 0
    for line_no, line_text in enumerate(document, 0):
        if line == line_no:
            if col >= len(line_text):
                raise RuntimeError("Not satisfiable")
            pos += col
            return pos
        pos += len(line_text) + 1 # +1 due to newline

def pos_to_vim(document, pos):
    if pos < 0:
        raise RuntimeError("Not satisfiable")

    accum = 0
    for line_no, line_text in enumerate(document, 1):
        if accum + len(line_text) > pos:
            if pos - accum == -1:
                raise RuntimeError("Not satisfiable") # pos is a \n
            return line_no, pos - accum
        accum += len(line_text) + 1 # sum 1 due to \n

    # Exhausted document
    raise RuntimeError("Not satisfiable")

import unittest


class TestVimToPos(unittest.TestCase):
    def setUp(self):
        self.doc = [
            "",
            "<ul>",
            "  <li></li>",
            "</ul>",
        ]
        self.text = '\n'.join(self.doc)

    def test_1(self):
        self.assertEqual(self.text[vim_to_pos(self.doc, 2, 0)], '<')
    def test_2(self):
        self.assertEqual(self.text[vim_to_pos(self.doc, 2, 1)], 'u')
    def test_3(self):
        self.assertEqual(self.text[vim_to_pos(self.doc, 2, 3)], '>')
    def test_4(self):
        self.assertEqual(self.text[vim_to_pos(self.doc, 3, 0)], ' ')
    def test_5(self):
        self.assertEqual(self.text[vim_to_pos(self.doc, 3, 2)], '<')
    def test_6(self):
        self.assertEqual(self.text[vim_to_pos(self.doc, 3, 10)], '>')
    def test_7(self):
        self.assertEqual(self.text[vim_to_pos(self.doc, 4, 0)], '<')
    def test_8(self):
        self.assertEqual(self.text[vim_to_pos(self.doc, 4, 4)], '>')

    def test_9(self):
        with self.assertRaises(RuntimeError):
            vim_to_pos(self.doc, 0, 0)
    def test_10(self):
        with self.assertRaises(RuntimeError):
            vim_to_pos(self.doc, 1, 0)
    def test_11(self):
        with self.assertRaises(RuntimeError):
            vim_to_pos(self.doc, 2, 4)
    def test_12(self):
        with self.assertRaises(RuntimeError):
            vim_to_pos(self.doc, 5, 0)


class TestPosToVim(unittest.TestCase):
    def setUp(self):
        self.doc = [
            "",
            "<ul>",
            "  <li></li>",
            "</ul>",
        ]
        self.text = '\n'.join(self.doc)

    def test_1(self):
        self.assertEqual(pos_to_vim(self.doc, 1), (2, 0))
    def test_2(self):
        self.assertEqual(pos_to_vim(self.doc, 2), (2, 1))
    def test_3(self):
        self.assertEqual(pos_to_vim(self.doc, 4), (2, 3))
    def test_4(self):
        self.assertEqual(pos_to_vim(self.doc, 6), (3, 0))
    def test_5(self):
        self.assertEqual(pos_to_vim(self.doc, 22), (4, 4))
    def test_6(self):
        with self.assertRaises(RuntimeError):
            pos_to_vim(self.doc, 23)
    def test_7(self):
        with self.assertRaises(RuntimeError):
            pos_to_vim(self.doc, -1)
    def test_8(self):
        with self.assertRaises(RuntimeError):
            pos_to_vim(self.doc, 5)
    

if __name__ == "__main__":
    unittest.main()
