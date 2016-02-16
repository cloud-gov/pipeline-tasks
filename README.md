## cloud.gov common Concourse pipeline tasks

This repo contains the source for some common concourse.ci pipeline tasks.

To include in your pipeline, define a resource named `pipeline-tasks`:
```yaml
resources:

...

- name: pipeline-tasks
  type: git
  source:
    uri: {{pipeline-tasks-git-url}}
    branch: {{pipeline-tasks-git-branch}}
```

Add `pipeline-tasks-git-url` and `pipeline-tasks-git-branch` to your `credentials.yml`:

```yaml
---
pipeline-tasks-git-url: https://github.com/18F/cg-pipeline-tasks.git
pipeline-tasks-git-branch: master
```