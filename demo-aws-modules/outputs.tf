output "panoramas_ips" {
  description = "Panoramas IPs"
  value = {
    aws = "${module.aws-panorama.mgmt_ip_address}",
  }
}