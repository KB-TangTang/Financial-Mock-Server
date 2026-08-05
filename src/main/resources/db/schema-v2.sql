CREATE DATABASE IF NOT EXISTS financial_mock
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE financial_mock;

DROP TABLE IF EXISTS mock_codef_pay_money;
DROP TABLE IF EXISTS mock_codef_loan;
DROP TABLE IF EXISTS mock_codef_stock_holding;
DROP TABLE IF EXISTS mock_codef_balance_snapshot;
DROP TABLE IF EXISTS mock_codef_transaction;
DROP TABLE IF EXISTS mock_codef_account;
DROP TABLE IF EXISTS mock_codef_connection;
DROP TABLE IF EXISTS mock_codef_institution;

DROP TABLE IF EXISTS securities_transaction;
DROP TABLE IF EXISTS securities_holding;
DROP TABLE IF EXISTS securities_account;
DROP TABLE IF EXISTS loan_transaction;
DROP TABLE IF EXISTS loan_account;
DROP TABLE IF EXISTS deposit_transaction;
DROP TABLE IF EXISTS deposit_account;
DROP TABLE IF EXISTS card_bill;
DROP TABLE IF EXISTS card_approval;
DROP TABLE IF EXISTS card_payment_account;
DROP TABLE IF EXISTS card;
DROP TABLE IF EXISTS pay_money_transaction;
DROP TABLE IF EXISTS pay_money;
DROP TABLE IF EXISTS bank_transaction;
DROP TABLE IF EXISTS bank_account;
DROP TABLE IF EXISTS financial_institution;

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
  UNIQUE KEY uk_mock_api_endpoint_operation_key (operation_key)
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
  CONSTRAINT fk_mock_scenario_assignment_user FOREIGN KEY (user_id) REFERENCES mock_user (id),
  CONSTRAINT fk_mock_scenario_assignment_scenario FOREIGN KEY (scenario_id) REFERENCES mock_scenario (id),
  CONSTRAINT fk_mock_scenario_assignment_endpoint FOREIGN KEY (endpoint_id) REFERENCES mock_api_endpoint (id)
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
  CONSTRAINT fk_mock_api_response_fixture_endpoint FOREIGN KEY (endpoint_id) REFERENCES mock_api_endpoint (id),
  CONSTRAINT fk_mock_api_response_fixture_scenario FOREIGN KEY (scenario_id) REFERENCES mock_scenario (id)
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
  CONSTRAINT fk_mock_api_call_log_endpoint FOREIGN KEY (endpoint_id) REFERENCES mock_api_endpoint (id),
  CONSTRAINT fk_mock_api_call_log_scenario FOREIGN KEY (scenario_id) REFERENCES mock_scenario (id),
  CONSTRAINT fk_mock_api_call_log_user FOREIGN KEY (user_id) REFERENCES mock_user (id),
  CONSTRAINT fk_mock_api_call_log_fixture FOREIGN KEY (response_fixture_id) REFERENCES mock_api_response_fixture (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE financial_institution (
  id BIGINT NOT NULL AUTO_INCREMENT,
  institution_code VARCHAR(50) NOT NULL,
  institution_name VARCHAR(100) NOT NULL,
  institution_type_code VARCHAR(30) NOT NULL,
  is_supported TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_financial_institution_code (institution_code),
  KEY idx_financial_institution_type (institution_type_code, is_supported)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE bank_account (
  id BIGINT NOT NULL AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  institution_id BIGINT NOT NULL,
  account_no_masked VARCHAR(100) NOT NULL,
  product_name VARCHAR(100) NOT NULL,
  account_type_code VARCHAR(30) NOT NULL,
  account_status_code VARCHAR(30) NOT NULL DEFAULT '01',
  currency CHAR(3) NOT NULL DEFAULT 'KRW',
  balance DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  available_amount DECIMAL(18,2) NULL,
  opened_at DATE NULL,
  last_synced_at DATETIME NULL,
  raw_json JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_bank_account_user_no (user_id, account_no_masked),
  KEY idx_bank_account_user_status (user_id, account_status_code),
  CONSTRAINT fk_bank_account_user FOREIGN KEY (user_id) REFERENCES mock_user (id),
  CONSTRAINT fk_bank_account_institution FOREIGN KEY (institution_id) REFERENCES financial_institution (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE bank_transaction (
  id BIGINT NOT NULL AUTO_INCREMENT,
  bank_account_id BIGINT NOT NULL,
  original_transaction_id VARCHAR(100) NOT NULL,
  transacted_at DATETIME NOT NULL,
  trans_type_code VARCHAR(30) NOT NULL,
  trans_type_name VARCHAR(100) NULL,
  amount DECIMAL(18,2) NOT NULL,
  balance_after DECIMAL(18,2) NULL,
  description VARCHAR(255) NULL,
  raw_json JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_bank_transaction_original (bank_account_id, original_transaction_id),
  KEY idx_bank_transaction_account_date (bank_account_id, transacted_at),
  CONSTRAINT fk_bank_transaction_account FOREIGN KEY (bank_account_id) REFERENCES bank_account (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE card (
  id BIGINT NOT NULL AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  institution_id BIGINT NOT NULL,
  card_no_masked VARCHAR(100) NOT NULL,
  product_name VARCHAR(100) NOT NULL,
  card_product_code VARCHAR(50) NULL,
  card_type_code VARCHAR(30) NOT NULL,
  card_status_code VARCHAR(30) NOT NULL DEFAULT '01',
  currency CHAR(3) NOT NULL DEFAULT 'KRW',
  issued_at DATE NULL,
  last_synced_at DATETIME NULL,
  raw_json JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_card_user_no (user_id, card_no_masked),
  KEY idx_card_user_status (user_id, card_status_code),
  CONSTRAINT fk_card_user FOREIGN KEY (user_id) REFERENCES mock_user (id),
  CONSTRAINT fk_card_institution FOREIGN KEY (institution_id) REFERENCES financial_institution (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE card_payment_account (
  id BIGINT NOT NULL AUTO_INCREMENT,
  card_id BIGINT NOT NULL,
  bank_account_id BIGINT NOT NULL,
  valid_from DATE NOT NULL,
  valid_to DATE NULL,
  is_primary TINYINT(1) NOT NULL DEFAULT 1,
  source_type VARCHAR(30) NOT NULL,
  match_confidence DECIMAL(5,4) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_card_payment_account_period (card_id, bank_account_id, valid_from),
  KEY idx_card_payment_account_card_period (card_id, valid_from, valid_to),
  KEY idx_card_payment_account_bank (bank_account_id),
  CONSTRAINT fk_card_payment_account_card FOREIGN KEY (card_id) REFERENCES card (id),
  CONSTRAINT fk_card_payment_account_bank FOREIGN KEY (bank_account_id) REFERENCES bank_account (id),
  CONSTRAINT chk_card_payment_account_period CHECK (valid_to IS NULL OR valid_to >= valid_from),
  CONSTRAINT chk_card_payment_account_confidence CHECK (
    match_confidence IS NULL OR (match_confidence >= 0.0000 AND match_confidence <= 1.0000)
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE card_approval (
  id BIGINT NOT NULL AUTO_INCREMENT,
  card_id BIGINT NOT NULL,
  approval_no VARCHAR(100) NOT NULL,
  approved_at DATETIME NOT NULL,
  approval_type_code VARCHAR(30) NOT NULL,
  approval_type_name VARCHAR(100) NULL,
  merchant_name VARCHAR(255) NULL,
  merchant_business_no VARCHAR(30) NULL,
  approved_amount DECIMAL(18,2) NOT NULL,
  currency CHAR(3) NOT NULL DEFAULT 'KRW',
  description VARCHAR(255) NULL,
  raw_json JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_card_approval_no (card_id, approval_no),
  KEY idx_card_approval_card_date (card_id, approved_at),
  CONSTRAINT fk_card_approval_card FOREIGN KEY (card_id) REFERENCES card (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE card_bill (
  id BIGINT NOT NULL AUTO_INCREMENT,
  card_id BIGINT NOT NULL,
  billing_month DATE NOT NULL,
  due_date DATE NULL,
  bill_status_code VARCHAR(30) NOT NULL,
  bill_status_name VARCHAR(100) NULL,
  total_amount DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  paid_amount DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  raw_json JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_card_bill_month (card_id, billing_month),
  CONSTRAINT fk_card_bill_card FOREIGN KEY (card_id) REFERENCES card (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE pay_money (
  id BIGINT NOT NULL AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  institution_id BIGINT NOT NULL,
  provider_code VARCHAR(50) NOT NULL,
  provider_name VARCHAR(100) NOT NULL,
  wallet_id VARCHAR(100) NOT NULL,
  wallet_name VARCHAR(100) NOT NULL,
  currency CHAR(3) NOT NULL DEFAULT 'KRW',
  balance DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  available_amount DECIMAL(18,2) NULL,
  point_amount DECIMAL(18,2) NULL,
  last_synced_at DATETIME NULL,
  raw_json JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_pay_money_user_wallet (user_id, provider_code, wallet_id),
  KEY idx_pay_money_user_provider (user_id, provider_code),
  CONSTRAINT fk_pay_money_user FOREIGN KEY (user_id) REFERENCES mock_user (id),
  CONSTRAINT fk_pay_money_institution FOREIGN KEY (institution_id) REFERENCES financial_institution (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE pay_money_transaction (
  id BIGINT NOT NULL AUTO_INCREMENT,
  pay_money_id BIGINT NOT NULL,
  original_transaction_id VARCHAR(100) NOT NULL,
  transacted_at DATETIME NOT NULL,
  trans_type_code VARCHAR(30) NOT NULL,
  trans_type_name VARCHAR(100) NULL,
  amount DECIMAL(18,2) NOT NULL,
  balance_after DECIMAL(18,2) NULL,
  point_amount DECIMAL(18,2) NULL,
  point_balance_after DECIMAL(18,2) NULL,
  merchant_name VARCHAR(255) NULL,
  description VARCHAR(255) NULL,
  raw_json JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_pay_money_transaction_original (pay_money_id, original_transaction_id),
  KEY idx_pay_money_transaction_wallet_date (pay_money_id, transacted_at),
  CONSTRAINT fk_pay_money_transaction_wallet FOREIGN KEY (pay_money_id) REFERENCES pay_money (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE deposit_account (
  id BIGINT NOT NULL AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  institution_id BIGINT NOT NULL,
  account_no_masked VARCHAR(100) NOT NULL,
  product_name VARCHAR(100) NOT NULL,
  deposit_type_code VARCHAR(30) NOT NULL,
  account_status_code VARCHAR(30) NOT NULL DEFAULT '01',
  currency CHAR(3) NOT NULL DEFAULT 'KRW',
  principal DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  balance DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  interest_rate DECIMAL(9,4) NULL,
  opened_at DATE NULL,
  maturity_date DATE NULL,
  last_synced_at DATETIME NULL,
  raw_json JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_deposit_account_user_no (user_id, account_no_masked),
  CONSTRAINT fk_deposit_account_user FOREIGN KEY (user_id) REFERENCES mock_user (id),
  CONSTRAINT fk_deposit_account_institution FOREIGN KEY (institution_id) REFERENCES financial_institution (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE deposit_transaction (
  id BIGINT NOT NULL AUTO_INCREMENT,
  deposit_account_id BIGINT NOT NULL,
  original_transaction_id VARCHAR(100) NOT NULL,
  transacted_at DATETIME NOT NULL,
  trans_type_code VARCHAR(30) NOT NULL,
  trans_type_name VARCHAR(100) NULL,
  amount DECIMAL(18,2) NOT NULL,
  balance_after DECIMAL(18,2) NULL,
  description VARCHAR(255) NULL,
  raw_json JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_deposit_transaction_original (deposit_account_id, original_transaction_id),
  KEY idx_deposit_transaction_account_date (deposit_account_id, transacted_at),
  CONSTRAINT fk_deposit_transaction_account FOREIGN KEY (deposit_account_id) REFERENCES deposit_account (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE loan_account (
  id BIGINT NOT NULL AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  institution_id BIGINT NOT NULL,
  loan_no_masked VARCHAR(100) NOT NULL,
  product_name VARCHAR(100) NOT NULL,
  account_type_code VARCHAR(30) NOT NULL,
  account_status_code VARCHAR(30) NOT NULL DEFAULT '01',
  repayment_method_code VARCHAR(30) NULL,
  currency CHAR(3) NOT NULL DEFAULT 'KRW',
  principal DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  outstanding_balance DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  interest_rate DECIMAL(9,4) NULL,
  start_date DATE NULL,
  maturity_date DATE NULL,
  monthly_payment DECIMAL(18,2) NULL,
  next_payment_date DATE NULL,
  last_synced_at DATETIME NULL,
  raw_json JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_loan_account_user_no (user_id, loan_no_masked),
  KEY idx_loan_account_maturity (maturity_date),
  CONSTRAINT fk_loan_account_user FOREIGN KEY (user_id) REFERENCES mock_user (id),
  CONSTRAINT fk_loan_account_institution FOREIGN KEY (institution_id) REFERENCES financial_institution (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE loan_transaction (
  id BIGINT NOT NULL AUTO_INCREMENT,
  loan_account_id BIGINT NOT NULL,
  original_transaction_id VARCHAR(100) NOT NULL,
  transacted_at DATETIME NOT NULL,
  trans_type_code VARCHAR(30) NOT NULL,
  trans_type_name VARCHAR(100) NULL,
  amount DECIMAL(18,2) NOT NULL,
  principal_amount DECIMAL(18,2) NULL,
  interest_amount DECIMAL(18,2) NULL,
  balance_after DECIMAL(18,2) NULL,
  description VARCHAR(255) NULL,
  raw_json JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_loan_transaction_original (loan_account_id, original_transaction_id),
  KEY idx_loan_transaction_account_date (loan_account_id, transacted_at),
  CONSTRAINT fk_loan_transaction_account FOREIGN KEY (loan_account_id) REFERENCES loan_account (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE securities_account (
  id BIGINT NOT NULL AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  institution_id BIGINT NOT NULL,
  account_no_masked VARCHAR(100) NOT NULL,
  product_name VARCHAR(100) NOT NULL,
  account_type_code VARCHAR(30) NOT NULL,
  account_status_code VARCHAR(30) NOT NULL DEFAULT '01',
  currency CHAR(3) NOT NULL DEFAULT 'KRW',
  cash_balance DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  valuation_amount DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  last_synced_at DATETIME NULL,
  raw_json JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_securities_account_user_no (user_id, account_no_masked),
  CONSTRAINT fk_securities_account_user FOREIGN KEY (user_id) REFERENCES mock_user (id),
  CONSTRAINT fk_securities_account_institution FOREIGN KEY (institution_id) REFERENCES financial_institution (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE securities_holding (
  id BIGINT NOT NULL AUTO_INCREMENT,
  securities_account_id BIGINT NOT NULL,
  product_code VARCHAR(30) NOT NULL,
  product_name VARCHAR(100) NOT NULL,
  market_country_code VARCHAR(30) NOT NULL DEFAULT 'KR',
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
  UNIQUE KEY uk_securities_holding_product (securities_account_id, product_code, market_country_code),
  KEY idx_securities_holding_product_code (product_code),
  CONSTRAINT fk_securities_holding_account FOREIGN KEY (securities_account_id) REFERENCES securities_account (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE securities_transaction (
  id BIGINT NOT NULL AUTO_INCREMENT,
  securities_account_id BIGINT NOT NULL,
  original_transaction_id VARCHAR(100) NOT NULL,
  transacted_at DATETIME NOT NULL,
  trans_type_code VARCHAR(30) NOT NULL,
  trans_type_name VARCHAR(100) NULL,
  product_code VARCHAR(30) NULL,
  product_name VARCHAR(100) NULL,
  quantity DECIMAL(18,6) NULL,
  unit_price DECIMAL(18,2) NULL,
  transaction_amount DECIMAL(18,2) NOT NULL,
  description VARCHAR(255) NULL,
  raw_json JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_securities_transaction_original (securities_account_id, original_transaction_id),
  KEY idx_securities_transaction_account_date (securities_account_id, transacted_at),
  CONSTRAINT fk_securities_transaction_account FOREIGN KEY (securities_account_id) REFERENCES securities_account (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
