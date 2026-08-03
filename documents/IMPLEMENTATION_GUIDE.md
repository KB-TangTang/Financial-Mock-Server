# Financial Mock Server Implementation Guide

이 문서는 금융 목 서버의 1차 API 구현 기준을 설명합니다.

## 핵심 원칙

- 이 서버는 본 서버 DB가 아니라 금융 API 응답을 재현하는 목 서버입니다.
- 기본 구현 전략은 `mock_codef_*` 원천 mock 데이터를 조회해 응답 JSON을 조립하는 방식입니다.
- `mock_api_response_fixture`는 고정 응답, 빈 데이터, 오류, 호출 제한 같은 시나리오 fallback 용도로 사용합니다.
- 기존 본 서버 ERD의 `tbl_*` 테이블을 새로 만들거나 사용하지 않습니다.
- `mock_api_call_log`에는 모든 API 호출 이력을 저장합니다.

## ERD 해석

현재 ERD는 두 영역으로 나뉩니다.

### 1. CODEF 원천 mock 영역

실제 CODEF에서 내려올 법한 금융 데이터를 저장하는 영역입니다. 1차 구현의 기본 응답은 이 영역에서 조회해 조립합니다.

- `mock_user`: 테스트 사용자
- `mock_codef_institution`: 금융기관
- `mock_codef_connection`: 사용자별 CODEF 연결 상태
- `mock_codef_account`: 은행, 증권, 대출, 페이머니 공통 계정
- `mock_codef_transaction`: 계정별 거래내역
- `mock_codef_balance_snapshot`: 잔액 스냅샷
- `mock_codef_stock_holding`: 증권 보유종목
- `mock_codef_loan`: 대출 상세
- `mock_codef_pay_money`: 페이머니 상세

### 2. Fixture 응답 영역

특정 시나리오에 대한 최종 반환 JSON을 저장하는 영역입니다.

- `mock_api_endpoint`: method/path/operation_key 기준 API 목록
- `mock_scenario`: 정상, 빈 데이터, 오류, 호출 제한 등 응답 시나리오
- `mock_api_response_fixture`: 요청 조건과 고정 응답 JSON
- `mock_api_call_log`: API 호출 이력
- `mock_scenario_assignment`: 사용자 또는 endpoint별 시나리오 할당

fixture는 다음 경우에 우선 사용합니다.

- 빈 데이터 응답
- 토큰 만료 응답
- 호출 제한 응답
- 외부 API 실패 응답
- 외부 API 일시 장애 응답
- 특정 화면 시연을 위해 고정해야 하는 응답

## 요청 처리 흐름

1. 요청 method와 path로 `mock_api_endpoint`를 조회합니다.
2. 요청 query parameter 또는 header에서 `scenarioKey`를 가져옵니다.
3. `scenarioKey`가 없으면 `demo-normal-user`를 기본값으로 사용합니다.
4. `scenarioKey`로 `mock_user`를 조회합니다.
5. 오류/빈 데이터 등 특수 시나리오가 지정된 경우 `mock_api_response_fixture`를 조회해 반환합니다.
6. 정상 시나리오인 경우 API별 `mock_codef_*` 테이블을 조회해 응답 JSON을 조립합니다.
7. 응답 후 `mock_api_call_log`에 호출 이력을 저장합니다.

## 응답 생성 전략

### 동적 조립 대상

자주 바뀌거나 시연 중 INSERT/UPDATE가 필요한 데이터는 원천 mock 테이블에서 조회해 응답을 조립합니다.

| API | 조회 기준 테이블 |
| --- | --- |
| `GET /api/v1/assets/accounts` | `mock_codef_account`, `mock_codef_institution`, `mock_codef_balance_snapshot` |
| `GET /api/v1/assets/stocks` | `mock_codef_account`, `mock_codef_stock_holding` |
| `GET /api/v1/assets/loans` | `mock_codef_account`, `mock_codef_loan` |
| `GET /api/v1/assets/payMoney` | `mock_codef_account`, `mock_codef_pay_money` |
| `GET /api/v1/transactions` | `mock_codef_transaction`, `mock_codef_account`, `mock_codef_institution` |

