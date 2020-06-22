pipeline {

    agent {
        docker {
            image 'alpine:latest'
        }
    }

    environment {
        TF_TOKEN = ""
        TF_URL = "https://app.terraform.io/v2/"
    } 
    
    stages {
        stage('Preparing Environment') {
            agent {
                docker {
                    reuseNode true
                }
            }
            steps {
                sh '''
                apk update && apk upgrade
                apk add git curl gunzip
                '''                
            }
        }

        stage('Preparing Terraform Enterprise Workspace') {
            agent {
                docker {
                    reuseNode true
                }
                
            steps {
                sh 'echo "Hello"'
            }
        }

        stage('Launching Terraform Plan') {
            agent {
                docker {
                    reuseNode true
                }
            steps {
                sh 'echo "Hello"'
            }
        }
        
        stage('Launching Terraform Apply') {
            agent {
                docker {
                    reuseNode true
                }
            steps {
                sh 'echo "Hello"'
            }
        }

    }

}
