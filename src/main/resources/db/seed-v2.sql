USE financial_mock;

INSERT INTO mock_scenario (
  scenario_code, name, description, http_status, app_code, latency_ms, is_default
) VALUES
  ('NORMAL', '정상 응답', '기본 정상 응답 시나리오', 200, 'SUCCESS', 0, 1),
  ('EMPTY_DATA', '빈 데이터', '원천 데이터가 없는 응답 시나리오', 200, 'SUCCESS', 0, 0),
  ('TOKEN_EXPIRED', '토큰 만료', '인증 토큰 만료 오류 시나리오', 401, 'TOKEN_EXPIRED', 0, 0),
  ('RATE_LIMITED', '호출 제한', '외부 API 호출 제한 시나리오', 429, 'RATE_LIMITED', 0, 0)
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
  provider, method, path, operation_key, description
) VALUES
  ('INTERNAL', 'GET', '/api/v1/accounts/banks', 'account_bank_list', '연동 지원 금융기관 목록 조회'),
  ('INTERNAL', 'POST', '/api/v1/accounts/verify', 'account_verify', '계좌 본인 인증 요청'),
  ('INTERNAL', 'POST', '/api/v1/accounts', 'account_connect', '연결 계좌 선택 및 등록'),
  ('INTERNAL', 'DELETE', '/api/v1/accounts/{accountId}', 'account_disconnect', '연결 계좌 해제'),
  ('INTERNAL', 'GET', '/api/v1/assets/dashboard', 'asset_dashboard', '자산 대시보드 조회'),
  ('INTERNAL', 'GET', '/api/v1/assets/accounts', 'asset_account_list', '은행 계좌 원천 조회'),
  ('INTERNAL', 'GET', '/api/v1/assets/stocks', 'asset_stock_list', '증권 계좌/보유 원천 조회'),
  ('INTERNAL', 'GET', '/api/v1/assets/payMoney', 'asset_pay_money_list', '구버전 호환용 빈 페이머니 조회'),
  ('INTERNAL', 'GET', '/api/v1/assets/loans', 'asset_loan_list', '대출 계좌 원천 조회'),
  ('INTERNAL', 'GET', '/api/v1/accounts/{accountId}/transactions', 'bank_transaction_list', '은행 입출금 원천 내역 조회'),
  ('INTERNAL', 'GET', '/api/v1/cards', 'card_list', '카드 원천 목록 조회'),
  ('INTERNAL', 'GET', '/api/v1/cards/{cardId}/approvals', 'card_approval_list', '카드 승인 원천 내역 조회'),
  ('CODEF', 'POST', '/codef/v1/account/list', 'codef_account_list', '기존 CODEF 계좌 목록 URL 호환'),
  ('CODEF', 'POST', '/codef/v1/account/balance', 'codef_balance', '은행 계좌 잔액 원천 응답 목업')
ON DUPLICATE KEY UPDATE
  provider = VALUES(provider),
  operation_key = VALUES(operation_key),
  description = VALUES(description),
  is_active = 1,
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_user (scenario_key, nickname, email) VALUES
  ('demo-normal-user', '정상 테스트 사용자', 'normal.user@example.com'),
  ('demo-empty-user', '빈 데이터 테스트 사용자', 'empty.user@example.com')
ON DUPLICATE KEY UPDATE
  nickname = VALUES(nickname),
  email = VALUES(email),
  is_active = 1,
  updated_at = CURRENT_TIMESTAMP;

UPDATE mock_api_endpoint
SET is_active = 0,
    updated_at = CURRENT_TIMESTAMP
WHERE operation_key IN (
  'transaction_list',
  'transaction_monthly',
  'transaction_search',
  'transaction_category_update',
  'codef_transaction_list'
);

INSERT INTO financial_institution (
  institution_code, institution_name, institution_type_code, is_supported
) VALUES
  ('0004', '국민은행', 'BANK', 1),
  ('0088', '신한은행', 'BANK', 1),
  ('0301', 'KB증권', 'SECURITIES', 1),
  ('0101', 'KB국민카드', 'CARD', 1)
ON DUPLICATE KEY UPDATE
  institution_name = VALUES(institution_name),
  institution_type_code = VALUES(institution_type_code),
  is_supported = VALUES(is_supported),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO bank_account (
  user_id, institution_id, account_no_masked, product_name, account_type_code,
  account_status_code, currency, balance, available_amount, opened_at, last_synced_at, raw_json
)
SELECT
  u.id, i.id, '123456******7890', 'KB Star 입출금통장', '1001',
  '01', 'KRW', 1244200.00, 1244200.00, '2024-01-15', '2026-07-31 10:30:00',
  JSON_OBJECT('resAccount', '123456******7890', 'resAccountName', 'KB Star 입출금통장', 'resAccountType', '1001')
