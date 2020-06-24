pipeline {

    agent {
        docker {
            image 'debian:jessie'
            args '-u root:sudo '
        }
    }

    parameters {
        string(name: 'org_token', defaultValue: 'default', description: 'Jenkins Terraform Enterprise Organization Token for Workspace Creation')
        string(name: 'user_token', defaultValue: 'default', description: 'User Terraform Enterprise Token for Runs')
        string(name: 'organization', defaultValue: 'default', description: 'Terraform Organization Name')
        string(name: 'tf_workspace', defaultValue: 'default', description: 'Terraform Workspace Name')
        string(name: 'url', defaultValue: 'default', description: 'Url to connect to Terraform Enterprise - ex : https://app.terraform.io/api/v2')
        string(name: 'version', defaultValue: '', description: 'Terraform Binary Version')
        string(name: 'client_id', defaultValue: '', description: 'Azure Client ID')
        string(name: 'client_secret', defaultValue: '', description: 'Azure Client Secret')
        string(name: 'subscription_id', defaultValue: '', description: 'Azure Subscription ID')
        string(name: 'tenant_id', defaultValue: '', description: 'Azure Tenant ID')
        
    }
    
    stages {
        stage('Preparing Environment') {

            steps {
                sh '''
                  set +e
                  apt update 
                  apt install -y git curl jq python
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
                               "terraform_version": "${version}"
                           },
                           "type": "workspaces"
                       }
                    }
EOF
                '''
                sh '''
                  tee $WORKSPACE/templates/variables_tmpl.json << EOF
                    {
                      "data": {
                          "type":"vars",
                          "attributes": {
                              "key":"my-key",
                              "value":"my-value",
                              "category":"my-category",
                              "hcl":my-hcl,
                              "sensitive":my-sensitive
                          },
                          "relationships": {
                          "workspace": {
                             "data": {
                                "id":"my-id",
                                "type":"workspaces"
                             }
                          }
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
                    ARM_CLIENT_ID,"${client_id}",env,false,false
                    ARM_CLIENT_SECRET,"${client_secret}",env,false,true
                    ARM_SUBSCRIPTION_ID,"${subscription_id}",env,false,false
                    ARM_TENANT_ID,"${tenant_id}",env,false,false
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
                CHECK_WORKSPACE_RESULT="$(curl -v -H "Authorization: Bearer ${org_token}" -H "Content-Type: application/vnd.api+json" "${url}/organizations/${organization}/workspaces/${tf_workspace}")"
                TFE_WORKSPACE_ID="$(echo $CHECK_WORKSPACE_RESULT | python -c "import sys, json; print(json.load(sys.stdin)['data']['id'])")"

                if [ -z "$TFE_WORKSPACE_ID"]; then
                    echo "Workspace doesn't exist so it will be created"
                    sed "s/placeholder/${tf_workspace}/" <$WORKSPACE/templates/workspace_tmpl.json > $WORKSPACE/workspace.json
                    TFE_WORKSPACE_ID="$(curl -v -H "Authorization: Bearer ${org_token}" -H "Content-Type: application/vnd.api+json" -d "@$WORKSPACE/workspace.json" "${url}/organizations/${organization}/workspaces" | jq -r '.data.id')"
                else
                    echo "Workspace Already Exist"
                fi

                echo "Configuring Variables at Workspace Level"
                while IFS=',' read -r key value category hcl sensitive
                do
                sed -e "s/my-id/${TFE_WORKSPACE_ID}/" -e "s/my-key/$key/" -e "s/my-value/$value/" -e "s/my-category/$category/" -e "s/my-hcl/$hcl/" -e "s/my-sensitive/$sensitive/" <$WORKSPACE/templates/variables_tmpl.json  > $WORKSPACE/variables/variables.json
                cat $WORKSPACE/variables/variables.json
                echo "Adding variable $key in category $category "
                upload_variable_result=$(curl -v -H "Authorization: Bearer ${org_token}" -H "Content-Type: application/vnd.api+json" -d "@$WORKSPACE/variables/variables.json" "${param.url}/vars")
                done < $WORKSPACE/variables/variables_file.csv

                echo "Creating configuration version."
                configuration_version_result=$(curl -s --header "Authorization: Bearer ${org_token}" --header "Content-Type: application/vnd.api+json" --data @$WORKSPACE/configversion.json "${url}/workspaces/${TFE_WORKSPACE_ID}/configuration-versions")

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
                sh '''
                TFE_WORKSPACE_ID="$(curl -v -H "Authorization: Bearer ${org_token}" -H "Content-Type: application/vnd.api+json" "${url}/organizations/${TFE_ORG}/workspaces/${tf_workspace}" | jq -r '.data.id')"
                sed "s/workspace_id/${TFE_WORKSPACE_ID}/" < $WORKSPACE/templates/run_tmpl.json  > $WORKSPACE/run.json
                run_result=$(curl -s --header "Authorization: Bearer ${org_token}" --header "Content-Type: application/vnd.api+json" --data @$WORKSPACE/run.json ${url}/runs)

                TFE_RUN_ID=$(echo $run_result | python -c "import sys, json; print(json.load(sys.stdin)['data']['id'])")
                echo "Run ID: " $TFE_RUN_ID

                continue=1
                while [ $continue -ne 0 ]; do
  
                sleep 5

                echo "Checking run status"

                check_result=$(curl -s --header "Authorization: Bearer ${org_token}" --header "Content-Type: application/vnd.api+json" ${url}/runs/${TFE_RUN_ID})

                run_status=$(echo $check_result | python -c "import sys, json; print(json.load(sys.stdin)['data']['attributes']['status'])")
                echo "Run Status: " $run_status
                is_confirmable=$(echo $check_result | python -c "import sys, json; print(json.load(sys.stdin)['data']['attributes']['actions']['is-confirmable'])")
                 echo "Run can be applied: " $is_confirmable

                if [ "$run_status" == "planned" -a "$is_confirmable" == "True" ]
                  then
                  continue=0
                  echo "There are " $sentinel_policy_count "policies, but none of them are applicable to this workspace."
                  echo "Check the run in Terraform Enterprise UI and apply there if desired."

                
                elif [ $run_status == "errored" ] 
                then
                  echo "Plan errored or hard-mandatory policy failed"
                  continue=0
                
                else 
                echo "We will sleep and try again soon."
                fi

                done
                '''
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