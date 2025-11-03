pipeline {
    agent { label 'vish-agent' }

    environment {
        AWS_DEFAULT_REGION = 'us-east-2'
        ECR_REPO = '042769662414.dkr.ecr.us-east-2.amazonaws.com/vishwesh/java'
        IMAGE_TAG = ''  // Placeholder, will be set later
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
                    // Extract version from version.json using jq
                    def version = sh(script: "cat version.json | jq -r .version", returnStdout: true).trim()
                    echo " Project version found in version.json: ${version}"
                    env.PROJECT_VERSION = version
                }
            }
        }

        stage('Set Image Tag') {
            steps {
                script {
                    // Combine version + build number for uniqueness
                    env.IMAGE_TAG = "${PROJECT_VERSION}-${BUILD_NUMBER}"
                    echo " Docker Image Tag set to: ${IMAGE_TAG}"
                }
            }
        }

        // stage('Build and Test with Coverage') {
        //     steps {
        //         sh 'mvn clean test jacoco:report'
        //     }
        // }

        // stage('Publish Coverage Report') {
        //     steps {
        //         publishCoverage adapters: [jacocoAdapter('**/target/site/jacoco/jacoco.xml')],
        //                         sourceFileResolver: sourceFiles('STORE_ALL_BUILD')
        //     }
        // }

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
                sh "docker build -t samplejava:${IMAGE_TAG} ."
            }
        }

        stage('Push to ECR') {
            steps {
                withAWS(credentials: 'aws-credentials-id', region: "${AWS_DEFAULT_REGION}") {
                    sh """
                        echo " Logging in to AWS ECR..."
                        aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}

                        echo " Tagging image as ${ECR_REPO}:${IMAGE_TAG}"
                        docker tag samplejava:${IMAGE_TAG} ${ECR_REPO}:${IMAGE_TAG}

                        echo "Pushing image to ECR..."
                        docker push ${ECR_REPO}:${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Deploy to Fargate') {
            steps {
                withAWS(credentials: 'aws-credentials-id', region: "${AWS_DEFAULT_REGION}") {
                    script {
                        if (BRANCH_NAME == 'development') {
                            sh "aws ecs update-service --cluster vishwesh-fargate-cluster --service vishwesh-java-task-service-development --force-new-deployment"
                        } else if (BRANCH_NAME == 'qa') {
                            sh "aws ecs update-service --cluster vishwesh-fargate-cluster --service vishwesh-java-task-service-qa --force-new-deployment"
                        } else if (BRANCH_NAME == 'verification') {
                            sh "aws ecs update-service --cluster vishwesh-fargate-cluster --service vishwesh-java-task-service-verification --force-new-deployment"
                        } else {
                            echo "Deploying branch '${BRANCH_NAME}' to default service"
                            sh "aws ecs update-service --cluster vishwesh-fargate-cluster --service vishwesh-service --force-new-deployment"
                        }
                    }
                }
            }
        }
    }

    post {
        success {
            echo " Build and deployment completed successfully!"
            echo " Final image: ${ECR_REPO}:${IMAGE_TAG}"
        }
        failure {
            echo " Build or deployment failed. Check logs!"
        }
    }
}
