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
            sh "sleep 20"
           
        }
      }
      stage('ansible') {
        steps { 
          sh "gcloud compute instances list --format='table(EXTERNAL_IP)' > ip.txt"
          sh "sed 1d ip.txt > hosts"
          sh "ansible-playbook -u vital playbook.yml"
        
        }
      }
   }
     

}
