INSERT INTO mock_scenario (
  scenario_code,
  name,
  description,
  http_status,
  app_code,
  latency_ms,
  is_default
) VALUES
  ('NORMAL', '정상 응답', '기본 정상 응답 시나리오', 200, 'SUCCESS', 0, 1),
  ('EMPTY_DATA', '빈 데이터', '계좌 또는 거래내역이 없는 응답 시나리오', 200, 'SUCCESS', 0, 0),
  ('TOKEN_EXPIRED', '토큰 만료', '인증 토큰 만료 오류 시나리오', 401, 'TOKEN_EXPIRED', 0, 0),
  ('RATE_LIMITED', '호출 제한', '외부 API 호출 제한 시나리오', 429, 'RATE_LIMITED', 0, 0),
  ('EXTERNAL_API_ERROR', '외부 API 실패', '외부 API 연동 실패 시나리오', 502, 'EXTERNAL_API_ERROR', 0, 0),
  ('EXTERNAL_API_UNAVAILABLE', '외부 API 일시 장애', '외부 API 일시 장애 시나리오', 503, 'EXTERNAL_API_UNAVAILABLE', 1000, 0)
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  description = VALUES(description),
  http_status = VALUES(http_status),
  app_code = VALUES(app_code),
  latency_ms = VALUES(latency_ms),
  is_default = VALUES(is_default),
  is_active = 1,
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_api_endpoint (
  provider,
  method,
  path,
  operation_key,
  description
) VALUES
  ('INTERNAL', 'GET', '/api/v1/accounts/banks', 'account_bank_list', '연동 지원 금융기관 목록 조회'),
  ('INTERNAL', 'POST', '/api/v1/accounts/verify', 'account_verify', '계좌 본인 인증 요청'),
  ('INTERNAL', 'POST', '/api/v1/accounts', 'account_connect', '연결 계좌 선택 및 등록'),
  ('INTERNAL', 'DELETE', '/api/v1/accounts/{accountId}', 'account_disconnect', '연결 계좌 해제'),
  ('INTERNAL', 'GET', '/api/v1/assets/dashboard', 'asset_dashboard', '자산 대시보드 조회'),
  ('INTERNAL', 'GET', '/api/v1/assets/accounts', 'asset_account_list', '은행 자산 상세 조회'),
  ('INTERNAL', 'GET', '/api/v1/assets/stocks', 'asset_stock_list', '주식 자산 상세 조회'),
  ('INTERNAL', 'GET', '/api/v1/assets/payMoney', 'asset_pay_money_list', '페이머니 상세 조회'),
  ('INTERNAL', 'GET', '/api/v1/assets/loans', 'asset_loan_list', '대출 상세 조회'),
  ('INTERNAL', 'GET', '/api/v1/transactions', 'transaction_list', '거래내역 조회'),
  ('INTERNAL', 'GET', '/api/v1/transactions/monthly', 'transaction_monthly', '월간 거래내역 조회'),
  ('INTERNAL', 'GET', '/api/v1/transactions/search', 'transaction_search', '거래내역 검색'),
  ('INTERNAL', 'PATCH', '/api/v1/transactions/{transactionId}/category', 'transaction_category_update', '거래 카테고리 수정'),
  ('CODEF', 'POST', '/codef/v1/account/list', 'codef_account_list', 'CODEF 계좌 목록 응답 목업'),
  ('CODEF', 'POST', '/codef/v1/account/transactions', 'codef_transaction_list', 'CODEF 거래내역 응답 목업'),
  ('CODEF', 'POST', '/codef/v1/account/balance', 'codef_balance', 'CODEF 잔액 응답 목업')
ON DUPLICATE KEY UPDATE
  provider = VALUES(provider),
  operation_key = VALUES(operation_key),
  description = VALUES(description),
  is_active = 1,
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_user (
  scenario_key,
  nickname,
  email
) VALUES
  ('demo-normal-user', '정상 테스트 사용자', 'normal.user@example.com'),
  ('demo-empty-user', '빈 데이터 테스트 사용자', 'empty.user@example.com')
