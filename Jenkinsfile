pipeline {

  agent{
    label 'linux'
  }

  stages {
    stage("build") {
      steps {
        echo "Build Successful."
      }
    }

    stage("test") {
      steps {
        echo "Test Successful."
      }
    }

    stage("deploy") {

      environment{
        AWS_ACCESS_KEY_ID=credentials('aws_access_key_id')
        AWS_SECRET_ACCESS_KEY=credentials('aws_secret_access_key')
      }

      steps {
        echo "Deploying ..."

        sh 'echo ${AWS_ACCESS_KEY_ID}'
        sh 'echo ${AWS_SECRET_ACCESS_KEY}'

        sh 'chmod +x deploy.sh'
        sh './deploy.sh'
        
        echo "Deployment Successful."
      }
    }

  }
}