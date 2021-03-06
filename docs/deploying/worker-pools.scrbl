#lang concourse/docs

@(require "../common.rkt")

@title[#:version version #:tag "worker-pools"]{Worker Pools}

Workers are @hyperlink["http://github.com/cloudfoundry-incubator/garden"]{Garden}
servers, continuously heartbeating their presence to the Concourse API. Workers
have a statically configured @code{platform} and a set of @code{tags}, both of
which determine where tasks are scheduled.

The worker also advertises which resource types it supports. This is just a
mapping from resource type (e.g. @code{git}) to the image URI
(e.g. @code{/var/vcap/packages/...} or @code{docker:///concourse/git-resource}).

For a given resource, the workers declaring that they support its type are used
to run its containers. The @code{platform} does not matter in this case.

For a given task, only workers with a @code{platform} that matches the
task's @code{platform} will be chosen. A worker's @code{platform} is
typically one of @code{linux}, @code{windows}, or @code{darwin}, but this is
just convention.

If a worker specifies @code{tags}, it is taken out of the "default" placement
pool, and tasks only run on the worker if they explicitly specify a common
subset of the worker's tags. This can be done in the task's configuration
directly (see @secref{configuring-tasks}) or by specifying them in the job
that's running the task (see @secref{pipelines}).

Worker registration can be done directly via the ATC API, or through the
@seclink["tsa"]{TSA}. You can see the current set of workers via @code{GET
/api/v1/workers}, and register one via @code{POST /api/v1/workers} with a
worker API object as the payload.

For example:

@codeblock|{
  {
    "platform": "linux",
    "tags": ["hetzner"],
    "addr": "10.0.16.10:8080",
    "active_containers": 123,
    "resource_types": [
      {"type": "git", "image": "/var/vcap/packages/git_resource"}
    ]
  }
}|

The worker JSON object contains the following attributes:

@defthing[platform string]{
  @emph{Required.} The platform supported by the worker, e.g. @code{linux},
  @code{darwin}, or @code{windows}.
}

@defthing[tags [string]]{
  @emph{Optional.} A set of arbitrary tags. Only tasks matching a subset of
  these tags will be placed on the worker.
}

@defthing[addr string]{
  @emph{Required.} The address of the Garden server. Note that this address
  must be reachable by the ATC, and has no authentication. For this reason it
  should always be an address only reachable from within Concourse's private
  network. To register external workers, see @secref{forwarding-via-tsa}.
}

@defthing[active_containers integer]{
  @emph{Optional.} The number of containers currently running on the worker.
}

@defthing[resource_types [{type, image}]]{
  @emph{Optional.} The set of resource types supported by the worker. If
  specified, the worker may be used for running resource containers of the
  given type, using the specified image URI.
}


@section[#:tag "other-workers"]{Windows and OS X Workers}

For Windows and OS X, a primitive Garden backend is available, called
@hyperlink["http://github.com/vito/houdini"]{Houdini}.

@margin-note{
  Containers running via Houdini are not isolated from each other. This is
  much less safe than the Linux workers, but will do just fine if you trust
  your builds.

  A proper @hyperlink["https://github.com/cloudfoundry-incubator/garden-windows"]{Garden Windows}
  implementation is in the works.
}

To set up Houdini, download the appropriate binary from its
@hyperlink["https://github.com/vito/houdini/releases/latest"]{latest GitHub
release}.

By default, Houdini will place container data in @code{./containers}
relative to wherever Houdini started from. To change this location, or see
other settings, run Houdini with @code{--help}.


@section[#:tag "linux-workers"]{Out-of-band Linux Workers}

A typical Concourse deployment includes Garden Linux, which is what provides
the default Linux workers.

If you're deploying with BOSH, all worker configuration is automatic, and
you can dynamically grow and shrink the worker pool just by changing the
instance count and redeploying.

However, sometimes your workers can't be automated by BOSH. Perhaps you have
some managed server, and you want to run builds on it.

To do this, you'll probably want to provision Garden Linux to your machine
manually. This can be done with Vagrant via the
@hyperlink["https://github.com/tknerr/vagrant-managed-servers"]{Vagrant
Managed Servers} provider and the
@hyperlink["https://github.com/cppforlife/vagrant-bosh"]{Vagrant BOSH}
provisioner.


@section[#:tag "tsa"]{Registering workers via the TSA}

The @hyperlink["https://github.com/concourse/tsa"]{TSA} is a SSH server that
can register and heartbeat workers via two pseudo-commands:
@code{register-worker} and @code{forward-worker}.

Both commands read a worker JSON payload from @code{stdin}. So long as the
SSH connection is live and the Garden server is responsive, the TSA will
register it with the ATC.


@subsection[#:tag "authorizing-with-tsa"]{Authenticating}

The TSA authorizes connections via public key authentication only (no
passwords).

Concourse automatically generates and authorizes a keypair for all workers
within the BOSH deployment, so you don't have to do any extra configuration
to register internal workers.

@margin-note{
  In the event of a leak, the auto-generated keypair can be disabled by
  setting the
  @elem[#:style break-word]{@code{tsa.authorize_generated_worker_key}}
  property to @code{false}.
}

To register an external worker using the TSA, however, you'll first need to
generate a private key, and then list it as an authorized key. For a BOSH
deployment, this can be done by listing the authorized public keys under the
@code{tsa.authorized_keys} property.


@subsection[#:tag "registering-via-tsa"]{Registering a worker directly}

The @code{register-worker} command is used when you have a Garden worker
accessible from within the private network. For example, registering a
Windows EC2 instance with the rest of your cluster, all within a VPC. This
is also the default registration mode for all Concourse workers within the
deployment.

So, to register a worker for direct access, you would run something like this:

@verbatim|{
  ssh \
    -i path/to/private-key \
    -p 2222 some-atc.com \
    register-worker < worker.json
}|

...where @code{worker.json} contains the worker JSON payload to advertise.


@subsection[#:tag "forwarding-via-tsa"]{Forwarding a local Garden server}

The @code{forward-worker} command is used when you want to tunnel a
locally-reachable Garden server (e.g. one listening on @code{127.0.0.1})
through the TSA, who will advertise the tunneled address on the client's
behalf.

For example, to securely register a local Garden server as a worker, you
would run:

@verbatim|{
  ssh \
    -i path/to/private-key \
    -R 0.0.0.0:0:127.0.0.1:7777 \
    -p 2222 some-atc.com \
    forward-worker < worker.json
}|

...where @code{127.0.0.1:7777} is the address of the local Garden server,
and @code{worker.json} is a file containing the worker JSON payload (sans
@code{"addr"}).


@inject-analytics[]
