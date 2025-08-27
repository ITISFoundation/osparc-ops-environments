There is currently no CD for building the fluentd image.
It has to be built and pushed manually:

Run e.g. `docker buildx build --platform linux/amd64,linux/arm64 --push -t itisfoundation/fluentd:v1.16.9-1.0 .` in this folder, then push the image to dockerhub.
Keep in mind that some ops machines run on ARM, so we need an ARM image as well.
