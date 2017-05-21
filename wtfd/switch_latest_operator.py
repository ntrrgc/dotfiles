"""
Implementation of ReactiveX switchLatest() operator with
simple callbacks.
"""
from functools import wraps


class SwitchLatestOperator(object):
    def __init__(self):
        self.latest_index = 0

    """
    Wrap a callback with the switch latest operator.
    
    The returned callback only does something when executed if a 
    newer callback has not been wrapped since then.
    """
    def wrap(self, callback):
        self.latest_index += 1
        returned_callback_index = self.latest_index

        @wraps(callback)
        def returned_callback(*args, **kwargs):
            if returned_callback_index == self.latest_index:
                return callback(*args, **kwargs)

        return returned_callback
