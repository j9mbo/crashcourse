pipeline {
  agent {
    label 'ubuntu'
  }
    environment {
SVC_ACCOUNT_KEY = credentials('terraform-auth')
    }
   stages {
      stage('terraform init') {
        steps {
            sh 'echo $SVC_ACCOUNT_KEY | base64 -d > keys.json'
            sh "terraform init"
            sh "terraform plan"
            
        }
      }
   }
}
