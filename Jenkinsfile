pipeline {

    agent {
        docker {
            image 'alpine:latest'
        }
    }

    environment {
        TF_TOKEN = ""
        TF_URL = ""
    } 
    
    stages {
        stage('Preparing Environment') {
            agent {
                docker {
                    reuseNode true
                }
            }
            steps {
                apk update && apk upgrade
                apk add git curl gunzip                
            }
        }

    stages {
        stage('Preparing Terraform Enterprise Workspace') {
            agent {
                docker {
                    reuseNode true
                }
                
            steps {

            }
        }

        stage('Launching Terraform Plan') {
            steps {

            }
        }
        
        stage('Launching Terraform Apply') {
            steps {

            }
        }

    }

}