ON DUPLICATE KEY UPDATE
  nickname = VALUES(nickname),
  email = VALUES(email),
  is_active = 1,
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_institution (
  codef_org_code,
  name,
  type,
  is_supported
) VALUES
  ('0004', '국민은행', 'BANK', 1),
  ('0088', '신한은행', 'BANK', 1),
  ('0020', '우리은행', 'BANK', 1),
  ('0003', '기업은행', 'BANK', 1),
  ('0301', 'KB증권', 'SECURITIES', 1),
  ('PAY_KB', 'KB Pay', 'PAY_MONEY', 1)
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  type = VALUES(type),
  is_supported = VALUES(is_supported),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_connection (
  user_id,
  institution_id,
  connected_id,
  status,
  consent_expired_at,
  last_synced_at
)
SELECT
  u.id,
  i.id,
  'conn-demo-normal-kb',
  'CONNECTED',
  '2027-07-31 23:59:59',
  '2026-07-31 10:30:00'
FROM mock_user u
JOIN mock_codef_institution i ON i.codef_org_code = '0004'
WHERE u.scenario_key = 'demo-normal-user'
ON DUPLICATE KEY UPDATE
  user_id = VALUES(user_id),
  institution_id = VALUES(institution_id),
  status = VALUES(status),
  consent_expired_at = VALUES(consent_expired_at),
  last_synced_at = VALUES(last_synced_at),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_connection (
  user_id,
  institution_id,
  connected_id,
  status,
  consent_expired_at,
  last_synced_at
)
SELECT
  u.id,
  i.id,
  'conn-demo-empty-shinhan',
  'CONNECTED',
  '2027-07-31 23:59:59',
  '2026-07-31 10:30:00'
FROM mock_user u
JOIN mock_codef_institution i ON i.codef_org_code = '0088'
WHERE u.scenario_key = 'demo-empty-user'
ON DUPLICATE KEY UPDATE
  user_id = VALUES(user_id),
  institution_id = VALUES(institution_id),
  status = VALUES(status),
  consent_expired_at = VALUES(consent_expired_at),
  last_synced_at = VALUES(last_synced_at),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_connection (
  user_id,
  institution_id,
  connected_id,
  status,
  consent_expired_at,
  last_synced_at
)
SELECT
  u.id,
  i.id,
  'conn-demo-normal-kbsec',
  'CONNECTED',
  '2027-07-31 23:59:59',
  '2026-07-31 10:30:00'
FROM mock_user u
JOIN mock_codef_institution i ON i.codef_org_code = '0301'
WHERE u.scenario_key = 'demo-normal-user'
ON DUPLICATE KEY UPDATE
  user_id = VALUES(user_id),
  institution_id = VALUES(institution_id),
  status = VALUES(status),
  consent_expired_at = VALUES(consent_expired_at),
  last_synced_at = VALUES(last_synced_at),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_connection (
  user_id,
  institution_id,
  connected_id,
  status,
  consent_expired_at,
  last_synced_at
)
SELECT
  u.id,
  i.id,
  'conn-demo-normal-kbpay',
  'CONNECTED',
  '2027-07-31 23:59:59',
  '2026-07-31 10:30:00'
FROM mock_user u
JOIN mock_codef_institution i ON i.codef_org_code = 'PAY_KB'
WHERE u.scenario_key = 'demo-normal-user'
ON DUPLICATE KEY UPDATE
  user_id = VALUES(user_id),
  institution_id = VALUES(institution_id),
  status = VALUES(status),
  consent_expired_at = VALUES(consent_expired_at),
  last_synced_at = VALUES(last_synced_at),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_account (
  connection_id,
  account_type,
  account_no_masked,
  account_no_encrypted,
  account_name,
  currency,
  status,
  opened_at,
  raw_json
)
SELECT
  c.id,
  'DEPOSIT',
  '123456******7890',
  'mock-encrypted-account-001',
  'KB Star 입출금통장',
  'KRW',
  'ACTIVE',
  '2024-01-15',
  JSON_OBJECT('resAccount', '123456******7890', 'resAccountName', 'KB Star 입출금통장')
FROM mock_codef_connection c
WHERE c.connected_id = 'conn-demo-normal-kb'
ON DUPLICATE KEY UPDATE
  account_name = VALUES(account_name),
  currency = VALUES(currency),
  status = VALUES(status),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_account (
  connection_id,
  account_type,
  account_no_masked,
  account_no_encrypted,
  account_name,
  currency,
  status,
  opened_at,
  raw_json
)
SELECT
  c.id,
  'STOCK',
  '987654******3210',
  'mock-encrypted-account-002',
  'KB증권 종합위탁',
  'KRW',
  'ACTIVE',
  '2025-03-10',
  JSON_OBJECT('resAccount', '987654******3210', 'resAccountName', 'KB증권 종합위탁')
