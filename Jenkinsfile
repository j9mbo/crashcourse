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
      stage('provisioning required files') {
        steps {
            sh 'echo $SVC_ACCOUNT_KEY | base64 -d > keys.json'
            sh 'echo $CERTIFICATE | base64 -d > cert.pem'
            sh 'echo $CERTIFICATE_PRIV_KEY | base64 -d > privkey.pem'
              }
      }
        stage('terraform') {
          steps { 
            sh "terraform init"
            sh "terraform plan"
            sh "terraform apply -auto-approve"
            sh "sleep 20"
            
        }
      }
      stage('ansible') {
        steps { 
          sh "gcloud compute instances list --format='table(EXTERNAL_IP)' > ip.txt"
          sh "sed -e '1d;3,5d' ip.txt > hosts"
          sh "ansible-playbook -u vital mr.yml"
          sh "sed -e '1d;2d;4d;5d' ip.txt > hosts"
          sh "ansible-playbook -u vital ns.yml"
        
        }
      }
   }
       post {
     
           success {
               sh 'curl -s -X POST https://api.telegram.org/bot1170047758:AAEiBItYQUnpvYgAyPNGVIHL_MIcUQU7BKU/sendMessage -d chat_id="-458684504" -d text="the job is successful https://crashnovi.xyz/"'
        }
     
           failure {
               sh 'curl -s -X POST https://api.telegram.org/bot1170047758:AAEiBItYQUnpvYgAyPNGVIHL_MIcUQU7BKU/sendMessage -d chat_id="-458684504" -d text="the job is failed"'
        }
  
    }
     

}
