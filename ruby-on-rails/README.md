
<h3 align="center">Ruby on Rails EKS POC</h3>


<!-- GETTING STARTED -->
## Latest Graviton Instances type
#### General Purpose
* T4g - graviton 2 
* M7g - graviton 3
* M7gd - graviton 3
#### Compute Optimised
* C7g - graviton 3
* C7gn - graviton 3
#### Memory Optimised
* R7g - graviton 3
* R7gd - graviton 3
* X2gd - graviton 2
#### Accelerated Computing
* G5g - graviton 2
#### HPC Optimized
* Hpc7g - graviton 2

to list all regions where a specific instance type is available you can use the following aws cli command, for example:
```
aws ec2 describe-instance-type-offerings --location-type region --filters Name=instance-type,Values=m7g.large --region ap-south-1
{
    "InstanceTypeOfferings": [
        {
            "InstanceType": "m7g.large",
            "LocationType": "region",
            "Location": "ap-south-1"
        }
    ]
}
```
## Run the Ruby on Rails EKS POC

### Create an EKS cluster with graviton and non Graviton managed worker groups

1. Clone this project and move to the Terraform folder to create the cluster

```
git clone https://github.com/dianibar/graviton-poc.git

cd graviton-poc/terraform


```
### Create a Docker image using an image base that supports ARM and push it to ECR

1. In the folder graviton-poc/ruby-on-rails there is a helloworld rubby application. In the folder, there is also a Docker file using ruby:latest as the base image. Checking in [DockerHub](https://hub.docker.com/_/ruby) we can see that this image supports ARM architecture.

2. ECR supports multi-architecture container images. To be able to create an image that is built for different architectures you can use an emulator. For this follow the instructions provided in this [AWS blog](https://aws.amazon.com/blogs/compute/how-to-quickly-setup-an-experimental-environment-to-run-containers-on-x86-and-aws-graviton2-based-amazon-ec2-instances-effort-to-port-a-container-based-application-from-x86-to-graviton2/) we can follow these steps:
   
   * Install buildx

   ```
   curl --silent -L https://github.com/docker/buildx/releases/download/v0.13.1/buildx-v0.13.1.linux-amd64 -o buildx-v0.13.1.linux-amd64

   chmod a+x buildx-v0.13.1.linux-amd64

   mkdir -p ~/.docker/cli-plugins
   
   mv buildx-v0.13.1.linux-amd64 ~/.docker/cli-plugins/docker-buildx
   
   docker buildx
   ```
   * Enter the following command to configure Buildx binary for different architectures

   ```
   docker run --privileged --rm tonistiigi/binfmt --install all
   ``` 
   * Check to see a list of build environment.
   ```
   docker buildx ls
   ```
   * Create a new builder named mybuild and switch to it to use it as default.
3. Create a multi-arch image for x*6 and Arm64 and push them to Amazon ECR
   * Set the environment variables
   ```
   AWS_ACCOUNT_ID=aws-account-id
   AWS_REGION=us-west-2
   ```
   * Authenticate your Docker client to your Amazon ECR registry

   ```
   login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
   ```
   * Create your multi-archi image and push it to ECR
   ```
   docker buildx build --platform linux/amd64,linux/arm64 --tag ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/myrepo:latest --push .
   ```
### Run the application on EKS

1. The folder graviton-poc/ruby-on-rails/kubernetes has a file with a service an a deployment. The deployment is configured to spread to multiple nodes. The eks cluster has been configured to have one node using t3.micro and another node using t4g.micro so it will show that the app runs in x86 and ARM.

```
cd graviton-poc/ruby-on-rails/kubernetes
kubectl apply 
```

### Additional Considerations

Check this [link](https://github.com/aws/aws-graviton-getting-started/blob/main/transition-guide.md) for the consideration provided by AWS. Some of the more importants for this poc are:

* Ruby is an Interpreted language same as Node.js or PHP so it should work with minor changes.
* Upgrading the application to use the latest version of required libraries will increase the probability that the library is supported. Therefore one suggested strategy is to update the libraries and test that it is working in x86, then migrate to ARM.
* The main issue that I found was with libraries using (c/c++) that needed to be compiled for ARM64 architecture. For example [libv8](https://github.com/rubyjs/libv8), binaries are not compiled for ARM. Check this link for the [solution](https://dev.sweatco.in/rails-on-arm/)
* This [section](https://github.com/aws/aws-graviton-getting-started/blob/main/transition-guide.md#appendix-a---locating-packages-for-arm64graviton) provides where to locate packages for ARM64/Graviton:
    
    *  Package repositories of your chosen Linux distribution(s)
    *  Container image registry.
    *  On GitHub, you can check for arm64 versions in the release section
* More details for Amazon EKS optimized Arm Amazon Linux AMIs in this [link](https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami.html#arm-ami):

    * If your cluster was deployed before August 17, 2020, you must do a one-time upgrade of critical cluster add-on manifests. This is so that Kubernetes can pull the correct image for each hardware architecture in use in your cluster.
    * Applications deployed to Arm nodes must be compiled for Arm.
    * If you have DaemonSets that are deployed in an existing cluster, or you want to deploy them to a new cluster that you also want to deploy Arm nodes in, then verify that your DaemonSet can run on all hardware architectures in your cluster.
    * You can run Arm node groups and x86 node groups in the same cluster. If you do, consider deploying multi-architecture container images to a container repository such as Amazon Elastic Container Registry and then adding node selectors to your manifests so that Kubernetes knows what hardware architecture a Pod can be deployed to.
    * Recommended to check: https://d1.awsstatic.com/events/Summits/reinvent2023/CMP404_Migrating-to-AWS-Graviton-with-AWS-container-services.pdf

* Review and benchmarking of deployment, useful links:
    * [Graviton Performance Runbook](https://github.com/aws/aws-graviton-getting-started/blob/main/perfrunbook/README.md)
    * [Optimizing for Graviton](https://github.com/aws/aws-graviton-getting-started/blob/main/optimizing.md)
    * [Monitoring tools for AWS Graviton](https://github.com/aws/aws-graviton-getting-started/blob/main/Monitoring_Tools_on_Graviton.md)
   
