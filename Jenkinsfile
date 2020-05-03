pipeline {
  agent {
    label 'ubuntu'
  }
   environment {

        SVC_ACCOUNT_KEY = credentials('terraform-auth')
               }
   stages {
      stage('terraform') {
        steps {
            sh 'echo $SVC_ACCOUNT_KEY | base64 -d > keys.json'
            sh "terraform init"
            sh "terraform plan"
            sh "terraform apply -auto-approve"
        }
      }
      stage('ansible') {
        steps { 
          
        
        }
      }
   }
      post {
     
        success {
            sh 'curl -s -X POST https://api.telegram.org/bot1170047758:AAEiBItYQUnpvYgAyPNGVIHL_MIcUQU7BKU/sendMessage -d chat_id="-458684504" -d text="the job succeeded"'
        }
     
        failure {
            sh 'curl -s -X POST https://api.telegram.org/bot1170047758:AAEiBItYQUnpvYgAyPNGVIHL_MIcUQU7BKU/sendMessage -d chat_id="-458684504" -d text="the job is failed"'
        }
  
    }

}
