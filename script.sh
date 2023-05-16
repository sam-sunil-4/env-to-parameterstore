#!/bin/bash

CHK1=$(which aws)
if [ -z $CHK1 ]
then
	echo "AWS CLI is not installed Please install aws cli first"
	exit
fi

echo "Please enter the name of your AWS profile : "
read AWSPROF

CHK2=$(cat ~/.aws/credentials | grep -w $AWSPROF)
if [ -z $CHK2 ]
then
	echo "AWS PROFILE NAMED $AWSPROF NOT FOUND"
	while true; do
		read -p "Do you want to configure your aws profile now? (Y/N) " yn
		case $yn in
			[yY] ) echo Proceeding;
			       read -p "Please enter a name for your profile" AWSPROFILENAME
			       aws configure --profile=$AWSPROFILENAME
			       echo exporting the configured profile to use.
			       export AWS_PROFILE=$AWSPROFILENAME
				break;;
			[nN] ) echo Exiting;
				exit;;
			*) echo Enter y or n;;
		esac
	done
else
	echo "Found a profile with the provided name. Exporting this now.."
	export AWS_PROFILE=$AWSPROF
fi

read -p "Please enter the prefix for your parameter store name(No need of / symbol) : " PREFIX
while read LINE
do
	NAME=$(echo "$LINE" | cut -d= -f1 | cut -d'"' -f2)
	VALUE=$(echo "$LINE" | cut -d= -f2 | cut -d'"' -f2)
	PUT=$(aws ssm put-parameter --name "/$PREFIX/$NAME" --type "String" --value "$VALUE" 2>&1)
	if [[ ! -z $(echo $PUT | grep -w "ParameterAlreadyExists") ]]
	then
		echo "Parameter exists"
	else
		if [[ -z $(echo $PUT | grep -w "{ "Version": 1, "Tier": "Standard" }") ]]
		then
			echo "Parameter with /$PREFIX/$NAME is successfully added"
		fi
	fi
done < .env
