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
            sh "terraform init -input=false"
            sh "terraform plan -out=tfplan -input=false "
            sh "terraform apply -input=false tfplan"
            
        }
      }
   }
}
