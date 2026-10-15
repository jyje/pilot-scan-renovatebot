<div align="center">

# jyje/pilot-scan-renovatebot

🤖 셀프호스트 Renovate(컨테이너/CLI)로 내 레포를 스캔해 보는 파일럿. GitHub Actions 먼저, 그다음 GitLab CI

[English](README.md) / [한국어](README-ko.md)

</div>

## 개요

[Renovate](https://docs.renovatebot.com/)를 컨테이너 이미지로 직접 돌려, 무료 기능만으로 `jyje/cluster`,
`jyje/pifanctl`, `jyje/mungchilog` 세 레포를 스캔하는 방법을 기록합니다. 레포마다 권장 `renovate.json5`와 그 근거,
gitlab.com에서의 같은 구성을 담았습니다.

사용한 Renovate 버전은 `44.149.2`입니다.

## 결과

권장 설정을 적용하기 전후로 Renovate가 열려는 브랜치 수입니다(드라이런 로그의 고유 브랜치 이름 기준).

| 레포 | 설정 없음 | 권장 설정 | 대시보드 승인 대기 중인 major |
|---|---|---|---|
| [mungchilog](docs/projects/mungchilog.md) | 42 | 24 | 13 |
| [pifanctl](docs/projects/pifanctl.md) | 4 | 2 | 1 |
| [cluster](docs/projects/cluster.md) | 117 | 1 | 1 |

레포별 핵심은 다음과 같습니다.

- **cluster**: `helm/**`에 업스트림 차트가 통째로 들어 있습니다(`values.yaml`만 169개). 이 경로를 제외하면 레포 자체
  워크플로만 남습니다.
- **pifanctl**: 차트 파일을 건드리면서 버전을 올리지 않은 PR은 CI가 실패시킵니다. 테스트용 Dockerfile은 프로젝트 자신의
  이미지를 고정하려 하고, 단순 설정은 CI의 Python 버전만 올립니다. 규칙 세 개로 막습니다.
- **mungchilog**: `dev`만 스캔하고(`stg`/`prd`는 dev에서 승격), non-major는 앱별로 묶고, major는 승인을 기다리게 합니다.

## 진행 상태

| 항목 | 상태 |
|---|---|
| 세 레포의 로컬 컨테이너 드라이런 | 완료 |
| 권장 설정 (`renovate-config-validator` 통과) | 완료 |
| 워크플로 템플릿 (actionlint 통과) | 완료 |
| GitLab: 샘플 프로젝트, 공용 러너 CI 잡, Renovate가 만든 MR | 완료 |
| GitHub: 호스티드 러너에서 컨테이너 실행 (세 레포 드라이런) | 완료 |
| GitHub: 이 레포의 중앙 워크플로, 세 레포의 설정 PR | `jyje-bot` 설치됨, 설정 PR 세 개 모두 머지 ([#112](https://github.com/jyje/mungchilog/pull/112), [#85](https://github.com/jyje/pifanctl/pull/85), [#166](https://github.com/jyje/cluster/pull/166)), 후속 [pifanctl#93](https://github.com/jyje/pifanctl/pull/93) 머지. 중앙 드라이런이 세 레포와 이 레포를 스캔. Dependabot 정리 PR [cluster#168](https://github.com/jyje/cluster/pull/168), [pifanctl#96](https://github.com/jyje/pifanctl/pull/96) 열림 |

## 문서

| | |
|---|---|
| [개요](docs/00-overview.md) | 무료 범위, 실행 방식 |
| [로컬 드라이런](docs/01-local-dry-run.md) | Docker, 로그 읽는 법, 설정 테스트 방법 |
| [GitHub Actions](docs/02-github-action.md) | App, secret, 워크플로, 적용 순서 |
| [GitLab](docs/03-gitlab.md) | 되는 것과 안 되는 것 |
| [스킬 분석](docs/skills-analysis.md) | [jyje/skills](https://github.com/jyje/skills) 중 적용 대상 |
| [권장사항](docs/recommendations.md) | 다음에 할 일, 레포별과 전체 |
| [실험 로그](docs/log.md) | 틀린 추측까지 포함한 날짜별 기록 |

## 실행해 보기

```bash
scripts/dry-run.sh jyje/mungchilog                          # 기본 동작, 아무것도 쓰지 않음
scripts/dry-run.sh jyje/mungchilog projects/mungchilog/renovate.json5
```

레포 설정을 전역 설정으로 테스트할 때의 주의점은 [docs/01-local-dry-run.md](docs/01-local-dry-run.md)를 보세요.
