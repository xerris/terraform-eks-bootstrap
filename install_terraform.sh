
#!/bin/bash


  sudo curl -o terraform_0.15.1_linux_amd64.zip https://releases.hashicorp.com/terraform/0.15.1/terraform_0.15.1_linux_amd64.zip
  sudo unzip -o terraform_0.15.1_linux_amd64.zip -d /bin
  export PATH=$PATH:./bin/