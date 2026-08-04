-- v2: 은행 자산의 입출금(DEMAND_DEPOSIT)/예적금(SAVINGS) 구분
-- init.sql 실행 이후에 적용한다.
-- 스키마 변경 없음 (mock_codef_account.account_type은 이미 VARCHAR(30)이라
-- 새 값을 그대로 사용). 기존 'DEPOSIT' 값을 입출금 의미로 명확히 하고,
-- 예적금 예시 계좌를 추가한다.

USE financial_mock;

-- 기존 입출금 계좌(KB Star 입출금통장)를 DEMAND_DEPOSIT으로 명확화
UPDATE mock_codef_account
SET account_type = 'DEMAND_DEPOSIT',
    updated_at = CURRENT_TIMESTAMP
WHERE account_type = 'DEPOSIT'
  AND account_no_masked = '123456******7890';

-- 예적금(정기예금) 예시 계좌 추가 (demo-normal-user, 국민은행 connection)
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
  c.institution_id,
  'SAVINGS',
  '110234******5678',
  'mock-encrypted-savings-001',
  'KB 정기예금',
  'KRW',
  'ACTIVE',
  '2025-06-01',
  JSON_OBJECT(
    'resAccount', '110234******5678',
    'resAccountName', 'KB 정기예금',
    'resAccountDeposit', '정기예금',
    'resAccountCurrency', 'KRW'
  )
FROM mock_codef_connection c
WHERE c.connected_id = 'conn-demo-normal-kb'
ON DUPLICATE KEY UPDATE
  account_name = VALUES(account_name),
  currency = VALUES(currency),
  status = VALUES(status),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;

-- 예적금 계좌 잔액 스냅샷
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
  10000000.00,
  10000000.00,
  10000000.00,
  JSON_OBJECT(
    'resAccountBalance', '10000000',
    'resAccountAvailableBalance', '10000000',
    'resAccountCurrency', 'KRW'
  )
FROM mock_codef_account a
WHERE a.account_no_masked = '110234******5678'
ON DUPLICATE KEY UPDATE
  balance = VALUES(balance),
  available_amount = VALUES(available_amount),
  valuation_amount = VALUES(valuation_amount),
  raw_json = VALUES(raw_json),
  updated_at = CURRENT_TIMESTAMP;
