USE financial_mock;

-- =====================================================================
-- [2026-08-19] scenario_key='9' — 카드 승인/은행 정합성 검증 전용 사용자
--
-- 선행 조건: schema-v2.sql → seed-v2.sql 순서로 먼저 적용돼 있어야 한다.
-- financial_institution 의 '0004'(KB국민은행)·'0381'(KB국민카드) 행을 seed-v2.sql 이
-- 넣기 때문에, 이 파일만 단독으로 먼저 돌리면 institution_id 조인이 0행으로 조용히 빠진다.
--
-- scenario_key='2'(seed-v2-scenario2.sql)는 계좌 하나에 bank_transaction 만 채운
-- "카테고리 다양성" 전용 시나리오였다. scenario_key='3'(seed-v2-scenario3.sql)에서
-- 한 걸음 더 나가 **카드 승인내역(card_approval)과 은행 입출금(bank_transaction) 두
-- 소스를 합쳐서 거래를 감지하는 탕탕 앱의 실제 동작을 재현**했고, scenario_key=
-- '4'/'5'/'6'/'7'/'8'(seed-v2-scenario4.sql~8.sql)에 이어 이 시나리오도 그 구조를
-- 그대로 재사용하는 독립된 사용자(계좌·카드 번호·MOD 계수만 다름)다 — 카드 정합성
-- 로직을 사용자 여러 명으로 병렬 테스트할 때 쓴다. scenario3~8 이 그랬던 것처럼
-- is_large/is_checkcard/small_bc/large_bc/daily_count 의 곱셈 계수를 3~8 어느
-- 것과도 겹치지 않는 새 값(daily_count 모듈러스 6/17, is_large 61/71, is_checkcard
-- 73/79, small idx 83/89, large idx 139/109, 급여 계수 227)으로 골라 날짜별
-- 카테고리·금액·체크/신용 배정이 실제로 다르게 나오도록 했다. large idx 는 처음
-- 97/101 로 시작했으나 로컬 검증에서 고액군 15개 중 2개(주유/충전·숙박)가 153일
-- 동안 단 한 번도 뽑히지 않는 걸 발견해(고액군은 전체 이벤트의 ~6%뿐이라 표본이
-- 작아 계수에 따라 특정 잔차가 통째로 비는 경우가 생긴다) 139/109 로 교체해
-- 15개 전부가 최소 1회 이상 나오는지 재확인했다. 신용카드·체크카드는
-- 정산 방식이 다르므로 소비를 3갈래로 나눠 각기 다른 소스에 기록한다:
--
--   그룹 A (자동이체, 12개 소분류) — 카드를 거치지 않고 bank_transaction 에 매월 1회
--     직접 기록한다.
--   그룹 B (체크카드, 32개 소분류 중 ~30%) — card_approval 1행 + bank_transaction 1행을
--     같은 correlationId 로 묶어 "1건의 소비"를 두 소스에서 동시에 표현한다.
--   그룹 C (신용카드, 32개 소분류 중 ~70%) — card_approval 에만 개별 소비를 기록하고,
--     bank_transaction 에는 그 달 신용카드 승인합계와 정확히 같은 금액의 "카드 이용대금"
--     1건만(다음달 14일 정산) 기록한다. 이 정산행의 challengeCategory 는 NULL 로 둬서
--     이미 card_approval 로 잡힌 소비가 집계에서 다시 잡히는 이중계산을 막는다.
--
-- 재실행해도 같은 결과가 나와야 ON DUPLICATE KEY UPDATE 멱등성이 유지되므로 MySQL
-- RAND() 대신 day_offset(n)·슬롯번호(s)를 시드로 한 결정론적 MOD 연산으로 "랜덤"을
-- 흉내낸다(scenario2 와 동일한 기법). daily_count(하루 2~5건)/카테고리 인덱스/시간/
-- 금액 모두 이 방식으로 정한다. 곱셈 계수는 서로 다른 모듈러스에 대해 서로소가 되도록
-- 골랐다(계수를 바꿀 일이 있으면 scenario2 파일 head 의 경고를 참고해 모듈러스와
-- 서로소인지 반드시 확인할 것 — 계수가 모듈러스의 배수가 되면 그 항이 사라져 특정
-- 축에만 의존하는 조인이 되면서 카테고리 다양성이 깨진다).
--
-- 그룹 B/C 카테고리 32개는 다시 "소액/고빈도"(17개) vs "고액/저빈도"(15개) 로 나누고
-- ~6% 확률로만 고액군을 뽑는다(scenario2 의 small/large 기법과 동일 사상). 32개를
-- 균등 확률로 뽑으면 평균 소비액이 너무 커져(고액 카테고리 상당수가 5~50만원대) 월
-- 지출이 급여(290~350만원)를 구조적으로 초과해 잔액이 마이너스로 떨어진다 — 로컬
-- MySQL 로 실제 로드해 MIN(balance_after) 를 확인하며 이 확률·시작잔액을 맞췄다.
--
-- 계좌 시작 잔액은 350만원 — 4/25 첫 급여 전까지 4월 그룹A+그룹B 지출을 감당해야 해서
-- scenario2 의 300만원보다 여유를 뒀다(scenario3~8 과 동일).
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. 기본 개체: 사용자 · 계좌 1개 · 카드 2장(신용/체크) · 카드-계좌 연결
-- ---------------------------------------------------------------------
INSERT INTO mock_user (scenario_key, nickname, email) VALUES
  ('9', '카드 정합성 검증 테스트 사용자 9', 'card.split.test9@example.com')
