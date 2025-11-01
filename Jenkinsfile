pipeline {
    agent any
    
    environment {
        AWS_DEFAULT_REGION = 'us-east-2'
        ECR_REPO = '<account-id>.dkr.ecr.us-east-2.amazonaws.com/java-sample'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', 
                    url: 'https://github.com/the-vish-bot/java.git', 
                    credentialsId: '9b5a4a1a-56c0-41a2-9947-a7708abbb720'
            }
        }
        
        stage('Build JAR') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }
        

        
        // 👇 ADD THIS STAGE (Optional - to check quality gate)
        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
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
                        aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $ECR_REPO
                        docker tag samplejava:${IMAGE_TAG} $ECR_REPO:${IMAGE_TAG}
                        docker push $ECR_REPO:${IMAGE_TAG}
                    """
                }
            }
        }
        
        stage('Deploy to Fargate') {
            steps {
                withAWS(credentials: 'aws-credentials-id', region: "${AWS_DEFAULT_REGION}") {
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
    }
    
    post {
        success {
            echo "✅ Build, SonarQube analysis, and deployment completed successfully!"
        }
        failure {
            echo "❌ Build, analysis, or deployment failed. Check logs!"
        }
    }
}
