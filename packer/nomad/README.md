# packer

## Folder Descriptions
- config - Had to put the configs in the image because scp is disabled in Instruct. I also could have done them dynamically, but that causes a slower stratup experience for the user.
- scripts - These are the base scripts to install the software.

## Workflow
- Copy the variables.pkrvars.hcl.example to variables.pkrvars.hcl and fill in your information.
- Build the images using:
```
packer build -force -var-file="variables.pkrvars.hcl" .
```