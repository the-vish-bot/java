pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-2'
        ECR_REPO = '<account-id>.dkr.ecr.us-east-2.amazonaws.com/java-sample'
        IMAGE_TAG = "${env.BUILD_NUMBER}"   // Unique tag for each build
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'git@github.com:the-vish-bot/java.git'
            }
        }

        stage('Build JAR') {
            steps {
                sh 'mvn clean package -DskipTests'
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
                        aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $ECR_REPO
                        docker tag samplejava:${IMAGE_TAG} $ECR_REPO:${IMAGE_TAG}
                        docker push $ECR_REPO:${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Deploy to Fargate') {
            steps {
                sh """
                    aws ecs update-service \
                        --cluster my-fargate-cluster \
                        --service java-sample-service \
                        --force-new-deployment \
                        --region $AWS_DEFAULT_REGION
                """
            }
        }
    }

    post {
        success {
            echo "✅ Build and deployment completed successfully!"
        }
        failure {
            echo "❌ Build or deployment failed. Check logs!"
        }
    }
}