ON DUPLICATE KEY UPDATE nickname=VALUES(nickname), email=VALUES(email), updated_at=CURRENT_TIMESTAMP;

INSERT INTO bank_account (user_id, institution_id, account_no_masked, product_name, account_type_code, account_status_code, currency, balance, available_amount, opened_at, last_synced_at, raw_json)
SELECT u.id, i.id, '004909******9009', 'KB 카드 정합성 검증 통장', '1001', '01', 'KRW', 3500000.00, 3500000.00, '2026-03-25', '2026-08-31 23:59:00', JSON_OBJECT('scenarioKey', '9')
FROM mock_user u JOIN financial_institution i ON i.institution_code = '0004'
WHERE u.scenario_key = '9'
ON DUPLICATE KEY UPDATE product_name=VALUES(product_name), last_synced_at=VALUES(last_synced_at), raw_json=VALUES(raw_json), updated_at=CURRENT_TIMESTAMP;

INSERT INTO card (user_id, institution_id, card_no_masked, product_name, card_product_code, card_type_code, card_status_code, currency, issued_at, last_synced_at, raw_json)
SELECT u.id, i.id, x.no, x.name, x.code, x.type, '01', 'KRW', '2026-03-25', '2026-08-31 23:59:00', JSON_OBJECT('scenarioKey', '9')
FROM mock_user u JOIN financial_institution i ON i.institution_code = '0381'
JOIN (
  SELECT '9490-****-****-9901' AS no, 'KB 카드 정합성 검증 신용카드' AS name, 'KB-CRD-9901' AS code, '01' AS type UNION ALL
  SELECT '5210-****-****-9902', 'KB 카드 정합성 검증 체크카드', 'KB-CHK-9902', '02'
) x
WHERE u.scenario_key = '9'
ON DUPLICATE KEY UPDATE product_name=VALUES(product_name), card_product_code=VALUES(card_product_code), card_type_code=VALUES(card_type_code), last_synced_at=VALUES(last_synced_at), raw_json=VALUES(raw_json), updated_at=CURRENT_TIMESTAMP;

INSERT INTO card_payment_account (card_id, bank_account_id, valid_from, valid_to, is_primary, source_type, match_confidence)
SELECT c.id, b.id, '2026-03-25', NULL, 1, 'SEED', 1.0000
FROM card c JOIN mock_user u ON u.id = c.user_id JOIN bank_account b ON b.user_id = u.id AND b.account_no_masked = '004909******9009'
WHERE u.scenario_key = '9' AND c.card_no_masked IN ('9490-****-****-9901', '5210-****-****-9902')
ON DUPLICATE KEY UPDATE valid_to=VALUES(valid_to), is_primary=VALUES(is_primary), source_type=VALUES(source_type), match_confidence=VALUES(match_confidence), updated_at=CURRENT_TIMESTAMP;