FROM mock_codef_connection c
WHERE c.connected_id = 'conn-demo-normal-kbsec'
ON DUPLICATE KEY UPDATE
  account_name = VALUES(account_name),
  currency = VALUES(currency),
  status = VALUES(status),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_account (
  connection_id,
  account_type,
  account_no_masked,
  account_no_encrypted,
  account_name,
  currency,
  status,
  opened_at,
  raw_json
)
SELECT
  c.id,
  'LOAN',
  '555555******0001',
  'mock-encrypted-account-003',
  'KB 직장인 신용대출',
  'KRW',
  'ACTIVE',
  '2025-02-01',
  JSON_OBJECT('resAccount', '555555******0001', 'resAccountName', 'KB 직장인 신용대출')
FROM mock_codef_connection c
WHERE c.connected_id = 'conn-demo-normal-kb'
ON DUPLICATE KEY UPDATE
  account_name = VALUES(account_name),
  currency = VALUES(currency),
  status = VALUES(status),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_account (
  connection_id,
  account_type,
  account_no_masked,
  account_no_encrypted,
  account_name,
  currency,
  status,
  opened_at,
  raw_json
)
SELECT
  c.id,
  'PAY_MONEY',
  'KB-PAY-WALLET-001',
  'mock-encrypted-account-004',
  'KB Pay 머니',
  'KRW',
  'ACTIVE',
  '2026-01-01',
  JSON_OBJECT('resAccount', 'KB-PAY-WALLET-001', 'resAccountName', 'KB Pay 머니')
FROM mock_codef_connection c
WHERE c.connected_id = 'conn-demo-normal-kbpay'
ON DUPLICATE KEY UPDATE
  account_name = VALUES(account_name),
  currency = VALUES(currency),
  status = VALUES(status),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_balance_snapshot (
  account_id,
  snapshot_at,
  balance,
  available_amount,
  valuation_amount,
  raw_json
)
SELECT
  a.id,
  '2026-07-31 10:30:00',
  1244200.00,
  1244200.00,
  1244200.00,
  JSON_OBJECT('balance', 1244200, 'availableAmount', 1244200)
FROM mock_codef_account a
WHERE a.account_no_masked = '123456******7890'
ON DUPLICATE KEY UPDATE
  balance = VALUES(balance),
  available_amount = VALUES(available_amount),
  valuation_amount = VALUES(valuation_amount),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_stock_holding (
  account_id,
  stock_code,
  stock_name,
  market_country,
  currency,
  quantity,
  average_purchase_price,
  last_price,
  purchase_amount,
  market_value,
  profit_loss_amount,
  profit_loss_rate,
  valuation_at,
  raw_json
)
SELECT
  a.id,
  '005930',
  '삼성전자',
  'KR',
  'KRW',
  12.000000,
  72000.00,
  78500.00,
  864000.00,
  942000.00,
  78000.00,
  9.0278,
  '2026-07-31 10:30:00',
  JSON_OBJECT('stockCode', '005930', 'stockName', '삼성전자')
FROM mock_codef_account a
WHERE a.account_no_masked = '987654******3210'
ON DUPLICATE KEY UPDATE
  stock_name = VALUES(stock_name),
  quantity = VALUES(quantity),
  average_purchase_price = VALUES(average_purchase_price),
  last_price = VALUES(last_price),
  purchase_amount = VALUES(purchase_amount),
  market_value = VALUES(market_value),
  profit_loss_amount = VALUES(profit_loss_amount),
  profit_loss_rate = VALUES(profit_loss_rate),
  valuation_at = VALUES(valuation_at),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_stock_holding (
  account_id,
  stock_code,
  stock_name,
  market_country,
  currency,
  quantity,
  average_purchase_price,
  last_price,
  purchase_amount,
  market_value,
  profit_loss_amount,
  profit_loss_rate,
  valuation_at,
  raw_json
)
SELECT
  a.id,
  '035720',
  '카카오',
  'KR',
  'KRW',
  8.000000,
  48000.00,
  45200.00,
  384000.00,
  361600.00,
  -22400.00,
  -5.8333,
  '2026-07-31 10:30:00',
  JSON_OBJECT('stockCode', '035720', 'stockName', '카카오')
