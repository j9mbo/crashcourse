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
            sh "sleep 5"
           
        }
      }
      stage('ansible') {
        steps { 
          sh "gcloud compute instances list --format='table(EXTERNAL_IP)' > hosts"
          sh "echo "$(tail -n +2 hosts)" > hosts"
          sh "ansible-playbook -u vital playbook.yml"
        
        }
      }
   }
     

}
