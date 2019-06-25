pipeline {
    agent {
        label 'att-corpjenkins02'
    }
    environment {
        PATH = "/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/local/sbin"
        LANG = "en_US.UTF-8"
        DEVELOPER_DIR = "/Applications/Xcode-${Xcode_Version}.app/Contents/Developer"
    }
    post {
        success {
            junit 'build/reports/junit.xml'
        }
    }
    stages {
        stage('Update Package') {
            steps {
                sh 'swift package update'
            }
        }
        stage('Mac Generate Xcode') {
            steps {
                sh 'swift package generate-xcodeproj'
            }
        }
        stage('Build and Test') {
            steps {
                script {
                    xcodeproj = sh(
                        script: 'echo *.xcodeproj',
                        returnStdout: true
                    ).trim()
                }
                sh """
                xcodebuild \
                -project ${ xcodeproj } \
                -scheme Run \
                -configuration Release \
                -destination 'platform=macOS' \
                clean \
                build \
                test \
                | xcpretty -r junit
                """
            }
        }
        stage('Release') {
            when {
                expression { params.SHOULD_DEPLOY == true }
            }
            steps {
                sh 'rm -rf releases'
                sh 'mkdir releases'
                sh 'mkdir releases/${Release_Version}'

                sh """
                cat Sources/Source/App.swift | \
                awk -v tag="${Release_Version}" '/let version = "master"/ { printf "let version = \\"%s\\"\\n", tag; next } 1' > tmp && \
                mv tmp Sources/Source/App.swift
                """

                sh 'swift build -c release'
                sh 'cp .build/release/SwiftyScripts releases/${Release_Version}'
                sh 'cd releases; tar czf ${Release_Version}.tar.gz ${Release_Version}'
                sh 'cd releases; echo Go to https://bitbucket.org/kevcodex/tm-homebrew-tap/src/master/ and create a new brew file. Replace the sha256 with the new sha256 below and create a new url path for the tar ball > tmp.txt'
                sh 'cd releases; shasum -a 256 ${Release_Version}.tar.gz | cut -d " " -f 1 >> tmp.txt'

                sh 'git reset --hard HEAD'
                echo 'TODO: generate brew formula'
                archiveArtifacts artifacts: 'releases/*.tar.gz, releases/*.txt', fingerprint: true
            }
        }
    }
}
