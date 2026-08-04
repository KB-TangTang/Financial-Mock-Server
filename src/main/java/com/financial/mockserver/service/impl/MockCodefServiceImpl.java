package com.financial.mockserver.service.impl;

import com.financial.mockserver.dto.ApiEnvelope;
import com.financial.mockserver.dto.CodefBalanceResponse;
import com.financial.mockserver.mapper.MockAssetMapper;
import com.financial.mockserver.service.MockCodefService;
import com.financial.mockserver.support.MockApiResult;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;

@Service
public class MockCodefServiceImpl extends AbstractMockApiService implements MockCodefService {

    @Autowired
    private MockAssetMapper assetMapper;

    @Override
    public MockApiResult getBalance(String scenarioKey, String account, String scenarioOverride) {
        String requestJson = buildRequestJson("account", account);
        return respond("POST", "/codef/v1/account/balance", scenarioKey, scenarioOverride, requestJson,
                (ctx, traceId, timestamp) -> {
                    Long userId = ctx.getUser().getId();
                    Long accountId = resolveTargetAccountId(userId, account);

                    CodefBalanceResponse data = (accountId == null)
                            ? emptyBalance()
                            : assetMapper.findLatestBalance(accountId);
                    if (data == null) {
                        data = emptyBalance();
                        data.setAccountId(accountId);
                    }
                    return ApiEnvelope.of("SUCCESS", "잔액 조회 성공", data, traceId, timestamp);
                });
    }

    private Long resolveTargetAccountId(Long userId, String account) {
        if (account != null && !account.trim().isEmpty()) {
            Long matched = assetMapper.findAccountIdByMaskedNo(userId, account.trim());
            if (matched != null) {
                return matched;
            }
        }
        return assetMapper.findFirstDepositAccountId(userId);
    }

    private CodefBalanceResponse emptyBalance() {
        CodefBalanceResponse response = new CodefBalanceResponse();
        response.setBalance(BigDecimal.ZERO);
        response.setAvailableAmount(BigDecimal.ZERO);
        response.setValuationAmount(BigDecimal.ZERO);
        response.setCurrency("KRW");
        return response;
    }
}
