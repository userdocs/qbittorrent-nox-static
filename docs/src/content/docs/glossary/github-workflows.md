---
title: Github Workflows
hide_title: true
---

🟦 A workflow is a configurable automated process that will run one or more jobs. Workflows are defined by a YAML file checked in to your repository and will run when triggered by an event in your repository, or they can be triggered manually, or at a defined schedule.

---

Workflows are defined in the `.github/workflows directory` in a repository, and a repository can have multiple workflows, each of which can perform a different set of tasks. For example, you can have one workflow to build and test pull requests, another workflow to deploy your application every time a release is created, and still another workflow that adds a label every time someone opens a new issue.

Github workflows are typically stored in the Github as `.github/workflows/workflow-name.yml` in the project repo.

In a nutshell a workflow is a special syntax to define some tasks you want done on what are called runners like `ubuntu-latest`.

You use a combination of `yaml` and scripting/shell languages to define the some criteria and then create steps towards completion of a job.

This project uses them to build and release static binaries and here is an example of on of the files that build releases using the workflow files.

Action overview for this workflows: [matrix_multi_build_and_release_qbt_workflow_files.yml](https://github.com/userdocs/qbittorrent-nox-static/actions/workflows/matrix_multi_build_and_release_qbt_workflow_files.yml)

The workflow file itself: [matrix_multi_build_and_release_qbt_workflow_files.yml](https://github.com/userdocs/qbittorrent-nox-static/blob/master/.github/workflows/matrix_multi_build_and_release_qbt_workflow_files.yml)

If you would like to know more about creating workflows you should read the excellent Github docs.

https://docs.github.com/en/actions/learn-github-actions/understanding-github-actions

https://docs.github.com/en/actions/using-workflows/about-workflows
