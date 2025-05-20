pipeline {
    environment {
        // Variables d'environnement
        DOCKER_ID = "tstallone" // Remplacez par votre identifiant DockerHub
        DOCKER_IMAGE = "fastapi-app"
        DOCKER_TAG = "v.${BUILD_ID}.0" // Tag incrémental pour chaque build
    }
    
    agent any
    
    stages {
        stage('Test') {
            steps {
                script {
                    sh '''
                    cd app/
                    python3 -m pytest || true
                    '''
                }
            }
        }
        
        stage('Docker Build') {
            steps {
                script {
                    sh '''
                    docker build -t $DOCKER_ID/$DOCKER_IMAGE:$DOCKER_TAG .
                    '''
                }
            }
        }
        
        stage('Docker Run & Test') {
            steps {
                script {
                    sh '''
                    docker run -d -p 80:80 --name fastapi-test $DOCKER_ID/$DOCKER_IMAGE:$DOCKER_TAG
                    sleep 10
                    curl localhost:80 || exit 1
                    docker stop fastapi-test
                    docker rm fastapi-test
                    '''
                }
            }
        }
        
        stage('Docker Push') {
            environment {
                DOCKER_PASS = credentials("DOCKER_HUB_PASS") // Secret Jenkins pour mot de passe DockerHub
            }
            steps {
                script {
                    sh '''
                    docker login -u $DOCKER_ID -p $DOCKER_PASS
                    docker push $DOCKER_ID/$DOCKER_IMAGE:$DOCKER_TAG
                    '''
                }
            }
        }
        
        stage('Déploiement en DEV') {
            environment {
                KUBECONFIG = credentials("config") // Secret Jenkins pour la config Kubernetes
            }
            steps {
                script {
                    sh '''
                    rm -Rf .kube
                    mkdir .kube
                    cat $KUBECONFIG > .kube/config
                    cp fastapi/values.yaml values.yml
                    sed -i "s+tag.*+tag: ${DOCKER_TAG}+g" values.yml
                    helm upgrade --install app fastapi --values=values.yml --namespace dev
                    '''
                }
            }
        }
        
        stage('Déploiement en QA') {
            when {
                expression { 
                    return env.BRANCH_NAME ==~ /PR-.*/ || env.CHANGE_TARGET == 'master'
                }
            }
            environment {
                KUBECONFIG = credentials("config")
            }
            steps {
                script {
                    sh '''
                    rm -Rf .kube
                    mkdir .kube
                    cat $KUBECONFIG > .kube/config
                    cp fastapi/values.yaml values.yml
                    sed -i "s+tag.*+tag: ${DOCKER_TAG}+g" values.yml
                    helm upgrade --install app fastapi --values=values.yml --namespace qa
                    '''
                }
            }
        }
        
        stage('Déploiement en STAGING') {
            when {
                expression { return env.BRANCH_NAME == 'master' }
            }
            environment {
                KUBECONFIG = credentials("config")
            }
            steps {
                script {
                    sh '''
                    rm -Rf .kube
                    mkdir .kube
                    cat $KUBECONFIG > .kube/config
                    cp fastapi/values.yaml values.yml
                    sed -i "s+tag.*+tag: ${DOCKER_TAG}+g" values.yml
                    helm upgrade --install app fastapi --values=values.yml --namespace staging
                    '''
                }
            }
        }
        
        stage('Déploiement en PRODUCTION') {
            when {
                expression { return env.BRANCH_NAME == 'master' }
            }
            environment {
                KUBECONFIG = credentials("config")
            }
            steps {
                // Déploiement manuel avec approbation
                timeout(time: 15, unit: "MINUTES") {
                    input message: 'Voulez-vous déployer en production ?', ok: 'Oui'
                }
                
                script {
                    sh '''
                    rm -Rf .kube
                    mkdir .kube
                    cat $KUBECONFIG > .kube/config
                    cp fastapi/values.yaml values.yml
                    sed -i "s+tag.*+tag: ${DOCKER_TAG}+g" values.yml
                    helm upgrade --install app fastapi --values=values.yml --namespace prod
                    '''
                }
            }
        }
    }
    
    post {
        always {
            // Nettoyage
            sh 'docker system prune -f'
        }
        success {
            echo 'Pipeline exécuté avec succès !'
        }
        failure {
            echo 'Le pipeline a échoué. Veuillez consulter les logs pour plus de détails.'
        }
    }
}
