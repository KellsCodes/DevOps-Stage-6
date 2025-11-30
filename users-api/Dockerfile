# Stage 1 - Build the application
FROM maven:3.9.6-eclipse-temurin-11 AS builder
WORKDIR /app
COPY pom.xml .
RUN mvn -q -e -B dependency:go-offline
COPY src ./src
RUN mvn -q -e -B package -DskipTests

# Stage 2 - Download JAXB JARs from Maven Central
FROM alpine:latest AS jaxb-downloader
RUN apk add --no-cache wget
WORKDIR /jaxb/libs
RUN wget -q https://repo1.maven.org/maven2/javax/xml/bind/jaxb-api/2.3.1/jaxb-api-2.3.1.jar && \
    wget -q https://repo1.maven.org/maven2/org/glassfish/jaxb/jaxb-runtime/2.3.1/jaxb-runtime-2.3.1.jar && \
    wget -q https://repo1.maven.org/maven2/javax/activation/javax.activation-api/1.2.0/javax.activation-api-1.2.0.jar && \
    wget -q https://repo1.maven.org/maven2/org/glassfish/jaxb/txw2/2.3.1/txw2-2.3.1.jar && \
    wget -q https://repo1.maven.org/maven2/com/sun/istack/istack-commons-runtime/3.0.7/istack-commons-runtime-3.0.7.jar

# Stage 3 - Create the runtime image
FROM eclipse-temurin:11-jre-alpine
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar
COPY --from=jaxb-downloader /jaxb/libs/*.jar /app/libs/

EXPOSE 8083
ENTRYPOINT ["java", \
  "-cp", "/app/app.jar:/app/libs/*", \
  "-Dloader.path=/app/libs", \
  "org.springframework.boot.loader.JarLauncher"]
