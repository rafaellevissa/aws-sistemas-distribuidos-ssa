#!/bin/bash

aws cloudformation deploy --template-file ./iac/infrastructure.yaml --stack-name aws-sistemas-distribuidos-ssa --capabilities CAPABILITY_NAMED_IAM