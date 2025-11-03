pipeline {
    agent { label 'vish-agent' }

    environment {
        AWS_DEFAULT_REGION = 'us-east-2'
        ECR_REPO = '042769662414.dkr.ecr.us-east-2.amazonaws.com/vishwesh/java'
        IMAGE_TAG = "${BUILD_NUMBER}" 
    }

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/the-vish-bot/java.git', credentialsId: '9b5a4a1a-56c0-41a2-9947-a7708abbb720'
                script {
                    echo "Checked out branch: ${env.BRANCH_NAME}"
                    echo "Build number: ${env.BUILD_NUMBER}"
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
                sh "docker build -t samplejava:${IMAGE_TAG} ."
            }
        }

        stage('Push to ECR') {
            steps {
                withAWS(credentials: 'aws-credentials-id', region: "${AWS_DEFAULT_REGION}") {
                    sh """
                        aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}
                        docker tag samplejava:${IMAGE_TAG} ${ECR_REPO}:${IMAGE_TAG}
                        docker push ${ECR_REPO}:${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Deploy to Fargate') {
            steps {
                withAWS(credentials: 'aws-credentials-id', region: "${AWS_DEFAULT_REGION}") {
                    script {
                        switch (env.BRANCH_NAME) {
                            case 'development':
                                sh """
                                    aws ecs update-service --cluster vishwesh-fargate-cluster --service vishwesh-java-task-service-development --force-new-deployment
                                """
                                break
                            case 'qa':
                                sh """
                                    aws ecs update-service --cluster vishwesh-fargate-cluster --service vishwesh-java-task-service-qa --force-new-deployment
                                """
                                break
                            case 'verification':
                                sh """
                                    aws ecs update-service --cluster vishwesh-fargate-cluster --service vishwesh-java-task-service-verification --force-new-deployment
                                """
                                break
                            default:
                                echo "Deploying '${env.BRANCH_NAME}' to default service"
                                sh """
                                    aws ecs update-service --cluster vishwesh-fargate-cluster --service vishwesh-service --force-new-deployment
                                """
                                break
                        }
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Build and deployment completed successfully for branch: ${env.BRANCH_NAME}"
        }
        failure {
            echo "Build or deployment failed for branch: ${env.BRANCH_NAME}. Check logs!"
        }
    }
}
