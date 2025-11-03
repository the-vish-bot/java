pipeline {
    agent { label 'vish-agent' }
    environment {
        AWS_DEFAULT_REGION = 'us-east-2'
        ECR_REPO = '042769662414.dkr.ecr.us-east-2.amazonaws.com/vishwesh/java'
        TEAMS_WEBHOOK = 'https://default5282d36903d74be586b29fa72a09d5.5b.environment.api.powerplatform.com:443/powerautomate/automations/direct/workflows/3e14992b564847b3af00ef50b0069153/triggers/manual/paths/invoke?api-version=1&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=ZdGtyVXaAkoy9WCuR8-1fB13QTJUr-yJUV3B9dKhke0'
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
                    // Read version from version.json
                    def version = sh(script: "cat version.json | jq -r '.version'", returnStdout: true).trim()
                    echo "Project version found: ${version}"
                    
                    // Optionally append build number for uniqueness
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
                        } else if (BRANCH_NAME == 'main') {
                            sh """
                                aws ecs update-service --cluster vishwesh-fargate-cluster --service vishwesh-java-task-service-production --force-new-deployment
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
            script {
                echo "Build and deployment completed successfully!"
                echo "Docker image: ${ECR_REPO}:${env.IMAGE_TAG}"
                
                sh """
                    curl -X POST '${TEAMS_WEBHOOK}' \
                    -H 'Content-Type: application/json' \
                    -d '{
                        "title": "✅ Pipeline SUCCESS",
                        "text": "Build and deployment completed successfully!",
                        "job": "${env.JOB_NAME}",
                        "buildNumber": "${env.BUILD_NUMBER}",
                        "branch": "${BRANCH_NAME}",
                        "imageTag": "${env.IMAGE_TAG}",
                        "status": "SUCCESS",
                        "color": "Good",
                        "buildUrl": "${env.BUILD_URL}"
                    }'
                """
            }
        }
        failure {
            script {
                echo "Build or deployment failed. Check logs!"
                
                sh """
                    curl -X POST '${TEAMS_WEBHOOK}' \
                    -H 'Content-Type: application/json' \
                    -d '{
                        "title": "❌ Pipeline FAILED",
                        "text": "Build or deployment failed. Please check the logs!",
                        "job": "${env.JOB_NAME}",
                        "buildNumber": "${env.BUILD_NUMBER}",
                        "branch": "${BRANCH_NAME}",
                        "status": "FAILED",
                        "color": "Attention",
                        "buildUrl": "${env.BUILD_URL}",
                        "consoleUrl": "${env.BUILD_URL}console"
                    }'
                """
            }
        }
        unstable {
            script {
                sh """
                    curl -X POST '${TEAMS_WEBHOOK}' \
                    -H 'Content-Type: application/json' \
                    -d '{
                        "title": "⚠️ Pipeline UNSTABLE",
                        "text": "Build completed but tests are unstable",
                        "job": "${env.JOB_NAME}",
                        "buildNumber": "${env.BUILD_NUMBER}",
                        "branch": "${BRANCH_NAME}",
                        "status": "UNSTABLE",
                        "color": "Warning",
                        "buildUrl": "${env.BUILD_URL}"
                    }'
                """
            }
        }
    }
}
