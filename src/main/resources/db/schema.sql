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
  CONSTRAINT fk_mock_codef_account_connection
    FOREIGN KEY (connection_id) REFERENCES mock_codef_connection (id)
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

