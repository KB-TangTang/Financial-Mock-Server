CREATE DATABASE IF NOT EXISTS financial_mock
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE financial_mock;

CREATE TABLE IF NOT EXISTS mock_user (
  id BIGINT NOT NULL AUTO_INCREMENT,
  scenario_key VARCHAR(50) NOT NULL,
  nickname VARCHAR(100) NOT NULL,
  email VARCHAR(255) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_mock_user_scenario_key (scenario_key),
  KEY idx_mock_user_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS mock_scenario (
  id BIGINT NOT NULL AUTO_INCREMENT,
  scenario_code VARCHAR(50) NOT NULL,
  name VARCHAR(100) NOT NULL,
  description VARCHAR(500) NULL,
  http_status INT NOT NULL DEFAULT 200,
  app_code VARCHAR(50) NOT NULL DEFAULT 'SUCCESS',
  latency_ms INT NOT NULL DEFAULT 0,
  is_default TINYINT(1) NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_mock_scenario_code (scenario_code),
  KEY idx_mock_scenario_default (is_default, is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS mock_api_endpoint (
  id BIGINT NOT NULL AUTO_INCREMENT,
  provider VARCHAR(30) NOT NULL DEFAULT 'INTERNAL',
  method VARCHAR(10) NOT NULL,
  path VARCHAR(255) NOT NULL,
  operation_key VARCHAR(100) NOT NULL,
  description VARCHAR(500) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_mock_api_endpoint_method_path (method, path),
  UNIQUE KEY uk_mock_api_endpoint_operation_key (operation_key),
  KEY idx_mock_api_endpoint_provider (provider, is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS mock_scenario_assignment (
  id BIGINT NOT NULL AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  scenario_id BIGINT NOT NULL,
  endpoint_id BIGINT NULL,
  starts_at DATETIME NULL,
  ends_at DATETIME NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_mock_scenario_assignment (user_id, scenario_id, endpoint_id),
  KEY idx_mock_scenario_assignment_user (user_id, is_active),
  KEY idx_mock_scenario_assignment_scenario (scenario_id),
  KEY idx_mock_scenario_assignment_endpoint (endpoint_id),
  CONSTRAINT fk_mock_scenario_assignment_user
    FOREIGN KEY (user_id) REFERENCES mock_user (id),
  CONSTRAINT fk_mock_scenario_assignment_scenario
    FOREIGN KEY (scenario_id) REFERENCES mock_scenario (id),
  CONSTRAINT fk_mock_scenario_assignment_endpoint
    FOREIGN KEY (endpoint_id) REFERENCES mock_api_endpoint (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS mock_api_response_fixture (
  id BIGINT NOT NULL AUTO_INCREMENT,
  endpoint_id BIGINT NOT NULL,
  scenario_id BIGINT NOT NULL,
  fixture_name VARCHAR(100) NOT NULL,
  request_match_json JSON NULL,
  response_json JSON NOT NULL,
  http_status INT NOT NULL DEFAULT 200,
  app_code VARCHAR(50) NOT NULL DEFAULT 'SUCCESS',
  priority INT NOT NULL DEFAULT 100,
  valid_from DATETIME NULL,
  valid_to DATETIME NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_mock_api_response_fixture (endpoint_id, scenario_id, fixture_name),
  KEY idx_mock_api_response_fixture_lookup (endpoint_id, scenario_id, is_active, priority),
  CONSTRAINT fk_mock_api_response_fixture_endpoint
    FOREIGN KEY (endpoint_id) REFERENCES mock_api_endpoint (id),
  CONSTRAINT fk_mock_api_response_fixture_scenario
    FOREIGN KEY (scenario_id) REFERENCES mock_scenario (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS mock_api_call_log (
  id BIGINT NOT NULL AUTO_INCREMENT,
  endpoint_id BIGINT NOT NULL,
  scenario_id BIGINT NULL,
  user_id BIGINT NULL,
  response_fixture_id BIGINT NULL,
  request_method VARCHAR(10) NOT NULL,
  request_path VARCHAR(255) NOT NULL,
  request_json JSON NULL,
  response_status INT NOT NULL,
  trace_id VARCHAR(64) NOT NULL,
  called_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_mock_api_call_log_endpoint_called (endpoint_id, called_at),
  KEY idx_mock_api_call_log_user_called (user_id, called_at),
  KEY idx_mock_api_call_log_trace_id (trace_id),
  CONSTRAINT fk_mock_api_call_log_endpoint
    FOREIGN KEY (endpoint_id) REFERENCES mock_api_endpoint (id),
  CONSTRAINT fk_mock_api_call_log_scenario
    FOREIGN KEY (scenario_id) REFERENCES mock_scenario (id),
  CONSTRAINT fk_mock_api_call_log_user
    FOREIGN KEY (user_id) REFERENCES mock_user (id),
  CONSTRAINT fk_mock_api_call_log_fixture
    FOREIGN KEY (response_fixture_id) REFERENCES mock_api_response_fixture (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS mock_codef_institution (
  id BIGINT NOT NULL AUTO_INCREMENT,
  codef_org_code VARCHAR(50) NOT NULL,
  name VARCHAR(100) NOT NULL,
  type VARCHAR(30) NOT NULL,
  is_supported TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_mock_codef_institution_org_code (codef_org_code),
  KEY idx_mock_codef_institution_type (type, is_supported)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS mock_codef_connection (
  id BIGINT NOT NULL AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  institution_id BIGINT NOT NULL,
  connected_id VARCHAR(100) NOT NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'CONNECTED',
  consent_expired_at DATETIME NULL,
  last_synced_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_mock_codef_connection_connected_id (connected_id),
  KEY idx_mock_codef_connection_user (user_id, status),
  KEY idx_mock_codef_connection_institution (institution_id),
  CONSTRAINT fk_mock_codef_connection_user
    FOREIGN KEY (user_id) REFERENCES mock_user (id),
  CONSTRAINT fk_mock_codef_connection_institution
    FOREIGN KEY (institution_id) REFERENCES mock_codef_institution (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS mock_codef_account (
  id BIGINT NOT NULL AUTO_INCREMENT,
  connection_id BIGINT NOT NULL,
  institution_id BIGINT NOT NULL,
  account_type VARCHAR(30) NOT NULL,
  account_no_masked VARCHAR(100) NOT NULL,
  account_no_encrypted VARCHAR(255) NULL,
  account_name VARCHAR(100) NULL,
  currency CHAR(3) NOT NULL DEFAULT 'KRW',
  status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',
  opened_at DATE NULL,
  raw_json JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_mock_codef_account_connection_no (connection_id, account_no_masked),
  KEY idx_mock_codef_account_connection (connection_id, status),
  KEY idx_mock_codef_account_institution (institution_id, account_type),
  CONSTRAINT fk_mock_codef_account_connection
    FOREIGN KEY (connection_id) REFERENCES mock_codef_connection (id),
  CONSTRAINT fk_mock_codef_account_institution
    FOREIGN KEY (institution_id) REFERENCES mock_codef_institution (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS mock_codef_transaction (
  id BIGINT NOT NULL AUTO_INCREMENT,
  account_id BIGINT NOT NULL,
  codef_tr_key VARCHAR(100) NOT NULL,
  transaction_at DATETIME NOT NULL,
  merchant_name VARCHAR(255) NULL,
  amount DECIMAL(18,2) NOT NULL,
  direction VARCHAR(20) NOT NULL,
  balance_after DECIMAL(18,2) NULL,
  raw_json JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_mock_codef_transaction_key (account_id, codef_tr_key),
  KEY idx_mock_codef_transaction_account_date (account_id, transaction_at),
  KEY idx_mock_codef_transaction_direction (direction),
  CONSTRAINT fk_mock_codef_transaction_account
    FOREIGN KEY (account_id) REFERENCES mock_codef_account (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS mock_codef_balance_snapshot (
  id BIGINT NOT NULL AUTO_INCREMENT,
  account_id BIGINT NOT NULL,
  snapshot_at DATETIME NOT NULL,
  balance DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  available_amount DECIMAL(18,2) NULL,
  valuation_amount DECIMAL(18,2) NULL,
  raw_json JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_mock_codef_balance_snapshot (account_id, snapshot_at),
  KEY idx_mock_codef_balance_snapshot_account_latest (account_id, snapshot_at),
  CONSTRAINT fk_mock_codef_balance_snapshot_account
    FOREIGN KEY (account_id) REFERENCES mock_codef_account (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS mock_codef_stock_holding (
  id BIGINT NOT NULL AUTO_INCREMENT,
  account_id BIGINT NOT NULL,
  stock_code VARCHAR(30) NOT NULL,
  stock_name VARCHAR(100) NOT NULL,
  market_country VARCHAR(30) NOT NULL DEFAULT 'KR',
  currency CHAR(3) NOT NULL DEFAULT 'KRW',
  quantity DECIMAL(18,6) NOT NULL DEFAULT 0.000000,
  average_purchase_price DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  last_price DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  purchase_amount DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  market_value DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  profit_loss_amount DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  profit_loss_rate DECIMAL(9,4) NOT NULL DEFAULT 0.0000,
  valuation_at DATETIME NOT NULL,
  raw_json JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_mock_codef_stock_holding (account_id, stock_code, market_country),
  KEY idx_mock_codef_stock_holding_account (account_id),
  KEY idx_mock_codef_stock_holding_stock_code (stock_code),
  CONSTRAINT fk_mock_codef_stock_holding_account
    FOREIGN KEY (account_id) REFERENCES mock_codef_account (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS mock_codef_loan (
  id BIGINT NOT NULL AUTO_INCREMENT,
  account_id BIGINT NOT NULL,
  loan_no_masked VARCHAR(100) NOT NULL,
  loan_no_encrypted VARCHAR(255) NULL,
  loan_name VARCHAR(100) NULL,
  loan_type VARCHAR(50) NOT NULL,
  currency CHAR(3) NOT NULL DEFAULT 'KRW',
  loan_amount DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  balance DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  interest_rate DECIMAL(9,4) NULL,
  start_date DATE NULL,
  maturity_date DATE NULL,
  monthly_payment DECIMAL(18,2) NULL,
  next_payment_date DATE NULL,
  raw_json JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_mock_codef_loan_account (account_id),
  KEY idx_mock_codef_loan_maturity_date (maturity_date),
  CONSTRAINT fk_mock_codef_loan_account
    FOREIGN KEY (account_id) REFERENCES mock_codef_account (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS mock_codef_pay_money (
  id BIGINT NOT NULL AUTO_INCREMENT,
  account_id BIGINT NOT NULL,
  provider_code VARCHAR(50) NOT NULL,
  provider_name VARCHAR(100) NOT NULL,
  wallet_id VARCHAR(100) NULL,
  wallet_name VARCHAR(100) NULL,
  currency CHAR(3) NOT NULL DEFAULT 'KRW',
  balance DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  available_amount DECIMAL(18,2) NULL,
  point_amount DECIMAL(18,2) NULL,
  last_synced_at DATETIME NULL,
  raw_json JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_mock_codef_pay_money_account (account_id),
  KEY idx_mock_codef_pay_money_provider (provider_code),
  CONSTRAINT fk_mock_codef_pay_money_account
    FOREIGN KEY (account_id) REFERENCES mock_codef_account (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
  ('RATE_LIMITED', '호출 제한', '외부 CODEF API 호출 제한 시나리오', 429, 'RATE_LIMITED', 0, 0),
  ('EXTERNAL_API_ERROR', '외부 API 실패', 'CODEF 연동 실패 시나리오', 502, 'EXTERNAL_API_ERROR', 0, 0),
  ('EXTERNAL_API_UNAVAILABLE', '외부 API 일시 장애', 'CODEF 일시 장애 시나리오', 503, 'EXTERNAL_API_UNAVAILABLE', 1000, 0)
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  description = VALUES(description),
  http_status = VALUES(http_status),
  app_code = VALUES(app_code),
  latency_ms = VALUES(latency_ms),
  is_default = VALUES(is_default),
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
  ('CODEF', 'POST', '/codef/v1/account/list', 'codef_account_list', 'CODEF 계좌 목록 응답 목'),
  ('CODEF', 'POST', '/codef/v1/account/transactions', 'codef_transaction_list', 'CODEF 거래내역 응답 목'),
  ('CODEF', 'POST', '/codef/v1/account/balance', 'codef_balance', 'CODEF 잔액 응답 목')
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
  ('0003', '기업은행', 'BANK', 1)
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

INSERT INTO mock_codef_account (
  connection_id,
  institution_id,
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
  i.id,
  'DEPOSIT',
  '123456******7890',
  'mock-encrypted-account-001',
  'KB Star 입출금통장',
  'KRW',
  'ACTIVE',
  '2024-01-15',
  JSON_OBJECT(
    'resAccount', '123456******7890',
    'resAccountName', 'KB Star 입출금통장',
    'resAccountDeposit', '보통예금',
    'resAccountCurrency', 'KRW'
  )
FROM mock_codef_connection c
JOIN mock_codef_institution i ON i.id = c.institution_id
WHERE c.connected_id = 'conn-demo-normal-kb'
ON DUPLICATE KEY UPDATE
  account_name = VALUES(account_name),
  currency = VALUES(currency),
  status = VALUES(status),
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
SELECT
  a.id,
  'tr-demo-20260731-001',
  '2026-07-31 08:12:00',
  '스타벅스 강남점',
  5800.00,
  'WITHDRAW',
  1244200.00,
  JSON_OBJECT(
    'resAccountTrDate', '20260731',
    'resAccountTrTime', '081200',
    'resAccountDesc1', '스타벅스 강남점',
    'resAccountOut', '5800',
    'resAfterTranBalance', '1244200'
  )
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
SELECT
  a.id,
  'tr-demo-20260730-001',
  '2026-07-30 12:35:00',
  '쿠팡',
  32900.00,
  'WITHDRAW',
  1250000.00,
  JSON_OBJECT(
    'resAccountTrDate', '20260730',
    'resAccountTrTime', '123500',
    'resAccountDesc1', '쿠팡',
    'resAccountOut', '32900',
    'resAfterTranBalance', '1250000'
  )
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
SELECT
  a.id,
  'tr-demo-20260725-001',
  '2026-07-25 09:00:00',
  '급여',
  2500000.00,
  'DEPOSIT',
  1282900.00,
  JSON_OBJECT(
    'resAccountTrDate', '20260725',
    'resAccountTrTime', '090000',
    'resAccountDesc1', '급여',
    'resAccountIn', '2500000',
    'resAfterTranBalance', '1282900'
  )
FROM mock_codef_account a
WHERE a.account_no_masked = '123456******7890'
ON DUPLICATE KEY UPDATE
  merchant_name = VALUES(merchant_name),
  amount = VALUES(amount),
  direction = VALUES(direction),
  balance_after = VALUES(balance_after),
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
  JSON_OBJECT(
    'resAccountBalance', '1244200',
    'resAccountAvailableBalance', '1244200',
    'resAccountCurrency', 'KRW'
  )
FROM mock_codef_account a
WHERE a.account_no_masked = '123456******7890'
ON DUPLICATE KEY UPDATE
  balance = VALUES(balance),
  available_amount = VALUES(available_amount),
  valuation_amount = VALUES(valuation_amount),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_account (
  connection_id,
  institution_id,
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
  i.id,
  'STOCK',
  '987654******3210',
  'mock-encrypted-stock-account-001',
  'KB증권 종합위탁',
  'KRW',
  'ACTIVE',
  '2024-03-20',
  JSON_OBJECT(
    'resAccount', '987654******3210',
    'resAccountName', 'KB증권 종합위탁',
    'resAccountType', 'STOCK',
    'resAccountCurrency', 'KRW'
  )
FROM mock_codef_connection c
JOIN mock_codef_institution i ON i.id = c.institution_id
WHERE c.connected_id = 'conn-demo-normal-kb'
ON DUPLICATE KEY UPDATE
  account_name = VALUES(account_name),
  currency = VALUES(currency),
  status = VALUES(status),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_account (
  connection_id,
  institution_id,
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
  i.id,
  'LOAN',
  '555555******1111',
  'mock-encrypted-loan-account-001',
  'KB 직장인 신용대출',
  'KRW',
  'ACTIVE',
  '2025-02-01',
  JSON_OBJECT(
    'resLoanNo', '555555******1111',
    'resLoanName', 'KB 직장인 신용대출',
    'resLoanType', 'CREDIT_LOAN',
    'resCurrency', 'KRW'
  )
FROM mock_codef_connection c
JOIN mock_codef_institution i ON i.id = c.institution_id
WHERE c.connected_id = 'conn-demo-normal-kb'
ON DUPLICATE KEY UPDATE
  account_name = VALUES(account_name),
  currency = VALUES(currency),
  status = VALUES(status),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;

INSERT INTO mock_codef_account (
  connection_id,
  institution_id,
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
  i.id,
  'PAY_MONEY',
  'pay-****-2026',
  'mock-encrypted-pay-money-001',
  'KB Pay 머니',
  'KRW',
  'ACTIVE',
  '2026-01-10',
  JSON_OBJECT(
    'resWalletId', 'pay-****-2026',
    'resWalletName', 'KB Pay 머니',
    'resProviderName', 'KB Pay',
    'resCurrency', 'KRW'
  )
FROM mock_codef_connection c
JOIN mock_codef_institution i ON i.id = c.institution_id
WHERE c.connected_id = 'conn-demo-normal-kb'
ON DUPLICATE KEY UPDATE
  account_name = VALUES(account_name),
  currency = VALUES(currency),
  status = VALUES(status),
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
  JSON_OBJECT(
    'resItemCode', '005930',
    'resItemName', '삼성전자',
    'resQuantity', '12',
    'resAveragePurchasePrice', '72000',
    'resCurrentPrice', '78500',
    'resValuationAmount', '942000',
    'resProfitLoss', '78000'
  )
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
  JSON_OBJECT(
    'resItemCode', '035720',
    'resItemName', '카카오',
    'resQuantity', '8',
    'resAveragePurchasePrice', '48000',
    'resCurrentPrice', '45200',
    'resValuationAmount', '361600',
    'resProfitLoss', '-22400'
  )
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
  '555555******1111',
  'mock-encrypted-loan-no-001',
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
  JSON_OBJECT(
    'resLoanName', 'KB 직장인 신용대출',
    'resLoanType', 'CREDIT_LOAN',
    'resLoanAmount', '20000000',
    'resLoanBalance', '14200000',
    'resInterestRate', '5.12',
    'resMaturityDate', '20280201'
  )
FROM mock_codef_account a
WHERE a.account_no_masked = '555555******1111'
ON DUPLICATE KEY UPDATE
  loan_name = VALUES(loan_name),
  loan_type = VALUES(loan_type),
  loan_amount = VALUES(loan_amount),
  balance = VALUES(balance),
  interest_rate = VALUES(interest_rate),
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
  'pay-2026-demo',
  'KB Pay 머니',
  'KRW',
  83500.00,
  83500.00,
  1240.00,
  '2026-07-31 10:30:00',
  JSON_OBJECT(
    'resProviderName', 'KB Pay',
    'resWalletName', 'KB Pay 머니',
    'resBalance', '83500',
    'resAvailableAmount', '83500',
    'resPointAmount', '1240'
  )
FROM mock_codef_account a
WHERE a.account_no_masked = 'pay-****-2026'
ON DUPLICATE KEY UPDATE
  provider_name = VALUES(provider_name),
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
SELECT
  a.id,
  'tr-stock-20260729-001',
  '2026-07-29 09:15:00',
  '삼성전자 매수',
  864000.00,
  'WITHDRAW',
  NULL,
  JSON_OBJECT(
    'resAccountTrDate', '20260729',
    'resAccountTrTime', '091500',
    'resAccountDesc1', '삼성전자 매수',
    'resAccountOut', '864000',
    'resStockCode', '005930',
    'resQuantity', '12'
  )
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
SELECT
  a.id,
  'tr-stock-20260726-001',
  '2026-07-26 10:02:00',
  '카카오 매수',
  384000.00,
  'WITHDRAW',
  NULL,
  JSON_OBJECT(
    'resAccountTrDate', '20260726',
    'resAccountTrTime', '100200',
    'resAccountDesc1', '카카오 매수',
    'resAccountOut', '384000',
    'resStockCode', '035720',
    'resQuantity', '8'
  )
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
SELECT
  a.id,
  'tr-stock-20260720-001',
  '2026-07-20 16:30:00',
  '배당금 입금',
  18500.00,
  'DEPOSIT',
  NULL,
  JSON_OBJECT(
    'resAccountTrDate', '20260720',
    'resAccountTrTime', '163000',
    'resAccountDesc1', '배당금 입금',
    'resAccountIn', '18500'
  )
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
SELECT
  a.id,
  'tr-pay-20260731-001',
  '2026-07-31 07:50:00',
  '페이머니 충전',
  100000.00,
  'DEPOSIT',
  183500.00,
  JSON_OBJECT(
    'resAccountTrDate', '20260731',
    'resAccountTrTime', '075000',
    'resAccountDesc1', '페이머니 충전',
    'resAccountIn', '100000',
    'resAfterTranBalance', '183500'
  )
FROM mock_codef_account a
WHERE a.account_no_masked = 'pay-****-2026'
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
SELECT
  a.id,
  'tr-pay-20260730-001',
  '2026-07-30 20:14:00',
  'CU 편의점',
  6700.00,
  'WITHDRAW',
  83500.00,
  JSON_OBJECT(
    'resAccountTrDate', '20260730',
    'resAccountTrTime', '201400',
    'resAccountDesc1', 'CU 편의점',
    'resAccountOut', '6700',
    'resAfterTranBalance', '83500'
  )
FROM mock_codef_account a
WHERE a.account_no_masked = 'pay-****-2026'
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
SELECT
  a.id,
  'tr-pay-20260730-002',
  '2026-07-30 20:15:00',
  '포인트 적립',
  120.00,
  'DEPOSIT',
  1240.00,
  JSON_OBJECT(
    'resAccountTrDate', '20260730',
    'resAccountTrTime', '201500',
    'resAccountDesc1', '포인트 적립',
    'resPointIn', '120',
    'resPointBalance', '1240'
  )
FROM mock_codef_account a
WHERE a.account_no_masked = 'pay-****-2026'
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
SELECT
  a.id,
  'tr-loan-20260701-001',
  '2026-07-01 09:00:00',
  '대출 실행',
  20000000.00,
  'DEPOSIT',
  20000000.00,
  JSON_OBJECT(
    'resAccountTrDate', '20260701',
    'resAccountTrTime', '090000',
    'resAccountDesc1', '대출 실행',
    'resAccountIn', '20000000',
    'resLoanBalance', '20000000'
  )
FROM mock_codef_account a
WHERE a.account_no_masked = '555555******1111'
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
SELECT
  a.id,
  'tr-loan-20260715-001',
  '2026-07-15 09:00:00',
  '원리금 상환',
  615000.00,
  'WITHDRAW',
  14200000.00,
  JSON_OBJECT(
    'resAccountTrDate', '20260715',
    'resAccountTrTime', '090000',
    'resAccountDesc1', '원리금 상환',
    'resAccountOut', '615000',
    'resLoanBalance', '14200000'
  )
FROM mock_codef_account a
WHERE a.account_no_masked = '555555******1111'
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
SELECT
  a.id,
  'tr-loan-20260715-002',
  '2026-07-15 09:01:00',
  '이자 납입',
  60500.00,
  'WITHDRAW',
  14200000.00,
  JSON_OBJECT(
    'resAccountTrDate', '20260715',
    'resAccountTrTime', '090100',
    'resAccountDesc1', '이자 납입',
    'resAccountOut', '60500',
    'resLoanBalance', '14200000'
  )
FROM mock_codef_account a
WHERE a.account_no_masked = '555555******1111'
ON DUPLICATE KEY UPDATE
  merchant_name = VALUES(merchant_name),
  amount = VALUES(amount),
  direction = VALUES(direction),
  balance_after = VALUES(balance_after),
  raw_json = VALUES(raw_json),
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
  'normal-account-list',
  JSON_OBJECT('scenarioKey', 'demo-normal-user'),
  JSON_OBJECT(
    'code', 'SUCCESS',
    'message', '계좌 목록 조회 성공',
    'data', JSON_OBJECT(
      'accounts', JSON_ARRAY(
        JSON_OBJECT(
          'accountId', 1,
          'bankCode', '0004',
          'bankName', '국민은행',
          'accountType', 'DEPOSIT',
          'accountName', 'KB Star 입출금통장',
          'accountNoMasked', '123456******7890',
          'currency', 'KRW',
          'balance', 1244200,
          'lastSyncAt', '2026-07-31T10:30:00+09:00'
        )
      )
    ),
    'traceId', '01J3MOCKACCOUNTLIST',
    'timestamp', '2026-07-31T10:30:00+09:00'
  ),
  200,
  'SUCCESS',
  10
FROM mock_api_endpoint e
JOIN mock_scenario s ON s.scenario_code = 'NORMAL'
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
  'normal-transaction-list',
  JSON_OBJECT('scenarioKey', 'demo-normal-user', 'yearMonth', '2026-07'),
  JSON_OBJECT(
    'code', 'SUCCESS',
    'message', '거래내역 조회 성공',
    'data', JSON_OBJECT(
      'transactions', JSON_ARRAY(
        JSON_OBJECT('transactionId', 1, 'accountType', 'DEPOSIT', 'accountName', 'KB Star 입출금통장', 'transactionAt', '2026-07-31T08:12:00+09:00', 'merchantName', '스타벅스 강남점', 'category', '카페', 'amount', 5800, 'direction', 'WITHDRAW', 'balanceAfter', 1244200),
        JSON_OBJECT('transactionId', 2, 'accountType', 'PAY_MONEY', 'accountName', 'KB Pay 머니', 'transactionAt', '2026-07-31T07:50:00+09:00', 'merchantName', '페이머니 충전', 'category', '충전', 'amount', 100000, 'direction', 'DEPOSIT', 'balanceAfter', 183500),
        JSON_OBJECT('transactionId', 3, 'accountType', 'DEPOSIT', 'accountName', 'KB Star 입출금통장', 'transactionAt', '2026-07-30T12:35:00+09:00', 'merchantName', '쿠팡', 'category', '쇼핑', 'amount', 32900, 'direction', 'WITHDRAW', 'balanceAfter', 1250000),
        JSON_OBJECT('transactionId', 4, 'accountType', 'PAY_MONEY', 'accountName', 'KB Pay 머니', 'transactionAt', '2026-07-30T20:14:00+09:00', 'merchantName', 'CU 편의점', 'category', '편의점', 'amount', 6700, 'direction', 'WITHDRAW', 'balanceAfter', 83500),
        JSON_OBJECT('transactionId', 5, 'accountType', 'PAY_MONEY', 'accountName', 'KB Pay 머니', 'transactionAt', '2026-07-30T20:15:00+09:00', 'merchantName', '포인트 적립', 'category', '포인트', 'amount', 120, 'direction', 'DEPOSIT', 'balanceAfter', 1240),
        JSON_OBJECT('transactionId', 6, 'accountType', 'STOCK', 'accountName', 'KB증권 종합위탁', 'transactionAt', '2026-07-29T09:15:00+09:00', 'merchantName', '삼성전자 매수', 'category', '주식매수', 'amount', 864000, 'direction', 'WITHDRAW', 'balanceAfter', NULL),
        JSON_OBJECT('transactionId', 7, 'accountType', 'STOCK', 'accountName', 'KB증권 종합위탁', 'transactionAt', '2026-07-26T10:02:00+09:00', 'merchantName', '카카오 매수', 'category', '주식매수', 'amount', 384000, 'direction', 'WITHDRAW', 'balanceAfter', NULL),
        JSON_OBJECT('transactionId', 8, 'accountType', 'DEPOSIT', 'accountName', 'KB Star 입출금통장', 'transactionAt', '2026-07-25T09:00:00+09:00', 'merchantName', '급여', 'category', '급여', 'amount', 2500000, 'direction', 'DEPOSIT', 'balanceAfter', 1282900),
        JSON_OBJECT('transactionId', 9, 'accountType', 'STOCK', 'accountName', 'KB증권 종합위탁', 'transactionAt', '2026-07-20T16:30:00+09:00', 'merchantName', '배당금 입금', 'category', '배당', 'amount', 18500, 'direction', 'DEPOSIT', 'balanceAfter', NULL),
        JSON_OBJECT('transactionId', 10, 'accountType', 'LOAN', 'accountName', 'KB 직장인 신용대출', 'transactionAt', '2026-07-15T09:00:00+09:00', 'merchantName', '원리금 상환', 'category', '대출상환', 'amount', 615000, 'direction', 'WITHDRAW', 'balanceAfter', 14200000),
        JSON_OBJECT('transactionId', 11, 'accountType', 'LOAN', 'accountName', 'KB 직장인 신용대출', 'transactionAt', '2026-07-15T09:01:00+09:00', 'merchantName', '이자 납입', 'category', '이자', 'amount', 60500, 'direction', 'WITHDRAW', 'balanceAfter', 14200000),
        JSON_OBJECT('transactionId', 12, 'accountType', 'LOAN', 'accountName', 'KB 직장인 신용대출', 'transactionAt', '2026-07-01T09:00:00+09:00', 'merchantName', '대출 실행', 'category', '대출실행', 'amount', 20000000, 'direction', 'DEPOSIT', 'balanceAfter', 20000000)
      )
    ),
    'traceId', '01J3MOCKTRANSACTION',
    'timestamp', '2026-07-31T10:30:00+09:00'
  ),
  200,
  'SUCCESS',
  5
FROM mock_api_endpoint e
JOIN mock_scenario s ON s.scenario_code = 'NORMAL'
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
  'normal-transaction-list',
  JSON_OBJECT('scenarioKey', 'demo-normal-user', 'yearMonth', '2026-07'),
  JSON_OBJECT(
    'code', 'SUCCESS',
    'message', '거래내역 조회 성공',
    'data', JSON_OBJECT(
      'transactions', JSON_ARRAY(
        JSON_OBJECT('transactionId', 1, 'accountType', 'DEPOSIT', 'accountName', 'KB Star 입출금통장', 'transactionAt', '2026-07-31T08:12:00+09:00', 'merchantName', '스타벅스 강남점', 'category', '카페', 'amount', 5800, 'direction', 'WITHDRAW', 'balanceAfter', 1244200),
        JSON_OBJECT('transactionId', 2, 'accountType', 'PAY_MONEY', 'accountName', 'KB Pay 머니', 'transactionAt', '2026-07-31T07:50:00+09:00', 'merchantName', '페이머니 충전', 'category', '충전', 'amount', 100000, 'direction', 'DEPOSIT', 'balanceAfter', 183500),
        JSON_OBJECT('transactionId', 3, 'accountType', 'DEPOSIT', 'accountName', 'KB Star 입출금통장', 'transactionAt', '2026-07-30T12:35:00+09:00', 'merchantName', '쿠팡', 'category', '쇼핑', 'amount', 32900, 'direction', 'WITHDRAW', 'balanceAfter', 1250000),
        JSON_OBJECT('transactionId', 4, 'accountType', 'PAY_MONEY', 'accountName', 'KB Pay 머니', 'transactionAt', '2026-07-30T20:14:00+09:00', 'merchantName', 'CU 편의점', 'category', '편의점', 'amount', 6700, 'direction', 'WITHDRAW', 'balanceAfter', 83500),
        JSON_OBJECT('transactionId', 5, 'accountType', 'PAY_MONEY', 'accountName', 'KB Pay 머니', 'transactionAt', '2026-07-30T20:15:00+09:00', 'merchantName', '포인트 적립', 'category', '포인트', 'amount', 120, 'direction', 'DEPOSIT', 'balanceAfter', 1240),
        JSON_OBJECT('transactionId', 6, 'accountType', 'STOCK', 'accountName', 'KB증권 종합위탁', 'transactionAt', '2026-07-29T09:15:00+09:00', 'merchantName', '삼성전자 매수', 'category', '주식매수', 'amount', 864000, 'direction', 'WITHDRAW', 'balanceAfter', NULL),
        JSON_OBJECT('transactionId', 7, 'accountType', 'STOCK', 'accountName', 'KB증권 종합위탁', 'transactionAt', '2026-07-26T10:02:00+09:00', 'merchantName', '카카오 매수', 'category', '주식매수', 'amount', 384000, 'direction', 'WITHDRAW', 'balanceAfter', NULL),
        JSON_OBJECT('transactionId', 8, 'accountType', 'DEPOSIT', 'accountName', 'KB Star 입출금통장', 'transactionAt', '2026-07-25T09:00:00+09:00', 'merchantName', '급여', 'category', '급여', 'amount', 2500000, 'direction', 'DEPOSIT', 'balanceAfter', 1282900),
        JSON_OBJECT('transactionId', 9, 'accountType', 'STOCK', 'accountName', 'KB증권 종합위탁', 'transactionAt', '2026-07-20T16:30:00+09:00', 'merchantName', '배당금 입금', 'category', '배당', 'amount', 18500, 'direction', 'DEPOSIT', 'balanceAfter', NULL),
        JSON_OBJECT('transactionId', 10, 'accountType', 'LOAN', 'accountName', 'KB 직장인 신용대출', 'transactionAt', '2026-07-15T09:00:00+09:00', 'merchantName', '원리금 상환', 'category', '대출상환', 'amount', 615000, 'direction', 'WITHDRAW', 'balanceAfter', 14200000),
        JSON_OBJECT('transactionId', 11, 'accountType', 'LOAN', 'accountName', 'KB 직장인 신용대출', 'transactionAt', '2026-07-15T09:01:00+09:00', 'merchantName', '이자 납입', 'category', '이자', 'amount', 60500, 'direction', 'WITHDRAW', 'balanceAfter', 14200000),
        JSON_OBJECT('transactionId', 12, 'accountType', 'LOAN', 'accountName', 'KB 직장인 신용대출', 'transactionAt', '2026-07-01T09:00:00+09:00', 'merchantName', '대출 실행', 'category', '대출실행', 'amount', 20000000, 'direction', 'DEPOSIT', 'balanceAfter', 20000000)
      )
    ),
    'traceId', '01J3MOCKTRANSACTION',
    'timestamp', '2026-07-31T10:30:00+09:00'
  ),
  200,
  'SUCCESS',
  5
FROM mock_api_endpoint e
JOIN mock_scenario s ON s.scenario_code = 'NORMAL'
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
  'normal-stock-list',
  JSON_OBJECT('scenarioKey', 'demo-normal-user'),
  JSON_OBJECT(
    'code', 'SUCCESS',
    'message', '주식 자산 조회 성공',
    'data', JSON_OBJECT(
      'accountId', 2,
      'accountName', 'KB증권 종합위탁',
      'currency', 'KRW',
      'totalPurchaseAmount', 1248000,
      'totalMarketValue', 1303600,
      'totalProfitLossAmount', 55600,
      'totalProfitLossRate', 4.4551,
      'holdings', JSON_ARRAY(
        JSON_OBJECT('stockCode', '005930', 'stockName', '삼성전자', 'marketCountry', 'KR', 'currency', 'KRW', 'quantity', 12, 'averagePurchasePrice', 72000, 'lastPrice', 78500, 'purchaseAmount', 864000, 'marketValue', 942000, 'profitLossAmount', 78000, 'profitLossRate', 9.0278),
        JSON_OBJECT('stockCode', '035720', 'stockName', '카카오', 'marketCountry', 'KR', 'currency', 'KRW', 'quantity', 8, 'averagePurchasePrice', 48000, 'lastPrice', 45200, 'purchaseAmount', 384000, 'marketValue', 361600, 'profitLossAmount', -22400, 'profitLossRate', -5.8333)
      ),
      'lastSyncAt', '2026-07-31T10:30:00+09:00'
    ),
    'traceId', '01J3MOCKSTOCKS',
    'timestamp', '2026-07-31T10:30:00+09:00'
  ),
  200,
  'SUCCESS',
  10
FROM mock_api_endpoint e
JOIN mock_scenario s ON s.scenario_code = 'NORMAL'
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
  'empty-stock-list',
  JSON_OBJECT('scenarioKey', 'demo-empty-user'),
  JSON_OBJECT(
    'code', 'SUCCESS',
    'message', '보유 주식이 없습니다',
    'data', JSON_OBJECT('holdings', JSON_ARRAY(), 'totalPurchaseAmount', 0, 'totalMarketValue', 0, 'totalProfitLossAmount', 0, 'totalProfitLossRate', 0),
    'traceId', '01J3MOCKEMPTYSTOCKS',
    'timestamp', '2026-07-31T10:30:00+09:00'
  ),
  200,
  'SUCCESS',
  20
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
  'normal-loan-list',
  JSON_OBJECT('scenarioKey', 'demo-normal-user'),
  JSON_OBJECT(
    'code', 'SUCCESS',
    'message', '대출 자산 조회 성공',
    'data', JSON_OBJECT(
      'loans', JSON_ARRAY(
        JSON_OBJECT('loanId', 1, 'bankName', '국민은행', 'loanName', 'KB 직장인 신용대출', 'loanType', 'CREDIT_LOAN', 'currency', 'KRW', 'loanAmount', 20000000, 'balance', 14200000, 'interestRate', 5.12, 'startDate', '2025-02-01', 'maturityDate', '2028-02-01', 'monthlyPayment', 615000, 'nextPaymentDate', '2026-08-01')
      ),
      'totalLoanAmount', 20000000,
      'totalBalance', 14200000,
      'lastSyncAt', '2026-07-31T10:30:00+09:00'
    ),
    'traceId', '01J3MOCKLOANS',
    'timestamp', '2026-07-31T10:30:00+09:00'
  ),
  200,
  'SUCCESS',
  10
FROM mock_api_endpoint e
JOIN mock_scenario s ON s.scenario_code = 'NORMAL'
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
  'empty-loan-list',
  JSON_OBJECT('scenarioKey', 'demo-empty-user'),
  JSON_OBJECT(
    'code', 'SUCCESS',
    'message', '대출 정보가 없습니다',
    'data', JSON_OBJECT('loans', JSON_ARRAY(), 'totalLoanAmount', 0, 'totalBalance', 0),
    'traceId', '01J3MOCKEMPTYLOANS',
    'timestamp', '2026-07-31T10:30:00+09:00'
  ),
  200,
  'SUCCESS',
  20
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
  'normal-pay-money-list',
  JSON_OBJECT('scenarioKey', 'demo-normal-user'),
  JSON_OBJECT(
    'code', 'SUCCESS',
    'message', '페이머니 조회 성공',
    'data', JSON_OBJECT(
      'payMoney', JSON_ARRAY(
        JSON_OBJECT('payMoneyId', 1, 'providerCode', 'KB_PAY', 'providerName', 'KB Pay', 'walletName', 'KB Pay 머니', 'currency', 'KRW', 'balance', 83500, 'availableAmount', 83500, 'pointAmount', 1240, 'lastSyncAt', '2026-07-31T10:30:00+09:00')
      ),
      'totalBalance', 83500,
      'totalPointAmount', 1240
    ),
    'traceId', '01J3MOCKPAYMONEY',
    'timestamp', '2026-07-31T10:30:00+09:00'
  ),
  200,
  'SUCCESS',
  10
FROM mock_api_endpoint e
JOIN mock_scenario s ON s.scenario_code = 'NORMAL'
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
  'empty-pay-money-list',
  JSON_OBJECT('scenarioKey', 'demo-empty-user'),
  JSON_OBJECT(
    'code', 'SUCCESS',
    'message', '페이머니 정보가 없습니다',
    'data', JSON_OBJECT('payMoney', JSON_ARRAY(), 'totalBalance', 0, 'totalPointAmount', 0),
    'traceId', '01J3MOCKEMPTYPAYMONEY',
    'timestamp', '2026-07-31T10:30:00+09:00'
  ),
  200,
  'SUCCESS',
  20
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
  'empty-account-list',
  JSON_OBJECT('scenarioKey', 'demo-empty-user'),
  JSON_OBJECT(
    'code', 'SUCCESS',
    'message', '연결된 계좌가 없습니다',
    'data', JSON_OBJECT('accounts', JSON_ARRAY()),
    'traceId', '01J3MOCKEMPTYACCOUNT',
    'timestamp', '2026-07-31T10:30:00+09:00'
  ),
  200,
  'SUCCESS',
  20
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
  'normal-transaction-list',
  JSON_OBJECT('scenarioKey', 'demo-normal-user', 'yearMonth', '2026-07'),
  JSON_OBJECT(
    'code', 'SUCCESS',
    'message', '거래내역 조회 성공',
    'data', JSON_OBJECT(
      'transactions', JSON_ARRAY(
        JSON_OBJECT('transactionId', 1, 'transactionAt', '2026-07-31T08:12:00+09:00', 'merchantName', '스타벅스 강남점', 'amount', 5800, 'direction', 'WITHDRAW', 'balanceAfter', 1244200),
        JSON_OBJECT('transactionId', 2, 'transactionAt', '2026-07-30T12:35:00+09:00', 'merchantName', '쿠팡', 'amount', 32900, 'direction', 'WITHDRAW', 'balanceAfter', 1250000),
        JSON_OBJECT('transactionId', 3, 'transactionAt', '2026-07-25T09:00:00+09:00', 'merchantName', '급여', 'amount', 2500000, 'direction', 'DEPOSIT', 'balanceAfter', 1282900)
      )
    ),
    'traceId', '01J3MOCKTRANSACTION',
    'timestamp', '2026-07-31T10:30:00+09:00'
  ),
  200,
  'SUCCESS',
  10
FROM mock_api_endpoint e
JOIN mock_scenario s ON s.scenario_code = 'NORMAL'
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
  'normal-transaction-list',
  JSON_OBJECT('scenarioKey', 'demo-normal-user', 'yearMonth', '2026-07'),
  JSON_OBJECT(
    'code', 'SUCCESS',
    'message', '거래내역 조회 성공',
    'data', JSON_OBJECT(
      'transactions', JSON_ARRAY(
        JSON_OBJECT('transactionId', 1, 'accountType', 'DEPOSIT', 'accountName', 'KB Star 입출금통장', 'transactionAt', '2026-07-31T08:12:00+09:00', 'merchantName', '스타벅스 강남점', 'category', '카페', 'amount', 5800, 'direction', 'WITHDRAW', 'balanceAfter', 1244200),
        JSON_OBJECT('transactionId', 2, 'accountType', 'PAY_MONEY', 'accountName', 'KB Pay 머니', 'transactionAt', '2026-07-31T07:50:00+09:00', 'merchantName', '페이머니 충전', 'category', '충전', 'amount', 100000, 'direction', 'DEPOSIT', 'balanceAfter', 183500),
        JSON_OBJECT('transactionId', 3, 'accountType', 'DEPOSIT', 'accountName', 'KB Star 입출금통장', 'transactionAt', '2026-07-30T12:35:00+09:00', 'merchantName', '쿠팡', 'category', '쇼핑', 'amount', 32900, 'direction', 'WITHDRAW', 'balanceAfter', 1250000),
        JSON_OBJECT('transactionId', 4, 'accountType', 'PAY_MONEY', 'accountName', 'KB Pay 머니', 'transactionAt', '2026-07-30T20:14:00+09:00', 'merchantName', 'CU 편의점', 'category', '편의점', 'amount', 6700, 'direction', 'WITHDRAW', 'balanceAfter', 83500),
        JSON_OBJECT('transactionId', 5, 'accountType', 'PAY_MONEY', 'accountName', 'KB Pay 머니', 'transactionAt', '2026-07-30T20:15:00+09:00', 'merchantName', '포인트 적립', 'category', '포인트', 'amount', 120, 'direction', 'DEPOSIT', 'balanceAfter', 1240),
        JSON_OBJECT('transactionId', 6, 'accountType', 'STOCK', 'accountName', 'KB증권 종합위탁', 'transactionAt', '2026-07-29T09:15:00+09:00', 'merchantName', '삼성전자 매수', 'category', '주식매수', 'amount', 864000, 'direction', 'WITHDRAW', 'balanceAfter', NULL),
        JSON_OBJECT('transactionId', 7, 'accountType', 'STOCK', 'accountName', 'KB증권 종합위탁', 'transactionAt', '2026-07-26T10:02:00+09:00', 'merchantName', '카카오 매수', 'category', '주식매수', 'amount', 384000, 'direction', 'WITHDRAW', 'balanceAfter', NULL),
        JSON_OBJECT('transactionId', 8, 'accountType', 'DEPOSIT', 'accountName', 'KB Star 입출금통장', 'transactionAt', '2026-07-25T09:00:00+09:00', 'merchantName', '급여', 'category', '급여', 'amount', 2500000, 'direction', 'DEPOSIT', 'balanceAfter', 1282900),
        JSON_OBJECT('transactionId', 9, 'accountType', 'STOCK', 'accountName', 'KB증권 종합위탁', 'transactionAt', '2026-07-20T16:30:00+09:00', 'merchantName', '배당금 입금', 'category', '배당', 'amount', 18500, 'direction', 'DEPOSIT', 'balanceAfter', NULL),
        JSON_OBJECT('transactionId', 10, 'accountType', 'LOAN', 'accountName', 'KB 직장인 신용대출', 'transactionAt', '2026-07-15T09:00:00+09:00', 'merchantName', '원리금 상환', 'category', '대출상환', 'amount', 615000, 'direction', 'WITHDRAW', 'balanceAfter', 14200000),
        JSON_OBJECT('transactionId', 11, 'accountType', 'LOAN', 'accountName', 'KB 직장인 신용대출', 'transactionAt', '2026-07-15T09:01:00+09:00', 'merchantName', '이자 납입', 'category', '이자', 'amount', 60500, 'direction', 'WITHDRAW', 'balanceAfter', 14200000),
        JSON_OBJECT('transactionId', 12, 'accountType', 'LOAN', 'accountName', 'KB 직장인 신용대출', 'transactionAt', '2026-07-01T09:00:00+09:00', 'merchantName', '대출 실행', 'category', '대출실행', 'amount', 20000000, 'direction', 'DEPOSIT', 'balanceAfter', 20000000)
      )
    ),
    'traceId', '01J3MOCKTRANSACTION',
    'timestamp', '2026-07-31T10:30:00+09:00'
  ),
  200,
  'SUCCESS',
  5
FROM mock_api_endpoint e
JOIN mock_scenario s ON s.scenario_code = 'NORMAL'
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
  'empty-transaction-list',
  JSON_OBJECT('scenarioKey', 'demo-empty-user', 'yearMonth', '2026-07'),
  JSON_OBJECT(
    'code', 'SUCCESS',
    'message', '거래내역이 없습니다',
    'data', JSON_OBJECT('transactions', JSON_ARRAY()),
    'traceId', '01J3MOCKEMPTYTRANSACTION',
    'timestamp', '2026-07-31T10:30:00+09:00'
  ),
  200,
  'SUCCESS',
  20
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
  'normal-balance',
  JSON_OBJECT('scenarioKey', 'demo-normal-user'),
  JSON_OBJECT(
    'code', 'SUCCESS',
    'message', '잔액 조회 성공',
    'data', JSON_OBJECT(
      'accountId', 1,
      'balance', 1244200,
      'availableAmount', 1244200,
      'valuationAmount', 1244200,
      'currency', 'KRW',
      'snapshotAt', '2026-07-31T10:30:00+09:00'
    ),
    'traceId', '01J3MOCKBALANCE',
    'timestamp', '2026-07-31T10:30:00+09:00'
  ),
  200,
  'SUCCESS',
  10
FROM mock_api_endpoint e
JOIN mock_scenario s ON s.scenario_code = 'NORMAL'
WHERE e.operation_key = 'codef_balance'
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
  'empty-balance',
  JSON_OBJECT('scenarioKey', 'demo-empty-user'),
  JSON_OBJECT(
    'code', 'SUCCESS',
    'message', '잔액 정보가 없습니다',
    'data', JSON_OBJECT(
      'accountId', NULL,
      'balance', 0,
      'availableAmount', 0,
      'valuationAmount', 0,
      'currency', 'KRW',
      'snapshotAt', NULL
    ),
    'traceId', '01J3MOCKEMPTYBALANCE',
    'timestamp', '2026-07-31T10:30:00+09:00'
  ),
  200,
  'SUCCESS',
  20
FROM mock_api_endpoint e
JOIN mock_scenario s ON s.scenario_code = 'EMPTY_DATA'
WHERE e.operation_key = 'codef_balance'
ON DUPLICATE KEY UPDATE
  request_match_json = VALUES(request_match_json),
  response_json = VALUES(response_json),
  http_status = VALUES(http_status),
  app_code = VALUES(app_code),
  priority = VALUES(priority),
  is_active = 1,
  updated_at = CURRENT_TIMESTAMP;
