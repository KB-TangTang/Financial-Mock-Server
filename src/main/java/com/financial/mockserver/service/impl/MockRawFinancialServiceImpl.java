package com.financial.mockserver.service.impl;

import com.financial.mockserver.dto.ApiEnvelope;
import com.financial.mockserver.dto.BankTransactionListResponse;
import com.financial.mockserver.dto.BankTransactionResponse;
import com.financial.mockserver.dto.CardApprovalListResponse;
import com.financial.mockserver.dto.CardApprovalResponse;
import com.financial.mockserver.dto.CardListResponse;
import com.financial.mockserver.dto.CardResponse;
import com.financial.mockserver.mapper.MockRawFinancialMapper;
import com.financial.mockserver.service.MockRawFinancialService;
import com.financial.mockserver.support.MockApiResult;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class MockRawFinancialServiceImpl extends AbstractMockApiService implements MockRawFinancialService {

    private static final String BANK_TRANSACTIONS_PATH = "/api/v1/accounts/{accountId}/transactions";
    private static final String CARDS_PATH = "/api/v1/cards";
    private static final String CARD_APPROVALS_PATH = "/api/v1/cards/{cardId}/approvals";

    @Autowired
    private MockRawFinancialMapper rawFinancialMapper;

    @Override
    public MockApiResult getBankTransactions(
            String scenarioKey,
            String scenarioOverride,
            Long accountId,
            String yearMonth) {
        String requestJson = buildRequestJson("accountId", accountId, "yearMonth", yearMonth);
        return respond("GET", BANK_TRANSACTIONS_PATH, scenarioKey, scenarioOverride, requestJson,
                (ctx, traceId, timestamp) -> {
                    List<BankTransactionResponse> transactions =
                            rawFinancialMapper.findBankTransactions(ctx.getUser().getId(), accountId, yearMonth);
                    BankTransactionListResponse data = new BankTransactionListResponse(transactions);
                    return ApiEnvelope.of("SUCCESS", "은행 입출금 내역 조회 성공", data, traceId, timestamp);
                });
    }

    @Override
    public MockApiResult getCards(String scenarioKey, String scenarioOverride) {
        return respond("GET", CARDS_PATH, scenarioKey, scenarioOverride, null,
                (ctx, traceId, timestamp) -> {
                    List<CardResponse> cards = rawFinancialMapper.findCards(ctx.getUser().getId());
                    CardListResponse data = new CardListResponse(cards);
                    return ApiEnvelope.of("SUCCESS", "카드 목록 조회 성공", data, traceId, timestamp);
                });
    }

    @Override
    public MockApiResult getCardApprovals(
            String scenarioKey,
            String scenarioOverride,
            Long cardId,
            String yearMonth) {
        String requestJson = buildRequestJson("cardId", cardId, "yearMonth", yearMonth);
        return respond("GET", CARD_APPROVALS_PATH, scenarioKey, scenarioOverride, requestJson,
                (ctx, traceId, timestamp) -> {
                    List<CardApprovalResponse> approvals =
                            rawFinancialMapper.findCardApprovals(ctx.getUser().getId(), cardId, yearMonth);
                    CardApprovalListResponse data = new CardApprovalListResponse(approvals);
                    return ApiEnvelope.of("SUCCESS", "카드 승인 내역 조회 성공", data, traceId, timestamp);
                });
    }
}
