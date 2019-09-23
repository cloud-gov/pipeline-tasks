## cloud.gov common Concourse pipeline tasks

This repo contains the source for some common concourse.ci pipeline tasks.

To include in your pipeline, define a resource named `pipeline-tasks`:
```yaml
resources:

...

- name: pipeline-tasks
  type: git
  source:
    uri: ((pipeline-tasks-git-url))
    branch: ((pipeline-tasks-git-branch))
```

Add `pipeline-tasks-git-url` and `pipeline-tasks-git-branch` to your `credentials.yml`:

```yaml
---
pipeline-tasks-git-url: https://github.com/18F/cg-pipeline-tasks.git
pipeline-tasks-git-branch: master
```

## Task usage
### bosh-errand
### decrypt
### display
### encrypt
### finalize-bosh-release
### inspect
### spiff-merge
### terraform-apply
### terraform-destroy
### terraform-state-to-yaml
Reads a terraform state file to get the terraform `outputs` and converts to yaml for use in spiff merging into other BOSH templates.

Requires:
 - STATE_FILE: The terraform state file

Outputs:
 - terraform-yaml/state.yml

```yaml
  - get: my-other-manifest-bits
  - get: s3-terraform-state
  - get: pipeline-tasks
  - task: terraform-yaml
    file: pipeline-tasks/terraform-state-to-yaml.yml
    params:
      STATE_FILE: s3-terraform-state/terraform.tfstate
 - task: generate-manifest
    file: pipeline-tasks/spiff-merge.yml
    config:
      inputs:
        - name: pipeline-tasks
        - name: my-other-manifest-bits
      params:
        OUTPUT_FILE: spiff-merge/manifest.yml
        SOURCE_FILE: my-other-manifest-bits/manifest.yml
        MERGE_FILES: terraform-yaml/state.yml

```
### upload-release
### write-file