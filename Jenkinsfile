pipeline {
    agent any
    environment {
        // Définition des variables d'environnement
        DOCKER_HUB_CREDS = credentials('dockerhub-credentials')
        DOCKER_IMAGE = 'tstallone/fastapi-app'
        DOCKER_TAG = "v.${env.BUILD_NUMBER}.0"
        KUBECONFIG = credentials('kubeconfig-credentials')
        GIT_REPO_URL = 'https://github.com/stalloneginette/news_jenkins.git'
    }
    stages {
        stage('Test') {
            steps {
                script {
                    // Exécution des tests
                    sh """
                        cd app/
                        python3 -m pytest
                    """
                }
            }
        }
        stage('Docker Build') {
            steps {
                script {
                    // Construction de l'image Docker
                    sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                    echo "Image Docker construite: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                }
            }
        }
        stage('Docker Run & Test') {
            steps {
                script {
                    // Test de l'image Docker
                    sh """
                        docker run -d -p 80:80 --name fastapi-test ${DOCKER_IMAGE}:${DOCKER_TAG}
                        sleep 10
                        curl localhost:80 || echo "Test terminé"
                        docker stop fastapi-test
                        docker rm fastapi-test
                    """
                }
            }
        }
        stage('Docker Push') {
            steps {
                script {
                    // Push vers DockerHub
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
                        sh "echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin"
                        sh "docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
                    }
                }
            }
        }
        stage('Déploiement en DEV') {
            steps {
                script {
                    withCredentials([kubeconfigFile(credentialsId: 'kubeconfig-credentials', variable: 'KUBECONFIG')]) {
                        // Déploiement sur l'environnement de développement
                        echo "🚀 Déploiement dans l'environnement DEV"
                        sh """
                            rm -Rf .kube
                            mkdir .kube
                            cat \$KUBECONFIG > .kube/config
                            cp fastapi/values.yaml values.yml
                            sed -i 's+tag.*+tag: ${DOCKER_TAG}+g' values.yml
                            helm upgrade --install app fastapi --values=values.yml --namespace dev
                        """
                    }
                }
            }
        }
        stage('Déploiement en QA') {
            steps {
                script {
                    withCredentials([kubeconfigFile(credentialsId: 'kubeconfig-credentials', variable: 'KUBECONFIG')]) {
                        // Déploiement sur l'environnement QA
                        echo "🧪 Déploiement dans l'environnement QA"
                        sh """
                            rm -Rf .kube
                            mkdir .kube
                            cat \$KUBECONFIG > .kube/config
                            cp fastapi/values.yaml values.yml
                            sed -i 's+tag.*+tag: ${DOCKER_TAG}+g' values.yml
                            helm upgrade --install app-qa fastapi --values=values.yml --namespace qa --create-namespace
                        """
                    }
                }
            }
        }
        stage('Déploiement en STAGING') {
            steps {
                script {
                    withCredentials([kubeconfigFile(credentialsId: 'kubeconfig-credentials', variable: 'KUBECONFIG')]) {
                        // Déploiement sur l'environnement de Staging
                        echo "🎭 Déploiement dans l'environnement STAGING"
                        sh """
                            rm -Rf .kube
                            mkdir .kube
                            cat \$KUBECONFIG > .kube/config
                            cp fastapi/values.yaml values.yml
                            sed -i 's+tag.*+tag: ${DOCKER_TAG}+g' values.yml
                            helm upgrade --install app-staging fastapi --values=values.yml --namespace staging --create-namespace
                        """
                    }
                }
            }
        }
        stage('Approbation Production') {
            steps {
                // Demande d'approbation manuelle pour le déploiement en production
                script {
                    echo "⏳ Demande d'approbation pour la production..."
                    timeout(time: 5, unit: 'MINUTES') {
                        input message: "🚨 Déployer en PRODUCTION?", ok: "✅ Oui, déployer en PROD!"
                    }
                }
            }
        }
        stage('Déploiement en PRODUCTION') {
            steps {
                script {
                    withCredentials([kubeconfigFile(credentialsId: 'kubeconfig-credentials', variable: 'KUBECONFIG')]) {
                        // Déploiement en production
                        echo "🏭 Déploiement dans l'environnement PRODUCTION"
                        sh """
                            rm -Rf .kube
                            mkdir .kube
                            cat \$KUBECONFIG > .kube/config
                            cp fastapi/values.yaml values.yml
                            sed -i 's+tag.*+tag: ${DOCKER_TAG}+g' values.yml
                            helm upgrade --install app-prod fastapi --values=values.yml --namespace production --create-namespace
                        """
                    }
                }
            }
        }
    }
    post {
        always {
            // Nettoyage des images Docker locales
            script {
                try {
                    sh """
                        docker system prune -f
                    """
                    echo "🧹 Nettoyage terminé"
                } catch (Exception e) {
                    echo "⚠️ Erreur lors du nettoyage: ${e.getMessage()}"
                }
            }
        }
        success {
            echo '🎉 Pipeline exécuté avec succès!'
        }
        failure {
            echo '❌ Le pipeline a échoué!'
        }
    }
}
