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

INSERT INTO financial_institution (
  institution_code, institution_name, institution_type_code, is_supported
) VALUES
  ('0004', 'KB Kookmin Bank', 'BANK', 1),
  ('0088', 'Shinhan Bank', 'BANK', 1),
  ('0301', 'KB Securities', 'SECURITIES', 1),
  ('0101', 'KB Kookmin Card', 'CARD', 1),
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
  u.id, i.id, '123456******7890', 'KB Star Checking', '1001',
  '01', 'KRW', 1244200.00, 1244200.00, '2024-01-15', '2026-07-31 10:30:00',
  JSON_OBJECT('resAccount', '123456******7890', 'resAccountName', 'KB Star Checking', 'resAccountType', '1001')
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
       'Withdrawal', 5800.00, 1244200.00, 'Starbucks Gangnam',
       JSON_OBJECT('resAccountTrType', '02', 'resAccountDesc', 'Starbucks Gangnam')
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
       'Deposit', 2500000.00, 1282900.00, 'Salary',
       JSON_OBJECT('resAccountTrType', '01', 'resAccountDesc', 'Salary')
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
