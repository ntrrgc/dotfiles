import fcntl
import os
import subprocess
import sys

from wtfd.io_loop import io_loop
from wtfd.line_buffer import LineBuffer


class ProcessReactor(object):
    def __init__(self, *args, **kwargs):
        kwargs['stdout'] = subprocess.PIPE
        self.process = subprocess.Popen(*args, **kwargs)

        self.fd = self.process.stdout.fileno()
        fl = fcntl.fcntl(self.fd, fcntl.F_GETFL)
        fcntl.fcntl(self.fd, fcntl.F_SETFL, fl | os.O_NONBLOCK)

        io_loop.add_handler(self.process.stdout,
                            self.can_read, io_loop.READ)
        self.line_buffer = LineBuffer()

    def can_read(self, fd, events):
        data = self.process.stdout.read(1024)
        if len(data) > 0:
            self.on_data(data)
        else:
            print('Lost connection to subprocess')
            sys.exit(1)

    def on_data(self, data):
        for line in self.line_buffer.read_lines(data):
            self.on_line(line.decode('UTF-8'))

    def on_line(self, line: str) -> None:
        pass
