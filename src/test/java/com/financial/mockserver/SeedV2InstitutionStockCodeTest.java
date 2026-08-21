package com.financial.mockserver;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.assertTrue;

class SeedV2InstitutionStockCodeTest {

    private static final Path SEED_PATH = Path.of("src/main/resources/db/seed-v2.sql");

    @Test
    void securitiesSeed_usesListedStockCodeForEachSecuritiesInstitution() throws IOException {
        String seed = Files.readString(SEED_PATH, StandardCharsets.UTF_8);

        assertTrue(seed.contains("SELECT id, '016360', '삼성증권'"));
        assertTrue(seed.contains("WHERE account_no_masked = '987654******3210'"));
        assertTrue(seed.contains("SELECT '551122******0011' AS account_no_masked, '071050' AS product_code, '한국금융지주' AS product_name"));
        assertTrue(seed.contains("UNION ALL SELECT '662233******0022', '005940', 'NH투자증권'"));
        assertTrue(seed.contains("UNION ALL SELECT '773344******0033', '030610', '교보증권'"));
    }

}
