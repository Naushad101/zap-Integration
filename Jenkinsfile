pipeline {
  agent any

  environment {
    GIT_REPO_URL = 'https://github.com/Naushad101/zap-Integration.git'
    DOCKER_USERNAME = 'Naushad101'

    // Environment variables passed into zap_scan.sh
    APP_URL     = "http://spring-boot-app:8081"
    ZAP_URL     = "http://localhost:8090"
    OPENAPI_URL = "http://spring-boot-app:8081/v3/api-docs"
    REPORTS_DIR = "zap_reports"
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
        sh 'chmod +x ./zap_scan.sh'
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

    stage('Wait for ZAP Ready') {
      steps {
        script {
          sh "sleep 60"
          def maxRetries = 10
          def count = 0
          def zapReady = false
          while (count < maxRetries && !zapReady) {
            def status = sh(script: "curl -s -o /dev/null -w '%{http_code}' ${env.ZAP_URL}", returnStdout: true).trim()
            echo "ZAP check attempt ${count + 1}: HTTP $status"
            if (status == '200') {
              zapReady = true
              echo "ZAP is running and healthy"
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

    stage('Run ZAP Security Scan') {
      steps {
        sh "./zap_scan.sh" 
      }
    }

    stage('Archive Reports') {
      steps {
        archiveArtifacts artifacts: "${env.REPORTS_DIR}/*", allowEmptyArchive: false
      }
    }
  }

  post {
    always {
      echo 'Cleaning up...'
      sh 'docker-compose -f docker-compose.yaml down zap'
    }
  }
}
