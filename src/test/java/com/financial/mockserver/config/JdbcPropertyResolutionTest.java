package com.financial.mockserver.config;

import org.junit.jupiter.api.Test;
import org.springframework.core.env.StandardEnvironment;
import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.support.ResourcePropertySource;

import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * application.properties 의 jdbc.* 가
 *  - 환경변수(또는 시스템 프로퍼티)가 없으면 로컬 기본값으로,
 *  - 있으면 그 값으로 해석되는지 검증한다.
 *
 * 컨테이너에서 DB 주소를 바꾸려면 이 해석이 동작해야 한다.
 * (RootConfig 의 @Value 도 같은 Environment 를 거쳐 풀린다)
 */
class JdbcPropertyResolutionTest {

    @Test
    void jdbcProperties_fallBackToLocalDefaults_whenNoOverride() throws Exception {
        StandardEnvironment env = environmentWithApplicationProperties();

        assertEquals("net.sf.log4jdbc.sql.jdbcapi.DriverSpy", env.getProperty("jdbc.driver"));
        assertEquals("jdbc:log4jdbc:mysql://localhost:3306/financial_mock", env.getProperty("jdbc.url"));
        assertEquals("root", env.getProperty("jdbc.username"));
        assertEquals("1234", env.getProperty("jdbc.password"));
    }

    @Test
    void jdbcProperties_areOverriddenByExternalConfig() throws Exception {
        System.setProperty("JDBC_URL", "jdbc:log4jdbc:mysql://db:3306/financial_mock");
        System.setProperty("JDBC_PASSWORD", "from-env");
        try {
            StandardEnvironment env = environmentWithApplicationProperties();

            assertEquals("jdbc:log4jdbc:mysql://db:3306/financial_mock", env.getProperty("jdbc.url"));
            assertEquals("from-env", env.getProperty("jdbc.password"));
            // 주입하지 않은 값은 그대로 기본값
            assertEquals("root", env.getProperty("jdbc.username"));
        } finally {
            System.clearProperty("JDBC_URL");
            System.clearProperty("JDBC_PASSWORD");
        }
    }

    private StandardEnvironment environmentWithApplicationProperties() throws Exception {
        StandardEnvironment env = new StandardEnvironment();
        env.getPropertySources().addLast(
                new ResourcePropertySource(new ClassPathResource("application.properties")));
        return env;
    }
}
