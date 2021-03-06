#!/bin/bash
# Purpose: Automated Deployment Via cloudformation for vpc,eks,alb ingress
# Maintainer: Muhammad Asim

# Update me

Region="us-east-1"
VpcCIDR="10.10.0.0/21"
PublicSubnets="10.10.0.0/24,10.10.1.0/24,10.10.2.0/24"
PrivateSubnets="10.10.3.0/24,10.10.4.0/24,10.10.5.0/24"
SSHKey="asim"
StackName="cloudgeeksca-cluster-eks"
Bucket="cloudgeeksca-deployment-update"
EnableVPCPeering="false"
EnvType="dev"

export AWS_DEFAULT_REGION=${Region}


# Fix
YAML="vpc.yaml"
Name="$StackName"



echo '
---
AWSTemplateFormatVersion: '2010-09-09'
Description: Basic VPC
Mappings:
  ARNNamespace:
    us-east-1:
      Partition: aws
    us-east-2:
      Partition: aws
    us-west-2:
      Partition: aws
    us-west-1:
      Partition: aws
    us-east-1:
      Partition: aws
    eu-central-1:
      Partition: aws
    ap-southeast-1:
      Partition: aws
    ap-northeast-1:
      Partition: aws
    ap-southeast-2:
      Partition: aws
    sa-east-1:
      Partition: aws
    us-gov-west-1:
      Partition: aws-us-gov
  S3Region:
    us-east-1:
      Region: us-east-1
    us-east-2:
      Region: us-east-2
    us-west-2:
      Region: us-east-1
    us-west-1:
      Region: us-east-1
    us-east-1:
      Region: us-east-1
    eu-central-1:
      Region: us-east-1
    ap-southeast-1:
      Region: us-east-1
    ap-northeast-1:
      Region: us-east-1
    ap-southeast-2:
      Region: us-east-1
    sa-east-1:
      Region: us-east-1
    us-gov-west-1:
      Region: us-gov-west-1
Parameters:
  Name:
    Type: String
    Description: Name references build template for automation
  Region:
    Type: String
  Bucket:
    Type: String
    Default: cloudgeeksca-deployment
  DeployBucketPrefix:
    Type: String
    Default: ""
  EnableVPCPeering:
    Type: String
    Default: false
    AllowedValues: ['false', 'true']
  VpcCIDR:
    Type: String
    Default: 10.10.0.0/21
  PublicSubnets:
    Type: CommaDelimitedList
    Description: List of 3 subnets
    Default: 10.10.0.0/24,10.10.1.0/24,10.10.2.0/24
  PrivateSubnets:
    Type: CommaDelimitedList
    Description: List of 3 Subnets
    Default: 10.10.3.0/24,10.10.4.0/24,10.10.5.0/24
  EnvType:
    Type: String
  SSHKey:
    Type: AWS::EC2::KeyPair::KeyName
    Default: devops
Conditions:
  CreatePeer: !Equals [ !Ref EnableVPCPeering, true]
