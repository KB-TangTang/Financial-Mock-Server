USE financial_mock;

INSERT INTO mock_scenario (
  scenario_code, name, description, http_status, app_code, latency_ms, is_default
) VALUES
  ('NORMAL', 'Normal response', 'Default successful response scenario', 200, 'SUCCESS', 0, 1),
  ('EMPTY_DATA', 'Empty data', 'Successful response with no source data', 200, 'SUCCESS', 0, 0),
  ('TOKEN_EXPIRED', 'Token expired', 'Authentication token expired error scenario', 401, 'TOKEN_EXPIRED', 0, 0),
  ('RATE_LIMITED', 'Rate limited', 'External API rate limit scenario', 429, 'RATE_LIMITED', 0, 0)
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
  ('INTERNAL', 'GET', '/api/v1/accounts/banks', 'account_bank_list', 'Supported bank list'),
  ('INTERNAL', 'POST', '/api/v1/accounts/verify', 'account_verify', 'Verify account owner'),
  ('INTERNAL', 'POST', '/api/v1/accounts', 'account_connect', 'Connect selected account'),
  ('INTERNAL', 'DELETE', '/api/v1/accounts/{accountId}', 'account_disconnect', 'Disconnect account'),
  ('INTERNAL', 'GET', '/api/v1/assets/dashboard', 'asset_dashboard', 'Asset dashboard'),
  ('INTERNAL', 'GET', '/api/v1/assets/accounts', 'asset_account_list', 'Raw bank checking account assets'),
  ('INTERNAL', 'GET', '/api/v1/assets/deposits', 'asset_deposit_list', 'Raw deposit and savings account assets'),
  ('INTERNAL', 'GET', '/api/v1/assets/stocks', 'asset_stock_list', 'Securities account and holding assets'),
  ('INTERNAL', 'GET', '/api/v1/assets/payMoney', 'asset_pay_money_list', 'Pay money wallet assets'),
  ('INTERNAL', 'GET', '/api/v1/assets/loans', 'asset_loan_list', 'Raw loan account assets'),
  ('INTERNAL', 'GET', '/api/v1/accounts/{accountId}/transactions', 'bank_transaction_list', 'Raw bank deposit/withdrawal transactions'),
  ('INTERNAL', 'GET', '/api/v1/deposits/{depositAccountId}/transactions', 'deposit_transaction_list', 'Raw deposit and savings account transactions'),
  ('INTERNAL', 'GET', '/api/v1/loans/{loanId}/transactions', 'loan_transaction_list', 'Raw loan repayment transactions'),
  ('INTERNAL', 'GET', '/api/v1/securities/{accountId}/transactions', 'securities_transaction_list', 'Raw securities transactions'),
  ('INTERNAL', 'GET', '/api/v1/pay-money/{payMoneyId}/transactions', 'pay_money_transaction_list', 'Raw pay money transactions'),
  ('INTERNAL', 'GET', '/api/v1/cards', 'card_list', 'Raw card list'),
  ('INTERNAL', 'GET', '/api/v1/cards/{cardId}/approvals', 'card_approval_list', 'Raw card approval list'),
  ('INTERNAL', 'GET', '/api/v1/cards/{cardId}/bills', 'card_bill_list', 'Raw card bill list'),
  ('CODEF', 'POST', '/codef/v1/account/list', 'codef_account_list', 'Legacy CODEF-compatible account list'),
  ('CODEF', 'POST', '/codef/v1/account/balance', 'codef_balance', 'Legacy CODEF-compatible account balance')
ON DUPLICATE KEY UPDATE
  provider = VALUES(provider),
  operation_key = VALUES(operation_key),
  description = VALUES(description),
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

INSERT INTO mock_user (scenario_key, nickname, email) VALUES
  ('demo-normal-user', 'Normal test user', 'normal.user@example.com'),
  ('demo-empty-user', 'Empty data test user', 'empty.user@example.com')
ON DUPLICATE KEY UPDATE
  nickname = VALUES(nickname),
  email = VALUES(email),
  is_active = 1,
  updated_at = CURRENT_TIMESTAMP;

