from __future__ import annotations
from typing import *
from abc import ABC, ABCMeta
from dataclasses import dataclass, field
import os, sys, json, shutil, re, tty, termios
import time, pprint, datetime
from pathlib import Path, PurePath, PurePosixPath, PureWindowsPath
from enum import Enum, StrEnum, IntEnum
import subprocess, shlex
from math import *
from itertools import *
from functools import *
from builtins import pow  # supports modular powers and integers, unlike math.pow()

try:
    import numpy as np
except ModuleNotFoundError:
    pass
try:
    import pandas as pd
except ModuleNotFoundError:
    pass
try:
    import matplotlib as plt
except ModuleNotFoundError:
    pass
try:
    import requests
except ModuleNotFoundError:
    pass
