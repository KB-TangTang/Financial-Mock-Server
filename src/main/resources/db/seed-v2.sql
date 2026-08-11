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
  ('demo-empty-user', 'Empty data test user', 'empty.user@example.com'),
  ('demo-normal-user2', '통합 금융 챌린지 테스트 사용자', 'normal.user2@example.com'),
  ('1', '본서버 연동용 통합 테스트 사용자', 'sync.dev@example.com')
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
  merchant_name, merchant_business_no, merchant_category_code, merchant_category_name,
  approved_amount, currency, description, raw_json
)
SELECT id, 'APV-20260730-001', '2026-07-30 12:35:00', '01', 'Approved',
       'Coupang', '120-88-00767', '5310', 'Discount store', 32900.00, 'KRW', 'One-time card approval',
       JSON_OBJECT('resApprovalType', '01', 'resMemberStoreName', 'Coupang', 'resMemberStoreTypeCode', '5310', 'resMemberStoreTypeName', 'Discount store')
FROM card
WHERE card_no_masked = '5555-****-****-1234'
ON DUPLICATE KEY UPDATE
  approval_type_code = VALUES(approval_type_code),
  approval_type_name = VALUES(approval_type_name),
  merchant_name = VALUES(merchant_name),
  merchant_business_no = VALUES(merchant_business_no),
  merchant_category_code = VALUES(merchant_category_code),
  merchant_category_name = VALUES(merchant_category_name),
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
  merchant_name, merchant_category_code, merchant_category_name, description, raw_json
)
SELECT id, 'PAY-20260710-001', '2026-07-10 08:30:00', '01',
       'Charge', 100000.00, 100000.00, NULL, NULL,
        NULL, NULL, NULL, 'Pay money charge',
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
  merchant_category_code = VALUES(merchant_category_code),
  merchant_category_name = VALUES(merchant_category_name),
  description = VALUES(description),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO pay_money_transaction (
  pay_money_id, original_transaction_id, transacted_at, trans_type_code,
  trans_type_name, amount, balance_after, point_amount, point_balance_after,
  merchant_name, merchant_category_code, merchant_category_name, description, raw_json
)
SELECT id, 'PAY-20260720-001', '2026-07-20 12:10:00', '02',
       'Payment', -16500.00, 83500.00, NULL, NULL,
        'Mock Coffee', '5814', 'Coffee shop', 'Pay money payment',
        JSON_OBJECT('trType', '02', 'providerCode', provider_code, 'walletId', wallet_id, 'merchantName', 'Mock Coffee', 'merchantCategoryCode', '5814', 'merchantCategoryName', 'Coffee shop')
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
  merchant_category_code = VALUES(merchant_category_code),
  merchant_category_name = VALUES(merchant_category_name),
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

-- Integrated finance / spending-challenge fixture: demo-normal-user2
INSERT INTO bank_account (user_id, institution_id, account_no_masked, product_name, account_type_code, account_status_code, currency, balance, available_amount, opened_at, last_synced_at, raw_json)
SELECT u.id, i.id, x.no, x.name, x.type, '01', 'KRW', x.balance, x.balance, '2026-01-02', '2026-08-31 23:00:00', JSON_OBJECT('scenarioKey', 'demo-normal-user2')
FROM mock_user u JOIN financial_institution i ON i.institution_code = '0004'
JOIN (SELECT '110-***-120045' no, 'KB 급여·생활비 통장' name, '1001' type, 16686700.00 balance UNION ALL SELECT '110-***-840921', 'KB 저축·투자 자금 통장', '1001', 0.00) x
WHERE u.scenario_key = 'demo-normal-user2'
ON DUPLICATE KEY UPDATE product_name=VALUES(product_name), balance=VALUES(balance), available_amount=VALUES(available_amount), last_synced_at=VALUES(last_synced_at), raw_json=VALUES(raw_json), updated_at=CURRENT_TIMESTAMP;

INSERT INTO card (user_id, institution_id, card_no_masked, product_name, card_product_code, card_type_code, card_status_code, currency, issued_at, last_synced_at, raw_json)
SELECT u.id, i.id, x.no, x.name, x.code, x.type, '01', 'KRW', '2025-10-01', '2026-08-31 23:00:00', JSON_OBJECT('scenarioKey','demo-normal-user2')
FROM mock_user u JOIN financial_institution i ON i.institution_code='0101'
JOIN (SELECT '9490-****-****-2201' no, 'KB 챌린지 신용카드' name, 'KB-CH-CREDIT' code, '01' type UNION ALL SELECT '5210-****-****-7714', 'KB 데일리 체크카드', 'KB-CH-CHECK', '02') x
WHERE u.scenario_key='demo-normal-user2'
ON DUPLICATE KEY UPDATE product_name=VALUES(product_name), card_product_code=VALUES(card_product_code), card_type_code=VALUES(card_type_code), last_synced_at=VALUES(last_synced_at), raw_json=VALUES(raw_json), updated_at=CURRENT_TIMESTAMP;

INSERT INTO card_payment_account (card_id, bank_account_id, valid_from, valid_to, is_primary, source_type, match_confidence)
SELECT c.id, b.id, '2025-10-01', NULL, 1, 'SEED', 1.0000 FROM card c JOIN mock_user u ON u.id=c.user_id JOIN bank_account b ON b.user_id=u.id AND b.account_no_masked='110-***-120045'
WHERE u.scenario_key='demo-normal-user2'
ON DUPLICATE KEY UPDATE valid_to=VALUES(valid_to), is_primary=VALUES(is_primary), source_type=VALUES(source_type), match_confidence=VALUES(match_confidence), updated_at=CURRENT_TIMESTAMP;

INSERT INTO pay_money (user_id,institution_id,provider_code,provider_name,wallet_id,wallet_name,currency,balance,available_amount,point_amount,last_synced_at,raw_json)
SELECT u.id,i.id,'KB_PAY','KB Pay','wallet-demo-normal-002','KB Pay 챌린지 지갑','KRW',130000.00,130000.00,800.00,'2026-08-31 23:00:00',JSON_OBJECT('scenarioKey','demo-normal-user2') FROM mock_user u JOIN financial_institution i ON i.institution_code='PAY_KB' WHERE u.scenario_key='demo-normal-user2'
ON DUPLICATE KEY UPDATE balance=VALUES(balance),available_amount=VALUES(available_amount),point_amount=VALUES(point_amount),last_synced_at=VALUES(last_synced_at),raw_json=VALUES(raw_json),updated_at=CURRENT_TIMESTAMP;

INSERT INTO deposit_account (user_id,institution_id,account_no_masked,product_name,deposit_type_code,account_status_code,currency,principal,balance,interest_rate,opened_at,maturity_date,last_synced_at,raw_json)
SELECT u.id,i.id,'110-***-SAVING2','KB 매월 챌린지 적금','2002','01','KRW',1500000.00,1500000.00,3.4000,'2026-04-15','2027-04-15','2026-08-31 23:00:00',JSON_OBJECT('scenarioKey','demo-normal-user2') FROM mock_user u JOIN financial_institution i ON i.institution_code='0004' WHERE u.scenario_key='demo-normal-user2'
ON DUPLICATE KEY UPDATE principal=VALUES(principal),balance=VALUES(balance),last_synced_at=VALUES(last_synced_at),raw_json=VALUES(raw_json),updated_at=CURRENT_TIMESTAMP;

INSERT INTO loan_account (user_id,institution_id,loan_no_masked,product_name,account_type_code,account_status_code,repayment_method_code,currency,principal,outstanding_balance,interest_rate,start_date,maturity_date,monthly_payment,next_payment_date,last_synced_at,raw_json)
SELECT u.id,i.id,'LN-TEST-****-2002','KB 생활안정 신용대출','3001','01','01','KRW',3000000.00,2100000.00,5.1000,'2026-04-10','2027-04-10',312000.00,'2026-09-05','2026-08-31 23:00:00',JSON_OBJECT('scenarioKey','demo-normal-user2') FROM mock_user u JOIN financial_institution i ON i.institution_code='0004' WHERE u.scenario_key='demo-normal-user2'
ON DUPLICATE KEY UPDATE principal=VALUES(principal),outstanding_balance=VALUES(outstanding_balance),next_payment_date=VALUES(next_payment_date),last_synced_at=VALUES(last_synced_at),raw_json=VALUES(raw_json),updated_at=CURRENT_TIMESTAMP;

INSERT INTO securities_account (user_id,institution_id,account_no_masked,product_name,account_type_code,account_status_code,currency,cash_balance,valuation_amount,last_synced_at,raw_json)
SELECT u.id,i.id,'301-***-INV2002','KB 증권 투자계좌','4001','01','KRW',0.00,1674000.00,'2026-08-31 23:00:00',JSON_OBJECT('scenarioKey','demo-normal-user2') FROM mock_user u JOIN financial_institution i ON i.institution_code='0301' WHERE u.scenario_key='demo-normal-user2'
ON DUPLICATE KEY UPDATE cash_balance=VALUES(cash_balance),valuation_amount=VALUES(valuation_amount),last_synced_at=VALUES(last_synced_at),raw_json=VALUES(raw_json),updated_at=CURRENT_TIMESTAMP;

