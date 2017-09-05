repo := docker.jiwiredev.com
docker-build-opt := --pull --force-rm
name := pca-mist

tag := mist-0.0.27
pca-python-ver := 0.4.27-pca-581-3

build:
	docker build ${docker-build-opt} -t "${repo}/nined/${name}:${tag}" \
	    --build-arg PCA_PYTHON_VER="${pca-python-ver}" \
		.

push:
	docker push "${repo}/nined/${name}:${tag}"
	