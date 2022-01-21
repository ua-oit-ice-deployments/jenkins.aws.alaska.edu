FROM jenkins/jenkins:lts-jdk11

COPY plugins /usr/share/jenkins/plugin-list
COPY jenkins.casc.yaml /usr/share/jenkins/jenkins.casc.yaml

ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false
ENV CASC_JENKINS_CONFIG /usr/share/jenkins/jenkins.casc.yaml

RUN jenkins-plugin-cli --verbose --plugins $(cat /usr/share/jenkins/plugin-list)
