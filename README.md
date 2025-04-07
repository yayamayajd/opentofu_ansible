# About this project


This project was originally developed as part of a group assignment at school.
This repository contains my own personal version and implementation of that project.
here is the result:

![the result of the project](/images/results.png)



This is a group assignment from school with the following goals:
Define and provision a working infrastructure using OpenTofu,
and automate configuration and installation using Ansible.

**🔧 The project includes:**


Three EC2 instances: two for web servers and one for the database.

One load balancer: to distribute traffic between the web server instances.

Three subnets: two public subnets for the web servers, and one private subnet for the database.

Security groups and IAM roles/policy documents: to restrict access based on best practices.

Ansible configuration: for installing and configuring both the web servers and the database.

Launch script: to create, install, and configure the infrastructure so that the web application is up and running and accessible.

*The flask-app code is offered from the teacher



**About OpenTofu**

OpenTofu is an open-source fork of Terraform that enables declarative infrastructure-as-code (IaC). Instead of writing step-by-step instructions, you define the desired state of your infrastructure, and OpenTofu automatically provisions or updates resources to match. It supports repeatable, version-controlled deployments, and simplifies the creation of cloud infrastructure such as VPCs, subnets, and EC2 instances. OpenTofu is cloud-agnostic and ideal for teams practicing DevOps or GitOps workflows.


**About Ansible**

Ansible is a lightweight, agentless configuration management and automation tool. It connects to remote machines via SSH and only requires Python and a Unix-like environment on the control node—no additional software needs to be installed on managed nodes. Ansible is known for its idempotency, meaning tasks can be safely run multiple times without unintended side effects. Its simple, human-readable YAML syntax makes it accessible while remaining powerful for provisioning, deployment, and orchestration.




**🚀 Deployment Guide**

***Step 1: Update Your IP in tfvars***

Edit your Terraform variables file and set your current Cloud Shell IP:

terraform.tfvars
allowed_ip = "the cloudshell ip/32"

***Step 2: Deploy Infrastructure with OpenTofu***

tofu init
tofu plan
tofu apply

***Step 3: Install Ansible***

./install_ansible

Then:

Update the Ansible inventory file with your EC2 instance IPs

Optionally update ~/.ssh/config for easier SSH access

***Step 4: SSH into the Jump Box***

ssh -i ~/.ssh/tofu-key ec2-user@<JUMP_BOX_PUBLIC_IP>

***Step 5: Test SSH to Private Instance via Jump Box***

ssh -i ~/.ssh/tofu-key \
  -o ProxyCommand="ssh -i ~/.ssh/tofu-key -W %h:%p ec2-user@<JUMP_BOX_PUBLIC_IP>" \
  ec2-user@<PRIVATE_DB_IP>

***Step 6: Run Ansible Playbook***

ansible-playbook -i inventory.yaml site.yaml




## 🔗 Dependency Summary Table

| **Component**                  | **Depends On**                            |
|-------------------------------|-------------------------------------------|
| Subnets                       | VPC                                       |
| Internet Gateway (IGW)        | VPC                                       |
| NAT Gateway                   | EIP, Public Subnet, IGW                   |
| Route Tables                  | VPC, IGW / NAT                            |
| Security Groups               | VPC                                       |
| EC2 Instances                 | Subnet, Security Group, Key Pair, AMI     |
| Application Load Balancer     | 2 Public Subnets, Security Group          |
| Target Group                  | VPC                                       |
| Target Group Attachment       | EC2 Instances, Target Group               |
| Listener                      | ALB, Target Group                         |


**problems and solutions** 

***About alb：*** 

One of the biggest issues was that ALB need to be created, but could not.  Because there were only 1 pub-sub from the beginning(accoring to the misslead of the compoment-list from school).

After the research, the conclusion came: AWS ALB requires at least two subnets in different Availability Zones. This is not just a best practice—it's a strict requirement. The subnets act as entry points for the ALB and ensure HA in the event of an AZ failure. Subnets in AWS are inherently bound to a single Availability Zone and cannot span across multiple zones. As a result, even if you have two EC2 instances in different AZs, they must reside in separate subnets. You cannot create one subnet across multiple AZs. This is why the ALB must be associated with two or more distinct subnets, each in a different AZ.

source from AWS official documents:

https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#subnets

also according to:

https://docs.aws.amazon.com/vpc/latest/userguide/how-it-works.html

"each subnet must reside entirely within one Availability Zone and cannot span zones."



***About ansible ping didn’t work:***

It was frustrating that finally all the tofu files had been built, but Ansible couldn’t even run a simple ping command to the private EC2. Manual SSH worked fine, but Ansible kept failing. Adding -vvvv to the Ansible command revealed the issue: missing SSH key. During testing, Ansible was initially unable to SSH into the private subnet EC2 instance. To troubleshoot,  manually ran an SSH command to the bastion host, then used a ProxyCommand-based SSH connection to the private instance. This process validated the SSH key and network path, and also, it established a trust entry in ~/.ssh/known_hosts, which resolved Ansible’s strict host key checking error. After this, Ansible was able to connect successfully.


***About NAT gateway:***

Can run ping with ansible, but to run deplyment.yml, always failed. The process is always stacked on install postgres. Tried SSH to the ec2s, used different ways to check the network, found out no network in this private subnet. (Although it can be ping and SSH from ansible, so make the logic mistake that it can take TCP packets)
Yes, it lacks a NAT gateway to connect to the internet(for install or update). So back to the tofu files and add the NAT gateway(eid, private rt at the same time also) it worked.
Had a discussion with another group, because according to what they said, Nat gateway is in a private sub, and connects to the internet directly. But the fact needs to be clarified is that the NAT gateway depends on a pubsub and eid, the traffic will go through IGW. 

source：https://docs.aws.amazon.com/vpc/latest/userguide/how-it-works.html