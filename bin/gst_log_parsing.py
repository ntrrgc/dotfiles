import io
import os
import re
import sys
from abc import ABCMeta, abstractmethod
from argparse import ArgumentParser, Namespace
from contextlib import suppress
from enum import Enum, IntEnum
from typing import Optional, Iterable, Union, Callable

from rich.console import Console
from rich.style import Style
from rich.text import Text
from rich.color import Color


class GstLogLevel(IntEnum):
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

rp_color_code = r"\x1b\[(?:[^m]+m|K)"
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
        boundary_column = 6
        boundary = self.re_match.start(boundary_column)
        before = self.original_line[:boundary]
        after = self.original_line[boundary:]
        return before + incision + after

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

    def text_columns(self) -> Iterable[str]:
        yield self.timestamp_str
        yield self.pid_str.rjust(5)
        yield self.thread_str.ljust(14)
        yield self.log_level_str.ljust(7)
        yield self.category.rjust(20)
        yield self.function_context
        yield self.message

    def reformat_as_plain_text(self):
        return " ".join(self.text_columns())


dummy_console = Console(file=io.StringIO(), force_terminal=True, color_system="256")


def rich_text_to_gst_log_text(text: Text):
    with dummy_console.capture() as capture:
        dummy_console.print(text, no_wrap=True, emoji=True, overflow="ignore", crop=False, soft_wrap=False)
    text_with_codes = capture.get()
    return text_with_codes


def rich_text_highlight_regex(text: Text, pattern: Union[str, re.Pattern],
                              format_groups: Iterable[Union[Style, Callable[[str], Style]]]) -> None:
    for match in re.finditer(pattern, text.plain):
        for (index, group), formatter in zip(enumerate(match.groups(), 1), format_groups):
            if group is None:
                continue
            style: Style = formatter(group) if callable(formatter) else formatter
            text.stylize(style, match.start(index), match.end(index))


def is_color_dark(ansi_bg_code: int) -> bool:
    """Return whether a background color is dark enough to need a white foreground."""
    # https://upload.wikimedia.org/wikipedia/commons/1/15/Xterm_256color_chart.svg
    if not hasattr(is_color_dark, "lookup_table"):
        _bg_color_needs_white_fg = {
            # Basic 16 colors
            range(0, 7): True,
            range(7, 8): False,
            range(8, 10): True,
            range(10, 12): False,
            range(12, 14): True,
            range(14, 16): False,

            # Extended 256 color palette
            range(16, 38): True,
            range(38, 52): False,
            range(52, 71): True,
            range(71, 88): False,
            range(88, 106): True,
            range(106, 124): False,
            range(124, 141): True,
            range(141, 160): False,
            range(160, 172): True,
            range(172, 196): False,
            range(196, 205): True,
            range(205, 232): False,
            range(232, 247): True,
            range(247, 256): False,
        }
        lookup_table = {}
        for key_range, needs_white in _bg_color_needs_white_fg.items():
            for color_code in key_range:
                lookup_table[color_code] = needs_white
        for color_code in range(0, 256):
            assert color_code in lookup_table, f"Missing color code in lookup table: {color_code}, lookup_table = {lookup_table}"
        is_color_dark.lookup_table = lookup_table

    return is_color_dark.lookup_table[ansi_bg_code]


dark_foreground = Color.from_ansi(232)
light_foreground = Color.from_ansi(255)


def color_bg_and_fg(ansi_bg_code: int) -> Style:
    if is_color_dark(ansi_bg_code):
        return Style(bgcolor=Color.from_ansi(ansi_bg_code), color=light_foreground)
    else:
        return Style(bgcolor=Color.from_ansi(ansi_bg_code), color=dark_foreground)


class LogProcessingApp(metaclass=ABCMeta):
    description: Optional[str] = None
    epilog: Optional[str] = None

    def __init__(self):
        self.argparse = ArgumentParser(description=self.description, epilog=self.epilog)
        self.configure_argparse(self.argparse)

    def configure_argparse(self, argparse: ArgumentParser):
        argparse.add_argument("input_file", nargs="?", default="-", help="The log to process (defaults to stdin)")
        argparse.add_argument("-o", "--output-file", nargs="?", default="-", help="Where to write the filtered log (defaults to stdout)")

    @abstractmethod
    def process_input_file(self, input_file: io.TextIOBase, output_file: io.TextIOBase, args: Namespace):
        raise NotImplementedError

    def main(self):
        args = self.argparse.parse_args()

        if args.input_file != "-":
            try:
                input_file = open(args.input_file, "r")
            except OSError as err:
                print(f"{self.argparse.prog}: Couldn't open '{args.input_file}' for reading: {err.strerror}")
                raise SystemExit(1)
        else:
            input_file = sys.stdin

        if args.output_file != "-":
            try:
                output_file = open(args.output_file, "w")
            except OSError as err:
                print(f"{self.argparse.prog}: Couldn't open '{args.output_file}' for writing: {err.strerror}")
                raise SystemExit(1)
        else:
            output_file = sys.stdout

        try:
            self.process_input_file(input_file, output_file, args)
        except KeyboardInterrupt:
            # No exception printing on ^C
            pass
        except BrokenPipeError:
            # No exception printing on pipe input being closed (e.g: head -n10 ... | python)
            pass
        finally:
            # Close the input and output files even if they're stdin and stdout.
            # Note that a BrokenPipeError can easily happen in both stdin and stdout. By closing both of them we
            # avoid getting an error like this when closing `less` or other pager:
            # > Exception ignored in: <_io.TextIOWrapper name='<stdout>' mode='w' encoding='utf-8'>
            # > BrokenPipeError: [Errno 32] Broken pipe
            with suppress(BrokenPipeError):
                input_file.close()
            with suppress(BrokenPipeError):
                output_file.close()
