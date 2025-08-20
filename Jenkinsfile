pipeline {
  agent any

  environment {
    GIT_REPO_URL    = 'https://github.com/Naushad101/zap-Integration.git'
    DOCKER_USERNAME = 'Naushad101'

    // Global scan variables
    TARGET_URL = "${params.TARGET_URL}"
    SCAN_TYPE  = "${params.SCAN_TYPE}"
    REPORT_DIR = "zap-reports"
    REPORT_NAME = "zap_report_${params.SCAN_TYPE}.html"
  }

  parameters {
    choice(
      name: 'SCAN_TYPE',
      choices: ['passive', 'active'],
      description: 'Choose scan type'
    )
    string(
      name: 'TARGET_URL',
      defaultValue: 'http://spring-boot-hello-world:8081',
      description: 'Target URL to scan'
    )
  }

  stages {

    stage('Checkout') {
      steps {
        git credentialsId: 'github-creads',
            url: env.GIT_REPO_URL,
            branch: 'main'
        sh 'git branch'
      }
    }

    stage('Set Permissions & Verify Tools') {
      steps {
        sh 'chmod +x ./gradlew'
        sh 'java -version'
      }
    }

    stage('Build Backend') {
      steps {
        sh './gradlew clean build -x test'
      }
      post {
        success {
          archiveArtifacts artifacts: 'build/libs/*.jar', fingerprint: true
        }
      }
    }

    stage('Start Services') {
      steps {
        sh 'docker-compose -f docker-compose.yaml up -d spring-boot-app zap'
      }
    }

    stage('Wait for ZAP') {
      steps {
        script {
          def maxRetries = 10
          def count = 0
          def zapReady = false
          while (count < maxRetries && !zapReady) {
            def status = sh(script: "curl -s -o /dev/null -w '%{http_code}' http://zap:8090", returnStdout: true).trim()
            if (status == '200') {
              zapReady = true
            } else {
              count++
              sleep(time: 10, unit: 'SECONDS')
            }
          }
          if (!zapReady) {
            error 'ZAP did not become ready in time!'
          }
        }
      }
    }

    stage('Run ZAP Scan') {
      steps {
        sh "mkdir -p ${env.REPORT_DIR} && chmod 777 ${env.REPORT_DIR}"

        script {
          if (env.SCAN_TYPE == 'passive') {
            sh """
              docker run --rm --network=jenkins-network -u root \
              -v \$(pwd)/${env.REPORT_DIR}:/zap/wrk \
              -t ghcr.io/zaproxy/zaproxy:stable \
              zap-baseline.py -t ${env.TARGET_URL} -r ${env.REPORT_NAME} --autooff
            """
          } else if (env.SCAN_TYPE == 'active') {
            sh """
              docker run --rm --network=jenkins-network -u root \
              -v \$(pwd)/${env.REPORT_DIR}:/zap/wrk \
              -t ghcr.io/zaproxy/zaproxy:stable \
              zap-full-scan.py -t ${env.TARGET_URL} -r ${env.REPORT_NAME}
            """
          }
        }
      }
    }

    stage('Archive Reports') {
      steps {
        archiveArtifacts artifacts: "${env.REPORT_DIR}/${env.REPORT_NAME}", allowEmptyArchive: false
      }
    }
  }

  post {
    always {
      echo 'Cleaning up...'
      sh 'docker-compose -f docker-compose.yaml down'
    }
  }
}
