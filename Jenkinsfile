pipeline {

    agent {
        docker {
            image 'debian:jessie'
            args '-u root:sudo '
        }
    }

    environment {
        TFE_TOKEN = "RN8ji0WbgyGJwA.atlasv1.LCdlAB2lRjYjCh9IMwIaqHkyy4Kwz3veuzbENTHU78NcfQmgfmYnNJn6MWV4dTMzFpU"
        TFE_ORG = "Hashicorp-neh-Demo"
        TFE_URL = "https://app.terraform.io/api/v2"
        TFE_WORKSPACE = "neh-test-jenkins"
        
        TF_VERSION = "0.12.26"
    } 
    
    stages {
        stage('Preparing Environment') {

            steps {
                sh '''
                  set +e
                  apt update 
                  apt install -y git curl jq
                  echo "git clone ${GIT_URL}"
                '''                
            }

        }

        stage('Preparing Terraform Configuration') {

            steps {
                sh '''
                  set +e
                  CONFIG_DIR="$(echo $GIT_URL | cut -d "/" -f 5 | cut -d "." -f 1)"
                  tar -czf $CONFIG_DIR.tar.gz --exclude='.git' --exclude='.gitignore' --exclude='Jenkinsfile' .
                '''                
            }
        }

        stage('Preparing Files Templates for Terraform Enterprise') {

            steps {
                sh '''
                  set +e
                  mkdir $WORKSPACE/templates
                  tee $WORKSPACE/templates/workspace_tmpl.json << EOF
                    {
                       "data": {
                           "attributes": {
                               "name": "placeholder",
                               "terraform_version": "$TF_VERSION"
                           },
                           "type": "workspaces"
                       }
                    }
EOF
                '''
                sh '''
                  tee $WORKSPACE/templates/variable_tmpl.json << EOF
                    {
                      "data": {
                          "type":"vars",
                          "attributes": {
                              "key":"my-key",
                              "value":"my-value",
                              "category":"my-category",
                              "hcl":my-hcl,
                              "sensitive":my-sensitive
                          }
                      },
                      "filter": {
                          "organization": {
                              "username":"my-organization"
                          },
                          "workspace": {
                              "name":"my-workspace"
                          }
                      }
                    }
EOF
                '''
                sh'''
                  tee $WORKSPACE/templates/run_tmpl.json << EOF
                    {
                      "data": {
                          "attributes": {
                              "is-destroy":false
                          },
                          "type":"runs",
                          "relationships": {
                              "workspace": {
                                  "data": {
                                      "type": "workspaces",
                                      "id": "workspace_id"
                                  }
                              }
                          }
                      }   
                    }
EOF
                '''
                sh'''
                  set +e
                  mkdir $WORKSPACE/variables
                  tee $WORKSPACE/variables/variables_file.csv << EOF
                    ARM_CLIENT_ID,$ARM_CLIENT_ID,env,false,false
                    ARM_CLIENT_SECRET,$ARM_CLIENT_SECRET,env,false,true
                    ARM_SUBSCRIPTION_ID,$ARM_SUBSCRIPTION_ID,env,false,false
                    ARM_TENANT_ID,$ARM_TENANT_ID,env,false,false
                    env,dev,terraform,false,false
EOF
                '''
                sh'''
                tee $WORKSPACE/configversion.json << EOF
                  {
                      "data": {
                          "type": "configuration-versions",
                          "attributes": {
                              "auto-queue-runs": false
                          }
                    }
                  }
EOF
                '''           
                
            }
        }

        stage('Preparing Terraform Enterprise Workspace') {
                
            steps {
                sh '''
                set +e
                echo "Checking if Workspace already exists"
                CHECK_WORKSPACE_RESULT="$(curl -v -H "Authorization: Bearer ${TFE_TOKEN}" -H "Content-Type: application/vnd.api+json" "${TFE_URL}/organizations/${TFE_ORG}/workspaces/${TFE_WORKSPACE}")"
                TFE_WORKSPACE_ID="$(echo $CHECK_WORKSPACE_RESULT | python -c "import sys, json; print(json.load(sys.stdin)['data']['id'])")"
                

                if [ -z "$TFE_WORKSPACE_ID"]; then
                    echo "Workspace doesn't exist so it will be created"
                    sed "s/placeholder/${TFE_WORKSPACE}/" <$WORKSPACE/templates/workspace_tmpl.json > $WORKSPACE/workspace.json
                    TFE_WORKSPACE_ID="$(curl -v -H "Authorization: Bearer ${TFE_TOKEN}" -H "Content-Type: application/vnd.api+json" -d "@$WORKSPACE/workspace.json" "${TFE_URL}/organizations/${TFE_ORG}/workspaces" | jq -r '.data.id')"
                else
                    echo "Workspace Already Exist"
                fi

                echo "Configuring Variables at Workspace Level"
                while IFS=',' read -r key value category hcl sensitive
                do
                sed -e "s/my_workspace/${TFE_WORKSPACE_ID}/" -e "s/my_key/$key/" -e "s/my_value/$value/" -e "s/my_category/$category/" -e "s/my_hcl/$hcl/" -e "s/my_sensitive/$sensitive/" < $WORKSPACE/templates/variables_tmpl.json  > $WORKSPACE/variables/variables.json
                cat ./variables/variables.json
                echo "Adding variable $key in category $category "
                upload_variable_result=$(curl -v -H "Authorization: Bearer ${TFE_TOKEN}" -H "Content-Type: application/vnd.api+json" -d "@$WORKSPACE/variables/variables.json" "${TF_HOSTNAME}/vars")
                done < $WORKSPACE/variables/variables_file.csv

                echo "Creating configuration version."
                configuration_version_result=$(curl -s --header "Authorization: Bearer $TFE_TOKEN" --header "Content-Type: application/vnd.api+json" --data @$WORKSPACE/configversion.json "${TFE_URL}/workspaces/${TFE_WORKSPACE_ID}/configuration-versions")

                config_version_id=$(echo $configuration_version_result | python -c "import sys, json; print(json.load(sys.stdin)['data']['id'])")
                upload_url=$(echo $configuration_version_result | python -c "import sys, json; print(json.load(sys.stdin)['data']['attributes']['upload-url'])")
                
                echo "Config Version ID: " $config_version_id
                echo "Upload URL: " $upload_url

                echo "Uploading configuration version using ${config_dir}.tar.gz"
                curl -s --header "Content-Type: application/octet-stream" --request PUT --data-binary @$CONFIG_DIR.tar.gz "$upload_url"
                '''
            }
        
        }

        stage('Launching Terraform Plan') {

            steps {
                sh 'echo "Hello"'
            }

        }

        stage('Approval') {
            steps {
                script {
                    def userInput = input(id: 'confirm', message: 'Apply Terraform?', parameters: [ [$class: 'BooleanParameterDefinition', defaultValue: false, description: 'Apply terraform', name: 'confirm'] ])
                }
            }
        }
        
        stage('Launching Terraform Apply') {

            steps {
                sh 'echo "Hello"'
            }

        }

    }

}