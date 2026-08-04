-- v3: 본레포 연동 테스트용 실제 유저 id=1을 demo-normal-user와 동일한
-- 시나리오(은행/증권/대출/페이머니 정상 데이터)로 매핑한다.
-- init.sql, init_v2.sql 실행 이후에 적용한다.
-- demo-normal-user는 그대로 유지하고, scenario_key='1'인 별도 사용자를 추가한다.

USE financial_mock;

-- 1. 본레포 실제 유저 id=1에 대응하는 mock_user
INSERT INTO mock_user (scenario_key, nickname, email)
VALUES ('1', '본레포 연동 테스트 유저', NULL)
ON DUPLICATE KEY UPDATE
  nickname = VALUES(nickname),
  is_active = 1,
  updated_at = CURRENT_TIMESTAMP;

-- 2. CODEF 연결 (국민은행)
INSERT INTO mock_codef_connection (
  user_id, institution_id, connected_id, status, consent_expired_at, last_synced_at
)
SELECT
  u.id, i.id, 'conn-user-1-kb', 'CONNECTED', '2027-07-31 23:59:59', '2026-07-31 10:30:00'
FROM mock_user u
JOIN mock_codef_institution i ON i.codef_org_code = '0004'
WHERE u.scenario_key = '1'
ON DUPLICATE KEY UPDATE
  status = VALUES(status),
  consent_expired_at = VALUES(consent_expired_at),
  last_synced_at = VALUES(last_synced_at),
  updated_at = CURRENT_TIMESTAMP;

-- 3. 계좌 5건 (입출금/예적금/증권/대출/페이머니)
INSERT INTO mock_codef_account (
  connection_id, institution_id, account_type, account_no_masked, account_no_encrypted,
  account_name, currency, status, opened_at, raw_json
)
SELECT c.id, c.institution_id, 'DEMAND_DEPOSIT', '123456******7890', 'mock-encrypted-account-001',
  'KB Star 입출금통장', 'KRW', 'ACTIVE', '2024-01-15',
  JSON_OBJECT('resAccount', '123456******7890', 'resAccountName', 'KB Star 입출금통장',
    'resAccountDeposit', '보통예금', 'resAccountCurrency', 'KRW')
FROM mock_codef_connection c WHERE c.connected_id = 'conn-user-1-kb'
ON DUPLICATE KEY UPDATE account_name = VALUES(account_name), currency = VALUES(currency),
  status = VALUES(status), raw_json = VALUES(raw_json), updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_account (
  connection_id, institution_id, account_type, account_no_masked, account_no_encrypted,
  account_name, currency, status, opened_at, raw_json
)
SELECT c.id, c.institution_id, 'SAVINGS', '110234******5678', 'mock-encrypted-savings-001',
  'KB 정기예금', 'KRW', 'ACTIVE', '2025-06-01',
  JSON_OBJECT('resAccount', '110234******5678', 'resAccountName', 'KB 정기예금',
    'resAccountDeposit', '정기예금', 'resAccountCurrency', 'KRW')
FROM mock_codef_connection c WHERE c.connected_id = 'conn-user-1-kb'
ON DUPLICATE KEY UPDATE account_name = VALUES(account_name), currency = VALUES(currency),
  status = VALUES(status), raw_json = VALUES(raw_json), updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_account (
  connection_id, institution_id, account_type, account_no_masked, account_no_encrypted,
  account_name, currency, status, opened_at, raw_json
)
SELECT c.id, c.institution_id, 'STOCK', '987654******3210', 'mock-encrypted-stock-account-001',
  'KB증권 종합위탁', 'KRW', 'ACTIVE', '2024-03-20',
  JSON_OBJECT('resAccount', '987654******3210', 'resAccountName', 'KB증권 종합위탁',
    'resAccountType', 'STOCK', 'resAccountCurrency', 'KRW')
