# GitHub → Synology 자동 업데이트

대상 폴더: `/volume1/docker/palangshim`

DSM 제어판 → 작업 스케줄러 → 생성 → 예약된 작업 → 사용자 정의 스크립트:

- 작업 이름: GitHub 앱 자동 업데이트
- 사용자: root (Container Manager의 Docker 실행 권한 필요)
- 일정: 매일, 반복 간격 1분. 첫 실행~마지막 실행을 하루 전체로 설정.
- 작업 설정 → 사용자 정의 스크립트: 아래 내용을 붙여넣기.

```sh
mkdir -p /volume1/docker/palangshim
curl --fail --location --silent --show-error --connect-timeout 15 --max-time 60 https://raw.githubusercontent.com/palangshim/New/main/synology-auto-update.sh -o /volume1/docker/palangshim/synology-auto-update.sh && /bin/sh /volume1/docker/palangshim/synology-auto-update.sh
```

저장 후 작업을 선택하고 **실행**을 눌러 첫 업데이트를 수행합니다.
작업의 실행 결과/출력을 저장하도록 설정하면 오류를 확인할 수 있습니다.

## 동작과 주의점

- 공개 저장소의 main에서 app.py와 compose.yaml만 가져옵니다. Git 설치나 토큰은 필요 없습니다.
- NAS의 같은 이름 파일은 GitHub 버전으로 교체됩니다. NAS에서 수정한 포트 등은 GitHub compose.yaml에도 먼저 반영하세요.
- 기존 프로젝트가 이 폴더의 compose.yaml로 실행되는 구성을 전제로 합니다. 프로젝트 이름을 별도로 지정해 실행했다면 먼저 확인이 필요합니다.
- 변경이 없으면 컨테이너를 다시 생성하지 않습니다.
- 변경 시 sample 서비스를 다시 생성하므로 잠깐 접속이 끊길 수 있습니다.
- 교체 전 파일은 .github-backups/날짜-시간/ 에 보관합니다. 백업은 자동 삭제하지 않습니다.
- 로컬 /health 응답 성공 후에만 배포 완료로 기록합니다. 실패하면 다음 실행에서 재시도하며 자동 롤백은 하지 않습니다.
- 다른 파일, .env 및 데이터 폴더는 동기화하지 않습니다. 앱 구성이 확장되면 스크립트도 수정해야 합니다.
- DSM이 예기치 않게 꺼지면 .github-update.lock이 남을 수 있습니다. 업데이트가 실행 중이지 않은지 확인한 뒤 해당 빈 디렉터리를 삭제하세요.
- 중단하려면 작업 스케줄러에서 해당 작업을 비활성화하세요. 앱은 계속 실행됩니다.

실제 NAS 연결과 실행은 이 저장소 변경만으로 수행되지 않습니다.
