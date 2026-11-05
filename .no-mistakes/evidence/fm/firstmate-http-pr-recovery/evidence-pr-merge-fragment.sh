# Product-level evidence for the guarded HTTP Forgejo merge entrypoint.
host=pi4:3001
url="http://$host/$FJ_OWNER/$FJ_REPO/pulls/12"
case_dir=$(make_forgejo_case evidence-http-forgejo-merge)
write_tea_logins_json "$case_dir/tea-logins.json" \
  other "http://pi4:3002" "$FJ_LOGIN" "http://$host"
rc=0
run_pr_merge "$case_dir" task-x1 "$url" > "$case_dir/stdout" 2> "$case_dir/stderr" || rc=$?
[ "$rc" -eq 0 ] || { cat "$case_dir/stderr"; fail "HTTP Forgejo merge failed"; }
grep -qxF "pr=$url" "$case_dir/state/task-x1.meta" || fail "merge did not record its PR"
[ -e "$case_dir/tea-merge-called" ] || fail "merge endpoint was not called"
merge_call=$(tea_merge_line "$case_dir/tea.log")
printf '$ bin/fm-pr-merge.sh task-x1 %s\n' "$url"
printf 'exit: %s\n' "$rc"
grep '^verified:' "$case_dir/stderr"
printf 'recorded: '; grep '^pr=' "$case_dir/state/task-x1.meta"
printf 'merge request: %s\n' "$merge_call"
wrong_dir=$(make_forgejo_case evidence-http-forgejo-wrong-port)
write_tea_logins_json "$wrong_dir/tea-logins.json" other "http://pi4:3002"
wrong_rc=0
run_pr_merge "$wrong_dir" task-x1 "$url" > "$wrong_dir/stdout" 2> "$wrong_dir/stderr" || wrong_rc=$?
[ "$wrong_rc" -eq 1 ] || fail "wrong-port-only login did not refuse"
[ ! -e "$wrong_dir/tea-merge-called" ] || fail "wrong-port login reached merge endpoint"
printf '\nwrong-port-only login:\nexit: %s\n' "$wrong_rc"
grep '^error:.*tea login' "$wrong_dir/stderr"
printf 'merge endpoint called: no\n'