FROM mock_codef_connection c WHERE c.connected_id = 'conn-user-1-kb'
ON DUPLICATE KEY UPDATE account_name = VALUES(account_name), currency = VALUES(currency),
  status = VALUES(status), raw_json = VALUES(raw_json), updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_account (
  connection_id, institution_id, account_type, account_no_masked, account_no_encrypted,
  account_name, currency, status, opened_at, raw_json
)
SELECT c.id, c.institution_id, 'LOAN', '555555******1111', 'mock-encrypted-loan-account-001',
  'KB 직장인 신용대출', 'KRW', 'ACTIVE', '2025-02-01',
  JSON_OBJECT('resLoanNo', '555555******1111', 'resLoanName', 'KB 직장인 신용대출',
    'resLoanType', 'CREDIT_LOAN', 'resCurrency', 'KRW')
FROM mock_codef_connection c WHERE c.connected_id = 'conn-user-1-kb'
ON DUPLICATE KEY UPDATE account_name = VALUES(account_name), currency = VALUES(currency),
  status = VALUES(status), raw_json = VALUES(raw_json), updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_account (
  connection_id, institution_id, account_type, account_no_masked, account_no_encrypted,
  account_name, currency, status, opened_at, raw_json
)
SELECT c.id, c.institution_id, 'PAY_MONEY', 'pay-****-2026', 'mock-encrypted-pay-money-001',
  'KB Pay 머니', 'KRW', 'ACTIVE', '2026-01-10',
  JSON_OBJECT('resWalletId', 'pay-****-2026', 'resWalletName', 'KB Pay 머니',
    'resProviderName', 'KB Pay', 'resCurrency', 'KRW')
FROM mock_codef_connection c WHERE c.connected_id = 'conn-user-1-kb'
ON DUPLICATE KEY UPDATE account_name = VALUES(account_name), currency = VALUES(currency),
  status = VALUES(status), raw_json = VALUES(raw_json), updated_at = CURRENT_TIMESTAMP;

-- 4. 잔액 스냅샷 (입출금 / 예적금)
INSERT INTO mock_codef_balance_snapshot (account_id, snapshot_at, balance, available_amount, valuation_amount, raw_json)
SELECT a.id, '2026-07-31 10:30:00', 1244200.00, 1244200.00, 1244200.00,
  JSON_OBJECT('resAccountBalance', '1244200', 'resAccountAvailableBalance', '1244200', 'resAccountCurrency', 'KRW')
FROM mock_codef_account a
JOIN mock_codef_connection c ON c.id = a.connection_id
WHERE c.connected_id = 'conn-user-1-kb' AND a.account_no_masked = '123456******7890'
ON DUPLICATE KEY UPDATE balance = VALUES(balance), available_amount = VALUES(available_amount),
  valuation_amount = VALUES(valuation_amount), raw_json = VALUES(raw_json), updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_balance_snapshot (account_id, snapshot_at, balance, available_amount, valuation_amount, raw_json)
SELECT a.id, '2026-07-31 10:30:00', 10000000.00, 10000000.00, 10000000.00,
  JSON_OBJECT('resAccountBalance', '10000000', 'resAccountAvailableBalance', '10000000', 'resAccountCurrency', 'KRW')
FROM mock_codef_account a
JOIN mock_codef_connection c ON c.id = a.connection_id
WHERE c.connected_id = 'conn-user-1-kb' AND a.account_no_masked = '110234******5678'
ON DUPLICATE KEY UPDATE balance = VALUES(balance), available_amount = VALUES(available_amount),
  valuation_amount = VALUES(valuation_amount), raw_json = VALUES(raw_json), updated_at = CURRENT_TIMESTAMP;

-- 5. 증권 보유종목 2건
INSERT INTO mock_codef_stock_holding (
  account_id, stock_code, stock_name, market_country, currency, quantity, average_purchase_price,
  last_price, purchase_amount, market_value, profit_loss_amount, profit_loss_rate, valuation_at, raw_json
)
SELECT a.id, '005930', '삼성전자', 'KR', 'KRW', 12.000000, 72000.00, 78500.00, 864000.00, 942000.00,
  78000.00, 9.0278, '2026-07-31 10:30:00',
  JSON_OBJECT('resItemCode', '005930', 'resItemName', '삼성전자', 'resQuantity', '12',
    'resAveragePurchasePrice', '72000', 'resCurrentPrice', '78500', 'resValuationAmount', '942000', 'resProfitLoss', '78000')
