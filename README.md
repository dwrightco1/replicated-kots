# Replicated KOTS Evaluation
Notes from my evaluation of Replicated.Com's KOTS product.

## Test Plan
1. Using this [Vagrantfile](vagrant/Vagrantfile), use Vagrant to build Dev Workstation running Ubuntu 18.04

The post-install for the Vagrant build includes:
* [configure-hostname.sh](vagrant/sripts/configure-hostname.sh)
* [configure-ntp.sh](vagrant/sripts/configure-ntp.sh)
* [install-terraform-aws.sh](vagrant/sripts/install-terraform-aws.sh)
* [install-kubectl.sh](vagrant/sripts/install-terraform-aws.sh)
* [install-replicated-cli.sh](vagrant/scripts/install-replicated-cli.sh)

**The remaining tasks will all be done using the Vagrant VM:**

2. Clone the following repos:
* [eks-deployer](https://github.com/dyvantage/eks-deployer)
* [nodeapp](https://github.com/dwrightco1/nodeapp)

3. Configure AWS Client
* **$ aws configure**
```
AWS Access Key ID [None]: ********
AWS Secret Access Key [None]: ********
Default region name [None]: us-east-1
Default output format [None]: json
```

4. Provision an EKS Cluster on AWS (target Kubernetes cluster for testing)
* `terraform init`
* `terraform apply -auto-approve`

Once the cluster is done provisioning, configure Kubectl:
4. Deploy & Validate 2-Tier Application (`nodeapp` -- which is a Node.js application with a Mysql database back-end)

## Comments/Observations
1. When extracting the replicated-cli package, it didn't extract to a subdiretory (and it override the README.md in the current directory)

## Documentation Bugs
1. URL = https://kots.io/vendor/guides/quickstart
```
bad_text = [
	"You’ll should be"
	"define how you application will work"
	"To add worker nodes to this installation, run the following script on your other nodes"
	"which will show the initial version that was check deployed"
]
```
