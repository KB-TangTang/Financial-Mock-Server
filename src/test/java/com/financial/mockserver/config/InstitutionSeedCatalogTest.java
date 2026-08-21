package com.financial.mockserver.config;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * 앱의 기관 선택 카탈로그에서 쓰는 대출·페이머니 코드가 목서버 시드에도 존재하는지 검증한다.
 * 실제 자산 행은 일부 기관만 보유해도, 기관 목록은 선택 코드와 동일해야 한다.
 */
class InstitutionSeedCatalogTest {

    @Test
    void seedRegistersEveryLoanAndPayMoneyInstitutionUsedByTheApp() throws IOException {
        String seed = seedV2();

        List<String> expectedCodes = List.of(
                "CP_KB", "CP_HYUNDAI", "CP_SHINHAN", "CP_HANA", "CP_WOORI",
                "SB_SBI", "SB_OK", "SB_WELCOME",
                "PAY_KAKAO", "PAY_NAVER", "PAY_TOSS", "PAY_PAYCO", "PAY_KB", "PAY_CPANG");

        for (String code : expectedCodes) {
            assertTrue(seed.contains("'" + code + "'"),
                    "financial_institution 시드에 기관 코드가 없습니다: " + code);
        }
    }

    @Test
    void payMoneyResponsesUseTheInstitutionCodeAsTheirProviderCode() throws IOException {
        assertTrue(mapper("mapper/MockAssetMapper.xml")
                        .contains("i.institution_code AS providerCode"),
                "페이머니 자산 응답은 기관 코드(PAY_KB)를 providerCode로 내려야 합니다.");
        assertTrue(mapper("mapper/MockRawFinancialMapper.xml")
                        .contains("i.institution_code AS providerCode"),
                "페이머니 거래 응답은 기관 코드(PAY_KB)를 providerCode로 내려야 합니다.");
    }

    @Test
    void payMoneySeedUsesInstitutionCodeAndMigratesExistingWalletsBeforeInserting() throws IOException {
        String seed = seedV2();

        assertFalse(seed.contains("'KB_PAY'"),
                "활성 v2 시드에는 별도 provider_code(KB_PAY)가 남아 있으면 안 됩니다.");
        assertTrue(seed.contains("SET p.provider_code = i.institution_code"),
                "기존 페이머니는 신규 시드 삽입 전에 기관 코드로 이관해야 합니다.");
        assertTrue(seed.contains("WHERE provider_code = 'PAY_KB'"),
                "페이머니 거래 시드도 기관 코드로 지갑을 찾아야 합니다.");
    }

    @Test
    void everyLoanSeedReferencesKbCapitalAndUpdatesTheExistingInstitutionReference() throws IOException {
        Matcher loanInserts = Pattern.compile(
                        "INSERT INTO loan_account[\\s\\S]*?ON DUPLICATE KEY UPDATE[\\s\\S]*?updated_at\\s*=\\s*CURRENT_TIMESTAMP;")
                .matcher(seedV2());
        int count = 0;
        while (loanInserts.find()) {
            String insert = loanInserts.group();
            assertTrue(insert.contains("institution_code = 'CP_KB'")
                            || insert.contains("institution_code='CP_KB'"),
                    "대출 시드는 KB캐피탈(CP_KB)을 참조해야 합니다.");
            assertTrue(insert.replaceAll("\\s+", "").contains("institution_id=VALUES(institution_id)"),
                    "재실행 시 기존 대출의 기관 참조도 CP_KB로 갱신해야 합니다.");
            count++;
        }
        assertEquals(3, count, "기존 대출 시드 3건을 모두 검증해야 합니다.");
    }

    private String seedV2() throws IOException {
        try (InputStream input = resource("db/seed-v2.sql")) {
            return new String(input.readAllBytes(), StandardCharsets.UTF_8);
        }
    }

    private String mapper(String path) throws IOException {
        try (InputStream input = resource(path)) {
            return new String(input.readAllBytes(), StandardCharsets.UTF_8);
        }
    }

    private InputStream resource(String path) {
        InputStream input = getClass().getClassLoader().getResourceAsStream(path);
        if (input == null) {
            throw new IllegalStateException(path + "을 찾을 수 없습니다.");
        }
        return input;
    }
}
