package com.financial.mockserver.service;

import com.financial.mockserver.support.MockApiResult;

public interface MockRawFinancialService {
    MockApiResult getBankTransactions(
            String scenarioKey,
            String scenarioOverride,
            Long accountId,
            String yearMonth);

    MockApiResult getCards(String scenarioKey, String scenarioOverride);

    MockApiResult getCardApprovals(
            String scenarioKey,
            String scenarioOverride,
            Long cardId,
            String yearMonth);
}