-- 기관 코드는 소비처(탕탕 앱)의 InstitutionCatalog 와 **반드시 같아야 한다.**
-- 앱은 계좌 응답의 institutionCode 로 "사용자가 고른 기관"과 대조해 필터링하므로,
-- 코드가 어긋난 계좌는 조회돼도 화면에서 통째로 버려진다.
-- institution_name 은 앱이 그대로 저장해(tbl_connected_account.bank_name) 연결 계좌 관리 화면에 뜬다.
--
-- [2026-08-11] 코드 2건 정정 + 은행 3곳 추가
--   0101 -> 0381 : 같은 KB국민카드인데 코드가 달랐다. 카탈로그 값이 0381 이다.
--   0301 -> 0240 : 카탈로그에 KB증권이 없고, **0301 은 카탈로그에서 신한카드**라 그대로 두면
--                  증권 계좌가 신한카드로 표시되는 사고가 난다. 카탈로그에 있는 증권사로 맞춘다.
--   0090·0020·0092 신설 : 기관 선택 화면에는 은행 9곳이 뜨는데 계좌가 KB 하나뿐이라
--                  다른 기관을 고르면 조회 결과가 0건이었다.
INSERT INTO financial_institution (
  institution_code, institution_name, institution_type_code, is_supported
) VALUES
  ('0004', 'KB국민은행', 'BANK', 1),
  ('0088', '신한은행', 'BANK', 1),
  ('0090', '카카오뱅크', 'BANK', 1),
  ('0020', '우리은행', 'BANK', 1),
  ('0092', '토스뱅크', 'BANK', 1),
  ('0240', '삼성증권', 'SECURITIES', 1),
  ('0381', 'KB국민카드', 'CARD', 1),
  ('PAY_KB', 'KB Pay', 'PAY_MONEY', 1)
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
       'Withdrawal', 5800.00, 1244200.00, '스타벅스 강남점',
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
       'Deposit', 2500000.00, 1282900.00, '급여 입금',
       JSON_OBJECT('resAccountTrType', '01', 'resAccountDesc', '급여 입금')
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
  u.id, i.id, '5555-****-****-1234', 'KB Everyday Credit Card', 'KB-CARD-001',
  '01', '01', 'KRW', '2025-04-01', '2026-07-31 10:30:00',
  JSON_OBJECT('resCardNo', '5555-****-****-1234', 'resCardName', 'KB Everyday Credit Card')
FROM mock_user u
JOIN financial_institution i ON i.institution_code = '0381'
WHERE u.scenario_key = 'demo-normal-user'
ON DUPLICATE KEY UPDATE
  product_name = VALUES(product_name),
  card_product_code = VALUES(card_product_code),
  card_type_code = VALUES(card_type_code),
  card_status_code = VALUES(card_status_code),
  last_synced_at = VALUES(last_synced_at),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO card_payment_account (
  card_id, bank_account_id, valid_from, valid_to,
  is_primary, source_type, match_confidence
)
SELECT
  c.id, ba.id, '2025-04-01', NULL,
  1, 'API', NULL
FROM card c
JOIN mock_user u ON u.id = c.user_id
JOIN bank_account ba ON ba.user_id = u.id
WHERE u.scenario_key = 'demo-normal-user'
  AND c.card_no_masked = '5555-****-****-1234'
  AND ba.account_no_masked = '123456******7890'
ON DUPLICATE KEY UPDATE
  valid_to = VALUES(valid_to),
  is_primary = VALUES(is_primary),
  source_type = VALUES(source_type),
  match_confidence = VALUES(match_confidence),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO card_approval (
  card_id, approval_no, approved_at, approval_type_code, approval_type_name,
  merchant_name, merchant_business_no, approved_amount, currency, description, raw_json
)
SELECT id, 'APV-20260730-001', '2026-07-30 12:35:00', '01', 'Approved',
       'Coupang', '120-88-00767', 32900.00, 'KRW', 'One-time card approval',
       JSON_OBJECT('resApprovalType', '01', 'resMemberStoreName', 'Coupang')
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
SELECT id, '2026-07-01', '2026-08-14', '01', 'Billing fixed', 483200.00, 0.00,
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

INSERT INTO pay_money (
  user_id, institution_id, provider_code, provider_name, wallet_id, wallet_name,
  currency, balance, available_amount, point_amount, last_synced_at, raw_json
)
SELECT
  u.id, i.id, 'KB_PAY', 'KB Pay', 'wallet-demo-normal-001', 'KB Pay Money',
  'KRW', 83500.00, 83500.00, 1240.00, '2026-07-31 10:30:00',
  JSON_OBJECT('providerCode', 'KB_PAY', 'providerName', 'KB Pay', 'walletId', 'wallet-demo-normal-001', 'walletName', 'KB Pay Money')
