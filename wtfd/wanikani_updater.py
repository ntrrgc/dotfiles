import json
import os
from functools import partial
from time import time

from tornado.httpclient import AsyncHTTPClient
from tornado.ioloop import PeriodicCallback, IOLoop

from wtfd.bar_singleton import bar
from wtfd.debug import debug
from wtfd.switch_latest_operator import SwitchLatestOperator

try:
    api_key = open(os.path.expanduser("~/Dropbox/.wanikani-api-key"), "r").read().strip()
except OSError:
    api_key = None

http_client = AsyncHTTPClient(defaults=dict(user_agent="Wanikani reviews widget"))

switch_latest_study_queue = SwitchLatestOperator()

def read_cached_wanikani_queue():
    try:
        with open("/tmp/.wanikani-update", "r") as f:
            data = json.load(f)
            seconds_old = time() - data["time"]
            if seconds_old < 100:
                return data["response"]
    except OSError:
        return None

def write_cached_wanikani_queue(json_response):
    with open("/tmp/.wanikani-update", "w") as f:
        debug(repr(json_response))
        json.dump({
            "time": time(),
            "response": json_response,
        }, f)

def request_update_wanikani():
    cached_response = read_cached_wanikani_queue()
    if cached_response:
        IOLoop.instance().call_later(0, partial(switch_latest_study_queue.wrap(response_update_wanikani),
                                                cached_response)),
    else:
        http_client.fetch("https://www.wanikani.com/api/user/{api_key}/study-queue".format(api_key=api_key),
                          switch_latest_study_queue.wrap(response_save_cache_update_wanikani))

def response_save_cache_update_wanikani(response):
    if response.error:
        debug("Error requesting Wanikani study queue: %s" % response.error)
        return

    json_response = json.loads(response.body)
    write_cached_wanikani_queue(json_response)
    response_update_wanikani(json_response)

def response_update_wanikani(json_response):
    data = json_response["requested_information"]

    # Note: this requires a clock roughly synchronized with NTP to work correctly
    seconds_next_review = max(0, data["next_review_date"] - time())

    bar.wanikani_reviews = {
        "reviews_available": data["reviews_available"],
        "hours_next_review": seconds_next_review // (60 * 60),
        "minutes_next_review": seconds_next_review % (60 * 60) // 60,
    }
    bar.update()

def start_wanikani_updater():
    # Send first request
    request_update_wanikani()

    # Schedule a new request every now and then
    periodic_callback = PeriodicCallback(request_update_wanikani, 2 * 60 * 1000)  # milliseconds
    periodic_callback.start()