Resources:
  Vpc:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: !Ref VpcCIDR
      EnableDnsSupport: 'true'
      EnableDnsHostnames: 'true'
      Tags:
        - Key: Name
          Value:
            Ref: AWS::StackName
        - Key: kubernetes.io/role/elb
          Value: shared
        - Key: alpha.eksctl.io/cluster-name
          Value: !Sub "${AWS::StackName}"
        - Key: eksctl.cluster.k8s.io/v1alpha1/cluster-name
          Value: !Sub "${AWS::StackName}"

  InternetGateway:
    Type: AWS::EC2::InternetGateway

  AttachGateway:
    Type: AWS::EC2::VPCGatewayAttachment
    Properties:
      VpcId:
        Ref: Vpc
      InternetGatewayId:
        Ref: InternetGateway

  PubSubnetAz1:
    Type: AWS::EC2::Subnet
    Properties:
      MapPublicIpOnLaunch: true
      VpcId:
        Ref: Vpc
      CidrBlock: !Select [0, !Ref PublicSubnets]
      AvailabilityZone:
        Fn::Select:
          - '0'
          - Fn::GetAZs:
              Ref: AWS::Region
      Tags:
        - Key: Name
          Value: !Sub ${AWS::StackName} Public Subnet (AZ1)
        - Key: alpha.eksctl.io/cluster-name
          Value: !Sub "${AWS::StackName}"
        - Key: eksctl.cluster.k8s.io/v1alpha1/cluster-name
          Value: !Sub "${AWS::StackName}"
        - Key: kubernetes.io/role/elb
          Value: 1
        - Key: Public-Subnet-AZ1
          Value: !Sub ${AWS::StackName}-Public-Subnet-AZ1


  PubSubnetAz2:
    Type: AWS::EC2::Subnet
    Properties:
      MapPublicIpOnLaunch: true
      VpcId:
        Ref: Vpc
      CidrBlock: !Select [1, !Ref PublicSubnets]
      AvailabilityZone:
        Fn::Select:
          - '1'
          - Fn::GetAZs:
              Ref: AWS::Region
      Tags:
        - Key: Name
          Value: !Sub ${AWS::StackName} Public Subnet (AZ2)
        - Key: alpha.eksctl.io/cluster-name
          Value: !Sub "${AWS::StackName}"
        - Key: eksctl.cluster.k8s.io/v1alpha1/cluster-name
          Value: !Sub "${AWS::StackName}"
        - Key: kubernetes.io/role/elb
          Value: 1
        - Key: Public-Subnet-AZ2
          Value: !Sub ${AWS::StackName}-Public-Subnet-AZ2

  PubSubnetAz3:
    Type: AWS::EC2::Subnet
    Properties:
      MapPublicIpOnLaunch: true
      VpcId:
        Ref: Vpc
      CidrBlock: !Select [2, !Ref PublicSubnets]
      AvailabilityZone:
        Fn::Select:
          - '2'
          - Fn::GetAZs:
              Ref: AWS::Region
      Tags:
        - Key: Name
          Value: !Sub ${AWS::StackName} Public Subnet (AZ3)
        - Key: alpha.eksctl.io/cluster-name
          Value: !Sub "${AWS::StackName}"
        - Key: eksctl.cluster.k8s.io/v1alpha1/cluster-name
          Value: !Sub "${AWS::StackName}"
        - Key: kubernetes.io/role/elb
          Value: 1
        - Key: Public-Subnet-AZ3
          Value: !Sub ${AWS::StackName}-Public-Subnet-AZ3

  PrivSubnetAz1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId:
        Ref: Vpc
      CidrBlock: !Select [0, !Ref PrivateSubnets]
      AvailabilityZone:
        Fn::Select:
          - '0'
          - Fn::GetAZs:
              Ref: AWS::Region
      Tags:
        - Key: Name
          Value: !Sub ${AWS::StackName} Private Subnet (AZ1)
        - Key: alpha.eksctl.io/cluster-name
          Value: !Sub "${AWS::StackName}"
        - Key: eksctl.cluster.k8s.io/v1alpha1/cluster-name
          Value: !Sub "${AWS::StackName}"
        - Key: kubernetes.io/role/elb
          Value: 1
        - Key: Private-Subnet-AZ1
          Value: !Sub ${AWS::StackName}-Private-Subnet-AZ1

  PrivSubnetAz2:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId:
        Ref: Vpc
      CidrBlock: !Select [1, !Ref PrivateSubnets]
      AvailabilityZone:
        Fn::Select:
          - '1'
          - Fn::GetAZs:
              Ref: AWS::Region
      Tags:
        - Key: Name
          Value: !Sub ${AWS::StackName} Private Subnet (AZ2)
        - Key: alpha.eksctl.io/cluster-name
          Value: !Sub "${AWS::StackName}"
        - Key: eksctl.cluster.k8s.io/v1alpha1/cluster-name
          Value: !Sub "${AWS::StackName}"
        - Key: kubernetes.io/role/elb
          Value: 1
        - Key: Private-Subnet-AZ2
          Value: !Sub ${AWS::StackName}-Private-Subnet-AZ2

  PrivSubnetAz3:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId:
        Ref: Vpc
      CidrBlock: !Select [2, !Ref PrivateSubnets]
      AvailabilityZone:
        Fn::Select:
          - '2'
          - Fn::GetAZs:
              Ref: AWS::Region
      Tags:
        - Key: Name
          Value: !Sub ${AWS::StackName} Private Subnet (AZ3)
        - Key: alpha.eksctl.io/cluster-name
          Value: !Sub "${AWS::StackName}"
        - Key: eksctl.cluster.k8s.io/v1alpha1/cluster-name
          Value: !Sub "${AWS::StackName}"
        - Key: kubernetes.io/role/elb
          Value: 1
        - Key: Private-Subnet-AZ3
          Value: !Sub ${AWS::StackName}-Private-Subnet-AZ3


  NatGateway1EIP:
    Type: AWS::EC2::EIP
    DependsOn: AttachGateway
    Properties:
      Domain: vpc

  NatGateway2EIP:
    Type: AWS::EC2::EIP
    DependsOn: AttachGateway
    Properties:
      Domain: vpc

  NatGateway3EIP:
    Type: AWS::EC2::EIP
    DependsOn: AttachGateway
    Properties:
      Domain: vpc

  NatGateway1:
    Type: AWS::EC2::NatGateway
    Properties:
      AllocationId: !GetAtt NatGateway1EIP.AllocationId
      SubnetId: !Ref PubSubnetAz1

  NatGateway2:
    Type: AWS::EC2::NatGateway
    Properties:
      AllocationId: !GetAtt NatGateway2EIP.AllocationId
      SubnetId: !Ref PubSubnetAz2

  NatGateway3:
    Type: AWS::EC2::NatGateway
    Properties:
      AllocationId: !GetAtt NatGateway3EIP.AllocationId
      SubnetId: !Ref PubSubnetAz3

  PublicRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref Vpc
      Tags:
        - Key: Name
          Value: !Sub ${AWS::StackName} Public Routes
        - Key: alpha.eksctl.io/cluster-name
          Value: !Sub "${AWS::StackName}"
        - Key: eksctl.cluster.k8s.io/v1alpha1/cluster-name
          Value: !Sub "${AWS::StackName}"

  DefaultPublicRoute:
    Type: AWS::EC2::Route
    DependsOn: AttachGateway
    Properties:
      RouteTableId: !Ref PublicRouteTable
      DestinationCidrBlock: 0.0.0.0/0
      GatewayId: !Ref InternetGateway

  PublicSubnet1RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PublicRouteTable
      SubnetId: !Ref PubSubnetAz1

  PublicSubnet2RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PublicRouteTable
      SubnetId: !Ref PubSubnetAz2

  PublicSubnet3RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PublicRouteTable
      SubnetId: !Ref PubSubnetAz3

  PrivateRouteTable1:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref Vpc
      Tags:
        - Key: Name
          Value: !Sub ${AWS::StackName} Private Routes (AZ1)
        - Key: alpha.eksctl.io/cluster-name
          Value: !Sub "${AWS::StackName}"
        - Key: eksctl.cluster.k8s.io/v1alpha1/cluster-name
          Value: !Sub "${AWS::StackName}"

  DefaultPrivateRoute1:
    Type: AWS::EC2::Route
    Properties:
      RouteTableId: !Ref PrivateRouteTable1
      DestinationCidrBlock: 0.0.0.0/0
      NatGatewayId: !Ref NatGateway1

  PrivateSubnet1RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PrivateRouteTable1
      SubnetId: !Ref PrivSubnetAz1

  PrivateRouteTable2:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref Vpc
      Tags:
        - Key: Name
          Value: !Sub ${AWS::StackName} Private Routes (AZ2)
        - Key: alpha.eksctl.io/cluster-name
          Value: !Sub "${AWS::StackName}"
        - Key: eksctl.cluster.k8s.io/v1alpha1/cluster-name
          Value: !Sub "${AWS::StackName}"

  DefaultPrivateRoute2:
    Type: AWS::EC2::Route
    Properties:
      RouteTableId: !Ref PrivateRouteTable2
      DestinationCidrBlock: 0.0.0.0/0
      NatGatewayId: !Ref NatGateway2

  PrivateSubnet2RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PrivateRouteTable2
      SubnetId: !Ref PrivSubnetAz2

  PrivateRouteTable3:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref Vpc
      Tags:
        - Key: Name
          Value: !Sub ${AWS::StackName} Private Routes (AZ3)
        - Key: alpha.eksctl.io/cluster-name
          Value: !Sub "${AWS::StackName}"
        - Key: eksctl.cluster.k8s.io/v1alpha1/cluster-name
          Value: !Sub "${AWS::StackName}"

  DefaultPrivateRoute3:
    Type: AWS::EC2::Route
    Properties:
      RouteTableId: !Ref PrivateRouteTable3
      DestinationCidrBlock: 0.0.0.0/0
      NatGatewayId: !Ref NatGateway3

  PrivateSubnet3RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      RouteTableId: !Ref PrivateRouteTable3
      SubnetId: !Ref PrivSubnetAz3

  NoIngressSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupName: "no-ingress-sg"
      GroupDescription: "Security group with no ingress rule"
      VpcId: !Ref Vpc

  VPCPeeringConnection:
    Type: 'AWS::EC2::VPCPeeringConnection'
    Condition: CreatePeer
    Properties:
      VpcId: !Ref Vpc
      PeerVpcId: vpc-283cac51
      PeerRegion: us-east-1
      Tags:
        - Key: Name
          Value: !Sub ${AWS::StackName} peer with Main_Production

