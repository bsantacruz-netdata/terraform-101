#####################################################################################
################################## GENERAL VARIABLES ################################
#####################################################################################

// Panorama Versions
// az vm image list -o table --all --publisher paloaltonetworks --offer panorama
// aws ec2 describe-images --filters "Name=product-code,Values=eclz7j04vu9lf8ont8ta3n17o" "Name=name,Values=Panorama-AWS*" --output json --query "Images[].Description" | grep -o 'Panorama-AWS-.*' | tr -d '",'
// oci compute pic version get --listing-id ocid1.appcataloglisting.oc1..aaaaaaaahy22aftxkgxhkgy5ydrhyn4qm5iihdbkpddxp2dlvg2wp6wai67q --resource-version 10.1.5-h1

global_tags = {
  Ambiente    = "QA",
  Descripcion = "Deployed by Terraform"
  Proyecto    = "Terraform 101"
}

panorama_version = "10.1.6"

#####################################################################################
#################################### AWS VARIABLES ##################################
#####################################################################################

region = "us-east-1"

## Transit gateway 

tgw_id = "tgw-0707a08e993f8ece1"