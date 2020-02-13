# Example:
# pad->parent[@GstElement*]->srcpads[0]->data[@GstObject*]->name
#  -->
# ((GstObject*) ((GstElement*) pad->parent)->srcpads[0]->data)->name
from collections import namedtuple
import gdb

Cast = namedtuple("Cast", ["expr", "dest_type"])
Plain = namedtuple("Plain", ["expr"])


def parse_cast(code):
    pos_type_signature = code.find("[@")
    if pos_type_signature == -1:
        return Plain(code), ""
    expr = code[:pos_type_signature]

    dest_type = ""
    bracket_count = 0
    for i in range(pos_type_signature + 2, len(code)):
        c = code[i]
        if bracket_count == 0 and c == "]":
            tail = code[i + 1:]
            return Cast(expr, dest_type), tail

        if c == "[":
            bracket_count += 1
        elif c == "]":
            bracket_count -= 1

        dest_type += c

    raise RuntimeError("Invalid cast: " + code)


def parse_code(code):
    ast = []

    while len(code) > 0:
        item, code = parse_cast(code)
        ast.append(item)

    return ast


def generate_c(ast):
    code = ""
    for item in ast:
        if isinstance(item, Cast):
            code = "((" + item.dest_type + ") " + code + item.expr + ")"
        else:
            code = code + item.expr
    return code


def transform_cast(code):
    return generate_c(parse_code(code))


class TranslateCasts(gdb.Command):
    def __init__(self):
        super(TranslateCasts, self).__init__("casts", gdb.COMMAND_SUPPORT, gdb.COMPLETE_NONE, True)

    def invoke(self, arg, from_tty):
        print(transform_cast(arg))

TranslateCasts()


class PrintWithCasts(gdb.Command):
    def __init__(self):
        super(PrintWithCasts, self).__init__("pc", gdb.COMMAND_SUPPORT, gdb.COMPLETE_NONE, True)

    def invoke(self, arg, from_tty):
        try:
            gdb.execute("print " + transform_cast(arg))
        except gdb.error as err:
            print(err)

PrintWithCasts()