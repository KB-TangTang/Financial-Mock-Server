package com.financial.mockserver.support;

import com.financial.mockserver.dto.ApiEnvelope;

import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.UUID;

/**
 * 응답 envelope에 필요한 traceId/timestamp 생성 유틸리티.
 * README.md의 응답 원칙(공통 envelope, KST timestamp)을 따른다.
 */
public final class MockResponseSupport {

    private static final ZoneId KST = ZoneId.of("Asia/Seoul");

    private MockResponseSupport() {
    }

    public static String generateTraceId() {
        return "MOCK-" + UUID.randomUUID().toString().replace("-", "").toUpperCase().substring(0, 20);
    }

    public static String currentTimestamp() {
        return ZonedDateTime.now(KST).format(DateTimeFormatter.ISO_OFFSET_DATE_TIME);
    }

    public static String firstNonBlank(String... values) {
        for (String value : values) {
            if (value != null && !value.trim().isEmpty()) {
                return value;
            }
        }
        return null;
    }

    /**
     * documents/IMPLEMENTATION_GUIDE.md "응답 규칙"에 정의된 404 NOT_FOUND envelope.
     * 매칭되는 fixture가 없거나 scenarioKey로 사용자를 찾을 수 없을 때 사용한다.
     */
    public static ApiEnvelope<Object> notFoundEnvelope(String traceId, String timestamp) {
        return ApiEnvelope.of("NOT_FOUND", "매칭되는 목 응답이 없습니다", null, traceId, timestamp);
    }
}