FROM mock_codef_account a
JOIN mock_codef_connection c ON c.id = a.connection_id
WHERE c.connected_id = 'conn-user-1-kb' AND a.account_no_masked = '987654******3210'
ON DUPLICATE KEY UPDATE stock_name = VALUES(stock_name), quantity = VALUES(quantity),
  average_purchase_price = VALUES(average_purchase_price), last_price = VALUES(last_price),
  purchase_amount = VALUES(purchase_amount), market_value = VALUES(market_value),
  profit_loss_amount = VALUES(profit_loss_amount), profit_loss_rate = VALUES(profit_loss_rate),
  valuation_at = VALUES(valuation_at), raw_json = VALUES(raw_json), updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_stock_holding (
  account_id, stock_code, stock_name, market_country, currency, quantity, average_purchase_price,
  last_price, purchase_amount, market_value, profit_loss_amount, profit_loss_rate, valuation_at, raw_json
)
SELECT a.id, '035720', '카카오', 'KR', 'KRW', 8.000000, 48000.00, 45200.00, 384000.00, 361600.00,
  -22400.00, -5.8333, '2026-07-31 10:30:00',
  JSON_OBJECT('resItemCode', '035720', 'resItemName', '카카오', 'resQuantity', '8',
    'resAveragePurchasePrice', '48000', 'resCurrentPrice', '45200', 'resValuationAmount', '361600', 'resProfitLoss', '-22400')
FROM mock_codef_account a
JOIN mock_codef_connection c ON c.id = a.connection_id
WHERE c.connected_id = 'conn-user-1-kb' AND a.account_no_masked = '987654******3210'
ON DUPLICATE KEY UPDATE stock_name = VALUES(stock_name), quantity = VALUES(quantity),
  average_purchase_price = VALUES(average_purchase_price), last_price = VALUES(last_price),
  purchase_amount = VALUES(purchase_amount), market_value = VALUES(market_value),
  profit_loss_amount = VALUES(profit_loss_amount), profit_loss_rate = VALUES(profit_loss_rate),
  valuation_at = VALUES(valuation_at), raw_json = VALUES(raw_json), updated_at = CURRENT_TIMESTAMP;

-- 6. 대출 상세
INSERT INTO mock_codef_loan (
  account_id, loan_no_masked, loan_no_encrypted, loan_name, loan_type, currency, loan_amount,
  balance, interest_rate, start_date, maturity_date, monthly_payment, next_payment_date, raw_json
)
SELECT a.id, '555555******1111', 'mock-encrypted-loan-no-001', 'KB 직장인 신용대출', 'CREDIT_LOAN', 'KRW',
  20000000.00, 14200000.00, 5.1200, '2025-02-01', '2028-02-01', 615000.00, '2026-08-01',
  JSON_OBJECT('resLoanName', 'KB 직장인 신용대출', 'resLoanType', 'CREDIT_LOAN', 'resLoanAmount', '20000000',
    'resLoanBalance', '14200000', 'resInterestRate', '5.12', 'resMaturityDate', '20280201')
FROM mock_codef_account a
JOIN mock_codef_connection c ON c.id = a.connection_id
WHERE c.connected_id = 'conn-user-1-kb' AND a.account_no_masked = '555555******1111'
ON DUPLICATE KEY UPDATE loan_name = VALUES(loan_name), loan_type = VALUES(loan_type),
  loan_amount = VALUES(loan_amount), balance = VALUES(balance), interest_rate = VALUES(interest_rate),
  maturity_date = VALUES(maturity_date), monthly_payment = VALUES(monthly_payment),
  next_payment_date = VALUES(next_payment_date), raw_json = VALUES(raw_json), updated_at = CURRENT_TIMESTAMP;

