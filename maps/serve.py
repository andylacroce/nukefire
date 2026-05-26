#!/usr/bin/env python3
"""
NukeFire cartography server.

Serves nukefire_map.html and streams nukefire.map in real time.
Automatically reloads the browser when the map file changes.

Usage:
    python serve.py
    python serve.py 8765       # custom port
"""

import http.server
import socketserver
import os
import sys
import time
import threading
import webbrowser

DIR  = os.path.dirname(os.path.abspath(__file__))
MAP  = os.path.join(DIR, 'nukefire.map')
HTML = os.path.join(DIR, 'nukefire_map.html')
PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8765


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *a, **kw):
        super().__init__(*a, directory=DIR, **kw)

    def do_GET(self):
        if self.path == '/':
            self.send_response(302)
            self.send_header('Location', '/nukefire_map.html')
            self.end_headers()

        elif self.path == '/nukefire_map.html':
            # Always serve fresh — no browser caching
            try:
                data = open(HTML, 'rb').read()
                self.send_response(200)
                self.send_header('Content-Type', 'text/html; charset=utf-8')
                self.send_header('Content-Length', str(len(data)))
                self.send_header('Cache-Control', 'no-store')
                self.end_headers()
                self.wfile.write(data)
            except FileNotFoundError:
                self.send_error(404, 'nukefire_map.html not found')
            except Exception as e:
                self.send_error(500, str(e))

        elif self.path == '/api/map':
            try:
                data = open(MAP, 'rb').read()
                self.send_response(200)
                self.send_header('Content-Type', 'text/plain; charset=utf-8')
                self.send_header('Content-Length', str(len(data)))
                self.send_header('Cache-Control', 'no-store')
                self.end_headers()
                self.wfile.write(data)
            except FileNotFoundError:
                self.send_error(404, 'nukefire.map not found')
            except Exception as e:
                self.send_error(500, str(e))

        elif self.path == '/api/watch':
            # Server-Sent Events stream — fires 'changed' when nukefire.map is modified
            self.send_response(200)
            self.send_header('Content-Type', 'text/event-stream')
            self.send_header('Cache-Control', 'no-cache')
            self.send_header('X-Accel-Buffering', 'no')
            self.end_headers()
            try:
                mtime = os.path.getmtime(MAP)
                self.wfile.write(b': connected\n\n')
                self.wfile.flush()
                while True:
                    time.sleep(1)
                    t = os.path.getmtime(MAP)
                    if t != mtime:
                        mtime = t
                        self.wfile.write(b'data: changed\n\n')
                        self.wfile.flush()
            except (BrokenPipeError, ConnectionResetError, OSError):
                pass  # client disconnected

        else:
            super().do_GET()

    def log_message(self, fmt, *args):
        if args and '/api/watch' in str(args[0]):
            return  # suppress SSE noise
        super().log_message(fmt, *args)


class ThreadedServer(socketserver.ThreadingMixIn, socketserver.TCPServer):
    allow_reuse_address = True
    daemon_threads = True


if __name__ == '__main__':
    url = f'http://localhost:{PORT}/nukefire_map.html'
    print(f'  NukeFire cartography  ->  {url}')
    print(f'  Watching map file     ->  {MAP}')
    print(f'  Press Ctrl+C to stop.\n')
    with ThreadedServer(('', PORT), Handler) as server:
        threading.Timer(0.7, lambda: webbrowser.open(url)).start()
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            print('\nServer stopped.')
