pipeline {
  agent {
    label 'ubuntu'
  }
   environment {
        CERTIFICATE = credentials('certificate')
        CERTIFICATE_PRIV_KEY = credentials('certificate-privkey')
        SVC_ACCOUNT_KEY = credentials('terraform-auth')
               }
   stages {
      stage('terraform') {
        steps {
       
            sh "terraform destroy -auto-approve"
        }
      }
      stage('ansible') {
        steps { 
          sh "echo you you"
        
        }
      }
   }
     

}