FROM mock_codef_account a
WHERE a.account_no_masked = '987654******3210'
ON DUPLICATE KEY UPDATE
  stock_name = VALUES(stock_name),
  quantity = VALUES(quantity),
  average_purchase_price = VALUES(average_purchase_price),
  last_price = VALUES(last_price),
  purchase_amount = VALUES(purchase_amount),
  market_value = VALUES(market_value),
  profit_loss_amount = VALUES(profit_loss_amount),
  profit_loss_rate = VALUES(profit_loss_rate),
  valuation_at = VALUES(valuation_at),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_loan (
  account_id,
  loan_no_masked,
  loan_no_encrypted,
  loan_name,
  loan_type,
  currency,
  loan_amount,
  balance,
  interest_rate,
  start_date,
  maturity_date,
  monthly_payment,
  next_payment_date,
  raw_json
)
SELECT
  a.id,
  'LN-2025-****-0001',
  'mock-encrypted-loan-001',
  'KB 직장인 신용대출',
  'CREDIT_LOAN',
  'KRW',
  20000000.00,
  14200000.00,
  5.1200,
  '2025-02-01',
  '2028-02-01',
  615000.00,
  '2026-08-01',
  JSON_OBJECT('loanName', 'KB 직장인 신용대출')
FROM mock_codef_account a
WHERE a.account_no_masked = '555555******0001'
ON DUPLICATE KEY UPDATE
  loan_name = VALUES(loan_name),
  loan_type = VALUES(loan_type),
  loan_amount = VALUES(loan_amount),
  balance = VALUES(balance),
  interest_rate = VALUES(interest_rate),
  start_date = VALUES(start_date),
  maturity_date = VALUES(maturity_date),
  monthly_payment = VALUES(monthly_payment),
  next_payment_date = VALUES(next_payment_date),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_pay_money (
  account_id,
  provider_code,
  provider_name,
  wallet_id,
  wallet_name,
  currency,
  balance,
  available_amount,
  point_amount,
  last_synced_at,
  raw_json
)
SELECT
  a.id,
  'KB_PAY',
  'KB Pay',
  'wallet-demo-normal-001',
  'KB Pay 머니',
  'KRW',
  83500.00,
  83500.00,
  1240.00,
  '2026-07-31 10:30:00',
  JSON_OBJECT('providerCode', 'KB_PAY', 'walletName', 'KB Pay 머니')
