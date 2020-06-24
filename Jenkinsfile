pipeline {

    agent {
        docker {
            image 'debian:jessie'
            args '-u root:sudo '
        }
    }

    environment {
        TFE_TOKEN = "3zy31sP1w8Kg6g.atlasv1.uZy2rh8axeUELdKAnqNCRxi6qQQeIcyOfSQiO3iC3A5L6oBVt74ryKazBdWqN1BVWEM"
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
                               "terraform_version": "$TF_VERSION"
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
                    ARM_CLIENT_ID,toto,env,false,false
                    ARM_CLIENT_SECRET,toto,env,false,true
                    ARM_SUBSCRIPTION_ID,toto,env,false,false
                    ARM_TENANT_ID,toto,env,false,false
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
                CHECK_WORKSPACE_RESULT="$(curl -v -H "Authorization: Bearer $TFE_TOKEN" -H "Content-Type: application/vnd.api+json" "${TFE_URL}/organizations/${TFE_ORG}/workspaces/${TFE_WORKSPACE}")"
                TFE_WORKSPACE_ID="$(echo $CHECK_WORKSPACE_RESULT | python -c "import sys, json; print(json.load(sys.stdin)['data']['id'])")"

                if [ -z "$TFE_WORKSPACE_ID"]; then
                    echo "Workspace doesn't exist so it will be created"
                    sed "s/placeholder/${TFE_WORKSPACE}/" <$WORKSPACE/templates/workspace_tmpl.json > $WORKSPACE/workspace.json
                    TFE_WORKSPACE_ID="$(curl -v -H "Authorization: Bearer $TFE_TOKEN" -H "Content-Type: application/vnd.api+json" -d "@$WORKSPACE/workspace.json" "${TFE_URL}/organizations/${TFE_ORG}/workspaces" | jq -r '.data.id')"
                else
                    echo "Workspace Already Exist"
                fi

                echo "Configuring Variables at Workspace Level"
                while IFS=',' read -r key value category hcl sensitive
                do
                sed -e "s/my-id/${TFE_WORKSPACE_ID}/" -e "s/my-key/$key/" -e "s/my-value/$value/" -e "s/my-category/$category/" -e "s/my-hcl/$hcl/" -e "s/my-sensitive/$sensitive/" <$WORKSPACE/templates/variables_tmpl.json  > $WORKSPACE/variables/variables.json
                cat $WORKSPACE/variables/variables.json
                echo "Adding variable $key in category $category "
                upload_variable_result=$(curl -v -H "Authorization: Bearer $TFE_TOKEN" -H "Content-Type: application/vnd.api+json" -d "@$WORKSPACE/variables/variables.json" "${TFE_URL}/vars")
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
                sh '''
                TFE_WORKSPACE_ID="$(curl -v -H "Authorization: Bearer $TFE_TOKEN" -H "Content-Type: application/vnd.api+json" "${TFE_URL}/organizations/${TFE_ORG}/workspaces/${TFE_WORKSPACE}" | jq -r '.data.id')"
                sed "s/workspace_id/${TFE_WORKSPACE_ID}/" < $WORKSPACE/templates/run_tmpl.json  > $WORKSPACE/run.json
                run_result=$(curl -s --header "Authorization: Bearer $TFE_TOKEN" --header "Content-Type: application/vnd.api+json" --data @$WORKSPACE/run.json $TFE_URL/runs)

                TFE_RUN_ID=$(echo $run_result | python -c "import sys, json; print(json.load(sys.stdin)['data']['id'])")
                echo "Run ID: " $TFE_RUN_ID

                continue=1
                while [ $continue -ne 0 ]; do
  
                sleep 5
                echo "Checking run status"

                check_result=$(curl -s --header "Authorization: Bearer $TFE_TOKEN" --header "Content-Type: application/vnd.api+json" $TFE_URL/runs/${TFE_RUN_ID})

                run_status=$(echo $check_result | python -c "import sys, json; print(json.load(sys.stdin)['data']['attributes']['status'])")
                echo "Run Status: " $run_status
                is_confirmable=$(echo $check_result | python -c "import sys, json; print(json.load(sys.stdin)['data']['attributes']['actions']['is-confirmable'])")
                 echo "Run can be applied: " $is_confirmable

                if [ "$run_status" == "planned" ] && [ "$is_confirmable" == "True" ]; then
                  continue=0
                  echo "There are " $sentinel_policy_count "policies, but none of them are applicable to this workspace."
                  echo "Check the run in Terraform Enterprise UI and apply there if desired."
                
                elif [ "$run_status" == "errored" ]; then
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