FROM mock_user u
JOIN financial_institution i ON i.institution_code = '0004'
WHERE u.scenario_key = 'demo-normal-user'
ON DUPLICATE KEY UPDATE
  product_name = VALUES(product_name),
  account_type_code = VALUES(account_type_code),
  account_status_code = VALUES(account_status_code),
  balance = VALUES(balance),
  available_amount = VALUES(available_amount),
  last_synced_at = VALUES(last_synced_at),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO bank_transaction (
  bank_account_id, original_transaction_id, transacted_at, trans_type_code,
  trans_type_name, amount, balance_after, description, raw_json
)
SELECT id, 'BANK-20260731-001', '2026-07-31 08:12:00', '02',
       '출금', 5800.00, 1244200.00, '스타벅스 강남점',
       JSON_OBJECT('resAccountTrType', '02', 'resAccountDesc', '스타벅스 강남점')
FROM bank_account
WHERE account_no_masked = '123456******7890'
ON DUPLICATE KEY UPDATE
  trans_type_code = VALUES(trans_type_code),
  trans_type_name = VALUES(trans_type_name),
  amount = VALUES(amount),
  balance_after = VALUES(balance_after),
  description = VALUES(description),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO bank_transaction (
  bank_account_id, original_transaction_id, transacted_at, trans_type_code,
  trans_type_name, amount, balance_after, description, raw_json
)
SELECT id, 'BANK-20260725-001', '2026-07-25 09:00:00', '01',
       '입금', 2500000.00, 1282900.00, '급여',
       JSON_OBJECT('resAccountTrType', '01', 'resAccountDesc', '급여')
FROM bank_account
WHERE account_no_masked = '123456******7890'
ON DUPLICATE KEY UPDATE
  trans_type_code = VALUES(trans_type_code),
  trans_type_name = VALUES(trans_type_name),
  amount = VALUES(amount),
  balance_after = VALUES(balance_after),
  description = VALUES(description),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO card (
  user_id, institution_id, card_no_masked, product_name, card_product_code,
  card_type_code, card_status_code, currency, issued_at, last_synced_at, raw_json
)
SELECT
  u.id, i.id, '5555-****-****-1234', 'KB국민 탄탄대로 올쇼핑카드', 'KB-CARD-001',
  '01', '01', 'KRW', '2025-04-01', '2026-07-31 10:30:00',
  JSON_OBJECT('resCardNo', '5555-****-****-1234', 'resCardName', 'KB국민 탄탄대로 올쇼핑카드')
FROM mock_user u
JOIN financial_institution i ON i.institution_code = '0101'
WHERE u.scenario_key = 'demo-normal-user'
ON DUPLICATE KEY UPDATE
  product_name = VALUES(product_name),
  card_product_code = VALUES(card_product_code),
  card_type_code = VALUES(card_type_code),
  card_status_code = VALUES(card_status_code),
  last_synced_at = VALUES(last_synced_at),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO card_approval (
  card_id, approval_no, approved_at, approval_type_code, approval_type_name,
  merchant_name, merchant_business_no, approved_amount, currency, description, raw_json
)
SELECT id, 'APV-20260730-001', '2026-07-30 12:35:00', '01', '승인',
       '쿠팡', '120-88-00767', 32900.00, 'KRW', '일시불 승인',
       JSON_OBJECT('resApprovalType', '01', 'resMemberStoreName', '쿠팡')
FROM card
WHERE card_no_masked = '5555-****-****-1234'
ON DUPLICATE KEY UPDATE
  approval_type_code = VALUES(approval_type_code),
  approval_type_name = VALUES(approval_type_name),
  merchant_name = VALUES(merchant_name),
  merchant_business_no = VALUES(merchant_business_no),
  approved_amount = VALUES(approved_amount),
  description = VALUES(description),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO card_bill (
  card_id, billing_month, due_date, bill_status_code, bill_status_name, total_amount, paid_amount, raw_json
)
SELECT id, '2026-07-01', '2026-08-14', '01', '청구확정', 483200.00, 0.00,
       JSON_OBJECT('resUsedMonth', '202607', 'resPaymentDueDate', '20260814')
FROM card
WHERE card_no_masked = '5555-****-****-1234'
ON DUPLICATE KEY UPDATE
  due_date = VALUES(due_date),
  bill_status_code = VALUES(bill_status_code),
  bill_status_name = VALUES(bill_status_name),
  total_amount = VALUES(total_amount),
  paid_amount = VALUES(paid_amount),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO deposit_account (
  user_id, institution_id, account_no_masked, product_name, deposit_type_code,
  account_status_code, currency, principal, balance, interest_rate, opened_at, maturity_date, last_synced_at, raw_json
)
SELECT
  u.id, i.id, '777777******0001', 'KB 정기예금', '2001',
  '01', 'KRW', 5000000.00, 5032000.00, 3.2500, '2026-01-01', '2027-01-01', '2026-07-31 10:30:00',
  JSON_OBJECT('resAccountName', 'KB 정기예금', 'resAccountType', '2001')
