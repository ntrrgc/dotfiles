#!/usr/bin/env python3
# Stack UNIX socket line multiplexer.
#
# Copyright (c) 2017 Alicia Boya García
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import os
import signal
import sys
import traceback
from argparse import ArgumentParser, RawTextHelpFormatter
from socket import socket
from typing import List, Callable, Optional

from tornado import gen
from tornado.ioloop import IOLoop
from tornado.iostream import IOStream, StreamClosedError
from tornado.netutil import add_accept_handler, bind_unix_socket


def debug(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

def print_traceback(fn):
    def wrapped(*args, **kwargs):
        try:
            fn(*args, **kwargs)
        except KeyboardInterrupt:
            raise
        except:
            traceback.print_exc()
            raise
    return wrapped

class PubConnection:
    def __init__(self, mux: "Multiplexer", conn: socket):
        self.mux = mux
        self.conn = conn
        self.stream = IOStream(conn)
        self.current_line: Optional[bytes] = None

    @print_traceback
    @gen.coroutine
    def handle_client(self):
        while True:
            try:
                self.current_line = yield self.stream.read_until(b"\n")
                self.mux.line_updated()
            except StreamClosedError:
                self.mux.pub_conn_lost(self)
                return


class SubConnection:
    def __init__(self, mux: "Multiplexer", conn: socket):
        self.mux = mux
        self.conn = conn
        self.stream = IOStream(conn)
        self.stream.set_close_callback(self.connection_lost)

    @print_traceback
    @gen.coroutine
    def emit(self, line: bytes):
        if not self.stream.closed():
            yield self.stream.write(line)

    @print_traceback
    def connection_lost(self):
        self.mux.sub_conn_lost(self)


class Multiplexer:
    def __init__(self):
        self.pub_connections: "List[PubConnection]" = []
        self.sub_connections: "List[SubConnection]" = []
        self.last_line_published: Optional[bytes] = None

    def get_current_line(self) -> Optional[bytes]:
        for pub in reversed(self.pub_connections):
            if pub.current_line is not None:
                return pub.current_line
        return None

    @print_traceback
    def pub_conn_arrived(self, conn: socket, _):
        pub = PubConnection(self, conn)
        self.pub_connections.append(pub)

        # begin asynchronous processing
        pub.handle_client()

    def pub_conn_lost(self, pub: PubConnection):
        self.pub_connections.remove(pub)
        self.line_updated()

    @print_traceback
    def sub_conn_arrived(self, conn: socket, _):
        sub = SubConnection(self, conn)
        self.sub_connections.append(sub)

        # emit initial value
        if self.last_line_published is not None:
            sub.emit(self.last_line_published)

    def sub_conn_lost(self, sub: SubConnection):
        self.sub_connections.remove(sub)

    def line_updated(self):
        old_line = self.last_line_published
        new_line = self.get_current_line()

        if old_line != new_line:
            self._publish(new_line)

    def _publish(self, new_line):
        self.last_line_published = new_line
        for sub in self.sub_connections:
            sub.emit(new_line if new_line is not None else b"\n")


def start_forking(server_callback: Callable[[], None], pidfile: str = None, no_fork=False):
    if no_fork:
        # Skip all other stuff...
        server_callback()
    else:
        # Time to fork, but before that...

        # Don't make anyone wait
        sys.stdin.close()

        # Don't get killed by your parent
        signal.signal(signal.SIGHUP, signal.SIG_IGN)

        # Don't get killed by ^C
        signal.signal(signal.SIGINT, signal.SIG_IGN)

        pid = os.fork()
        if pid == 0:
            # I'm the child, let's serve all the things
            server_callback()
        else:
            # I'm the parent, write the PID file and return
            if pidfile is not None:
                with open(pidfile, "w") as f:
                    f.write(str(pid))

def main():
    parser = ArgumentParser(formatter_class=RawTextHelpFormatter,
                            description="""
    Stack UNIX socket line multiplexer. 

    This program listens on a UNIX socket where zero or more clients (publishers)
    can connect and send data delimited by the newline character. Each publisher
    has may have a "current line": the last newline delimited string it has send
    to the multiplexer.
    
    The multiplexer also has a global current line, defined as the current line
    of the most recent alive publisher.
    
    Clients of the Subscribe socket (subscribers) receive the current line of
    the multiplexer when they connect and every time it changes.
    
    The current line may be null if there is currently no alive publisher that
    has written a line. In that case new subscriber clients receive no data
    until a line is published later. 
    
    If the current line of the server, while being not null, is later lost due 
    to the disconnection of a publisher, then the subscribers receive a newline
    character.
    
    This program forks: a child keeps working on the background while the parent
    process exits after the socket is bound and listening.
    """.strip())

    parser.add_argument("pub", type=str, help="path to Publish socket file")
    parser.add_argument("sub", type=str, help="path to Subscribe socket file")
    parser.add_argument("--pidfile", "-p", type=str, nargs="?", help="optional PID file")
    parser.add_argument("--no-fork", "-k", default=False, action='store_true',
                        help="run synchronously instead of forking")

    args = parser.parse_args()

    mux = Multiplexer()

    pub_socket = bind_unix_socket(args.pub)
    add_accept_handler(pub_socket, mux.pub_conn_arrived)

    sub_socket = bind_unix_socket(args.sub)
    add_accept_handler(sub_socket, mux.sub_conn_arrived)

    def main_loop():
        try:
            IOLoop.current().start()
        except KeyboardInterrupt:
            pass

    start_forking(main_loop, pidfile=args.pidfile, no_fork=args.no_fork)


if __name__ == '__main__':
    main()
