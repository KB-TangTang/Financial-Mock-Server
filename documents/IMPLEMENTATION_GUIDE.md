# Financial Mock Server Implementation Guide

이 문서는 금융 목 서버의 1차 API 구현 기준을 설명합니다.

## 핵심 원칙

- 이 서버는 본 서버 DB가 아니라 금융 API 응답을 재현하는 목 서버입니다.
- `mock_api_response_fixture`가 핵심 테이블입니다.
- 초기 구현에서는 `mock_codef_*` 데이터를 조합해서 응답을 만들지 않습니다.
- API는 `mock_api_response_fixture.response_json`을 그대로 반환합니다.
- 기존 본 서버 ERD의 `tbl_*` 테이블을 새로 만들거나 사용하지 않습니다.
- `mock_codef_*` 테이블은 CODEF 원천 데이터를 흉내내는 mock source 데이터입니다.
- `mock_api_call_log`에는 모든 API 호출 이력을 저장합니다.

## ERD 해석

현재 ERD는 두 영역으로 나뉩니다.

### 1. Fixture 응답 영역

API 요청에 대한 최종 반환 JSON을 저장하는 영역입니다.

- `mock_api_endpoint`: method/path/operation_key 기준 API 목록
- `mock_scenario`: 정상, 빈 데이터, 오류, 호출 제한 등 응답 시나리오
- `mock_api_response_fixture`: 요청 조건과 최종 응답 JSON
- `mock_api_call_log`: API 호출 이력
- `mock_scenario_assignment`: 사용자 또는 endpoint별 시나리오 할당

1차 구현은 이 영역만 사용해도 됩니다.

### 2. CODEF 원천 mock 영역

실제 CODEF에서 내려올 법한 금융 데이터를 저장하는 영역입니다.

- `mock_user`: 테스트 사용자
- `mock_codef_institution`: 금융기관
- `mock_codef_connection`: 사용자별 CODEF 연결 상태
- `mock_codef_account`: 은행, 증권, 대출, 페이머니 공통 계정
- `mock_codef_transaction`: 계정별 거래내역
- `mock_codef_balance_snapshot`: 잔액 스냅샷
- `mock_codef_stock_holding`: 증권 보유종목
- `mock_codef_loan`: 대출 상세
- `mock_codef_pay_money`: 페이머니 상세

이 테이블들은 fixture JSON의 근거 데이터입니다. 초기 API 구현에서는 직접 조합하지 않아도 됩니다.

## 요청 처리 흐름

1. 요청 method와 path로 `mock_api_endpoint`를 조회합니다.
2. 요청 query parameter 또는 header에서 `scenarioKey`를 가져옵니다.
3. `scenarioKey`가 없으면 `demo-normal-user`를 기본값으로 사용합니다.
4. `scenarioKey`와 요청 조건을 JSON으로 만들어 `request_match_json`과 매칭합니다.
5. 매칭되는 `mock_api_response_fixture`를 찾습니다.
6. 찾은 fixture의 `response_json`을 그대로 응답합니다.
7. 응답 후 `mock_api_call_log`에 호출 이력을 저장합니다.

## Fixture 매칭 기준

기본 매칭 조건은 `scenarioKey`입니다.

예시:

```json
{
  "scenarioKey": "demo-normal-user"
}
```

거래내역 조회는 월 조건을 함께 사용합니다.

```json
{
  "scenarioKey": "demo-normal-user",
  "yearMonth": "2026-07"
}
```

조회 우선순위:

1. method/path로 endpoint 조회
2. `request_match_json`이 가장 정확히 일치하는 fixture 조회
3. 동일 endpoint/scenario에 여러 fixture가 있으면 `priority`가 낮은 fixture 우선
4. fixture가 없으면 `EMPTY_DATA` fixture 조회
5. 그래도 없으면 404 envelope 반환

## 기본 scenarioKey

- `demo-normal-user`: 은행, 증권, 대출, 페이머니 데이터가 모두 있는 정상 사용자
- `demo-empty-user`: 빈 데이터 응답 테스트 사용자

## 1차 구현 API

- `GET /api/v1/assets/accounts`
- `GET /api/v1/assets/stocks`
- `GET /api/v1/assets/loans`
- `GET /api/v1/assets/payMoney`
- `GET /api/v1/transactions`
- `POST /codef/v1/account/balance`

## API별 operation_key

| API | operation_key |
| --- | --- |
| `GET /api/v1/assets/accounts` | `asset_account_list` |
| `GET /api/v1/assets/stocks` | `asset_stock_list` |
| `GET /api/v1/assets/loans` | `asset_loan_list` |
| `GET /api/v1/assets/payMoney` | `asset_pay_money_list` |
| `GET /api/v1/transactions` | `transaction_list` |
| `POST /codef/v1/account/balance` | `codef_balance` |

## 호출 로그 저장

모든 API 호출은 `mock_api_call_log`에 저장합니다.

저장 권장 값:

- `endpoint_id`: 조회된 endpoint ID
- `scenario_id`: 매칭된 scenario ID
- `user_id`: scenarioKey로 식별 가능한 사용자 ID
- `response_fixture_id`: 반환한 fixture ID
- `request_method`: HTTP method
- `request_path`: 요청 path
- `request_json`: query/body/header 중 매칭에 사용한 요청 정보
- `response_status`: 반환 HTTP status
- `trace_id`: 응답 JSON의 `traceId` 또는 서버에서 생성한 trace ID

## 응답 규칙

fixture의 `response_json`을 그대로 반환합니다.

예시:

```json
{
  "code": "SUCCESS",
  "message": "조회 성공",
  "data": {},
  "traceId": "01J3EXAMPLETRACE",
  "timestamp": "2026-07-31T10:30:00+09:00"
}
```

fixture가 없는 경우에는 다음 형태의 404 envelope를 반환합니다.

```json
{
  "code": "NOT_FOUND",
  "message": "매칭되는 목 응답이 없습니다",
  "data": null,
  "traceId": "generated-trace-id",
  "timestamp": "server-time"
}
```

## 구현 금지 사항

- 기존 본 서버의 `tbl_connected_account`, `tbl_transaction`, `tbl_loan`, `investment_holding` 테이블을 새로 만들지 않습니다.
- 1차 구현에서 `mock_codef_*` 데이터를 조합해 응답 JSON을 동적으로 생성하지 않습니다.
- 실제 CODEF 인증정보, 계좌 원문, 주민번호 등 민감정보를 저장하지 않습니다.
- fixture가 없을 때 임의 데이터를 즉석에서 만들어 반환하지 않습니다.

## 구현 권장 구조

Spring MVC + MyBatis 기준으로 다음 구조를 권장합니다.

```text
controller/
  MockAssetController
  MockTransactionController
  MockCodefController

service/
  MockFixtureService
  MockCallLogService

mapper/
  MockFixtureMapper
  MockCallLogMapper

domain/
  MockApiEndpoint
  MockScenario
  MockApiResponseFixture
  MockApiCallLog
```

1차 구현의 중심은 `MockFixtureService`입니다.

```text
Controller
  -> MockFixtureService.findFixture(method, path, requestCondition)
  -> response_json 반환
  -> MockCallLogService.save(...)
```
