rstudio-server-rpi4b

## AIMS

Principal aim is to provide a Dockerfile to run RStudio Server Open on a
Raspberry Pi 4B, i.e. compiled for an ARM64v8 (aarch64).

More likely, it could provide a working starting point for people much
smarter than me to create a "good" Docker image to achieve the
principal aim.

## NOTE

1. For the moment [rocker project](https://www.rocker-project.org/) provide
a r-base image for aarch64 but building their rstudio's Dockerfile
return the following error

```
Step 6/9 : RUN /rocker_scripts/install_rstudio.sh
 ---> [Warning] The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested
 ---> Running in 59fc51c9b3fa

standard_init_linux.go:219: exec user process caused: exec format error
```

That Dockerfile calls
[`install_rstudio.sh`](https://github.com/rocker-org/rocker-versioned2/blob/master/scripts/install_rstudio.sh)
to install RStudio, and it considers AMD64 only. The issue is relevant
both for the installation of RStudio and S6 (inside the
[`install_s6init.sh`](https://github.com/rocker-org/rocker-versioned2/blob/master/scripts/install_s6init.sh)).
S6 provide binary for aarch64, but rstudio not yet (see
[this](https://github.com/rstudio/rstudio/issues/8809), and
[this](https://github.com/rstudio/rstudio/issues/8652) issues on
RStudio's GitHub profile).



2. https://github.com/elbamos/rstudio-m1 actually works and compile
correctly on rpi4b. @elbamos states this docker is based on an old
version of rocker's scripts, and that it is quite large as image, so I
think this repo can still be useful.

3. Based on @elbamos's repo, I have build an rpi4b image which is
accessible [here](https://hub.docker.com/r/corradolanera/rstudio-rpi4b).
For the moment it has the following tags `latest`, `elbamos`
(i.e., source for the Dockerfile), and `v1.4.1106` (i.e., the RStudio
version).


## State of the project

- [x] it starts :-)

- [ ] it doesn't login :-(

- [ ] it doesn't persists, i.e. if run into bash with `-it` and the
  server is manually started it works (even if the user is not
  recognised), but when a container is run as is the servise starts and
  stops immediately.

- [ ] the crashpad is not installed due to the following error rised during the build fase of rstudiom (and I was not able to fix it):
    ```
    /opt/rstudio-tools/crashpad/crashpad/out/Default/obj/client/libclient.a: error adding symbols: File in wrong format
    collect2: error: ld returned 1 exit status
    ```

I would/will try to include/adapt all the rocker's scripts to this
project, possibly using as a starting point the
[@elbamos](https://github.com/elbamos/rstudio-m1)' project (which
actually compile on rpi4b too).

## Acknowledge
To construct this Dockerfile I started from, used,  modified or
integrated codes from many resources, the main ones are:

- https://github.com/dashaub/ARM-RStudio/blob/master/ARM-RStudio.sh
- https://github.com/jrowen/ARM-rstudio-server/blob/master/build_rstudio.sh
- https://github.com/rstudio/rstudio/blob/master/docker/jenkins/Dockerfile.debian9-x86_64
- https://github.com/rocker-org/rocker-versioned2/blob/master/scripts/install_rstudio.sh


## License
This program is licensed under the terms of version 3 of the
GNU Affero General Public License. This program is distributed WITHOUT
ANY EXPRESS OR IMPLIED WARRANTY, INCLUDING THOSE OF NON-INFRINGEMENT,
MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. Please refer to the
AGPL (http://www.gnu.org/licenses/agpl-3.0.txt) for more details.