Outputs:
  VpcID:
    Description: Created VPC ID
    Value:
      Ref: Vpc
    Export:
      Name: !Sub ${AWS::StackName}-VpcID
  PublicSubnetAz1:
    Description: Public Subnet AZ1 created in VPC
    Value:
      Ref: PubSubnetAz1
  PublicSubnetAz2:
    Description: Public Subnet AZ2 created in VPC
    Value:
      Ref: PubSubnetAz2
  PublicSubnetAz3:
    Description: Public Subnet AZ2 created in VPC
    Value:
      Ref: PubSubnetAz3
  PrivateSubnetAz1:
    Description: Private Subnet AZ1 created in VPC
    Value:
      Ref: PrivSubnetAz1
  PrivateSubnetAz2:
    Description: Private Subnet AZ2 created in VPC
    Value:
      Ref: PrivSubnetAz2
  PrivateSubnetAz3:
    Description: Private Subnet AZ2 created in VPC
    Value:
      Ref: PrivSubnetAz3
  PublicSubnetGroup:
    Value: !Sub ${PubSubnetAz1},${PubSubnetAz2},${PubSubnetAz3}
    Export:
      Name: !Sub ${AWS::StackName}-PublicSubnetGroup
  PrivateSubnetGroup:
    Value: !Sub ${PrivSubnetAz1},${PrivSubnetAz2},${PrivSubnetAz3}
    Export:
      Name: !Sub ${AWS::StackName}-PrivateSubnetGroup
  VpcCidr:
    Description: VPC network block
    Value: !Ref VpcCIDR
    Export:
      Name: !Sub ${AWS::StackName}-VpcCidr
  StackName:
    Description: Output Stack Name
    Value: !Ref AWS::StackName
  Region:
    Description: Stack location
    Value: !Ref AWS::Region
 ' > $YAML


 # Parameters

 cat << EOF > parameters.json
 [
  {
    "ParameterKey": "Bucket",
    "ParameterValue": "$Bucket"
    },
   {
     "ParameterKey": "EnableVPCPeering",
     "ParameterValue": "$EnableVPCPeering"
    },
    {
      "ParameterKey": "EnvType",
      "ParameterValue": "$EnvType"
    },
    {
      "ParameterKey": "PrivateSubnets",
     "ParameterValue": "$PrivateSubnets"
     },
    {
    "ParameterKey": "PublicSubnets",
    "ParameterValue": "$PublicSubnets"
    },
    {
    "ParameterKey": "Region",
    "ParameterValue": "$Region"
    },
    {
    "ParameterKey": "SSHKey",
    "ParameterValue": "$SSHKey"
    },
    {
    "ParameterKey": "VpcCIDR",
    "ParameterValue": "$VpcCIDR"
    },
    {
     "ParameterKey": "Name",
    "ParameterValue": "$Name"
    }


]
EOF