FROM mock_user u
JOIN financial_institution i ON i.institution_code = '0004'
WHERE u.scenario_key = 'demo-normal-user'
ON DUPLICATE KEY UPDATE
  product_name = VALUES(product_name),
  deposit_type_code = VALUES(deposit_type_code),
  principal = VALUES(principal),
  balance = VALUES(balance),
  interest_rate = VALUES(interest_rate),
  maturity_date = VALUES(maturity_date),
  last_synced_at = VALUES(last_synced_at),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO deposit_transaction (
  deposit_account_id, original_transaction_id, transacted_at, trans_type_code,
  trans_type_name, amount, balance_after, description, raw_json
)
SELECT id, 'DEP-20260701-001', '2026-07-01 00:00:00', '03',
       '이자', 32000.00, 5032000.00, '정기예금 이자',
       JSON_OBJECT('resAccountTrType', '03', 'resAccountDesc', '정기예금 이자')
FROM deposit_account
WHERE account_no_masked = '777777******0001'
ON DUPLICATE KEY UPDATE
  amount = VALUES(amount),
  balance_after = VALUES(balance_after),
  description = VALUES(description),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO loan_account (
  user_id, institution_id, loan_no_masked, product_name, account_type_code,
  account_status_code, repayment_method_code, currency, principal, outstanding_balance,
  interest_rate, start_date, maturity_date, monthly_payment, next_payment_date, last_synced_at, raw_json
)
SELECT
  u.id, i.id, 'LN-2025-****-0001', 'KB 직장인 신용대출', '3001',
  '01', '01', 'KRW', 20000000.00, 14200000.00,
  5.1200, '2025-02-01', '2028-02-01', 615000.00, '2026-08-01', '2026-07-31 10:30:00',
  JSON_OBJECT('resLoanName', 'KB 직장인 신용대출', 'resAccountType', '3001')
FROM mock_user u
JOIN financial_institution i ON i.institution_code = '0004'
WHERE u.scenario_key = 'demo-normal-user'
ON DUPLICATE KEY UPDATE
  product_name = VALUES(product_name),
  account_type_code = VALUES(account_type_code),
  repayment_method_code = VALUES(repayment_method_code),
  principal = VALUES(principal),
  outstanding_balance = VALUES(outstanding_balance),
  interest_rate = VALUES(interest_rate),
  maturity_date = VALUES(maturity_date),
  monthly_payment = VALUES(monthly_payment),
  next_payment_date = VALUES(next_payment_date),
  last_synced_at = VALUES(last_synced_at),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO loan_transaction (
  loan_account_id, original_transaction_id, transacted_at, trans_type_code,
  trans_type_name, amount, principal_amount, interest_amount, balance_after, description, raw_json
)
SELECT id, 'LOAN-20260715-001', '2026-07-15 09:00:00', '02',
       '상환', 615000.00, 554000.00, 61000.00, 14200000.00, '원리금 상환',
       JSON_OBJECT('resLoanTrType', '02', 'resAccountDesc', '원리금 상환')
FROM loan_account
WHERE loan_no_masked = 'LN-2025-****-0001'
ON DUPLICATE KEY UPDATE
  amount = VALUES(amount),
  principal_amount = VALUES(principal_amount),
  interest_amount = VALUES(interest_amount),
  balance_after = VALUES(balance_after),
  description = VALUES(description),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO securities_account (
  user_id, institution_id, account_no_masked, product_name, account_type_code,
  account_status_code, currency, cash_balance, valuation_amount, last_synced_at, raw_json
)
SELECT
  u.id, i.id, '987654******3210', 'KB증권 종합위탁', '4001',
  '01', 'KRW', 120000.00, 1303600.00, '2026-07-31 10:30:00',
  JSON_OBJECT('resAccount', '987654******3210', 'resAccountName', 'KB증권 종합위탁')
