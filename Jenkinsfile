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
            sh 'echo $SVC_ACCOUNT_KEY | base64 -d > keys.json'
            sh 'echo $CERTIFICATE | base64 -d > cert.pem'
            sh 'echo $CERTIFICATE_PRIV_KEY | base64 -d > privkey.pem'
            sh "terraform init"
            sh "terraform plan"
            sh "terraform apply -auto-approve"
        }
      }
      stage('ansible') {
        steps { 
          sh "echo waiting for ansible"
        
        }
      }
   }
      post {
     
        success {
            sh 'curl -s -X POST https://api.telegram.org/bot1170047758:AAEiBItYQUnpvYgAyPNGVIHL_MIcUQU7BKU/sendMessage -d chat_id="-458684504" -d text="the job is successful"'
        }
     
        failure {
            sh 'curl -s -X POST https://api.telegram.org/bot1170047758:AAEiBItYQUnpvYgAyPNGVIHL_MIcUQU7BKU/sendMessage -d chat_id="-458684504" -d text="the job is failed"'
        }
  
    }

}