INSERT INTO bank_transaction (bank_account_id,original_transaction_id,transacted_at,trans_type_code,trans_type_name,amount,balance_after,description,raw_json)
SELECT b.id,x.tid,x.at,x.code,x.type,x.amount,x.bal,x.descr,JSON_OBJECT('correlationId',x.corr,'challengeEligible',IF(x.challenge=1, TRUE, FALSE),'challengeCategory',x.category,'merchantName',x.merchant,'mcc',x.mcc)
FROM bank_account b JOIN mock_user u ON u.id=b.user_id
JOIN (
 SELECT 'N2-B-001' tid,'2026-04-01 09:00:00' at,'01' code,'입금' type,3000000 amount,3000000 bal,'기초 잔액 이관' descr,'N2-OPEN' corr,0 challenge,NULL category,NULL merchant,NULL mcc UNION ALL
 SELECT 'N2-B-002','2026-04-10 10:00:00','01','입금',3000000,6000000,'대출 실행금 입금','N2-LOAN-EXEC',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-003','2026-04-15 09:05:00','02','출금',300000,5700000,'적금 납입','N2-DEP-04',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-004','2026-04-20 18:00:00','02','출금',100000,5600000,'KB Pay 머니 충전','N2-PAY-04',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-005','2026-04-25 08:30:00','01','입금',3400000,9000000,'급여','N2-SAL-04',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-006','2026-05-15 09:05:00','02','출금',300000,8700000,'적금 납입','N2-DEP-05',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-007','2026-05-25 08:30:00','01','입금',3400000,12100000,'급여','N2-SAL-05',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-008','2026-06-05 09:00:00','02','출금',315000,11785000,'대출 원리금 상환','N2-LOAN-06',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-009','2026-06-10 09:05:00','02','출금',300000,11485000,'적금 납입','N2-DEP-06',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-010','2026-06-12 18:00:00','02','출금',150000,11335000,'KB Pay 머니 충전','N2-PAY-06',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-011','2026-06-17 12:20:00','02','출금',50000,11285000,'GS25 역삼센터점','N2-CHK-0617',1,'편의점','GS25 역삼센터점','5499' UNION ALL
 SELECT 'N2-B-012','2026-06-23 08:10:00','02','출금',35000,11250000,'카카오T','N2-CHK-0623',1,'교통','카카오T','4111' UNION ALL
 SELECT 'N2-B-013','2026-06-25 08:30:00','01','입금',3400000,14650000,'급여','N2-SAL-06',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-014','2026-06-29 09:10:00','02','출금',700000,13950000,'증권 매수대금','N2-SEC-BUY-06',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-015','2026-07-05 09:00:00','02','출금',313000,13637000,'대출 원리금 상환','N2-LOAN-07',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-016','2026-07-10 09:05:00','02','출금',300000,13337000,'적금 납입','N2-DEP-07',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-017','2026-07-12 18:00:00','02','출금',200000,13137000,'KB Pay 머니 충전','N2-PAY-07',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-018','2026-07-14 09:00:00','02','출금',270000,12867000,'카드 이용대금','N2-CARD-BILL-06',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-019','2026-07-17 19:10:00','02','출금',70000,12797000,'다이소 강남역점','N2-CHK-0717',1,'생활용품','다이소 강남역점','5331' UNION ALL
 SELECT 'N2-B-020','2026-07-21 12:10:00','02','출금',40000,12757000,'CU 역삼점','N2-CHK-0721',1,'편의점','CU 역삼점','5499' UNION ALL
 SELECT 'N2-B-021','2026-07-23 08:10:00','02','출금',35000,12722000,'카카오T','N2-CHK-0723',1,'교통','카카오T','4111' UNION ALL
 SELECT 'N2-B-022','2026-07-25 08:30:00','01','입금',3400000,16122000,'급여','N2-SAL-07',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-023','2026-07-29 09:10:00','02','출금',1000000,15122000,'증권 매수대금','N2-SEC-BUY-07',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-024','2026-08-05 09:00:00','02','출금',312000,14810000,'대출 원리금 상환','N2-LOAN-08',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-025','2026-08-10 09:05:00','02','출금',300000,14510000,'적금 납입','N2-DEP-08',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-026','2026-08-12 18:00:00','02','출금',150000,14360000,'KB Pay 머니 충전','N2-PAY-08',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-027','2026-08-14 09:00:00','02','출금',477000,13883000,'카드 이용대금','N2-CARD-BILL-07',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-028','2026-08-17 12:20:00','02','출금',50000,13833000,'GS25 역삼센터점','N2-CHK-0817',1,'편의점','GS25 역삼센터점','5499' UNION ALL
 SELECT 'N2-B-029','2026-08-22 08:10:00','02','출금',30000,13803000,'카카오T','N2-CHK-0822',1,'교통','카카오T','4111' UNION ALL
 SELECT 'N2-B-030','2026-08-25 08:30:00','01','입금',3400000,17203000,'급여','N2-SAL-08',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-031','2026-08-28 15:10:00','01','입금',150000,17353000,'증권 매도대금','N2-SEC-SELL-08',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-032','2026-08-31 23:00:00','01','입금',145000,17498000,'월말 정산 이체','N2-MONTH-END',0,NULL,NULL,NULL
) x ON b.account_no_masked='110-***-120045' WHERE u.scenario_key='demo-normal-user2'
ON DUPLICATE KEY UPDATE transacted_at=VALUES(transacted_at),trans_type_code=VALUES(trans_type_code),trans_type_name=VALUES(trans_type_name),amount=VALUES(amount),balance_after=VALUES(balance_after),description=VALUES(description),raw_json=VALUES(raw_json),updated_at=CURRENT_TIMESTAMP;

INSERT INTO bank_transaction (bank_account_id,original_transaction_id,transacted_at,trans_type_code,trans_type_name,amount,balance_after,description,raw_json)
SELECT b.id,'N2-B-INV-OPEN','2026-04-01 09:01:00','01','입금',0.00,0.00,'투자자금 계좌 기초잔액',JSON_OBJECT('challengeEligible',false) FROM bank_account b JOIN mock_user u ON u.id=b.user_id
WHERE u.scenario_key='demo-normal-user2' AND b.account_no_masked='110-***-840921'
ON DUPLICATE KEY UPDATE transacted_at=VALUES(transacted_at),amount=VALUES(amount),balance_after=VALUES(balance_after),raw_json=VALUES(raw_json),updated_at=CURRENT_TIMESTAMP;

INSERT INTO card_approval (card_id,approval_no,approved_at,approval_type_code,approval_type_name,merchant_name,merchant_business_no,merchant_category_code,merchant_category_name,approved_amount,currency,description,raw_json)
SELECT c.id,x.no,x.at,x.kind,IF(x.kind='01','승인','취소'),x.merchant,'000-00-00000',x.mcc,x.cat,x.amount,'KRW',x.merchant,JSON_OBJECT('correlationId',CASE x.no WHEN 'N2-D-0617' THEN 'N2-CHK-0617' WHEN 'N2-D-0623' THEN 'N2-CHK-0623' WHEN 'N2-D-0717' THEN 'N2-CHK-0717' WHEN 'N2-D-0721' THEN 'N2-CHK-0721' WHEN 'N2-D-0723' THEN 'N2-CHK-0723' WHEN 'N2-D-0817' THEN 'N2-CHK-0817' WHEN 'N2-D-0822' THEN 'N2-CHK-0822' ELSE NULL END,'challengeEligible',true,'challengeCategory',x.challenge,'originalApprovalNo',x.originalNo)
FROM card c JOIN mock_user u ON u.id=c.user_id JOIN (
 SELECT '9490-****-****-2201' card,'N2-C-0610' no,'2026-06-10 19:00:00' at,'01' kind,'이마트 역삼점' merchant,'5411' mcc,'대형마트·식료품' cat,120000 amount,'마트' challenge,NULL originalNo UNION ALL SELECT '9490-****-****-2201','N2-C-0615','2026-06-15 15:10:00','01','스타벅스 강남역점','5814','카페',50000,'카페',NULL UNION ALL SELECT '9490-****-****-2201','N2-C-0620','2026-06-20 21:00:00','01','쿠팡','5999','온라인 쇼핑',100000,'쇼핑',NULL UNION ALL SELECT '5210-****-****-7714','N2-D-0617','2026-06-17 12:20:00','01','GS25 역삼센터점','5499','편의점',50000,'편의점',NULL UNION ALL SELECT '5210-****-****-7714','N2-D-0623','2026-06-23 08:10:00','01','카카오T','4111','교통',35000,'교통',NULL UNION ALL
 SELECT '9490-****-****-2201','N2-C-0710','2026-07-10 20:00:00','01','쿠팡','5999','온라인 쇼핑',300000,'쇼핑',NULL UNION ALL SELECT '9490-****-****-2201','N2-C-0714','2026-07-14 18:10:00','01','이마트 역삼점','5411','대형마트·식료품',100000,'마트',NULL UNION ALL SELECT '9490-****-****-2201','N2-C-0718','2026-07-18 10:20:00','01','스타벅스 강남역점','5814','카페',40000,'카페',NULL UNION ALL SELECT '9490-****-****-2201','N2-C-0720','2026-07-20 09:00:00','01','SK텔레콤','4814','통신 서비스',20000,'통신',NULL UNION ALL SELECT '9490-****-****-2201','N2-C-0728','2026-07-28 09:00:00','01','넷플릭스','4899','디지털 콘텐츠·구독',17000,'구독',NULL UNION ALL SELECT '5210-****-****-7714','N2-D-0717','2026-07-17 19:10:00','01','다이소 강남역점','5331','생활용품',70000,'생활용품',NULL UNION ALL SELECT '5210-****-****-7714','N2-D-0721','2026-07-21 12:10:00','01','CU 역삼점','5499','편의점',40000,'편의점',NULL UNION ALL SELECT '5210-****-****-7714','N2-D-0723','2026-07-23 08:10:00','01','카카오T','4111','교통',35000,'교통',NULL UNION ALL
 SELECT '9490-****-****-2201','N2-C-0810','2026-08-10 20:00:00','01','쿠팡','5999','온라인 쇼핑',250000,'쇼핑',NULL UNION ALL SELECT '9490-****-****-2201','N2-C-0814','2026-08-14 18:10:00','01','이마트 역삼점','5411','대형마트·식료품',100000,'마트',NULL UNION ALL SELECT '9490-****-****-2201','N2-C-0814-C','2026-08-15 09:00:00','03','이마트 역삼점','5411','대형마트·식료품',-20000,'마트','N2-C-0814' UNION ALL SELECT '9490-****-****-2201','N2-C-0818','2026-08-18 10:20:00','01','스타벅스 강남역점','5814','카페',55000,'카페',NULL UNION ALL SELECT '9490-****-****-2201','N2-C-0828','2026-08-28 09:00:00','01','넷플릭스','4899','디지털 콘텐츠·구독',17000,'구독',NULL UNION ALL SELECT '5210-****-****-7714','N2-D-0817','2026-08-17 12:20:00','01','GS25 역삼센터점','5499','편의점',50000,'편의점',NULL UNION ALL SELECT '5210-****-****-7714','N2-D-0822','2026-08-22 08:10:00','01','카카오T','4111','교통',30000,'교통',NULL
) x ON x.card=c.card_no_masked WHERE u.scenario_key='demo-normal-user2'
ON DUPLICATE KEY UPDATE approved_at=VALUES(approved_at),approval_type_code=VALUES(approval_type_code),merchant_name=VALUES(merchant_name),merchant_category_code=VALUES(merchant_category_code),merchant_category_name=VALUES(merchant_category_name),approved_amount=VALUES(approved_amount),raw_json=VALUES(raw_json),updated_at=CURRENT_TIMESTAMP;

