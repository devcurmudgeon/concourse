#lang concourse/docs

@(require "../common.rkt")

@title[#:style 'toc #:version version #:tag "configuring-resources"]{@code{resources}@aux-elem{: Objects flowing through the pipeline}}

@seclink["resources"]{Resources} are the objects that are going to be used
for jobs in the pipeline. They are listed under the @code{resources} key in
the pipeline configuration.

The following example defines a resource representing Concourse's BOSH
release repository:

@codeblock|{
resources:
- name: concourse
  type: git
  source:
    uri: https://github.com/concourse/concourse.git
}|

Any time commits are pushed, the resource will detect them and save new
versions of the resource. Any jobs immediately downstream of the resource
will then be triggered with the latest version, potentially starting a
chain of builds as it makes its way through the pipeline's jobs.

Resources can also be updated via a @seclink["put-step"]{@code{put} step} in
the pipeline's jobs.

Each configured resource consists of the following attributes:

@defthing[name string]{
  @emph{Required.} The name of the resource. This should be short and simple.
  This name will be referenced by @seclink["build-plans"]{build plans} of jobs
  in the pipeline.
}

@defthing[type string]{
  @emph{Required.} The type of the resource. Each worker advertises a mapping
  of @code{resource-type -> container-image}; @code{type} corresponds to the
  key in the map.

  To see what resource types your deployment supports, check the status of your
  worker pool via the @code{/api/v1/workers} API endpoint.
}

@defthing[source object]{
  @emph{Optional.} The location of the resource. This varies
  by resource type, and is a black box to Concourse; it is blindly passed to
  the resource at runtime.

  To use @code{git} as an example, the source may contain the repo URI, the
  branch of the repo to track, and a private key to use when pushing/pulling.

  By convention, documentation for each resource type's configuration is
  in each implementation's @code{README}.

  You can find the source for the resource types provided with Concourse at the
  @hyperlink["https://github.com/concourse?query=-resource"]{Concourse
  GitHub organization}.
}

@inject-analytics[]
