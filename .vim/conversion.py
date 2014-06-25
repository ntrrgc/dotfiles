import unittest

def pos_to_xy(document, pos):
    if pos < 0:
        raise RuntimeError("Not satisfiable")

    chars_up_to_line = 0
    for line_no, line_text in enumerate(document, 0):
        if pos < chars_up_to_line + len(line_text):
            return (line_no, pos - chars_up_to_line)
        elif pos == chars_up_to_line + len(line_text):
            # newline
            return (line_no, len(line_text))
        else:
            chars_up_to_line += len(line_text) + 1 # sum 1 due to \n

    # Exhausted document
    raise RuntimeError("Not satisfiable")


class TestConv(unittest.TestCase):
    def setUp(self):
        self.doc = [
            "AB",
            "CDE",
            "DE"
        ]

    def test_1(self):
        self.assertEqual(pos_to_xy(self.doc, 1), (0,1))
    def test_2(self):
        self.assertEqual(pos_to_xy(self.doc, 2), (0,2))
    def test_3(self):
        self.assertEqual(pos_to_xy(self.doc, 3), (1,0))
    def test_4(self):
        self.assertEqual(pos_to_xy(self.doc, 4), (1,1))


if __name__ == "__main__":
    unittest.main()