-- Two ordinary credit-card purchases every day; existing check-card purchases add variation on selected days.
INSERT INTO card_approval (card_id,approval_no,approved_at,approval_type_code,approval_type_name,merchant_name,merchant_business_no,merchant_category_code,merchant_category_name,approved_amount,currency,description,raw_json)
WITH RECURSIVE challenge_days AS (
  SELECT DATE('2026-06-01') AS purchase_date
  UNION ALL
  SELECT DATE_ADD(purchase_date, INTERVAL 1 DAY) FROM challenge_days WHERE purchase_date < '2026-08-31'
)
SELECT c.id,
       CONCAT('N2-DAILY-', DATE_FORMAT(d.purchase_date, '%Y%m%d'), '-', x.suffix),
       TIMESTAMP(d.purchase_date, x.purchase_time),
       '01', '승인',
       CASE WHEN x.suffix='A' THEN x.merchant ELSE CASE MOD(DATEDIFF(d.purchase_date, '2026-06-01'), 22)
         WHEN 0 THEN '이바돔감자탕 강남점' WHEN 1 THEN '신의주찹쌀순대 역삼점'
         WHEN 2 THEN '맥도날드 역삼점' WHEN 3 THEN '피자헛 강남점'
         WHEN 4 THEN '버거킹 역삼점' WHEN 5 THEN '현대옥 콩나물국밥 강남점'
         WHEN 6 THEN '명동교자 강남점' WHEN 7 THEN '홍콩반점 강남역점'
         WHEN 8 THEN '역전우동 강남점' WHEN 9 THEN '맘스터치 역삼점'
         WHEN 10 THEN '본죽 강남역점' WHEN 11 THEN '교촌치킨 역삼1호점'
         WHEN 12 THEN '배달의민족' WHEN 13 THEN '쿠팡이츠'
         WHEN 14 THEN '죠스떡볶이 강남점' WHEN 15 THEN '포메인 강남역점'
         WHEN 16 THEN '스시로 강남점' WHEN 17 THEN '샐러디 역삼점'
         WHEN 18 THEN '김가네 강남역점' WHEN 19 THEN '육전식당 강남점'
         WHEN 20 THEN '한솥도시락 강남역점' ELSE '탕화쿵푸마라탕 강남점' END END,
       '000-00-00000',
       CASE WHEN x.suffix='A' THEN x.mcc ELSE CASE MOD(DATEDIFF(d.purchase_date, '2026-06-01'), 22) WHEN 2 THEN '5814' WHEN 4 THEN '5814' WHEN 9 THEN '5814' ELSE '5812' END END,
       CASE WHEN x.suffix='A' THEN x.category ELSE CASE MOD(DATEDIFF(d.purchase_date, '2026-06-01'), 22) WHEN 2 THEN '패스트푸드' WHEN 4 THEN '패스트푸드' WHEN 9 THEN '패스트푸드' ELSE '음식점' END END,
       x.amount, 'KRW',
       CASE WHEN x.suffix='A' THEN x.merchant ELSE '일상 식사 결제' END,
       JSON_OBJECT('challengeEligible', true, 'challengeCategory', CASE WHEN x.suffix='A' THEN x.challenge_category ELSE '식비' END, 'dailyChallengeSeed', true)
FROM challenge_days d
CROSS JOIN (SELECT 'A' suffix, '08:25:00' purchase_time, '스타벅스 강남역점' merchant, '5814' mcc, '카페' category, 5800.00 amount, '카페' challenge_category
      UNION ALL SELECT 'B', '18:40:00', '일상 식사 결제', '5812', '음식점', 7500.00, '식비') x
JOIN card c ON c.card_no_masked='9490-****-****-2201'
JOIN mock_user u ON u.id=c.user_id AND u.scenario_key='demo-normal-user2'
WHERE TRUE
ON DUPLICATE KEY UPDATE approved_at=VALUES(approved_at),merchant_name=VALUES(merchant_name),merchant_category_code=VALUES(merchant_category_code),merchant_category_name=VALUES(merchant_category_name),approved_amount=VALUES(approved_amount),raw_json=VALUES(raw_json),updated_at=CURRENT_TIMESTAMP;

INSERT INTO card_bill (card_id,billing_month,due_date,bill_status_code,bill_status_name,total_amount,paid_amount,raw_json)
SELECT c.id,x.month,x.due,x.status,x.name,x.total,x.paid,JSON_OBJECT('includedApprovalAmount',x.total,'paymentCorrelationId',x.corr) FROM card c JOIN mock_user u ON u.id=c.user_id JOIN (SELECT '2026-06-01' month,'2026-07-14' due,'02' status,'결제완료' name,669000 total,669000 paid,'N2-CARD-BILL-06' corr UNION ALL SELECT '2026-07-01','2026-08-14','02','결제완료',889300,889300,'N2-CARD-BILL-07' UNION ALL SELECT '2026-08-01','2026-08-31','01','청구확정',814300,0,'N2-CARD-BILL-08') x
WHERE u.scenario_key='demo-normal-user2' AND c.card_no_masked='9490-****-****-2201'
ON DUPLICATE KEY UPDATE due_date=VALUES(due_date),bill_status_code=VALUES(bill_status_code),bill_status_name=VALUES(bill_status_name),total_amount=VALUES(total_amount),paid_amount=VALUES(paid_amount),raw_json=VALUES(raw_json),updated_at=CURRENT_TIMESTAMP;