FROM mock_codef_account a
WHERE a.account_no_masked = 'KB-PAY-WALLET-001'
ON DUPLICATE KEY UPDATE
  provider_name = VALUES(provider_name),
  wallet_id = VALUES(wallet_id),
  wallet_name = VALUES(wallet_name),
  balance = VALUES(balance),
  available_amount = VALUES(available_amount),
  point_amount = VALUES(point_amount),
  last_synced_at = VALUES(last_synced_at),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_transaction (
  account_id,
  codef_tr_key,
  transaction_at,
  merchant_name,
  amount,
  direction,
  balance_after,
  raw_json
)
SELECT a.id, 'tr-demo-20260731-001', '2026-07-31 08:12:00', '스타벅스 강남점', 5800.00, 'WITHDRAW', 1244200.00, JSON_OBJECT('merchantName', '스타벅스 강남점')
FROM mock_codef_account a
WHERE a.account_no_masked = '123456******7890'
ON DUPLICATE KEY UPDATE
  merchant_name = VALUES(merchant_name),
  amount = VALUES(amount),
  direction = VALUES(direction),
  balance_after = VALUES(balance_after),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_transaction (
  account_id,
  codef_tr_key,
  transaction_at,
  merchant_name,
  amount,
  direction,
  balance_after,
  raw_json
)
SELECT a.id, 'tr-demo-20260730-001', '2026-07-30 12:35:00', '쿠팡', 32900.00, 'WITHDRAW', 1250000.00, JSON_OBJECT('merchantName', '쿠팡')
FROM mock_codef_account a
WHERE a.account_no_masked = '123456******7890'
ON DUPLICATE KEY UPDATE
  merchant_name = VALUES(merchant_name),
  amount = VALUES(amount),
  direction = VALUES(direction),
  balance_after = VALUES(balance_after),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_transaction (
  account_id,
  codef_tr_key,
  transaction_at,
  merchant_name,
  amount,
  direction,
  balance_after,
  raw_json
)
SELECT a.id, 'tr-demo-20260725-001', '2026-07-25 09:00:00', '급여', 2500000.00, 'DEPOSIT', 1282900.00, JSON_OBJECT('merchantName', '급여')
FROM mock_codef_account a
WHERE a.account_no_masked = '123456******7890'
ON DUPLICATE KEY UPDATE
  merchant_name = VALUES(merchant_name),
  amount = VALUES(amount),
  direction = VALUES(direction),
  balance_after = VALUES(balance_after),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_transaction (
  account_id,
  codef_tr_key,
  transaction_at,
  merchant_name,
  amount,
  direction,
  balance_after,
  raw_json
)
SELECT a.id, 'tr-demo-20260729-stock-001', '2026-07-29 09:15:00', '삼성전자 매수', 864000.00, 'WITHDRAW', NULL, JSON_OBJECT('merchantName', '삼성전자 매수')
FROM mock_codef_account a
WHERE a.account_no_masked = '987654******3210'
ON DUPLICATE KEY UPDATE
  merchant_name = VALUES(merchant_name),
  amount = VALUES(amount),
  direction = VALUES(direction),
  balance_after = VALUES(balance_after),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_transaction (
  account_id,
  codef_tr_key,
  transaction_at,
  merchant_name,
  amount,
  direction,
  balance_after,
  raw_json
)
SELECT a.id, 'tr-demo-20260715-loan-001', '2026-07-15 09:00:00', '원리금 상환', 615000.00, 'WITHDRAW', 14200000.00, JSON_OBJECT('merchantName', '원리금 상환')
FROM mock_codef_account a
WHERE a.account_no_masked = '555555******0001'
ON DUPLICATE KEY UPDATE
  merchant_name = VALUES(merchant_name),
  amount = VALUES(amount),
  direction = VALUES(direction),
  balance_after = VALUES(balance_after),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_transaction (
  account_id,
  codef_tr_key,
  transaction_at,
  merchant_name,
  amount,
  direction,
  balance_after,
  raw_json
)
SELECT a.id, 'tr-demo-20260730-pay-001', '2026-07-30 20:14:00', 'CU 편의점', 6700.00, 'WITHDRAW', 83500.00, JSON_OBJECT('merchantName', 'CU 편의점')
FROM mock_codef_account a
WHERE a.account_no_masked = 'KB-PAY-WALLET-001'
ON DUPLICATE KEY UPDATE
  merchant_name = VALUES(merchant_name),
  amount = VALUES(amount),
  direction = VALUES(direction),
  balance_after = VALUES(balance_after),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_scenario_assignment (
  user_id,
  scenario_id,
  endpoint_id,
  starts_at,
  ends_at,
  is_active
)
SELECT
  u.id,
  s.id,
  NULL,
  NULL,
  NULL,
  1
FROM mock_user u
JOIN mock_scenario s ON s.scenario_code = 'EMPTY_DATA'
WHERE u.scenario_key = 'demo-empty-user'
  AND NOT EXISTS (
    SELECT 1
    FROM mock_scenario_assignment existing
    WHERE existing.user_id = u.id
      AND existing.scenario_id = s.id
      AND existing.endpoint_id IS NULL
  )
ON DUPLICATE KEY UPDATE
  starts_at = VALUES(starts_at),
  ends_at = VALUES(ends_at),
  is_active = VALUES(is_active),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_api_response_fixture (
  endpoint_id,
  scenario_id,
  fixture_name,
  request_match_json,
  response_json,
  http_status,
  app_code,
  priority
)
SELECT
  e.id,
  s.id,
  CONCAT('empty-', e.operation_key),
  JSON_OBJECT('scenarioKey', 'demo-empty-user'),
  JSON_OBJECT(
    'code', 'SUCCESS',
    'message', '조회 결과가 없습니다.',
    'data', JSON_OBJECT(),
    'traceId', '01J3MOCKEMPTY',
    'timestamp', '2026-07-31T10:30:00+09:00'
  ),
  200,
  'SUCCESS',
  20
