import json
import os
from time import time

from tornado.httpclient import AsyncHTTPClient
from tornado.ioloop import PeriodicCallback

from wtfd.bar_singleton import bar
from wtfd.debug import debug
from wtfd.switch_latest_operator import SwitchLatestOperator

try:
    api_key = open(os.path.expanduser("~/Dropbox/.wanikani-api-key"), "r").read().strip()
except OSError:
    api_key = None

http_client = AsyncHTTPClient(defaults=dict(user_agent="Wanikani reviews widget"))

switch_latest_study_queue = SwitchLatestOperator()


def request_update_wanikani():
    http_client.fetch("https://www.wanikani.com/api/user/{api_key}/study-queue".format(api_key=api_key),
                      switch_latest_study_queue.wrap(response_update_wanikani))

def response_update_wanikani(response):
    if response.error:
        debug("Error requesting Wanikani study queue: %s" % response.error)
        return

    data = json.loads(response.body)["requested_information"]

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
