pipeline {
    agent any

    environment {
        IMAGE_NAME = 'manujanaa/kanban-dashboard'
    }

    stages {

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} .'
            }
        }

        stage('Docker Login & Push') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-cred',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {
                    sh '''
                        echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${IMAGE_NAME}:${BUILD_NUMBER}
                    '''
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                sshagent(['kanban-deploy-ssh']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ubuntu@172.31.8.93 "
                            docker pull ${IMAGE_NAME}:${BUILD_NUMBER} &&
                            docker stop kanban-app || true &&
                            docker rm kanban-app || true &&
                            
                               docker run -d \
                                --name kanban-app \
                                --memory 512m \
                                --memory-swap 512m \
                                --cpus 1.0 \
                                -p 5173:5173 \
                                ${IMAGE_NAME}:${BUILD_NUMBER}
                        "
                    '''
                }
            }
        }

        stage('Health Check') {
            steps {
                sshagent(['kanban-deploy-ssh']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ubuntu@172.31.8.93 "
                            for i in 1 2 3 4 5 6 7 8 9 10 11 12
                            do
                                STATUS=\\$(docker inspect kanban-app --format='{{.State.Health.Status}}')
                                echo \\\"Container health: \\$STATUS\\\"

                                if [ \\\"\\$STATUS\\\" = \\\"healthy\\\" ]; then
                                    echo \\\"Container is healthy\\\"
                                    curl -f http://localhost:5173
                                    exit 0
                                fi

                                if [ \\\"\\$STATUS\\\" = \\\"unhealthy\\\" ]; then
                                    echo \\\"Container is unhealthy\\\"
                                    docker logs kanban-app
                                    exit 1
                                fi

                                echo \\\"Waiting for container health...\\\"
                                sleep 5
                            done

                            echo \\\"Health check timed out\\\"
                            docker logs kanban-app
                            exit 1
                        "
                    '''
                }
            }
        }
    }
}
