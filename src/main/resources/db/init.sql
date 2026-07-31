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