FROM mock_api_endpoint e
JOIN mock_scenario s ON s.scenario_code = 'EMPTY_DATA'
WHERE e.operation_key IN (
  'account_bank_list',
  'account_verify',
  'account_connect',
  'account_disconnect',
  'asset_dashboard',
  'asset_account_list',
  'asset_stock_list',
  'asset_pay_money_list',
  'asset_loan_list',
  'transaction_list',
  'transaction_monthly',
  'transaction_search',
  'transaction_category_update',
  'codef_account_list',
  'codef_transaction_list',
  'codef_balance'
)
ON DUPLICATE KEY UPDATE
  request_match_json = VALUES(request_match_json),
  response_json = VALUES(response_json),
  http_status = VALUES(http_status),
  app_code = VALUES(app_code),
  priority = VALUES(priority),
  is_active = 1,
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_api_response_fixture (
  endpoint_id,
  scenario_id,
  fixture_name,
  request_match_json,
  response_json,
  http_status,
  app_code,
  priority
)
SELECT
  e.id,
  s.id,
  'empty-account-list-shaped',
  JSON_OBJECT('scenarioKey', 'demo-empty-user'),
  JSON_OBJECT(
    'code', 'SUCCESS',
    'message', '연결된 계좌가 없습니다.',
    'data', JSON_OBJECT('accounts', JSON_ARRAY()),
    'traceId', '01J3MOCKEMPTYACCOUNT',
    'timestamp', '2026-07-31T10:30:00+09:00'
  ),
  200,
  'SUCCESS',
  5
FROM mock_api_endpoint e
JOIN mock_scenario s ON s.scenario_code = 'EMPTY_DATA'
WHERE e.operation_key = 'asset_account_list'
ON DUPLICATE KEY UPDATE
  request_match_json = VALUES(request_match_json),
  response_json = VALUES(response_json),
  http_status = VALUES(http_status),
  app_code = VALUES(app_code),
  priority = VALUES(priority),
  is_active = 1,
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_api_response_fixture (
  endpoint_id,
  scenario_id,
  fixture_name,
  request_match_json,
  response_json,
  http_status,
  app_code,
  priority
)
SELECT
  e.id,
  s.id,
  'empty-stock-list-shaped',
  JSON_OBJECT('scenarioKey', 'demo-empty-user'),
  JSON_OBJECT(
    'code', 'SUCCESS',
    'message', '보유 주식이 없습니다.',
    'data', JSON_OBJECT(
      'accountId', NULL,
      'accountName', NULL,
      'institutionName', NULL,
      'currency', 'KRW',
      'totalPurchaseAmount', 0,
      'totalMarketValue', 0,
      'totalProfitLossAmount', 0,
      'totalProfitLossRate', 0,
      'holdings', JSON_ARRAY(),
      'lastSyncAt', NULL
    ),
    'traceId', '01J3MOCKEMPTYSTOCK',
    'timestamp', '2026-07-31T10:30:00+09:00'
  ),
  200,
  'SUCCESS',
  5
FROM mock_api_endpoint e
JOIN mock_scenario s ON s.scenario_code = 'EMPTY_DATA'
WHERE e.operation_key = 'asset_stock_list'
ON DUPLICATE KEY UPDATE
  request_match_json = VALUES(request_match_json),
  response_json = VALUES(response_json),
  http_status = VALUES(http_status),
  app_code = VALUES(app_code),
  priority = VALUES(priority),
  is_active = 1,
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_api_response_fixture (
  endpoint_id,
  scenario_id,
  fixture_name,
  request_match_json,
  response_json,
  http_status,
  app_code,
  priority
)
SELECT
  e.id,
  s.id,
  'empty-loan-list-shaped',
  JSON_OBJECT('scenarioKey', 'demo-empty-user'),
  JSON_OBJECT(
    'code', 'SUCCESS',
    'message', '대출 정보가 없습니다.',
    'data', JSON_OBJECT(
      'loans', JSON_ARRAY(),
      'totalLoanAmount', 0,
      'totalBalance', 0,
      'lastSyncAt', NULL
    ),
    'traceId', '01J3MOCKEMPTYLOAN',
    'timestamp', '2026-07-31T10:30:00+09:00'
  ),
  200,
  'SUCCESS',
  5