-- ---------------------------------------------------------------------
-- 1. 그룹 B/C 카드 승인내역(card_approval) — 체크카드/신용카드 공통 일별 생성
--    체크카드(그룹B, ~30%)는 아래 2절에서 같은 날짜·슬롯·금액으로 bank_transaction
--    한 행을 correlationId 로 묶어 추가한다. 신용카드(그룹C, ~70%)는 여기서 끝난다.
-- ---------------------------------------------------------------------
INSERT INTO card_approval (card_id, approval_no, approved_at, approval_type_code, approval_type_name, merchant_name, merchant_business_no, merchant_category_code, merchant_category_name, approved_amount, currency, description, raw_json)
WITH RECURSIVE calendar_days AS (
  SELECT DATE('2026-04-01') AS tx_date, 0 AS day_offset
  UNION ALL
  SELECT tx_date + INTERVAL 1 DAY, day_offset + 1 FROM calendar_days WHERE tx_date < '2026-08-31'
),
slots AS (
  SELECT 1 AS slot_no UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
),
small_bc AS (
  SELECT 0 idx,'음식점/외식' cat,'5812' mcc,'이바돔감자탕 강남점' mch,8000 amin,18000 amax UNION ALL
  SELECT 1,'배달앱','5812','배달의민족',10000,20000 UNION ALL
  SELECT 2,'카페/간식','5814','스타벅스 강남역점',4000,9000 UNION ALL
  SELECT 3,'편의점','5499','GS25 역삼센터점',3000,12000 UNION ALL
  SELECT 4,'뷰티','5977','올리브영 강남점',10000,20000 UNION ALL
  SELECT 5,'대중교통','4111','카카오T버스',3000,6000 UNION ALL
  SELECT 6,'택시/모빌리티','4121','카카오T',6000,18000 UNION ALL
  SELECT 7,'주차/통행료','7523','강남역공영주차장',3000,10000 UNION ALL
  SELECT 8,'생활용품','5331','다이소 강남역점',5000,20000 UNION ALL
  SELECT 9,'세탁비','7210','크린토피아 역삼점',5000,15000 UNION ALL
  SELECT 10,'반려동물','5995','펫프렌즈',10000,20000 UNION ALL
  SELECT 11,'영화·공연·전시','7832','CGV 강남',12000,20000 UNION ALL
  SELECT 12,'도서','5942','교보문고 강남점',10000,20000 UNION ALL
  SELECT 13,'취미','5945','핫트랙스 강남점',10000,20000 UNION ALL
  SELECT 14,'약국','5912','온누리약국 역삼점',5000,20000 UNION ALL
  SELECT 15,'건강관리','8099','강남정성한의원',10000,20000 UNION ALL
  SELECT 16,'학습 교재','5942','예스24',10000,20000
),
large_bc AS (
  SELECT 0 idx,'온라인쇼핑' cat,'5399' mcc,'쿠팡' mch,50000 amin,150000 amax UNION ALL
  SELECT 1,'패션','5651','무신사',50000,150000 UNION ALL
  SELECT 2,'주유/충전','5541','GS칼텍스 역삼주유소',50000,100000 UNION ALL
  SELECT 3,'장보기/마트','5411','이마트 역삼점',50000,150000 UNION ALL
  SELECT 4,'경조사/선물','5947','카카오선물하기',50000,200000 UNION ALL
  SELECT 5,'자녀','8351','뽀로로 어린이집',50000,150000 UNION ALL
  SELECT 6,'레저','7997','잠실클라이밍짐',50000,150000 UNION ALL
  SELECT 7,'교통권','4511','대한항공',80000,300000 UNION ALL
  SELECT 8,'숙박','7011','롯데호텔 제주',80000,300000 UNION ALL
  SELECT 9,'관광·여행상품','4722','하나투어',100000,500000 UNION ALL
  SELECT 10,'병원','8062','서울역삼의원',50000,150000 UNION ALL
  SELECT 11,'운동시설','7997','강남스포애니',50000,150000 UNION ALL
  SELECT 12,'학원','8299','강남토익학원',100000,400000 UNION ALL
  SELECT 13,'온라인 강의','8241','인프런',50000,150000 UNION ALL
  SELECT 14,'시험/자격증','8249','한국산업인력공단',50000,200000
),
daily_slots AS (
  SELECT d.tx_date, d.day_offset AS n, s.slot_no AS s,
         2 + MOD(MOD(d.day_offset,6) + MOD(d.day_offset,17), 4) AS daily_count,
         (MOD(d.day_offset*61 + s.slot_no*71, 100) < 6) AS is_large,
         (MOD(d.day_offset*73 + s.slot_no*79, 100) < 30) AS is_checkcard
  FROM calendar_days d CROSS JOIN slots s
),
filtered AS (
  SELECT * FROM daily_slots WHERE s <= daily_count
),
computed_rows AS (
  SELECT f.tx_date, f.n, f.s, f.is_large, f.is_checkcard,
         sc.cat scat, sc.mcc smcc, sc.mch smch, sc.amin samin, sc.amax samax,
         lc.cat lcat, lc.mcc lmcc, lc.mch lmch, lc.amin lamin, lc.amax lamax
  FROM filtered f
  LEFT JOIN small_bc sc ON sc.idx = MOD(f.n*83 + f.s*89, 17)
  LEFT JOIN large_bc lc ON lc.idx = MOD(f.n*139 + f.s*109, 15)
),
rows_final AS (
  SELECT
    cr.tx_date, cr.n, cr.s, cr.is_checkcard,
    TIMESTAMP(cr.tx_date, SEC_TO_TIME(
      (CASE cr.s WHEN 1 THEN 8 WHEN 2 THEN 12 WHEN 3 THEN 15 WHEN 4 THEN 18 ELSE 21 END)*3600
      + MOD(cr.n*7 + cr.s*53, 60)*60
    )) AS tat,
    CASE WHEN cr.is_large THEN
      ROUND((cr.lamin + (cr.lamax-cr.lamin) * MOD(cr.n*31 + cr.s*67, 1000) / 1000) / 100) * 100
    ELSE
      ROUND((cr.samin + (cr.samax-cr.samin) * MOD(cr.n*31 + cr.s*67, 1000) / 1000) / 100) * 100
    END AS amt,
    CASE WHEN cr.is_large THEN cr.lcat ELSE cr.scat END AS catv,
    CASE WHEN cr.is_large THEN cr.lmcc ELSE cr.smcc END AS mccv,
    CASE WHEN cr.is_large THEN cr.lmch ELSE cr.smch END AS mchv
  FROM computed_rows cr
)
SELECT
  IF(rf.is_checkcard, chk.id, crd.id) AS card_id,
  CASE WHEN rf.is_checkcard THEN CONCAT('S9-A-CHK-', DATE_FORMAT(rf.tx_date,'%Y%m%d'), '-', LPAD(rf.s,2,'0'))
       ELSE CONCAT('S9-A-CRD-', DATE_FORMAT(rf.tx_date,'%Y%m%d'), '-', LPAD(rf.s,2,'0')) END AS approval_no,
  rf.tat,
  '01', '승인',
  rf.mchv,
  '000-00-00000',
  rf.mccv,
  rf.catv,
  rf.amt,
  'KRW',
  rf.mchv,
  JSON_OBJECT(
    'merchantName', rf.mchv, 'mcc', rf.mccv, 'challengeCategory', rf.catv,
    'correlationId', IF(rf.is_checkcard, CONCAT('S9-CHK-', DATE_FORMAT(rf.tx_date,'%Y%m%d'), '-', LPAD(rf.s,2,'0')), NULL),
    'challengeEligible', true
  )
