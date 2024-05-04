FROM maven:3.6.3-jdk-8-slim AS build
WORKDIR /home/app/
COPY . /home/app/
RUN mvn -f /home/app/pom.xml clean install package
FROM tomcat:9.0
COPY  --from=build /home/app/target/sample.war /usr/local/tomcat/webapps/sample.war
