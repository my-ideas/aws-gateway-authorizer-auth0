#!/usr/bin/env bash

# USAGE ./turbodeploy <create|update|deps> [stageName]

FUNC="authorizer-auth0"
HANDLER="handler.auth"
BUILDZIP="./$FUNC.zip"

if [ -z "$2" ]; then STAGE="dev_$(whoami)"; else STAGE=$2; fi
echo "action $1 on using stage $STAGE"

function build {
    echo "Remove existing artifact"
    [ -e "$BUILDZIP" ] && rm $BUILDZIP

    echo "Building artifact "

    zip -r $BUILDZIP ./ --exclude=*.git* --exclude=*node_modules_local*
    echo "Deploying $FUNC to Lambda"
}
function update {
    build

    echo "Updating lambda"
    lambdav=$(aws lambda update-function-code    \
    --region eu-central-1 \
    --function-name $FUNC \
    --zip-file fileb://$BUILDZIP\
    --publish | python -c "import sys, json; print(json.load(sys.stdin)['Version'])")

    echo "Updating the alias"
    aws lambda update-alias \
    --region eu-central-1 \
     --function-name $FUNC \
     --function-version $lambdav \
     --name $STAGE \
     --description "turbodeploy - Alias for $STAGE"
}

function create {

    build

    echo "Creating a new Lambda $FUNC handler $HANDLER"

    lambdav=$(aws lambda create-function \
    --region eu-central-1 \
    --function-name $FUNC \
    --zip-file fileb://$BUILDZIP \
    --role arn:aws:iam::645244340892:role/lambda-kotenna \
    --handler $HANDLER \
    --runtime nodejs4.3 \
    --description 'Kotenna REST API for porketta' \
    --environment Variables=\{auth0_client_id=j2oLMgtxbnEfooQYu79SY4ys25NPyRxU,auth0_client_secret=zmKF6YAHJyC9fEpdycXvj0NQiaJwXXNlRdKGEBnLRJU38tbvu52tOUBymebTxqkj\} \
    --publish \
    --memory-size 128 \
    --timeout 300 | python -c "import sys, json; print(json.load(sys.stdin)['Version'])")

    aws lambda create-alias \
     --region eu-central-1 \
     --function-name $FUNC \
     --function-version $lambdav \
     --name $STAGE \
     --description "turbodeploy - Alias for $STAGE"
}

function buildDeps {
    echo "Deleting existing node_modules folder"
    docker run -it -v "$PWD":/var/task lambci/lambda:build-nodejs6.10 npm install --save
    mv node_modules node_modules_aws
}



echo $1
case $1 in
    create)
    create
    ;;
    update)
    update
    ;;
    deps)
    buildDeps
    ;;
esac

# Update the permissions (probably only once?(
# aws lambda add-permission --function-name arn:aws:lambda:eu-central-1:645244340892:function:kotenna-rest:dev_doninell --source-arn 'arn:aws:execute-api:eu-central-1:645244340892:v5kn65r9a0/*/*/' --principal apigateway.amazonaws.com --statement-id 5316760c-9dd6-4380-b42b-ffbcb5cbad84 --action lambda:InvokeFunction --region eu-central-1
# aws lambda add-permission --function-name arn:aws:lambda:eu-central-1:645244340892:function:kotenna-rest:dev_doninell --source-arn 'arn:aws:execute-api:eu-central-1:645244340892:v5kn65r9a0/*/*/vhost/*' --principal apigateway.amazonaws.com --statement-id 3a731ddb-5a45-4173-9076-25e87da22ba3 --action lambda:InvokeFunction --region eu-central-1
# aws lambda add-permission --function-name arn:aws:lambda:eu-central-1:645244340892:function:kotenna-rest:dev_doninell --source-arn 'arn:aws:execute-api:eu-central-1:645244340892:v5kn65r9a0/*/*/vhost' --principal apigateway.amazonaws.com --statement-id f5648128-073a-4f34-889f-158e1184d6d1 --action lambda:InvokeFunction --region eu-central-1



