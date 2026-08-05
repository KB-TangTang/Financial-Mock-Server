package com.financial.mockserver.service;

import com.financial.mockserver.support.MockApiResult;

public interface MockRawFinancialService {
    MockApiResult getBankTransactions(
            String scenarioKey,
            String scenarioOverride,
            Long accountId,
            String yearMonth);

    MockApiResult getDepositTransactions(
            String scenarioKey,
            String scenarioOverride,
            Long depositAccountId,
            String yearMonth);

    MockApiResult getLoanTransactions(
            String scenarioKey,
            String scenarioOverride,
            Long loanId,
            String yearMonth);

    MockApiResult getSecuritiesTransactions(
            String scenarioKey,
            String scenarioOverride,
            Long accountId,
            String yearMonth);

    MockApiResult getPayMoneyTransactions(
            String scenarioKey,
            String scenarioOverride,
            Long payMoneyId,
            String yearMonth);

    MockApiResult getCards(String scenarioKey, String scenarioOverride);

    MockApiResult getCardApprovals(
            String scenarioKey,
            String scenarioOverride,
            Long cardId,
            String yearMonth);

    MockApiResult getCardBills(
            String scenarioKey,
            String scenarioOverride,
            Long cardId,
            String billingMonth);
}