FROM mock_user u
JOIN financial_institution i ON i.institution_code = 'PAY_KB'
WHERE u.scenario_key = 'demo-normal-user'
ON DUPLICATE KEY UPDATE
  provider_name = VALUES(provider_name),
  wallet_name = VALUES(wallet_name),
  currency = VALUES(currency),
  balance = VALUES(balance),
  available_amount = VALUES(available_amount),
  point_amount = VALUES(point_amount),
  last_synced_at = VALUES(last_synced_at),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO pay_money_transaction (
  pay_money_id, original_transaction_id, transacted_at, trans_type_code,
  trans_type_name, amount, balance_after, point_amount, point_balance_after,
  merchant_name, description, raw_json
)
SELECT id, 'PAY-20260710-001', '2026-07-10 08:30:00', '01',
       'Charge', 100000.00, 100000.00, NULL, NULL,
       NULL, 'Pay money charge',
       JSON_OBJECT('trType', '01', 'providerCode', provider_code, 'walletId', wallet_id)
FROM pay_money
WHERE provider_code = 'KB_PAY'
  AND wallet_id = 'wallet-demo-normal-001'
ON DUPLICATE KEY UPDATE
  trans_type_code = VALUES(trans_type_code),
  trans_type_name = VALUES(trans_type_name),
  amount = VALUES(amount),
  balance_after = VALUES(balance_after),
  point_amount = VALUES(point_amount),
  point_balance_after = VALUES(point_balance_after),
  merchant_name = VALUES(merchant_name),
  description = VALUES(description),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO pay_money_transaction (
  pay_money_id, original_transaction_id, transacted_at, trans_type_code,
  trans_type_name, amount, balance_after, point_amount, point_balance_after,
  merchant_name, description, raw_json
)
SELECT id, 'PAY-20260720-001', '2026-07-20 12:10:00', '02',
       'Payment', -16500.00, 83500.00, NULL, NULL,
       'Mock Coffee', 'Pay money payment',
       JSON_OBJECT('trType', '02', 'providerCode', provider_code, 'walletId', wallet_id, 'merchantName', 'Mock Coffee')
FROM pay_money
WHERE provider_code = 'KB_PAY'
  AND wallet_id = 'wallet-demo-normal-001'
ON DUPLICATE KEY UPDATE
  trans_type_code = VALUES(trans_type_code),
  trans_type_name = VALUES(trans_type_name),
  amount = VALUES(amount),
  balance_after = VALUES(balance_after),
  point_amount = VALUES(point_amount),
  point_balance_after = VALUES(point_balance_after),
  merchant_name = VALUES(merchant_name),
  description = VALUES(description),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO deposit_account (
  user_id, institution_id, account_no_masked, product_name, deposit_type_code,
  account_status_code, currency, principal, balance, interest_rate, opened_at, maturity_date, last_synced_at, raw_json
)
SELECT
  u.id, i.id, '777777******0001', 'KB Time Deposit', '2001',
  '01', 'KRW', 5000000.00, 5032000.00, 3.2500, '2026-01-01', '2027-01-01', '2026-07-31 10:30:00',
  JSON_OBJECT('resAccountName', 'KB Time Deposit', 'resAccountType', '2001')
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
       'Interest', 32000.00, 5032000.00, 'Time deposit interest',
       JSON_OBJECT('resAccountTrType', '03', 'resAccountDesc', 'Time deposit interest')
FROM deposit_account
WHERE account_no_masked = '777777******0001'
ON DUPLICATE KEY UPDATE
  trans_type_code = VALUES(trans_type_code),
  trans_type_name = VALUES(trans_type_name),
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
  u.id, i.id, 'LN-2025-****-0001', 'KB Credit Loan', '3001',
  '01', '01', 'KRW', 20000000.00, 14200000.00,
  5.1200, '2025-02-01', '2028-02-01', 615000.00, '2026-08-01', '2026-07-31 10:30:00',
  JSON_OBJECT('resLoanName', 'KB Credit Loan', 'resAccountType', '3001')
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
       'Repayment', 615000.00, 554000.00, 61000.00, 14200000.00, 'Principal and interest repayment',
       JSON_OBJECT('resLoanTrType', '02', 'resAccountDesc', 'Principal and interest repayment')
