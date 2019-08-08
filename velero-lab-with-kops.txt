** configure aws user and kops **

  # use aws client to create kops group, assign policies, create kops user, and assign the user to the group
  
  aws iam create-group --group-name kops

  aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess --group-name kops
  aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonRoute53FullAccess --group-name kops
  aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess --group-name kops
  aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/IAMFullAccess --group-name kops
  aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonVPCFullAccess --group-name kops

  aws iam create-user --user-name kops

  aws iam add-user-to-group --user-name kops --group-name kops

  aws iam create-access-key --user-name kops

  # configure the aws client to use your new IAM user
  
  aws configure           # Use your new access and secret key here
  aws iam list-users      # you should see a list of all your IAM users here

  # because "aws configure" doesn't export these vars for kops to use, we export them now
  
  export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
  export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)

  # create kops state store in s3
  
  export BUCKET_NAME=kops-state-store
  aws s3api create-bucket --bucket $BUCKET_NAME --region us-east-1
  aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled
  
** create kops clusters **

  # set your kubeconfig path
  
  export KUBECONFIG=~/.kube/config

  # create "prod" cluster v1.13.5
  
  export ZONE=us-east-1a
  export NAME=prod.k8s.local
  kops create cluster --zones ${ZONE} --name ${NAME}
  
  # edit the cluster and instance group configs to check/specify node sizes, node count, k8s version, etc.
  
  kops edit cluster ${NAME}
  kops edit ig --name ${NAME} nodes
  kops edit ig --name ${NAME} master-us-east-1a
  
  # deploy the cluster
  
  kops update cluster --name ${NAME} --yes
  kops get clusters
  
  # it will take several minutes for everything to come online. eventually, the following will return your nodes.
  
  kubectl get nodes -o wide
  
  # create "staging" cluster v1.14.3
  
  export ZONE=us-east-1a
  export NAME2=staging.k8s.local
  kops create cluster --zones ${ZONE} --name ${NAME2}
  
  # edit the cluster and instance group configs to check/specify node sizes, node count, k8s version, etc.
  
  kops edit cluster ${NAME2}
  kops edit ig --name ${NAME2} nodes
  kops edit ig --name ${NAME2} master-us-east-1a
  
  # deploy the cluster
  
  kops update cluster --name ${NAME2} --yes
  kops get clusters
  
  # it will take several minutes for everything to come online. eventually, the following will return your nodes.
  
  kubectl get nodes -o wide
  
** follow velero install instructions for aws **

  https://velero.io/docs/v1.0.0/aws-config/
  
  # create backup bucket in s3
  
  export BUCKET=dockeryk-backup-store
  export REGION=us-east-1
  aws s3api create-bucket --bucket ${BUCKET} --region ${REGION}
  
  # create the velero iam users (one for each cluster)
  
  aws iam create-user --user-name velero-prod
  aws iam create-user --user-name velero-staging
  
  # create the iam policy file (this will be applied to both users)
  
cat > velero-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeVolumes",
                "ec2:DescribeSnapshots",
                "ec2:CreateTags",
                "ec2:CreateVolume",
                "ec2:CreateSnapshot",
                "ec2:DeleteSnapshot"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:PutObject",
                "s3:AbortMultipartUpload",
                "s3:ListMultipartUploadParts"
            ],
            "Resource": [
                "arn:aws:s3:::${BUCKET}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::${BUCKET}"
            ]
        }
    ]
}
EOF

  # apply the policy file to both users
  
  aws iam put-user-policy --user-name velero-prod --policy-name velero --policy-document file://velero-policy.json
  aws iam put-user-policy --user-name velero-staging --policy-name velero --policy-document file://velero-policy.json
  
  # create iam access keys for both users
  
  aws iam create-access-key --user-name velero-prod
  aws iam create-access-key --user-name velero-staging
  
  # create credential files for both users
  
  touch credentials-velero-prod
  touch credentials-velero-staging
  
  # place the following in each file using the key and secret from the "create access keys" step above
  
[default]
aws_access_key_id=<AWS_ACCESS_KEY_ID>
aws_secret_access_key=<AWS_SECRET_ACCESS_KEY>

  # install velero on prod cluster
  
  kubectl config use-context prod.k8s.local
  
  velero install --provider aws --bucket $BUCKET \
    --secret-file ./credentials-velero-prod \
    --backup-location-config region=$REGION \
    --snapshot-location-config region=$REGION
    
  kubectl -n velero get pods
    
  # install velero on staging cluster
  
  kubectl config use-context staging.k8s.local
  
  velero install --provider aws --bucket $BUCKET \
    --secret-file ./credentials-velero-staging \
    --backup-location-config region=$REGION \
    --snapshot-location-config region=$REGION
    
  kubectl -n velero get pods
  
  # 
  
  
at this point, we have two clusters up and both have velero running in them.
we'll now deploy two apps (one with a persistent volume) to prod, back them up,
and then restore them onto the staging cluster.
