USE financial_mock;

-- =====================================================================
-- [2026-08-19] scenario_key='2' — 거래내역(카테고리 분류) 테스트 전용 사용자
--
-- 선행 조건: schema-v2.sql → seed-v2.sql 순서로 먼저 적용돼 있어야 한다.
-- financial_institution 의 '0004'(KB국민은행) 행을 seed-v2.sql 이 넣기 때문에,
-- 이 파일만 단독으로 먼저 돌리면 institution_id 조인이 0행으로 조용히 빠진다.
--
-- 계좌·카드 등 전체 금융 구조를 채운 seed-v2.sql 의 scenario_key='1'/
-- 'demo-normal-user2' 와 달리, 이 시나리오는 bank_account 1개만 두고
-- bank_transaction 볼륨·카테고리 다양성에만 집중한다. 그래서 seed-v2.sql 에
-- 이어붙이지 않고 별도 파일로 분리했다. 2026-04-01~2026-08-31(153일) 매일
-- 2~5건씩, db/seed_category.sql 기준 소분류 44개를 전부 최소 1회 이상 커버한다.
--
-- 재실행 시에도 같은 결과가 나와야 ON DUPLICATE KEY UPDATE 멱등성이 유지되므로
-- MySQL RAND() 대신 day_offset·슬롯번호를 시드로 한 결정론적 MOD 연산으로
-- "랜덤"을 흉내낸다 — 매일 거래 건수(daily_count), 카테고리 인덱스, 시각(hour/
-- minute), 금액 모두 이 방식으로 정한다.
--
-- ⚠ small_categories/large_categories 조인 인덱스에 쓰는 곱셈 계수는 MOD 의
-- 모듈러스와 절대 같은 값(또는 배수)을 쓰면 안 된다 — 처음 짰을 때 실수로
-- MOD(n*23 + s*41, 23) 을 썼다가 n*23 항이 항상 0으로 사라져 슬롯번호(1~5)에만
-- 의존하는 조인이 되면서 23개 소분류 중 5개만 등장하는 버그가 났다(로컬 검증
-- 중 발견해 n*19 로 교정). 계수를 바꿀 일이 있으면 모듈러스와 서로소인지
-- 반드시 확인한다.
--
-- 계좌 시작 잔액은 300만원 — 4/25 첫 급여(약 288~328만원) 전까지 4월 소비를
-- 감당해야 해서, 예시로 든 80만원보다 넉넉하게 잡았다. 로컬 검증에서
-- MIN(balance_after) 는 48,500원까지 내려가지만 마이너스로 떨어지지 않는다.
-- =====================================================================
INSERT INTO mock_user (scenario_key, nickname, email) VALUES
  ('2', '카테고리 분류 테스트 사용자', 'category.test@example.com')
ON DUPLICATE KEY UPDATE nickname=VALUES(nickname), email=VALUES(email), updated_at=CURRENT_TIMESTAMP;

INSERT INTO bank_account (user_id, institution_id, account_no_masked, product_name, account_type_code, account_status_code, currency, balance, available_amount, opened_at, last_synced_at, raw_json)
SELECT u.id, i.id, '004909******2002', 'KB 카테고리 분류 테스트 통장', '1001', '01', 'KRW', 3000000.00, 3000000.00, '2026-03-25', '2026-08-31 23:59:00', JSON_OBJECT('scenarioKey', '2')
FROM mock_user u JOIN financial_institution i ON i.institution_code = '0004'
WHERE u.scenario_key = '2'
ON DUPLICATE KEY UPDATE product_name=VALUES(product_name), last_synced_at=VALUES(last_synced_at), raw_json=VALUES(raw_json), updated_at=CURRENT_TIMESTAMP;

