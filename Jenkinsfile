properties(
    [
        githubProjectProperty(
            displayName: 'docker-dependency-track-exporter/',
            projectUrlStr: 'https://github.com/ruepp-jenkins/docker-dependency-track-exporter/'
        ),
        disableConcurrentBuilds(abortPrevious: true)
    ]
)

pipeline {
    agent {
        label 'docker'
    }

    environment {
        IMAGE_FULLNAME = 'ruepp/dependency-track-exporter'
        DOCKER_API_PASSWORD = credentials('DOCKER_API_PASSWORD')
        DEPENDENCYTRACK_HOST = 'http://172.20.89.2:8080'
        DEPENDENCYTRACK_API_TOKEN = credentials('dependencychecker')
    }

    triggers {
        URLTrigger(
            cronTabSpec: '0 H/4 * * *',
            entries: [
                URLTriggerEntry(
                    url: 'https://api.github.com/repos/jetstack/dependency-track-exporter/commits/main',
                    contentTypes: [
                        JsonContent(
                            [
                                JsonContentEntry(jsonPath: '$.commit.author.date')
                            ]
                        )
                    ]
                )
            ]
        )
    }

    stages {
        stage('Pre Cleanup') {
            steps {
                cleanWs()
            }
        }
        stage('Checkout') {
            steps {
                git branch: env.BRANCH_NAME,
                url: env.GIT_URL
            }
        }
        stage('Build') {
            steps {
                sh 'chmod +x scripts/*.sh'
                sh './scripts/start.sh'
            }
        }
        stage('SBOM generation') {
            steps {
                sh "docker run --rm --network Internal -v /opt/docker/jenkins/jenkins_ws:/home/jenkins/workspace aquasec/trivy image --format cyclonedx --output ${WORKSPACE}/bom.xml --scanners vuln,secret ${IMAGE_FULLNAME}:latest"
            }
        }
        stage('DependencyTracker') {
            steps {
                script {
                    // root project body
                    def body = groovy.json.JsonOutput.toJson([
                        name: "${env.JOB_NAME}",
                        classifier: "NONE",
                        collectionLogic: "AGGREGATE_LATEST_VERSION_CHILDREN"
                    ])

                    // create root project
                    httpRequest contentType: 'APPLICATION_JSON',
                        httpMode: 'PUT',
                        customHeaders: [
                            [name: 'X-Api-Key', value: env.DEPENDENCYTRACK_API_TOKEN, maskValue: true]
                        ],
                        requestBody: body,
                        url: "${DEPENDENCYTRACK_HOST}/api/v1/project",
                        validResponseCodes: '200:299,409' // 409: project already exist
                }

                dependencyTrackPublisher(
                    artifact: 'bom.xml',
                    projectName: env.JOB_NAME,
                    projectVersion: env.BUILD_NUMBER,
                    synchronous: true,
                    projectProperties: [
                        isLatest: true,
                        parentName: env.JOB_NAME,
                        tags: ['image']
                    ]
                )
            }
        }
    }

    post {
        always {
            discordSend result: currentBuild.currentResult,
                description: env.GIT_URL,
                link: env.BUILD_URL,
                title: JOB_NAME,
                webhookURL: DISCORD_WEBHOOK
        }
    }
}