FROM rows_final rf
JOIN mock_user u ON u.scenario_key = '9'
JOIN card chk ON chk.user_id = u.id AND chk.card_no_masked = '5210-****-****-9902'
JOIN card crd ON crd.user_id = u.id AND crd.card_no_masked = '9490-****-****-9901'
ON DUPLICATE KEY UPDATE
  approved_at=VALUES(approved_at), merchant_name=VALUES(merchant_name), merchant_category_code=VALUES(merchant_category_code),
  merchant_category_name=VALUES(merchant_category_name), approved_amount=VALUES(approved_amount), raw_json=VALUES(raw_json),
  updated_at=CURRENT_TIMESTAMP;

-- ---------------------------------------------------------------------
-- 2. bank_transaction — 그룹A(월 1회 자동이체) + 그룹B(체크카드 은행측 다리) +
--    급여(월 1회) + 그룹C 정산(월 1회, card_approval 합계 서브쿼리) 를 한 스트림으로
--    합쳐 잔액을 이어 계산한다.
-- ---------------------------------------------------------------------
INSERT INTO bank_transaction (bank_account_id, original_transaction_id, transacted_at, trans_type_code, trans_type_name, amount, balance_after, description, raw_json)
WITH RECURSIVE calendar_days AS (
  SELECT DATE('2026-04-01') AS tx_date, 0 AS day_offset
  UNION ALL
  SELECT tx_date + INTERVAL 1 DAY, day_offset + 1 FROM calendar_days WHERE tx_date < '2026-08-31'
),
slots AS (
  SELECT 1 AS slot_no UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
),
small_bc AS (
  SELECT 0 idx,'음식점/외식' cat,'5812' mcc,'이바돔감자탕 강남점' mch,8000 amin,18000 amax UNION ALL
  SELECT 1,'배달앱','5812','배달의민족',10000,20000 UNION ALL
  SELECT 2,'카페/간식','5814','스타벅스 강남역점',4000,9000 UNION ALL
  SELECT 3,'편의점','5499','GS25 역삼센터점',3000,12000 UNION ALL
  SELECT 4,'뷰티','5977','올리브영 강남점',10000,20000 UNION ALL
  SELECT 5,'대중교통','4111','카카오T버스',3000,6000 UNION ALL
  SELECT 6,'택시/모빌리티','4121','카카오T',6000,18000 UNION ALL
  SELECT 7,'주차/통행료','7523','강남역공영주차장',3000,10000 UNION ALL
  SELECT 8,'생활용품','5331','다이소 강남역점',5000,20000 UNION ALL
  SELECT 9,'세탁비','7210','크린토피아 역삼점',5000,15000 UNION ALL
  SELECT 10,'반려동물','5995','펫프렌즈',10000,20000 UNION ALL
  SELECT 11,'영화·공연·전시','7832','CGV 강남',12000,20000 UNION ALL
  SELECT 12,'도서','5942','교보문고 강남점',10000,20000 UNION ALL
  SELECT 13,'취미','5945','핫트랙스 강남점',10000,20000 UNION ALL
  SELECT 14,'약국','5912','온누리약국 역삼점',5000,20000 UNION ALL
  SELECT 15,'건강관리','8099','강남정성한의원',10000,20000 UNION ALL
  SELECT 16,'학습 교재','5942','예스24',10000,20000
),
large_bc AS (
  SELECT 0 idx,'온라인쇼핑' cat,'5399' mcc,'쿠팡' mch,50000 amin,150000 amax UNION ALL
  SELECT 1,'패션','5651','무신사',50000,150000 UNION ALL
  SELECT 2,'주유/충전','5541','GS칼텍스 역삼주유소',50000,100000 UNION ALL
  SELECT 3,'장보기/마트','5411','이마트 역삼점',50000,150000 UNION ALL
  SELECT 4,'경조사/선물','5947','카카오선물하기',50000,200000 UNION ALL
  SELECT 5,'자녀','8351','뽀로로 어린이집',50000,150000 UNION ALL
  SELECT 6,'레저','7997','잠실클라이밍짐',50000,150000 UNION ALL
  SELECT 7,'교통권','4511','대한항공',80000,300000 UNION ALL
  SELECT 8,'숙박','7011','롯데호텔 제주',80000,300000 UNION ALL
  SELECT 9,'관광·여행상품','4722','하나투어',100000,500000 UNION ALL
  SELECT 10,'병원','8062','서울역삼의원',50000,150000 UNION ALL
  SELECT 11,'운동시설','7997','강남스포애니',50000,150000 UNION ALL
  SELECT 12,'학원','8299','강남토익학원',100000,400000 UNION ALL
  SELECT 13,'온라인 강의','8241','인프런',50000,150000 UNION ALL
  SELECT 14,'시험/자격증','8249','한국산업인력공단',50000,200000
),
daily_slots AS (
  SELECT d.tx_date, d.day_offset AS n, s.slot_no AS s,
         2 + MOD(MOD(d.day_offset,6) + MOD(d.day_offset,17), 4) AS daily_count,
         (MOD(d.day_offset*61 + s.slot_no*71, 100) < 6) AS is_large,
         (MOD(d.day_offset*73 + s.slot_no*79, 100) < 30) AS is_checkcard
  FROM calendar_days d CROSS JOIN slots s
),
filtered AS (
  SELECT * FROM daily_slots WHERE s <= daily_count AND is_checkcard = 1
),
computed_rows AS (
  SELECT f.tx_date, f.n, f.s, f.is_large,
         sc.cat scat, sc.mcc smcc, sc.mch smch, sc.amin samin, sc.amax samax,
         lc.cat lcat, lc.mcc lmcc, lc.mch lmch, lc.amin lamin, lc.amax lamax
  FROM filtered f
  LEFT JOIN small_bc sc ON sc.idx = MOD(f.n*83 + f.s*89, 17)
  LEFT JOIN large_bc lc ON lc.idx = MOD(f.n*139 + f.s*109, 15)
),
checkcard_legs AS (
  SELECT
    CONCAT('S9-B-CHK-', DATE_FORMAT(cr.tx_date,'%Y%m%d'), '-', LPAD(cr.s,2,'0')) AS tid,
    TIMESTAMP(cr.tx_date, SEC_TO_TIME(
      (CASE cr.s WHEN 1 THEN 8 WHEN 2 THEN 12 WHEN 3 THEN 15 WHEN 4 THEN 18 ELSE 21 END)*3600
      + MOD(cr.n*7 + cr.s*53, 60)*60
    )) AS tat,
    '02' AS code, '출금' AS tname,
    CASE WHEN cr.is_large THEN
      ROUND((cr.lamin + (cr.lamax-cr.lamin) * MOD(cr.n*31 + cr.s*67, 1000) / 1000) / 100) * 100
    ELSE
      ROUND((cr.samin + (cr.samax-cr.samin) * MOD(cr.n*31 + cr.s*67, 1000) / 1000) / 100) * 100
    END AS amt,
    CASE WHEN cr.is_large THEN cr.lmch ELSE cr.smch END AS descr,
    CASE WHEN cr.is_large THEN cr.lcat ELSE cr.scat END AS catv,
    CASE WHEN cr.is_large THEN cr.lmcc ELSE cr.smcc END AS mccv,
    CASE WHEN cr.is_large THEN cr.lmch ELSE cr.smch END AS mchv,
    CONCAT('S9-CHK-', DATE_FORMAT(cr.tx_date,'%Y%m%d'), '-', LPAD(cr.s,2,'0')) AS corr
  FROM computed_rows cr
),
ga_categories AS (
  SELECT 0 idx,'월세' cat,'6513' mcc,'역삼오피스텔 월세' mch,400000 amin,500000 amax UNION ALL
  SELECT 1,'관리비','6513','역삼래미안 관리비',100000,200000 UNION ALL
  SELECT 2,'전기·가스·수도','4900','한국전력공사',50000,120000 UNION ALL
  SELECT 3,'통신비','4814','SK텔레콤',50000,70000 UNION ALL
  SELECT 4,'OTT','4899','티빙',9900,17000 UNION ALL
  SELECT 5,'음원','5735','멜론',8000,13000 UNION ALL
  SELECT 6,'앱·게임','5816','스팀',5000,20000 UNION ALL
  SELECT 7,'소프트웨어·클라우드','5734','노션',10000,20000 UNION ALL
  SELECT 8,'보험료','6300','삼성화재',50000,200000 UNION ALL
  SELECT 9,'이자','6012','KB국민은행 이자',5000,20000 UNION ALL
  SELECT 10,'수수료','6012','KB국민은행 수수료',3000,5000 UNION ALL
  SELECT 11,'금융상품','6211','미래에셋증권',100000,500000
),
months AS (
  SELECT 0 AS month_offset, DATE('2026-04-01') AS month_start UNION ALL
  SELECT 1, DATE('2026-05-01') UNION ALL
  SELECT 2, DATE('2026-06-01') UNION ALL
  SELECT 3, DATE('2026-07-01') UNION ALL
  SELECT 4, DATE('2026-08-01')
),
ga_legs AS (
  SELECT
    CONCAT('S9-A-', DATE_FORMAT(m.month_start,'%Y%m'), '-', LPAD(g.idx,2,'0')) AS tid,
    TIMESTAMP(DATE_ADD(m.month_start, INTERVAL (3 + MOD(g.idx*7, 25) - 1) DAY), SEC_TO_TIME(9*3600 + MOD(g.idx*13,60)*60)) AS tat,
    '02' AS code, '출금' AS tname,
    ROUND((g.amin + (g.amax-g.amin) * MOD(m.month_offset*31 + g.idx*67, 1000) / 1000) / 100) * 100 AS amt,
    g.mch AS descr, g.cat AS catv, g.mcc AS mccv, g.mch AS mchv, NULL AS corr
  FROM months m CROSS JOIN ga_categories g
),
payday_legs AS (
  SELECT
    CONCAT('S9-SAL-', DATE_FORMAT(m.month_start,'%Y%m')) AS tid,
    TIMESTAMP(DATE_ADD(m.month_start, INTERVAL 24 DAY), SEC_TO_TIME(8*3600 + 30*60)) AS tat,
    '01' AS code, '급여' AS tname,
    2900000 + MOD(m.month_offset*227, 601)*1000 AS amt,
    '급여' AS descr, NULL AS catv, NULL AS mccv, NULL AS mchv, NULL AS corr
  FROM months m
),
settlement_months AS (
  SELECT 0 AS month_offset, DATE('2026-04-01') AS billing_start, DATE('2026-04-30') AS billing_end, DATE('2026-05-14') AS due_date UNION ALL
  SELECT 1, DATE('2026-05-01'), DATE('2026-05-31'), DATE('2026-06-14') UNION ALL
  SELECT 2, DATE('2026-06-01'), DATE('2026-06-30'), DATE('2026-07-14') UNION ALL
  SELECT 3, DATE('2026-07-01'), DATE('2026-07-31'), DATE('2026-08-14')
),
settlement_legs AS (
  SELECT
    CONCAT('S9-BILL-', DATE_FORMAT(sm.billing_start,'%Y%m')) AS tid,
    TIMESTAMP(sm.due_date, SEC_TO_TIME(9*3600)) AS tat,
    '02' AS code, '출금' AS tname,
    (SELECT COALESCE(SUM(ca.approved_amount),0) FROM card_approval ca
       JOIN card crd ON crd.id = ca.card_id
       JOIN mock_user u ON u.id = crd.user_id
       WHERE u.scenario_key = '9' AND crd.card_no_masked = '9490-****-****-9901'
         AND ca.approved_at >= sm.billing_start AND ca.approved_at < DATE_ADD(sm.billing_end, INTERVAL 1 DAY)
    ) AS amt,
    '카드 이용대금' AS descr, NULL AS catv, NULL AS mccv, NULL AS mchv,
    CONCAT('S9-CARD-BILL-', DATE_FORMAT(sm.billing_start,'%Y%m')) AS corr
  FROM settlement_months sm
),
all_legs AS (
  SELECT tid, tat, code, tname, amt, descr, catv, mccv, mchv, corr FROM checkcard_legs
  UNION ALL
  SELECT tid, tat, code, tname, amt, descr, catv, mccv, mchv, corr FROM ga_legs
  UNION ALL
  SELECT tid, tat, code, tname, amt, descr, catv, mccv, mchv, corr FROM payday_legs
  UNION ALL
  SELECT tid, tat, code, tname, amt, descr, catv, mccv, mchv, corr FROM settlement_legs
)
SELECT
  b.id,
  al.tid,
  al.tat,
  al.code,
  al.tname,
  al.amt,
  3500000 + SUM(CASE WHEN al.code='01' THEN al.amt ELSE -al.amt END) OVER (ORDER BY al.tat, al.tid ROWS UNBOUNDED PRECEDING) AS balance_after,
  al.descr,
  JSON_OBJECT('merchantName', al.mchv, 'mcc', al.mccv, 'challengeCategory', al.catv, 'correlationId', al.corr, 'challengeEligible', IF(al.catv IS NULL, false, true))
