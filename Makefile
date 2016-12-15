GITLAB_URL=http://${GITLAB_IP}:${GITLAB_PORT}/
REG_TOKEN=${GITLAB_TOKEN}


gitlab-runner: ubuntu

debian: apt-pinning-debian repo-ansible install
ubuntu: repo-ansible install

apt-pinning-debian:
	ansible-playbook main.yml -i localhost -t apt_pinning_debian

repo-script:
	ansible-playbook main.yml -i localhost -t repo_script

repo-ansible:
	ansible-playbook main.yml -i localhost -t repo_ansible

install:
	ansible-playbook main.yml -i localhost -t install

verify:
	sudo -u gitlab-runner -H docker info

register: register-shell-runner register-dind-runner register-socket-runner

register-shell-runner:
	gitlab-ci-multi-runner register -n \
  --url ${GITLAB_URL} \
  --registration-token ${REG_TOKEN} \
  --executor shell \
  --description "shell-runner"

register-dind-runner:
	gitlab-ci-multi-runner register -n \
  --url ${GITLAB_URL} \
  --registration-token ${REG_TOKEN} \
  --executor docker \
  --description "dind-runner" \
  --docker-image "docker:latest" \
  --docker-privileged

register-socket-runner:
	sudo gitlab-ci-multi-runner register -n \
  --url ${GITLAB_URL} \
  --registration-token ${REG_TOKEN} \
  --executor docker \
  --description "socket-runner" \
  --docker-image "docker:latest" \
  --docker-volumes /var/run/docker.sock:/var/run/docker.sock

# https://gitlab.com/gitlab-org/gitlab-runner-docker-cleanup
cleanup:
	docker run -d \
    -e LOW_FREE_SPACE=10G \
    -e EXPECTED_FREE_SPACE=20G \
    -e LOW_FREE_FILES_COUNT=1048576 \
    -e EXPECTED_FREE_FILES_COUNT=2097152 \
    -e DEFAULT_TTL=10m \
    -e USE_DF=1 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    --name=gitlab-runner-docker-cleanup \
    quay.io/gitlab/gitlab-runner-docker-cleanup
