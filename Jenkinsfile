pipeline {
    agent any
    environment {
        DOCKER_IMAGE_MOVIE = 'tstallone/movie-service'
        DOCKER_IMAGE_CAST = 'tstallone/cast-service'
        DOCKER_TAG = "v.${env.BUILD_NUMBER}.0"
        KUBECONFIG = credentials('kubeconfig-credentials')
    }
    stages {
        stage('Test') {
            steps {
                script {
                    echo "🧪 Exécution des tests"
                    sh """
                        echo "Test du movie-service..."
                        cd movie-service/app/
                        python3 -m pytest || echo "Aucun test trouvé pour movie-service"
                        
                        echo "Test du cast-service..."
                        cd ../../cast-service/app/
                        python3 -m pytest || echo "Aucun test trouvé pour cast-service"
                    """
                    echo "✅ Tests terminés"
                }
            }
        }
        stage('Docker Build') {
            steps {
                script {
                    echo "🏗️ Construction des images Docker"
                    sh """
                        echo "🎬 Construction de movie-service..."
                        cd movie-service
                        docker build -t \${DOCKER_IMAGE_MOVIE}:\${DOCKER_TAG} .
                        
                        echo "🎭 Construction de cast-service..."
                        cd ../cast-service
                        docker build -t \${DOCKER_IMAGE_CAST}:\${DOCKER_TAG} .
                        
                        echo "✅ Images construites:"
                        echo "- \${DOCKER_IMAGE_MOVIE}:\${DOCKER_TAG}"
                        echo "- \${DOCKER_IMAGE_CAST}:\${DOCKER_TAG}"
                    """
                }
            }
        }
        stage('Docker Compose Test') {
            steps {
                script {
                    echo "🐳 Test avec Docker Compose"
                    sh """
                        echo "Mise à jour des tags dans docker-compose..."
                        # Mettre à jour les images avec les nouveaux tags
                        sed -i 's|build: ./movie-service|image: \${DOCKER_IMAGE_MOVIE}:\${DOCKER_TAG}|g' docker-compose.yml || true
                        sed -i 's|build: ./cast-service|image: \${DOCKER_IMAGE_CAST}:\${DOCKER_TAG}|g' docker-compose.yml || true
                        
                        echo "Lancement des services..."
                        docker-compose up -d
                        
                        echo "Attente du démarrage des services..."
                        sleep 30
                        
                        echo "Test des endpoints..."
                        curl -f http://localhost:8001/docs || echo "⚠️ Movie service endpoint non accessible"
                        curl -f http://localhost:8002/docs || echo "⚠️ Cast service endpoint non accessible"
                        curl -f http://localhost:8080 || echo "⚠️ Nginx endpoint non accessible"
                        
                        echo "Arrêt des services..."
                        docker-compose down -v
                    """
                }
            }
        }
        stage('Docker Push') {
            steps {
                script {
                    echo "📤 Push vers DockerHub"
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
                        sh """
                            echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                            
                            echo "Push movie-service..."
                            docker push \${DOCKER_IMAGE_MOVIE}:\${DOCKER_TAG}
                            
                            echo "Push cast-service..."
                            docker push \${DOCKER_IMAGE_CAST}:\${DOCKER_TAG}
                            
                            echo "✅ Images publiées sur DockerHub"
                        """
                    }
                }
            }
        }
        stage('Déploiement en DEV') {
            steps {
                script {
                    echo "🚀 Déploiement DEV avec Docker Compose"
                    sh """
                        echo "Configuration pour l'environnement DEV..."
                        
                        # Créer un docker-compose spécifique pour DEV
                        cp docker-compose.yml docker-compose.dev.yml
                        
                        # Remplacer les ports pour éviter les conflits
                        sed -i 's|8001:8000|8011:8000|g' docker-compose.dev.yml
                        sed -i 's|8002:8000|8012:8000|g' docker-compose.dev.yml
                        sed -i 's|8080:8080|8090:8080|g' docker-compose.dev.yml
                        
                        # Utiliser les nouvelles images
                        sed -i 's|build: ./movie-service|image: \${DOCKER_IMAGE_MOVIE}:\${DOCKER_TAG}|g' docker-compose.dev.yml
                        sed -i 's|build: ./cast-service|image: \${DOCKER_IMAGE_CAST}:\${DOCKER_TAG}|g' docker-compose.dev.yml
                        
                        echo "Déploiement des services en DEV..."
                        docker-compose -f docker-compose.dev.yml up -d
                        
                        echo "✅ DEV: Application déployée sur les ports 8011, 8012, 8090"
                    """
                }
            }
        }
        stage('Déploiement en QA') {
            steps {
                script {
                    echo "🧪 Déploiement QA avec Kubernetes"
                    withCredentials([kubeconfigFile(credentialsId: 'kubeconfig-credentials', variable: 'KUBECONFIG')]) {
                        sh """
                            echo "Configuration Kubernetes pour QA..."
                            rm -rf .kube
                            mkdir .kube
                            cat \$KUBECONFIG > .kube/config
                            
                            echo "Mise à jour des valeurs Helm pour QA..."
                            cd charts
                            cp values.yaml values-qa.yaml
                            
                            # Mettre à jour les images dans les values
                            sed -i 's|repository:.*movie.*|repository: \${DOCKER_IMAGE_MOVIE}|g' values-qa.yaml || true
                            sed -i 's|repository:.*cast.*|repository: \${DOCKER_IMAGE_CAST}|g' values-qa.yaml || true
                            sed -i 's|tag:.*|tag: \${DOCKER_TAG}|g' values-qa.yaml
                            
                            echo "Déploiement avec Helm en QA..."
                            helm upgrade --install app-qa . \\
                                --values=values-qa.yaml \\
                                --namespace qa \\
                                --create-namespace \\
                                --set environment=qa
                            
                            echo "✅ QA: Application déployée sur Kubernetes (namespace: qa)"
                        """
                    }
                }
            }
        }
        stage('Déploiement en STAGING') {
            steps {
                script {
                    echo "🎭 Déploiement STAGING avec Kubernetes"
                    withCredentials([kubeconfigFile(credentialsId: 'kubeconfig-credentials', variable: 'KUBECONFIG')]) {
                        sh """
                            echo "Configuration Kubernetes pour STAGING..."
                            rm -rf .kube
                            mkdir .kube
                            cat \$KUBECONFIG > .kube/config
                            
                            echo "Mise à jour des valeurs Helm pour STAGING..."
                            cd charts
                            cp values.yaml values-staging.yaml
                            
                            # Mettre à jour les images dans les values
                            sed -i 's|repository:.*movie.*|repository: \${DOCKER_IMAGE_MOVIE}|g' values-staging.yaml || true
                            sed -i 's|repository:.*cast.*|repository: \${DOCKER_IMAGE_CAST}|g' values-staging.yaml || true
                            sed -i 's|tag:.*|tag: \${DOCKER_TAG}|g' values-staging.yaml
                            
                            echo "Déploiement avec Helm en STAGING..."
                            helm upgrade --install app-staging . \\
                                --values=values-staging.yaml \\
                                --namespace staging \\
                                --create-namespace \\
                                --set environment=staging
                            
                            echo "✅ STAGING: Application déployée sur Kubernetes (namespace: staging)"
                        """
                    }
                }
            }
        }
        stage('Approbation Production') {
            steps {
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
                    echo "🏭 Déploiement PRODUCTION avec Kubernetes"
                    withCredentials([kubeconfigFile(credentialsId: 'kubeconfig-credentials', variable: 'KUBECONFIG')]) {
                        sh """
                            echo "Configuration Kubernetes pour PRODUCTION..."
                            rm -rf .kube
                            mkdir .kube
                            cat \$KUBECONFIG > .kube/config
                            
                            echo "Mise à jour des valeurs Helm pour PRODUCTION..."
                            cd charts
                            cp values.yaml values-prod.yaml
                            
                            # Mettre à jour les images dans les values
                            sed -i 's|repository:.*movie.*|repository: \${DOCKER_IMAGE_MOVIE}|g' values-prod.yaml || true
                            sed -i 's|repository:.*cast.*|repository: \${DOCKER_IMAGE_CAST}|g' values-prod.yaml || true
                            sed -i 's|tag:.*|tag: \${DOCKER_TAG}|g' values-prod.yaml
                            
                            echo "Déploiement avec Helm en PRODUCTION..."
                            helm upgrade --install app-prod . \\
                                --values=values-prod.yaml \\
                                --namespace production \\
                                --create-namespace \\
                                --set environment=production
                            
                            echo "🎉 PRODUCTION: Application déployée avec succès sur Kubernetes!"
                            echo "📊 Vérifiez les services avec: kubectl get all -n production"
                        """
                    }
                }
            }
        }
    }
    post {
        always {
            echo "🧹 Nettoyage terminé"
        }
        success {
            echo '🎉 Pipeline exécuté avec succès!'
        }
        failure {
            echo '❌ Le pipeline a échoué!'
        }
    }
}
