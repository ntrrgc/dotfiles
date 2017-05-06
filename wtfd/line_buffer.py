class LineBuffer(object):
    def __init__(self):
        self.buffer = b''

    def read_lines(self, input):
        while b'\n' in input:
            before, after = input.split(b'\n', 1)
            yield self.buffer + before

            self.buffer = b''
            input = after
        self.buffer += input