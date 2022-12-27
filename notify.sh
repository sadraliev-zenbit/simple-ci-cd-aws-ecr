slack_channel="#tb_solution_bots"
slack_username="Frontend Dev Environment Bot"
success=":rocket:"
failure=":pensive:"
slack_webhook_url="https://hooks.slack.com/services/"
success_message="Tests passed successfully"
failed_message="the tests failed"


function run {
    url="${slack_webhook_url}$1"
    message=$2
    emoji=$3
    curl -X POST --data-urlencode \
    "payload={\"channel\": \"${slack_channel}\", \"username\": \"${slack_username}\", \"text\": \"${message}\", \"icon_emoji\": \"${emoji}\"}" \
    ${url}
}

run $1 "$2" $3