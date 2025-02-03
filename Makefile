PKRVARS_FILE := ${SECRETS_DIR}/embedded-cluster.pkrvars.hcl
PARAMS := ${SECRETS_DIR}/params.yaml

APPS := $(shell replicated app ls --output json | jq -c .) 
APP_SLUGS := $(shell echo '$(APPS)' | jq -r '.[].app.slug')

SALT := $(shell openssl rand -hex 64)

define PKRVARS
project_root		 = "$(PROJECT_DIR)"
replicated_api_token="$(shell sops --decrypt --extract '["replicated"]["api_token"]' $(PARAMS))"

shadow    = "$(shell openssl passwd -6 -salt $(SALT) $(shell yq .default_password $(PARAMS)))"

instance_type = "$(shell yq .instance_type $(PARAMS))"

volume_size = $(shell yq .volume_size $(PARAMS))

source_ami          = "$(shell yq .source_ami $(PARAMS))"
source_iso          = "$(shell yq .source_iso ${PARAMS})"
source_iso_checksum = "$(shell yq .source_iso_checksum ${PARAMS})"

access_key_id	= "$(shell sops --decrypt --extract '["aws"]["access_key_id"]' $(PARAMS))"
secret_access_key	= "$(shell sops --decrypt --extract '["aws"]["secret_access_key"]' $(PARAMS))"
regions = $(shell yq --output-format json .aws.regions $(PARAMS))

vsphere_server   = "$(shell yq .vsphere.server ${PARAMS})"
vsphere_username = "$(shell yq .vsphere.username ${PARAMS})"
vsphere_password = "$(shell sops --decrypt --extract '["vsphere"]["password"]' ${PARAMS})"

vsphere_datacenter      = "$(shell yq .vsphere.datacenter ${PARAMS})"
vsphere_cluster         = "$(shell yq .vsphere.cluster ${PARAMS})"
vsphere_network         = "$(shell yq .vsphere.network ${PARAMS})"
vsphere_datastore       = "$(shell yq .vsphere.datastore ${PARAMS})"

authorized_keys = $(shell yq --output-format json .ssh.authorized_keys ${PARAMS})

output_directory = "${WORK_DIR}"
endef

define make-channel-targets
.PHONY: image\:$(1)/$(2) ami\:$(1)/$(2) validate\:$(1)/$(2) debug\:$(1)/$(2) console\:$(1)/$(2)
image\:$(1)/$(2): 
	packer build --force --var 'application=$(1)' --var 'channel=$(2)' \
		--var-file=${SECRETS_DIR}/embedded-cluster.pkrvars.hcl ${SOURCE_DIR}/packer

ami\:$(1)/$(2): $(PKRVARS_FILE) ${SOURCE_DIR}/packer/*.hcl ${SOURCE_DIR}/packer/templates/*.tmpl
	packer build --only="amazon-ebs.embedded-cluster" --force --var 'application=$(1)' --var 'channel=$(2)' \
		--var-file=${SECRETS_DIR}/embedded-cluster.pkrvars.hcl ${SOURCE_DIR}/packer

ova\:$(1)/$(2): work/$(1)-$(2)-ubuntu-22.04-lts.ova

work/$(1)-$(2)-ubuntu-22.04-lts/$(1)-$(2)-ubuntu-22.04-lts.ovf: $(PKRVARS_FILE) ${SOURCE_DIR}/packer/*.hcl ${SOURCE_DIR}/packer/templates/*.tmpl
	packer build --only="vsphere-iso.embedded-cluster" --force --var 'application=$(1)' --var 'channel=$(2)' \
		--var-file=${SECRETS_DIR}/embedded-cluster.pkrvars.hcl ${SOURCE_DIR}/packer

work/$(1)-$(2)-ubuntu-22.04-lts.ova: work/$(1)-$(2)-ubuntu-22.04-lts/$(1)-$(2)-ubuntu-22.04-lts.ovf 
	python src/python/add-ovf-properties.py --application $(1) --channel $(2) work/$(1)-$(2)-ubuntu-22.04-lts/$(1)-$(2)-ubuntu-22.04-lts.ovf 
	ovftool --targetType=OVA --diskMode=thin --overwrite work/$(1)-$(2)-ubuntu-22.04-lts/$(1)-$(2)-ubuntu-22.04-lts.ovf work/$(1)-$(2)-ubuntu-22.04-lts.ova

validate\:$(1)/$(2): $(PKRVARS_FILE)
	packer validate --var 'application=$(1)' --var 'channel=$(2)' \
		--var-file=${SECRETS_DIR}/embedded-cluster.pkrvars.hcl ${SOURCE_DIR}/packer

debug\:$(1)/$(2): $(PKRVARS_FILE)
	packer build --force --debug --var 'application=$(1)' --var 'channel=$(2)' \
		--var-file=${SECRETS_DIR}/embedded-cluster.pkrvars.hcl ${SOURCE_DIR}/packer

console\:$(1)/$(2): $(PKRVARS_FILE)
	packer console --var 'application=$(1)' --var 'channel=$(2)' \
		--var-file=${SECRETS_DIR}/embedded-cluster.pkrvars.hcl ${SOURCE_DIR}/packer
endef

define make-app-targets
CHANNELS := $(shell echo '$(APPS)' | jq -r --arg slug $(1) '.[] | select(.app.slug == $$slug) | .channels[].channelSlug')
$(foreach element,$(CHANNELS),$(eval $(call make-channel-targets,$(1),$(element))))
endef
$(foreach element,$(APP_SLUGS),$(eval $(call make-app-targets,$(element))))

.PHONY: pkrvars
pkrvars: $(PKRVARS_FILE)

export PKRVARS
$(PKRVARS_FILE): $(PARAMS)
	@echo "$$PKRVARS" > $@

.PHONY: init
init: $(PKRVARS_FILE)
	packer init ${SOURCE_DIR}/packer

clean:
	@rm $(PKRVARS_FILE)

.PHONY: encrypt
encrypt: 
	@sops --encrypt --in-place $(PARAMS)

.PHONY: decrypt
decrypt: 
	@sops --decrypt --in-place $(PARAMS
