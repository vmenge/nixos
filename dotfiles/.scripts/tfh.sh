teleport_login() {
  tsh login --proxy=teleport-cluster.orb.internal-tools.worldcoin.dev --auth=okta
}

teleport_mongo() {
  tsh login --proxy=teleport.worldcoin.dev:443 teleport.worldcoin.dev --auth=okta && \
  tsh db connect mongo-atlas-orb-stage --db-user arn:aws:iam::510867353226:role/developer-read-write --db-name admin
}

teleport_mongo_prod() {
  tsh login --proxy=teleport.worldcoin.dev:443 teleport.worldcoin.dev --auth=okta && \
  tsh db connect mongo-atlas-orb-prod --db-user arn:aws:iam::573252405782:role/developer-read-only --db-name iot
}

cloudflare_token() {
  export CLOUDFLARE_TOKEN=$(cloudflared access login management.internal.stage.orb.worldcoin.dev)
}

tfh_docker_login() {
  docker login -u AWS -p $(aws ecr get-login-password --region us-east-1) https://507152310572.dkr.ecr.us-east-1.amazonaws.com
}

tfh_aws_auth_token() {
  aws ecr get-authorization-token --region us-east-1 --output text --query 'authorizationData[].authorizationToken'
}

ssh_hsm() {
  AWS_REGION=us-west-2 aws ssm start-session --target i-07de64952bd161197 --document-name AWS-StartInteractiveCommand --parameters command="/bin/bash"
}

tfh_ec2() {
  AWS_REGION=eu-central-1 aws ssm start-session --target i-08d4a465c27c7a4b2 --document-name AWS-StartInteractiveCommand --parameters command="/bin/bash" --profile orb-dev
}

tfh_aws_login() {
  aws sso login --profile orb-prod --use-device-code
}
