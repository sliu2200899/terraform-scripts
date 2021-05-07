
## how to run the terraform for digital ocean?
terraform apply -auto-approve \
-var "do_token=${DO_TOKEN}" \
-var "pub_key=/Users/sliu/.ssh/dokey.pub" \
-var "pvt_key=/Users/sliu/.ssh/dokey" \
-var "ssh_fingerprint=$SSH_FINGERPRINT"

## other useful commands 
terraform plan 
terraform destroy
terraform state list
terraform state show resource_name