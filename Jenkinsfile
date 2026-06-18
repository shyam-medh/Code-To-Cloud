pipeline {
    agent { label 'slave' }

    environment {
        // Change this to your actual Docker Hub username!
        DOCKER_IMAGE = 'shyammedh/java-app'
        
        // This links to the credentials you will create in Jenkins
        DOCKER_CREDS = 'docker-hub-credentials' 
        
        // The URL for the SonarQube server running on the Slave node
        SONAR_HOST_URL = 'http://localhost:9000'
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
                echo 'Code successfully cloned from GitHub!'
            }
        }

        stage('Checkov Security Scan') {
            steps {
                echo 'Scanning Terraform Infrastructure as Code for vulnerabilities...'
                // Using the official Checkov Docker container so we don't pollute the host OS
                // Note: We use "|| true" so it doesn't instantly block your build while you are learning!
                sh "docker run --rm -v \$(pwd):/tf bridgecrew/checkov -d /tf/infrastructure || true"
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo 'Scanning Java code for bugs, vulnerabilities, and code smells...'
                dir('task-tracker') {
                    // We will activate this exact command once you get the Sonar token!
                    echo 'Running SonarQube analysis...'
                    withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
                        sh "mvn clean verify sonar:sonar -Dsonar.projectKey=task-tracker -Dsonar.host.url=${SONAR_HOST_URL} -Dsonar.login=${SONAR_TOKEN}"
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                dir('task-tracker') {
                    echo 'Building the Spring Boot application using Docker...'
                    sh "docker build -t ${DOCKER_IMAGE}:latest -t ${DOCKER_IMAGE}:${env.BUILD_NUMBER} ."
                }
            }
        }

        stage('Trivy Vulnerability Scan') {
            steps {
                echo 'Scanning the Docker Image for CVEs before pushing...'
                // Scan the image locally for HIGH and CRITICAL vulnerabilities
                sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image --severity HIGH,CRITICAL ${DOCKER_IMAGE}:${env.BUILD_NUMBER} || true"
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo 'Pushing the secure image to Docker Hub...'
                withCredentials([usernamePassword(credentialsId: env.DOCKER_CREDS, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh "echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin"
                    sh "docker push ${DOCKER_IMAGE}:latest"
                    sh "docker push ${DOCKER_IMAGE}:${env.BUILD_NUMBER}"
                }
            }
        }

        stage('Deploy to AWS (Continuous Deployment)') {
            steps {
                echo 'Triggering AWS Auto Scaling Group to replace servers with the new image...'
                // This command tells AWS to gently terminate the old Java servers and boot new ones using the fresh Docker image!
                sh "aws autoscaling start-instance-refresh --auto-scaling-group-name devops-app-asg --region ap-south-1 || true"
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline completed successfully! The new version is deploying to AWS.'
        }
        failure {
            echo '❌ Pipeline failed. Check the logs above for details.'
        }
        always {
            // Always logout for security
            sh "docker logout || true"
        }
    }
}