특히 `/api/v1/transactions`는 fixture JSON을 반환하지 않고 `mock_codef_transaction`을 조회해 조립합니다. 시연 중 새 거래를 추가하려면 이 테이블에 `INSERT`하면 됩니다.

### Fixture fallback 대상

다음 응답은 `mock_api_response_fixture.response_json`을 그대로 반환해도 됩니다.

| 시나리오 | 예시 |
| --- | --- |
| `EMPTY_DATA` | 빈 계좌, 빈 거래내역 |
| `TOKEN_EXPIRED` | 인증 토큰 만료 |
| `RATE_LIMITED` | CODEF 호출 제한 |
| `EXTERNAL_API_ERROR` | CODEF 연동 실패 |
| `EXTERNAL_API_UNAVAILABLE` | CODEF 일시 장애 |

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

## 거래내역 구현 규칙

`mock_codef_transaction`은 은행, 증권, 대출, 페이머니 거래를 모두 저장합니다.

거래 조회 시 다음 정보를 함께 조립합니다.

- `accountType`: `mock_codef_account.account_type`
- `accountName`: `mock_codef_account.account_name`
- `bankName` 또는 `institutionName`: `mock_codef_institution.name`
- `transactionAt`: `mock_codef_transaction.transaction_at`
- `merchantName`: `mock_codef_transaction.merchant_name`
- `amount`: `mock_codef_transaction.amount`
- `direction`: `mock_codef_transaction.direction`
- `balanceAfter`: `mock_codef_transaction.balance_after`

월별 조회 조건이 있으면 `transaction_at` 기준으로 필터링합니다.

## 호출 로그 저장

모든 API 호출은 `mock_api_call_log`에 저장합니다.

저장 권장 값:

- `endpoint_id`: 조회된 endpoint ID
- `scenario_id`: 적용된 scenario ID
- `user_id`: scenarioKey로 식별 가능한 사용자 ID
- `response_fixture_id`: fixture를 반환한 경우의 fixture ID, 동적 조립 응답이면 `NULL`
- `request_method`: HTTP method
- `request_path`: 요청 path
- `request_json`: query/body/header 중 매칭에 사용한 요청 정보
- `response_status`: 반환 HTTP status
- `trace_id`: 응답 JSON의 `traceId` 또는 서버에서 생성한 trace ID

## 응답 규칙

모든 응답은 공통 envelope를 따릅니다.

```json
{
  "code": "SUCCESS",
  "message": "조회 성공",
  "data": {},
  "traceId": "generated-trace-id",
  "timestamp": "server-time"
}
```

fixture도 같은 envelope 구조를 가져야 합니다. fixture를 반환하는 경우에는 저장된 `response_json`을 그대로 반환합니다.

데이터가 없는 경우에는 가능한 한 `EMPTY_DATA` fixture를 사용합니다. 매칭되는 fixture도 없으면 다음 형태의 404 envelope를 반환합니다.

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
- 거래내역을 `mock_api_response_fixture.response_json`만 수정하는 방식으로 관리하지 않습니다.
- 실제 CODEF 인증정보, 계좌 원문, 주민번호 등 민감정보를 저장하지 않습니다.
- 원천 mock 데이터나 fixture가 없을 때 임의 데이터를 즉석에서 만들어 반환하지 않습니다.

## 구현 권장 구조

Spring MVC + MyBatis 기준으로 다음 구조를 권장합니다.

```text
controller/
  MockAssetController
  MockTransactionController
  MockCodefController

service/
  MockAssetService
  MockTransactionService
  MockFixtureService
  MockCallLogService

mapper/
  MockAssetMapper
  MockTransactionMapper
  MockFixtureMapper
  MockCallLogMapper

domain/
  MockApiEndpoint
  MockScenario
  MockApiResponseFixture
  MockApiCallLog
  MockCodefAccount
  MockCodefTransaction
```

1차 구현의 중심은 `MockAssetService`, `MockTransactionService`, `MockFixtureService`입니다.

```text
Controller
  -> scenarioKey 확인
  -> 특수 시나리오면 MockFixtureService.findFixture(...)
  -> 정상 시나리오면 MockAssetService 또는 MockTransactionService에서 원천 데이터 조회
  -> 응답 envelope 조립
  -> MockCallLogService.save(...)
```