FROM all_legs al
JOIN mock_user u ON u.scenario_key = '9'
JOIN bank_account b ON b.user_id = u.id AND b.account_no_masked = '004909******9009'
ON DUPLICATE KEY UPDATE
  transacted_at=VALUES(transacted_at), trans_type_code=VALUES(trans_type_code), trans_type_name=VALUES(trans_type_name),
  amount=VALUES(amount), balance_after=VALUES(balance_after), description=VALUES(description), raw_json=VALUES(raw_json),
  updated_at=CURRENT_TIMESTAMP;

-- ---------------------------------------------------------------------
-- 3. card_bill — 신용카드 월별 청구서. 4~7월분은 결제완료(다음달 14일 정산 반영),
--    8월분은 기간 종료 시점에 아직 청구 확정만 된 상태(정산 bank_transaction 없음).
-- ---------------------------------------------------------------------
INSERT INTO card_bill (card_id, billing_month, due_date, bill_status_code, bill_status_name, total_amount, paid_amount, raw_json)
SELECT
  c.id, x.billing_month, x.due_date, x.status, x.status_name,
  (SELECT COALESCE(SUM(ca.approved_amount),0) FROM card_approval ca WHERE ca.card_id = c.id
     AND ca.approved_at >= x.billing_month AND ca.approved_at < DATE_ADD(x.billing_month, INTERVAL 1 MONTH)
  ) AS total_amount,
  x.paid_amount_flag *
  (SELECT COALESCE(SUM(ca.approved_amount),0) FROM card_approval ca WHERE ca.card_id = c.id
     AND ca.approved_at >= x.billing_month AND ca.approved_at < DATE_ADD(x.billing_month, INTERVAL 1 MONTH)
  ) AS paid_amount,
  JSON_OBJECT('paymentCorrelationId', x.corr)