INSERT INTO pay_money_transaction (pay_money_id,original_transaction_id,transacted_at,trans_type_code,trans_type_name,amount,balance_after,point_amount,point_balance_after,merchant_name,merchant_category_code,merchant_category_name,description,raw_json)
SELECT p.id,x.id,x.at,x.code,x.type,x.amount,x.balance,x.points,x.pointBalance,x.merchant,x.mcc,x.category,x.merchant,JSON_OBJECT('correlationId',x.corr,'challengeEligible',IF(x.challenge=1, TRUE, FALSE),'challengeCategory',x.challengeCategory,'originalTransactionId',x.original)
FROM pay_money p JOIN mock_user u ON u.id=p.user_id JOIN (
 SELECT 'N2-P-04C' id,'2026-04-20 18:00:01' at,'01' code,'충전' type,100000 amount,100000 balance,NULL points,0 pointBalance,NULL merchant,NULL mcc,NULL category,'N2-PAY-04' corr,0 challenge,NULL challengeCategory,NULL original UNION ALL SELECT 'N2-P-04P','2026-04-21 12:00:00','02','결제',-100000,0,NULL,0,'맥도날드 역삼점','5814','패스트푸드','N2-P-04',1,'식비',NULL UNION ALL
 SELECT 'N2-P-06C','2026-06-12 18:00:01','01','충전',150000,150000,NULL,0,NULL,NULL,NULL,'N2-PAY-06',0,NULL,NULL UNION ALL SELECT 'N2-P-0615','2026-06-15 12:30:00','02','결제',-70000,80000,NULL,0,'배달의민족','5812','음식점','N2-PAY-0615',1,'식비',NULL UNION ALL SELECT 'N2-P-0619','2026-06-19 19:00:00','02','결제',-25000,55000,NULL,0,'올리브영 강남점','5977','화장품·생활용품','N2-PAY-0619',1,'생활용품',NULL UNION ALL SELECT 'N2-P-0626','2026-06-26 08:40:00','02','결제',-30000,25000,NULL,0,'스타벅스 강남역점','5814','카페','N2-PAY-0626',1,'카페',NULL UNION ALL SELECT 'N2-P-0627','2026-06-27 10:00:00','03','환불',10000,35000,500,500,'배달의민족','5812','음식점','N2-PAY-0615',1,'식비','N2-P-0615' UNION ALL
 SELECT 'N2-P-07C','2026-07-12 18:00:01','01','충전',200000,235000,NULL,500,NULL,NULL,NULL,'N2-PAY-07',0,NULL,NULL UNION ALL SELECT 'N2-P-0716','2026-07-16 12:30:00','02','결제',-80000,155000,NULL,500,'배달의민족','5812','음식점','N2-PAY-0716',1,'식비',NULL UNION ALL SELECT 'N2-P-0720','2026-07-20 19:00:00','02','결제',-45000,110000,NULL,500,'올리브영 강남점','5977','화장품·생활용품','N2-PAY-0720',1,'생활용품',NULL UNION ALL SELECT 'N2-P-0726','2026-07-26 08:40:00','02','결제',-25000,85000,NULL,500,'스타벅스 강남역점','5814','카페','N2-PAY-0726',1,'카페',NULL UNION ALL SELECT 'N2-P-0727','2026-07-27 10:00:00','03','환불',10000,95000,300,800,'배달의민족','5812','음식점','N2-PAY-0716',1,'식비','N2-P-0716' UNION ALL
 SELECT 'N2-P-08C','2026-08-12 18:00:01','01','충전',150000,245000,NULL,800,NULL,NULL,NULL,'N2-PAY-08',0,NULL,NULL UNION ALL SELECT 'N2-P-0816','2026-08-16 12:30:00','02','결제',-55000,190000,NULL,800,'배달의민족','5812','음식점','N2-PAY-0816',1,'식비',NULL UNION ALL SELECT 'N2-P-0820','2026-08-20 19:00:00','02','결제',-35000,155000,NULL,800,'올리브영 강남점','5977','화장품·생활용품','N2-PAY-0820',1,'생활용품',NULL UNION ALL SELECT 'N2-P-0826','2026-08-26 08:40:00','02','결제',-25000,130000,NULL,800,'스타벅스 강남역점','5814','카페','N2-PAY-0826',1,'카페',NULL
) x WHERE u.scenario_key='demo-normal-user2' AND p.wallet_id='wallet-demo-normal-002'
ON DUPLICATE KEY UPDATE transacted_at=VALUES(transacted_at),amount=VALUES(amount),balance_after=VALUES(balance_after),point_amount=VALUES(point_amount),point_balance_after=VALUES(point_balance_after),merchant_name=VALUES(merchant_name),raw_json=VALUES(raw_json),updated_at=CURRENT_TIMESTAMP;

INSERT INTO deposit_transaction (deposit_account_id,original_transaction_id,transacted_at,trans_type_code,trans_type_name,amount,balance_after,description,raw_json)
SELECT d.id,x.id,x.at,'01','납입',300000,x.balance,'정기 적금 납입',JSON_OBJECT('correlationId',x.corr,'challengeEligible',false) FROM deposit_account d JOIN mock_user u ON u.id=d.user_id JOIN (SELECT 'N2-D-04' id,'2026-04-15 09:05:01' at,300000 balance,'N2-DEP-04' corr UNION ALL SELECT 'N2-D-05','2026-05-15 09:05:01',600000,'N2-DEP-05' UNION ALL SELECT 'N2-D-06','2026-06-10 09:05:01',900000,'N2-DEP-06' UNION ALL SELECT 'N2-D-07','2026-07-10 09:05:01',1200000,'N2-DEP-07' UNION ALL SELECT 'N2-D-08','2026-08-10 09:05:01',1500000,'N2-DEP-08') x WHERE u.scenario_key='demo-normal-user2' AND d.account_no_masked='110-***-SAVING2'
ON DUPLICATE KEY UPDATE transacted_at=VALUES(transacted_at),amount=VALUES(amount),balance_after=VALUES(balance_after),raw_json=VALUES(raw_json),updated_at=CURRENT_TIMESTAMP;

INSERT INTO loan_transaction (loan_account_id,original_transaction_id,transacted_at,trans_type_code,trans_type_name,amount,principal_amount,interest_amount,balance_after,description,raw_json)
SELECT l.id,x.id,x.at,x.code,x.type,x.amount,x.principal,x.interest,x.balance,x.type,JSON_OBJECT('correlationId',x.corr,'challengeEligible',false) FROM loan_account l JOIN mock_user u ON u.id=l.user_id JOIN (SELECT 'N2-L-EXEC' id,'2026-04-10 10:00:01' at,'01' code,'대출 실행' type,3000000 amount,3000000 principal,0 interest,3000000 balance,'N2-LOAN-EXEC' corr UNION ALL SELECT 'N2-L-06','2026-06-05 09:00:01','02','원리금 상환',315000,300000,15000,2700000,'N2-LOAN-06' UNION ALL SELECT 'N2-L-07','2026-07-05 09:00:01','02','원리금 상환',313000,300000,13000,2400000,'N2-LOAN-07' UNION ALL SELECT 'N2-L-08','2026-08-05 09:00:01','02','원리금 상환',312000,300000,12000,2100000,'N2-LOAN-08') x WHERE u.scenario_key='demo-normal-user2' AND l.loan_no_masked='LN-TEST-****-2002'
ON DUPLICATE KEY UPDATE transacted_at=VALUES(transacted_at),amount=VALUES(amount),principal_amount=VALUES(principal_amount),interest_amount=VALUES(interest_amount),balance_after=VALUES(balance_after),raw_json=VALUES(raw_json),updated_at=CURRENT_TIMESTAMP;

INSERT INTO securities_holding (securities_account_id,product_code,product_name,market_country_code,currency,quantity,average_purchase_price,last_price,purchase_amount,market_value,profit_loss_amount,profit_loss_rate,valuation_at,raw_json)
SELECT a.id,x.code,x.name,'KR','KRW',x.qty,x.avg,x.last,x.cost,x.value,x.pnl,x.rate,'2026-08-31 23:00:00',JSON_OBJECT('scenarioKey','demo-normal-user2') FROM securities_account a JOIN mock_user u ON u.id=a.user_id JOIN (SELECT '005930' code,'삼성전자' name,8.000000 qty,70000 avg,78000 last,560000 cost,624000 value,64000 pnl,11.4286 rate UNION ALL SELECT '000660','SK하이닉스',5.000000,200000,210000,1000000,1050000,50000,5.0000) x WHERE u.scenario_key='demo-normal-user2' AND a.account_no_masked='301-***-INV2002'
ON DUPLICATE KEY UPDATE quantity=VALUES(quantity),average_purchase_price=VALUES(average_purchase_price),last_price=VALUES(last_price),purchase_amount=VALUES(purchase_amount),market_value=VALUES(market_value),profit_loss_amount=VALUES(profit_loss_amount),profit_loss_rate=VALUES(profit_loss_rate),valuation_at=VALUES(valuation_at),raw_json=VALUES(raw_json),updated_at=CURRENT_TIMESTAMP;

INSERT INTO securities_transaction (securities_account_id,original_transaction_id,transacted_at,trans_type_code,trans_type_name,product_code,product_name,quantity,unit_price,transaction_amount,description,raw_json)
SELECT a.id,x.id,x.at,x.code,x.type,x.product,x.name,x.qty,x.price,x.amount,x.name,JSON_OBJECT('correlationId',x.corr,'challengeEligible',false) FROM securities_account a JOIN mock_user u ON u.id=a.user_id JOIN (SELECT 'N2-S-06' id,'2026-06-29 09:10:01' at,'01' code,'매수' type,'005930' product,'삼성전자' name,10.000000 qty,70000 price,700000 amount,'N2-SEC-BUY-06' corr UNION ALL SELECT 'N2-S-07','2026-07-29 09:10:01','01','매수','000660','SK하이닉스',5.000000,200000,1000000,'N2-SEC-BUY-07' UNION ALL SELECT 'N2-S-08','2026-08-28 15:10:01','02','매도','005930','삼성전자',2.000000,75000,150000,'N2-SEC-SELL-08') x WHERE u.scenario_key='demo-normal-user2' AND a.account_no_masked='301-***-INV2002'
ON DUPLICATE KEY UPDATE transacted_at=VALUES(transacted_at),trans_type_code=VALUES(trans_type_code),quantity=VALUES(quantity),unit_price=VALUES(unit_price),transaction_amount=VALUES(transaction_amount),raw_json=VALUES(raw_json),updated_at=CURRENT_TIMESTAMP;

