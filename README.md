# How to deploy to the AWS EC2 server
- [How to deploy to the AWS EC2 server](#how-to-deploy-to-the-aws-ec2-server)
  - [create the AWS EC2 server](#create-the-aws-ec2-server)
    - [install Docker](#install-docker)
      - [Executing the Docker Command Without Sudo (Optional)](#executing-the-docker-command-without-sudo-optional)
      - [Running NGINX Open Source in a Docker Container](#running-nginx-open-source-in-a-docker-container)
    - [Installing the latest version of the AWS CLI](#installing-the-latest-version-of-the-aws-cli)
    - [Create the ECR repository](#create-the-ecr-repository)
      - [Create the IAM user credentials](#create-the-iam-user-credentials)
      - [Creating the User Groups](#creating-the-user-groups)
- [Create a new Nest.JS project](#create-a-new-nestjs-project)
      - [Generate new project using nest cli](#generate-new-project-using-nest-cli)
      - [Create Multistage Dockerfile](#create-multistage-dockerfile)
      - [GitHub Action configuration](#github-action-configuration)
      - [Push to a remote repository](#push-to-a-remote-repository)
    - [Setting The ECR on the server](#setting-the-ecr-on-the-server)
      - [Update a secure group (Firewall)](#update-a-secure-group-firewall)
    - [From manual deployment to automatic deployment.](#from-manual-deployment-to-automatic-deployment)

## create the AWS EC2 server 
here will be a link to the video
https://prnt.sc/b1hmlOzOFP1S

### install Docker
First, update your existing list of packages:
```bash
sudo apt update
```
Next, install a few prerequisite packages which let apt use packages over HTTPS:
```bash
sudo apt install apt-transport-https ca-certificates curl software-properties-common
```
Then add the GPG key for the official Docker repository to your system:
```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
```
Add the Docker repository to APT sources:
```bash
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
```
This will also update our package database with the Docker packages from the newly added repo.

Make sure you are about to install from the Docker repo instead of the default Ubuntu repo:
```bash
apt-cache policy docker-ce
```
You’ll see output like this, although the version number for Docker may be different:
```bash
# Output of apt-cache policy docker-ce
docker-ce:
  Installed: (none)
  Candidate: 5:19.03.9~3-0~ubuntu-focal
  Version table:
     5:19.03.9~3-0~ubuntu-focal 500
        500 https://download.docker.com/linux/ubuntu focal/stable amd64 Packages
```
Notice that `docker-ce` is not installed, but the candidate for installation is from the Docker repository for Ubuntu 20.04 (focal).

Finally, install Docker:
```bash
sudo apt install docker-ce
```
Docker should now be installed, the daemon started, and the process enabled to start on boot. Check that it’s running:
```bash
sudo systemctl status docker
```

The output should be similar to the following, showing that the service is active and running:
```bash
Output
● docker.service - Docker Application Container Engine
     Loaded: loaded (/lib/systemd/system/docker.service; enabled; vendor preset: enabled)
     Active: active (running) since Tue 2020-05-19 17:00:41 UTC; 17s ago
TriggeredBy: ● docker.socket
       Docs: https://docs.docker.com
   Main PID: 24321 (dockerd)
      Tasks: 8
     Memory: 46.4M
     CGroup: /system.slice/docker.service
             └─24321 /usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
```
Installing Docker now gives you not just the Docker service (daemon) but also the docker command line utility, or the Docker client. We’ll explore how to use the docker command later in this tutorial.

#### Executing the Docker Command Without Sudo (Optional)
By default, the docker command can only be run the root user or by a user in the docker group, which is automatically created during Docker’s installation process. If you attempt to run the docker command without prefixing it with sudo or without being in the docker group, you’ll get an output like this:
```bash
# Output
docker: Cannot connect to the Docker daemon. Is the docker daemon running on this host?.
See 'docker run --help'.
```
If you want to avoid typing sudo whenever you run the docker command, add your username to the docker group:
```bash
sudo usermod -aG docker ${USER}
```

To apply the new group membership, **log out of the server and back in**, or type the following:
```bash
su - ${USER}
```
You will be prompted to enter your user’s password to continue.
Confirm that your user is now added to the docker group by typing:
```bash
groups
# Output
ubuntu adm dialout cdrom floppy sudo audio dip video plugdev netdev lxd docker
```
If you need to add a user to the docker group that you’re not logged in as, declare that username explicitly using:
```bash
sudo usermod -aG docker ${USER}
```
The rest of this article assumes you are running the docker command as a user in the docker group. If you choose not to, please prepend the commands with sudo.

Let’s explore the docker command next.
```bash
docker info
```
#### Running NGINX Open Source in a Docker Container
You can create an NGINX instance in a Docker container using the NGINX Open Source image from the Docker Hub.
1. Launch an instance of NGINX running in a container and using the default NGINX configuration with the following command:

```bash
docker run --rm --name mynginx1 -p 80:80 -d nginx
```
where:
- the -rm option tells Docker to remove the container after stop
- mynginx1 is the name of the created container based on the NGINX image

- the -d option specifies that the container runs in detached mode: the container continues to run until stopped but does not respond to commands run on the command line.

- the -p option tells Docker to map the ports exposed in the container by the NGINX image (port 80) to the specified port on the Docker host. The first parameter specifies the port in the Docker host, the second parameter is mapped to the port exposed in the container

The command returns the long form of the container ID: **fcd1fb01b14557c7c9d991238f2558ae2704d129cf9fb97bb4fadf673a58580d**. This form of ID is used in the name of log files.
```bash
docker run --rm --name mynginx1 -p 80:80 -d nginx
# output
Unable to find image 'nginx:latest' locally
latest: Pulling from library/nginx
3f4ca61aafcd: Pull complete
50c68654b16f: Pull complete
3ed295c083ec: Pull complete
40b838968eea: Pull complete
88d3ab68332d: Pull complete
5f63362a3fa3: Pull complete
Digest: sha256:0047b729188a15da49380d9506d65959cce6d40291ccfb4e039f5dc7efd33286
Status: Downloaded newer image for nginx:latest
be641008bf66c410d82bc640c132486835e249a8dc34a1fbc716dacabe989973
```
2. Verify that the container was created and is running with the docker ps command:

```bash
docker ps
# output
CONTAINER ID   IMAGE     COMMAND                  CREATED          STATUS          PORTS                               NAMES
be641008bf66   nginx     "/docker-entrypoint.…"   35 seconds ago   Up 34 seconds   0.0.0.0:80->80/tcp, :::80->80/tcp   mynginx1
```
Go to our server `http://ec2-54-173-228-252.compute-1.amazonaws.com/`, you should see like this:
![main screen](docs/nginx_main_screen.png)
### Installing the latest version of the AWS CLI
To update your current installation of AWS CLI, download a new installer each time you update to overwrite previous versions. Follow these steps from the command line to install the AWS CLI on Linux.

We provide the steps in one easy-to-copy-and-paste group based on whether you use 64-bit Linux or Linux ARM. See the descriptions of each line in the steps that follow.
Use the curl command – The -o option specifies the file name that the downloaded package is written to. The options on the following example command write the downloaded file to the current directory with the local name awscliv2.zip.
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

```
install unzip
```bash
sudo apt install unzip
```
The following example command unzips the package and creates a directory named aws under the current directory.
```bash
unzip awscliv2.zip
```
Run the install program. The installation command uses a file named install in the newly unzipped aws directory. By default, the files are all installed to /usr/local/aws-cli, and a symbolic link is created in /usr/local/bin. The command includes sudo to grant write permissions to those directories.
```bash
sudo ./aws/install
```
Confirm the installation with the following command.
```bash
$ aws --version
aws-cli/2.9.10 Python/3.9.11 Linux/5.15.0-1026-aws exe/x86_64.ubuntu.22 prompt/off
```

### Create the ECR repository
In this step, we will create a new repository to store our images.
Go to `https://aws.amazon.com/ecr/`, then create your first repository.
![create a new repository](docs/ecr.png)
After creation, you need to set a lifecycle policy, if you plan to use the repository for free for one year.
![repository overview](docs/inside_repository.png)
Please set 
**You must stick to the 500MB**, for a private repository.
To do this, set the parameters as shown in the image. 
In my case, each image weighs about 150MB.
So I can store no more than three images. 
When a new image is saved, the oldest image will be deleted.

If your images weigh less, you can change the limit from 3 to 4, depending on the weight of the image.
![repository-policy](docs/ecr_lifecycle_police.png)

#### Create the IAM user credentials
We need to create credentials to access our repository  
programmatically.
Go to `https://aws.amazon.com/iam/`, On the IAM dashboard, click on Users on the left panel
![aws aim main screen](docs/aim_main_screen.png)
 then click on Add users at the top-right of the page to initialize adding users.
![create a new user ](docs/aim_add_users.png)

Now configure the user details with the following:

- Provide a username in the User name field shown below. For this example, the username is set to user-1.
- Enable the Access Key – AWS Management Console access option to allow users to sign in to AWS using programmatic mode. 

![set programmatically](docs/aim_set_progmatically.png)

Skip setting permission and click on Next: Tags since you’re creating a user that doesn’t have permissions.
![skip user groups](docs/skip_user_group.png)
Skip adding tags too and click Next: Review.
![skip adding tags](docs/aim_skip_tags.png)
Review the user details and click on Create user to finalize creating the user.
![review](docs/aim_review_user.png)
finally, you get credentials, like this:
Access key ID: `ACCESSAYWNKEYWGH5IDGGO7N`
Secret access key: `SecREtaCceSsKEy5spYW1dnd2yOXMU2JahTDJ48DR`

**Warning! Keep them in your possession and do not give them to anyone else. 
You will need them later.** 
![save credentials](docs/aim_save_credentials.png)

After creating the user, you’ll get a Success screen like the one below.

![after creating](docs/aim_after_created.png)

#### Creating the User Groups
Now that you’ve created the users, it’s time to create groups. You’ll create groups using the AWS-managed policy and a JSON file.

For this tutorial, you’ll create a group:
- **AmazonEC2ContainerRegistryFullAccess** - Provides permissions to push and pull images to/from ECR.

To start creating user groups.
In your IAM dashboard, click on the User groups on the left pane, then click on Create group.
![user groups](docs/aim_creating_user_groups.png)
Provide a User group name (ECR-FULL-ACCESS), select user and select policy on the Create user group page, as shown below.
![creating new group](docs/aim_creating_ecr_group.png)

After creating the user group.
![](docs/aim_after_creating_ecr_group.png)
# Create a new Nest.JS project

#### Generate new project using nest cli
before you need to install a global package nest and create a new project.
```
npm i -g @nestjs/cli
nest new websocket-module-communication
```
We got the following file structure:
```bash
simple-ci-cd-aws-ecr/
├── node_modules/
├── src/
├── test/
├── .eslintrc.js
├── .gitignore
├── .prettierrc
├── nest-cli.json
├── package.json
├── package-lock.json
├── README.md
├── tsconfig.build.md
└── tsconfig.json
```
Perfect! Now we will create two directories. One for storing images for documentation and the other for the configuration of GitHub Actions.
```bash
simple-ci-cd-aws-ecr/
├── node_modules/
├── .github/ #github actions
├── docs/ #documentation
├── src/
├── test/
├── .eslintrc.js
├── .gitignore
├── .prettierrc
├── nest-cli.json
├── package.json
├── package-lock.json
├── README.md
├── tsconfig.build.md
└── tsconfig.json
```

#### Create Multistage Dockerfile
To create an image, we need to create a Dockerfile, where will be our application.
```dockerfile
# Build Stage 1
# This build created a staging docker image
#
FROM node:10.15.2-alpine AS appbuild
WORKDIR /usr/src/app
COPY package.json ./
RUN npm install
COPY . .
RUN npm run build

# Build Stage 2
# This build takes the production build from staging build
#
FROM node:10.15.2-alpine
WORKDIR /usr/src/app
COPY package.json ./
RUN npm install
COPY --from=appbuild /usr/src/app/dist ./dist
EXPOSE 3000
CMD ["node", "dist/main"]
```

#### GitHub Action configuration
1. create trigger
An event is a specific activity in a repository that triggers a workflow run. In our case, activity can originate from GitHub when someone pushes a commit to a repository. 

```yml
on:
  push:
    branches:
      - 'main' 
```
2. store credentials to the GitHub secret.
Go to the `setting` section of your repository, and create a new secret.
![create secret](docs/storing_credentials_github_actions.png)

Also, I added **two more** secrets:
`AWS_REGION` with value `us-east-1` - set this to your preferred AWS region, e.g. us-west-1.
`ECR_REPOSITORY` with value `simple-ci-cd-aws-ecr` - set this to your Amazon ECR repository name.

After creating, you should have two secrets as shown below.
They will come in handy later.
![after creating](docs/after_storing_github_actions.png)
3. Extract the source code and copy it inside the container
```yml
jobs:
  deploy:
    name: Deploy
    runs-on: ubuntu-latest
    environment: development

    steps:
      - name: Checkout
        uses: actions/checkout@v3
```
4. Configure AWS credential and region environment variables for use in other GitHub Actions. The environment variables will be detected by both the AWS SDKs and the AWS CLI to determine the credentials and region to use for AWS API calls.
```yml
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ secrets.AWS_REGION }}
```
5. Login to Amazon ECR
```yml

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1
```
6. Build, tag, and push an image to Amazon ECR
```yml
      - name: Build, tag, and push image to Amazon ECR
        id: build-image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
          ECR_REPOSITORY: ${{ secrets.ECR_REPOSITORY }}
        run: |
          # Build a docker container and
          # push it to ECR so that it can
          # be deployed to ECS.

          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          echo "::set-output name=image::$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG"
```
#### Push to a remote repository
Great! Now, we can push our code to the repository.
Every time, when we push/pull requests the GitHub Actions will run jobs as described in main.yml.
![push](docs/github_actions.png)

In 6 step, we build and push a new image to the ECR. 
Let's check out the ECR repository. 
You should see something like this: 
![new a image](docs/ecr_new_image.png)

### Setting The ECR on the server
To pull the image just created from the ECR to the EC2 server, we need to configure our  `aws cli` as shown below, please write `aws configure` in your a terminal of server:
```bash
$ aws configure
#Output
AWS Access Key ID [None]: <your access key>
AWS Secret Access Key [None]: <your secret key>
Default region name [None]: us-east-1
Default output format [None]: json
```
Next, enter the following command, I copied it from the ECR repository
```bash
$ aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 597884108175.dkr.ecr.us-east-1.amazonaws.com
# Output
WARNING! Your password will be stored unencrypted in /home/ubuntu/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
```
![all commands](docs/ecr_view_commands.png)
![login commands](docs/ecr_login_command.png)

Now, copy URI from created image and run your container.
`docker run -p 8080:3000 ${IMAGE_URI}`
![image uri](docs/ecr_image_uri.png)
```bash
$ docker run -p 8080:3000 597884108175.dkr.ecr.us-east-1.amazonaws.com/simple-ci-cd-aws-ecr:8f9e94e6f4b19180142b48bff6045a28bd990eb6
#Output
Unable to find image '597884108175.dkr.ecr.us-east-1.amazonaws.com/simple-ci-cd-aws-ecr:8f9e94e6f4b19180142b48bff6045a28bd990eb6' locally
8f9e94e6f4b19180142b48bff6045a28bd990eb6: Pulling from simple-ci-cd-aws-ecr
169185f82c45: Pull complete
53e52a67e355: Pull complete
fc2cb9a5e98e: Pull complete
056eb93f952d: Pull complete
1c92e5341865: Pull complete
e5cfcf777036: Pull complete
a6f80ea41547: Pull complete
Digest: sha256:23c991e8c25081e31b9170216df8d942179f623158a2eae57cb97909b3718c0f
Status: Downloaded newer image for 597884108175.dkr.ecr.us-east-1.amazonaws.com/simple-ci-cd-aws-ecr:8f9e94e6f4b19180142b48bff6045a28bd990eb6
```
Before checking it, we need to add port `8080` to the security group`.

#### Update a secure group (Firewall)
Go to the AWS Console and select your EC2 instance.
![select instance](docs/ec2-secure.png)
![select security section](docs/ec2-choose-secure.png)
![select security](docs/ec2-select-group.png)
![select inbound rules](docs/ec2-inbound.png)
![set port ](docs/ec2-set-8080-port.png)
After setting, reboot your server.
![reboot](docs/ec2-reboot.png)

Go to your website `http://ip.address:8080/`. Note! It must be the HTTP protocol! 

![hello world](docs/running_container.png)

### From manual deployment to automatic deployment.
Now, we will automate the pulling down, stopping the old container and starting the new one.

To do this, update your workflow file. 
```yml
- name: Deploy to EC2 via ssh
        env:
          IMAGE_TAG: ${{ github.sha }}
        uses: appleboy/ssh-action@v0.1.4
        with:
          host: ec2-54-173-228-252.compute-1.amazonaws.com
          username: ubuntu
          port: 22
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script_stop: true
          envs: IMAGE_TAG
          script: |
            bash /home/ubuntu/deploy_scripts/deploy.sh ${IMAGE_TAG}
```
then add a new secret `SSH_PRIVATE_KEY` with a value of .pem/.cer file to your repository.
To get the value of your key use the command:
```bash
$ cat aws-linux-ecr.cer
#Output
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAngeAQwRC0rjgvR//Q2FiMdkIHnFxnwarl/Ibn2lIhvj7qV/m
0YQdXirn3FDNCld5DlIE9P/4zZGBbHNqK93hcmmIAauLp+ekjYPta6gXYBnXErMC
blh5tilZLoISa7PumnNWM1jBykDIXhk7AmQj87JLc6ml7Pjyo0REOSDm+mEAvdK4
/mrI723Go8dWXAqCD8DsyxWCCKqaVql1xWnkEo7qucmbqWcws6KznK30pRjfSj2o
FaQ9Dnhqp8kdQi88dasdcGssvgYmRUPIQZcQDck+X0wcsfo2roz0RXne4ydZrss0
6Mh4jGbq4Lg5VZ0WKvZdUHxMb8L2ZtFeRUNrnQIDAQABAoIBAQCB6ASmErCj7NrC
XbVHPJyuAY1NCVCvu5n/dEUEzFWUrsSiPXXPMd26dWbYk4uaPsIC5aWxiWKMClrs
Pgw/invalidkeyInvalidKeYInvaltOYSZNsBks3VdI8Cyz9YJJ6YOmxl/rmOk78
G52In612PVENKZ5+qT88u3ehxsxZcW2Xhf9zFfVmitGQD3xKAKZkRXRNHZ5EcF5b
dpuyuwn5qZtgRbh7pWR8yveZLx5FgZhY3SmmQWfhFdN02eM4qTDMnefReUaO2il5
0UntO/pgGel0RWaEq8kjdP28c140p2lYn7GvQ6/7eLKBymv+ySnVqkSHsrVclsNO
4bams265AoGBAM2rad6ZWq6DfpfB/IhIKHLXe0XjG4ATf0AppSbansIOzNTn7BD
g7AGIbqIYm72HoVDKoGAh6M5iiFsfZUlC2J/UVAbZapASzToeQ2za4R/EoS92pfI
3Hy6Ce2+cVzM6q+b1bzEjuCUFaI5v5jfIwZqszNFWcFTKxRoxyWp3WkjAoGBAMSz
lJu38dOAD/npEgPAXnSdZhDX29uoHX89G2mXmZDWnC+02Uvh05LqFSvPH73PI5HZ
lUgm8yeiLFU2Z14YdliB6wJWxkWyFRypRhGC5jLlwaMuoC2qrPdmXXE/Jt6E8mcc
crT/lPSzf5ETyJ2HqdVduluw1bX3jpRF67UEdgQ/AoGADf8YFGMw+65lvSAyfjva
6KfaYIQ1vlau+ATPUVWyTWUmAjwypeAyWgxQx0z4xexh71e+0MlacbU8vUGQ2lGH
ENDxS65RoOB3PcaEVnZbXsz3CamR8rpspuBSRKetN0+KuSC1zv7hak8pmbysWU72
Jz2jrF2P2iQ6zkzDIMEKnFkCgYEAr5VyEXKoflhxam7/srOUXVpnUp+tVS2DbyIY
BzDZVu4Lq5Yu5kqmdx1XWqzgM6nkoXvtguOp5/Yexs3yhY8mjSkjpAnboTkvGU+N
CXKklEh9inHDcCBLl+gbf0yVIMriKuK9Dg6bY7ebJuDXEq+YDatGADUg//cEohys
JADgbDcCgYBAiENcjLWm4jHACclAK84XbfJCtbuzSdxpWsvA9L19wEczQ812/sLs
NO4XAe0CtIQajqfCla90z29u6AP+pDYNhPTzqPBNnOXXNqVK0LLL//jSCtKQ5cpO
FhJUwcWLZzRO5jsV2BFQOJ/myohuinX4RQDNdqk90xKNrLbW1eUs1Q==
-----END RSA PRIVATE KEY-----%
```
After, you should create a new shell script for deploying in your server `/home/ubuntu/deploy.sh`

```bash
#!/bin/env bash
CONTAINERS=`docker ps -a | awk 'NR>1 {print $1}'`

# Stops all containers
if [ ! -z "$CONTAINERS" ]; then
    # This policy will never automatically start a container. This 	   is the default policy for all containers created with `docker run`.
	docker update --restart=no ${CONTAINERS}
	docker stop ${CONTAINERS}
fi
# Clean up
docker system prune -f -a

IMAGE_ID=$1
ECR_URL="597884108175.dkr.ecr.us-east-1.amazonaws.com"
ECR_REPOSITORY_NAME="simple-ci-cd-aws-ecr"

IMAGE_URI="${ECR_URL}/${ECR_REPOSITORY_NAME}:${IMAGE_ID}"
echo "$1" > ${img_tag_file}

echo "$(date): starting server"
echo "connection to the AWS ECR"
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 597884108175.dkr.ecr.us-east-1.amazonaws.com

docker run -d -p 8080:3000 ${IMAGE_URI}
echo "deployment finished"
```