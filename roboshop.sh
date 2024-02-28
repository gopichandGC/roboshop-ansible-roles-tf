#!/bin/bash

AMI=ami-0f3c7d07486cad139
SG_ID=sg-0523f705109b77eaa
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "web")
ZONE_ID=Z01392352BS5MX7GMAHS1
DOMAIN_NAME="techwithgopi.online"

for i in "${INSTANCES[@]}"
do
    if [ $i == "mongodb" ] || [ $i == "mysql" ] || [ $i == "shipping" ]
    then
         INSTANCE_TYPE="t3.small"
    else
         INSTANCE_TYPE="t2.micro"
    fi
    
    IP_ADDRESS=$(aws ec2 run-instances --image-id $AMI --instance-type $INSTANCE_TYPE --security-group-ids $SG_ID --tag-specifications "ResourceType=instance, Tags=[{Key=Name,Value=$i}]" --query 'Instances[0].PrivateIpAddress' --output text)

    echo "$i: $IP_ADDRESS"

#Creating new R53 record, Make sure you delete the existing record
  aws route53 change-resource-record-sets \
  --hosted-zone-id $ZONE_ID \
  --change-batch '
  {
    "Comment": "Testing creating a record set"
    ,"Changes": [{
      "Action"              : "UPSERT" 
      ,"ResourceRecordSet"  : {
        "Name"              : "'$i'.'$DOMAIN_NAME'"
        ,"Type"             : "A"
        ,"TTL"              : 1
        ,"ResourceRecords"  : [{
            "Value"         : "'$IP_ADDRESS'"
        }]
    }
    }]
  }
  '
done

## UPSERT: If a resource set doesn't exist, Route 53 creates it. 
#If a resource set exists Route 53 updates it with the values in the request.