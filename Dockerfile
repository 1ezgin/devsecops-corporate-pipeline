FROM maven:3.9.6-eclipse-temurin-17 AS builder

WORKDIR /app

COPY pom.xml .

RUN mvn dependency:go-offline -B

COPY src /app/src

RUN mvn clean package -DskipTests=true

FROM eclipse-temurin:17-jre-alpine

EXPOSE 8080

LABEL maintainer="1ezgin"

WORKDIR /opt/app

COPY --from=builder /app/target/spring-petclinic-4.0.0-SNAPSHOT.jar app.jar

ENTRYPOINT ["java", "-jar", "app.jar"]

