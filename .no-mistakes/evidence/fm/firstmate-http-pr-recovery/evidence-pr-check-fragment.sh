# Product-level evidence for the public scan and generated static poll.
dir=$(make_case evidence-http-forgejo)
state="$dir/home/state"
url=http://pi4:3001/o/r/pulls/7
write_task_meta "$dir" task-a
printf 'done [at=2]: PR %s checks green\n' "$url" > "$state/task-a.status"
write_task_meta "$dir" task-prose
printf 'done [at=2]: opened http://pi4:3001/o/r/pulls/8\n' > "$state/task-prose.status"
cat > "$dir/fakebin/tea" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$FM_TEST_TEA_LOG"
if [ "${1:-} ${2:-}" = "login list" ]; then
  if [ -n "${FM_TEST_TEA_WRONG_PORT_ONLY:-}" ]; then
    printf '[{"name":"other","url":"http://pi4:3002"}]\n'
  else
    printf '[{"name":"main","url":"http://pi4:3001"},{"name":"other","url":"http://pi4:3002"}]\n'
  fi
  exit 0
fi
[ "${1:-}" = api ] || exit 0
case "${FM_TEST_TEA_PULL:-open}" in
  merged) printf '{"state":"closed","merged":true,"head":{"sha":"abc"}}\n' ;;
  *) printf '{"state":"open","merged":false,"head":{"sha":"abc"}}\n' ;;
esac
SH
chmod +x "$dir/fakebin/tea"
ln -sf "$REAL_JQ" "$dir/fakebin/jq"
: > "$dir/tea.log"
run_check_entry "$dir" scan || fail "public HTTP Forgejo scan failed"
grep -qxF "pr=$url" "$state/task-a.meta" || fail "scan did not persist the HTTP Forgejo PR"
fm_pr_poll_artifacts_valid "$state" task-a "$POLL" || fail "scan did not arm an authenticated poll"
! grep -q '^pr=' "$state/task-prose.meta" || fail "scan claimed a prose HTTP URL"
open_out=$(FM_TEST_TEA_LOG="$dir/tea.log" run_poll "$dir") || fail "open poll failed"
[ -z "$open_out" ] || fail "open poll emitted $open_out"
merged_out=$(FM_TEST_TEA_LOG="$dir/tea.log" FM_TEST_TEA_PULL=merged run_poll "$dir") || fail "merged poll failed"
[ "$merged_out" = merged ] || fail "merged poll emitted $merged_out"
wrong_port_out=$(FM_TEST_TEA_LOG="$dir/tea.log" FM_TEST_TEA_PULL=merged FM_TEST_TEA_WRONG_PORT_ONLY=1 run_poll "$dir") || fail "wrong-port poll failed"
[ -z "$wrong_port_out" ] || fail "wrong-port login emitted $wrong_port_out"
printf '$ bin/fm-pr-check.sh scan\n'
printf 'recorded: '; grep '^pr=' "$state/task-a.meta"
printf 'poll sidecar (provider, URL, authority, repository, number):\n'; cat "$state/task-a.pr-poll"
printf 'prose-only HTTP task pr records: '; grep -c '^pr=' "$state/task-prose.meta" || true
printf 'open PR poll output: %s\n' "${open_out:-<silent>}"
printf 'merged PR poll output: %s\n' "$merged_out"
printf 'wrong-port-only login poll output: %s\n' "${wrong_port_out:-<silent>}"
printf 'authenticated API request: '; grep '^api --login main ' "$dir/tea.log" | head -1
