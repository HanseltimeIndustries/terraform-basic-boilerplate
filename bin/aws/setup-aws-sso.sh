# This is just an example of commands to run.  Ideally, you can create a session once and then setup different profiles

echo "We will take you through the AWS SSO setup for your particular user that you were granted..."

PROFILE='hanseltime-developer'

aws configure sso --profile $PROFILE

aws configure sso-session --profile $PROFILE