FROM card c
JOIN mock_user u ON u.id = c.user_id
JOIN (
  SELECT DATE('2026-04-01') billing_month, DATE('2026-05-14') due_date, '02' status, '결제완료' status_name, 1 paid_amount_flag, 'S9-CARD-BILL-202604' corr UNION ALL
  SELECT DATE('2026-05-01'), DATE('2026-06-14'), '02', '결제완료', 1, 'S9-CARD-BILL-202605' UNION ALL
  SELECT DATE('2026-06-01'), DATE('2026-07-14'), '02', '결제완료', 1, 'S9-CARD-BILL-202606' UNION ALL
  SELECT DATE('2026-07-01'), DATE('2026-08-14'), '02', '결제완료', 1, 'S9-CARD-BILL-202607' UNION ALL
  SELECT DATE('2026-08-01'), DATE('2026-08-31'), '01', '청구확정', 0, NULL
) x
WHERE u.scenario_key = '9' AND c.card_no_masked = '9490-****-****-9901'
ON DUPLICATE KEY UPDATE due_date=VALUES(due_date), bill_status_code=VALUES(bill_status_code), bill_status_name=VALUES(bill_status_name), total_amount=VALUES(total_amount), paid_amount=VALUES(paid_amount), raw_json=VALUES(raw_json), updated_at=CURRENT_TIMESTAMP;

-- ---------------------------------------------------------------------
-- 4. bank_account 잔액을 마지막 거래의 balance_after 로 동기화
-- ---------------------------------------------------------------------
UPDATE bank_account b JOIN mock_user u ON u.id=b.user_id
SET b.balance = (SELECT t.balance_after FROM bank_transaction t WHERE t.bank_account_id=b.id ORDER BY t.transacted_at DESC, t.id DESC LIMIT 1),
    b.available_amount = (SELECT t.balance_after FROM bank_transaction t WHERE t.bank_account_id=b.id ORDER BY t.transacted_at DESC, t.id DESC LIMIT 1),
    b.updated_at = CURRENT_TIMESTAMP
WHERE u.scenario_key='9' AND b.account_no_masked='004909******9009';
