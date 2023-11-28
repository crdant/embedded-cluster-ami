pkrvars := ${SECRETS_DIR}/embedded-cluster.pkrvars.hcl
params_yaml := ${SECRETS_DIR}/params.yaml

define PKRVARS
project_root		 = "$(PROJECT_DIR)"

application = "$(shell yq .application $(params_yaml))"
admin_console_password = "$(shell sops --decrypt --extract '["admin_console_password"]' $(params_yaml))"

instance_type = "$(shell yq .instance_type $(params_yaml))"
volume_size = $(shell yq .volume_size $(params_yaml))

source_ami = "$(shell yq .source_ami $(params_yaml))"
access_key_id	= "$(shell sops --decrypt --extract '["aws"]["access_key_id"]' $(params_yaml))"
secret_access_key	= "$(shell sops --decrypt --extract '["aws"]["secret_access_key"]' $(params_yaml))"
region = "$(shell yq .aws.region $(params_yaml))"
endef

.PHONY: pkrvars
pkrvars: $(pkrvars)

export PKRVARS
$(pkrvars): $(params_yaml)
	@echo "$$PKRVARS" > $@

.PHONY: init
init: $(pkrvars)
	packer init ${SOURCE_DIR}/packer

.PHONY: create
create: image

.PHONY: image
validate: $(pkrvars)
	packer validate --var-file=${SECRETS_DIR}/embedded-cluster.pkrvars.hcl ${SOURCE_DIR}/packer

.PHONY: image
image: $(pkrvars)
	packer build --force --var-file=${SECRETS_DIR}/embedded-cluster.pkrvars.hcl ${SOURCE_DIR}/packer

clean:
	@rm $(pkrvars)

.PHONY: encrypt
encrypt: 
	@sops --encrypt --in-place $(params_yaml)

.PHONY: decrypt
decrypt: 
	@sops --decrypt --in-place $(params_yaml)
