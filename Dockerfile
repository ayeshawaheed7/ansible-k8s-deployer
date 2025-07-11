FROM eclipse-temurin:17-jdk-alpine

EXPOSE 8080

WORKDIR /home/app

RUN apt-get update & apt-get install -y --no-install-recommends & groupadd -r appgroup & useradd -r -g appgroup appuser & rm -rf /var/lib/apt/lists/*

COPY --chown=appuser:appgroup build/libs/my-app-*.jar /home/app/app.jar

USER appuser

CMD ["java", "-jar", "app.jar"]