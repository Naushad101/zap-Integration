pipeline {
  agent any

  environment {
    GIT_REPO_URL    = 'https://github.com/Naushad101/zap-Integration.git'
    DOCKER_USERNAME = 'Naushad101'
    REPORT_NAME     = "zap_security_report.html"
    TARGET_URL      = "http://spring-boot-hello-world:8081"
    REPORT_DIR      = "zap_reports"
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
          def maxRetries = 15
          def count = 0
          def zapReady = false

          while (count < maxRetries && !zapReady) {
            def response = sh(
              script: "curl -s http://zap:8090/JSON/core/view/version/",
              returnStdout: true
            ).trim()

            if (response && response.contains("version")) {
              zapReady = true
              echo "✅ ZAP is ready! Version: ${response}"
            } else {
              count++
              echo "⏳ Waiting for ZAP to be ready... Attempt ${count}/${maxRetries}"
              sleep(time: 10, unit: 'SECONDS')
            }
          }

          if (!zapReady) {
            error '❌ ZAP did not become ready in time!'
          }
        }
      }
    }

    stage('Run ZAP Active Scan') {
      steps {
        script {
          sh "mkdir -p ${env.REPORT_DIR} && chmod 777 ${env.REPORT_DIR}"

          try {
            sh """
              docker exec -u root zap \
              zap-full-scan.py -t ${env.TARGET_URL} -r /zap/wrk/${env.REPORT_NAME}
            """
          } catch (Exception e) {
            currentBuild.result = 'UNSTABLE'
            echo "⚠️ ZAP scan failed: ${e.message}"
          }
        }
      }
      post {
        always {
          echo "Archiving ZAP reports..."
          archiveArtifacts artifacts: "${env.REPORT_DIR}/${env.REPORT_NAME}", allowEmptyArchive: true
        }
      }
    }
  }

  post {
    always {
      echo 'Cleaning up...'
      // Uncomment if you want services down after pipeline
      // sh 'docker-compose -f docker-compose.yaml down'
    }
  }
}
