pipeline {
  agent {
    label 'ubuntu'
  }
   stages {
      stage('terraform init') {
        steps {
            sh "terraform init -input=false"
            sh "export AWS_ACCESS_KEY_ID=$AWSAccessKeyId"
            sh "export AWS_SECRET_ACCESS_KEY=$AWSSecretKey"
            sh "export AWS_DEFAULT_REGION=us-west-2"
            sh "terraform plan -out=tfplan -input=false "
            sh "terraform apply -input=false tfplan"
            
        }
      }
   }
}
