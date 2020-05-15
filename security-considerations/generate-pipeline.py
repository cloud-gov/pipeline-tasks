from pathlib import Path
import os


def main():
    repos_file = find_repos_file()
    repos = []
    context = "pr-message-includes-security-considerations"
    with open(repos_file, "r") as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#'):
                repos.append(line)
    with open(repos_file.parent / "pipeline.yml", "w") as f:

        f.write("---\njobs:")
        for repo in repos:
            resource_name = pr_resource_name(repo)
            f.write(f"""
- name: pull-status-check-{repo_name(repo)}
  plan:
  - get: pipeline-tasks
  - get: {resource_name}
    version: every
    trigger: true
  - put: {resource_name}
    params:
      path: {resource_name}
      status: pending
      context: {context}
  - task: build
    input_mapping:
      pull-request: {resource_name}
    file: pipeline-tasks/security-considerations/security-considerations.yml
    on_success:
      put: {resource_name}
      params:
        path: {resource_name}
        status: success
        context: {context}
    on_failure:
      put: {resource_name}
      params:
        path: {resource_name}
        status: failure
        context: {context}
""")
        f.write("""
resources:
- name: pipeline-tasks
  type: git
  source:
    uri: ((pipeline-tasks-git-url))
    branch: ((pipeline-tasks-git-branch))
""")
        for repo in repos:
            resource_name = pr_resource_name(repo)
            f.write(f"""
- name: {resource_name}
  type: pull-request
  source:
    repo: {repo}
    access_token: ((status-access-token))
    every: true
""")
        f.write("""
resource_types:
- name: pull-request
  type: docker-image
  source:
    repository: jtarchie/pr
""")


def repo_name(repo):
    """make a resource name from a repo name"""
    return repo.split("/")[1]

def pr_resource_name(repo):
    return f"pull-request-{repo_name(repo)}"

def find_repos_file():
    script_dir = os.path.dirname(os.path.realpath(__file__))
    repos_file = Path(script_dir) / "repos.txt"
    if repos_file.exists():
        return repos_file
    else:
        raise Exception("Can't find repos.txt")

if __name__ == "__main__":
    main()
