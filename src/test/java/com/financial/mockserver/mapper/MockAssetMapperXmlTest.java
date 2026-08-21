package com.financial.mockserver.mapper;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.assertTrue;

class MockAssetMapperXmlTest {

    @Test
    void accountEndpointQueryIncludesSecuritiesAndDepositAccounts() throws IOException {
        String mapper = Files.readString(Path.of("src/main/resources/mapper/MockAssetMapper.xml"));
        int accountQueryStart = mapper.indexOf("<select id=\"findBankAccounts\"");
        int accountQueryEnd = mapper.indexOf("</select>", accountQueryStart);
        String accountQuery = mapper.substring(accountQueryStart, accountQueryEnd);

        assertTrue(accountQuery.contains("FROM securities_account"),
                "연동 단계의 /assets/accounts 응답에는 증권 계좌도 포함해야 한다");
        assertTrue(accountQuery.contains("FROM deposit_account"),
                "연동 단계의 /assets/accounts 응답에는 예적금 계좌도 포함해야 한다");
    }

    @Test
    void stockEndpointQueryIncludesSecuritiesIdentityForConnectionSync() throws IOException {
        String mapper = Files.readString(Path.of("src/main/resources/mapper/MockAssetMapper.xml"));
        int stockQueryStart = mapper.indexOf("<select id=\"findStockAccountSummary\"");
        int stockQueryEnd = mapper.indexOf("</select>", stockQueryStart);
        String stockQuery = mapper.substring(stockQueryStart, stockQueryEnd);

        assertTrue(stockQuery.contains("i.institution_code AS institutionCode"),
                "증권 동기화가 연동 계좌와 같은 기관 키를 만들 수 있어야 한다");
        assertTrue(stockQuery.contains("a.account_no_masked AS accountNoMasked"),
                "증권 동기화가 연동 계좌와 같은 자연키를 만들 수 있어야 한다");
    }
}
