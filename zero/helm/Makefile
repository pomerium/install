.PHONY: lint test template clean

lint:
	helm lint .

test: lint
	./tests/helm_test.sh

template:
	helm template test . --set pomeriumZeroToken=test-token

template-deployment:
	helm template test . --set pomeriumZeroToken=test-token --set persistence.enabled=false

clean:
	rm -rf charts/ *.tgz

package: lint test
	helm package .
