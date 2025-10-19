# Chapter 1: Hello World - Your First Container

The classic "Hello, World!" in Docker. This demonstrates the complete Docker workflow: pulling images, creating containers, and running them.

## What This Example Demonstrates

- How Docker pulls images from Docker Hub
- Creating and running a container
- The complete container lifecycle
- Image caching behavior

## Run It

```bash
docker run hello-world
```

## What Happens Behind the Scenes

1. Docker checks for `hello-world` image locally
2. If not found, downloads from Docker Hub
3. Creates a container from the image
4. Runs the container
5. Container prints message and exits
6. Container stops (but still exists)

## Expected Output

```
Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.
```

## Try Running It Again

```bash
# Run it a second time
docker run hello-world
```

Notice it's faster? Docker cached the image. It didn't need to download again.

## Check Your Images

```bash
# List downloaded images
docker images

# You'll see:
# REPOSITORY    TAG       IMAGE ID       CREATED       SIZE
# hello-world   latest    9c7a54a9a43c   3 weeks ago   13.3kB
```

## Check Your Containers

```bash
# List running containers (none, it exited)
docker ps

# List ALL containers (including stopped)
docker ps -a

# You'll see stopped hello-world containers
```

## Cleanup

```bash
# Remove stopped containers
docker rm $(docker ps -a -q --filter ancestor=hello-world)

# Remove the image
docker rmi hello-world
```

## Key Takeaways

✅ `docker run` combines pull + create + start
✅ Images are cached locally after first download
✅ Containers remain after stopping (unless `--rm` flag used)
✅ Docker Hub is the default registry

## Next Steps

Try running a more interactive container:

```bash
# Run an interactive Ubuntu container
docker run -it ubuntu:22.04 bash

# Inside the container, try:
cat /etc/os-release
ls /
exit
```

**Reference:** Docker Field Manual, Chapter 1, Page 12
