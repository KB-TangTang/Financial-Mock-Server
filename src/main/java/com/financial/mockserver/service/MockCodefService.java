package com.financial.mockserver.service;

import com.financial.mockserver.support.MockApiResult;

/**
 * CODEF 잔액 응답 목 API(POST /codef/v1/account/balance)를 담당한다.
 */
public interface MockCodefService {

    MockApiResult getBalance(String scenarioKey, String account, String scenarioOverride);
}
