# Creating a VPC in aws with openvpn access
This terraform setup will deploy an openvpn server with certs signed by letsencrypt that gives the user access to a VPC that has a public and private subnet. Based on this, it's easy to set up a lab that other devices can be deployed to.

Ultimately this is a combination of a bunch of older terraform tutorials that no longer work/weren't quite what I was looking for, hopefully it'll help someone do something cool!

## Usage
1. Create a Identity on amazon eith full ec2 and route53 permissions
2. Export the access key and secret access key as follows:
```bash
export AWS_ACCESS_KEY_ID="whateveryouraccesskeyis"
export AWS_SECRET_ACCESS_KEY="whateveryoursecretaccesskeyis"
```

3. Create a route53 hosted zone with whatever domain you'd like to use. If you already have a domain registered with a service provider, it'd possible to use that, otherwise, it's definitely easiest to register one with amazon.

4. Generate an RSA keypair in the terraform folder using `ssh-keygen -f mykeypairname`

5. Fill in the relavent fields in the terraform.tfvars file, make sure that if you change your zone you update the ami

6. run `terraform init` and `terraform apply` to spin everything up, `terraform plan` before terraform apply will let you see what's happening before you make a horrible mistake.

## Variables
In the terraform.tfvars file, all the variables you'd normally want to change, as well as those you might not want to are detailed. Make sure you take a look at where these fit in before changing them!
