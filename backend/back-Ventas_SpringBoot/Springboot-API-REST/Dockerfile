# Etapa 1: Build con Maven y Java 21
FROM maven:3.9.9-eclipse-temurin-21 AS builder
WORKDIR /build
# Copiar pom.xml primero para cachear dependencias
COPY pom.xml .
RUN mvn dependency:go-offline -B
# Copiar el resto del código
COPY src ./src
# Empaquetar la aplicación (saltar tests para agilizar)
RUN mvn clean package -DskipTests

# Etapa 2: Runtime con JRE slim
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
# Instalar curl para las comprobaciones de salud
RUN apk add --no-cache curl
# Crear usuario no root
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring
# Copiar el JAR desde el builder
COPY --from=builder /build/target/*.jar app.jar
# Exponer puerto de Ventas (8080 según application.properties)
EXPOSE 8080
# Comando de entrada
ENTRYPOINT ["java", "-jar", "app.jar"]