FROM mock_api_endpoint e
JOIN mock_scenario s ON s.scenario_code = 'EMPTY_DATA'
WHERE e.operation_key = 'asset_loan_list'
ON DUPLICATE KEY UPDATE
  request_match_json = VALUES(request_match_json),
  response_json = VALUES(response_json),
  http_status = VALUES(http_status),
  app_code = VALUES(app_code),
  priority = VALUES(priority),
  is_active = 1,
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_api_response_fixture (
  endpoint_id,
  scenario_id,
  fixture_name,
  request_match_json,
  response_json,
  http_status,
  app_code,
  priority
)
SELECT
  e.id,
  s.id,
  'empty-pay-money-list-shaped',
  JSON_OBJECT('scenarioKey', 'demo-empty-user'),
  JSON_OBJECT(
    'code', 'SUCCESS',
    'message', '페이머니 정보가 없습니다.',
    'data', JSON_OBJECT(
      'payMoney', JSON_ARRAY(),
      'totalBalance', 0,
      'totalPointAmount', 0
    ),
    'traceId', '01J3MOCKEMPTYPAY',
    'timestamp', '2026-07-31T10:30:00+09:00'
  ),
  200,
  'SUCCESS',
  5
FROM mock_api_endpoint e
JOIN mock_scenario s ON s.scenario_code = 'EMPTY_DATA'
WHERE e.operation_key = 'asset_pay_money_list'
ON DUPLICATE KEY UPDATE
  request_match_json = VALUES(request_match_json),
  response_json = VALUES(response_json),
  http_status = VALUES(http_status),
  app_code = VALUES(app_code),
  priority = VALUES(priority),
  is_active = 1,
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_api_response_fixture (
  endpoint_id,
  scenario_id,
  fixture_name,
  request_match_json,
  response_json,
  http_status,
  app_code,
  priority
)
SELECT
  e.id,
  s.id,
  'empty-transaction-list-shaped',
  JSON_OBJECT('scenarioKey', 'demo-empty-user'),
  JSON_OBJECT(
    'code', 'SUCCESS',
    'message', '거래내역이 없습니다.',
    'data', JSON_OBJECT('transactions', JSON_ARRAY()),
    'traceId', '01J3MOCKEMPTYTRX',
    'timestamp', '2026-07-31T10:30:00+09:00'
  ),
  200,
  'SUCCESS',
  5
FROM mock_api_endpoint e
JOIN mock_scenario s ON s.scenario_code = 'EMPTY_DATA'
WHERE e.operation_key = 'transaction_list'
ON DUPLICATE KEY UPDATE
  request_match_json = VALUES(request_match_json),
  response_json = VALUES(response_json),
  http_status = VALUES(http_status),
  app_code = VALUES(app_code),
  priority = VALUES(priority),
  is_active = 1,
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_api_response_fixture (
  endpoint_id,
  scenario_id,
  fixture_name,
  request_match_json,
  response_json,
  http_status,
  app_code,
  priority
)
SELECT
  e.id,
  s.id,
  CONCAT('token-expired-', e.operation_key),
  NULL,
  JSON_OBJECT(
    'code', 'TOKEN_EXPIRED',
    'message', '인증 토큰이 만료되었습니다.',
    'data', NULL,
    'traceId', '01J3MOCKTOKEN',
    'timestamp', '2026-07-31T10:30:00+09:00'
  ),
  401,
  'TOKEN_EXPIRED',
  10
FROM mock_api_endpoint e
JOIN mock_scenario s ON s.scenario_code = 'TOKEN_EXPIRED'
ON DUPLICATE KEY UPDATE
  request_match_json = VALUES(request_match_json),
  response_json = VALUES(response_json),
  http_status = VALUES(http_status),
  app_code = VALUES(app_code),
  priority = VALUES(priority),
  is_active = 1,
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_api_response_fixture (
  endpoint_id,
  scenario_id,
  fixture_name,
  request_match_json,
  response_json,
  http_status,
  app_code,
  priority
)
SELECT
  e.id,
  s.id,
  CONCAT('rate-limited-', e.operation_key),
  NULL,
  JSON_OBJECT(
    'code', 'RATE_LIMITED',
    'message', '외부 API 호출 한도를 초과했습니다.',
    'data', NULL,
    'traceId', '01J3MOCKRATE',
    'timestamp', '2026-07-31T10:30:00+09:00'
  ),
  429,
  'RATE_LIMITED',
  10
FROM mock_api_endpoint e
JOIN mock_scenario s ON s.scenario_code = 'RATE_LIMITED'
ON DUPLICATE KEY UPDATE
  request_match_json = VALUES(request_match_json),
  response_json = VALUES(response_json),
  http_status = VALUES(http_status),
  app_code = VALUES(app_code),
  priority = VALUES(priority),
  is_active = 1,
  updated_at = CURRENT_TIMESTAMP;