INSERT INTO bank_transaction (bank_account_id, original_transaction_id, transacted_at, trans_type_code, trans_type_name, amount, balance_after, description, raw_json)
WITH RECURSIVE calendar_days AS (
  SELECT DATE('2026-04-01') AS tx_date, 0 AS day_offset
  UNION ALL
  SELECT tx_date + INTERVAL 1 DAY, day_offset + 1 FROM calendar_days WHERE tx_date < '2026-08-31'
),
slots AS (
  SELECT 1 AS slot_no UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
),
small_categories AS (
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
  SELECT 11,'OTT','4899','티빙',9900,17000 UNION ALL
  SELECT 12,'음원','5735','멜론',8000,13000 UNION ALL
  SELECT 13,'앱·게임','5816','스팀',5000,20000 UNION ALL
  SELECT 14,'소프트웨어·클라우드','5734','노션',10000,20000 UNION ALL
  SELECT 15,'영화·공연·전시','7832','CGV 강남',12000,20000 UNION ALL
  SELECT 16,'도서','5942','교보문고 강남점',10000,20000 UNION ALL
  SELECT 17,'취미','5945','핫트랙스 강남점',10000,20000 UNION ALL
  SELECT 18,'약국','5912','온누리약국 역삼점',5000,20000 UNION ALL
  SELECT 19,'건강관리','8099','강남정성한의원',10000,20000 UNION ALL
  SELECT 20,'학습 교재','5942','예스24',10000,20000 UNION ALL
  SELECT 21,'이자','6012','KB국민은행 이자',5000,20000 UNION ALL
  SELECT 22,'수수료','6012','KB국민은행 수수료',3000,5000
),
large_categories AS (
  SELECT 0 idx,'온라인쇼핑' cat,'5399' mcc,'쿠팡' mch,50000 amin,150000 amax UNION ALL
  SELECT 1,'패션','5651','무신사',50000,150000 UNION ALL
  SELECT 2,'주유/충전','5541','GS칼텍스 역삼주유소',50000,100000 UNION ALL
  SELECT 3,'월세','6513','역삼오피스텔 월세',400000,500000 UNION ALL
  SELECT 4,'관리비','6513','역삼래미안 관리비',100000,200000 UNION ALL
  SELECT 5,'전기·가스·수도','4900','한국전력공사',50000,120000 UNION ALL
  SELECT 6,'장보기/마트','5411','이마트 역삼점',50000,150000 UNION ALL
  SELECT 7,'경조사/선물','5947','카카오선물하기',50000,200000 UNION ALL
  SELECT 8,'자녀','8351','뽀로로 어린이집',50000,150000 UNION ALL
  SELECT 9,'통신비','4814','SK텔레콤',50000,70000 UNION ALL
  SELECT 10,'레저','7997','잠실클라이밍짐',50000,150000 UNION ALL
  SELECT 11,'교통권','4511','대한항공',80000,300000 UNION ALL
  SELECT 12,'숙박','7011','롯데호텔 제주',80000,300000 UNION ALL
  SELECT 13,'관광·여행상품','4722','하나투어',100000,500000 UNION ALL
  SELECT 14,'병원','8062','서울역삼의원',50000,150000 UNION ALL
  SELECT 15,'운동시설','7997','강남스포애니',50000,150000 UNION ALL
  SELECT 16,'학원','8299','강남토익학원',100000,400000 UNION ALL
  SELECT 17,'온라인 강의','8241','인프런',50000,150000 UNION ALL
  SELECT 18,'시험/자격증','8249','한국산업인력공단',50000,200000 UNION ALL
  SELECT 19,'보험료','6300','삼성화재',50000,200000 UNION ALL
  SELECT 20,'금융상품','6211','미래에셋증권',100000,500000
),
daily_slots AS (
  SELECT d.tx_date, d.day_offset AS n, s.slot_no AS s,
         2 + MOD(MOD(d.day_offset,7) + MOD(d.day_offset,11), 4) AS daily_count,
         (DAY(d.tx_date) = 25 AND s.slot_no = 1) AS is_payday,
         (MOD(d.day_offset, 23) = 11 AND s.slot_no = 2) AS is_refund,
         (MOD(d.day_offset*17 + s.slot_no*31, 100) < 10) AS is_large
  FROM calendar_days d CROSS JOIN slots s
),
filtered AS (
  SELECT * FROM daily_slots WHERE s <= daily_count
),
computed_rows AS (
  SELECT f.tx_date, f.n, f.s, f.is_payday, f.is_refund, f.is_large,
         sc.cat scat, sc.mcc smcc, sc.mch smch, sc.amin samin, sc.amax samax,
         lc.cat lcat, lc.mcc lmcc, lc.mch lmch, lc.amin lamin, lc.amax lamax
  FROM filtered f
  LEFT JOIN small_categories sc ON sc.idx = MOD(f.n*19 + f.s*41, 23)
  LEFT JOIN large_categories lc ON lc.idx = MOD(f.n*31 + f.s*43, 21)
),
rows_final AS (
  SELECT
    CONCAT('S2-B-', DATE_FORMAT(cr.tx_date,'%Y%m%d'), '-', LPAD(cr.s,2,'0')) AS tid,
    TIMESTAMP(cr.tx_date, SEC_TO_TIME(
      (CASE cr.s WHEN 1 THEN 8 WHEN 2 THEN 12 WHEN 3 THEN 15 WHEN 4 THEN 18 ELSE 21 END)*3600
      + MOD(cr.n*7 + cr.s*53, 60)*60
    )) AS tat,
    CASE WHEN cr.is_payday OR cr.is_refund THEN '01' ELSE '02' END AS code,
    CASE WHEN cr.is_payday THEN '급여' WHEN cr.is_refund THEN '환불' ELSE '출금' END AS tname,
    CASE
      WHEN cr.is_payday THEN 2500000 + MOD(MONTH(cr.tx_date)*97, 1000)*1000
      WHEN cr.is_refund THEN 5000 + MOD(cr.n*11, 10)*1000
      WHEN cr.is_large THEN ROUND((cr.lamin + (cr.lamax-cr.lamin) * MOD(cr.n*31 + cr.s*67, 1000) / 1000) / 100) * 100
      ELSE ROUND((cr.samin + (cr.samax-cr.samin) * MOD(cr.n*31 + cr.s*67, 1000) / 1000) / 100) * 100
    END AS amt,
    CASE
      WHEN cr.is_payday THEN '급여'
      WHEN cr.is_refund THEN '환불 - 온라인쇼핑 반품'
      WHEN cr.is_large THEN cr.lmch
      ELSE cr.smch
    END AS descr,
    CASE WHEN cr.is_payday OR cr.is_refund THEN NULL WHEN cr.is_large THEN cr.lcat ELSE cr.scat END AS catv,
    CASE WHEN cr.is_payday OR cr.is_refund THEN NULL WHEN cr.is_large THEN cr.lmcc ELSE cr.smcc END AS mccv,
    CASE WHEN cr.is_payday OR cr.is_refund THEN NULL WHEN cr.is_large THEN cr.lmch ELSE cr.smch END AS mchv
  FROM computed_rows cr
)
SELECT
  b.id,
  rf.tid,
  rf.tat,
  rf.code,
  rf.tname,
  rf.amt,
  3000000 + SUM(CASE WHEN rf.code='01' THEN rf.amt ELSE -rf.amt END) OVER (ORDER BY rf.tat ROWS UNBOUNDED PRECEDING) AS balance_after,
  rf.descr,
  JSON_OBJECT('merchantName', rf.mchv, 'mcc', rf.mccv, 'challengeCategory', rf.catv)
FROM rows_final rf
JOIN mock_user u ON u.scenario_key = '2'
JOIN bank_account b ON b.user_id = u.id AND b.account_no_masked = '004909******2002'
ON DUPLICATE KEY UPDATE
  transacted_at=VALUES(transacted_at), trans_type_code=VALUES(trans_type_code), trans_type_name=VALUES(trans_type_name),
  amount=VALUES(amount), balance_after=VALUES(balance_after), description=VALUES(description), raw_json=VALUES(raw_json),
  updated_at=CURRENT_TIMESTAMP;

UPDATE bank_account b JOIN mock_user u ON u.id=b.user_id
SET b.balance = (SELECT t.balance_after FROM bank_transaction t WHERE t.bank_account_id=b.id ORDER BY t.transacted_at DESC LIMIT 1),
    b.available_amount = (SELECT t.balance_after FROM bank_transaction t WHERE t.bank_account_id=b.id ORDER BY t.transacted_at DESC LIMIT 1),
    b.updated_at = CURRENT_TIMESTAMP
WHERE u.scenario_key='2' AND b.account_no_masked='004909******2002';