-- Reconcile completed June/July credit-card bills with the daily approvals above.
UPDATE bank_transaction t
JOIN bank_account b ON b.id=t.bank_account_id
JOIN mock_user u ON u.id=b.user_id
SET t.amount = CASE t.original_transaction_id
                 WHEN 'N2-B-018' THEN 669000.00
                 WHEN 'N2-B-027' THEN 889300.00
                 ELSE t.amount
               END,
    t.balance_after = CASE t.original_transaction_id
                 WHEN 'N2-B-018' THEN 12468000.00
                 WHEN 'N2-B-019' THEN 12398000.00
                 WHEN 'N2-B-020' THEN 12358000.00
                 WHEN 'N2-B-021' THEN 12323000.00
                 WHEN 'N2-B-022' THEN 15723000.00
                 WHEN 'N2-B-023' THEN 14723000.00
                 WHEN 'N2-B-024' THEN 14411000.00
                 WHEN 'N2-B-025' THEN 14111000.00
                 WHEN 'N2-B-026' THEN 13961000.00
                 WHEN 'N2-B-027' THEN 13071700.00
                 WHEN 'N2-B-028' THEN 13021700.00
                 WHEN 'N2-B-029' THEN 12991700.00
                 WHEN 'N2-B-030' THEN 16391700.00
                 WHEN 'N2-B-031' THEN 16541700.00
                 WHEN 'N2-B-032' THEN 16686700.00
                 ELSE t.balance_after
               END,
    t.updated_at = CURRENT_TIMESTAMP
WHERE u.scenario_key='demo-normal-user2'
  AND t.original_transaction_id IN ('N2-B-018','N2-B-019','N2-B-020','N2-B-021','N2-B-022','N2-B-023','N2-B-024','N2-B-025','N2-B-026','N2-B-027','N2-B-028','N2-B-029','N2-B-030','N2-B-031','N2-B-032');

-- Integrated finance / spending-challenge fixture: scenario_key='1' (cloned from demo-normal-user2)
INSERT INTO bank_account (user_id, institution_id, account_no_masked, product_name, account_type_code, account_status_code, currency, balance, available_amount, opened_at, last_synced_at, raw_json)
SELECT u.id, i.id, x.no, x.name, x.type, '01', 'KRW', x.balance, x.balance, '2026-01-02', '2026-08-31 23:00:00', JSON_OBJECT('scenarioKey', 'demo-normal-user2')
FROM mock_user u JOIN financial_institution i ON i.institution_code = '0004'
JOIN (SELECT '110-***-120045' no, 'KB 급여·생활비 통장' name, '1001' type, 16686700.00 balance UNION ALL SELECT '110-***-840921', 'KB 저축·투자 자금 통장', '1001', 0.00) x
WHERE u.scenario_key = '1'
ON DUPLICATE KEY UPDATE product_name=VALUES(product_name), balance=VALUES(balance), available_amount=VALUES(available_amount), last_synced_at=VALUES(last_synced_at), raw_json=VALUES(raw_json), updated_at=CURRENT_TIMESTAMP;

INSERT INTO card (user_id, institution_id, card_no_masked, product_name, card_product_code, card_type_code, card_status_code, currency, issued_at, last_synced_at, raw_json)
SELECT u.id, i.id, x.no, x.name, x.code, x.type, '01', 'KRW', '2025-10-01', '2026-08-31 23:00:00', JSON_OBJECT('scenarioKey','demo-normal-user2')
FROM mock_user u JOIN financial_institution i ON i.institution_code='0101'
JOIN (SELECT '9490-****-****-2201' no, 'KB 챌린지 신용카드' name, 'KB-CH-CREDIT' code, '01' type UNION ALL SELECT '5210-****-****-7714', 'KB 데일리 체크카드', 'KB-CH-CHECK', '02') x
WHERE u.scenario_key='1'
ON DUPLICATE KEY UPDATE product_name=VALUES(product_name), card_product_code=VALUES(card_product_code), card_type_code=VALUES(card_type_code), last_synced_at=VALUES(last_synced_at), raw_json=VALUES(raw_json), updated_at=CURRENT_TIMESTAMP;

INSERT INTO card_payment_account (card_id, bank_account_id, valid_from, valid_to, is_primary, source_type, match_confidence)
SELECT c.id, b.id, '2025-10-01', NULL, 1, 'SEED', 1.0000 FROM card c JOIN mock_user u ON u.id=c.user_id JOIN bank_account b ON b.user_id=u.id AND b.account_no_masked='110-***-120045'
WHERE u.scenario_key='1'
ON DUPLICATE KEY UPDATE valid_to=VALUES(valid_to), is_primary=VALUES(is_primary), source_type=VALUES(source_type), match_confidence=VALUES(match_confidence), updated_at=CURRENT_TIMESTAMP;

INSERT INTO pay_money (user_id,institution_id,provider_code,provider_name,wallet_id,wallet_name,currency,balance,available_amount,point_amount,last_synced_at,raw_json)
SELECT u.id,i.id,'KB_PAY','KB Pay','wallet-demo-normal-002','KB Pay 챌린지 지갑','KRW',130000.00,130000.00,800.00,'2026-08-31 23:00:00',JSON_OBJECT('scenarioKey','demo-normal-user2') FROM mock_user u JOIN financial_institution i ON i.institution_code='PAY_KB' WHERE u.scenario_key='1'
ON DUPLICATE KEY UPDATE balance=VALUES(balance),available_amount=VALUES(available_amount),point_amount=VALUES(point_amount),last_synced_at=VALUES(last_synced_at),raw_json=VALUES(raw_json),updated_at=CURRENT_TIMESTAMP;

INSERT INTO deposit_account (user_id,institution_id,account_no_masked,product_name,deposit_type_code,account_status_code,currency,principal,balance,interest_rate,opened_at,maturity_date,last_synced_at,raw_json)
SELECT u.id,i.id,'110-***-SAVING2','KB 매월 챌린지 적금','2002','01','KRW',1500000.00,1500000.00,3.4000,'2026-04-15','2027-04-15','2026-08-31 23:00:00',JSON_OBJECT('scenarioKey','demo-normal-user2') FROM mock_user u JOIN financial_institution i ON i.institution_code='0004' WHERE u.scenario_key='1'
ON DUPLICATE KEY UPDATE principal=VALUES(principal),balance=VALUES(balance),last_synced_at=VALUES(last_synced_at),raw_json=VALUES(raw_json),updated_at=CURRENT_TIMESTAMP;

INSERT INTO loan_account (user_id,institution_id,loan_no_masked,product_name,account_type_code,account_status_code,repayment_method_code,currency,principal,outstanding_balance,interest_rate,start_date,maturity_date,monthly_payment,next_payment_date,last_synced_at,raw_json)
SELECT u.id,i.id,'LN-TEST-****-2002','KB 생활안정 신용대출','3001','01','01','KRW',3000000.00,2100000.00,5.1000,'2026-04-10','2027-04-10',312000.00,'2026-09-05','2026-08-31 23:00:00',JSON_OBJECT('scenarioKey','demo-normal-user2') FROM mock_user u JOIN financial_institution i ON i.institution_code='0004' WHERE u.scenario_key='1'
ON DUPLICATE KEY UPDATE principal=VALUES(principal),outstanding_balance=VALUES(outstanding_balance),next_payment_date=VALUES(next_payment_date),last_synced_at=VALUES(last_synced_at),raw_json=VALUES(raw_json),updated_at=CURRENT_TIMESTAMP;

INSERT INTO securities_account (user_id,institution_id,account_no_masked,product_name,account_type_code,account_status_code,currency,cash_balance,valuation_amount,last_synced_at,raw_json)
SELECT u.id,i.id,'301-***-INV2002','KB 증권 투자계좌','4001','01','KRW',0.00,1674000.00,'2026-08-31 23:00:00',JSON_OBJECT('scenarioKey','demo-normal-user2') FROM mock_user u JOIN financial_institution i ON i.institution_code='0301' WHERE u.scenario_key='1'
ON DUPLICATE KEY UPDATE cash_balance=VALUES(cash_balance),valuation_amount=VALUES(valuation_amount),last_synced_at=VALUES(last_synced_at),raw_json=VALUES(raw_json),updated_at=CURRENT_TIMESTAMP;

