package com.financial.mockserver.service.impl;

import com.financial.mockserver.domain.MockApiEndpoint;
import com.financial.mockserver.domain.MockApiResponseFixture;
import com.financial.mockserver.domain.MockScenario;
import com.financial.mockserver.domain.MockUser;
import com.financial.mockserver.domain.ResolvedScenario;
import com.financial.mockserver.dto.AccountResponse;
import com.financial.mockserver.dto.ApiEnvelope;
import com.financial.mockserver.dto.CodefBalanceResponse;
import com.financial.mockserver.dto.DepositListResponse;
import com.financial.mockserver.dto.DepositResponse;
import com.financial.mockserver.dto.LoanListResponse;
import com.financial.mockserver.dto.LoanResponse;
import com.financial.mockserver.dto.PayMoneyListResponse;
import com.financial.mockserver.dto.PayMoneyResponse;
import com.financial.mockserver.dto.StockAssetResponse;
import com.financial.mockserver.dto.StockHoldingResponse;
import com.financial.mockserver.mapper.MockAssetMapper;
import com.financial.mockserver.service.MockCallLogService;
import com.financial.mockserver.service.MockFixtureService;
import com.financial.mockserver.support.MockApiResult;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * mock_codef_* 원천 테이블에서 조회한 값으로 합계/수익률을 정확히 조립하는지 검증한다.
 * 실제 DB 대신 MockAssetMapper를 stub으로 대체한다.
 */
class MockAssetServiceImplTest {

    private static final MockUser USER = user(10L, "demo-normal-user");
    private static final MockScenario NORMAL = scenario("NORMAL");

    private MockAssetServiceImpl service;
    private StubAssetMapper assetMapper;

    @BeforeEach
    void setUp() {
        service = new MockAssetServiceImpl();
        assetMapper = new StubAssetMapper();

        ReflectionTestUtils.setField(service, "assetMapper", assetMapper);
        ReflectionTestUtils.setField(service, "fixtureService", alwaysNormalFixtureService());
        ReflectionTestUtils.setField(service, "callLogService", noOpCallLogService());
    }

    @Test
    void getStocks_computesTotalsAndProfitLossRate_fromHoldings() {
        assetMapper.stockSummary = stockSummary(2L, "KB증권 종합위탁");
        assetMapper.stockHoldings = Arrays.asList(
                holding("005930", "삼성전자", "864000", "942000", "78000"),
                holding("035720", "카카오", "384000", "361600", "-22400"));

        MockApiResult result = service.getStocks("demo-normal-user", null);

        StockAssetResponse data = extractData(result, StockAssetResponse.class);
        assertEquals(0, new BigDecimal("1248000").compareTo(data.getTotalPurchaseAmount()));
        assertEquals(0, new BigDecimal("1303600").compareTo(data.getTotalMarketValue()));
        assertEquals(0, new BigDecimal("55600").compareTo(data.getTotalProfitLossAmount()));
        assertEquals(0, new BigDecimal("4.4551").compareTo(data.getTotalProfitLossRate()));
        assertEquals(200, result.getHttpStatus());
    }

    @Test
    void getStocks_returnsZeroedResponse_whenUserHasNoStockAccount() {
        assetMapper.stockSummary = null;

        MockApiResult result = service.getStocks("demo-normal-user", null);

        StockAssetResponse data = extractData(result, StockAssetResponse.class);
        assertTrue(data.getHoldings().isEmpty());
        assertEquals(0, BigDecimal.ZERO.compareTo(data.getTotalPurchaseAmount()));
        assertEquals(0, BigDecimal.ZERO.compareTo(data.getTotalProfitLossRate()));
    }

    @Test
    void getLoans_sumsLoanAmountAndBalance_acrossAllLoans() {
        assetMapper.loans = Arrays.asList(
                loan(1L, "20000000", "14200000"),
                loan(2L, "5000000", "5000000"));
        assetMapper.loanLastSyncAt = "2026-07-31T10:30:00+09:00";

        MockApiResult result = service.getLoans("demo-normal-user", null);

        LoanListResponse data = extractData(result, LoanListResponse.class);
        assertEquals(0, new BigDecimal("25000000").compareTo(data.getTotalLoanAmount()));
        assertEquals(0, new BigDecimal("19200000").compareTo(data.getTotalBalance()));
        assertEquals("2026-07-31T10:30:00+09:00", data.getLastSyncAt());
    }

    @Test
    void getDeposits_sumsPrincipalAndBalance() {
        assetMapper.deposits = Arrays.asList(
                deposit(1L, "5000000", "5032000"),
                deposit(2L, "3000000", "3015000"));
        assetMapper.depositLastSyncAt = "2026-07-31T10:30:00+09:00";

        MockApiResult result = service.getDeposits("demo-normal-user", null);

        DepositListResponse data = extractData(result, DepositListResponse.class);
        assertEquals(0, new BigDecimal("8000000").compareTo(data.getTotalPrincipal()));
        assertEquals(0, new BigDecimal("8047000").compareTo(data.getTotalBalance()));
        assertEquals("2026-07-31T10:30:00+09:00", data.getLastSyncAt());
    }

    @Test
    void getPayMoney_sumsBalanceAndPointAmount() {
        assetMapper.payMoney = Collections.singletonList(payMoney(1L, "83500", "1240"));

        MockApiResult result = service.getPayMoney("demo-normal-user", null);

        PayMoneyListResponse data = extractData(result, PayMoneyListResponse.class);
        assertEquals(0, new BigDecimal("83500").compareTo(data.getTotalBalance()));
        assertEquals(0, new BigDecimal("1240").compareTo(data.getTotalPointAmount()));
    }

