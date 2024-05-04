pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                sh 'cd $WORKSPACE'
                sh 'sudo docker build -t manoj8795/app:capstone .'
            }
        }

        stage('Code Analysis') {
            environment {
                scannerHome = tool 'sonarqube'
            }
            steps {
                script {
                    withSonarQubeEnv('sonarqube') {
                        sh "${scannerHome}/bin/sonar-scanner \
                            -Dsonar.projectKey=capstone \
                            -Dsonar.projectName=capstone \
                            -Dsonar.sources=."
                    }
                }
            }
        }
        stage('Pushing to DockerHub') {
           steps {
                withCredentials([usernamePassword(credentialsId: 'docker-credentials', passwordVariable: 'dockerHubPassword', usernameVariable: 'dockerHubUser')]) {
                sh "sudo docker login -u ${env.dockerHubUser} -p ${env.dockerHubPassword}"
                sh 'sudo docker push manoj8795/app:capstone'
            }
        }
        }
        stage('Deploying to K8s') {
           steps {
              sshagent(['k8s-cluster']) {
               script {
                 def instanceId = sh(script: 'aws ec2 describe-instances --region eu-central-1 --filters "Name=tag:Name,Values=msaicharan-capstone-k8s-master" --query "Reservations[0].Instances[0].InstanceId"', returnStdout: true).trim()
                 def instanceIp = sh(script: "aws ec2 describe-instances --region eu-central-1 --instance-ids ${instanceId} --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text", returnStdout: true).trim()
                 sh 'cd $WORKSPACE'
                 sh "scp -o StrictHostKeyChecking=no webapp.yaml ubuntu@${instanceIp}:/home/ubuntu/"
                 try{
                    sh "ssh ubuntu@${instanceIp} kubectl rollout restart deployment capstone-spga"
                  }catch(error) {
                    sh "ssh ubuntu@${instanceIp} kubectl apply -f /home/ubuntu/webapp.yaml"
                     }
               }
           }
        }
      }
   }
}
