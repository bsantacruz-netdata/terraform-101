##### Security VPC #####

output "security_gwlb_service_name" {
  description = "The AWS Service Name of the created GWLB, which is suitable to use for subsequent VPC Endpoints."
  value       = module.security_gwlb.endpoint_service.service_name
}

output "tgw_attach_subnets" {
  value = module.security_subnet_sets["sn-aws-interno-tgw-attach-pdn"]
}