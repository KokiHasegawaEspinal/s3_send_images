#!/bin/bash -x
#DATE OF CREATION: 19/AUGUST/2024
#I MODIFIED THE FILE FROM THIS REPOSITORY: https://gist.github.com/tuxfight3r/7ccbd5abc4ded37ecdbc8fa46966b7e8
#THIS SHELLSCRIPT JUST SEND IMAGES FROM AN DIRECTORY

#S3 parameters
S3KEY="YOUR_KEY"
S3SECRET="YOUR_SECRET_KEY"
S3BUCKET="BUCKET'S_NAME"
S3STORAGETYPE="STANDARD" #DON'T CHANGE
AWSREGION="YOUR_REGION"

# Fixed paths
directory_path="/YOUR/DIRECTORY/PATHS/" #FROM SERVER OR LOCAL
s3_folder_path="/uploads/images/"       #DON'T CHANGE

function putS3
{
  file_path=$1
  aws_path=$2
  bucket="${S3BUCKET}"
  date=$(date -R)
  acl="x-amz-acl:private"
  content_type=$(file --mime-type -b "$file_path")
  storage_type="x-amz-storage-class:${S3STORAGETYPE}"

  # Remove trailing slash from s3_folder_path if present
  aws_path=$(echo "$aws_path" | sed 's:/*$::')

  # Remove trailing slash from file_path if present
  file_name=$(basename "$file_path")

  string="PUT\n\n$content_type\n$date\n$acl\n$storage_type\n/$bucket$aws_path/${file_path##/*/}"
  signature=$(echo -en "${string}" | openssl sha1 -hmac "${S3SECRET}" -binary | base64)
  response=$(curl -s --retry 3 --retry-delay 10 -X PUT -T "$file_path" \
       -H "Host: $bucket.s3.${AWSREGION}.amazonaws.com" \
       -H "Date: $date" \
       -H "Content-Type: $content_type" \
       -H "$storage_type" \
       -H "$acl" \
       -H "Authorization: AWS ${S3KEY}:$signature" \
       "https://$bucket.s3.${AWSREGION}.amazonaws.com$aws_path/${file_path##/*/}")

  if [ $? -ne 0 ]; then
      echo "Error: Failed to upload $file_path to S3"
  else
      echo "Successfully uploaded $file_path to $aws_path"
  fi
}

# Iterate over all files in the directory
for file in "$directory_path" *; do
  if [ -f "$file" ]; then
    putS3 "$file" "$s3_folder_path"
  fi
done