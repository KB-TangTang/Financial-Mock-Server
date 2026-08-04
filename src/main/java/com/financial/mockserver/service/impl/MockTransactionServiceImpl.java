package com.financial.mockserver.service.impl;

import com.financial.mockserver.dto.ApiEnvelope;
import com.financial.mockserver.dto.TransactionListResponse;
import com.financial.mockserver.dto.TransactionResponse;
import com.financial.mockserver.mapper.MockTransactionMapper;
import com.financial.mockserver.service.MockTransactionService;
import com.financial.mockserver.support.MockApiResult;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class MockTransactionServiceImpl extends AbstractMockApiService implements MockTransactionService {

    @Autowired
    private MockTransactionMapper transactionMapper;

    @Override
    public MockApiResult getTransactions(String scenarioKey, String scenarioOverride, String yearMonth) {
        String requestJson = buildRequestJson("yearMonth", yearMonth);
        return respond("GET", "/api/v1/transactions", scenarioKey, scenarioOverride, requestJson,
                (ctx, traceId, timestamp) -> {
                    List<TransactionResponse> transactions =
                            transactionMapper.findTransactions(ctx.getUser().getId(), yearMonth);
                    TransactionListResponse data = new TransactionListResponse(transactions);
                    return ApiEnvelope.of("SUCCESS", "거래내역 조회 성공", data, traceId, timestamp);
                });
    }
}
