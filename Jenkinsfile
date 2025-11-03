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
                    def versionJson = readJSON file: 'version.json'
                    env.IMAGE_TAG = versionJson.version
                    echo "Version from version.json: ${env.IMAGE_TAG}"
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
                script {
                    sh "docker build -t samplejava:${env.IMAGE_TAG} ."
                }
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
            echo "Build and deployment completed successfully! Image tag: ${env.IMAGE_TAG}"
        }
        failure {
            echo "Build or deployment failed. Check logs!"
        }
    }
}