FROM loan_account
WHERE loan_no_masked = 'LN-2025-****-0001'
ON DUPLICATE KEY UPDATE
  trans_type_code = VALUES(trans_type_code),
  trans_type_name = VALUES(trans_type_name),
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
  u.id, i.id, '987654******3210', 'KB Securities Trading Account', '4001',
  '01', 'KRW', 120000.00, 1303600.00, '2026-07-31 10:30:00',
  JSON_OBJECT('resAccount', '987654******3210', 'resAccountName', 'KB Securities Trading Account')
FROM mock_user u
JOIN financial_institution i ON i.institution_code = '0240'
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
SELECT id, '005930', 'Samsung Electronics', 'KR', 'KRW',
       12.000000, 72000.00, 78500.00, 864000.00, 942000.00,
       78000.00, 9.0278, '2026-07-31 10:30:00',
       JSON_OBJECT('isuCd', '005930', 'isuKorNm', 'Samsung Electronics')
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
SELECT id, '035720', 'Kakao', 'KR', 'KRW',
       8.000000, 48000.00, 45200.00, 384000.00, 361600.00,
       -22400.00, -5.8333, '2026-07-31 10:30:00',
       JSON_OBJECT('isuCd', '035720', 'isuKorNm', 'Kakao')
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
       'Buy', '005930', 'Samsung Electronics', 12.000000, 72000.00, 864000.00, 'Buy Samsung Electronics',
       JSON_OBJECT('trType', '01', 'isuCd', '005930', 'isuKorNm', 'Samsung Electronics')
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
  JSON_OBJECT('code', 'SUCCESS', 'message', 'No data found.', 'data', JSON_OBJECT(), 'traceId', '01J3MOCKEMPTY', 'timestamp', '2026-07-31T10:30:00+09:00'),
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
  JSON_OBJECT('code', 'TOKEN_EXPIRED', 'message', 'Authentication token has expired.', 'data', NULL, 'traceId', '01J3MOCKTOKEN', 'timestamp', '2026-07-31T10:30:00+09:00'),
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


-- =====================================================================
-- [2026-08-11] 구 기관 코드 정리 — 0101 -> 0381 (KB국민카드), 0301 -> 0240 (증권)
--
-- ⚠ 위 financial_institution INSERT 는 institution_code 가 유일키라
--    코드를 바꾼 값은 **새 행으로 들어가고 구 행은 그대로 남는다.**
--    카드·증권 데이터가 구 행을 계속 참조하면 같은 기관이 둘로 보이고,
--    특히 0301 은 앱 카탈로그에서 **신한카드**라 증권 계좌가 신한카드로 표시된다.
--    그래서 참조를 새 기관으로 옮긴 뒤 구 행을 지운다.
--
-- financial_institution 을 참조하는 테이블은 6개다
--   bank_account · card · deposit_account · loan_account · pay_money · securities_account
--   (구 코드를 쓰던 건 card · securities_account 뿐이지만, 나중에 늘어도 빠지지 않게 전부 적는다)
-- 이 블록은 여러 번 실행해도 안전하다 — 옮길 대상이 없으면 0행이 갱신된다.
-- =====================================================================

UPDATE card c
  JOIN financial_institution old ON old.id = c.institution_id AND old.institution_code = '0101'
  JOIN financial_institution new_i ON new_i.institution_code = '0381'
SET c.institution_id = new_i.id, c.updated_at = CURRENT_TIMESTAMP;

UPDATE securities_account a
  JOIN financial_institution old ON old.id = a.institution_id AND old.institution_code = '0301'
  JOIN financial_institution new_i ON new_i.institution_code = '0240'
SET a.institution_id = new_i.id, a.updated_at = CURRENT_TIMESTAMP;

UPDATE bank_account a
  JOIN financial_institution old ON old.id = a.institution_id AND old.institution_code IN ('0101', '0301')
  JOIN financial_institution new_i
    ON new_i.institution_code = CASE old.institution_code WHEN '0101' THEN '0381' ELSE '0240' END
SET a.institution_id = new_i.id, a.updated_at = CURRENT_TIMESTAMP;

UPDATE deposit_account a
  JOIN financial_institution old ON old.id = a.institution_id AND old.institution_code IN ('0101', '0301')
  JOIN financial_institution new_i
    ON new_i.institution_code = CASE old.institution_code WHEN '0101' THEN '0381' ELSE '0240' END
