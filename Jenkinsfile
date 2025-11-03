pipeline {
    agent { label 'vish-agent' }

    environment {
        AWS_DEFAULT_REGION = 'us-east-2'
        ECR_REPO = '042769662414.dkr.ecr.us-east-2.amazonaws.com/vishwesh/java'
        IMAGE_TAG = "${BUILD_NUMBER}" // Unique tag for each build
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    git branch: 'main', url: 'https://github.com/the-vish-bot/java.git', credentialsId: '9b5a4a1a-56c0-41a2-9947-a7708abbb720'
                    env.BRANCH_NAME = sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()
                    echo "Branch name is ${env.BRANCH_NAME} and build number is ${env.BUILD_NUMBER}"
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
                        if (env.BRANCH_NAME == 'development') {
                            sh """
                                aws ecs update-service --cluster vishwesh-fargate-cluster --service vishwesh-java-task-service-development --force-new-deployment
                            """
                        } else if (env.BRANCH_NAME == 'qa') {
                            sh """
                                aws ecs update-service --cluster vishwesh-fargate-cluster --service vishwesh-java-task-service-qa --force-new-deployment
                            """
                        } else if (env.BRANCH_NAME == 'verification') {
                            sh """
                                aws ecs update-service --cluster vishwesh-fargate-cluster --service vishwesh-java-task-service-verification --force-new-deployment
                            """
                        } else {
                            echo "Deploying branch '${env.BRANCH_NAME}' to default service"
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
            echo "Build and deployment completed successfully!"
        }
        failure {
            echo "Build or deployment failed. Check logs!"
        }
    }
}