# Creating a key pair for EC2 Workers Nodes

mkdir ~/.ssh 2>&1 >/dev/null

aws ec2 create-key-pair --key-name $SSHKey --query 'KeyMaterial' --output text > ~/.ssh/$SSHKey.pem


# Create VPC Stack via Cloudformation
aws cloudformation create-stack --stack-name ${StackName} --template-body file://${YAML} --parameters file://parameters.json


# aws cloudformation delete-stack --stack-name cloudgeeksca-cluster-eks --region us-east-1
# END


# Example

#!/usr/bin/env bash

STACK_NAME=$1

if [ -z "$1" ]
  then
    echo "No STACK_NAME argument supplied"
    exit 1
fi

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Creating stack..."
STACK_ID=$( \
  aws cloudformation create-stack \
  --stack-name ${STACK_NAME} \
  --template-body file://${DIR}/cron-batch-stack.yml \
  --capabilities CAPABILITY_IAM \
  --parameters file://${DIR}/parameters.json \
  --tags file://${DIR}/tags.json \
  | jq -r .StackId \
)

echo "Waiting on ${STACK_ID} create completion..."
aws cloudformation wait stack-create-complete --stack-name ${STACK_ID}
aws cloudformation describe-stacks --stack-name ${STACK_ID} | jq .Stacks[0].Outputs





# Parameters.json

[
  {
    "ParameterKey": "MyFooParam",
    "ParameterValue": "bar"
  }
]


# tags.json

[
  {
    "Key": "app",
    "Value": "myapp"
  },
  {
    "Key": "team",
    "Value": "myteam"
  },
  {
    "Key": "env",
    "Value": "dev"
  },
  {
    "Key": "created_by",
    "Value": "nackjicholson"
  }
]


