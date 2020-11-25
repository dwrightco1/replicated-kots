# Replicated KOTS Evaluation
Notes from my evaluation of Replicated.Com's KOTS product.

## Evaluation Plan
**1) Setup Dev Workstation**

Using this [Vagrantfile](vagrant/Vagrantfile), use Vagrant to build a Dev Workstation running Ubuntu 18.04

The post-install for the Vagrant build includes:
* [configure-hostname.sh](vagrant/scripts/configure-hostname.sh)
* [configure-ntp.sh](vagrant/scripts/configure-ntp.sh)
* [install-terraform-aws.sh](vagrant/scripts/install-terraform-aws.sh)
* [install-kubectl.sh](vagrant/scripts/install-terraform-aws.sh)
* [install-replicated-cli.sh](vagrant/scripts/install-replicated-cli.sh)

Once the Vagrant VM is ready, SSH to it and perform the remaining tasks from there.

**2) Configure AWS Integration**

Configure the AWS Client to use your AWS account when provisioning resources:
```
$ aws configure
AWS Access Key ID [None]: ********
AWS Secret Access Key [None]: ********
Default region name [None]: us-east-1
Default output format [None]: json
```

**3) Provision an EKS Cluster on AWS**

Using `eks-deployer`, create a Kubernetes cluster (to run tests against):
```
$ git clone https://github.com/dyvantage/eks-deployer.git
$ cd ~/eks-deployer
$ ./install-prereqs.sh
$ terraform init
$ terraform plan     # this is an optional preview step
$ terraform apply -auto-approve
```

Once the cluster is done provisioning, configure kubectl:
```
$ aws eks --region $(terraform output region) update-kubeconfig --name $(terraform output cluster_name)
$ kubectl get nodes
NAME                                       STATUS   ROLES    AGE    VERSION
ip-10-0-1-158.us-east-2.compute.internal   Ready    <none>   110s   v1.17.12-eks-7684af
ip-10-0-3-164.us-east-2.compute.internal   Ready    <none>   108s   v1.17.12-eks-7684af
ip-10-0-3-59.us-east-2.compute.internal    Ready    <none>   107s   v1.17.12-eks-7684af
```

**4. Deploy 2-Tier Application (Web/Database)**

Validate the new cluster by deploying a simple Node.js application with a Mysql database back-end.
```
kubectl apply -f https://raw.githubusercontent.com/dwrightco1/nodeapp/master/kubernetes/install-nodeapp.yaml
```

Verify the application installed correctly by listing the Deployments:
```
$ kubectl get deployments -n nodeapp-dev
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
mysql-deployment   1/1     1            1           76s
nodeapp            1/1     1            1           75s
```

And the Services:
```
$ kubectl get services -n nodeapp-dev
NAME              TYPE           CLUSTER-IP       EXTERNAL-IP                                                               PORT(S)          AGE
mysql-service     ClusterIP      172.20.160.251   <none>                                                                    3306/TCP         99s
nodeapp-service   LoadBalancer   172.20.230.59    a9589e18cc9af41d2828baeb1650ea30-1358380261.us-east-2.elb.amazonaws.com   3000:30457/TCP   97s
```

Validate the front-end (Node.Js App) can talk to the back-end (MySql database):
```
$ curl http://a9589e18cc9af41d2828baeb1650ea30-1358380261.us-east-2.elb.amazonaws.com:3000
Successfully connected to database: root@172.20.160.251:nodeapp
IP Address (lo) = 127.0.0.1
IP Address (eth0) = 10.0.2.235
```

Cleanup (delete all Kubernetes resources created by the installer)
```
$ kubectl delete -f https://raw.githubusercontent.com/dwrightco1/nodeapp/master/kubernetes/install-nodeapp.yaml
```

**N. Delete EKS Cluster**
IMPORTANT: don't forget this step -- it deletes all AWS resources created by the Terraform installer:
```
$ terraform destroy -auto-approve
```

Something to watch out for: if you create an AWS resource through Kubernetes (like a PVC) deleteting the EKS cluster will not remove the storage volume associated with the PVC.  So make sure you clean up your Kubernetes resoures using `kubectl` before cleaning up with Terraform.

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

