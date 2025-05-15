#!/bin/bash
set -e
latestTag=$(git describe --tags --abbrev=0)
commitsSinceLatestTag=$(git log "${latestTag}"..HEAD --oneline | awk '{print $1}')
affectedFilePaths=()
while IFS= read -r commitId || [[ -n "${commitId}" ]]; do
  affectedFilePathsFromCommit=$(git diff-tree --no-commit-id --name-only "${commitId}" -r)
  while IFS= read -r affectedFilePathFromCommit || [[ -n "${affectedFilePathFromCommit}" ]]; do
    affectedFilePaths+=("${affectedFilePathFromCommit}")
  done < <(printf '%s' "${affectedFilePathsFromCommit}")
done < <(printf '%s' "${commitsSinceLatestTag}")

packageJsonContent="$(< ./package.json)"
workspacePaths=()
for workspacePath in $(echo "${packageJsonContent}" | jq -cr '.workspaces[]'); do
  workspacePaths+=($(echo "${workspacePath}" | sed 's@./@@'))
done

affectedWorkspaces=()
for workspacePath in "${workspacePaths[@]}"; do
  for affectedFilePath in "${affectedFilePaths[@]}"; do
    if [[ "${affectedFilePath}" =~ "${workspacePath}" ]] && [[ ! "${affectedWorkspaces[@]} " =~ "${workspacePath}" ]]; then
      affectedWorkspaces+=("${workspacePath}")
    fi
  done
done

if [[ -z "${affectedWorkspaces[@]}" ]]; then
  echo "No workspace affected.";
  exit 0;
fi

echo "Affected workspaces:"
for affectedWorkspace in "${affectedWorkspaces[@]}"; do
  echo "  - ${affectedWorkspace}"
done

for affectedWorkspace in "${affectedWorkspaces[@]}"; do
  npm run lint --if-present --workspace "${affectedWorkspace}"
  npm run test --if-present --workspace "${affectedWorkspace}"
done
