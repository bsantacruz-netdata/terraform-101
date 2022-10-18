# terraform-101
Curso de Terraform para integrantes de NETDATA

## demo-aws-basics

Este template de `terraform` se trae una VPC existente, y sobre esta VPC despliegue un Internet Gateway, una Subnet y una Route Table, usando autenticación via `aws cli` con el perfil por defecto.

```
main.tf
outputs.tf
```

## demo-aws-modules

Este template de `terraform` usa modulos para desplegar la infraestructura en AWS. El primer módulo ( `aws-network`) despliega infraestructura que tenga que ver con redes (VPC, Internet Gateway, Transit Gateway) y el segundo módulo (`aws-panorama`) despliega la infraestructura para un Panorama, usando autenticación via `aws cli` con el perfil por defecto.

```
modules/
root.tf
outputs.tf
```

## demo-azure

Este template de `terraform` despliega una web app contenerizada en una máquina virtual en Azure con todos sus componentes (VNET, Subnets, NSGs, etc). Este despliegue se realiza autenticando `terraform` via Service Principal de Azure, sin embargo también es posible la autenticación via `az cli`.

```
main.tf
```