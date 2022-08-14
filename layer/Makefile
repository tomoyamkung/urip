build-BootstrapLayer:
	# Install AWS CLI
	pip3 install awscli -t $(ARTIFACTS_DIR)

	# Install jq
	# Download the binary and add it to your path.
	curl -sSL https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -o $(ARTIFACTS_DIR)/jq

	chmod +x $(ARTIFACTS_DIR)/bin/ $(ARTIFACTS_DIR)/jq