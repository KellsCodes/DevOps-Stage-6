# Stage 1 - Build the application
FROM maven:3.9.6-eclipse-temurin-17 AS builder

WORKDIR /app

COPY pom.xml .

RUN mvn -q -e -B dependency:go-offline

COPY src ./src

RUN mvn -q -e -B package -DskipTests

# Stage 2 - Create the runtime image
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

COPY --from=builder /app/target/*.jar app.jar

EXPOSE 8083

ENTRYPOINT ["java", "-jar", "app.jar"]
