FROM eclipse-temurin:17-jdk-alpine

EXPOSE 8080

WORKDIR /home/app

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

COPY --chown=appuser:appgroup build/libs/my-app-*.jar /home/app/app.jar

USER appuser

CMD ["java", "-jar", "app.jar"]