# Product-level evidence for the rendered Bearings board payload.
home=$(make_home evidence-http-pr-urls)
data="$home/payload.json"
board="$home/.lavish/bearings-board.html"
write_valid_payload "$data"
jq '.captains_call[1].pr_url = "http://pi4:3001/o/r/pulls/7"
  | .landed = [{
    "id":"http-landed",
    "repo":"sample",
    "what":"Landed through Forgejo",
    "owner":"firstmate",
    "pr_url":"http://pi4:3001/o/r/pulls/8"
  }]' "$data" > "$data.tmp" && mv "$data.tmp" "$data"
run_board "$home" build "$data" > /dev/null || fail "board rejected HTTP Forgejo links"
extract_payload "$board" | jq -e '.captains_call[1].pr_url == "http://pi4:3001/o/r/pulls/7"
  and .landed[0].pr_url == "http://pi4:3001/o/r/pulls/8"' > /dev/null \
  || fail "built board dropped HTTP Forgejo links"
cp "$board" /Users/user/.no-mistakes/evidence/01M6MSQ97V3TKMNHZ3Y95VM8TJ/http-forgejo-board.html
printf '$ bin/fm-bearings-board.sh build <payload>\n'
extract_payload "$board" | jq '{captains_call_pr: .captains_call[1].pr_url, landed: .landed}'
printf 'rendered HTML: http-forgejo-board.html\n'
