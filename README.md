# Replicated KOTS Evaluation
Notes from my evaluation of Replicated.Com's KOTS product.

## Evaluation Plan
I tested Replicated.Com's KOTS product using two (2) deployment types:
* Embedded (Vagrant VM)
* Existing (EKS Cluster on AWS)

I used [NodeApp](https://github.com/dwrightco1/nodeapp) for testing.  The application has a front-end running Node.Js and a back-end running MySQL.

For the Kotsadm `Configure Application` screen, I decided to add an option for exposing the front-end service as either a `LoadBalancer` or `NodePort`.  My assumption is that I'll be able to parameterize the user-select value into the `frontent-service.yaml` (which manages access to the frontend Deployment).

## Environment Setup
I used this [Vagrantfile](vagrant/Vagrantfile) to build a Dev Workstation running Ubuntu 18.04.

The post-install for the Vagrant build includes:
* [configure-hostname.sh](vagrant/scripts/configure-hostname.sh)
* [configure-ntp.sh](vagrant/scripts/configure-ntp.sh)
* [install-terraform-aws.sh](vagrant/scripts/install-terraform-aws.sh)
* [install-kubectl.sh](vagrant/scripts/install-terraform-aws.sh)
* [install-replicated-cli.sh](vagrant/scripts/install-replicated-cli.sh)

All remaining tasks were performed from the Vagrant VM.

## Evaluation Step 1: PACKAGE [NodeApp](https://github.com/dwrightco1/nodeapp) Using Replicated KOTS

**1.1 Using [https://vendor.replicated.com](https://vendor.replicated.com), Create an Application**

* Create an Application and get its `Slug`
* Create an API Token (with read/write access)

**1.2 Configure & Validate Environment**

```
export REPLICATED_APP=<slug>
export REPLICATED_API_TOKEN=<token>
replicated release ls
```

**1.3 Clone Repository, Re-Factor Code, Run Linter, and Package Application**
After re-factoring code, I created a new repo: [NodeApp-Replicated](https://github.com/dwrightco1/nodeapp-replicated.git)
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

To see the metadata for the various installation types (embedded, existing, air-gapped), run:
```
$ replicated channel inspect Unstable
```

## Evaluation Step 2 : DEPLOY [NodeApp-Replicated](https://github.com/dwrightco1/nodeapp-replicated.git) TO *EMBEDDED* CLUSTER

**2.1 Install Kubernetes Cluster (Embedded)**
To install Kubernetes components, run:
```
curl -fsSL https://k8s.kurl.sh/nodeapp-unstable | sudo bash
```

Here is a [sample log](kots-install.log) from the embedded installer.

**2.2 Configure Kubectl**
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

## Evaluation Step 3 : DEPLOY [NodeApp-Replicated](https://github.com/dwrightco1/nodeapp-replicated.git) TO *EXISTING* CLUSTER

**3.1 Build EKS Cluster (on AWS)**

I built an EKS Cluster on AWS using [eks-deployer](https://github.com/dyvantage/eks-deployer).

**3.2 Deploy *Non-Replicated* Version of NodeApp**

Validate the cluster by deploying the *non-Replicated* version of [NodeApp](https://github.com/dwrightco1/nodeapp):
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

Delete all Kubernetes resources created by insalling NodeApp:
```
$ kubectl delete -f https://raw.githubusercontent.com/dwrightco1/nodeapp/master/kubernetes/install-nodeapp.yaml
```

**3.3 Deploy *Replicated* Version of NodeApp**

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

**4. Delete EKS Cluster**

IMPORTANT: don't forget this step -- it deletes all AWS resources created by the Terraform installer:
```
$ terraform destroy -auto-approve
```

Something to watch out for: if you create an AWS resource through Kubernetes (like a PVC) deleteting the EKS cluster will not remove the storage volume associated with the PVC.  So make sure you clean up your Kubernetes resoures using `kubectl` before cleaning up with Terraform.

## Comments/Observations
1. When extracting the replicated-cli package, it didn't extract to a subdiretory (and it override the README.md in the current directory)
2. Is the embedded installer omnipotent?  (It seems to download even if already downloaded)
3. Is there a log for the embedded installer?
4. How do you configure serviceType Load-Balancer in embedded clusters?
5. Make sure the hostname is set and resolvable in local /etc/hosts
6. Make sure NTS is configured and working (I experienced curl TLS-related errors due to time drift)

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