-- 7. 페이머니 상세
INSERT INTO mock_codef_pay_money (
  account_id, provider_code, provider_name, wallet_id, wallet_name, currency,
  balance, available_amount, point_amount, last_synced_at, raw_json
)
SELECT a.id, 'KB_PAY', 'KB Pay', 'pay-2026-demo-u1', 'KB Pay 머니', 'KRW',
  83500.00, 83500.00, 1240.00, '2026-07-31 10:30:00',
  JSON_OBJECT('resProviderName', 'KB Pay', 'resWalletName', 'KB Pay 머니', 'resBalance', '83500',
    'resAvailableAmount', '83500', 'resPointAmount', '1240')
FROM mock_codef_account a
JOIN mock_codef_connection c ON c.id = a.connection_id
WHERE c.connected_id = 'conn-user-1-kb' AND a.account_no_masked = 'pay-****-2026'
ON DUPLICATE KEY UPDATE provider_name = VALUES(provider_name), wallet_name = VALUES(wallet_name),
  balance = VALUES(balance), available_amount = VALUES(available_amount),
  point_amount = VALUES(point_amount), last_synced_at = VALUES(last_synced_at),
  raw_json = VALUES(raw_json), updated_at = CURRENT_TIMESTAMP;

-- 8. 거래내역 12건 (은행 3 / 증권 3 / 페이머니 3 / 대출 3)
INSERT INTO mock_codef_transaction (account_id, codef_tr_key, transaction_at, merchant_name, amount, direction, balance_after, raw_json)
SELECT a.id, 'u1-bank-20260731-001', '2026-07-31 08:12:00', '스타벅스 강남점', 5800.00, 'WITHDRAW', 1244200.00,
  JSON_OBJECT('resAccountDesc1', '스타벅스 강남점', 'resAccountOut', '5800', 'resAfterTranBalance', '1244200')
FROM mock_codef_account a JOIN mock_codef_connection c ON c.id = a.connection_id
WHERE c.connected_id = 'conn-user-1-kb' AND a.account_no_masked = '123456******7890'
ON DUPLICATE KEY UPDATE merchant_name = VALUES(merchant_name), amount = VALUES(amount),
  direction = VALUES(direction), balance_after = VALUES(balance_after), raw_json = VALUES(raw_json), updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_transaction (account_id, codef_tr_key, transaction_at, merchant_name, amount, direction, balance_after, raw_json)
SELECT a.id, 'u1-bank-20260730-001', '2026-07-30 12:35:00', '쿠팡', 32900.00, 'WITHDRAW', 1250000.00,
  JSON_OBJECT('resAccountDesc1', '쿠팡', 'resAccountOut', '32900', 'resAfterTranBalance', '1250000')
FROM mock_codef_account a JOIN mock_codef_connection c ON c.id = a.connection_id
WHERE c.connected_id = 'conn-user-1-kb' AND a.account_no_masked = '123456******7890'
ON DUPLICATE KEY UPDATE merchant_name = VALUES(merchant_name), amount = VALUES(amount),
  direction = VALUES(direction), balance_after = VALUES(balance_after), raw_json = VALUES(raw_json), updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_transaction (account_id, codef_tr_key, transaction_at, merchant_name, amount, direction, balance_after, raw_json)
SELECT a.id, 'u1-bank-20260725-001', '2026-07-25 09:00:00', '급여', 2500000.00, 'DEPOSIT', 1282900.00,
  JSON_OBJECT('resAccountDesc1', '급여', 'resAccountIn', '2500000', 'resAfterTranBalance', '1282900')
