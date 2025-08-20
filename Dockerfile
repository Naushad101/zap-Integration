FROM eclipse-temurin:21-jdk-alpine
MAINTAINER example.com
COPY build/libs/spring-boot-hello-world-0.0.1-SNAPSHOT.jar app.jar
ENTRYPOINT ["java", "-jar", "/app.jar"]