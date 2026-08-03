package com.financial.mockserver.service;

import com.financial.mockserver.support.MockApiResult;

/**
 * 은행/증권/대출/페이머니 자산 조회 API를 담당한다.
 */
public interface MockAssetService {

    MockApiResult getBankAccounts(String scenarioKey, String scenarioOverride);

    MockApiResult getStocks(String scenarioKey, String scenarioOverride);

    MockApiResult getLoans(String scenarioKey, String scenarioOverride);

    MockApiResult getPayMoney(String scenarioKey, String scenarioOverride);
}