INSERT INTO bank_transaction (bank_account_id,original_transaction_id,transacted_at,trans_type_code,trans_type_name,amount,balance_after,description,raw_json)
SELECT b.id,x.tid,x.at,x.code,x.type,x.amount,x.bal,x.descr,JSON_OBJECT('correlationId',x.corr,'challengeEligible',IF(x.challenge=1, TRUE, FALSE),'challengeCategory',x.category,'merchantName',x.merchant,'mcc',x.mcc)
FROM bank_account b JOIN mock_user u ON u.id=b.user_id
JOIN (
 SELECT 'N2-B-001' tid,'2026-04-01 09:00:00' at,'01' code,'입금' type,3000000 amount,3000000 bal,'기초 잔액 이관' descr,'N2-OPEN' corr,0 challenge,NULL category,NULL merchant,NULL mcc UNION ALL
 SELECT 'N2-B-002','2026-04-10 10:00:00','01','입금',3000000,6000000,'대출 실행금 입금','N2-LOAN-EXEC',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-003','2026-04-15 09:05:00','02','출금',300000,5700000,'적금 납입','N2-DEP-04',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-004','2026-04-20 18:00:00','02','출금',100000,5600000,'KB Pay 머니 충전','N2-PAY-04',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-005','2026-04-25 08:30:00','01','입금',3400000,9000000,'급여','N2-SAL-04',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-006','2026-05-15 09:05:00','02','출금',300000,8700000,'적금 납입','N2-DEP-05',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-007','2026-05-25 08:30:00','01','입금',3400000,12100000,'급여','N2-SAL-05',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-008','2026-06-05 09:00:00','02','출금',315000,11785000,'대출 원리금 상환','N2-LOAN-06',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-009','2026-06-10 09:05:00','02','출금',300000,11485000,'적금 납입','N2-DEP-06',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-010','2026-06-12 18:00:00','02','출금',150000,11335000,'KB Pay 머니 충전','N2-PAY-06',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-011','2026-06-17 12:20:00','02','출금',50000,11285000,'GS25 역삼센터점','N2-CHK-0617',1,'편의점','GS25 역삼센터점','5499' UNION ALL
 SELECT 'N2-B-012','2026-06-23 08:10:00','02','출금',35000,11250000,'카카오T','N2-CHK-0623',1,'교통','카카오T','4111' UNION ALL
 SELECT 'N2-B-013','2026-06-25 08:30:00','01','입금',3400000,14650000,'급여','N2-SAL-06',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-014','2026-06-29 09:10:00','02','출금',700000,13950000,'증권 매수대금','N2-SEC-BUY-06',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-015','2026-07-05 09:00:00','02','출금',313000,13637000,'대출 원리금 상환','N2-LOAN-07',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-016','2026-07-10 09:05:00','02','출금',300000,13337000,'적금 납입','N2-DEP-07',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-017','2026-07-12 18:00:00','02','출금',200000,13137000,'KB Pay 머니 충전','N2-PAY-07',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-018','2026-07-14 09:00:00','02','출금',270000,12867000,'카드 이용대금','N2-CARD-BILL-06',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-019','2026-07-17 19:10:00','02','출금',70000,12797000,'다이소 강남역점','N2-CHK-0717',1,'생활용품','다이소 강남역점','5331' UNION ALL
 SELECT 'N2-B-020','2026-07-21 12:10:00','02','출금',40000,12757000,'CU 역삼점','N2-CHK-0721',1,'편의점','CU 역삼점','5499' UNION ALL
 SELECT 'N2-B-021','2026-07-23 08:10:00','02','출금',35000,12722000,'카카오T','N2-CHK-0723',1,'교통','카카오T','4111' UNION ALL
 SELECT 'N2-B-022','2026-07-25 08:30:00','01','입금',3400000,16122000,'급여','N2-SAL-07',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-023','2026-07-29 09:10:00','02','출금',1000000,15122000,'증권 매수대금','N2-SEC-BUY-07',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-024','2026-08-05 09:00:00','02','출금',312000,14810000,'대출 원리금 상환','N2-LOAN-08',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-025','2026-08-10 09:05:00','02','출금',300000,14510000,'적금 납입','N2-DEP-08',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-026','2026-08-12 18:00:00','02','출금',150000,14360000,'KB Pay 머니 충전','N2-PAY-08',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-027','2026-08-14 09:00:00','02','출금',477000,13883000,'카드 이용대금','N2-CARD-BILL-07',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-028','2026-08-17 12:20:00','02','출금',50000,13833000,'GS25 역삼센터점','N2-CHK-0817',1,'편의점','GS25 역삼센터점','5499' UNION ALL
 SELECT 'N2-B-029','2026-08-22 08:10:00','02','출금',30000,13803000,'카카오T','N2-CHK-0822',1,'교통','카카오T','4111' UNION ALL
 SELECT 'N2-B-030','2026-08-25 08:30:00','01','입금',3400000,17203000,'급여','N2-SAL-08',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-031','2026-08-28 15:10:00','01','입금',150000,17353000,'증권 매도대금','N2-SEC-SELL-08',0,NULL,NULL,NULL UNION ALL
 SELECT 'N2-B-032','2026-08-31 23:00:00','01','입금',145000,17498000,'월말 정산 이체','N2-MONTH-END',0,NULL,NULL,NULL
) x ON b.account_no_masked='110-***-120045' WHERE u.scenario_key='1'
ON DUPLICATE KEY UPDATE transacted_at=VALUES(transacted_at),trans_type_code=VALUES(trans_type_code),trans_type_name=VALUES(trans_type_name),amount=VALUES(amount),balance_after=VALUES(balance_after),description=VALUES(description),raw_json=VALUES(raw_json),updated_at=CURRENT_TIMESTAMP;

INSERT INTO bank_transaction (bank_account_id,original_transaction_id,transacted_at,trans_type_code,trans_type_name,amount,balance_after,description,raw_json)
SELECT b.id,'N2-B-INV-OPEN','2026-04-01 09:01:00','01','입금',0.00,0.00,'투자자금 계좌 기초잔액',JSON_OBJECT('challengeEligible',false) FROM bank_account b JOIN mock_user u ON u.id=b.user_id
WHERE u.scenario_key='1' AND b.account_no_masked='110-***-840921'
ON DUPLICATE KEY UPDATE transacted_at=VALUES(transacted_at),amount=VALUES(amount),balance_after=VALUES(balance_after),raw_json=VALUES(raw_json),updated_at=CURRENT_TIMESTAMP;

INSERT INTO card_approval (card_id,approval_no,approved_at,approval_type_code,approval_type_name,merchant_name,merchant_business_no,merchant_category_code,merchant_category_name,approved_amount,currency,description,raw_json)
SELECT c.id,x.no,x.at,x.kind,IF(x.kind='01','승인','취소'),x.merchant,'000-00-00000',x.mcc,x.cat,x.amount,'KRW',x.merchant,JSON_OBJECT('correlationId',CASE x.no WHEN 'N2-D-0617' THEN 'N2-CHK-0617' WHEN 'N2-D-0623' THEN 'N2-CHK-0623' WHEN 'N2-D-0717' THEN 'N2-CHK-0717' WHEN 'N2-D-0721' THEN 'N2-CHK-0721' WHEN 'N2-D-0723' THEN 'N2-CHK-0723' WHEN 'N2-D-0817' THEN 'N2-CHK-0817' WHEN 'N2-D-0822' THEN 'N2-CHK-0822' ELSE NULL END,'challengeEligible',true,'challengeCategory',x.challenge,'originalApprovalNo',x.originalNo)
FROM card c JOIN mock_user u ON u.id=c.user_id JOIN (
 SELECT '9490-****-****-2201' card,'N2-C-0610' no,'2026-06-10 19:00:00' at,'01' kind,'이마트 역삼점' merchant,'5411' mcc,'대형마트·식료품' cat,120000 amount,'마트' challenge,NULL originalNo UNION ALL SELECT '9490-****-****-2201','N2-C-0615','2026-06-15 15:10:00','01','스타벅스 강남역점','5814','카페',50000,'카페',NULL UNION ALL SELECT '9490-****-****-2201','N2-C-0620','2026-06-20 21:00:00','01','쿠팡','5999','온라인 쇼핑',100000,'쇼핑',NULL UNION ALL SELECT '5210-****-****-7714','N2-D-0617','2026-06-17 12:20:00','01','GS25 역삼센터점','5499','편의점',50000,'편의점',NULL UNION ALL SELECT '5210-****-****-7714','N2-D-0623','2026-06-23 08:10:00','01','카카오T','4111','교통',35000,'교통',NULL UNION ALL
 SELECT '9490-****-****-2201','N2-C-0710','2026-07-10 20:00:00','01','쿠팡','5999','온라인 쇼핑',300000,'쇼핑',NULL UNION ALL SELECT '9490-****-****-2201','N2-C-0714','2026-07-14 18:10:00','01','이마트 역삼점','5411','대형마트·식료품',100000,'마트',NULL UNION ALL SELECT '9490-****-****-2201','N2-C-0718','2026-07-18 10:20:00','01','스타벅스 강남역점','5814','카페',40000,'카페',NULL UNION ALL SELECT '9490-****-****-2201','N2-C-0720','2026-07-20 09:00:00','01','SK텔레콤','4814','통신 서비스',20000,'통신',NULL UNION ALL SELECT '9490-****-****-2201','N2-C-0728','2026-07-28 09:00:00','01','넷플릭스','4899','디지털 콘텐츠·구독',17000,'구독',NULL UNION ALL SELECT '5210-****-****-7714','N2-D-0717','2026-07-17 19:10:00','01','다이소 강남역점','5331','생활용품',70000,'생활용품',NULL UNION ALL SELECT '5210-****-****-7714','N2-D-0721','2026-07-21 12:10:00','01','CU 역삼점','5499','편의점',40000,'편의점',NULL UNION ALL SELECT '5210-****-****-7714','N2-D-0723','2026-07-23 08:10:00','01','카카오T','4111','교통',35000,'교통',NULL UNION ALL
 SELECT '9490-****-****-2201','N2-C-0810','2026-08-10 20:00:00','01','쿠팡','5999','온라인 쇼핑',250000,'쇼핑',NULL UNION ALL SELECT '9490-****-****-2201','N2-C-0814','2026-08-14 18:10:00','01','이마트 역삼점','5411','대형마트·식료품',100000,'마트',NULL UNION ALL SELECT '9490-****-****-2201','N2-C-0814-C','2026-08-15 09:00:00','03','이마트 역삼점','5411','대형마트·식료품',-20000,'마트','N2-C-0814' UNION ALL SELECT '9490-****-****-2201','N2-C-0818','2026-08-18 10:20:00','01','스타벅스 강남역점','5814','카페',55000,'카페',NULL UNION ALL SELECT '9490-****-****-2201','N2-C-0828','2026-08-28 09:00:00','01','넷플릭스','4899','디지털 콘텐츠·구독',17000,'구독',NULL UNION ALL SELECT '5210-****-****-7714','N2-D-0817','2026-08-17 12:20:00','01','GS25 역삼센터점','5499','편의점',50000,'편의점',NULL UNION ALL SELECT '5210-****-****-7714','N2-D-0822','2026-08-22 08:10:00','01','카카오T','4111','교통',30000,'교통',NULL
) x ON x.card=c.card_no_masked WHERE u.scenario_key='1'
ON DUPLICATE KEY UPDATE approved_at=VALUES(approved_at),approval_type_code=VALUES(approval_type_code),merchant_name=VALUES(merchant_name),merchant_category_code=VALUES(merchant_category_code),merchant_category_name=VALUES(merchant_category_name),approved_amount=VALUES(approved_amount),raw_json=VALUES(raw_json),updated_at=CURRENT_TIMESTAMP;

