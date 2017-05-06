def full_width(text: str) -> str:
    in_char_codes = [ord(c) for c in text]
    # https://en.wikipedia.org/wiki/Halfwidth_and_fullwidth_forms#Block
    ret_char_codes = [
        0xFF00 + (code - 0x20) if 0x20 <= code <= 0x7e else code
        for code in in_char_codes
    ]
    return ''.join(chr(code) for code in ret_char_codes)
