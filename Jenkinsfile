pipeline {
  agent {
    label 'ubuntu'
  }
   stages {
      stage('terraform init') {
        steps {
            sh "terraform init -input=false"
            sh "terraform plan -out=tfplan -input=false "
            sh "terraform apply -input=false tfplan"
            sh "terraform destroy -input=false"
            
        }
      }
   }
}
