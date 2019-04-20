#!/bin/sh
set -e
cd "${GO_ACTION_WORKING_DIR:-.}"

set +e
if test -e "go.mod"; then go mod download; fi
OUTPUT=$(sh -c "go vet -vettool=/go/bin/shadow ${FLAGS} ./... $*" 2>&1)
SUCCESS=$?
echo "${OUTPUT}"
set -e

if [ ${SUCCESS} -eq 0 ]; then
    exit 0
fi

if [ "${GO_ACTION_COMMENT}" = "1" ] || [ "${GO_ACTION_COMMENT}" = "false" ]; then
    exit ${SUCCESS}
fi

COMMENT="## shadow Failed

\`\`\`
${OUTPUT}
\`\`\`

"

PAYLOAD=$(echo '{}' | jq --arg body "${COMMENT}" '.body = $body')
COMMENTS_URL=$(cat /github/workflow/event.json | jq -r .pull_request.comments_url)
curl -s -S -H "Authorization: token ${GITHUB_TOKEN}" --header "Content-Type: application/json" --data "${PAYLOAD}" "${COMMENTS_URL}" > /dev/null

exit ${SUCCESS}