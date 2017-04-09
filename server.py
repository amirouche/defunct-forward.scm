import os
import sys
import urllib
import argparse

from http.server import BaseHTTPRequestHandler
from http.server import HTTPStatus
from http.server import HTTPServer
from http.server import SimpleHTTPRequestHandler


class MyHTTPRequestHandler(SimpleHTTPRequestHandler):

    def send_head(self):
        """Common code for GET and HEAD commands.

        This sends the response code and MIME headers.

        Return value is either a file object (which has to be copied
        to the outputfile by the caller unless the command was HEAD,
        and must be closed by the caller under all circumstances), or
        None, in which case the caller has nothing further to do.

        """
        if (self.path.startswith('/static')
            or self.path.startswith('/api')
            or self.path == '/forward.scm'
            or self.path == '/main.scm'):
            return super().send_head()
        else:
            self.path = "/"
            return super().send_head()

def test(HandlerClass=BaseHTTPRequestHandler,
         ServerClass=HTTPServer, protocol="HTTP/1.0", port=8000, bind=""):
    """Test the HTTP request handler class.

    This runs an HTTP server on port 8000 (or the port argument).

    """
    server_address = (bind, port)

    HandlerClass.protocol_version = protocol
    httpd = ServerClass(server_address, HandlerClass)

    sa = httpd.socket.getsockname()
    print("Serving HTTP on", sa[0], "port", sa[1], "...")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nKeyboard interrupt received, exiting.")
        httpd.server_close()
        sys.exit(0)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--bind', '-b', default='', metavar='ADDRESS',
                        help='Specify alternate bind address '
                             '[default: all interfaces]')
    parser.add_argument('port', action='store',
                        default=8000, type=int,
                        nargs='?',
                        help='Specify alternate port [default: 8000]')
    args = parser.parse_args()


    handler_class = MyHTTPRequestHandler
    test(HandlerClass=handler_class, port=args.port, bind=args.bind)
