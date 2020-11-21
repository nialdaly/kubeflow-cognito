#!/bin/sh

# Removes generated artifacts from the sh deploy_kubeflow.sh command
rm -rf mlplatform/.cache
rm -rf mlplatform/aws_config
rm -rf mlplatform/kustomize
rm -rf mlplatform/kubeflow_manifest.yaml