#!/usr/bin/env groovy
pipeline {
  agent {
    label 'commonslave'
  }

  stages {
    stage('Prepare') {
      steps {
        step([$class: 'WsCleanup'])
        checkout(scm)
        sh("make clean test")
      }
    }
    stage('Build artefact') {
      steps {
        sh('make clean build')
      }
    }
    stage('Upload to s3') {
      steps {
        sh("""
           make push-s3 S3_BUCKET=txm-lambda-functions-tools
           """)
      }
    }
  }
}

