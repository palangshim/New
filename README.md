# New 연결 테스트 샘플

Python 3.12 이상으로 실행합니다. 추가 패키지나 비밀 키는 필요하지 않습니다.

```sh
cd /workspace/New
python3 app.py --port 8000
```

다른 터미널에서 확인합니다.

```sh
curl --fail http://127.0.0.1:8000/
curl --fail http://127.0.0.1:8000/health
```

첫 요청은 `연결 성공` 페이지를, 두 번째 요청은
`{"status": "ok", "service": "New"}`를 반환합니다.

서버 종료는 실행 터미널에서 Ctrl+C를 누릅니다.