-- Two ordinary credit-card purchases every day; existing check-card purchases add variation on selected days.
INSERT INTO card_approval (card_id,approval_no,approved_at,approval_type_code,approval_type_name,merchant_name,merchant_business_no,merchant_category_code,merchant_category_name,approved_amount,currency,description,raw_json)
WITH RECURSIVE challenge_days AS (
  SELECT DATE('2026-06-01') AS purchase_date
  UNION ALL
  SELECT DATE_ADD(purchase_date, INTERVAL 1 DAY) FROM challenge_days WHERE purchase_date < '2026-08-31'
)
SELECT c.id,
       CONCAT('N2-DAILY-', DATE_FORMAT(d.purchase_date, '%Y%m%d'), '-', x.suffix),
       TIMESTAMP(d.purchase_date, x.purchase_time),
       '01', '승인',
       CASE WHEN x.suffix='A' THEN x.merchant ELSE CASE MOD(DATEDIFF(d.purchase_date, '2026-06-01'), 22)
         WHEN 0 THEN '이바돔감자탕 강남점' WHEN 1 THEN '신의주찹쌀순대 역삼점'
         WHEN 2 THEN '맥도날드 역삼점' WHEN 3 THEN '피자헛 강남점'
         WHEN 4 THEN '버거킹 역삼점' WHEN 5 THEN '현대옥 콩나물국밥 강남점'
         WHEN 6 THEN '명동교자 강남점' WHEN 7 THEN '홍콩반점 강남역점'
         WHEN 8 THEN '역전우동 강남점' WHEN 9 THEN '맘스터치 역삼점'
         WHEN 10 THEN '본죽 강남역점' WHEN 11 THEN '교촌치킨 역삼1호점'
         WHEN 12 THEN '배달의민족' WHEN 13 THEN '쿠팡이츠'
         WHEN 14 THEN '죠스떡볶이 강남점' WHEN 15 THEN '포메인 강남역점'
         WHEN 16 THEN '스시로 강남점' WHEN 17 THEN '샐러디 역삼점'
         WHEN 18 THEN '김가네 강남역점' WHEN 19 THEN '육전식당 강남점'
         WHEN 20 THEN '한솥도시락 강남역점' ELSE '탕화쿵푸마라탕 강남점' END END,
       '000-00-00000',
       CASE WHEN x.suffix='A' THEN x.mcc ELSE CASE MOD(DATEDIFF(d.purchase_date, '2026-06-01'), 22) WHEN 2 THEN '5814' WHEN 4 THEN '5814' WHEN 9 THEN '5814' ELSE '5812' END END,
       CASE WHEN x.suffix='A' THEN x.category ELSE CASE MOD(DATEDIFF(d.purchase_date, '2026-06-01'), 22) WHEN 2 THEN '패스트푸드' WHEN 4 THEN '패스트푸드' WHEN 9 THEN '패스트푸드' ELSE '음식점' END END,
       x.amount, 'KRW',
       CASE WHEN x.suffix='A' THEN x.merchant ELSE '일상 식사 결제' END,
       JSON_OBJECT('challengeEligible', true, 'challengeCategory', CASE WHEN x.suffix='A' THEN x.challenge_category ELSE '식비' END, 'dailyChallengeSeed', true)
FROM challenge_days d
CROSS JOIN (SELECT 'A' suffix, '08:25:00' purchase_time, '스타벅스 강남역점' merchant, '5814' mcc, '카페' category, 5800.00 amount, '카페' challenge_category
      UNION ALL SELECT 'B', '18:40:00', '일상 식사 결제', '5812', '음식점', 7500.00, '식비') x
JOIN card c ON c.card_no_masked='9490-****-****-2201'
JOIN mock_user u ON u.id=c.user_id AND u.scenario_key='1'
WHERE TRUE
ON DUPLICATE KEY UPDATE approved_at=VALUES(approved_at),merchant_name=VALUES(merchant_name),merchant_category_code=VALUES(merchant_category_code),merchant_category_name=VALUES(merchant_category_name),approved_amount=VALUES(approved_amount),raw_json=VALUES(raw_json),updated_at=CURRENT_TIMESTAMP;

INSERT INTO card_bill (card_id,billing_month,due_date,bill_status_code,bill_status_name,total_amount,paid_amount,raw_json)
SELECT c.id,x.month,x.due,x.status,x.name,x.total,x.paid,JSON_OBJECT('includedApprovalAmount',x.total,'paymentCorrelationId',x.corr) FROM card c JOIN mock_user u ON u.id=c.user_id JOIN (SELECT '2026-06-01' month,'2026-07-14' due,'02' status,'결제완료' name,669000 total,669000 paid,'N2-CARD-BILL-06' corr UNION ALL SELECT '2026-07-01','2026-08-14','02','결제완료',889300,889300,'N2-CARD-BILL-07' UNION ALL SELECT '2026-08-01','2026-08-31','01','청구확정',814300,0,'N2-CARD-BILL-08') x
WHERE u.scenario_key='1' AND c.card_no_masked='9490-****-****-2201'
ON DUPLICATE KEY UPDATE due_date=VALUES(due_date),bill_status_code=VALUES(bill_status_code),bill_status_name=VALUES(bill_status_name),total_amount=VALUES(total_amount),paid_amount=VALUES(paid_amount),raw_json=VALUES(raw_json),updated_at=CURRENT_TIMESTAMP;

INSERT INTO pay_money_transaction (pay_money_id,original_transaction_id,transacted_at,trans_type_code,trans_type_name,amount,balance_after,point_amount,point_balance_after,merchant_name,merchant_category_code,merchant_category_name,description,raw_json)
SELECT p.id,x.id,x.at,x.code,x.type,x.amount,x.balance,x.points,x.pointBalance,x.merchant,x.mcc,x.category,x.merchant,JSON_OBJECT('correlationId',x.corr,'challengeEligible',IF(x.challenge=1, TRUE, FALSE),'challengeCategory',x.challengeCategory,'originalTransactionId',x.original)
FROM pay_money p JOIN mock_user u ON u.id=p.user_id JOIN (
 SELECT 'N2-P-04C' id,'2026-04-20 18:00:01' at,'01' code,'충전' type,100000 amount,100000 balance,NULL points,0 pointBalance,NULL merchant,NULL mcc,NULL category,'N2-PAY-04' corr,0 challenge,NULL challengeCategory,NULL original UNION ALL SELECT 'N2-P-04P','2026-04-21 12:00:00','02','결제',-100000,0,NULL,0,'맥도날드 역삼점','5814','패스트푸드','N2-P-04',1,'식비',NULL UNION ALL
 SELECT 'N2-P-06C','2026-06-12 18:00:01','01','충전',150000,150000,NULL,0,NULL,NULL,NULL,'N2-PAY-06',0,NULL,NULL UNION ALL SELECT 'N2-P-0615','2026-06-15 12:30:00','02','결제',-70000,80000,NULL,0,'배달의민족','5812','음식점','N2-PAY-0615',1,'식비',NULL UNION ALL SELECT 'N2-P-0619','2026-06-19 19:00:00','02','결제',-25000,55000,NULL,0,'올리브영 강남점','5977','화장품·생활용품','N2-PAY-0619',1,'생활용품',NULL UNION ALL SELECT 'N2-P-0626','2026-06-26 08:40:00','02','결제',-30000,25000,NULL,0,'스타벅스 강남역점','5814','카페','N2-PAY-0626',1,'카페',NULL UNION ALL SELECT 'N2-P-0627','2026-06-27 10:00:00','03','환불',10000,35000,500,500,'배달의민족','5812','음식점','N2-PAY-0615',1,'식비','N2-P-0615' UNION ALL
 SELECT 'N2-P-07C','2026-07-12 18:00:01','01','충전',200000,235000,NULL,500,NULL,NULL,NULL,'N2-PAY-07',0,NULL,NULL UNION ALL SELECT 'N2-P-0716','2026-07-16 12:30:00','02','결제',-80000,155000,NULL,500,'배달의민족','5812','음식점','N2-PAY-0716',1,'식비',NULL UNION ALL SELECT 'N2-P-0720','2026-07-20 19:00:00','02','결제',-45000,110000,NULL,500,'올리브영 강남점','5977','화장품·생활용품','N2-PAY-0720',1,'생활용품',NULL UNION ALL SELECT 'N2-P-0726','2026-07-26 08:40:00','02','결제',-25000,85000,NULL,500,'스타벅스 강남역점','5814','카페','N2-PAY-0726',1,'카페',NULL UNION ALL SELECT 'N2-P-0727','2026-07-27 10:00:00','03','환불',10000,95000,300,800,'배달의민족','5812','음식점','N2-PAY-0716',1,'식비','N2-P-0716' UNION ALL
 SELECT 'N2-P-08C','2026-08-12 18:00:01','01','충전',150000,245000,NULL,800,NULL,NULL,NULL,'N2-PAY-08',0,NULL,NULL UNION ALL SELECT 'N2-P-0816','2026-08-16 12:30:00','02','결제',-55000,190000,NULL,800,'배달의민족','5812','음식점','N2-PAY-0816',1,'식비',NULL UNION ALL SELECT 'N2-P-0820','2026-08-20 19:00:00','02','결제',-35000,155000,NULL,800,'올리브영 강남점','5977','화장품·생활용품','N2-PAY-0820',1,'생활용품',NULL UNION ALL SELECT 'N2-P-0826','2026-08-26 08:40:00','02','결제',-25000,130000,NULL,800,'스타벅스 강남역점','5814','카페','N2-PAY-0826',1,'카페',NULL
) x WHERE u.scenario_key='1' AND p.wallet_id='wallet-demo-normal-002'
ON DUPLICATE KEY UPDATE transacted_at=VALUES(transacted_at),amount=VALUES(amount),balance_after=VALUES(balance_after),point_amount=VALUES(point_amount),point_balance_after=VALUES(point_balance_after),merchant_name=VALUES(merchant_name),raw_json=VALUES(raw_json),updated_at=CURRENT_TIMESTAMP;

