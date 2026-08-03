package com.financial.mockserver.controller;

import com.financial.mockserver.dto.ApiEnvelope;
import com.financial.mockserver.support.MockResponseSupport;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * scenarioKey/fixture로 시뮬레이션하는 의도된 오류(401/404/429/502/503)와 달리,
 * DB 장애 등 예상치 못한 런타임 예외가 발생했을 때도
 * README.md/IMPLEMENTATION_GUIDE.md가 정한 공통 envelope 형태로 응답하기 위한 전역 처리기.
 */
@RestControllerAdvice(basePackages = "com.financial.mockserver.controller")
public class GlobalExceptionHandler {

    private static final Logger log = LogManager.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiEnvelope<Object>> handleUnexpectedException(Exception ex) {
        String traceId = MockResponseSupport.generateTraceId();
        String timestamp = MockResponseSupport.currentTimestamp();
        log.error("Unhandled exception traceId={}", traceId, ex);

        ApiEnvelope<Object> envelope = ApiEnvelope.of(
                "INTERNAL_ERROR",
                "서버 처리 중 오류가 발생했습니다",
                null,
                traceId,
                timestamp);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(envelope);
    }
}