FROM mock_codef_account a JOIN mock_codef_connection c ON c.id = a.connection_id
WHERE c.connected_id = 'conn-user-1-kb' AND a.account_no_masked = '123456******7890'
ON DUPLICATE KEY UPDATE merchant_name = VALUES(merchant_name), amount = VALUES(amount),
  direction = VALUES(direction), balance_after = VALUES(balance_after), raw_json = VALUES(raw_json), updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_transaction (account_id, codef_tr_key, transaction_at, merchant_name, amount, direction, balance_after, raw_json)
SELECT a.id, 'u1-stock-20260729-001', '2026-07-29 09:15:00', '삼성전자 매수', 864000.00, 'WITHDRAW', NULL,
  JSON_OBJECT('resAccountDesc1', '삼성전자 매수', 'resAccountOut', '864000', 'resStockCode', '005930', 'resQuantity', '12')
FROM mock_codef_account a JOIN mock_codef_connection c ON c.id = a.connection_id
WHERE c.connected_id = 'conn-user-1-kb' AND a.account_no_masked = '987654******3210'
ON DUPLICATE KEY UPDATE merchant_name = VALUES(merchant_name), amount = VALUES(amount),
  direction = VALUES(direction), balance_after = VALUES(balance_after), raw_json = VALUES(raw_json), updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_transaction (account_id, codef_tr_key, transaction_at, merchant_name, amount, direction, balance_after, raw_json)
SELECT a.id, 'u1-stock-20260726-001', '2026-07-26 10:02:00', '카카오 매수', 384000.00, 'WITHDRAW', NULL,
  JSON_OBJECT('resAccountDesc1', '카카오 매수', 'resAccountOut', '384000', 'resStockCode', '035720', 'resQuantity', '8')
FROM mock_codef_account a JOIN mock_codef_connection c ON c.id = a.connection_id
WHERE c.connected_id = 'conn-user-1-kb' AND a.account_no_masked = '987654******3210'
ON DUPLICATE KEY UPDATE merchant_name = VALUES(merchant_name), amount = VALUES(amount),
  direction = VALUES(direction), balance_after = VALUES(balance_after), raw_json = VALUES(raw_json), updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_transaction (account_id, codef_tr_key, transaction_at, merchant_name, amount, direction, balance_after, raw_json)
SELECT a.id, 'u1-stock-20260720-001', '2026-07-20 16:30:00', '배당금 입금', 18500.00, 'DEPOSIT', NULL,
  JSON_OBJECT('resAccountDesc1', '배당금 입금', 'resAccountIn', '18500')
FROM mock_codef_account a JOIN mock_codef_connection c ON c.id = a.connection_id
WHERE c.connected_id = 'conn-user-1-kb' AND a.account_no_masked = '987654******3210'
ON DUPLICATE KEY UPDATE merchant_name = VALUES(merchant_name), amount = VALUES(amount),
  direction = VALUES(direction), balance_after = VALUES(balance_after), raw_json = VALUES(raw_json), updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_transaction (account_id, codef_tr_key, transaction_at, merchant_name, amount, direction, balance_after, raw_json)
SELECT a.id, 'u1-pay-20260731-001', '2026-07-31 07:50:00', '페이머니 충전', 100000.00, 'DEPOSIT', 183500.00,
  JSON_OBJECT('resAccountDesc1', '페이머니 충전', 'resAccountIn', '100000', 'resAfterTranBalance', '183500')
FROM mock_codef_account a JOIN mock_codef_connection c ON c.id = a.connection_id
WHERE c.connected_id = 'conn-user-1-kb' AND a.account_no_masked = 'pay-****-2026'
ON DUPLICATE KEY UPDATE merchant_name = VALUES(merchant_name), amount = VALUES(amount),
  direction = VALUES(direction), balance_after = VALUES(balance_after), raw_json = VALUES(raw_json), updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_transaction (account_id, codef_tr_key, transaction_at, merchant_name, amount, direction, balance_after, raw_json)
SELECT a.id, 'u1-pay-20260730-001', '2026-07-30 20:14:00', 'CU 편의점', 6700.00, 'WITHDRAW', 83500.00,
  JSON_OBJECT('resAccountDesc1', 'CU 편의점', 'resAccountOut', '6700', 'resAfterTranBalance', '83500')
