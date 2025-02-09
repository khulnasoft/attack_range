# Attack Range Azure

## Docker
We built a docker image which you can use to build and run the attack range. The image includes all needed binaries. 
````bash
docker pull khulnasoft/attack_range
docker run -it khulnasoft/attack_range
az login
python attack_range.py configure
````

## MacOS
Install and configure Terraform:
````bash
brew update
brew install terraform
cd terraform/azure && terraform init && cd ../..
````

Install Packer:
````bash
brew tap hashicorp/tap
brew install hashicorp/tap/packer
````

Install the Azure CLI:
````bash
brew install azure-cli
az login
````

Install and run Poetry:
````bash
curl -sSL https://install.python-poetry.org/ | python -
poetry shell
poetry install
````

Configure Attack Range:
````bash
python attack_range.py configure
````

## Linux
Install the required packages:
````bash
apt-get update
apt-get install -y python3.8 git unzip python3-pip curl
````

Install and configure Terraform:
````bash
curl -s https://releases.hashicorp.com/terraform/1.1.8/terraform_1.1.8_linux_amd64.zip -o terraform.zip && \
unzip terraform.zip && \
mv terraform /usr/local/bin/
````

Install Packer:
````bash
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install packer
````

Install the Azure CLI:
````bash
apt-get install -y azure-cli
az login
````

Install and run Poetry:
````bash
curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python -
poetry shell
poetry install
````

Configure Attack Range:
````bash
python attack_range.py configure
````

## Windows
We recommend to use the Windows Subsystem for Linux (WSL). You can find a tutorial [here](https://docs.microsoft.com/en-us/windows/wsl/install). After installed WSL, you can follow the steps described in the Linux section.