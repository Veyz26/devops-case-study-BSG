FROM eclipse-temurin:17-jre
WORKDIR /app
COPY target/payment-app-1.0.0-jar-with-dependencies.jar /app/payment-app.jar
EXPOSE 80
ENTRYPOINT ["java","-jar","/app/payment-app.jar"]
