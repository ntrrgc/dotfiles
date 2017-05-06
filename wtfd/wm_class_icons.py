# Map of class name to Font-Awesome icon
from typing import Dict, Tuple, Union

class_map: Dict[str, str] = {}

_class_map = {
    ("chrome",
     "google-chrome",
     "google-chrome-stable",
     "google-chrome-unstable",
     "chromium"):
        "\uf268",

    "firefox": "\uf269",

    # yeah, I use all of those
    # Check the classes with xprop |grep WM_CLASS
    ("jetbrains-pychar",
     "jetbrains-webstorm",
     "jetbrains-idea",
     "jetbrains-idea-c",
     "jetbrains-clion",
     "jetbrains-studi",
     "jetbrains-phpstorm",
     "emacs",
     "code",
     "qtcreator"):
        "\uf121",

    "gvim": "\uf27d",
    "teamspeak 3": "\uf0c0",
    "steam": "\uf1b6",
    "": "\uf1bc", #spotify
    ("dolphin", "dolphin4"): "\uf07c",
    "thunderbird": "\uf003",
    "skype": "\uf17e",
    "gajim": "\uf075",
    "clementine": "\uf001",
    ("gnome-terminal",
     "konsole",
     "xterm",
     "termite",
     "terminology",
     "urxvt"):
        "\uf120",
    "okular": "\uf02d",
    "gimp": "\uf1fc",
    "inkscape": "\uf040",
}

def _expand_to_list(item):
    if isinstance(item, tuple):
        return item
    else:
        return (item, )

for keys, value in _class_map.items():
    for key in _expand_to_list(keys):
        assert key == "" or key.islower()
        class_map[key] = value