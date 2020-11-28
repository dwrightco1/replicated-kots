# Replicated KOTS Evaluation
Notes from my evaluation of Replicated.Com's KOTS product.

## Questions / Comments

1. Is the embedded installer omnipotent?  (It seems to download even if already downloaded)
2. Is there a log for the embedded installer?

## Evaluation Plan
**0. Installation Log**
Here is the [Log](kots-install.log) from running the installer.

**1. Provision Dev Workstation**

Using this [Vagrantfile](vagrant/Vagrantfile), use Vagrant to build a Dev Workstation running Ubuntu 18.04

The post-install for the Vagrant build includes:
* [configure-hostname.sh](vagrant/scripts/configure-hostname.sh)
* [configure-ntp.sh](vagrant/scripts/configure-ntp.sh)
* [install-terraform-aws.sh](vagrant/scripts/install-terraform-aws.sh)
* [install-kubectl.sh](vagrant/scripts/install-terraform-aws.sh)
* [install-replicated-cli.sh](vagrant/scripts/install-replicated-cli.sh)

Once the Vagrant VM is ready, SSH to it and perform the remaining tasks from there.

**2. Configure AWS Integration**

Configure the AWS Client to use your AWS account when provisioning resources:
```
$ aws configure
AWS Access Key ID [None]: ********
AWS Secret Access Key [None]: ********
Default region name [None]: us-east-1
Default output format [None]: json
```

**3. Provision an EKS Cluster on AWS**

Using [eks-deployer](https://github.com/dyvantage/eks-deployer), create a Kubernetes cluster (to run tests against):
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

Validate the new cluster by deploying a [Sample Application](https://github.com/dwrightco1/nodeapp).  This is a simple Node.js application with a MySQL database back-end.
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

Validate the database connection string (i.e. which Pod is the back-end running on):
```
$ kubectl get pods -l app=mysql
$ kubectl describe pod <>
```

Cleanup (delete all Kubernetes resources created by the installer)
```
$ kubectl delete -f https://raw.githubusercontent.com/dwrightco1/nodeapp/master/kubernetes/install-nodeapp.yaml
```

**5) Package [Sample Application](https://github.com/dwrightco1/nodeapp) Using Replicated KOTS**

**5.1 Using [https://vendor.replicated.com](https://vendor.replicated.com), Create an Application**

* Create an Application and get its `Slug`
* Create an API Token (with read/write access)

**5.2 Configure & Validate Environment**

```
export REPLICATED_APP=<slug>
export REPLICATED_API_TOKEN=<token>
replicated release ls
```

**5.3 Clone Repository, Run Linter, and Package Application**

```
git clone https://github.com/dwrightco1/nodeapp-replicated.git ~/nodeapp-replicated
cd ~/nodeapp-replicated
replicated release lint --yaml-dir=manifests
```

Once the linter runs clean, performing the following steps to package:
```
replicated release create --auto
replicated customer create --name "DyVantage" --expires-in "240h" --channel "Unstable"
replicated customer download-license --customer DyVantage ~/DyVantage-${REPLICATED_APP}-license.yaml
```

Note: Try setting `--expires-in` to an hour (and learn the license renewal process)

Once the application is packaged, use this command to get the `installation strings` for each type of deployment:
```
replicated channel describe Unstable
```

These are the different installation types:
* `EXISTING` -- deploy against an existing Kubernetes cluster
* `EMBEDDED` -- deploy a NEW Kubernetes cluster on a local machine (VM)
* `AIRGAP` -- deploy in an Air-Gapped environment (i.e. no Internet connectivity)

**5.3 Deploy Application to *EXISTING EKS CLUSTER*)**

First, install KOTS (which is a Plugin for kubectl):
```
$ curl -fsSL https://kots.io/install | bash
```

Once installed, validate by running:
```
kubectl kots --help
```

Now you're ready to deploy KOTS infrastrucure to the cluster:
```
kubectl kots install nodeapp/unstable
```

Note: it prompts for a namespace to deploy the application to, which is why the linter flags hard-coded namespaces.

Now take a look at the Kubernetes objects associated with KOTS:
```
$ kubectl get deployments -n nodeapp-dev
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
kotsadm            1/1     1            1           5m13s
kotsadm-operator   1/1     1            1           5m12s

$ kubectl get services -n nodeapp-dev
NAME               TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
kotsadm            ClusterIP   172.20.247.97    <none>        3000/TCP   4m48s
kotsadm-minio      ClusterIP   172.20.218.220   <none>        9000/TCP   6m5s
kotsadm-postgres   ClusterIP   172.20.99.165    <none>        5432/TCP   6m4s

$ kubectl get pods -n nodeapp-dev
NAME                                READY   STATUS      RESTARTS   AGE
kotsadm-6c586cbd84-mqnp8            1/1     Running     0          4m35s
kotsadm-migrations-1606491633       0/1     Completed   0          5m1s
kotsadm-minio-0                     1/1     Running     0          5m51s
kotsadm-operator-7d86d48c46-q8bnp   1/1     Running     0          4m34s
kotsadm-postgres-0                  1/1     Running     0          5m51s
```

**5.4 Deploy Application to *EMBEDDED CLUSTER*)**

Post-Install Configs for VM or Bare-Metal cluster node:
* Make sure the hostname is set and resolvable in local /etc/hosts
* Make sure NTS is configured and working (I experienced curl TLS-related errors due to time drift)

**5.4.1 Install Kubernetes Cluster (Embedded)**
To install Kubernetes components, run:
```
curl -fsSL https://k8s.kurl.sh/nodeapp-unstable | sudo bash
```

Here is a [sample log](kots-install.log) from the embedded installer.

**5.4.2 Configure Kubectl **
To configure `kubectl` to operate against the cluster, run:
```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

To validate, run:
```
$ kubectl get nodes
NAME   STATUS   ROLES    AGE   VERSION
kots   Ready    master   50m   v1.19.3
```

**6. Delete EKS Cluster**

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

