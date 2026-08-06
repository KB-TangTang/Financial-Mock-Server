package com.financial.mockserver.config;

import org.apache.ibatis.builder.xml.XMLMapperEntityResolver;
import org.apache.ibatis.parsing.XPathParser;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.fail;

/**
 * mapper/*.xml 이 XML 로서 파싱되는지 검사한다.
 *
 * SQL 의 부등호(`<`, `<=`)나 `&` 를 그대로 쓰면 XML 파서가 태그 시작으로 읽어 깨진다.
 * 이때 sqlSessionFactory 빈 생성이 실패해 **컨텍스트가 통째로 뜨지 않는다** —
 * 컴파일도 되고 테스트도 통과하는데 배포된 톰캣만 죽으므로 발견이 늦다.
 * 실제로 2026-08-06 배포에서 `AND t.transacted_at <= CURRENT_TIMESTAMP` 한 줄로
 * 목서버 전체가 기동하지 못했다.
 *
 * 부등호가 필요하면 `&lt;` 로 쓰거나 <![CDATA[ ... ]]> 로 감싼다.
 */
class MapperXmlWellFormedTest {

    @Test
    void everyMapperXmlIsWellFormed() throws Exception {
        List<Path> mappers = mapperFiles();
        assertFalse(mappers.isEmpty(), "매퍼 XML 을 한 개도 찾지 못했다. 경로 규칙이 바뀌었는지 확인할 것");

        for (Path mapper : mappers) {
            try (InputStream in = Files.newInputStream(mapper)) {
                // RootConfig 의 sqlSessionFactory 가 매퍼를 읽을 때 거치는 것과 같은 파서다.
                new XPathParser(in, true, null, new XMLMapperEntityResolver());
            } catch (Exception e) {
                fail(mapper.getFileName() + " 파싱 실패 — SQL 안의 <, & 를 이스케이프했는지 확인할 것: "
                        + rootMessage(e));
            }
        }
    }

    private List<Path> mapperFiles() throws IOException, Exception {
        URL mapperDir = getClass().getClassLoader().getResource("mapper");
        if (mapperDir == null) {
            throw new IllegalStateException("classpath 에 mapper 디렉터리가 없다");
        }
        try (Stream<Path> paths = Files.list(Path.of(mapperDir.toURI()))) {
            return paths.filter(path -> path.getFileName().toString().endsWith(".xml"))
                    .sorted()
                    .collect(Collectors.toList());
        }
    }

    private String rootMessage(Throwable e) {
        Throwable cause = e;
        while (cause.getCause() != null) {
            cause = cause.getCause();
        }
        return cause.getMessage();
    }
}
