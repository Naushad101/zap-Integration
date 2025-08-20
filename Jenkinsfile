pipeline {
  agent any

  environment {
    GIT_REPO_URL    = 'https://github.com/Naushad101/zap-Integration.git'
    DOCKER_USERNAME = 'Naushad101'
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

    stage('Start Services') {
      steps {
        sh 'docker-compose -f docker-compose-app.yaml up -d spring-boot-app zap'
      }
    }

    stage('Wait for ZAP') {
      steps {
        script {
          def maxRetries = 10
          def count = 0
          def zapReady = false
          while (count < maxRetries && !zapReady) {
            def status = sh(script: "curl -s -o /dev/null -w '%{http_code}' http://localhost:8090", returnStdout: true).trim()
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
        script {
          def targetUrl = params.TARGET_URL
          def scanType = params.SCAN_TYPE
          def reportName = "zap_report.html"

          if (scanType == 'passive') {
            sh """
            docker run --rm -v \$(pwd)/zap-reports:/zap/wrk -t ghcr.io/zaproxy/zaproxy:stable \
              zap-baseline.py -t ${targetUrl} -r ${reportName}
            """
          } else if (scanType == 'active') {
            sh """
            docker run --rm -v \$(pwd)/zap-reports:/zap/wrk -t ghcr.io/zaproxy/zaproxy:stable \
              zap-full-scan.py -t ${targetUrl} -r ${reportName}
            """
          } else {
            error "Invalid SCAN_TYPE: ${scanType}. Use 'active' or 'passive'."
          }
        }
      }
    }

    stage('Archive Reports') {
      steps {
        archiveArtifacts artifacts: 'zap_report.html', allowEmptyArchive: true
      }
    }
  }

  post {
    always {
      echo 'Cleaning up...'
      sh 'docker-compose -f docker-compose-app.yaml down'
    }
  }
}
