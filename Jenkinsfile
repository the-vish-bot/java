pipeline {
    agent { label 'vish-agent' }
    environment {
        AWS_DEFAULT_REGION = 'us-east-2'
        ECR_REPO = '042769662414.dkr.ecr.us-east-2.amazonaws.com/vishwesh/java'
    }
    stages {
        stage('Checkout') {
            steps {
                script {
                    echo "Branch name is ${BRANCH_NAME} and build number is ${BUILD_NUMBER}"
                }
            }
        }

        stage('Set Version') {
            steps {
                script {
                    def version = sh(script: "cat version.json | jq -r '.version'", returnStdout: true).trim()
                    echo "Project version found: ${version}"
                    env.IMAGE_TAG = "${version}-${BUILD_NUMBER}"
                    echo "Image will be tagged as: ${env.IMAGE_TAG}"
                }
            }
        }

        stage('Build JAR') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }


        // stage('Build and Test with Coverage') {
        //     steps {
        //         sh 'mvn clean test jacoco:report'
        //     }
        // }
        //
        // stage('Publish Coverage Report') {
        //     steps {
        //         publishCoverage adapters: [jacocoAdapter('**/target/site/jacoco/jacoco.xml')], 
        //                         sourceFileResolver: sourceFiles('STORE_ALL_BUILD')
        //     }
        // }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('vishwesh-sonar') {
                    sh 'mvn sonar:sonar'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t samplejava:${env.IMAGE_TAG} ."
            }
        }

        stage('Push to ECR') {
            steps {
                withAWS(credentials: 'aws-credentials-id', region: "${AWS_DEFAULT_REGION}") {
                    sh """
                        aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}
                        docker tag samplejava:${env.IMAGE_TAG} ${ECR_REPO}:${env.IMAGE_TAG}
                        docker push ${ECR_REPO}:${env.IMAGE_TAG}
                    """
                }
            }
        }

        stage('Deploy to Fargate') {
            steps {
                withAWS(credentials: 'aws-credentials-id', region: "${AWS_DEFAULT_REGION}") {
                    script {
                        if (BRANCH_NAME == 'development') {
                            sh """
                                aws ecs update-service --cluster vishwesh-fargate-cluster --service vishwesh-java-task-service-development --force-new-deployment
                            """
                        } else if (BRANCH_NAME == 'qa') {
                            sh """
                                aws ecs update-service --cluster vishwesh-fargate-cluster --service vishwesh-java-task-service-qa --force-new-deployment
                            """
                        } else if (BRANCH_NAME == 'verification') {
                            sh """
                                aws ecs update-service --cluster vishwesh-fargate-cluster --service vishwesh-java-task-service-verification --force-new-deployment
                            """
                        } else {
                            echo "Deploying branch '${BRANCH_NAME}' to default service"
                            sh """
                                aws ecs update-service --cluster vishwesh-fargate-cluster --service vishwesh-service --force-new-deployment
                            """
                        }
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Build and deployment successful for branch ${BRANCH_NAME} - Build #${BUILD_NUMBER}"
        }
        failure {
            echo "❌ Build or deployment failed for branch ${BRANCH_NAME} - Build #${BUILD_NUMBER}"
        }
        // success {
        //     office365ConnectorSend message: "✅ Build and deployment successful!",
        //                            status: "SUCCESS",
        //                            webhookUrl: "https://novatekno.webhook.office.com/webhookb2/1342fad1-c702-4867-ab8f-b65b4ac1f960@5282d369-03d7-4be5-86b2-9fa72a09d55b/IncomingWebhook/543d1e13b2ce4a37a45fb074021ac22d/4abbc960-ba3e-43e3-bb65-9163971ff8ee/V2Zc86fhcqTRpnHx6agpMlGi4QCx95UP3qjModFocUlt01"
        // }
        // failure {
        //     office365ConnectorSend message: "❌ Build or deployment failed!",
        //                            status: "FAILURE",
        //                            webhookUrl: "https://novatekno.webhook.office.com/webhookb2/1342fad1-c702-4867-ab8f-b65b4ac1f960@5282d369-03d7-4be5-86b2-9fa72a09d55b/IncomingWebhook/543d1e13b2ce4a37a45fb074021ac22d/4abbc960-ba3e-43e3-bb65-9163971ff8ee/V2Zc86fhcqTRpnHx6agpMlGi4QCx95UP3qjModFocUlt01"
        // }
    }
}
