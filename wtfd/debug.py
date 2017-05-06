import sys


def debug(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)