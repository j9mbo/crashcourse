pipeline {
  agent {
    label 'ubuntu'
  }
    environment {
credentials = "${JSON}"
    }
   stages {
      stage('terraform init') {
        steps {
            sh "terraform init"
            sh "terraform plan"
            sh "terraform apply"
        }
      }
   }
}
