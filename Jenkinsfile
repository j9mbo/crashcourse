pipeline {
  agent {
    label 'ubuntu'
  }
   stages {
      stage('terraform init') {
         steps 
            sh "terraform init"
            sh "terraform plan"
         
      }
   }
}
