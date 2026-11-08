"""외부 의존성 없이 실행하는 연결 테스트 서버."""

import argparse
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            body = json.dumps({"status": "ok", "service": "New"}).encode()
            content_type = "application/json; charset=utf-8"
        elif self.path == "/":
            body = """<!doctype html>
<html lang="ko"><meta charset="utf-8"><title>New 연결 테스트</title>
<h1>연결 성공</h1><p>New 샘플 서버가 정상 작동 중입니다.</p>
<a href="/health">서버 상태 확인</a></html>""".encode()
            content_type = "text/html; charset=utf-8"
        else:
            self.send_error(404)
            return
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8000)
    args = parser.parse_args()
    server = ThreadingHTTPServer((args.host, args.port), Handler)
    print(f"Listening on {args.host}:{args.port}", flush=True)
    server.serve_forever()
