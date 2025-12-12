pipeline {
    agent any
    
    tools {
        maven 'maven3'
        jdk 'jdk17'
    }
    
    environment {
        SCANNER_HOME = tool 'SonarQube Scanner'
        DOCKER_IMAGE_NAME = "1ezgin/corp"
        DOCKER_TAG = "latest"
        RECIPIENT_EMAIL = "amirovamir2003@gmail.com"
    }

    stages {
        stage('Git Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/1ezgin/devsecops-corporate-pipeline.git'
            }
        }
        
        stage('Build and Test') {
            steps {
                sh "mvn clean install -DskipITs -Dcheckstyle.skip=true"
            }
        }
        
        stage('File System Scan (Trivy)') {
            steps {
                sh "trivy fs --format table --output trivy-fs-report.html ."
            }
        }
        
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar') {
                    sh '''
                        $SCANNER_HOME/bin/sonar-scanner \
                        -Dsonar.projectName=PetClinicDevOps \
                        -Dsonar.projectKey=PetClinic \
                        -Dsonar.sources=src/main/java \
                        -Dsonar.java.binaries=target/classes
                    '''
                }
            }
        }
        
        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true, credentialsId: 'sonar-token'
                }
            }
        }
        
        stage('Publish to Nexus') {
            steps {
                withMaven(globalMavenSettingsConfig: 'global-settings', jdk: 'jdk17', maven: 'maven3') {
                    sh "mvn deploy -Dcheckstyle.skip=true"
                }
            }
        }
        
        stage('Build and Tag Docker Image') {
            steps {
                withDockerRegistry(credentialsId: 'docker-cred', toolName: 'docker') {
                    sh "docker build -t ${DOCKER_IMAGE_NAME}:${DOCKER_TAG} ."
                }
            }
        }

        stage('Docker Image Scan (Trivy)') {
            steps {
                sh "trivy image --format table --output trivy-image-report.html ${DOCKER_IMAGE_NAME}:${DOCKER_TAG}"
            }
        }
        
        stage('Push Docker Image') {
            steps {
                withDockerRegistry(credentialsId: 'docker-cred', toolName: 'docker') {
                    sh "docker push ${DOCKER_IMAGE_NAME}:${DOCKER_TAG}"
                }
            }
        }
        
        stage('Deploy to k8s') {
            when { expression { return env.BRANCH_NAME == 'main' } }
            steps {
                withKubeConfig(credentialsId: 'k8-cred', namespace: 'webapps', serverUrl: 'https://172.31.41.254:6443') {
                    sh "kubectl apply -f deployment-service.yaml -n webapps"
                }
            }
        }
        
        stage('Verify the Deployment') {
            when { expression { return env.BRANCH_NAME == 'main' } }
            steps {
                withKubeConfig(credentialsId: 'k8-cred', namespace: 'webapps', serverUrl: 'https://172.31.41.254:6443') {
                    sh "kubectl get pods -n webapps"
                    sh "kubectl get svc -n webapps"
                }
            }
        }
        
        stage('Manual Deploy Instructions') {
            when { expression { return env.BRANCH_NAME != 'main' } }
            steps {
                echo "Deployment skipped for branch ${env.BRANCH_NAME}. Deploy manually using: kubectl apply -f deployment-service.yaml -n webapps"
            }
        }
    } 
    
    post {
        success {
            emailext(
                body: "Pipeline SUCCESS. Build: \${env.BUILD_NUMBER}. Check reports in workspace.",
                subject: "SUCCESS: \${env.JOB_NAME}",
                to: "${RECIPIENT_EMAIL}",
                attachments: 'trivy-fs-report.html, trivy-image-report.html' 
            )
        }
        failure {
            emailext(
                body: "Pipeline FAILED. Build: \${env.BUILD_NUMBER}. Check Jenkins log.",
                subject: "FAILED: \${env.JOB_NAME}",
                to: "${RECIPIENT_EMAIL}"
            )
        }
        always {
            archiveArtifacts artifacts: 'target/*.jar,trivy-*.html', allowEmptyArchive: true
            cleanWs()
        }
    }
}
