# Stage 1: Build the Java app
FROM maven:3.9.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: Run the app
FROM eclipse-temurin:17-jdk-alpine
WORKDIR /app
COPY --from=build /app/target/java-sample-1.0.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]
