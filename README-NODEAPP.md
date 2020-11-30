**Deploy *Non-Replicated* Version of NodeApp**

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
