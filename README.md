# PHP - From code to Kubernetes

This project aims to demonstrate how to run a PHP Laravel application on Kubernetes, from the Dockerfile to the deployment manifests.

In addition you can find a example of how to configure and run your local development environment fully based on Docker containers.

## Requirements

* Kubernetes cluster (local or remote). If you are on Mac I strongly recommed https://docs.docker.com/docker-for-mac/install/. You can get your cluster up and running within minutes. Apart than that the Docker daemon will be the same for local and cluster. That means images don't have to be pushed to a remote registry in order to deploy to your local cluster.

* kubectl command line tool - https://kubernetes.io/docs/tasks/tools/install-kubectl/.
  * Mac:
  ```
  brew install kubernetes-cli
  ```

  * Ubuntu:
  ```
  sudo apt-get update && sudo apt-get install -y apt-transport-https
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
  sudo touch /etc/apt/sources.list.d/kubernetes.list
  echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
  sudo apt-get update
  sudo apt-get install -y kubectl
```

* Kubernetes Dashboard
  ```
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
  ```

## Local Development

The `docker-compose.yaml` contains the following services:

* NGINX
* Web
* Worker
* Scheduler (WIP)
* Redis
* MySQL
* Elasticsearch

Just run `docker-compose up` and point your browser to http://localhost:9002.

**Interacting with local containers**

* logs: `docker logs -f [CONTAINER_NAME]`
* bash: `docker exec -it [CONTAINER_NAME] bash`
* tinker: `docker exec -it web bash -c "php artisan tinker"`

## Kuberernetes Manifests

All the Kubernetes manifests are placed under the `k8s` folder. The files are named as the order they should be deployed.

## Secrets and Environment Variables

For the sake of simplicity the file `envs/.env.production` contains the database credentials as plaintext. It is worthy saying that this **should never be done** for production like projects. Sensitive info **should never be pushed** to neither Github or any other remote repo (private or public).

There are many solutions out there that could help on that matters. For example:
* https://github.com/Shopify/ejson
* https://www.vaultproject.io/
* https://github.com/bitnami-labs/sealed-secrets

### PHP Application

The application's manifests have been split into:

* Namespace: creates a namespace named `php-k8s`
* Configs: php-fpm and NGINX configmaps that will be used by the POD when it is started.
* Web: NGINX + PHP-FPM
* Worker: Laravel Worker
* Scheduler: Laravel Scheduler

As you may have seen, all the manifests are using the same `image:tag`. What will differs the process that starts on every container is defined by the `args` key. That argument maps to `bin/entrypoint.sh` file more specifically to the `case` statement.

### Datastore

There are extra manifests under `k8s/datastore` folder. Those manifests are used in order to make it available within the cluster the following services:

* MySQL
* Redis
* Elasticsearch

You can find an example of how to use the internal name resolution checking `envs/.env.production` file. It contains `DB_HOST=mysql-svc.datastore`. This name will be resolved internally by Kubernetes DNS service, callend Kube-DNS.

Make sure that you have the FQDN when pointing to services that are not under the same namespace.

Taking that example you can split the service name as:

* `mysql-svc`: Service name
* `datastore`: Namespace name where the service/deployment has been deployed.

## Image Build

Before pushing your manifests, a image must be available. The default images used by the manifests points to `danieloliv/php-k8s:latest`. If you wanna try this out using your own image or your own version of this project you have to follow the steps below:

* Build your image: `docker build -t myimage:mytag .`
* Update K8S manifests and replace `danieloliv/php-k8s:latest` by `myimage:mytag`. Your manifests can also use a remote image that is publicly available.

**Tip**: If you wanna deploy manifests that points to private imates check the documentation here https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/.

## Deploy

The deployment is very straightforward. Since you get your manifests ready and the docker image is available, you can push your manifests running:

* Deploy Datastore: `kubectl apply -f k8s/datastore`
* Deploy PHP: `kubectl apply -f k8s/`

Check your PODS:

* Terminal: `kubectl -n php-k8s get pods`
* Dashboard:
  * `kubectl proxy` - http://localhost:8001
  * Skip the Token/Kubeconfig screen
  * Select `php-k8s` from the namespace list

If there are no errors and all pods have the status equals RUNNING you can point your browser to http://localhost:9001.

You should be seeing the `Laravel` welcome page.

## Troubleshooting

If you can't see the `Laravel` welcome page try the following:

* Check PODs status and logs:
  * `kubectl -n datastore get pods` - Check PODs from `datastore` namespace. If there are any that is not running, take its name.
  * `kubectl -n datastore logs -f POD_NAME`
  * `kubectl -n php-k8s get pods` - List all pods and its status. If there are any that is not running, take its name.
  * `kubectl -n php-k8s logs -f POD_NAME`

* Dashboard
  * Run `kubectl proxy` and open http://localhost:8001
  * Select `datastore` from the namespace list and look for any POD that has its status not equals `Running`. Check the POD's events list.
  * Repeat the steps above but select the `php-k8s` instead.

Depending on what is the problem you can workout the solution. Usually it can be related a services not ready under the `datastore` namespace. If it is the first time you are pushing your manifests and the images have never been pulled, it can take some time until the POD becomes available.

## Security

Check `security` folder for very useful info about how to make Kubernetes and Docker secure.
