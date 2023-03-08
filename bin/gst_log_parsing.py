import re
from enum import Enum
from typing import Optional

class GstLogLevel(Enum):
    """GStreamer log levels from:
    https://gstreamer.freedesktop.org/documentation/tutorials/basic/debugging-tools.html"""
    none = 0
    ERROR = 1
    WARNING = 2
    FIXME = 3
    INFO = 4
    DEBUG = 5
    LOG = 6
    TRACE = 7
    MEMDUMP = 9

rp_color_code = r"\x1b\[[^m]+m"
rp_any_color_codes = r"(?:" + rp_color_code + ")*"
rp_any_color_codes_or_whitespace = r"(?:" + rp_color_code + "|\s+)*"
rp_column_spacer = rp_any_color_codes + r"\s+" + rp_any_color_codes_or_whitespace

rp_capture_column_time = r"(\d+:\d\d:\d\d\.\d{9})"
rp_capture_column_integer = r"(\d+)"
rp_capture_column_pointer = r"(0x[a-fA-F0-9]+)"
rp_capture_column_log_level = r"(" + "|".join(level.name for level in GstLogLevel if level.name != "none") + ")"
rp_capture_column_no_whitespace = r"([^\s\x1b]+)"
rp_capture_column_rest = r"(.*)"
rp_capture_columns = [
    rp_capture_column_time,
    rp_capture_column_integer,  # PID
    rp_capture_column_pointer,  # thread ID
    rp_capture_column_log_level,
    rp_capture_column_no_whitespace,  # category
    rp_capture_column_no_whitespace,  # function context
    rp_capture_column_rest,
]
rp_log_line = rp_any_color_codes + rp_column_spacer.join(rp_capture_columns) + r"\n*"
re_log_line = re.compile(rp_log_line)

class GstLogEntry:
    def __init__(self, re_match: re.Match):
        self.re_match = re_match

        # Sanity checks:
        assert re_match is not None
        assert self.message is not None
        assert type(self.pid) == int
        assert type(self.timestamp_ns) == int
        assert type(self.log_level) == GstLogLevel

    @staticmethod
    def parse(line: str) -> Optional['GstLogEntry']:
        if match := re_log_line.match(line):
            return GstLogEntry(match)

    @property
    def original_line(self) -> str:
        """Return the original matched line. Color codes, if any, will be included."""
        return self.re_match.group()

    def original_line_with_incision(self, incision: str) -> str:
        """Return a version of the original line that has been modified to include a certain string immediately before
        the function context column. This is the last point where all columns' width visually matches."""
        boundary_column = 5
        return self.original_line_cropped(end_column=boundary_column) + incision + \
               self.original_line_cropped(start_column=boundary_column + 1)

    def original_line_cropped(self, start_column: Optional[int] = None, end_column: Optional[int] = None):
        """Return the original line, optionally cropping some columns. Column numbers start at 1 and they're the capture
        groups in the regex. end_column is inclusive."""
        start = 0 if start_column is None else self.re_match.start(start_column)
        end = None if end_column is None else self.re_match.end(end_column)
        return self.original_line[start:end]

    @property
    def timestamp_str(self) -> str:    return self.re_match.group(1)
    @property
    def pid_str(self) -> str:          return self.re_match.group(2)
    @property
    def thread_str(self) -> str:       return self.re_match.group(3)
    @property
    def log_level_str(self) -> str:    return self.re_match.group(4)
    @property
    def category(self) -> str:         return self.re_match.group(5)
    @property
    def function_context(self) -> str: return self.re_match.group(6)
    @property
    def message(self) -> str:          return self.re_match.group(7)

    @property
    def pid(self) -> int:
        return int(self.pid_str)
    @property
    def timestamp_ns(self) -> int:
        return int(self.timestamp_str.replace(":", "").replace(".", ""), 10)
    @property
    def log_level(self) -> GstLogLevel:
        return GstLogLevel[self.log_level_str]
