# Synology에 라이믹스 설치

대상: `/volume1/docker/palangshim/rhymix`

공식 Rhymix 2.1.39 (커밋 6234bfd2bc133286113421e8a525f38a9fa3eaf5), PHP 8.3 Apache, MariaDB 10.11을 사용합니다.
Rhymix 소스 아카이브는 SHA-256을 검증합니다.

## 실행

기존 GitHub 자동 업데이트 작업을 비활성화하세요.
DSM → 제어판 → 작업 스케줄러에서 root 사용자 정의 스크립트 작업을 만들고 아래 내용을 넣으세요.
작업 출력 저장을 활성화하고 저장 후 수동으로 **실행**하세요. 반복 실행할 필요는 없습니다.

```sh
mkdir -p /volume1/docker/palangshim
curl -fLsS --connect-timeout 15 --max-time 60 https://raw.githubusercontent.com/palangshim/New/main/rhymix/install.sh -o /volume1/docker/palangshim/install-rhymix.sh && /bin/sh /volume1/docker/palangshim/install-rhymix.sh
```

첫 빌드는 NAS 성능에 따라 수 분 이상 걸릴 수 있습니다. 완료 후 기존 홈페이지 주소를 열면 라이믹스 설치 화면이 나옵니다.
기존 역방향 프록시가 HTTP 127.0.0.1:18080으로 연결되어 있어야 합니다. 기존 홈페이지가 다른 대상으로 연결되어 있다면 먼저 확인하세요.

DB 설치 입력:

- 종류: MySQL (PDO)
- 호스트: db (localhost가 아님)
- 포트: 3306
- DB 이름: rhymix
- 사용자: rhymix
- 비밀번호: **작업 실행 결과 마지막 부분의 Database password** 값

이후 브라우저에서 관리자 계정을 만들어 설치를 마무리하세요.
DB 비밀번호가 포함된 작업 실행 결과를 다른 사람이나 채팅에 보내지 마세요.
비밀번호는 NAS의 `rhymix/.env`에도 보관됩니다.

## 데이터와 전환

- 웹사이트 파일·첨부파일·설정: `rhymix/www`
- DB 데이터: `rhymix/db`
- DB 비밀번호: `rhymix/.env` (root만 읽도록 설정)
- 기존 `app.py`, `compose.yaml`과 기존 Python 컨테이너는 삭제하지 않습니다.
- DB 준비 후 포트 18080을 쓰는 기존 Python 컨테이너만 확인하여 중지합니다.
- 웹 실행에 실패하면 기존 Python 컨테이너 재시작을 시도합니다.
- 루트 폴더의 `.rhymix-mode`는 기존 Python 자동 업데이트를 차단합니다.
- 성공 후 Container Manager에서 `palangshim-rhymix` 프로젝트/컨테이너를 확인할 수 있습니다.
- 재실행해도 사이트 파일을 덮어쓰거나 DB 비밀번호를 새로 만들지 않습니다.
- 설치 후에는 기존 app.py 수정이 라이믹스에 반영되지 않습니다. 이 저장소에는 설치 구성만 있으며 라이믹스 사이트의 변경은 관리자 화면 또는 www 폴더에서 관리합니다.
- 라이믹스 버전 업그레이드는 별도 작업입니다. Docker 이미지만 재빌드해도 기존 www의 코어 파일을 덮어쓰지는 않습니다.

## 백업·복구

DB와 www, .env를 함께 백업해야 합니다. 실행 중 DB 디렉터리 복사만으로는 일관된 백업이 보장되지 않습니다.
DB 덤프 또는 DB를 중지한 상태의 데이터 백업을 사용하세요. 백업 파일을 GitHub에 올리지 마세요.

이전 샘플로 돌아가려면 먼저 palangshim-rhymix 프로젝트를 중지하고,
기존 Python 컨테이너를 다시 시작하세요. 이후 자동 업데이트도 복구할 경우에만 .rhymix-mode를 지우고 기존 작업을 활성화합니다.
라이믹스 데이터는 삭제할 필요가 없습니다.

## 제한

저장소 구성만으로 NAS 실행이나 브라우저 관리자 계정 생성까지 완료되지는 않습니다.
이 스크립트는 Container Manager를 지원하고 Docker Hub 및 GitHub에 접속할 수 있는 Synology NAS를 전제로 합니다.
포트 충돌, DSM 권한, CPU 아키텍처 등 실제 NAS 환경 문제는 작업 로그로 확인해야 합니다.

## 검증 상태

설치 스크립트의 문법, 모의 배포·재실행·실패 시 기존 앱 복구, Compose 구성 검사를 통과했습니다.
클라우드 테스트 환경의 디스크 부족으로 Docker 이미지 전체 빌드 및 실제 설치 화면 확인은 완료하지 못했습니다.
실제 NAS에서는 작업 실행 결과를 확인해야 합니다.
