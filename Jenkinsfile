pipeline {
  agent any

  environment {
    GIT_REPO_URL    = 'https://github.com/Naushad101/zap-Integration.git'
    DOCKER_USERNAME = 'Naushad101'

    REPORTS_DIR     = "zap_reports"
    REPORT_NAME     = "security-report.html"
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
        sh 'docker-compose -f docker-compose.yaml up -d'
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
      //sh 'docker-compose -f docker-compose.yaml down'
    }
  }
}