    @SuppressWarnings("unchecked")
    private <T> T extractData(MockApiResult result, Class<T> type) {
        Object body = result.getBody();
        assertTrue(body instanceof ApiEnvelope, "동적 조립 응답은 ApiEnvelope 이어야 한다");
        Object data = ((ApiEnvelope<?>) body).getData();
        assertTrue(type.isInstance(data));
        return (T) data;
    }

    private MockFixtureService alwaysNormalFixtureService() {
        return new MockFixtureService() {
            @Override
            public ResolvedScenario resolveContext(String method, String path, String scenarioKey, String scenarioOverride) {
                MockApiEndpoint endpoint = new MockApiEndpoint();
                endpoint.setId(1L);
                endpoint.setMethod(method);
                endpoint.setPath(path);
                return new ResolvedScenario(USER, endpoint, NORMAL);
            }

            @Override
            public Optional<MockApiResponseFixture> findFixture(ResolvedScenario context) {
                return Optional.empty();
            }
        };
    }

    private MockCallLogService noOpCallLogService() {
        return (context, requestMethod, requestPath, requestJson, responseStatus, traceId, responseFixtureId) -> {
            // 테스트에서는 호출 로그 저장을 검증하지 않는다.
        };
    }

    private static MockUser user(Long id, String scenarioKey) {
        MockUser u = new MockUser();
        u.setId(id);
        u.setScenarioKey(scenarioKey);
        u.setIsActive(true);
        return u;
    }

    private static MockScenario scenario(String code) {
        MockScenario s = new MockScenario();
        s.setId(1L);
        s.setScenarioCode(code);
        s.setHttpStatus(200);
        s.setAppCode("SUCCESS");
        s.setIsDefault(true);
        return s;
    }

    private static StockAssetResponse stockSummary(Long accountId, String accountName) {
        StockAssetResponse response = new StockAssetResponse();
        response.setAccountId(accountId);
        response.setAccountName(accountName);
        response.setCurrency("KRW");
        response.setLastSyncAt("2026-07-31T10:30:00+09:00");
        return response;
    }

    private static StockHoldingResponse holding(String code, String name, String purchase, String marketValue, String profitLoss) {
        StockHoldingResponse h = new StockHoldingResponse();
        h.setStockCode(code);
        h.setStockName(name);
        h.setMarketCountry("KR");
        h.setCurrency("KRW");
        h.setPurchaseAmount(new BigDecimal(purchase));
        h.setMarketValue(new BigDecimal(marketValue));
        h.setProfitLossAmount(new BigDecimal(profitLoss));
        return h;
    }

    private static LoanResponse loan(Long id, String loanAmount, String balance) {
        LoanResponse l = new LoanResponse();
        l.setLoanId(id);
        l.setLoanAmount(new BigDecimal(loanAmount));
        l.setBalance(new BigDecimal(balance));
        return l;
    }

    private static DepositResponse deposit(Long id, String principal, String balance) {
        DepositResponse d = new DepositResponse();
        d.setDepositAccountId(id);
        d.setPrincipal(new BigDecimal(principal));
        d.setBalance(new BigDecimal(balance));
        return d;
    }

    private static PayMoneyResponse payMoney(Long id, String balance, String pointAmount) {
        PayMoneyResponse p = new PayMoneyResponse();
        p.setPayMoneyId(id);
        p.setBalance(new BigDecimal(balance));
        p.setPointAmount(new BigDecimal(pointAmount));
        return p;
    }

    /**
     * MockAssetMapper의 테스트용 stub. 필요한 반환값만 설정해서 사용한다.
     */
    private static class StubAssetMapper implements MockAssetMapper {
        List<AccountResponse> bankAccounts = Collections.emptyList();
        List<DepositResponse> deposits = Collections.emptyList();
        String depositLastSyncAt;
        StockAssetResponse stockSummary;
        List<StockHoldingResponse> stockHoldings = Collections.emptyList();
        List<LoanResponse> loans = Collections.emptyList();
        String loanLastSyncAt;
        List<PayMoneyResponse> payMoney = Collections.emptyList();
        Long accountIdByMaskedNo;
        Long firstDepositAccountId;
        CodefBalanceResponse latestBalance;

        @Override
        public List<AccountResponse> findBankAccounts(Long userId) {
            return bankAccounts;
        }

        @Override
        public List<DepositResponse> findDeposits(Long userId) {
            return deposits;
        }

        @Override
        public String findDepositLastSyncAt(Long userId) {
            return depositLastSyncAt;
        }

        @Override
        public StockAssetResponse findStockAccountSummary(Long userId) {
            return stockSummary;
        }

        @Override
        public List<StockHoldingResponse> findStockHoldings(Long accountId) {
            return stockHoldings;
        }

        @Override
        public List<LoanResponse> findLoans(Long userId) {
            return loans;
        }

        @Override
        public String findLoanLastSyncAt(Long userId) {
            return loanLastSyncAt;
        }

        @Override
        public List<PayMoneyResponse> findPayMoney(Long userId) {
            return payMoney;
        }

        @Override
        public Long findAccountIdByMaskedNo(Long userId, String accountNoMasked) {
            return accountIdByMaskedNo;
        }

        @Override
        public Long findFirstDepositAccountId(Long userId) {
            return firstDepositAccountId;
        }

        @Override
        public CodefBalanceResponse findLatestBalance(Long accountId) {
            return latestBalance;
        }
    }
}
