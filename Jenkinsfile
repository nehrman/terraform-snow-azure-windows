pipeline {

    agent {
        docker {
            image 'alpine:latest'
            args '-v $HOME/tf:root/tf'
        }
    }

    environment {
        TF_TOKEN = ""
        TF_URL = "https://app.terraform.io/v2/"
    } 
    
    stages {
        stage('Preparing Environment') {

            steps {
                sh '''
                apk update && apk upgrade
                apk add git curl gunzip
                '''                
            }

        }

        stage('Preparing Terraform Enterprise Workspace') {
                
            steps {
                sh 'echo "Hello"'
            }
        
        }

        stage('Launching Terraform Plan') {

            steps {
                sh 'echo "Hello"'
            }

        }
        
        stage('Launching Terraform Apply') {

            steps {
                sh 'echo "Hello"'
            }

        }

    }

}