# Test Plan
1. Using this [Vagrantfile](vagrant/Vagrantfile), use Vagrant to build Dev Workstation running Ubuntu 18.04

The post-install includes:
* [configure-hostname.sh](vagrant/sripts/configure-hostname.sh)
* [configure-ntp.sh](vagrant/sripts/configure-ntp.sh)
* [install-terraform-aws.sh](vagrant/sripts/install-terraform-aws.sh)
* [install-replicated-cli.sh](vagrant/scripts/install-replicated-cli.sh)

2. Using [eks-deployer](https://github.com/dyvantage/eks-deployer), use Terraform to build a Kubernetes Cluster (EKS on AWS)

3. Validate a simple 2-Tier Application application (Node.js with Mysql database)

