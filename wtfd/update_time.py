import datetime

from wtfd.bar_singleton import bar
from wtfd.io_loop import io_loop

"""Feeds bar with the current time and schedules a new time check for the next minute."""
def update_time():
    now = datetime.datetime.now()
    time = now.strftime('%{U#00FF00}%{+u}%a %Y-%m-%d  %H:%M%{-u}')
    bar.time = time
    bar.update()

    seconds_to_next_min = 60 - now.second
    io_loop.call_later(seconds_to_next_min, update_time)