#!/usr/bin/env python3
"""A stand-in for the Ryogami daemon socket, for picker captures and probes.

  ryogami-fake-daemon.py SOCKET SCHEMA_JSON

Answers settings.schema with the dumped schema, settings.get with no user
values (every key at its default) and any other call with an empty object, so
the picker's chrome and settings folio render without the real daemon, which
would apply wallpapers. It never writes anything but its socket.
"""
import json
import os
import socket
import sys
import threading

sock_path, schema_path = sys.argv[1], sys.argv[2]
with open(schema_path, encoding="utf-8") as fh:
    schema = json.load(fh)


def answer(method):
    if method == "settings.schema":
        return schema
    if method == "settings.get":
        return {"values": {}}
    return {}


def serve(conn):
    buf = b""
    with conn:
        while True:
            chunk = conn.recv(65536)
            if not chunk:
                return
            buf += chunk
            while b"\n" in buf:
                line, buf = buf.split(b"\n", 1)
                if not line.strip():
                    continue
                try:
                    req = json.loads(line)
                except ValueError:
                    continue
                if "id" not in req:
                    continue
                reply = {"id": req["id"], "result": answer(req.get("method", ""))}
                conn.sendall(json.dumps(reply).encode() + b"\n")


if os.path.exists(sock_path):
    os.unlink(sock_path)
srv = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
srv.bind(sock_path)
srv.listen(4)
while True:
    c, _ = srv.accept()
    threading.Thread(target=serve, args=(c,), daemon=True).start()
