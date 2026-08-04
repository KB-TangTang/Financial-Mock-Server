package com.financial.mockserver.service;

import com.financial.mockserver.support.MockApiResult;

/**
 * 은행·증권·대출·페이머니 통합 거래내역 조회를 담당한다.
 * fixture를 사용하지 않고 항상 업권별 원천 거래 테이블을 조회해 조립한다.
 */
public interface MockTransactionService {

    MockApiResult getTransactions(String scenarioKey, String scenarioOverride, String yearMonth);
}
