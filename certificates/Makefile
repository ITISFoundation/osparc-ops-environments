#
#
# by sanderegg, pcrespov, dkaiser

# Include common functionality
REPO_BASE_DIR := $(shell git rev-parse --show-toplevel)

include ${REPO_BASE_DIR}/scripts/common.Makefile
include $(REPO_CONFIG_LOCATION)

# TARGETS --------------------------------------------------
.DEFAULT_GOAL := help

.PHONY: create-certificates
create-certificates: rootca.crt domain.crt domain.key ## create self-signed certificates and ca authority

.PHONY: deploy
deploy: .init
	@if ! docker secret ls | grep -w domain.crt >/dev/null; then docker secret create domain.crt domain.crt; fi;
	@if ! docker secret ls | grep -w domain.key >/dev/null; then docker secret create domain.key domain.key; fi;

	@if [ ! -f rootca.crt ]; then cp domain.crt rootca.crt; fi;
	@if ! docker secret ls | grep -w rootca.crt >/dev/null; then docker secret create rootca.crt rootca.crt; fi;
	@if ! docker secret ls | grep -w storageca.crt >/dev/null; then docker secret create storageca.crt rootca.crt; fi;

rootca.key:
	# Creating key for authority in $@
	@openssl genrsa -out $@ 4096

rootca.crt: rootca.key
	# Creating certificate for authority in $@ from key $< (10000 days validity)
	@openssl req -x509 -new -nodes -key $< \
		-subj "/C=US/ST=sparc/O=oSparc/CN=IT'IS oSparc" \
		-sha384 -days 10000 -out $@;

extfile.cnf:
	@echo "subjectAltName = DNS:${MACHINE_FQDN}, DNS:testing.${MACHINE_FQDN}, DNS:services.testing.${MACHINE_FQDN}, DNS:*.services.testing.${MACHINE_FQDN}, DNS:services.${MACHINE_FQDN}, DNS:*.services.${MACHINE_FQDN}, DNS:traefikdashboard.${MACHINE_FQDN}, DNS:invitations.${MACHINE_FQDN}, DNS:${MONITORING_DOMAIN}, DNS:${STORAGE_DOMAIN}, DNS:${FILESTASH_DOMAIN}, DNS:${REGISTRY_DOMAIN}, DNS:${API_DOMAIN}, DNS:testing.${API_DOMAIN}" > $@ #You can use IP:your_IP or DNS:host_name

domain.key:
	# Creating private key
	@openssl genrsa -out $@ 4096

domain.csr: domain.key
	@openssl req -new -key $< -out $@ \
 		-subj "/C=US/ST=sparc/O=oSparc/CN=${MACHINE_FQDN}"

domain.crt: domain.csr rootca.crt rootca.key extfile.cnf
	# Creating private certificate (500 days validity)
	@openssl x509 -req -in domain.csr \
		-CA rootca.crt \
		-extfile extfile.cnf \
		-CAkey rootca.key \
		-CAcreateserial \
		-out domain.crt \
		-days 500 -sha384

.PHONY: install-root-certificate
install-root-certificate: rootca.crt ## installs a certificate in the host system
	# installing certificate in trusted root certificates and restarting docker daemon...
	@$(if $(IS_WSL2),\
		echo "======================================";\
		certutil.exe -user -addstore -f root $<;				\
		sudo cp $< /usr/local/share/ca-certificates/osparc.crt; \
		if ! sudo update-ca-certificates | grep "0 added" -q -v; then \
		echo "Please restart the DOCKER service now..." && read -n 1; \
		echo "Is the DOCKER service ready? press when ready" && read -n 1; \
	    fi;\
		echo "======================================";,\
		sudo cp $< /etc/ca-certificates/trust-source/anchors/osparc.crt; \
		sudo trust extract-compat &&                            \
		echo "# restarting docker daemon" &&                      \
		sudo systemctl restart docker                           \
	)


.PHONY: remove-root-certificate
remove-root-certificate: ## removes the certificate from the host system
	# deleting certificate from trusted root certificates...
	-@$(if $(IS_WSL2), \
		certutil.exe -user -delstore -f root "*sparc*";\
		sudo rm -f /usr/local/share/ca-certificates/osparc.crt; \
		sudo update-ca-certificates -f; \
	,\
		$(if $(IS_OSX), \
			sudo security remove-trusted-cert -d rootca.crt; \
		, \
		sudo rm -f /etc/ca-certificates/trust-source/anchors/osparc.crt; \
		sudo trust extract-compat; \
		sudo systemctl restart docker; \
		) \
	)
