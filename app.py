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
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>안녕하세요 · Palangshim</title>
<style>
* { box-sizing: border-box; }
body { margin: 0; background: #f5f7f2; color: #233c34;
       font-family: system-ui, sans-serif; }
main { max-width: 760px; margin: 0 auto; padding: 64px 24px; }
.brand { font-size: 14px; letter-spacing: 3px; color: #547669; }
h1 { font-size: clamp(32px, 7vw, 52px); margin: 28px 0 16px; }
p { font-size: 18px; line-height: 1.8; color: #54675e; }
svg { display: block; width: 100%; height: auto; margin: 32px 0;
      border-radius: 24px; }
footer { font-size: 13px; color: #687c71; }
</style>
</head>
<body><main>
<div class="brand">PALANGSHIM</div>
<h1>안녕하세요.</h1>
<p>팔랑심 홈페이지에 오신 것을 환영합니다.<br>
잠시 쉬어 가며, 오늘도 기분 좋은 하루 보내세요.</p>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 440"
     role="img" aria-labelledby="landscape-title landscape-desc">
<title id="landscape-title">햇살이 비치는 초록 언덕</title>
<desc id="landscape-desc">따뜻한 해와 구름 아래 초록 언덕과 작은 집이 있는 풍경입니다.</desc>
<rect width="800" height="440" fill="#dceee9"/>
<circle cx="615" cy="105" r="51" fill="#f9ce78"/>
<g fill="#fff" opacity=".8">
<rect x="105" y="87" width="150" height="35" rx="18"/>
<ellipse cx="169" cy="88" rx="41" ry="25"/>
<rect x="370" y="145" width="104" height="26" rx="13"/>
</g>
<path d="M0 295 Q190 125 430 290 T800 245 V440 H0Z" fill="#9fbe9d"/>
<path d="M0 345 Q220 240 450 330 T800 290 V440 H0Z" fill="#638c70"/>
<path d="M0 415 Q285 310 800 405 V440 H0Z" fill="#365f4c"/>
<path d="M405 440 Q430 360 518 318" fill="none" stroke="#e8d9b7" stroke-width="26"/>
<rect x="488" y="257" width="93" height="73" rx="3" fill="#fff3db"/>
<path d="M474 262 L534 211 L594 262Z" fill="#bc795c"/>
<rect x="525" y="284" width="22" height="46" rx="2" fill="#6d826f"/>
<rect x="499" y="279" width="16" height="18" fill="#e6bc6d"/>
<path d="M235 320 V247" stroke="#6d6550" stroke-width="12"/>
<circle cx="235" cy="231" r="43" fill="#47795d"/>
</svg>
<footer>작은 인사로 시작하는, 우리의 새로운 공간.</footer>
</main></body></html>""".encode()
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