INSERT INTO deposit_transaction (deposit_account_id,original_transaction_id,transacted_at,trans_type_code,trans_type_name,amount,balance_after,description,raw_json)
SELECT d.id,x.id,x.at,'01','납입',300000,x.balance,'정기 적금 납입',JSON_OBJECT('correlationId',x.corr,'challengeEligible',false) FROM deposit_account d JOIN mock_user u ON u.id=d.user_id JOIN (SELECT 'N2-D-04' id,'2026-04-15 09:05:01' at,300000 balance,'N2-DEP-04' corr UNION ALL SELECT 'N2-D-05','2026-05-15 09:05:01',600000,'N2-DEP-05' UNION ALL SELECT 'N2-D-06','2026-06-10 09:05:01',900000,'N2-DEP-06' UNION ALL SELECT 'N2-D-07','2026-07-10 09:05:01',1200000,'N2-DEP-07' UNION ALL SELECT 'N2-D-08','2026-08-10 09:05:01',1500000,'N2-DEP-08') x WHERE u.scenario_key='1' AND d.account_no_masked='110-***-SAVING2'
ON DUPLICATE KEY UPDATE transacted_at=VALUES(transacted_at),amount=VALUES(amount),balance_after=VALUES(balance_after),raw_json=VALUES(raw_json),updated_at=CURRENT_TIMESTAMP;

INSERT INTO loan_transaction (loan_account_id,original_transaction_id,transacted_at,trans_type_code,trans_type_name,amount,principal_amount,interest_amount,balance_after,description,raw_json)
SELECT l.id,x.id,x.at,x.code,x.type,x.amount,x.principal,x.interest,x.balance,x.type,JSON_OBJECT('correlationId',x.corr,'challengeEligible',false) FROM loan_account l JOIN mock_user u ON u.id=l.user_id JOIN (SELECT 'N2-L-EXEC' id,'2026-04-10 10:00:01' at,'01' code,'대출 실행' type,3000000 amount,3000000 principal,0 interest,3000000 balance,'N2-LOAN-EXEC' corr UNION ALL SELECT 'N2-L-06','2026-06-05 09:00:01','02','원리금 상환',315000,300000,15000,2700000,'N2-LOAN-06' UNION ALL SELECT 'N2-L-07','2026-07-05 09:00:01','02','원리금 상환',313000,300000,13000,2400000,'N2-LOAN-07' UNION ALL SELECT 'N2-L-08','2026-08-05 09:00:01','02','원리금 상환',312000,300000,12000,2100000,'N2-LOAN-08') x WHERE u.scenario_key='1' AND l.loan_no_masked='LN-TEST-****-2002'
ON DUPLICATE KEY UPDATE transacted_at=VALUES(transacted_at),amount=VALUES(amount),principal_amount=VALUES(principal_amount),interest_amount=VALUES(interest_amount),balance_after=VALUES(balance_after),raw_json=VALUES(raw_json),updated_at=CURRENT_TIMESTAMP;

INSERT INTO securities_holding (securities_account_id,product_code,product_name,market_country_code,currency,quantity,average_purchase_price,last_price,purchase_amount,market_value,profit_loss_amount,profit_loss_rate,valuation_at,raw_json)
SELECT a.id,x.code,x.name,'KR','KRW',x.qty,x.avg,x.last,x.cost,x.value,x.pnl,x.rate,'2026-08-31 23:00:00',JSON_OBJECT('scenarioKey','demo-normal-user2') FROM securities_account a JOIN mock_user u ON u.id=a.user_id JOIN (SELECT '005930' code,'삼성전자' name,8.000000 qty,70000 avg,78000 last,560000 cost,624000 value,64000 pnl,11.4286 rate UNION ALL SELECT '000660','SK하이닉스',5.000000,200000,210000,1000000,1050000,50000,5.0000) x WHERE u.scenario_key='1' AND a.account_no_masked='301-***-INV2002'
ON DUPLICATE KEY UPDATE quantity=VALUES(quantity),average_purchase_price=VALUES(average_purchase_price),last_price=VALUES(last_price),purchase_amount=VALUES(purchase_amount),market_value=VALUES(market_value),profit_loss_amount=VALUES(profit_loss_amount),profit_loss_rate=VALUES(profit_loss_rate),valuation_at=VALUES(valuation_at),raw_json=VALUES(raw_json),updated_at=CURRENT_TIMESTAMP;

INSERT INTO securities_transaction (securities_account_id,original_transaction_id,transacted_at,trans_type_code,trans_type_name,product_code,product_name,quantity,unit_price,transaction_amount,description,raw_json)
SELECT a.id,x.id,x.at,x.code,x.type,x.product,x.name,x.qty,x.price,x.amount,x.name,JSON_OBJECT('correlationId',x.corr,'challengeEligible',false) FROM securities_account a JOIN mock_user u ON u.id=a.user_id JOIN (SELECT 'N2-S-06' id,'2026-06-29 09:10:01' at,'01' code,'매수' type,'005930' product,'삼성전자' name,10.000000 qty,70000 price,700000 amount,'N2-SEC-BUY-06' corr UNION ALL SELECT 'N2-S-07','2026-07-29 09:10:01','01','매수','000660','SK하이닉스',5.000000,200000,1000000,'N2-SEC-BUY-07' UNION ALL SELECT 'N2-S-08','2026-08-28 15:10:01','02','매도','005930','삼성전자',2.000000,75000,150000,'N2-SEC-SELL-08') x WHERE u.scenario_key='1' AND a.account_no_masked='301-***-INV2002'
ON DUPLICATE KEY UPDATE transacted_at=VALUES(transacted_at),trans_type_code=VALUES(trans_type_code),quantity=VALUES(quantity),unit_price=VALUES(unit_price),transaction_amount=VALUES(transaction_amount),raw_json=VALUES(raw_json),updated_at=CURRENT_TIMESTAMP;

-- Reconcile completed June/July credit-card bills with the daily approvals above.
UPDATE bank_transaction t
JOIN bank_account b ON b.id=t.bank_account_id
JOIN mock_user u ON u.id=b.user_id
SET t.amount = CASE t.original_transaction_id
                 WHEN 'N2-B-018' THEN 669000.00
                 WHEN 'N2-B-027' THEN 889300.00
                 ELSE t.amount
               END,
    t.balance_after = CASE t.original_transaction_id
                 WHEN 'N2-B-018' THEN 12468000.00
                 WHEN 'N2-B-019' THEN 12398000.00
                 WHEN 'N2-B-020' THEN 12358000.00
                 WHEN 'N2-B-021' THEN 12323000.00
                 WHEN 'N2-B-022' THEN 15723000.00
                 WHEN 'N2-B-023' THEN 14723000.00
                 WHEN 'N2-B-024' THEN 14411000.00
                 WHEN 'N2-B-025' THEN 14111000.00
                 WHEN 'N2-B-026' THEN 13961000.00
                 WHEN 'N2-B-027' THEN 13071700.00
                 WHEN 'N2-B-028' THEN 13021700.00
                 WHEN 'N2-B-029' THEN 12991700.00
                 WHEN 'N2-B-030' THEN 16391700.00
                 WHEN 'N2-B-031' THEN 16541700.00
                 WHEN 'N2-B-032' THEN 16686700.00
                 ELSE t.balance_after
               END,
    t.updated_at = CURRENT_TIMESTAMP
WHERE u.scenario_key='1'
  AND t.original_transaction_id IN ('N2-B-018','N2-B-019','N2-B-020','N2-B-021','N2-B-022','N2-B-023','N2-B-024','N2-B-025','N2-B-026','N2-B-027','N2-B-028','N2-B-029','N2-B-030','N2-B-031','N2-B-032');
