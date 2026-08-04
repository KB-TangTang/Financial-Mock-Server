package com.financial.mockserver.dto;

import lombok.Data;

/**
 * POST /codef/v1/account/balance 요청 body.
 *
 * CODEF 실제 API를 모사하는 목 엔드포인트이므로 scenarioKey(대상 사용자)와
 * account(조회할 계좌 마스킹 번호, 선택)를 함께 받는다. account가 없으면
 * 해당 사용자의 첫 번째 은행 계좌(DEMAND_DEPOSIT/SAVINGS)를 기본으로 사용한다.
 */
@Data
public class CodefBalanceRequest {
    private String scenarioKey;
    private String account;
}