FROM mock_user u
JOIN financial_institution i ON i.institution_code = '0301'
WHERE u.scenario_key = 'demo-normal-user'
ON DUPLICATE KEY UPDATE
  product_name = VALUES(product_name),
  account_type_code = VALUES(account_type_code),
  cash_balance = VALUES(cash_balance),
  valuation_amount = VALUES(valuation_amount),
  last_synced_at = VALUES(last_synced_at),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO securities_holding (
  securities_account_id, product_code, product_name, market_country_code, currency,
  quantity, average_purchase_price, last_price, purchase_amount, market_value,
  profit_loss_amount, profit_loss_rate, valuation_at, raw_json
)
SELECT id, '005930', '삼성전자', 'KR', 'KRW',
       12.000000, 72000.00, 78500.00, 864000.00, 942000.00,
       78000.00, 9.0278, '2026-07-31 10:30:00',
       JSON_OBJECT('isuCd', '005930', 'isuKorNm', '삼성전자')
FROM securities_account
WHERE account_no_masked = '987654******3210'
ON DUPLICATE KEY UPDATE
  product_name = VALUES(product_name),
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

INSERT INTO securities_holding (
  securities_account_id, product_code, product_name, market_country_code, currency,
  quantity, average_purchase_price, last_price, purchase_amount, market_value,
  profit_loss_amount, profit_loss_rate, valuation_at, raw_json
)
SELECT id, '035720', '카카오', 'KR', 'KRW',
       8.000000, 48000.00, 45200.00, 384000.00, 361600.00,
       -22400.00, -5.8333, '2026-07-31 10:30:00',
       JSON_OBJECT('isuCd', '035720', 'isuKorNm', '카카오')
FROM securities_account
WHERE account_no_masked = '987654******3210'
ON DUPLICATE KEY UPDATE
  product_name = VALUES(product_name),
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

INSERT INTO securities_transaction (
  securities_account_id, original_transaction_id, transacted_at, trans_type_code,
  trans_type_name, product_code, product_name, quantity, unit_price, transaction_amount, description, raw_json
)
SELECT id, 'SEC-20260729-001', '2026-07-29 09:15:00', '01',
       '매수', '005930', '삼성전자', 12.000000, 72000.00, 864000.00, '삼성전자 매수',
       JSON_OBJECT('trType', '01', 'isuCd', '005930', 'isuKorNm', '삼성전자')
FROM securities_account
WHERE account_no_masked = '987654******3210'
ON DUPLICATE KEY UPDATE
  trans_type_code = VALUES(trans_type_code),
  trans_type_name = VALUES(trans_type_name),
  product_code = VALUES(product_code),
  product_name = VALUES(product_name),
  quantity = VALUES(quantity),
  unit_price = VALUES(unit_price),
  transaction_amount = VALUES(transaction_amount),
  description = VALUES(description),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_scenario_assignment (
  user_id, scenario_id, endpoint_id, starts_at, ends_at, is_active
)
SELECT u.id, s.id, NULL, NULL, NULL, 1
FROM mock_user u
JOIN mock_scenario s ON s.scenario_code = 'EMPTY_DATA'
WHERE u.scenario_key = 'demo-empty-user'
ON DUPLICATE KEY UPDATE
  is_active = VALUES(is_active),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_api_response_fixture (
  endpoint_id, scenario_id, fixture_name, request_match_json, response_json, http_status, app_code, priority
)
SELECT
  e.id,
  s.id,
  CONCAT('empty-', e.operation_key),
  JSON_OBJECT('scenarioKey', 'demo-empty-user'),
  JSON_OBJECT('code', 'SUCCESS', 'message', '조회 결과가 없습니다.', 'data', JSON_OBJECT(), 'traceId', '01J3MOCKEMPTY', 'timestamp', '2026-07-31T10:30:00+09:00'),
  200,
  'SUCCESS',
  20
FROM mock_api_endpoint e
JOIN mock_scenario s ON s.scenario_code = 'EMPTY_DATA'
WHERE e.operation_key IN (
  'asset_account_list',
  'asset_stock_list',
  'asset_loan_list',
  'asset_pay_money_list',
  'bank_transaction_list',
  'card_list',
  'card_approval_list',
  'codef_account_list',
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
  endpoint_id, scenario_id, fixture_name, request_match_json, response_json, http_status, app_code, priority
)
SELECT
  e.id,
  s.id,
  CONCAT('token-expired-', e.operation_key),
  NULL,
  JSON_OBJECT('code', 'TOKEN_EXPIRED', 'message', '인증 토큰이 만료되었습니다.', 'data', NULL, 'traceId', '01J3MOCKTOKEN', 'timestamp', '2026-07-31T10:30:00+09:00'),
  401,
  'TOKEN_EXPIRED',
  10
FROM mock_api_endpoint e
JOIN mock_scenario s ON s.scenario_code = 'TOKEN_EXPIRED'
ON DUPLICATE KEY UPDATE
  response_json = VALUES(response_json),
  http_status = VALUES(http_status),
  app_code = VALUES(app_code),
  priority = VALUES(priority),
  is_active = 1,
  updated_at = CURRENT_TIMESTAMP;
