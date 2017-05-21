import traceback
from functools import wraps

from wtfd.debug import debug


def wrap_traceback(fn):
    @wraps(fn)
    def wrapped_fn(*args, **kwargs):
        # noinspection PyBroadException
        try:
            return fn(*args, **kwargs)
        except:
            debug(traceback.format_exc())

    return wrapped_fn