FROM mock_codef_account a JOIN mock_codef_connection c ON c.id = a.connection_id
WHERE c.connected_id = 'conn-user-1-kb' AND a.account_no_masked = 'pay-****-2026'
ON DUPLICATE KEY UPDATE merchant_name = VALUES(merchant_name), amount = VALUES(amount),
  direction = VALUES(direction), balance_after = VALUES(balance_after), raw_json = VALUES(raw_json), updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_transaction (account_id, codef_tr_key, transaction_at, merchant_name, amount, direction, balance_after, raw_json)
SELECT a.id, 'u1-pay-20260730-002', '2026-07-30 20:15:00', '포인트 적립', 120.00, 'DEPOSIT', 1240.00,
  JSON_OBJECT('resAccountDesc1', '포인트 적립', 'resPointIn', '120', 'resPointBalance', '1240')
FROM mock_codef_account a JOIN mock_codef_connection c ON c.id = a.connection_id
WHERE c.connected_id = 'conn-user-1-kb' AND a.account_no_masked = 'pay-****-2026'
ON DUPLICATE KEY UPDATE merchant_name = VALUES(merchant_name), amount = VALUES(amount),
  direction = VALUES(direction), balance_after = VALUES(balance_after), raw_json = VALUES(raw_json), updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_transaction (account_id, codef_tr_key, transaction_at, merchant_name, amount, direction, balance_after, raw_json)
SELECT a.id, 'u1-loan-20260701-001', '2026-07-01 09:00:00', '대출 실행', 20000000.00, 'DEPOSIT', 20000000.00,
  JSON_OBJECT('resAccountDesc1', '대출 실행', 'resAccountIn', '20000000', 'resLoanBalance', '20000000')
FROM mock_codef_account a JOIN mock_codef_connection c ON c.id = a.connection_id
WHERE c.connected_id = 'conn-user-1-kb' AND a.account_no_masked = '555555******1111'
ON DUPLICATE KEY UPDATE merchant_name = VALUES(merchant_name), amount = VALUES(amount),
  direction = VALUES(direction), balance_after = VALUES(balance_after), raw_json = VALUES(raw_json), updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_transaction (account_id, codef_tr_key, transaction_at, merchant_name, amount, direction, balance_after, raw_json)
SELECT a.id, 'u1-loan-20260715-001', '2026-07-15 09:00:00', '원리금 상환', 615000.00, 'WITHDRAW', 14200000.00,
  JSON_OBJECT('resAccountDesc1', '원리금 상환', 'resAccountOut', '615000', 'resLoanBalance', '14200000')
FROM mock_codef_account a JOIN mock_codef_connection c ON c.id = a.connection_id
WHERE c.connected_id = 'conn-user-1-kb' AND a.account_no_masked = '555555******1111'
ON DUPLICATE KEY UPDATE merchant_name = VALUES(merchant_name), amount = VALUES(amount),
  direction = VALUES(direction), balance_after = VALUES(balance_after), raw_json = VALUES(raw_json), updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_transaction (account_id, codef_tr_key, transaction_at, merchant_name, amount, direction, balance_after, raw_json)
SELECT a.id, 'u1-loan-20260715-002', '2026-07-15 09:01:00', '이자 납입', 60500.00, 'WITHDRAW', 14200000.00,
  JSON_OBJECT('resAccountDesc1', '이자 납입', 'resAccountOut', '60500', 'resLoanBalance', '14200000')
FROM mock_codef_account a JOIN mock_codef_connection c ON c.id = a.connection_id
WHERE c.connected_id = 'conn-user-1-kb' AND a.account_no_masked = '555555******1111'
ON DUPLICATE KEY UPDATE merchant_name = VALUES(merchant_name), amount = VALUES(amount),
  direction = VALUES(direction), balance_after = VALUES(balance_after), raw_json = VALUES(raw_json), updated_at = CURRENT_TIMESTAMP;
