# Etapa 1: Build con Maven y Java 17
FROM maven:3.9.9-eclipse-temurin-17 AS builder
WORKDIR /build
# Copiar pom.xml primero para cachear dependencias
COPY pom.xml .
RUN mvn dependency:go-offline -B
# Copiar el resto del código
COPY src ./src
# Empaquetar la aplicación (saltar tests para agilizar)
RUN mvn clean package -DskipTests

# Etapa 2: Runtime con JRE slim
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
# Crear usuario no root
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring
# Copiar el JAR desde el builder
COPY --from=builder /build/target/*.jar app.jar
# Exponer puerto de Despachos (8081 según application.properties)
EXPOSE 8081
# Comando de entrada
ENTRYPOINT ["java", "-jar", "app.jar"]