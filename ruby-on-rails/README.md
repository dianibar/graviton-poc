
<h3 align="center">Ruby on Rails EKS POC</h3>


<!-- GETTING STARTED -->
## Latest Graviton Instances type
#### General Purpose
* T4g - graviton 2 
* M7g - graviton 3
#### Compute Optimised
* C7g - graviton 3
#### Memory Optimised
* R7g - graviton 3
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