SET a.institution_id = new_i.id, a.updated_at = CURRENT_TIMESTAMP;

UPDATE loan_account a
  JOIN financial_institution old ON old.id = a.institution_id AND old.institution_code IN ('0101', '0301')
  JOIN financial_institution new_i
    ON new_i.institution_code = CASE old.institution_code WHEN '0101' THEN '0381' ELSE '0240' END
SET a.institution_id = new_i.id, a.updated_at = CURRENT_TIMESTAMP;

UPDATE pay_money a
  JOIN financial_institution old ON old.id = a.institution_id AND old.institution_code IN ('0101', '0301')
  JOIN financial_institution new_i
    ON new_i.institution_code = CASE old.institution_code WHEN '0101' THEN '0381' ELSE '0240' END
SET a.institution_id = new_i.id, a.updated_at = CURRENT_TIMESTAMP;

DELETE FROM financial_institution WHERE institution_code IN ('0101', '0301');

-- =====================================================================
-- [2026-08-11] 다중 기관·다중 계좌 시연용 은행 계좌 확충
--
-- 왜 필요했나
--   기관 선택 화면에는 은행 9곳이 뜨는데(앱의 supportedOrganizations() 가 빈 집합=제한 없음)
--   bank_account 는 KB국민은행 1건뿐이었다. 신한·카카오·우리·토스를 골라 연동하면
--   "조회는 성공했는데 계좌가 0건" 이 돼 연동이 실패한 것처럼 보였다.
--
--   앱이 실제로 호출하는 목서버 API 는 GET /api/v1/assets/accounts **하나뿐**이고
--   이 쿼리는 bank_account 만 내려준다(예적금·대출·증권은 별도 테이블이라 여기 안 나온다).
--   그래서 확충 대상도 bank_account 다.
--
-- 계좌번호는 uk_bank_account_user_no (user_id, account_no_masked) 로 유일하다.
-- 아래 문장은 전부 ON DUPLICATE KEY UPDATE 라 여러 번 실행해도 안전하다.
-- =====================================================================

INSERT INTO bank_account (
  user_id, institution_id, account_no_masked, product_name, account_type_code,
  account_status_code, currency, balance, available_amount, opened_at, last_synced_at, raw_json
)
SELECT
  u.id, i.id, s.account_no_masked, s.product_name, '1001',
  '01', 'KRW', s.balance, s.balance, s.opened_at, '2026-08-11 09:00:00',
  JSON_OBJECT('resAccount', s.account_no_masked, 'resAccountName', s.product_name, 'resAccountType', '1001')
FROM mock_user u
JOIN (
  SELECT '0004' AS institution_code, '004901******1122' AS account_no_masked,
         'KB 직장인우대 급여통장'   AS product_name, 3180500.00 AS balance, '2023-03-02' AS opened_at
  UNION ALL SELECT '0004', '004902******3344', 'KB 비상금 파킹통장',      5400000.00, '2025-02-10'
  UNION ALL SELECT '0088', '110234******5566', '신한 주거래 우대통장',     862300.00, '2022-11-21'
  UNION ALL SELECT '0088', '110235******7788', '신한 모임통장',           1150000.00, '2026-01-05'
  UNION ALL SELECT '0090', '3333-01******9900', '카카오뱅크 입출금통장',    428700.00, '2021-06-30'
  UNION ALL SELECT '0090', '3333-02******1212', '카카오뱅크 세이프박스',   2000000.00, '2024-09-12'
  UNION ALL SELECT '0020', '1002-45******3434', '우리 첫급여 우대통장',     233900.00, '2025-05-19'
  UNION ALL SELECT '0092', '1000-11******5656', '토스뱅크 통장',            76400.00, '2026-03-08'
) s
JOIN financial_institution i ON i.institution_code = s.institution_code
WHERE u.scenario_key = 'demo-normal-user'
ON DUPLICATE KEY UPDATE
  institution_id = VALUES(institution_id),
  product_name = VALUES(product_name),
  account_type_code = VALUES(account_type_code),
  account_status_code = VALUES(account_status_code),
  balance = VALUES(balance),
  available_amount = VALUES(available_amount),
  opened_at = VALUES(opened_at),
  last_synced_at = VALUES(last_synced_at),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;

