# Stage 1: Gradle로 WAR 파일 생성
FROM eclipse-temurin:17-jdk AS builder

WORKDIR /workspace

COPY gradlew settings.gradle build.gradle ./
COPY gradle/ gradle/

RUN chmod +x gradlew && ./gradlew dependencies --no-daemon || true

COPY src src
RUN ./gradlew build -x test --no-daemon

# Stage 2: Tomcat 9에 WAR 배포
FROM tomcat:9-jdk17-temurin

RUN rm -rf /usr/local/tomcat/webapps/*

COPY --from=builder /workspace/build/libs/Financial-Mock-Server-1.0-SNAPSHOT.war \
       /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080
CMD ["catalina.sh", "run"]
