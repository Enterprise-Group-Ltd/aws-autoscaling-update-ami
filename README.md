# EGL AWS Autoscaling Update AMI Utility

This utility updates autoscaling Launch Configurations and associated autoscaling groups with a new AMI.

This utility provides Autoscaling AMI update functionality unavailable in the AWS console or directly via the AWS CLI API. 

This utility can: 

* Create a new clone Launch Configuration for every Launch Configuration using the old, target AMI
* Update all clone Launch Configurations to use the new AMI
* Update all associated Autoscaling Groups to use the new Launch Configuration with the new AMI
* Retain X prior Launch Configuration versions  
* Append text to the Launch Configuration name
* Enable or disable EC2 instance detailed monitoring
* Add a security group to all Launch Configurations    

This utility produces a summary report listing:

* The AWS account and alias
* The old AMI ID and name
* The new AMI ID and name
* The number of prior launch configuration versions to retain
* The number of launch configurations updated
* The number of autoscaling groups updated
* Errors
* List of prior version Launch Configurations deleted
* List of each set of new and old AMIs, new and old Launch Configurations and associated Autoscaling Groups  


## Getting Started

1. Instantiate a local or EC2 Linux instance
2. Install or update the AWS CLI utilities
    * The AWS CLI utilities are pre-installed on AWS EC2 Linux instances
    * To update on an AWS EC2 instance: `$ sudo pip install --upgrade awscli` 
3. Create an AWS CLI named profile that includes the required IAM permissions 
    * See the "[Prerequisites](#prerequisites)" section for the required IAM permissions
    * To create an AWS CLI named profile: `$ aws configure --profile MyProfileName`
    * AWS CLI named profile documentation is here: [Named Profiles](http://docs.aws.amazon.com/cli/latest/userguide/cli-multiple-profiles.html)
4. Install the [bash](https://www.gnu.org/software/bash/) shell
    * The bash shell is included in most distributions and is pre-installed on AWS EC2 Linux instances
5. Install [jq](https://github.com/stedolan/jq) 
    * To install jq on AWS EC2: `$ sudo yum install jq -y`
6. Download this utility script or create a local copy and run it on the local or EC2 linux instance
    * Example: `$ bash ./autoscaling-update-ami.sh -p AWS_CLI_profile -n new_AMI_ID_or_name -t old_target_AMI_ID_or_name -a append-text`  

## [Prerequisites](#prerequisites)

* [bash](https://www.gnu.org/software/bash/) - Linux shell 
* [jq](https://github.com/stedolan/jq) - JSON wrangler
* [AWS CLI](https://aws.amazon.com/cli/) - command line utilities (pre-installed on AWS AMIs) 
* AWS CLI profile with IAM permissions for the following AWS CLI commands:  
  * aws autoscaling create-launch-configuration
  * aws autoscaling delete-launch-configuration
  * aws autoscaling describe-auto-scaling-groups
  * aws autoscaling describe-launch-configurations
  * aws autoscaling update-auto-scaling-group
  * aws ec2 describe-images (used to test AMI)
  * aws iam list-account-aliases (used to pull AWS account alias)
  * aws sts get-caller-identity (used to pull AWS acount)


## Deployment

To execute the utility:

  * Example: `$ bash ./autoscaling-update-ami.sh -p AWS_CLI_profile -n new_AMI_ID_or_name -t old_target_AMI_ID_or_name -a append-text`  

To directly execute the utility:  

1. Set the execute flag: `$ chmod +x autoscaling-update-ami.sh`
2. Execute the utility  
    * Example: `$ ./autoscaling-update-ami.sh -p AWS_CLI_profile -n new_AMI_ID_or_name -t old_target_AMI_ID_or_name -a append-text`    

## Output

* Summary report 
* Debug log (execute with the `-g y` parameter)  
  * Example: `$ bash ./autoscaling-update-ami.sh -p AWS_CLI_profile -n new_AMI_ID_or_name -t old_target_AMI_ID_or_name -a append-text -g y`  
* Console verbose mode (execute with the `-b y` parameter)  
  * Example: `$ bash ./autoscaling-update-ami.sh -p AWS_CLI_profile -n new_AMI_ID_or_name -t old_target_AMI_ID_or_name -a append-text -b y`  

## Contributing

Please read [CONTRIBUTING.md](https://github.com/Enterprise-Group-Ltd/aws-autoscaling-update-ami/blob/master/CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. 

## Authors

* **Douglas Hackney** - [dhackney](https://github.com/dhackney)

## License

This project is licensed under the MIT License - see the [LICENSE.md](https://github.com/Enterprise-Group-Ltd/aws-autoscaling-update-ami/blob/master/LICENSE) file for details

## Acknowledgments

* [Progress bar](https://stackoverflow.com/questions/238073/how-to-add-a-progress-bar-to-a-shell-script)  
* [Dynamic headers fprint](https://stackoverflow.com/questions/5799303/print-a-character-repeatedly-in-bash)
* [Menu](https://stackoverflow.com/questions/30182086/how-to-use-goto-statement-in-shell-script)
* Countless other jq and bash/shell man pages, Q&A, posts, examples, tutorials, etc. from various sources  