-- 계좌만 늘리고 거래를 비워두면 GET /api/v1/accounts/{accountId}/transactions 가
-- 빈 배열을 돌려줘 목서버가 반쯤 세팅된 것처럼 보인다. 계좌마다 입금 1·출금 1을 넣는다.
-- trans_type_code 는 기존 시드와 같은 규약이다 — 01=입금, 02=출금.
INSERT INTO bank_transaction (
  bank_account_id, original_transaction_id, transacted_at, trans_type_code,
  trans_type_name, amount, balance_after, description, raw_json
)
SELECT
  a.id, t.original_transaction_id, t.transacted_at, t.trans_type_code,
  CASE t.trans_type_code WHEN '01' THEN 'Deposit' ELSE 'Withdrawal' END,
  t.amount, t.balance_after, t.description,
  JSON_OBJECT('resAccountTrType', t.trans_type_code, 'resAccountDesc', t.description)
FROM bank_account a
JOIN mock_user u ON u.id = a.user_id
JOIN (
  SELECT '004901******1122' AS account_no_masked, 'BANK-20260810-101' AS original_transaction_id,
         '2026-08-10 09:00:00' AS transacted_at, '01' AS trans_type_code,
         2850000.00 AS amount, 3180500.00 AS balance_after, '급여 입금' AS description
  UNION ALL SELECT '004901******1122', 'BANK-20260805-102', '2026-08-05 19:41:00', '02',
                   132000.00, 330500.00, '이마트 성수점'
  UNION ALL SELECT '004902******3344', 'BANK-20260801-103', '2026-08-01 10:00:00', '01',
                   400000.00, 5400000.00, '비상금 이체'
  UNION ALL SELECT '004902******3344', 'BANK-20260728-104', '2026-07-28 14:22:00', '02',
                   150000.00, 5000000.00, '경조사비 출금'
  UNION ALL SELECT '110234******5566', 'BANK-20260809-105', '2026-08-09 12:05:00', '02',
                   38000.00, 862300.00, '배달의민족'
  UNION ALL SELECT '110234******5566', 'BANK-20260803-106', '2026-08-03 08:30:00', '01',
                   500000.00, 900300.00, '용돈 입금'
  UNION ALL SELECT '110235******7788', 'BANK-20260807-107', '2026-08-07 20:10:00', '01',
                   150000.00, 1150000.00, '모임 회비'
  UNION ALL SELECT '110235******7788', 'BANK-20260802-108', '2026-08-02 21:15:00', '02',
                   84000.00, 1000000.00, '한신포차 강남'
  UNION ALL SELECT '3333-01******9900', 'BANK-20260811-109', '2026-08-11 07:55:00', '02',
                   4500.00, 428700.00, 'CU 편의점'
  UNION ALL SELECT '3333-01******9900', 'BANK-20260806-110', '2026-08-06 13:00:00', '01',
                   200000.00, 433200.00, '중고거래 정산'
  UNION ALL SELECT '3333-02******1212', 'BANK-20260801-111', '2026-08-01 00:05:00', '01',
                   500000.00, 2000000.00, '세이프박스 자동이체'
  UNION ALL SELECT '3333-02******1212', 'BANK-20260715-112', '2026-07-15 00:05:00', '01',
                   500000.00, 1500000.00, '세이프박스 자동이체'
  UNION ALL SELECT '1002-45******3434', 'BANK-20260808-113', '2026-08-08 18:30:00', '02',
                   26800.00, 233900.00, 'GS25 역삼'
  UNION ALL SELECT '1002-45******3434', 'BANK-20260804-114', '2026-08-04 11:00:00', '01',
                   150000.00, 260700.00, '환급금 입금'
  UNION ALL SELECT '1000-11******5656', 'BANK-20260810-115', '2026-08-10 22:40:00', '02',
                   12900.00, 76400.00, '넷플릭스'
  UNION ALL SELECT '1000-11******5656', 'BANK-20260801-116', '2026-08-01 09:10:00', '01',
                   50000.00, 89300.00, '토스 캐시백'
) t ON t.account_no_masked = a.account_no_masked
WHERE u.scenario_key = 'demo-normal-user'
ON DUPLICATE KEY UPDATE
  transacted_at = VALUES(transacted_at),
  trans_type_code = VALUES(trans_type_code),
  trans_type_name = VALUES(trans_type_name),
  amount = VALUES(amount),
  balance_after = VALUES(balance_after),
  description = VALUES(description),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;
